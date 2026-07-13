import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/generated_encounter.dart';
import 'package:pokedex_5e_ita/models/generated_npc_trainer.dart';
import 'package:pokedex_5e_ita/models/generated_pokemon.dart';
import 'package:pokedex_5e_ita/models/master_battle_session.dart';
import 'package:pokedex_5e_ita/models/pokemon.dart';
import 'package:pokedex_5e_ita/models/pokemon_attributes.dart';
import 'package:pokedex_5e_ita/models/pokemon_moves.dart';
import 'package:pokedex_5e_ita/models/saved_npc_trainer.dart';
import 'package:pokedex_5e_ita/services/master_battle_service.dart';
import 'package:pokedex_5e_ita/services/saved_npc_trainer_mapper_service.dart';

void main() {
  const mapper = SavedNpcTrainerMapperService();
  const battleService = MasterBattleService();
  final rattata = _pokemon(19, 'Rattata');
  final pidgey = _pokemon(16, 'Pidgey');

  test('saved NPC trainer JSON preserves identity and complete team', () {
    final generated = _generatedTrainer(rattata, pidgey);
    final saved = mapper.fromGenerated(
      generated,
      name: 'Marco',
      notes: 'Capopalestra del quartiere nord.',
      now: DateTime.utc(2026, 7, 13),
    );

    final decoded = SavedNpcTrainer.fromJson(saved.toJson());

    expect(decoded.name, 'Marco');
    expect(decoded.epithet, generated.epithet);
    expect(decoded.rank, NpcTrainerRank.expert);
    expect(decoded.team, hasLength(2));
    expect(decoded.team.first.pokemonId, 19);
    expect(decoded.team.first.selectedMoves, ['Tackle']);
    expect(decoded.notes, contains('quartiere nord'));
  });

  test('saved NPC trainer mapper restores generated Pokémon', () {
    final generated = _generatedTrainer(rattata, pidgey);
    final saved = mapper.fromGenerated(generated);
    final restored = mapper.toGenerated(
      saved: saved,
      catalog: [rattata, pidgey],
    );

    expect(restored.displayName, generated.displayName);
    expect(restored.team, hasLength(2));
    expect(restored.team.first.basePokemon.id, 19);
    expect(restored.team.last.level, 5);
  });

  test(
    'master fight supports multiple trainers with independent active teams',
    () {
      final first = mapper.fromGenerated(
        _generatedTrainer(rattata, pidgey),
        name: 'Marco',
        now: DateTime.utc(2026, 7, 13, 10),
      );
      final second = mapper.fromGenerated(
        _generatedTrainer(pidgey, rattata),
        name: 'Lucia',
        now: DateTime.utc(2026, 7, 13, 11),
      );

      final session = battleService.createSession(
        profileId: 'profile-1',
        trainers: [first, second],
        activeCounts: {first.id: 2, second.id: 1},
        catalog: [rattata, pidgey],
        random: Random(4),
      );

      expect(session.participants, hasLength(2));
      expect(session.participants.first.activeSlotIndices, hasLength(2));
      expect(session.participants.last.activeSlotIndices, hasLength(1));
      expect(session.initiativeEntries, hasLength(3));
      expect(
        session.initiativeEntries.map((entry) => entry.id).toSet(),
        hasLength(3),
      );
    },
  );

  test('wild encounter starts a temporary Master fight', () {
    final rattataGenerated = _generatedPokemon(rattata);
    final shinyPidgey = GeneratedPokemon(
      basePokemon: pidgey,
      pokemon: pidgey,
      formName: null,
      level: 7,
      gender: 'Female',
      nature: 'Jolly',
      ability: 'Keen Eye',
      selectedMoves: const ['Tackle', 'Gust'],
      isShiny: true,
      maxHp: 27,
    );
    final encounter = GeneratedEncounter(
      id: 'encounter-1',
      source: EncounterSource.automatic,
      title: 'Branco sul sentiero',
      party: const EncounterPartyProfile(
        trainerCount: 2,
        activePokemon: 2,
        averageLevel: 6,
      ),
      filters: const EncounterGeneratorFilters(level: 6),
      targetDifficulty: EncounterDifficulty.medium,
      members: [
        EncounterMember(pokemon: rattataGenerated),
        EncounterMember(pokemon: shinyPidgey),
      ],
      estimate: const EncounterEstimate(
        partyBudget: 8,
        encounterCost: 8,
        difficulty: EncounterDifficulty.medium,
        targetDifficulty: EncounterDifficulty.medium,
      ),
      createdAt: DateTime.utc(2026, 7, 14),
    );

    final session = battleService.createWildSession(
      profileId: 'profile-1',
      encounter: encounter,
      activeCount: 2,
      catalog: [rattata, pidgey],
      random: Random(7),
    );

    expect(session.participants, hasLength(1));
    final wildGroup = session.participants.single;
    expect(wildGroup.name, 'Branco sul sentiero');
    expect(wildGroup.epithet, 'Incontro selvatico');
    expect(wildGroup.activeSlotIndices, {0, 1});
    expect(wildGroup.team, hasLength(2));
    expect(wildGroup.team.first.pokemon.pokemonId, 19);
    expect(wildGroup.team.last.pokemon.isShiny, isTrue);
    expect(wildGroup.team.last.pokemon.level, 7);
    expect(wildGroup.team.last.pokemon.selectedMoves, ['Tackle', 'Gust']);
    expect(wildGroup.team.last.currentHp, 27);
    expect(session.initiativeEntries, hasLength(2));

    final decoded = MasterBattleSession.fromJson(session.toJson());
    expect(decoded.participants.single.team.last.pokemon.isShiny, isTrue);
    expect(decoded.participants.single.activeSlotIndices, {0, 1});
  });

  test('master battle session JSON preserves HP, PP and statuses', () {
    final saved = mapper.fromGenerated(
      _generatedTrainer(rattata, pidgey),
      now: DateTime.utc(2026, 7, 13),
    );
    final session = battleService.createSession(
      profileId: 'profile-1',
      trainers: [saved],
      activeCounts: {saved.id: 1},
      catalog: [rattata, pidgey],
      random: Random(2),
    );
    final participant = session.participants.single;
    final damaged = participant.team.first.copyWith(
      currentHp: 3,
      nonVolatileStatus: 'Poisoned',
      volatileStatuses: const {'Confused'},
      remainingPp: const {'tackle': 7},
    );
    final updated = session.copyWith(
      participants: [
        participant.copyWith(team: [damaged, participant.team.last]),
      ],
    );

    final decoded = MasterBattleSession.fromJson(updated.toJson());
    final state = decoded.participants.single.team.first;

    expect(state.currentHp, 3);
    expect(state.nonVolatileStatus, 'Poisoned');
    expect(state.volatileStatuses, contains('Confused'));
    expect(state.remainingPp['tackle'], 7);
  });
}

