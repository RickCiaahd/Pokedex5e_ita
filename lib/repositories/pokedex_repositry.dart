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
    return _entryFromBox(box, profileId, pokemonId);
  }

  PokedexEntry _entryFromBox(Box box, String profileId, int pokemonId) {
    final data = box.get(_key(profileId, pokemonId));
    if (data == null) return PokedexEntry.empty(pokemonId);
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
    await box.put(_key(profileId, entry.pokemonId), entry.toJson());
    await box.flush();
  }

  Future<void> updateMarkMode({
    required String profileId,
    required int pokemonId,
    required bool seen,
    required bool caught,
    String? formName,
    String speciesName = '',
  }) async {
    final current = await getEntry(profileId: profileId, pokemonId: pokemonId);
    final entry = current.setFormState(
      formName: formName,
      speciesName: speciesName,
      seen: seen,
      caught: caught,
    );

    await saveEntry(profileId: profileId, entry: entry);
  }

  Future<void> registerSeen({
    required String profileId,
    required int pokemonId,
    String? formName,
    String speciesName = '',
  }) {
    return updateMarkMode(
      profileId: profileId,
      pokemonId: pokemonId,
      formName: formName,
      speciesName: speciesName,
      seen: true,
      caught: false,
    );
  }

  Future<void> registerCaught({
    required String profileId,
    required int pokemonId,
    String? formName,
    String speciesName = '',
  }) {
    return updateMarkMode(
      profileId: profileId,
      pokemonId: pokemonId,
      formName: formName,
      speciesName: speciesName,
      seen: true,
      caught: true,
    );
  }

  Future<void> registerCaughtMany({
    required String profileId,
    required Iterable<PokedexOwnedForm> pokemon,
  }) async {
    final registrations = pokemon
        .where((item) => item.pokemonId > 0)
        .toList(growable: false);
    if (registrations.isEmpty) return;

    final box = await _box();
    final updates = <String, dynamic>{};

    for (final item in registrations) {
      if (!PokedexEntry.isTrackableForm(item.formName)) continue;
      final current = _entryFromBox(box, profileId, item.pokemonId);
      final updated = current.setFormState(
        formName: item.formName,
        seen: true,
        caught: true,
      );
      updates[_key(profileId, item.pokemonId)] = updated.toJson();
    }

    if (updates.isEmpty) return;
    await box.putAll(updates);
    await box.flush();
  }

  Future<void> clearProfilePokedex(String profileId) async {
    final box = await _box();
    final keysToDelete = box.keys
        .where((key) => key is String && key.startsWith('$profileId:'))
        .toList();

    await box.deleteAll(keysToDelete);
    await box.flush();
  }
}
