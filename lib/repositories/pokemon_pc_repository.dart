import 'package:hive_flutter/hive_flutter.dart';

import '../database/hive_boxes.dart';
import '../models/pc_pokemon.dart';

class PokemonPcRepository {
  Future<Box> _box() => Hive.openBox(HiveBoxes.pcPokemon);

  Future<List<PcPokemon>> getPokemon(String profileId) async {
    final box = await _box();
    final data = box.get(profileId);

    if (data == null) {
      return [];
    }

    return List<Map>.from(data)
        .map((item) => PcPokemon.fromJson(Map<String, dynamic>.from(item)))
        .toList()
      ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
  }

  Future<void> savePokemon(String profileId, List<PcPokemon> pokemon) async {
    final box = await _box();

    await box.put(profileId, pokemon.map((item) => item.toJson()).toList());
    await box.flush();
  }

  Future<PcPokemon> depositPokemon({
    required String profileId,
    required int pokemonId,
  }) async {
    final storedPokemon = await getPokemon(profileId);
    final item = PcPokemon(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      pokemonId: pokemonId,
    );

    await savePokemon(profileId, [item, ...storedPokemon]);

    return item;
  }

  Future<void> removePokemon({
    required String profileId,
    required String pcPokemonId,
  }) async {
    final storedPokemon = await getPokemon(profileId);

    await savePokemon(
      profileId,
      [
        for (final item in storedPokemon)
          if (item.id != pcPokemonId) item,
      ],
    );
  }

  Future<void> deletePc(String profileId) async {
    final box = await _box();

    await box.delete(profileId);
    await box.flush();
  }
}
