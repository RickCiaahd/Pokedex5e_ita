import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/localization/game_catalog_locale.dart';
import 'package:pokedex_5e_ita/models/battle_environment.dart';
import 'package:pokedex_5e_ita/models/generated_npc_trainer.dart';
import 'package:pokedex_5e_ita/widgets/battle/pokemon_battle_attributes_card.dart';

void main() {
  tearDown(() {
    GameCatalogLocale.setLanguageCode('it');
  });

  test('dynamic model labels expose English alternatives', () {
    expect(BattleWeather.clear.englishLabel, 'No weather');
    expect(BattleNaturalTerrain.none.englishLabel, 'None');
    expect(BattleFieldTerrain.none.englishLabel, 'None');
    expect(NpcTrainerRank.common.englishLabel, 'Common');
    expect(
      NpcTrainerRank.common.englishDescription,
      contains('ordinary Trainer'),
    );
    expect(NpcTeamComposition.mixed.englishLabel, 'Mixed');
  });

  testWidgets('battle ability card is fully English with an English locale', (
    tester,
  ) async {
    GameCatalogLocale.setLanguageCode('en');
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('en'),
          home: Scaffold(
            body: PokemonBattleAttributesCard(
              attributes: {
                'STR': 13,
                'DEX': 12,
                'CON': 12,
                'INT': 6,
                'WIS': 10,
                'CHA': 10,
              },
            ),
          ),
        ),
      );

      expect(find.text('ABILITY SCORES'), findsOneWidget);
      expect(find.bySemanticsLabel('Strength: 13, +1'), findsOneWidget);
      expect(find.bySemanticsLabel('Dexterity: 12, +1'), findsOneWidget);
      expect(find.bySemanticsLabel('Constitution: 12, +1'), findsOneWidget);
      expect(find.bySemanticsLabel('Intelligence: 6, -2'), findsOneWidget);
      expect(find.bySemanticsLabel('Wisdom: 10, +0'), findsOneWidget);
      expect(find.bySemanticsLabel('Charisma: 10, +0'), findsOneWidget);
      expect(find.text('CARATTERISTICHE'), findsNothing);
    } finally {
      semantics.dispose();
    }
  });

  test('reported screens include their English UI text', () {
    final expectations = <String, List<String>>{
      'lib/widgets/battle/battle_environment_card.dart': [
        "'ENVIRONMENT'",
        "'Update environment'",
      ],
      'lib/screens/bag/bag_screen.dart': [
        "'Bag'",
        "'Search items'",
        "'Quantity",
      ],
      'lib/screens/trainer/trainer_sheet_screen.dart': [
        "'Choose specialization'",
        "'Trainer Path'",
        "'Path Feature'",
      ],
      'lib/screens/pokedex/pokedex_screen.dart': [
        "'Filters and modes'",
        "'Filter by region'",
        "'Apply'",
      ],
      'lib/screens/profile/profiles_screen.dart': [
        "'Trainer profiles'",
        "'Active'",
        "'New'",
      ],
      'lib/screens/tools/pokemon_generator_screen.dart': [
        "'Pokémon Generator'",
        "'Create a ready-to-use Pokémon'",
        "'All types'",
      ],
      'lib/screens/tools/encounter_generator_screen.dart': [
        "'Encounter Generator'",
        "'Automatic composition'",
        "'ADVANCED FILTERS'",
      ],
      'lib/screens/tools/npc_trainer_generator_screen.dart': [
        "'NPC Trainer'",
        "'NPC Trainer Generator'",
        "'LEVELS AND TEAM'",
      ],
      'lib/screens/tools/encounter_library_screen.dart': [
        "'Encounter Library'",
        "'Prepared encounters'",
        "'No saved encounters'",
      ],
      'lib/screens/tools/npc_trainer_library_screen.dart': [
        "'NPC Trainer Library'",
        "'Game Master Trainers'",
        "'No saved NPC Trainers'",
      ],
      'lib/screens/pc/pokemon_pc_screen.dart': [
        "'Pokémon PC'",
        "'Team'",
        "'Deposit'",
      ],
    };

    for (final entry in expectations.entries) {
      final source = entry.key == 'lib/screens/bag/bag_screen.dart'
          ? _bagSource()
          : File(entry.key).readAsStringSync();
      for (final expected in entry.value) {
        expect(
          source,
          contains(expected),
          reason: '${entry.key} does not contain $expected',
        );
      }
    }
  });

  test('reported direct Italian-only controls are no longer present', () {
    final sources = [
      'lib/screens/battle/battle_screen.dart',
      'lib/screens/tools/encounter_collection_editor_screen.dart',
      'lib/screens/tools/encounter_result_screen.dart',
      'lib/screens/tools/npc_trainer_result_screen.dart',
    ].map((path) => File(path).readAsStringSync()).join('\n');

    expect(sources, isNot(contains("child: Text('ZAINO')")));
    expect(sources, isNot(contains("label: Text('NESSUNO')")));
    expect(sources, isNot(contains("child: Text('ANNULLA')")));
    expect(
      sources,
      isNot(
        contains(
          "const InputDecoration(\n              labelText: context.uiText",
        ),
      ),
    );
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
