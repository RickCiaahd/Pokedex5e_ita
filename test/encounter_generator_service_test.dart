import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/encounter_collection.dart';
import 'package:pokedex_5e_ita/models/generated_encounter.dart';
import 'package:pokedex_5e_ita/models/pokemon.dart';
import 'package:pokedex_5e_ita/models/pokemon_attributes.dart';
import 'package:pokedex_5e_ita/models/pokemon_moves.dart';
import 'package:pokedex_5e_ita/services/encounter_generator_service.dart';

void main() {
  const service = EncounterGeneratorService();
  final catalog = [
    _pokemon(
      id: 19,
      name: 'Rattata',
      types: const ['Normal'],
      sr: 0.5,
      description: 'Lives in fields and cities.',
    ),
    _pokemon(
      id: 16,
      name: 'Pidgey',
      types: const ['Normal', 'Flying'],
      sr: 0.5,
      description: 'A common grassland bird.',
    ),
    _pokemon(
      id: 21,
      name: 'Spearow',
      types: const ['Normal', 'Flying'],
      sr: 0.5,
      description: 'Flies over open fields.',
    ),
    _pokemon(
      id: 41,
      name: 'Zubat',
      types: const ['Poison', 'Flying'],
      sr: 0.5,
      description: 'A bat found in caves.',
    ),
    _pokemon(
      id: 144,
      name: 'Articuno',
      types: const ['Ice', 'Flying'],
      sr: 10,
      description: 'A legendary bird of frozen mountains.',
    ),
  ];

  test('filters by habitat and excludes legendary species by default', () {
    final candidates = service.filterCandidates(
      catalog,
      const EncounterGeneratorFilters(habitat: 'Grotta'),
    );

    expect(candidates.map((pokemon) => pokemon.name), contains('Zubat'));
    expect(
      candidates.map((pokemon) => pokemon.name),
      isNot(contains('Articuno')),
    );
  });

  test('automatic generation respects the requested enemy bounds', () {
    final encounter = service.generateAutomatic(
      catalog: catalog,
      party: const EncounterPartyProfile(
        trainerCount: 2,
        activePokemon: 2,
        averageLevel: 5,
      ),
      filters: const EncounterGeneratorFilters(habitat: 'Prateria', level: 5),
      difficulty: EncounterDifficulty.medium,
      composition: EncounterComposition.mixed,
      minEnemies: 2,
      maxEnemies: 3,
      random: Random(4),
    );

    expect(encounter, isNotNull);
    expect(encounter!.members.length, inInclusiveRange(2, 3));
    expect(encounter.estimate.encounterCost, greaterThan(0));
  });

  test('manual generation creates the requested quantities', () {
    final encounter = service.generateManual(
      catalog: catalog,
      selections: const [
        EncounterManualSelection(pokemonId: 19, quantity: 2),
        EncounterManualSelection(pokemonId: 16, quantity: 1),
      ],
      party: const EncounterPartyProfile(),
      filters: const EncounterGeneratorFilters(level: 3),
      targetDifficulty: EncounterDifficulty.medium,
      random: Random(2),
    );

    expect(encounter, isNotNull);
    expect(encounter!.members, hasLength(3));
    expect(
      encounter.members
          .where((member) => member.pokemon.basePokemon.id == 19)
          .length,
      2,
    );
  });

  test('manual generation preserves the selected permanent form', () {
    final rattata = catalog.firstWhere((pokemon) => pokemon.id == 19);
    final alolan = PokemonFormDefinition(
      key: 'Alolan',
      displayName: 'Alolan',
      pokemon: rattata.copyWith(types: const ['Dark', 'Normal']),
    );
    final formCatalog = [
      rattata.copyWith(formDefinitions: [alolan]),
      ...catalog.where((pokemon) => pokemon.id != 19),
    ];

    final encounter = service.generateManual(
      catalog: formCatalog,
      selections: const [
        EncounterManualSelection(
          pokemonId: 19,
          formName: 'Alolan',
          quantity: 2,
        ),
      ],
      party: const EncounterPartyProfile(),
      filters: const EncounterGeneratorFilters(level: 3),
      targetDifficulty: EncounterDifficulty.medium,
      random: Random(8),
    );

    expect(encounter, isNotNull);
    expect(encounter!.members, hasLength(2));
    expect(
      encounter.members.every((member) => member.pokemon.formName == 'Alolan'),
      isTrue,
    );
    expect(
      encounter.members.every(
        (member) => member.pokemon.pokemon.types.contains('Dark'),
      ),
      isTrue,
    );
  });

  test('a 100 percent collection always selects its only species', () {
    final encounter = service.generateFromCollection(
      catalog: catalog,
      collection: EncounterCollection(
        id: 'route-24',
        name: 'Percorso 24',
        entries: const [EncounterCollectionEntry(pokemonId: 19, weight: 100)],
        updatedAt: DateTime(2026),
      ),
      count: 5,
      allowDuplicates: true,
      party: const EncounterPartyProfile(),
      filters: const EncounterGeneratorFilters(level: 4),
      targetDifficulty: EncounterDifficulty.medium,
      random: Random(9),
    );

    expect(encounter, isNotNull);
    expect(encounter!.members, hasLength(5));
    expect(
      encounter.members.every((member) => member.pokemon.basePokemon.id == 19),
      isTrue,
    );
  });

  test('weighted collections preserve an explicitly selected form', () {
    final rattata = catalog.firstWhere((pokemon) => pokemon.id == 19);
    final alolan = PokemonFormDefinition(
      key: 'Alolan',
      displayName: 'Alolan',
      pokemon: rattata.copyWith(types: const ['Dark', 'Normal']),
    );
    final formCatalog = [
      rattata.copyWith(formDefinitions: [alolan]),
      ...catalog.where((pokemon) => pokemon.id != 19),
    ];

    final encounter = service.generateFromCollection(
      catalog: formCatalog,
      collection: EncounterCollection(
        id: 'alola-route',
        name: 'Percorso Alola',
        entries: const [
          EncounterCollectionEntry(
            pokemonId: 19,
            formName: 'Alolan',
            weight: 100,
          ),
        ],
        updatedAt: DateTime(2026),
      ),
      count: 3,
      allowDuplicates: true,
      party: const EncounterPartyProfile(),
      filters: const EncounterGeneratorFilters(level: 4),
      targetDifficulty: EncounterDifficulty.medium,
      random: Random(11),
    );

    expect(encounter, isNotNull);
    expect(
      encounter!.members.every((member) => member.pokemon.formName == 'Alolan'),
      isTrue,
    );
  });

  test('collection generation without duplicates returns unique species', () {
    final encounter = service.generateFromCollection(
      catalog: catalog,
      collection: EncounterCollection(
        id: 'route-24',
        name: 'Percorso 24',
        entries: const [
          EncounterCollectionEntry(pokemonId: 19, weight: 50),
          EncounterCollectionEntry(pokemonId: 16, weight: 25),
          EncounterCollectionEntry(pokemonId: 21, weight: 25),
        ],
        updatedAt: DateTime(2026),
      ),
      count: 6,
      allowDuplicates: false,
      party: const EncounterPartyProfile(),
      filters: const EncounterGeneratorFilters(level: 4),
      targetDifficulty: EncounterDifficulty.medium,
      random: Random(3),
    );

    expect(encounter, isNotNull);
    final ids = encounter!.members
        .map((member) => member.pokemon.basePokemon.id)
        .toList();
    expect(ids, hasLength(3));
    expect(ids.toSet(), hasLength(3));
  });
}

Pokemon _pokemon({
  required int id,
  required String name,
  required List<String> types,
  required double sr,
  required String description,
}) {
  return Pokemon(
    id: id,
    name: name,
    types: types,
    armorClass: 12,
    hitPoints: 12,
    size: 'Small',
    speed: 9,
    attributes: const PokemonAttributes(
      strength: 10,
      dexterity: 12,
      constitution: 10,
      intelligence: 6,
      wisdom: 10,
      charisma: 8,
    ),
    abilities: const ['Keen Eye'],
    hiddenAbility: null,
    skills: const [],
    savingThrows: const [],
    moves: const PokemonMoves(
      startingMoves: ['Tackle'],
      levelMoves: {},
      tmMoves: [],
    ),
    hitDice: 6,
    sr: sr,
    minLevelFound: 1,
    description: description,
  );
}
