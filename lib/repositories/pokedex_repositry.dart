import 'package:hive_flutter/hive_flutter.dart';

import '../database/hive_boxes.dart';
import '../models/pokedex_entry.dart';

class PokedexRepository {
  Future<Box> _box() => Hive.openBox(HiveBoxes.pokedexEntries);

  String _key(String profileId, int pokemonId) {
    return '$profileId:$pokemonId';
  }

  Future<PokedexEntry> getEntry({
    required String profileId,
    required int pokemonId,
  }) async {
    final box = await _box();
    final data = box.get(_key(profileId, pokemonId));

    if (data == null) {
      return PokedexEntry.empty(pokemonId);
    }

    return PokedexEntry.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Map<int, PokedexEntry>> getEntriesForProfile(String profileId) async {
    final box = await _box();

    final result = <int, PokedexEntry>{};

    for (final key in box.keys) {
      if (key is String && key.startsWith('$profileId:')) {
        final data = box.get(key);
        final entry = PokedexEntry.fromJson(Map<String, dynamic>.from(data));
        result[entry.pokemonId] = entry;
      }
    }

    return result;
  }

  Future<void> saveEntry({
    required String profileId,
    required PokedexEntry entry,
  }) async {
    final box = await _box();

    await box.put(
      _key(profileId, entry.pokemonId),
      entry.toJson(),
    );
  }

  Future<void> updateMarkMode({
    required String profileId,
    required int pokemonId,
    required MarkMode markMode,
  }) async {
    final entry = PokedexEntry(
      pokemonId: pokemonId,
      markMode: markMode,
      updatedAt: DateTime.now(),
    );

    await saveEntry(profileId: profileId, entry: entry);
  }

  Future<void> clearProfilePokedex(String profileId) async {
    final box = await _box();

    final keysToDelete = box.keys
        .where((key) => key is String && key.startsWith('$profileId:'))
        .toList();

    await box.deleteAll(keysToDelete);
  }
}