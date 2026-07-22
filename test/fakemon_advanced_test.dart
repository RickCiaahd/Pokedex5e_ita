import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/custom_pokemon_advanced_data.dart';
import 'package:pokedex_5e_ita/models/custom_pokemon_definition.dart';
import 'package:pokedex_5e_ita/models/custom_pokemon_transfer_bundle.dart';
import 'package:pokedex_5e_ita/models/pokemon_attributes.dart';
import 'package:pokedex_5e_ita/repositories/evolution_repository.dart';
import 'package:pokedex_5e_ita/services/custom_pokemon_runtime_registry.dart';

// Regressioni principali del formato Fakemon v2 e dei flussi giocatore.
CustomPokemonDefinition _definition({
  required String stableId,
  required int pokemonId,
  required String name,
  CustomPokemonAdvancedData advanced = const CustomPokemonAdvancedData(),
}) {
  final now = DateTime.utc(2026, 7, 22);
  return CustomPokemonDefinition(
    formatVersion: CustomPokemonDefinition.currentFormatVersion,
    stableId: stableId,
    pokemonId: pokemonId,
    createdAt: now,
    updatedAt: now,
    name: name,
    author: 'Test',
    types: const ['Electric'],
    armorClass: 14,
    hitPoints: 40,
    size: 'Small',
    speed: 35,
    attributes: const PokemonAttributes(
      strength: 10,
      dexterity: 16,
      constitution: 13,
      intelligence: 12,
      wisdom: 14,
      charisma: 12,
    ),
    abilities: const ['Static'],
    skills: const [],
    savingThrows: const ['Dexterity'],
    startingMoves: const ['Quick Attack'],
    levelMoves: const {},
    tmMoves: const [],
    eggMoves: const [],
    hitDice: 8,
    sr: 2,
    minLevelFound: 1,
    advanced: advanced,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => CustomPokemonRuntimeRegistry.replaceAll(const []));

  test('una forma personalizzata sovrascrive statistiche e tipi', () {
    final definition = _definition(
      stableId: 'storm-eon',
      pokemonId: 2000000,
      name: 'Stormeon',
      advanced: const CustomPokemonAdvancedData(
        forms: [
          CustomPokemonForm(
            id: 'tempesta',
            name: 'Forma Tempesta',
            duration: CustomPokemonFormDuration.battle,
            types: ['Electric', 'Flying'],
            armorClass: 17,
            speed: 50,
          ),
        ],
      ),
    );

    final pokemon = definition.toPokemon();
    final form = pokemon.resolveVariant(formName: 'Forma Tempesta');

    expect(form.types, ['Electric', 'Flying']);
    expect(form.armorClass, 17);
    expect(form.speed, 50);
    expect(pokemon.formDefinitions.single.displayName, 'Forma Tempesta');
  });

  test('un Fakemon può essere collegato come forma di una specie', () {
    final definition = _definition(
      stableId: 'storm-eon',
      pokemonId: 2000000,
      name: 'Stormeon',
      advanced: const CustomPokemonAdvancedData(
        alternateFormOf: CustomPokemonReference(pokemonId: 133, name: 'Eevee'),
        alternateFormDuration: CustomPokemonFormDuration.battle,
      ),
    );
    final decoded = CustomPokemonDefinition.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(jsonEncode(definition.toJson())) as Map,
      ),
    );

    expect(decoded.advanced.alternateFormOf?.pokemonId, 133);
    expect(
      decoded.advanced.alternateFormDuration,
      CustomPokemonFormDuration.battle,
    );

    CustomPokemonRuntimeRegistry.replaceAll([decoded]);
    expect(
      CustomPokemonRuntimeRegistry.isTemporaryForm(133, 'Stormeon'),
      isTrue,
    );
  });

  test('Eevee riceve una nuova evoluzione Fakemon', () async {
    final definition = _definition(
      stableId: 'storm-eon',
      pokemonId: 2000000,
      name: 'Stormeon',
      advanced: const CustomPokemonAdvancedData(
        sealedForPlayer: true,
        evolvesFrom: [
          CustomPokemonEvolutionLink(
            id: 'eevee-stormeon',
            pokemon: CustomPokemonReference(pokemonId: 133, name: 'Eevee'),
            conditions: [
              CustomPokemonEvolutionCondition(type: 'level', value: 5),
            ],
            hint: 'Il pelo si carica durante una tempesta.',
          ),
        ],
      ),
    );
    CustomPokemonRuntimeRegistry.replaceAll([definition]);

    final evolutions = await EvolutionRepository().getEvolutionData();
    final eevee = evolutions['eevee']!;
    final custom = eevee.options.firstWhere(
      (option) => option.targetPokemonId == 2000000,
    );

    expect(custom.toName, 'Stormeon');
    expect(custom.levelCondition, 5);
    expect(custom.isSecret, isTrue);
    expect(custom.secretHint, contains('tempesta'));
  });

  test('il pacchetto segreto conserva checksum e flag sealed', () {
    final definition = _definition(
      stableId: 'storm-eon',
      pokemonId: 2000000,
      name: 'Stormeon',
      advanced: const CustomPokemonAdvancedData(secretUntilDiscovered: true),
    );
    final bundle = CustomPokemonTransferBundle.create(
      definition,
      sealed: true,
      exportedAt: DateTime.utc(2026, 7, 22),
    );

    final decoded = CustomPokemonTransferBundle.fromJson(
      Map<String, dynamic>.from(jsonDecode(jsonEncode(bundle.toJson())) as Map),
    );

    expect(decoded.sealed, isTrue);
    expect(decoded.definition.name, 'Stormeon');
    expect(decoded.definition.advanced.secretUntilDiscovered, isTrue);
  });
}
