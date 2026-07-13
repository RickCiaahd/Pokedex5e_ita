import 'dart:math';

import '../models/battle_session.dart';
import '../models/generated_npc_trainer.dart';
import '../models/master_battle_session.dart';
import '../models/pokemon.dart';
import '../models/saved_npc_trainer.dart';

class MasterBattleService {
  const MasterBattleService();

  MasterBattleSession createSession({
    required String profileId,
    required List<SavedNpcTrainer> trainers,
    required Map<String, int> activeCounts,
    required List<Pokemon> catalog,
    Random? random,
  }) {
    if (trainers.isEmpty) {
      throw const FormatException('Seleziona almeno un allenatore PNG.');
    }
    final rng = random ?? Random();
    final byId = {for (final pokemon in catalog) pokemon.id: pokemon};
    final participants = <MasterBattleParticipant>[];
    final initiative = <BattleInitiativeEntry>[];

    for (final trainer in trainers) {
      if (!trainer.isValid) continue;
      final activeLimit = (activeCounts[trainer.id] ?? 1)
          .clamp(1, trainer.team.length)
          .toInt();
      final team = <MasterBattlePokemonState>[];
      for (var index = 0; index < trainer.team.length; index++) {
        final pokemon = trainer.team[index];
        team.add(
          MasterBattlePokemonState(
            slotIndex: index,
            pokemon: pokemon,
            currentHp: pokemon.maxHp,
          ),
        );
      }
      final activeSlots = {
        for (var index = 0; index < activeLimit; index++) index,
      };
      participants.add(
        MasterBattleParticipant(
          trainerId: trainer.id,
          name: trainer.name,
          epithet: trainer.epithet,
          rank: trainer.rank.label,
          tactics: trainer.tactics,
          personality: trainer.personality,
          rewardMoney: trainer.rewardMoney,
          rewards: trainer.rewards,
          activeLimit: activeLimit,
          activeSlotIndices: activeSlots,
          team: team,
        ),
      );
      for (final slotIndex in activeSlots) {
        final savedPokemon = trainer.team[slotIndex];
        final pokemonName =
            byId[savedPokemon.pokemonId]?.name ?? '#${savedPokemon.pokemonId}';
        initiative.add(
          BattleInitiativeEntry(
            id: initiativeId(trainer.id, slotIndex),
            name: '${trainer.name} + $pokemonName',
            initiative: rng.nextInt(20) + 1,
            isTrainerGroup: true,
          ),
        );
      }
    }
    if (participants.isEmpty) {
      throw const FormatException(
        'Gli allenatori selezionati non sono validi.',
      );
    }
    initiative.sort((a, b) => b.initiative.compareTo(a.initiative));
    final now = DateTime.now();
    return MasterBattleSession(
      profileId: profileId,
      id: now.microsecondsSinceEpoch.toString(),
      round: 1,
      turnIndex: 0,
      selectedTrainerId: participants.first.trainerId,
      focusedSlotIndex: participants.first.activeSlotIndices.first,
      participants: participants,
      initiativeEntries: initiative,
      updatedAt: now,
    );
  }

  MasterBattleSession reset(MasterBattleSession session, {Random? random}) {
    final rng = random ?? Random();
    final participants = [
      for (final participant in session.participants)
        participant.copyWith(
          activeSlotIndices: {
            for (var index = 0; index < participant.activeLimit; index++)
              participant.team[index].slotIndex,
          },
          team: [
            for (final state in participant.team)
              MasterBattlePokemonState(
                slotIndex: state.slotIndex,
                pokemon: state.pokemon,
                currentHp: state.pokemon.maxHp,
              ),
          ],
        ),
    ];
    final initiative = [
      for (final participant in participants)
        for (final slot in participant.activeSlotIndices)
          BattleInitiativeEntry(
            id: initiativeId(participant.trainerId, slot),
            name: _initiativeName(participant, slot),
            initiative: rng.nextInt(20) + 1,
            isTrainerGroup: true,
          ),
    ]..sort((a, b) => b.initiative.compareTo(a.initiative));
    return session.copyWith(
      round: 1,
      turnIndex: 0,
      selectedTrainerId: participants.first.trainerId,
      focusedSlotIndex: participants.first.activeSlotIndices.first,
      participants: participants,
      initiativeEntries: initiative,
      updatedAt: DateTime.now(),
    );
  }

  MasterBattleSession syncInitiative(
    MasterBattleSession session, {
    Random? random,
  }) {
    final rng = random ?? Random();
    final desired = <String, String>{};
    for (final participant in session.participants) {
      for (final slot in participant.activeSlotIndices) {
        desired[initiativeId(participant.trainerId, slot)] = _initiativeName(
          participant,
          slot,
        );
      }
    }

    final entries = <BattleInitiativeEntry>[];
    for (final entry in session.initiativeEntries) {
      if (!entry.isTrainerGroup) {
        entries.add(entry);
        continue;
      }
      final name = desired.remove(entry.id);
      if (name != null) entries.add(entry.copyWith(name: name));
    }
    for (final entry in desired.entries) {
      entries.add(
        BattleInitiativeEntry(
          id: entry.key,
          name: entry.value,
          initiative: rng.nextInt(20) + 1,
          isTrainerGroup: true,
        ),
      );
    }
    entries.sort((a, b) {
      final initiativeCompare = b.initiative.compareTo(a.initiative);
      if (initiativeCompare != 0) return initiativeCompare;
      if (a.isTrainerGroup != b.isTrainerGroup) {
        return a.isTrainerGroup ? -1 : 1;
      }
      return a.name.compareTo(b.name);
    });
    final turnIndex = entries.isEmpty
        ? 0
        : session.turnIndex.clamp(0, entries.length - 1).toInt();
    return session.copyWith(
      initiativeEntries: entries,
      turnIndex: turnIndex,
      updatedAt: DateTime.now(),
    );
  }

  static String initiativeId(String trainerId, int slotIndex) =>
      'npc:$trainerId:$slotIndex';

  String _initiativeName(MasterBattleParticipant participant, int slotIndex) {
    final state = participant.team.firstWhere(
      (pokemon) => pokemon.slotIndex == slotIndex,
      orElse: () => participant.team.first,
    );
    return '${participant.name} + Pokémon #${state.pokemon.pokemonId}';
  }
}