GeneratedNpcTrainer _generatedTrainer(Pokemon first, Pokemon second) {
  return GeneratedNpcTrainer(
    name: 'Allenatore',
    epithet: 'Esperto Normale',
    trainerLevel: 5,
    rank: NpcTrainerRank.expert,
    origin: 'Viaggiatore',
    path: 'Ace Trainer',
    specializations: const ['Team Player'],
    preferredType: 'Normal',
    personality: 'Calmo e metodico.',
    motivation: 'Dimostrare il proprio valore.',
    quirk: 'Conta ogni turno ad alta voce.',
    openingLine: 'Vediamo cosa sai fare.',
    tactics: 'Conserva il Pokémon più resistente per la fine.',
    rewardMoney: 1200,
    rewards: const ['Potion'],
    team: [_generatedPokemon(first), _generatedPokemon(second)],
    options: const NpcTrainerGeneratorOptions(
      trainerLevel: 5,
      pokemonLevel: 5,
      teamSize: 2,
      rank: NpcTrainerRank.expert,
    ),
    generatedAt: DateTime.utc(2026, 7, 13),
  );
}

GeneratedPokemon _generatedPokemon(Pokemon pokemon) {
  return GeneratedPokemon(
    basePokemon: pokemon,
    pokemon: pokemon,
    formName: null,
    level: 5,
    gender: 'Male',
    nature: 'Hardy',
    ability: 'Run Away',
    selectedMoves: const ['Tackle'],
    isShiny: false,
    maxHp: 20,
  );
}

Pokemon _pokemon(int id, String name) {
  return Pokemon(
    id: id,
    name: name,
    types: const ['Normal'],
    armorClass: 12,
    hitPoints: 12,
    size: 'Small',
    speed: 9,
    attributes: const PokemonAttributes(
      strength: 7,
      dexterity: 15,
      constitution: 10,
      intelligence: 6,
      wisdom: 9,
      charisma: 8,
    ),
    abilities: const ['Run Away'],
    hiddenAbility: 'Hustle',
    skills: const [],
    savingThrows: const [],
    moves: const PokemonMoves(
      startingMoves: ['Tackle'],
      levelMoves: {},
      tmMoves: [],
    ),
    hitDice: 6,
    sr: 0.5,
    minLevelFound: 1,
  );
}
