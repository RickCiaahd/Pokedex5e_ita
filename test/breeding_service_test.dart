import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:pokedex_5e_ita/models/breeding_candidate.dart';
import 'package:pokedex_5e_ita/models/breeding_egg.dart';
import 'package:pokedex_5e_ita/models/breeding_species_data.dart';
import 'package:pokedex_5e_ita/models/pokemon.dart';
import 'package:pokedex_5e_ita/models/pokemon_attributes.dart';
import 'package:pokedex_5e_ita/models/pokemon_moves.dart';
import 'package:pokedex_5e_ita/models/team_slot.dart';
import 'package:pokedex_5e_ita/models/user_profile.dart';
import 'package:pokedex_5e_ita/services/breeding_service.dart';

void main() {
  const service = BreedingService();

  test('accetta sesso opposto, Lealtà +2 e Gruppo Uova condiviso', () {
    final result = service.compatibility(
      first: _candidate('a', gender: 'Male', pokemonId: 1),
      second: _candidate('b', gender: 'Female', pokemonId: 2),
      speciesData: {
        1: _species(1, ['Monster'], base: 1),
        2: _species(2, ['Monster'], base: 1),
      },
      catalog: {1: _pokemon(1), 2: _pokemon(2)},
    );

    expect(result.isCompatible, isTrue);
    expect(result.childSpeciesId, 1);
    expect(result.sharedEggGroups, ['Monster']);
  });

  test('rifiuta Lealtà insufficiente e stesso sesso', () {
    final result = service.compatibility(
      first: _candidate('a', gender: 'Male', pokemonId: 1, loyalty: 1),
      second: _candidate('b', gender: 'Male', pokemonId: 2),
      speciesData: {
        1: _species(1, ['Field'], base: 1),
        2: _species(2, ['Field'], base: 2),
      },
      catalog: {1: _pokemon(1), 2: _pokemon(2)},
    );

    expect(result.isCompatible, isFalse);
    expect(result.errors.join(' '), contains('Lealtà'));
    expect(result.errors.join(' '), contains('maschio'));
  });

  test('Ditto ignora sesso e Gruppo Uova ma non può accoppiarsi con Ditto', () {
    final accepted = service.compatibility(
      first: _candidate('ditto', gender: 'Genderless', pokemonId: 132),
      second: _candidate('other', gender: 'Male', pokemonId: 25),
      speciesData: {
        132: _species(132, ['Ditto'], base: 132),
        25: _species(25, ['Field', 'Fairy'], base: 172),
      },
      catalog: {25: _pokemon(25), 132: _pokemon(132), 172: _pokemon(172)},
    );
    expect(accepted.isCompatible, isTrue);
    expect(accepted.childSpeciesId, 172);

    final rejected = service.compatibility(
      first: _candidate('ditto-a', gender: 'Genderless', pokemonId: 132),
      second: _candidate('ditto-b', gender: 'Genderless', pokemonId: 132),
      speciesData: {
        132: _species(132, ['Ditto'], base: 132),
      },
      catalog: {132: _pokemon(132)},
    );
    expect(rejected.isCompatible, isFalse);
  });

  test('calcola CD e tempi di schiusa dalla tabella del manuale', () {
    expect(service.successDc(4), 19);
    expect(service.successDc(5), 18);
    expect(service.successDc(6), 17);
    expect(service.hatchTimeForSr(0.125), 125);
    expect(service.hatchTimeForSr(0.25), 250);
    expect(service.hatchTimeForSr(0.5), 500);
    expect(service.hatchTimeForSr(1), 600);
    expect(service.hatchTimeForSr(7), 1200);
    expect(service.hatchTimeForSr(15), 2000);
  });

  test('Pokémon Breeder applica WIS al tentativo e vantaggio al d100', () {
    final profile = _profile(path: 'Pokémon Breeder', level: 5, wisdom: 16);
    expect(service.breedingRollModifier(profile), 3);
    expect(service.hasIncubationAdvantage(profile), isTrue);

    final egg = BreedingEgg(
      id: 'egg',
      speciesId: 1,
      parentNames: const ['A', 'B'],
      createdAt: DateTime(2026),
      hatchTime: 500,
      incubationRemaining: 500,
      nature: 'Hardy',
      gender: 'Male',
      ability: null,
      selectedMoves: const [],
      inheritedMoves: const [],
      incubator: EggIncubator.superIncubator,
    );
    final result = service.advanceIncubation(
      egg: egg,
      profile: profile,
      random: Random(7),
    );
    expect(result.d100Rolls, hasLength(2));
    expect(result.incubatorRolls, hasLength(3));
    expect(result.egg.incubationRemaining, lessThan(500));
  });

  test('ignora gli slot vuoti non ancora sbloccati alla schiusa', () {
    final team = [
      TeamSlot(slotIndex: 0, pokemonId: 1),
      TeamSlot(slotIndex: 1, pokemonId: 2),
      TeamSlot(slotIndex: 2, pokemonId: 3),
      TeamSlot(slotIndex: 3, pokemonId: null),
      TeamSlot(slotIndex: 4, pokemonId: null),
      TeamSlot(slotIndex: 5, pokemonId: null),
    ];

    expect(
      service.firstFreeUnlockedTeamSlot(team: team, unlockedPokeslots: 3),
      isNull,
    );
    expect(
      service.firstFreeUnlockedTeamSlot(team: team, unlockedPokeslots: 4)?.slotIndex,
      3,
    );
  });

  test('individua Pokémon rimasti per errore in slot bloccati', () {
    final team = [
      TeamSlot(slotIndex: 0, pokemonId: 1),
      TeamSlot(slotIndex: 1, pokemonId: 2),
      TeamSlot(slotIndex: 2, pokemonId: 3),
      TeamSlot(slotIndex: 3, pokemonId: 403),
      TeamSlot(slotIndex: 4, pokemonId: null),
      TeamSlot(slotIndex: 5, pokemonId: null),
    ];

    final locked = service.occupiedLockedTeamSlots(
      team: team,
      unlockedPokeslots: 3,
    );

    expect(locked, hasLength(1));
    expect(locked.single.slotIndex, 3);
    expect(locked.single.pokemonId, 403);
  });
}

