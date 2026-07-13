import 'package:hive_flutter/hive_flutter.dart';

import '../database/hive_boxes.dart';
import '../models/saved_encounter.dart';

class SavedEncounterRepository {
  Future<Box> _box() => Hive.openBox(HiveBoxes.savedEncounters);

  Future<List<SavedEncounter>> getEncounters(String profileId) async {
    final box = await _box();
    final data = box.get(profileId);
    if (data == null) return const [];

    final encounters = [
      for (final value in List<dynamic>.from(data as List))
        if (value is Map)
          SavedEncounter.fromJson(Map<String, dynamic>.from(value)),
    ];
    encounters.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return encounters;
  }

  Future<void> replaceEncounters(
    String profileId,
    List<SavedEncounter> encounters,
  ) async {
    final box = await _box();
    await box.put(
      profileId,
      encounters.map((encounter) => encounter.toJson()).toList(growable: false),
    );
    await box.flush();
  }

  Future<void> saveEncounter({
    required String profileId,
    required SavedEncounter encounter,
  }) async {
    if (!encounter.isValid) {
      throw const FormatException('L’incontro da salvare non è valido.');
    }
    final encounters = await getEncounters(profileId);
    final updated = [
      encounter,
      for (final existing in encounters)
        if (existing.id != encounter.id) existing,
    ];
    await replaceEncounters(profileId, updated);
  }

  Future<void> deleteEncounter({
    required String profileId,
    required String encounterId,
  }) async {
    final encounters = await getEncounters(profileId);
    await replaceEncounters(profileId, [
      for (final encounter in encounters)
        if (encounter.id != encounterId) encounter,
    ]);
  }

  Future<void> deleteEncounters(String profileId) async {
    final box = await _box();
    await box.delete(profileId);
    await box.flush();
  }
}
