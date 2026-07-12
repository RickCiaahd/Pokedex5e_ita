import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/generated_pokemon.dart';
import 'package:pokedex_5e_ita/models/pokemon.dart';
import 'package:pokedex_5e_ita/models/pokemon_attributes.dart';
import 'package:pokedex_5e_ita/models/pokemon_moves.dart';
import 'package:pokedex_5e_ita/models/pokemon_type_localization.dart';
import 'package:pokedex_5e_ita/services/pokemon_generator_service.dart';

Pokemon _pokemon({
  required int id,
  required String name,
  required List<String> types,
  double sr = 0.5,
  int minLevel = 1,
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
    abilities: const ['Run Away'],
    hiddenAbility: 'Hustle',
    skills: const [],
    savingThrows: const [],
    moves: const PokemonMoves(
      startingMoves: ['Tackle', 'Tail Whip'],
      levelMoves: {
        2: ['Quick Attack'],
        4: ['Bite'],
      },
      tmMoves: [],
    ),
    hitDice: 6,
    sr: sr,
    minLevelFound: minLevel,
  );
}

void main() {
  const service = PokemonGeneratorService();

  test('deduplicates type aliases and sorts them by Italian label', () {
    final catalog = [
      _pokemon(id: 4, name: 'Charmander', types: const ['Fire']),
      _pokemon(id: 37, name: 'Vulpix', types: const ['fire']),
      _pokemon(id: 146, name: 'Moltres', types: const ['Fuoco', 'Flying']),
      _pokemon(id: 16, name: 'Pidgey', types: const ['flying']),
    ];

    expect(service.availableTypes(catalog), ['Fire', 'Flying']);
    expect(PokemonTypeLocalization.italianLabel('Fire'), 'Fuoco');
    expect(PokemonTypeLocalization.italianLabel('flying'), 'Volante');
  });

  test('accepts Italian type labels in filters and free-text search', () {
    final catalog = [
      _pokemon(id: 4, name: 'Charmander', types: const ['Fire']),
      _pokemon(id: 7, name: 'Squirtle', types: const ['Water']),
    ];

    final filteredByType = service.filterPokemon(
      catalog,
      const PokemonGeneratorFilters(type: 'Fuoco'),
    );
    final filteredByQuery = service.filterPokemon(
      catalog,
      const PokemonGeneratorFilters(query: 'acqua'),
    );

    expect(filteredByType.map((pokemon) => pokemon.name), ['Charmander']);
    expect(filteredByQuery.map((pokemon) => pokemon.name), ['Squirtle']);
  });

  test('generates one independent result for every selected species', () {
    final selected = [
      _pokemon(id: 19, name: 'Rattata', types: const ['Normal']),
      _pokemon(id: 41, name: 'Zubat', types: const ['Poison', 'Flying']),
      _pokemon(id: 74, name: 'Geodude', types: const ['Rock', 'Ground']),
    ];

    final generated = service.generateSelected(
      pokemon: selected,
      filters: const PokemonGeneratorFilters(level: 5, shinyChance: 1),
      random: Random(7),
    );

    expect(generated, hasLength(3));
    expect(generated.map((result) => result.basePokemon.id).toSet(), {
      19,
      41,
      74,
    });
    expect(generated.every((result) => result.level == 5), isTrue);
    expect(generated.every((result) => result.isShiny), isTrue);
    expect(
      generated.every((result) => result.selectedMoves.isNotEmpty),
      isTrue,
    );
  });
}