BreedingCandidate _candidate(
  String key, {
  required String gender,
  required int pokemonId,
  int loyalty = 2,
}) {
  return BreedingCandidate(
    key: key,
    pokemonId: pokemonId,
    displayName: key,
    location: 'Squadra',
    gender: gender,
    loyalty: loyalty,
    selectedMoves: const [],
    abilities: const [],
  );
}

BreedingSpeciesData _species(int id, List<String> groups, {required int base}) {
  return BreedingSpeciesData(
    speciesId: id,
    eggGroups: groups,
    baseSpeciesId: base,
    isBaby: false,
    isLegendary: false,
    isMythical: false,
  );
}

Pokemon _pokemon(int id) {
  return Pokemon(
    id: id,
    name: 'Pokemon $id',
    types: const ['Normal'],
    armorClass: 10,
    hitPoints: 10,
    size: 'Tiny',
    speed: 30,
    attributes: const PokemonAttributes(
      strength: 10,
      dexterity: 10,
      constitution: 10,
      intelligence: 10,
      wisdom: 10,
      charisma: 10,
    ),
    abilities: const ['Ability'],
    hiddenAbility: null,
    skills: const [],
    savingThrows: const [],
    moves: const PokemonMoves(
      startingMoves: ['Tackle'],
      levelMoves: {},
      tmMoves: [],
      eggMoves: [],
    ),
    hitDice: 6,
    sr: 0.25,
    minLevelFound: 1,
  );
}

UserProfile _profile({
  required String path,
  required int level,
  required int wisdom,
}) {
  final now = DateTime(2026);
  return UserProfile(
    id: 'profile',
    name: 'Trainer',
    createdAt: now,
    updatedAt: now,
    trainerLevel: level,
    trainerPath: path,
    abilityScores: {
      'STR': 10,
      'DEX': 10,
      'CON': 10,
      'INT': 10,
      'WIS': wisdom,
      'CHA': 10,
    },
  );
}
