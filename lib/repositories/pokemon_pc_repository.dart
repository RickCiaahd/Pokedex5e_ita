import 'package:hive_flutter/hive_flutter.dart';

import '../database/hive_boxes.dart';
import '../models/pc_pokemon.dart';
import '../models/pokedex_entry.dart';
import '../models/team_slot.dart';
import 'pokedex_repositry.dart';

class PokemonPcRepository {
  PokemonPcRepository({PokedexRepository? pokedexRepository})
    : _pokedexRepository = pokedexRepository ?? PokedexRepository();

  final PokedexRepository _pokedexRepository;

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
    await _pokedexRepository.registerCaughtMany(
      profileId: profileId,
      pokemon: [
        for (final item in pokemon)
          PokedexOwnedForm(pokemonId: item.pokemonId, formName: item.formName),
      ],
    );
  }

  Future<PcPokemon> depositPokemon({
    required String profileId,
    required int pokemonId,
    int experience = 0,
    int currentHp = 0,
    String? nickname,
    List<String> selectedMoves = const [],
    bool isShiny = false,
    String? gender,
    String? formName,
    String nature = 'No Nature',
    String? heldItem,
    List<String> abilities = const [],
    List<String> feats = const [],
    List<String> extraSkills = const [],
    List<String> statusEffects = const [],
    Map<String, int> customAbilityScores = const {},
    int loyalty = 0,
    String notes = '',
  }) async {
    final storedPokemon = await getPokemon(profileId);
    final item = PcPokemon(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      pokemonId: pokemonId,
      experience: experience,
      currentHp: currentHp,
      nickname: nickname,
      selectedMoves: selectedMoves,
      isShiny: isShiny,
      gender: gender,
      formName: formName,
      nature: nature,
      heldItem: heldItem,
      abilities: abilities,
      feats: feats,
      extraSkills: extraSkills,
      statusEffects: statusEffects,
      customAbilityScores: customAbilityScores,
      loyalty: loyalty,
      notes: notes,
    );

    await savePokemon(profileId, [item, ...storedPokemon]);

    return item;
  }

  Future<PcPokemon> depositTeamSlot({
    required String profileId,
    required TeamSlot slot,
  }) async {
    final storedPokemon = await getPokemon(profileId);
    final item = PcPokemon.fromTeamSlot(slot);

    await savePokemon(profileId, [item, ...storedPokemon]);

    return item;
  }

  Future<void> removePokemon({
    required String profileId,
    required String pcPokemonId,
  }) async {
    final storedPokemon = await getPokemon(profileId);

    await savePokemon(profileId, [
      for (final item in storedPokemon)
        if (item.id != pcPokemonId) item,
    ]);
  }

  Future<void> deletePc(String profileId) async {
    final box = await _box();

    await box.delete(profileId);
    await box.flush();
  }
}
