import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/localization/game_catalog_locale.dart';
import 'package:pokedex_5e_ita/models/trainer_origin_name_localization.dart';
import 'package:pokedex_5e_ita/models/trainer_ui_localization.dart';

void main() {
  setUp(() {
    GameCatalogLocale.setLanguageCode('it');
  });

  tearDown(() {
    GameCatalogLocale.setLanguageCode('it');
  });

  test('in italiano usa il nome ufficiale della regione', () {
    const expectedNames = {
      'Alolan': 'Alola',
      'Hoennian': 'Hoenn',
      'Johtoan': 'Johto',
      'Kalosian': 'Kalos',
      'Kantoan': 'Kanto',
      'Sinnoan': 'Sinnoh',
      'Unovan': 'Unima',
      'Galarian': 'Galar',
    };

    for (final entry in expectedNames.entries) {
      expect(
        trainerOriginDisplayName(
          entry.key,
          isItalian: true,
          dmApprovedLabel: 'Origine 5e approvata dal DM',
        ),
        entry.value,
      );
    }
  });

  test('in inglese mantiene i nomi originali', () {
    for (final origin in ['Alolan', 'Hoennian', 'Unovan', 'Galarian']) {
      expect(
        trainerOriginDisplayName(
          origin,
          isItalian: false,
          dmApprovedLabel: 'DM-approved 5e origin',
        ),
        origin,
      );
    }
  });

  test('mantiene la traduzione dedicata per l origine approvata dal DM', () {
    expect(
      trainerOriginDisplayName(
        'Origine 5e approvata dal DM',
        isItalian: false,
        dmApprovedLabel: 'DM-approved 5e origin',
      ),
      'DM-approved 5e origin',
    );
  });

  test('onboarding e scheda allenatore usano lo stesso traduttore', () {
    final onboarding = File(
      'lib/screens/onboarding/first_launch_onboarding_screen.dart',
    ).readAsStringSync();
    final trainerSheet = File(
      'lib/screens/trainer/trainer_sheet_screen.dart',
    ).readAsStringSync();

    for (final source in [onboarding, trainerSheet]) {
      expect(
        source,
        contains('trainerOriginDisplayName('),
        reason:
            'Onboarding e scheda devono riusare la localizzazione condivisa dei nomi',
      );
      expect(
        source,
        contains('TrainerUiLocalization.visibleText(description)'),
        reason:
            'Onboarding, elenco e box devono mostrare la stessa descrizione localizzata',
      );
    }

    expect(
      trainerSheet,
      contains('_localizedOriginName(selectedOrigin)'),
      reason: 'Il box Origine non deve mostrare la chiave inglese salvata',
    );
  });

  test('le descrizioni italiane convertono tutte le abbreviazioni inglesi', () {
    const description =
        'Bonus caratteristiche: STR +1, DEX +1, CON +1, INT +1, WIS +1, CHA +1.';

    expect(
      TrainerUiLocalization.visibleText(description),
      'Bonus caratteristiche: FOR +1, DES +1, COS +1, INT +1, SAG +1, CAR +1.',
    );
  });
}
