import 'package:hive_flutter/hive_flutter.dart';

import '../database/hive_boxes.dart';
import '../models/pokedex_entry.dart';
import '../models/team_slot.dart';
import 'move_repository.dart';
import 'pokedex_repositry.dart';

class TeamRepository {
  TeamRepository({
    MoveRepository? moveRepository,
    PokedexRepository? pokedexRepository,
  }) : _moveRepository = moveRepository ?? MoveRepository(),
       _pokedexRepository = pokedexRepository ?? PokedexRepository();

  final MoveRepository _moveRepository;
  final PokedexRepository _pokedexRepository;

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

  Future<List<TeamSlot>> _migrateSavedMoveReferences(
    List<TeamSlot> team,
  ) async {
    final migratedTeam = <TeamSlot>[];

    for (final slot in team) {
      if (!slot.isPokemon) {
        migratedTeam.add(slot);
        continue;
      }
      final migratedMoves = <String>[];

      for (final reference in slot.selectedMoves) {
        final trimmedReference = reference.trim();
        if (trimmedReference.isEmpty) continue;

        final move = await _moveRepository.getMove(
          trimmedReference,
          pokemonId: slot.pokemonId,
        );
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
    await _pokedexRepository.registerCaughtMany(
      profileId: profileId,
      pokemon: [
        for (final slot in team)
          if (slot.pokemonId != null)
            PokedexOwnedForm(
              pokemonId: slot.pokemonId!,
              formName: slot.formName,
            ),
      ],
    );
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
        final changedPokemon = slot.pokemonId != pokemonId || slot.isEgg;

        return slot.copyWith(
          pokemonId: pokemonId,
          clearPokemon: pokemonId == null,
          clearEgg: true,
          experience: changedPokemon ? 0 : slot.experience,
          currentHp: changedPokemon ? (initialCurrentHp ?? 0) : slot.currentHp,
          nickname: changedPokemon ? null : slot.nickname,
          selectedMoves: changedPokemon ? [] : slot.selectedMoves,
          isShiny: changedPokemon ? false : slot.isShiny,
          gender: changedPokemon ? null : slot.gender,
          formName: changedPokemon ? null : slot.formName,
          nature: changedPokemon ? 'No Nature' : slot.nature,
          heldItem: changedPokemon ? null : slot.heldItem,
          abilities: changedPokemon ? [] : slot.abilities,
          feats: changedPokemon ? [] : slot.feats,
          extraSkills: changedPokemon ? [] : slot.extraSkills,
          statusEffects: changedPokemon ? [] : slot.statusEffects,
          customAbilityScores: changedPokemon ? {} : slot.customAbilityScores,
          loyalty: changedPokemon ? 0 : slot.loyalty,
        );
      }

      return slot;
    }).toList();

    await saveTeam(profileId, updatedTeam);
  }

  Future<void> setEggInSlot({
    required String profileId,
    required int slotIndex,
    required String? eggId,
  }) async {
    final team = await getTeam(profileId);
    final updatedTeam = [
      for (final slot in team)
        if (slot.slotIndex == slotIndex)
          TeamSlot(slotIndex: slot.slotIndex, pokemonId: null, eggId: eggId)
        else
          slot,
    ];
    await saveTeam(profileId, updatedTeam);
  }

  Future<void> clearSlot({
    required String profileId,
    required int slotIndex,
  }) async {
    final team = await getTeam(profileId);
    final updatedTeam = [
      for (final slot in team)
        if (slot.slotIndex == slotIndex)
          TeamSlot(slotIndex: slot.slotIndex, pokemonId: null)
        else
          slot,
    ];
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

  Future<List<TeamSlot>> reorderSlots({
    required String profileId,
    required int fromSlotIndex,
    required int toSlotIndex,
  }) async {
    final team = await getTeam(profileId);
    final reordered = reorderTeam(
      team,
      fromSlotIndex: fromSlotIndex,
      toSlotIndex: toSlotIndex,
    );
    await saveTeam(profileId, reordered);
    return reordered;
  }

  static List<TeamSlot> reorderTeam(
    List<TeamSlot> team, {
    required int fromSlotIndex,
    required int toSlotIndex,
  }) {
    final ordered = [...team]
      ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
    final fromPosition = ordered.indexWhere(
      (slot) => slot.slotIndex == fromSlotIndex,
    );
    final toPosition = ordered.indexWhere(
      (slot) => slot.slotIndex == toSlotIndex,
    );

    if (fromPosition < 0 || toPosition < 0) {
      throw RangeError(
        'Impossibile riordinare gli slot $fromSlotIndex e $toSlotIndex.',
      );
    }
    if (fromPosition == toPosition) return ordered;

    final moved = ordered.removeAt(fromPosition);
    ordered.insert(toPosition, moved);

    return [
      for (var index = 0; index < ordered.length; index++)
        ordered[index].copyWith(slotIndex: index),
    ];
  }

  Future<void> deleteTeam(String profileId) async {
    final box = await _box();
    await box.delete(profileId);
    await box.flush();
  }
}
