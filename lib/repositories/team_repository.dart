import 'package:hive_flutter/hive_flutter.dart';

import '../database/hive_boxes.dart';
import '../models/team_slot.dart';
import 'move_repository.dart';

class TeamRepository {
  TeamRepository({MoveRepository? moveRepository})
      : _moveRepository = moveRepository ?? MoveRepository();

  final MoveRepository _moveRepository;

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

    final team = List<Map>.from(data)
        .map((item) => TeamSlot.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    final migratedTeam = await _migrateSavedMoveReferences(team);

    if (!_sameTeamMoveReferences(team, migratedTeam)) {
      await box.put(
        profileId,
        migratedTeam.map((slot) => slot.toJson()).toList(),
      );
      await box.flush();
    }

    return migratedTeam;
  }

  Future<List<TeamSlot>> _migrateSavedMoveReferences(List<TeamSlot> team) async {
    final migratedTeam = <TeamSlot>[];

    for (final slot in team) {
      final migratedMoves = <String>[];

      for (final reference in slot.selectedMoves) {
        final trimmedReference = reference.trim();
        if (trimmedReference.isEmpty) continue;

        final move = await _moveRepository.getMove(trimmedReference);
        migratedMoves.add(move?.id ?? trimmedReference);
      }

      migratedTeam.add(slot.copyWith(selectedMoves: migratedMoves));
    }

    return migratedTeam;
  }

  bool _sameTeamMoveReferences(List<TeamSlot> a, List<TeamSlot> b) {
    if (a.length != b.length) return false;

    for (var index = 0; index < a.length; index++) {
      final aMoves = a[index].selectedMoves;
      final bMoves = b[index].selectedMoves;
      if (aMoves.length != bMoves.length) return false;

      for (var moveIndex = 0; moveIndex < aMoves.length; moveIndex++) {
        if (aMoves[moveIndex] != bMoves[moveIndex]) return false;
      }
    }

    return true;
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
