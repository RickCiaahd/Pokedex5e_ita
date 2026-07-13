import 'package:hive_flutter/hive_flutter.dart';

import '../database/hive_boxes.dart';
import '../models/saved_npc_trainer.dart';

class SavedNpcTrainerRepository {
  Future<Box> _box() => Hive.openBox(HiveBoxes.savedNpcTrainers);

  Future<List<SavedNpcTrainer>> getTrainers(String profileId) async {
    final box = await _box();
    final raw = box.get(profileId);
    if (raw == null) return const [];
    final trainers = [
      for (final value in List<dynamic>.from(raw as List))
        if (value is Map)
          SavedNpcTrainer.fromJson(Map<String, dynamic>.from(value)),
    ];
    trainers.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return trainers;
  }

  Future<void> replaceTrainers(
    String profileId,
    List<SavedNpcTrainer> trainers,
  ) async {
    final box = await _box();
    await box.put(
      profileId,
      trainers.map((trainer) => trainer.toJson()).toList(growable: false),
    );
    await box.flush();
  }

  Future<void> saveTrainer({
    required String profileId,
    required SavedNpcTrainer trainer,
  }) async {
    if (!trainer.isValid) {
      throw const FormatException('L’allenatore PNG da salvare non è valido.');
    }
    final trainers = await getTrainers(profileId);
    await replaceTrainers(profileId, [
      trainer,
      for (final existing in trainers)
        if (existing.id != trainer.id) existing,
    ]);
  }

  Future<void> deleteTrainer({
    required String profileId,
    required String trainerId,
  }) async {
    final trainers = await getTrainers(profileId);
    await replaceTrainers(profileId, [
      for (final trainer in trainers)
        if (trainer.id != trainerId) trainer,
    ]);
  }

  Future<void> deleteTrainers(String profileId) async {
    final box = await _box();
    await box.delete(profileId);
    await box.flush();
  }
}
