import 'package:flutter_test/flutter_test.dart';

import 'package:pokedex_5e_ita/models/breeding_egg.dart';
import 'package:pokedex_5e_ita/models/pokemon.dart';
import 'package:pokedex_5e_ita/models/pokemon_attributes.dart';
import 'package:pokedex_5e_ita/models/pokemon_moves.dart';
import 'package:pokedex_5e_ita/models/user_profile.dart';
import 'package:pokedex_5e_ita/services/breeder_feature_service.dart';

void main() {
  const service = BreederFeatureService();

  group('BreederFeatureService', () {
    test('Good Genes e Master of Traits seguono i livelli 9 e 15', () {
      expect(service.hasGoodGenes(_profile(level: 8)), isFalse);
      expect(service.hasGoodGenes(_profile(level: 9)), isTrue);
      expect(service.hasMasterOfTraits(_profile(level: 14)), isFalse);
      expect(service.hasMasterOfTraits(_profile(level: 15)), isTrue);
    });

    test('Good Genes richiede esattamente due punti e rispetta il limite 20', () {
      final pokemon = _pokemon(strength: 19, dexterity: 12);

      expect(
        service.isValidGoodGenesAllocation(
          pokemon: pokemon,
          bonuses: const {'STR': 1, 'DEX': 1},
        ),
        isTrue,
      );
      expect(
        service.isValidGoodGenesAllocation(
          pokemon: pokemon,
          bonuses: const {'STR': 2},
        ),
        isFalse,
      );
      expect(
        service.isValidGoodGenesAllocation(
          pokemon: pokemon,
          bonuses: const {'DEX': 1},
        ),
        isFalse,
      );
    });

    test('Master of Traits sostituisce soltanto Egg Moves valide', () {
      final pokemon = _pokemon(
        startingMoves: const ['Tackle', 'Leer'],
        eggMoves: const ['Quick Attack', 'Night Slash', 'Howl'],
      );

      final moves = service.applyMasterTraitEggMoves(
        child: pokemon,
        selectedMoves: const ['Tackle', 'Quick Attack', 'Leer'],
        inheritedMoves: const ['Quick Attack'],
        replacements: const ['Night Slash'],
      );

      expect(moves, containsAll(['Tackle', 'Leer', 'Night Slash']));
      expect(moves, isNot(contains('Quick Attack')));
      expect(
        () => service.applyMasterTraitEggMoves(
          child: pokemon,
          selectedMoves: const ['Tackle', 'Quick Attack'],
          inheritedMoves: const ['Quick Attack'],
          replacements: const ['Surf'],
        ),
        throwsArgumentError,
      );
    });

    test('le opzioni di sesso rispettano specie miste e genderless', () {
      expect(
        service.availableGenders(_pokemon(genderRatio: '50% Male / 50% Female')),
        ['Male', 'Female'],
      );
      expect(
        service.availableGenders(_pokemon(genderRatio: 'Genderless')),
        ['Genderless'],
      );
    });
  });

  group('BreedingEgg avanzato', () {
    test('i vecchi salvataggi ricevono 10 PF e nessuna personalizzazione', () {
      final egg = BreedingEgg.fromJson({
        'id': 'legacy',
        'speciesId': 1,
        'parentNames': <String>[],
        'createdAt': DateTime.utc(2026, 7, 14).toIso8601String(),
        'hatchTime': 100,
        'incubationRemaining': 50,
        'nature': 'Hardy',
        'selectedMoves': <String>[],
        'inheritedMoves': <String>[],
      });

      expect(egg.currentHp, BreedingEgg.maxHitPoints);
      expect(egg.masterTraitsCustomized, isFalse);
      expect(egg.isDestroyed, isFalse);
    });

    test('PF e scelte Master of Traits persistono nel JSON', () {
      final egg = _egg().copyWith(
        currentHp: 4,
        nature: 'Brave',
        gender: 'Female',
        ability: 'Rivalry',
        selectedMoves: const ['Tackle', 'Night Slash'],
        inheritedMoves: const ['Night Slash'],
        masterTraitsCustomized: true,
      );
      final decoded = BreedingEgg.fromJson(egg.toJson());

      expect(decoded.currentHp, 4);
      expect(decoded.nature, 'Brave');
      expect(decoded.gender, 'Female');
      expect(decoded.ability, 'Rivalry');
      expect(decoded.inheritedMoves, ['Night Slash']);
      expect(decoded.masterTraitsCustomized, isTrue);
    });

    test('gli incubatori espongono gli item consumabili corretti', () {
      expect(EggIncubator.basic.inventoryItemId, 'egg-incubator-basic');
      expect(EggIncubator.plus.inventoryItemId, 'egg-incubator-plus');
      expect(
        EggIncubator.superIncubator.inventoryItemId,
        'egg-incubator-super',
      );
      expect(EggIncubator.none.inventoryItemId, isNull);
    });
  });
}

UserProfile _profile({required int level}) {
  final now = DateTime.utc(2026, 7, 14);
  return UserProfile(
    id: 'profile',
    name: 'Breeder',
    createdAt: now,
    updatedAt: now,
    trainerLevel: level,
    trainerPath: 'Pokémon Breeder',
  );
}

Pokemon _pokemon({
  int strength = 10,
  int dexterity = 10,
  String? genderRatio,
  List<String> startingMoves = const [],
  List<String> eggMoves = const [],
}) {
  return Pokemon(
    id: 1,
    name: 'Testmon',
    types: const ['Normal'],
    armorClass: 10,
    hitPoints: 8,
    size: 'Small',
    speed: 30,
    attributes: PokemonAttributes(
      strength: strength,
      dexterity: dexterity,
      constitution: 10,
      intelligence: 10,
      wisdom: 10,
      charisma: 10,
    ),
    abilities: const ['Ability One', 'Ability Two'],
    hiddenAbility: null,
    skills: const [],
    savingThrows: const [],
    moves: PokemonMoves(
      startingMoves: startingMoves,
      levelMoves: const {},
      tmMoves: const [],
      eggMoves: eggMoves,
    ),
    hitDice: 6,
    sr: 0.25,
    minLevelFound: 1,
    genderRatio: genderRatio,
  );
}

BreedingEgg _egg() {
  return BreedingEgg(
    id: 'egg',
    speciesId: 1,
    parentNames: const ['Parent A', 'Parent B'],
    createdAt: DateTime.utc(2026, 7, 14),
    hatchTime: 100,
    incubationRemaining: 50,
    nature: 'Hardy',
    gender: 'Male',
    ability: 'Ability One',
    selectedMoves: const ['Tackle'],
    inheritedMoves: const [],
  );
}
