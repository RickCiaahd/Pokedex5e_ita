import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/localization/game_catalog_locale.dart';
import 'package:pokedex_5e_ita/models/breeding_candidate.dart';
import 'package:pokedex_5e_ita/services/pokemon_habitat_service.dart';

void main() {
  tearDown(() => GameCatalogLocale.setLanguageCode('it'));

  test('breeding labels and habitats follow the selected language', () {
    const candidate = BreedingCandidate(
      key: 'test',
      pokemonId: 1,
      displayName: 'Test',
      location: 'PC',
      loyalty: 2,
      selectedMoves: [],
      abilities: [],
      gender: 'genderless',
    );

    GameCatalogLocale.setLanguageCode('en');
    expect(candidate.genderLabel, 'Genderless');
    expect(PokemonHabitatService.englishLabel('Qualsiasi'), 'Any');

    GameCatalogLocale.setLanguageCode('it');
    expect(candidate.genderLabel, 'Senza sesso');
  });

  test('third audit localizes the reported screens', () {
    final breeding = File(
      'lib/screens/breeding/breeding_screen.dart',
    ).readAsStringSync();
    expect(breeding, contains('Breeding and Eggs'));
    expect(breeding, contains('POKÉMON BREEDING'));
    expect(breeding, contains('NEW ATTEMPT'));
    expect(breeding, contains('INCUBATING EGGS'));

    final battle = File(
      'lib/screens/battle/battle_screen.dart',
    ).readAsStringSync();
    expect(battle, contains('INIT.'));
    expect(battle, contains("uiTextForLanguage('USA', 'USE')"));

    final encounter = File(
      'lib/screens/tools/encounter_generator_screen.dart',
    ).readAsStringSync();
    expect(encounter, contains('PokemonHabitatService.englishLabel(habitat)'));
  });
}
