import 'package:hive_flutter/hive_flutter.dart';

import '../database/hive_boxes.dart';
import '../models/breeding_egg.dart';

class BreedingEggRepository {
  Future<Box> _box() => Hive.openBox(HiveBoxes.breedingEggs);

  Future<List<BreedingEgg>> getEggs(String profileId) async {
    final box = await _box();
    final raw = box.get(profileId);
    if (raw == null) return const [];
    final eggs = List<Map>.from(raw)
        .map((item) => BreedingEgg.fromJson(Map<String, dynamic>.from(item)))
        .where((egg) => egg.id.isNotEmpty && egg.speciesId > 0)
        .toList();
    eggs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return eggs;
  }

  Future<void> replaceEggs(String profileId, List<BreedingEgg> eggs) async {
    final box = await _box();
    await box.put(profileId, eggs.map((egg) => egg.toJson()).toList());
    await box.flush();
  }

  Future<void> saveEgg(String profileId, BreedingEgg egg) async {
    final eggs = await getEggs(profileId);
    final index = eggs.indexWhere((candidate) => candidate.id == egg.id);
    if (index == -1) {
      eggs.insert(0, egg);
    } else {
      eggs[index] = egg;
    }
    await replaceEggs(profileId, eggs);
  }

  Future<void> deleteEgg(String profileId, String eggId) async {
    final eggs = await getEggs(profileId);
    await replaceEggs(profileId, [
      for (final egg in eggs)
        if (egg.id != eggId) egg,
    ]);
  }

  Future<void> deleteEggs(String profileId) async {
    final box = await _box();
    await box.delete(profileId);
    await box.flush();
  }
}
