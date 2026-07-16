import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pokedex_5e_ita/models/campaign_transfer_bundle.dart';
import 'package:pokedex_5e_ita/models/custom_pokemon_definition.dart';
import 'package:pokedex_5e_ita/models/generated_encounter.dart';
import 'package:pokedex_5e_ita/models/pokemon_attributes.dart';
import 'package:pokedex_5e_ita/models/pokemon_transfer_bundle.dart';
import 'package:pokedex_5e_ita/models/saved_encounter.dart';
import 'package:pokedex_5e_ita/models/team_slot.dart';
import 'package:pokedex_5e_ita/repositories/custom_pokemon_repository.dart';
import 'package:pokedex_5e_ita/services/campaign_transfer_service.dart';
import 'package:pokedex_5e_ita/services/custom_pokemon_transfer_service.dart';
import 'package:pokedex_5e_ita/services/embedded_custom_pokemon_transfer_service.dart';
import 'package:pokedex_5e_ita/services/pokemon_transfer_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;
  late CustomPokemonRepository repository;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'pokedex_portable_fakemon_',
    );
    Hive.init(hiveDirectory.path);
    CustomPokemonRepository.markStorageReady();
    repository = CustomPokemonRepository();
  });

  tearDown(() async {
    await Hive.close();
    CustomPokemonRepository.markStorageUnavailable();
    await hiveDirectory.delete(recursive: true);
  });

  test('il trasferimento di un Pokémon incorpora la specie Fakemon', () async {
    final definition = _definition(
      stableId: 'fakemon-lunavolt',
      pokemonId: CustomPokemonDefinition.firstCustomPokemonId,
      name: 'Lunavolt',
    );
    await repository.save(definition);

    final service = PokemonTransferService(
      embeddedCustomPokemonService: _embedded(repository),
    );
    final draft = PokemonTransferBundle.single(
      slot: TeamSlot(slotIndex: 0, pokemonId: definition.pokemonId),
      sourceTrainerName: 'Riccardo',
      exportedAt: DateTime.utc(2026, 7, 16),
    );

    final decoded = service.decode(await service.encodePortable(draft));

    expect(decoded.formatVersion, PokemonTransferBundle.currentFormatVersion);
    expect(decoded.customPokemon, hasLength(1));
    expect(decoded.customPokemon.single.stableId, definition.stableId);
    expect(decoded.customPokemon.single.imageBytes, isNotNull);
  });

  test('un incontro incorpora una sola volta ogni Fakemon usato', () async {
    final definition = _definition(
      stableId: 'fakemon-lunavolt',
      pokemonId: CustomPokemonDefinition.firstCustomPokemonId,
      name: 'Lunavolt',
    );
    await repository.save(definition);

    final encounter = SavedEncounter(
      id: 'encounter-1',
      name: 'Prova Fakemon',
      source: EncounterSource.manual,
      party: const EncounterPartyProfile(),
      filters: const EncounterGeneratorFilters(),
      targetDifficulty: EncounterDifficulty.medium,
      members: [
        for (var index = 0; index < 2; index++)
          SavedEncounterMember(
            pokemonId: definition.pokemonId,
            level: 5,
            nature: 'Hardy',
            selectedMoves: const ['Scarica Astrale'],
            isShiny: false,
            maxHp: 30,
          ),
      ],
      createdAt: DateTime.utc(2026, 7, 16),
      updatedAt: DateTime.utc(2026, 7, 16),
    );
    final service = CampaignTransferService(
      embeddedCustomPokemonService: _embedded(repository),
    );
    final draft = CampaignTransferBundle.forEncounter(
      encounter: encounter,
      sourceProfileName: 'Master',
    );

    final decoded = service.decode(await service.encodePortable(draft));

    expect(decoded.formatVersion, CampaignTransferBundle.currentFormatVersion);
    expect(decoded.customPokemon, hasLength(1));
    expect(decoded.customPokemon.single.name, 'Lunavolt');
  });

  test('un conflitto numerico rimappa la specie importata', () async {
    final existing = _definition(
      stableId: 'fakemon-esistente',
      pokemonId: CustomPokemonDefinition.firstCustomPokemonId,
      name: 'Esistente',
    );
    final incoming = _definition(
      stableId: 'fakemon-importato',
      pokemonId: CustomPokemonDefinition.firstCustomPokemonId,
      name: 'Importato',
    );
    await repository.save(existing);

    final result = await _embedded(repository).installDefinitions([incoming]);

    expect(result.remapped, 1);
    expect(
      result.resolvePokemonId(incoming.pokemonId),
      isNot(incoming.pokemonId),
    );
    final imported = await repository.getByStableId(incoming.stableId);
    expect(imported, isNotNull);
    expect(imported!.pokemonId, result.resolvePokemonId(incoming.pokemonId));
  });

  test('i trasferimenti versione 1 restano importabili', () {
    final legacy = PokemonTransferBundle.fromJson({
      'application': PokemonTransferBundle.applicationId,
      'formatVersion': 1,
      'kind': 'pokemon',
      'exportedAt': DateTime.utc(2026, 7, 1).toIso8601String(),
      'sourceTrainerName': 'Legacy',
      'pokemon': [
        TeamSlot(slotIndex: 0, pokemonId: 25).toJson(),
      ],
    });

    expect(legacy.formatVersion, 1);
    expect(legacy.customPokemon, isEmpty);
    expect(legacy.pokemon.single.pokemonId, 25);
  });
}

EmbeddedCustomPokemonTransferService _embedded(
  CustomPokemonRepository repository,
) {
  return EmbeddedCustomPokemonTransferService(
    repository: repository,
    transferService: CustomPokemonTransferService(repository: repository),
  );
}

CustomPokemonDefinition _definition({
  required String stableId,
  required int pokemonId,
  required String name,
}) {
  return CustomPokemonDefinition(
    formatVersion: CustomPokemonDefinition.currentFormatVersion,
    stableId: stableId,
    pokemonId: pokemonId,
    createdAt: DateTime.utc(2026, 7, 16),
    updatedAt: DateTime.utc(2026, 7, 16),
    name: name,
    author: 'Test',
    types: const ['Electric'],
    armorClass: 13,
    hitPoints: 30,
    size: 'Medium',
    speed: 30,
    attributes: const PokemonAttributes(
      strength: 10,
      dexterity: 14,
      constitution: 12,
      intelligence: 11,
      wisdom: 13,
      charisma: 15,
    ),
    abilities: const ['Conduttore Lunare'],
    skills: const [],
    savingThrows: const [],
    startingMoves: const ['Scarica Astrale'],
    levelMoves: const {},
    tmMoves: const [],
    eggMoves: const [],
    hitDice: 4,
    sr: 1,
    minLevelFound: 1,
    imageMimeType: 'image/png',
    imageBase64: 'AQIDBA==',
    localMoves: const [
      CustomPokemonMoveDefinition(
        id: 'move-scarica-astrale',
        name: 'Scarica Astrale',
        type: 'Electric',
        pp: '10',
        range: '60 ft.',
        duration: 'Instantaneous',
        moveTime: '1 Action',
        description: 'Una scarica di energia astrale.',
        damageByLevel: {1: '2d6'},
        isAttack: true,
      ),
    ],
    localAbilities: const [
      CustomPokemonAbilityDefinition(
        id: 'ability-conduttore-lunare',
        name: 'Conduttore Lunare',
        description: 'Concentra la luce della luna.',
      ),
    ],
  );
}
