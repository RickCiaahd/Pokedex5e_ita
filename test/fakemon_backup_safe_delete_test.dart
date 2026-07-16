import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pokedex_5e_ita/models/custom_pokemon_catalog_bundle.dart';
import 'package:pokedex_5e_ita/models/custom_pokemon_definition.dart';
import 'package:pokedex_5e_ita/models/pokemon_attributes.dart';
import 'package:pokedex_5e_ita/models/pokedex_entry.dart';
import 'package:pokedex_5e_ita/models/profile_backup.dart';
import 'package:pokedex_5e_ita/models/team_slot.dart';
import 'package:pokedex_5e_ita/repositories/custom_pokemon_repository.dart';
import 'package:pokedex_5e_ita/repositories/pokedex_repositry.dart';
import 'package:pokedex_5e_ita/repositories/profile_repository.dart';
import 'package:pokedex_5e_ita/repositories/team_repository.dart';
import 'package:pokedex_5e_ita/services/custom_pokemon_catalog_service.dart';
import 'package:pokedex_5e_ita/services/custom_pokemon_reference_service.dart';
import 'package:pokedex_5e_ita/services/profile_backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;
  late CustomPokemonRepository customPokemonRepository;
  late ProfileRepository profileRepository;
  late TeamRepository teamRepository;
  late ProfileBackupService backupService;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'pokedex_fakemon_backup_',
    );
    Hive.init(hiveDirectory.path);
    CustomPokemonRepository.markStorageReady();
    customPokemonRepository = CustomPokemonRepository();
    profileRepository = ProfileRepository();
    teamRepository = TeamRepository();
    backupService = ProfileBackupService();
  });

  tearDown(() async {
    await Hive.close();
    CustomPokemonRepository.markStorageUnavailable();
    await hiveDirectory.delete(recursive: true);
  });

  test('il backup v6 incorpora e rimappa un Fakemon in conflitto', () async {
    final sourceDefinition = _definition(
      stableId: 'fakemon-lunavolt',
      pokemonId: CustomPokemonDefinition.firstCustomPokemonId,
      name: 'Lunavolt',
    );
    await customPokemonRepository.save(sourceDefinition);
    final sourceProfile = await profileRepository.createProfile('Origine');
    await teamRepository.saveTeam(sourceProfile.id, [
      TeamSlot(
        slotIndex: 0,
        pokemonId: sourceDefinition.pokemonId,
        nickname: 'Luna',
        selectedMoves: const ['Scarica Astrale'],
      ),
      for (var index = 1; index < 6; index++)
        TeamSlot(slotIndex: index, pokemonId: null),
    ]);

    final backup = await backupService.createBackup(sourceProfile.id);
    expect(backup.formatVersion, ProfileBackup.currentFormatVersion);
    expect(backup.customPokemon, hasLength(1));
    expect(backup.customPokemon.single.stableId, sourceDefinition.stableId);
    expect(backup.customPokemon.single.imageBytes, isNotNull);

    final restoredFromJson = backupService.decodeBackup(
      backupService.encodeBackup(backup),
    );
    expect(restoredFromJson.customPokemon.single.name, 'Lunavolt');

    await customPokemonRepository.delete(sourceDefinition.stableId);
    final conflictingDefinition = _definition(
      stableId: 'fakemon-conflitto',
      pokemonId: sourceDefinition.pokemonId,
      name: 'Conflitto',
    );
    await customPokemonRepository.save(conflictingDefinition);

    final importedProfile = await backupService.importBackup(
      restoredFromJson,
      profileName: 'Importato',
    );
    final importedTeam = await teamRepository.getTeam(importedProfile.id);
    final importedDefinition = await customPokemonRepository.getByStableId(
      sourceDefinition.stableId,
    );

    expect(importedDefinition, isNotNull);
    expect(importedDefinition!.pokemonId, isNot(sourceDefinition.pokemonId));
    expect(importedTeam.first.pokemonId, importedDefinition.pokemonId);
    expect(importedTeam.first.nickname, 'Luna');
  });

  test(
    'il controllo riferimenti blocca una specie presente in squadra',
    () async {
      final definition = _definition(
        stableId: 'fakemon-usato',
        pokemonId: CustomPokemonDefinition.firstCustomPokemonId,
        name: 'Usato',
      );
      await customPokemonRepository.save(definition);
      final profile = await profileRepository.createProfile('Riccardo');
      await teamRepository.saveTeam(profile.id, [
        TeamSlot(
          slotIndex: 1,
          pokemonId: definition.pokemonId,
          nickname: 'Compagno',
        ),
        TeamSlot(slotIndex: 0, pokemonId: null),
        for (var index = 2; index < 6; index++)
          TeamSlot(slotIndex: index, pokemonId: null),
      ]);

      final report = await CustomPokemonReferenceService().findReferences(
        definition.pokemonId,
      );

      expect(report.isInUse, isTrue);
      expect(report.references, isNotEmpty);
      expect(
        report.references.any((reference) => reference.location == 'Squadra'),
        isTrue,
      );
      expect(
        report.references.any(
          (reference) => reference.detail.contains('slot 2'),
        ),
        isTrue,
      );
    },
  );

  test('una voce Pokédex vuota non blocca l’eliminazione', () async {
    final definition = _definition(
      stableId: 'fakemon-pokedex-vuoto',
      pokemonId: CustomPokemonDefinition.firstCustomPokemonId,
      name: 'Vuoto',
    );
    await customPokemonRepository.save(definition);
    final profile = await profileRepository.createProfile('Archivio');
    await PokedexRepository().saveEntry(
      profileId: profile.id,
      entry: PokedexEntry.empty(definition.pokemonId),
    );

    final backup = await backupService.createBackup(profile.id);
    final report = await CustomPokemonReferenceService().findReferences(
      definition.pokemonId,
    );

    expect(backup.customPokemon, isEmpty);
    expect(report.isInUse, isFalse);
  });

  test('il catalogo globale ha checksum e rileva le modifiche', () async {
    final definition = _definition(
      stableId: 'fakemon-catalogo',
      pokemonId: CustomPokemonDefinition.firstCustomPokemonId,
      name: 'Catalogo',
    );
    await customPokemonRepository.save(definition);
    final service = CustomPokemonCatalogService();
    final bundle = await service.createBundle();
    final encoded = service.encode(bundle);
    final decoded = service.decode(encoded);

    expect(decoded.definitions.single.name, 'Catalogo');

    final json = Map<String, dynamic>.from(jsonDecode(encoded));
    final definitions = List<dynamic>.from(json['definitions'] as List);
    final first = Map<String, dynamic>.from(definitions.first as Map);
    first['name'] = 'Alterato';
    definitions[0] = first;
    json['definitions'] = definitions;

    expect(
      () => CustomPokemonCatalogBundle.fromJson(json),
      throwsFormatException,
    );
  });
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
