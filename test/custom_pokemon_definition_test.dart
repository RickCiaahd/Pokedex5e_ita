import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pokedex_5e_ita/models/custom_pokemon_definition.dart';
import 'package:pokedex_5e_ita/models/custom_pokemon_transfer_bundle.dart';
import 'package:pokedex_5e_ita/models/pokemon_attributes.dart';
import 'package:pokedex_5e_ita/repositories/custom_pokemon_repository.dart';
import 'package:pokedex_5e_ita/services/custom_pokemon_runtime_registry.dart';
import 'package:pokedex_5e_ita/services/custom_pokemon_transfer_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CustomPokemonDefinition', () {
    test('conserva immagine, mosse e abilità esclusive nel JSON', () {
      final definition = _definition();
      final restored = CustomPokemonDefinition.fromJson(definition.toJson());

      expect(restored.stableId, definition.stableId);
      expect(restored.pokemonId, definition.pokemonId);
      expect(restored.imageBytes, Uint8List.fromList([1, 2, 3, 4]));
      expect(restored.localMoves.single.name, 'Scarica Astrale');
      expect(restored.localMoveCatalog()['scarica-astrale']?.type, 'Electric');
      expect(
        restored.localAbilityCatalog()['Conduttore Lunare'],
        contains('luce lunare'),
      );
      expect(
        restored.toPokemon().moves.startingMoves,
        contains('Scarica Astrale'),
      );
    });

    test('il file portabile rileva una modifica al contenuto', () {
      final service = CustomPokemonTransferService();
      final encoded = service.encode(_definition());
      final decoded = service.decode(encoded);

      expect(decoded.definition.name, 'Lunavolt');

      final json = Map<String, dynamic>.from(jsonDecode(encoded));
      final definitionJson = Map<String, dynamic>.from(
        json['definition'] as Map,
      );
      definitionJson['name'] = 'Nome alterato';
      json['definition'] = definitionJson;

      expect(
        () => CustomPokemonTransferBundle.fromJson(json),
        throwsFormatException,
      );
    });
  });

  group('CustomPokemonRepository', () {
    late Directory hiveDirectory;
    late CustomPokemonRepository repository;

    setUp(() async {
      hiveDirectory = await Directory.systemTemp.createTemp('pokedex_fakemon_');
      Hive.init(hiveDirectory.path);
      repository = CustomPokemonRepository();
    });

    tearDown(() async {
      await Hive.close();
      await hiveDirectory.delete(recursive: true);
    });

    test('salva la specie globale e aggiorna il registro runtime', () async {
      final definition = _definition();
      await repository.save(definition);

      final saved = await repository.getAll();
      expect(saved, hasLength(1));
      expect(saved.single.name, 'Lunavolt');
      expect(
        CustomPokemonRuntimeRegistry.imageBytesFor(definition.pokemonId),
        isNotNull,
      );
      expect(await repository.allocatePokemonId(), definition.pokemonId + 1);

      await repository.delete(definition.stableId);
      expect(await repository.getAll(), isEmpty);
    });
  });
}

CustomPokemonDefinition _definition() {
  return CustomPokemonDefinition(
    formatVersion: CustomPokemonDefinition.currentFormatVersion,
    stableId: 'fakemon-lunavolt-test',
    pokemonId: CustomPokemonDefinition.firstCustomPokemonId,
    createdAt: DateTime.utc(2026, 7, 16),
    updatedAt: DateTime.utc(2026, 7, 16),
    name: 'Lunavolt',
    author: 'Test Master',
    types: const ['Electric', 'Fairy'],
    armorClass: 14,
    hitPoints: 36,
    size: 'Medium',
    speed: 40,
    attributes: const PokemonAttributes(
      strength: 10,
      dexterity: 16,
      constitution: 14,
      intelligence: 12,
      wisdom: 13,
      charisma: 15,
    ),
    abilities: const ['Conduttore Lunare'],
    skills: const ['Perception'],
    savingThrows: const ['DEX', 'CHA'],
    startingMoves: const ['Scarica Astrale'],
    levelMoves: const {
      5: ['Moonblast'],
    },
    tmMoves: const [3],
    eggMoves: const ['Wish'],
    hitDice: 6,
    sr: 2,
    minLevelFound: 3,
    description: 'Un Fakemon nato dalla luce della luna.',
    genus: 'Pokémon Lunare',
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
        description: 'Una scarica di energia lunare.',
        damageByLevel: {1: '2d6'},
        isAttack: true,
      ),
    ],
    localAbilities: const [
      CustomPokemonAbilityDefinition(
        id: 'ability-conduttore-lunare',
        name: 'Conduttore Lunare',
        description: 'Assorbe e concentra la luce lunare.',
      ),
    ],
  );
}
