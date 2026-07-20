import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/trainer_ui_localization.dart';

void main() {
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
      TrainerUiLocalization.specializationName('Bug Maniac'),
      'Insettologo',
    );
    expect(TrainerUiLocalization.specializationName('Engineer'), 'Meccanico');
    expect(
      TrainerUiLocalization.featureName('Rapid Switching'),
      'Cambio Rapido',
    );
    expect(TrainerUiLocalization.featureName('Follow Me'), 'Sonoqui');
  });

  test('la UI non reintroduce le principali etichette inglesi', () {
    final pokemonDetail = File(
      'lib/screens/pokemon/pokemon_detail_screen_legacy.dart',
    ).readAsStringSync();
    final trainerSheet = File(
      'lib/screens/trainer/trainer_sheet_screen.dart',
    ).readAsStringSync();

    expect(pokemonDetail, contains("Tab(text: 'PRIVILEGI')"));
    expect(pokemonDetail, contains("Tab(text: 'TRATTI')"));
    expect(pokemonDetail, contains("'TIRI SALVEZZA'"));
    expect(pokemonDetail, contains("'+ AGGIUNGI STATUS'"));
    expect(pokemonDetail, contains("'LEALTÀ'"));
    expect(trainerSheet, contains("title: 'ALLENATORE'"));
    expect(trainerSheet, contains("title: 'ABILITÀ'"));
    expect(trainerSheet, contains("title: 'TIRI SALVEZZA'"));
    expect(trainerSheet, contains("title: 'AVANZAMENTO'"));
  });
}
