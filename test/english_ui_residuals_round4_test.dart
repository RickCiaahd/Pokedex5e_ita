import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/localization/game_catalog_locale.dart';
import 'package:pokedex_5e_ita/localization/ui_text.dart';

void main() {
  tearDown(() => GameCatalogLocale.setLanguageCode('it'));

  test('round 4 strings follow the selected language', () {
    GameCatalogLocale.setLanguageCode('en');
    expect(uiTextForLanguage('Annulla', 'Cancel'), 'Cancel');
    expect(uiTextForLanguage('Scheda', 'Sheet'), 'Sheet');
    GameCatalogLocale.setLanguageCode('it');
    expect(uiTextForLanguage('Annulla', 'Cancel'), 'Annulla');
  });

  test('general English audit covers the remaining visible areas', () {
    final files = <String, List<String>>{
      'lib/screens/battle/npc_battle_screen.dart': [
        'NPC Trainer',
        'SHARED INITIATIVE',
        'NEXT TURN',
      ],
      'lib/screens/pokemon/custom_pokemon_library_screen.dart': [
        'OPEN ADVANCED EDITOR',
        'SAVE FAKEMON',
      ],
      'lib/screens/pokemon/custom_pokemon_advanced_editor_screen.dart': [
        'SAVE ADVANCED DATA',
        'CUSTOM FORM',
      ],
      'lib/screens/pokemon/pokemon_edit_screen.dart': [
        'Choose ability',
        'Proficiencies',
        'CHOOSE MOVE',
      ],
      'lib/screens/team/team_selection_screen.dart': [
        'Choose Pokémon',
        'Retry',
      ],
      'lib/widgets/trainer/trainer_path_automation_panel.dart': [
        'TRAINER PATH MANAGEMENT',
      ],
    };
    for (final entry in files.entries) {
      final source = File(entry.key).readAsStringSync();
      for (final expected in entry.value) {
        expect(source, contains(expected), reason: '${entry.key}: $expected');
      }
    }
  });
}
