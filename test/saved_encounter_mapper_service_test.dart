import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/generated_encounter.dart';
import 'package:pokedex_5e_ita/models/generated_pokemon.dart';
import 'package:pokedex_5e_ita/models/pokemon.dart';
import 'package:pokedex_5e_ita/models/pokemon_attributes.dart';
import 'package:pokedex_5e_ita/models/pokemon_moves.dart';
import 'package:pokedex_5e_ita/models/saved_encounter.dart';
import 'package:pokedex_5e_ita/services/encounter_generator_service.dart';
import 'package:pokedex_5e_ita/services/saved_encounter_mapper_service.dart';

void main() {
  const mapper = SavedEncounterMapperService();
  const encounterService = EncounterGeneratorService();
  final rattata = _pokemon();

  test('saved encounter JSON preserves every generated member field', () {
    final saved = SavedEncounter(
      id: 'route-24-night',
      name: 'Percorso 24 notte',
      notes: 'Incontro vicino al ponte.',
      source: EncounterSource.collection,
      party: const EncounterPartyProfile(
        trainerCount: 2,
        activePokemon: 2,
        averageLevel: 5,
      ),
      filters: const EncounterGeneratorFilters(habitat: 'Prateria', level: 4),
      targetDifficulty: EncounterDifficulty.hard,
      members: const [
        SavedEncounterMember(
          pokemonId: 19,
          formName: 'Alolan',
          level: 4,
          gender: 'Female',
          nature: 'Jolly',
          ability: 'Gluttony',
          selectedMoves: ['Tackle', 'Quick Attack'],
          isShiny: true,
          maxHp: 22,
          isLocked: true,
        ),
      ],
      createdAt: DateTime.utc(2026, 7, 13, 10),
      updatedAt: DateTime.utc(2026, 7, 13, 11),
      collectionId: 'route-24',
      collectionName: 'Percorso 24',
    );

    final decoded = SavedEncounter.fromJson(saved.toJson());

    expect(decoded.name, saved.name);
    expect(decoded.notes, saved.notes);
    expect(decoded.source, EncounterSource.collection);
    expect(decoded.targetDifficulty, EncounterDifficulty.hard);
    expect(decoded.members.single.formName, 'Alolan');
    expect(decoded.members.single.selectedMoves, ['Tackle', 'Quick Attack']);
    expect(decoded.members.single.isLocked, isTrue);
    expect(decoded.collectionName, 'Percorso 24');
  });

  test('mapper restores an exact form and recalculates the estimate', () {
    final alolan = rattata.copyWith(types: const ['Dark', 'Normal'], sr: 1);
    final catalog = [
      rattata.copyWith(
        formDefinitions: [
          PokemonFormDefinition(
            key: 'Alolan',
            displayName: 'Alolan',
            pokemon: alolan,
          ),
        ],
      ),
    ];
    final generated = GeneratedPokemon(
      basePokemon: catalog.single,
      pokemon: alolan,
      formName: 'Alolan',
      level: 4,
      gender: 'Female',
      nature: 'Jolly',
      ability: 'Gluttony',
      selectedMoves: const ['Tackle'],
      isShiny: false,
      maxHp: 20,
    );
    final encounter = encounterService.buildEncounter(
      source: EncounterSource.manual,
      title: 'Incontro personalizzato',
      party: const EncounterPartyProfile(averageLevel: 4),
      filters: const EncounterGeneratorFilters(level: 4),
      targetDifficulty: EncounterDifficulty.medium,
      generated: [generated],
    );

    final saved = mapper.fromGenerated(
      encounter,
      name: 'Rattata di Alola',
      notes: 'Forma bloccata',
      now: DateTime.utc(2026, 7, 13),
    );
    final restored = mapper.toGenerated(saved: saved, catalog: catalog);

    expect(restored.title, 'Rattata di Alola');
    expect(restored.members.single.pokemon.formName, 'Alolan');
    expect(restored.members.single.pokemon.pokemon.types, contains('Dark'));
    expect(restored.estimate.encounterCost, greaterThan(0));
  });
}

Pokemon _pokemon() {
  return const Pokemon(
    id: 19,
    name: 'Rattata',
    types: ['Normal'],
    armorClass: 12,
    hitPoints: 12,
    size: 'Small',
    speed: 9,
    attributes: PokemonAttributes(
      strength: 7,
      dexterity: 15,
      constitution: 10,
      intelligence: 6,
      wisdom: 9,
      charisma: 8,
    ),
    abilities: ['Run Away'],
    hiddenAbility: 'Hustle',
    skills: [],
    savingThrows: [],
    moves: PokemonMoves(startingMoves: ['Tackle'], levelMoves: {}, tmMoves: []),
    hitDice: 6,
    sr: 0.5,
    minLevelFound: 1,
    description: 'A small mouse Pokémon.',
  );
}
