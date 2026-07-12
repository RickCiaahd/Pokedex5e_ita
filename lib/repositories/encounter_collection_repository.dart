import 'package:hive_flutter/hive_flutter.dart';

import '../database/hive_boxes.dart';
import '../models/encounter_collection.dart';

class EncounterCollectionRepository {
  Future<Box> _box() => Hive.openBox(HiveBoxes.encounterCollections);

  Future<List<EncounterCollection>> getCollections(String profileId) async {
    final box = await _box();
    final data = box.get(profileId);
    if (data == null) return const [];

    final collections = [
      for (final value in List<dynamic>.from(data as List))
        if (value is Map)
          EncounterCollection.fromJson(Map<String, dynamic>.from(value)),
    ];
    collections.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return collections;
  }

  Future<void> replaceCollections(
    String profileId,
    List<EncounterCollection> collections,
  ) async {
    final box = await _box();
    await box.put(
      profileId,
      collections.map((collection) => collection.toJson()).toList(),
    );
    await box.flush();
  }

  Future<void> saveCollection({
    required String profileId,
    required EncounterCollection collection,
  }) async {
    final collections = await getCollections(profileId);
    final updated = [
      collection,
      for (final existing in collections)
        if (existing.id != collection.id) existing,
    ];
    await replaceCollections(profileId, updated);
  }

  Future<void> deleteCollection({
    required String profileId,
    required String collectionId,
  }) async {
    final collections = await getCollections(profileId);
    await replaceCollections(profileId, [
      for (final collection in collections)
        if (collection.id != collectionId) collection,
    ]);
  }

  Future<void> deleteCollections(String profileId) async {
    final box = await _box();
    await box.delete(profileId);
    await box.flush();
  }
}
