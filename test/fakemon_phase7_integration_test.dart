import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/breeding_candidate.dart';
import 'package:pokedex_5e_ita/models/breeding_egg.dart';
import 'package:pokedex_5e_ita/models/breeding_species_data.dart';
import 'package:pokedex_5e_ita/models/custom_pokemon_definition.dart';
import 'package:pokedex_5e_ita/models/generated_encounter.dart';
import 'package:pokedex_5e_ita/models/generated_npc_trainer.dart';
import 'package:pokedex_5e_ita/models/generated_pokemon.dart';
import 'package:pokedex_5e_ita/models/pc_pokemon.dart';
import 'package:pokedex_5e_ita/models/pokemon.dart';
import 'package:pokedex_5e_ita/models/pokemon_attributes.dart';
import 'package:pokedex_5e_ita/models/trainer_manual_content.dart';
import 'package:pokedex_5e_ita/repositories/move_repository.dart';
import 'package:pokedex_5e_ita/services/breeding_service.dart';
import 'package:pokedex_5e_ita/services/custom_pokemon_runtime_registry.dart';
import 'package:pokedex_5e_ita/services/encounter_generator_service.dart';
import 'package:pokedex_5e_ita/services/npc_trainer_generator_service.dart';
import 'package:pokedex_5e_ita/services/pokemon_generator_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CustomPokemonDefinition fireDefinition;
  late CustomPokemonDefinition waterDefinition;

  setUp(() {
    fireDefinition = _definition(
      id: CustomPokemonDefinition.firstCustomPokemonId,
      stableId: 'phase7-fire',
      name: 'Pyroecho',
      type: 'Fire',
      moveType: 'Fire',
    );
    waterDefinition = _definition(
      id: CustomPokemonDefinition.firstCustomPokemonId + 1,
      stableId: 'phase7-water',
      name: 'Aquaecho',
      type: 'Water',
      moveType: 'Water',
    );
    CustomPokemonRuntimeRegistry.replaceAll([fireDefinition, waterDefinition]);
  });

  tearDown(() {
    CustomPokemonRuntimeRegistry.replaceAll(const <CustomPokemonDefinition>[]);
  });

  test(
    'risolve mosse Fakemon omonime per specie in generatori, incontri e fight',
    () async {
      final repository = MoveRepository();
      final moves = await repository.getMovesByPokemon({
        fireDefinition.pokemonId: const ['Eco Primordiale'],
        waterDefinition.pokemonId: const ['Eco Primordiale'],
      });

      expect(
        moves[MoveRepository.contextualKey(
              fireDefinition.pokemonId,
              'Eco Primordiale',
            )]
            ?.type,
        'Fire',
      );
      expect(
        moves[MoveRepository.contextualKey(
              waterDefinition.pokemonId,
              'Eco Primordiale',
            )]
            ?.type,
        'Water',
      );
    },
  );

  test(
    'Fakemon generato conserva specie, abilità e mossa passando tra cattura, squadra e PC',
    () {
      const generator = PokemonGeneratorService();
      final generated = generator.generateForPokemon(
        pokemon: fireDefinition.toPokemon(),
        filters: const PokemonGeneratorFilters(level: 5, shinyChance: 0),
        random: Random(4),
      );

      expect(generated, isNotNull);
      expect(generated!.basePokemon.id, fireDefinition.pokemonId);
      expect(generated.selectedMoves, contains('Eco Primordiale'));
      expect(generated.ability, 'Risonanza');

      final capturedSlot = generated.toTeamSlot(slotIndex: 0);
      final stored = PcPokemon.fromTeamSlot(capturedSlot);
      final restored = stored.toTeamSlot(
        slotIndex: 2,
        fallbackCurrentHp: generated.maxHp,
      );

      expect(restored.pokemonId, fireDefinition.pokemonId);
      expect(restored.selectedMoves, contains('Eco Primordiale'));
      expect(restored.abilities, ['Risonanza']);
      expect(restored.currentHp, generated.maxHp);
    },
  );

  test('incontri manuali accettano una specie Fakemon', () {
    const service = EncounterGeneratorService();
    final encounter = service.generateManual(
      catalog: [fireDefinition.toPokemon()],
      selections: [
        EncounterManualSelection(
          pokemonId: fireDefinition.pokemonId,
          quantity: 2,
        ),
      ],
      party: const EncounterPartyProfile(),
      filters: const EncounterGeneratorFilters(level: 4),
      targetDifficulty: EncounterDifficulty.medium,
      random: Random(8),
    );

    expect(encounter, isNotNull);
    expect(encounter!.members, hasLength(2));
    expect(
      encounter.members.every(
        (member) => member.pokemon.basePokemon.id == fireDefinition.pokemonId,
      ),
      isTrue,
    );
  });

  test('il generatore Allenatori PNG usa il Fakemon dal catalogo', () {
    const service = NpcTrainerGeneratorService();
    final trainer = service.generate(
      catalog: [fireDefinition.toPokemon()],
      options: const NpcTrainerGeneratorOptions(
        trainerLevel: 5,
        pokemonLevel: 5,
        teamSize: 1,
        specialization: 'Pyromaniac',
        composition: NpcTeamComposition.themed,
      ),
      specializations: const ['Pyromaniac'],
      origins: const [
        TrainerOrigin(
          name: 'Umano',
          description: '',
          abilityBonuses: {},
          skillProficiencies: [],
          savingThrowProficiencies: [],
        ),
      ],
      paths: const [TrainerPath(name: 'Ace Trainer', features: [])],
      random: Random(3),
    );

    expect(trainer, isNotNull);
    expect(trainer!.team.single.basePokemon.id, fireDefinition.pokemonId);
    expect(trainer.team.single.selectedMoves, contains('Eco Primordiale'));
  });

  test(
    'metadati di allevamento Fakemon producono compatibilità e uovo della specie corretta',
    () {
      final speciesData = BreedingDataService.mergeCustomDefinitions(
        const <int, BreedingSpeciesData>{},
        [fireDefinition, waterDefinition],
      );
      expect(speciesData[fireDefinition.pokemonId]?.eggGroups, ['Field']);

      const service = BreedingService();
      final compatibility = service.compatibility(
        first: BreedingCandidate(
          key: 'fire',
          pokemonId: fireDefinition.pokemonId,
          displayName: fireDefinition.name,
          location: 'Squadra',
          gender: 'Male',
          loyalty: 2,
          selectedMoves: const ['Eco Primordiale'],
          abilities: const ['Risonanza'],
        ),
        second: BreedingCandidate(
          key: 'water',
          pokemonId: waterDefinition.pokemonId,
          displayName: waterDefinition.name,
          location: 'PC',
          gender: 'Female',
          loyalty: 2,
          selectedMoves: const ['Eco Primordiale'],
          abilities: const ['Risonanza'],
        ),
        speciesData: speciesData,
        catalog: {
          fireDefinition.pokemonId: fireDefinition.toPokemon(),
          waterDefinition.pokemonId: waterDefinition.toPokemon(),
        },
      );

      expect(compatibility.isCompatible, isTrue);
      expect(compatibility.childSpeciesId, waterDefinition.pokemonId);

      final egg = service.createEgg(
        first: BreedingCandidate(
          key: 'fire',
          pokemonId: fireDefinition.pokemonId,
          displayName: fireDefinition.name,
          location: 'Squadra',
          gender: 'Male',
          loyalty: 2,
          selectedMoves: const ['Eco Primordiale'],
          abilities: const ['Risonanza'],
        ),
        second: BreedingCandidate(
          key: 'water',
          pokemonId: waterDefinition.pokemonId,
          displayName: waterDefinition.name,
          location: 'PC',
          gender: 'Female',
          loyalty: 2,
          selectedMoves: const ['Eco Primordiale'],
          abilities: const ['Risonanza'],
        ),
        compatibility: compatibility,
        catalog: {
          fireDefinition.pokemonId: fireDefinition.toPokemon(),
          waterDefinition.pokemonId: waterDefinition.toPokemon(),
        },
        selectedGender: 'Female',
        selectedAbility: 'Risonanza',
        random: Random(2),
      );
      expect(egg.speciesId, waterDefinition.pokemonId);
      expect(egg.selectedMoves, contains('Eco Primordiale'));
      expect(egg.ability, 'Risonanza');

      final hatchedSlot = generatedPokemonFromEgg(
        egg,
        waterDefinition.toPokemon(),
      ).toTeamSlot(slotIndex: 1);
      expect(hatchedSlot.pokemonId, waterDefinition.pokemonId);
      expect(hatchedSlot.selectedMoves, contains('Eco Primordiale'));
      expect(hatchedSlot.abilities, ['Risonanza']);
    },
  );

  test('JSON Fakemon mantiene i dati di allevamento', () {
    final restored = CustomPokemonDefinition.fromJson(fireDefinition.toJson());
    expect(restored.eggGroups, ['Field']);
    expect(restored.baseSpeciesId, fireDefinition.pokemonId);
  });
}

