import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/localization/game_catalog_locale.dart';
import 'package:pokedex_5e_ita/models/trainer_ui_localization.dart';

void main() {
  setUp(() {
    GameCatalogLocale.setLanguageCode('it');
  });

  tearDown(() {
    GameCatalogLocale.setLanguageCode('it');
  });

  test('caratteristiche e abilità vengono mostrate in italiano', () {
    expect(TrainerUiLocalization.abilityAbbreviation('STR'), 'FOR');
    expect(TrainerUiLocalization.abilityAbbreviation('DEX'), 'DES');
    expect(TrainerUiLocalization.abilityAbbreviation('CON'), 'COS');
    expect(TrainerUiLocalization.abilityAbbreviation('WIS'), 'SAG');
    expect(TrainerUiLocalization.abilityAbbreviation('CHA'), 'CAR');
    expect(
      TrainerUiLocalization.skillName('Animal Handling'),
      'Addestrare Animali',
    );
    expect(
      TrainerUiLocalization.skillName('Sleight of Hand'),
      'Rapidità di Mano',
    );
  });

  test('etichette tecniche rimangono inglesi con interfaccia inglese', () {
    GameCatalogLocale.setLanguageCode('en');

    expect(TrainerUiLocalization.abilityAbbreviation('STR'), 'STR');
    expect(TrainerUiLocalization.abilityAbbreviation('DEX'), 'DEX');
    expect(
      TrainerUiLocalization.skillName('Animal Handling'),
      'Animal Handling',
    );
    expect(TrainerUiLocalization.trainerPathName('Ace Trainer'), 'Ace Trainer');
    expect(TrainerUiLocalization.natureName('Adamant'), 'Adamant');
    expect(TrainerUiLocalization.sizeName('Medium'), 'Medium');
    expect(TrainerUiLocalization.genderName('Female'), 'Female');
  });

  test('nomi tecnici mantengono etichette italiane separate', () {
    expect(
      TrainerUiLocalization.trainerPathName('Ace Trainer'),
      'Fantallenatore',
    );
    expect(TrainerUiLocalization.trainerPathName('Grunt'), 'Recluta');
    expect(
      TrainerUiLocalization.specializationName('Bird Keeper'),
      'Avicoltore',
    );
    expect(
      TrainerUiLocalization.featureName('Rapid Switching'),
      'Cambio Rapido',
    );
    expect(TrainerUiLocalization.natureName('Adamant'), 'Decisa');
    expect(TrainerUiLocalization.sizeName('Medium'), 'Media');
    expect(TrainerUiLocalization.genderName('Female'), 'Femmina');
  });

  test('le schermate migrate contengono entrambe le lingue', () {
    final pokemonDetail = File(
      'lib/screens/pokemon/pokemon_detail_screen_legacy.dart',
    ).readAsStringSync();
    final trainerSheet = File(
      'lib/screens/trainer/trainer_sheet_screen.dart',
    ).readAsStringSync();

    expect(pokemonDetail, contains("context.uiText('PRIVILEGI', 'FEATURES')"));
    expect(pokemonDetail, contains("context.uiText('TRATTI', 'TRAITS')"));
    expect(trainerSheet, contains("context.uiText('ALLENATORE', 'TRAINER')"));
    expect(trainerSheet, contains("context.uiText('ABILITÀ', 'SKILLS')"));
    expect(
      trainerSheet,
      contains("context.uiText('TIRI SALVEZZA', 'SAVING THROWS')"),
    );
    expect(
      trainerSheet,
      contains("context.uiText('AVANZAMENTO', 'PROGRESSION')"),
    );
  });
}
