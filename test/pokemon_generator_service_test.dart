import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/generated_pokemon.dart';
import 'package:pokedex_5e_ita/models/level_progression.dart';
import 'package:pokedex_5e_ita/models/pokemon.dart';
import 'package:pokedex_5e_ita/models/pokemon_attributes.dart';
import 'package:pokedex_5e_ita/models/pokemon_moves.dart';
import 'package:pokedex_5e_ita/services/pokemon_generator_service.dart';

Pokemon _pokemon({
  required int id,
  required String name,
  required List<String> types,
  required double sr,
  required int minLevel,
  List<PokemonFormDefinition> forms = const [],
}) {
  return Pokemon(
    id: id,
    name: name,
    types: types,
    armorClass: 12,
    hitPoints: 18,
    size: 'Tiny',
    speed: 30,
    attributes: const PokemonAttributes(
      strength: 8,
      dexterity: 14,
      constitution: 12,
      intelligence: 6,
      wisdom: 10,
      charisma: 8,
    ),
    abilities: const ['Run Away', 'Guts'],
    hiddenAbility: 'Hustle',
    skills: const [],
    savingThrows: const [],
    moves: const PokemonMoves(
      startingMoves: ['Tackle', 'Tail Whip'],
      levelMoves: {
        2: ['Quick Attack'],
        4: ['Bite'],
        8: ['Crunch'],
      },
      tmMoves: [],
    ),
    hitDice: 6,
    sr: sr,
    minLevelFound: minLevel,
    formDefinitions: forms,
  );
}

void main() {
  const service = PokemonGeneratorService();

  test('filters by query, type, SR, generation and available level', () {
    final catalog = [
      _pokemon(
        id: 19,
        name: 'Rattata',
        types: const ['Normal'],
        sr: 0.25,
        minLevel: 1,
      ),
      _pokemon(
        id: 152,
        name: 'Chikorita',
        types: const ['Grass'],
        sr: 0.5,
        minLevel: 2,
      ),
      _pokemon(
        id: 906,
        name: 'Sprigatito',
        types: const ['Grass'],
        sr: 0.5,
        minLevel: 3,
      ),
    ];

    final filtered = service.filterPokemon(
      catalog,
      const PokemonGeneratorFilters(
        query: 'chiko',
        type: 'Grass',
        minSr: 0.25,
        maxSr: 1,
        minGeneration: 2,
        maxGeneration: 2,
        level: 2,
      ),
    );

    expect(filtered.map((pokemon) => pokemon.name), ['Chikorita']);
  });

  test('generates a legal permanent form and level-ready moves', () {
    final alolan = _pokemon(
      id: 19,
      name: 'Rattata',
      types: const ['Dark', 'Normal'],
      sr: 0.5,
      minLevel: 1,
    );
    final mega = _pokemon(
      id: 19,
      name: 'Rattata',
      types: const ['Dark'],
      sr: 3,
      minLevel: 1,
    );
    final rattata = _pokemon(
      id: 19,
      name: 'Rattata',
      types: const ['Normal'],
      sr: 0.25,
      minLevel: 1,
      forms: [
        PokemonFormDefinition(
          key: 'alolan',
          displayName: 'Alolan',
          pokemon: alolan,
        ),
        PokemonFormDefinition(
          key: 'mega',
          displayName: 'Mega',
          pokemon: mega,
        ),
      ],
    );

    final generated = service.generate(
      pokemon: [rattata],
      filters: const PokemonGeneratorFilters(
        level: 5,
        includeForms: true,
        shinyChance: 1,
      ),
      random: Random(4),
    );

    expect(generated, isNotNull);
    expect(generated!.formName, anyOf(isNull, 'Alolan'));
    expect(generated.formName, isNot('Mega'));
    expect(generated.level, 5);
    expect(generated.experience, LevelProgression.thresholdForLevel(5));
    expect(generated.selectedMoves, hasLength(4));
    expect(generated.selectedMoves, isNot(contains('Crunch')));
    expect(generated.isShiny, isTrue);
    expect(generated.nature, isNot('No Nature'));
    expect(generated.maxHp, greaterThan(0));
  });

  test('includes types from permanent forms in the filter catalog', () {
    final alolan = _pokemon(
      id: 19,
      name: 'Rattata',
      types: const ['Dark', 'Normal'],
      sr: 0.5,
      minLevel: 1,
    );
    final rattata = _pokemon(
      id: 19,
      name: 'Rattata',
      types: const ['Normal'],
      sr: 0.25,
      minLevel: 1,
      forms: [
        PokemonFormDefinition(
          key: 'alolan',
          displayName: 'Alolan',
          pokemon: alolan,
        ),
      ],
    );

    expect(service.availableTypes([rattata]), containsAll(['Normal', 'Dark']));
    expect(service.generationForPokemonId(19), 1);
    expect(service.generationForPokemonId(906), 9);
  });
}
