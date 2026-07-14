import 'package:flutter_test/flutter_test.dart';

import 'package:pokedex_5e_ita/models/breeding_candidate.dart';
import 'package:pokedex_5e_ita/models/breeding_egg.dart';
import 'package:pokedex_5e_ita/models/pokemon.dart';
import 'package:pokedex_5e_ita/models/pokemon_attributes.dart';
import 'package:pokedex_5e_ita/models/pokemon_moves.dart';
import 'package:pokedex_5e_ita/models/user_profile.dart';
import 'package:pokedex_5e_ita/services/breeding_service.dart';

void main() {
  const service = BreedingService();

  test('riconosce Good Genes e Master of Traits ai livelli corretti', () {
    expect(service.hasGoodGenes(_profile(level: 8)), isFalse);
    expect(service.hasGoodGenes(_profile(level: 9)), isTrue);
    expect(service.hasMasterOfTraits(_profile(level: 14)), isFalse);
    expect(service.hasMasterOfTraits(_profile(level: 15)), isTrue);
  });

  test(
    'Master of Traits sostituisce solo il numero di Egg Moves ereditate',
    () {
      final child = _pokemon();
      final result = service.createEgg(
        first: _candidate('A', moves: const ['Quick Attack', 'Tackle']),
        second: _candidate('B', moves: const ['Tackle']),
        compatibility: const BreedingCompatibility(
          errors: [],
          sharedEggGroups: ['Field'],
          childSpeciesId: 1,
        ),
        catalog: {1: child},
        selectedGender: 'Female',
        selectedNature: 'Reckless',
        selectedAbility: 'Second Ability',
        replacementEggMoves: const ['Wish', 'Fake Tears'],
        masterOfTraitsApplied: true,
      );

      expect(result.gender, 'Female');
      expect(result.nature, 'Reckless');
      expect(result.ability, 'Second Ability');
      expect(result.masterOfTraitsApplied, isTrue);
      expect(result.inheritedMoves, contains('Wish'));
      expect(result.inheritedMoves, isNot(contains('Fake Tears')));
      expect(result.inheritedMoves, contains('Tackle'));
    },
  );

  test('il modello uovo conserva PF e scelte Good Genes nei backup', () {
    final egg = BreedingEgg(
      id: 'egg',
      speciesId: 1,
      parentNames: const ['A', 'B'],
      createdAt: DateTime(2026),
      hatchTime: 250,
      incubationRemaining: 0,
      nature: 'Bold',
      gender: 'Female',
      ability: 'Ability',
      selectedMoves: const ['Tackle'],
      inheritedMoves: const ['Tackle'],
      currentHp: 6,
      goodGenesAbilityBonuses: const {'CON': 2},
      masterOfTraitsApplied: true,
      incubator: EggIncubator.plus,
    );

    final restored = BreedingEgg.fromJson(egg.toJson());
    expect(restored.currentHp, 6);
    expect(restored.goodGenesAbilityBonuses, {'CON': 2});
    expect(restored.masterOfTraitsApplied, isTrue);
    expect(restored.incubator, EggIncubator.plus);
  });

  test('gli incubatori espongono costo, oggetto e dadi del manuale', () {
    expect(EggIncubator.basic.extraD20, 1);
    expect(EggIncubator.basic.cost, 1000);
    expect(EggIncubator.plus.extraD20, 2);
    expect(EggIncubator.plus.cost, 3000);
    expect(EggIncubator.superIncubator.extraD20, 3);
    expect(EggIncubator.superIncubator.cost, 10000);
    expect(EggIncubator.basic.itemId, 'egg-incubator');
    expect(EggIncubator.plus.itemId, 'egg-incubator-plus');
    expect(EggIncubator.superIncubator.itemId, 'egg-incubator-super');
  });
}

BreedingCandidate _candidate(String name, {required List<String> moves}) {
  return BreedingCandidate(
    key: name,
    pokemonId: 1,
    displayName: name,
    location: 'Squadra',
    gender: name == 'A' ? 'Female' : 'Male',
    loyalty: 2,
    selectedMoves: moves,
    abilities: const ['Ability'],
  );
}

Pokemon _pokemon() {
  return const Pokemon(
    id: 1,
    name: 'Testmon',
    types: ['Normal'],
    armorClass: 10,
    hitPoints: 10,
    size: 'Tiny',
    speed: 30,
    attributes: PokemonAttributes(
      strength: 10,
      dexterity: 10,
      constitution: 10,
      intelligence: 10,
      wisdom: 10,
      charisma: 10,
    ),
    abilities: ['Ability', 'Second Ability'],
    hiddenAbility: 'Hidden Ability',
    skills: [],
    savingThrows: [],
    moves: PokemonMoves(
      startingMoves: ['Tackle'],
      levelMoves: {
        5: ['Tackle'],
      },
      tmMoves: [],
      eggMoves: ['Quick Attack', 'Wish', 'Fake Tears'],
    ),
    hitDice: 6,
    sr: 0.25,
    minLevelFound: 1,
    genderRatio: '50% Male, 50% Female',
  );
}

UserProfile _profile({required int level}) {
  final now = DateTime(2026);
  return UserProfile(
    id: 'profile',
    name: 'Breeder',
    createdAt: now,
    updatedAt: now,
    trainerLevel: level,
    trainerPath: 'Pokémon Breeder',
  );
}
