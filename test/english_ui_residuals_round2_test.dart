import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/localization/game_catalog_locale.dart';
import 'package:pokedex_5e_ita/models/trainer_manual_options.dart';

void main() {
  tearDown(() {
    GameCatalogLocale.setLanguageCode('it');
  });

  test('specialization descriptions follow the selected language', () {
    GameCatalogLocale.setLanguageCode('en');
    expect(
      TrainerManualOptions.specializationNote('Bird Keeper'),
      contains('Gain proficiency in Perception'),
    );
    expect(
      TrainerManualOptions.specializationNote('Ice Skater'),
      contains('Ice-type Pokémon'),
    );

    GameCatalogLocale.setLanguageCode('it');
    expect(
      TrainerManualOptions.specializationNote('Bird Keeper'),
      contains('Ottieni competenza in Perception'),
    );
  });

  test('second localization audit includes the reported English labels', () {
    final expectations = <String, List<String>>{
      'lib/screens/battle/battle_screen.dart': [
        'Time: \${move.moveTime}',
        'Duration: \${move.duration}',
      ],
      'lib/screens/capture/capture_pokemon_screen.dart': [
        'Unlocked Poké Slots:',
        'Gender',
        'Nature',
        'Choose',
      ],
      'lib/screens/team/team_selection_screen.dart': [
        'Team',
        'Empty slot',
        'Tap to choose',
      ],
      'lib/screens/pokemon/pokemon_detail_screen_legacy.dart': [
        'AVAILABLE ASI',
        'EVOLUTION REQUIREMENTS',
        'LOYALTY',
        'SAVING THROWS',
        'Equipped moves',
      ],
      'lib/services/npc_trainer_generator_service.dart': [
        '_personalitiesEn',
        '_motivationsEn',
        '_commonOpeningLinesEn',
        '_commonTacticsEn',
      ],
      'lib/screens/tools/npc_trainer_result_screen.dart': [
        'Specializations:',
        'No ability',
        'englishValue',
        'englishLabel',
      ],
    };

    for (final entry in expectations.entries) {
      final source = File(entry.key).readAsStringSync();
      for (final expected in entry.value) {
        expect(
          source,
          contains(expected),
          reason: '${entry.key} does not contain $expected',
        );
      }
    }
  });
}
