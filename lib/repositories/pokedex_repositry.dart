import 'package:flutter/foundation.dart';
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

    debugPrint(
      'POKEDEX REPOSITORY: caricate ${result.length} entries per profilo $profileId',
    );

    return result;
  }

  Future<void> saveEntry({
    required String profileId,
    required PokedexEntry entry,
  }) async {
    final box = await _box();

    await box.put(_key(profileId, entry.pokemonId), entry.toJson());
    await box.flush();

    debugPrint(
      'POKEDEX REPOSITORY: salvato pokemon ${entry.pokemonId} '
      'seen=${entry.seen} caught=${entry.caught} '
      'forms=${entry.forms.length} profilo=$profileId',
    );
  }

  Future<PokedexEntry> updateFormMarkMode({
    required String profileId,
    required int pokemonId,
    required String formKey,
    String? formName,
    required bool seen,
    required bool caught,
  }) async {
    final current = await getEntry(profileId: profileId, pokemonId: pokemonId);
    final updated = current.withFormStatus(
      formKey: formKey,
      formName: formName,
      seen: seen,
      caught: caught,
    );

    await saveEntry(profileId: profileId, entry: updated);
    return updated;
  }

  Future<PokedexEntry> registerCaught({
    required String profileId,
    required int pokemonId,
    String? formName,
  }) {
    final formKey = PokedexEntry.normalizeFormKey(formName);
    return updateFormMarkMode(
      profileId: profileId,
      pokemonId: pokemonId,
      formKey: formKey,
      formName: formName?.trim().isEmpty == false ? formName : 'Base',
      seen: true,
      caught: true,
    );
  }

  Future<PokedexEntry> registerSeen({
    required String profileId,
    required int pokemonId,
    String? formName,
  }) {
    final formKey = PokedexEntry.normalizeFormKey(formName);
    return updateFormMarkMode(
      profileId: profileId,
      pokemonId: pokemonId,
      formKey: formKey,
      formName: formName?.trim().isEmpty == false ? formName : 'Base',
      seen: true,
      caught: false,
    );
  }

  /// Backward-compatible species update used by older screens.
  ///
  /// If a precise alternate form was registered immediately before this call,
  /// a generic caught update must not also unlock the base form.
  Future<void> updateMarkMode({
    required String profileId,
    required int pokemonId,
    required bool seen,
    required bool caught,
    String? formName,
  }) async {
    final current = await getEntry(profileId: profileId, pokemonId: pokemonId);
    final hasKnownAlternate = current.forms.entries.any(
      (entry) =>
          entry.key != PokedexEntry.baseFormKey &&
          (entry.value.seen || entry.value.caught),
    );

    if (formName == null && caught && hasKnownAlternate) {
      return;
    }

    await updateFormMarkMode(
      profileId: profileId,
      pokemonId: pokemonId,
      formKey: PokedexEntry.normalizeFormKey(formName),
      formName: formName?.trim().isEmpty == false ? formName : 'Base',
      seen: seen,
      caught: caught,
    );
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
