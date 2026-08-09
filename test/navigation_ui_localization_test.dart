import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('le schermate principali espongono testi italiani e inglesi', () {
    final expectations = <String, List<String>>{
      'lib/screens/pokedex/pokedex_screen.dart': [
        "'Cerca Pokémon...'",
        "'Search Pokémon...'",
      ],
      'lib/screens/team/team_selection_screen.dart': [
        "'Esporta squadra'",
        "'Export team'",
      ],
      'lib/screens/profile/profiles_screen.dart': [
        "'Profili allenatore'",
        "'Trainer profiles'",
      ],
      'lib/screens/bag/bag_screen.dart': ["'Zaino'", "'Bag'"],
      'lib/screens/pc/pokemon_pc_screen.dart': ["'PC Pokémon'", "'Pokémon PC'"],
      'lib/screens/capture/capture_pokemon_screen.dart': [
        "'REGISTRA CATTURA'",
        "'RECORD CATCH'",
      ],
    };

    for (final entry in expectations.entries) {
      final source = entry.key == 'lib/screens/bag/bag_screen.dart'
          ? _bagSource()
          : File(entry.key).readAsStringSync();
      expect(source, contains("import '../../localization/ui_text.dart';"));
      for (final text in entry.value) {
        expect(
          source,
          contains(text),
          reason: '${entry.key} non contiene $text',
        );
      }
    }
  });
}

String _bagSource() {
  final files = Directory('lib/screens/bag')
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  return files.map((file) => file.readAsStringSync()).join('\n');
}
