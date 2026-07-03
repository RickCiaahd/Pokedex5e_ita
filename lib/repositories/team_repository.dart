import 'package:hive_flutter/hive_flutter.dart';

import '../database/hive_boxes.dart';
import '../models/team_slot.dart';

class TeamRepository {
  Future<Box> _box() => Hive.openBox(HiveBoxes.teams);

  Future<List<TeamSlot>> getTeam(String profileId) async {
    final box = await _box();
    final data = box.get(profileId);

    if (data == null) {
      return List.generate(
        6,
        (index) => TeamSlot(slotIndex: index, pokemonId: null),
      );
    }

    return List<Map>.from(data)
        .map((item) => TeamSlot.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> saveTeam(String profileId, List<TeamSlot> team) async {
    final box = await _box();

    await box.put(
      profileId,
      team.map((slot) => slot.toJson()).toList(),
    );
  }

  Future<void> setPokemonInSlot({
    required String profileId,
    required int slotIndex,
    required int? pokemonId,
  }) async {
    final team = await getTeam(profileId);

    final updatedTeam = team.map((slot) {
      if (slot.slotIndex == slotIndex) {
        return TeamSlot(
          slotIndex: slotIndex,
          pokemonId: pokemonId,
        );
      }

      return slot;
    }).toList();

    await saveTeam(profileId, updatedTeam);
  }
}