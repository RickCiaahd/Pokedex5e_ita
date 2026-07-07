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

    await box.put(profileId, team.map((slot) => slot.toJson()).toList());
    await box.flush();
  }

  Future<void> setPokemonInSlot({
    required String profileId,
    required int slotIndex,
    required int? pokemonId,
    int? initialCurrentHp,
  }) async {
    final team = await getTeam(profileId);

    final updatedTeam = team.map((slot) {
      if (slot.slotIndex == slotIndex) {
        final changedPokemon = slot.pokemonId != pokemonId;

        return slot.copyWith(
          pokemonId: pokemonId,
          clearPokemon: pokemonId == null,
          experience: changedPokemon ? 0 : slot.experience,
          currentHp: changedPokemon ? (initialCurrentHp ?? 0) : slot.currentHp,
          nickname: changedPokemon ? null : slot.nickname,
          selectedMoves: changedPokemon ? [] : slot.selectedMoves,
          isShiny: changedPokemon ? false : slot.isShiny,
          gender: changedPokemon ? null : slot.gender,
          nature: changedPokemon ? 'No Nature' : slot.nature,
          heldItem: changedPokemon ? null : slot.heldItem,
          abilities: changedPokemon ? [] : slot.abilities,
          feats: changedPokemon ? [] : slot.feats,
          extraSkills: changedPokemon ? [] : slot.extraSkills,
          customAbilityScores: changedPokemon ? {} : slot.customAbilityScores,
        );
      }

      return slot;
    }).toList();

    await saveTeam(profileId, updatedTeam);
  }

  Future<void> updateSlot({
    required String profileId,
    required TeamSlot updatedSlot,
  }) async {
    final team = await getTeam(profileId);

    final updatedTeam = team.map((slot) {
      if (slot.slotIndex == updatedSlot.slotIndex) {
        return updatedSlot;
      }

      return slot;
    }).toList();

    await saveTeam(profileId, updatedTeam);
  }

  Future<void> deleteTeam(String profileId) async {
    final box = await _box();
    await box.delete(profileId);
    await box.flush();
  }
}
