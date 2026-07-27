import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/localization/game_catalog_locale.dart';
import 'package:pokedex_5e_ita/models/trainer_ui_localization.dart';

void main() {
  tearDown(() => GameCatalogLocale.setLanguageCode('it'));

  test('NPC specialization labels follow the selected language', () {
    GameCatalogLocale.setLanguageCode('it');
    expect(
      TrainerUiLocalization.specializationName('Bird Keeper'),
      'Avicoltore',
    );
    expect(
      TrainerUiLocalization.specializationName('Alchemist'),
      'Alchimista',
    );

    GameCatalogLocale.setLanguageCode('en');
    expect(
      TrainerUiLocalization.specializationName('Bird Keeper'),
      'Bird Keeper',
    );
  });

  test('NPC screens render specializations through the localization helper', () {
    for (final path in <String>[
      'lib/screens/tools/npc_trainer_generator_screen.dart',
      'lib/screens/tools/npc_trainer_result_screen.dart',
      'lib/screens/tools/npc_trainer_library_screen.dart',
    ]) {
      expect(
        File(path).readAsStringSync(),
        contains('TrainerUiLocalization.specializationName'),
        reason: path,
      );
    }
  });

  test('advanced encounter filters leave room for the floating label', () {
    final source = File(
      'lib/screens/tools/encounter_generator_screen.dart',
    ).readAsStringSync();
    expect(
      source,
      contains('childrenPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16)'),
    );
  });
}