GeneratedPokemon generatedPokemonFromEgg(BreedingEgg egg, Pokemon pokemon) {
  return GeneratedPokemon(
    basePokemon: pokemon,
    pokemon: pokemon,
    formName: egg.formName,
    level: pokemon.minLevelFound,
    gender: egg.gender,
    nature: egg.nature,
    ability: egg.ability,
    selectedMoves: egg.selectedMoves,
    isShiny: egg.isShiny,
    maxHp: pokemon.hitPoints,
  );
}

CustomPokemonDefinition _definition({
  required int id,
  required String stableId,
  required String name,
  required String type,
  required String moveType,
}) {
  return CustomPokemonDefinition(
    formatVersion: CustomPokemonDefinition.currentFormatVersion,
    stableId: stableId,
    pokemonId: id,
    createdAt: DateTime.utc(2026, 7, 17),
    updatedAt: DateTime.utc(2026, 7, 17),
    name: name,
    author: 'Phase 7 test',
    types: [type],
    armorClass: 12,
    hitPoints: 20,
    size: 'Small',
    speed: 30,
    attributes: const PokemonAttributes(
      strength: 10,
      dexterity: 12,
      constitution: 12,
      intelligence: 8,
      wisdom: 10,
      charisma: 10,
    ),
    abilities: const ['Risonanza'],
    skills: const [],
    savingThrows: const [],
    startingMoves: const ['Eco Primordiale'],
    levelMoves: const {},
    tmMoves: const [],
    eggMoves: const ['Eco Primordiale'],
    eggGroups: const ['Field'],
    baseSpeciesId: id,
    hitDice: 6,
    sr: 1,
    minLevelFound: 1,
    genderRatio: '50% Male / 50% Female',
    localMoves: [
      CustomPokemonMoveDefinition(
        id: 'move-eco-$stableId',
        name: 'Eco Primordiale',
        type: moveType,
        pp: '10',
        range: '60 ft.',
        duration: 'Instantaneous',
        moveTime: '1 Action',
        description: 'Una mossa locale usata dal test di fase 7.',
        damageByLevel: const {1: '1d8'},
        isAttack: true,
      ),
    ],
    localAbilities: const [
      CustomPokemonAbilityDefinition(
        id: 'ability-risonanza',
        name: 'Risonanza',
        description: 'Abilità locale usata dal test.',
      ),
    ],
  );
}
