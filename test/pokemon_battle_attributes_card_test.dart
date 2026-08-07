import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pokedex_5e_ita/l10n/app_localizations.dart';
import 'package:pokedex_5e_ita/widgets/battle/pokemon_battle_attributes_card.dart';

void main() {
  const attributes = {
    'STR': 8,
    'DEX': 12,
    'CON': 14,
    'INT': 10,
    'WIS': 16,
    'CHA': 6,
  };

  testWidgets('mostra tutte le caratteristiche e i modificatori', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('it'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: PokemonBattleAttributesCard(attributes: attributes),
          ),
        ),
      ),
    );

    expect(find.text('CARATTERISTICHE'), findsOneWidget);
    for (final abbreviation in ['STR', 'DEX', 'CON', 'INT', 'WIS', 'CHA']) {
      expect(find.text(abbreviation), findsOneWidget);
    }
    for (final label in [
      'Forza: 8, -1',
      'Destrezza: 12, +1',
      'Costituzione: 14, +2',
      'Intelligenza: 10, +0',
      'Saggezza: 16, +3',
      'Carisma: 6, -2',
    ]) {
      expect(find.bySemanticsLabel(label), findsOneWidget);
    }
    expect(find.text('-1'), findsOneWidget);
    expect(find.text('+1'), findsOneWidget);
    expect(find.text('+2'), findsOneWidget);
    expect(find.text('+0'), findsOneWidget);
    expect(find.text('+3'), findsOneWidget);
    expect(find.text('-2'), findsOneWidget);
  });

  testWidgets('non genera vincoli negativi con larghezza quasi nulla', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('it'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 24,
              child: PokemonBattleAttributesCard(attributes: attributes),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
