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
    expect(
      find.text(
        'Valori effettivi e modificatori da usare per prove, tiri salvezza e iniziativa del Pokémon.',
      ),
      findsOneWidget,
    );
    expect(find.text('Forza'), findsOneWidget);
    expect(find.text('Destrezza'), findsOneWidget);
    expect(find.text('Costituzione'), findsOneWidget);
    expect(find.text('Intelligenza'), findsOneWidget);
    expect(find.text('Saggezza'), findsOneWidget);
    expect(find.text('Carisma'), findsOneWidget);
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
