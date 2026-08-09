import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/l10n/app_localizations.dart';
import 'package:pokedex_5e_ita/models/pokedex_entry.dart';
import 'package:pokedex_5e_ita/models/pokemon.dart';
import 'package:pokedex_5e_ita/models/pokemon_attributes.dart';
import 'package:pokedex_5e_ita/models/pokemon_moves.dart';
import 'package:pokedex_5e_ita/widgets/pokedex/pokemon_summary_dialog.dart';

Pokemon _pokemon({
  required int id,
  required String name,
  required List<String> types,
  String? assetSlug,
  String? genus,
  String? description,
}) {
  return Pokemon(
    id: id,
    name: name,
    types: types,
    armorClass: 12,
    hitPoints: 16,
    size: 'Tiny',
    speed: 30,
    attributes: const PokemonAttributes(
      strength: 7,
      dexterity: 15,
      constitution: 11,
      intelligence: 6,
      wisdom: 9,
      charisma: 8,
    ),
    abilities: const [],
    hiddenAbility: null,
    skills: const [],
    savingThrows: const [],
    moves: const PokemonMoves(startingMoves: [], levelMoves: {}, tmMoves: []),
    hitDice: 6,
    sr: 0.5,
    minLevelFound: 1,
    assetSlug: assetSlug,
    genus: genus,
    description: description,
  );
}

Widget _dialogHost({
  required Pokemon pokemon,
  required PokedexEntry entry,
  double textScale = 1,
}) {
  return MaterialApp(
    locale: const Locale('it'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (_) => PokemonSummaryDialog(
                  pokemon: pokemon,
                  entry: entry,
                  onEntryChanged: (_) async {},
                ),
              );
            },
            child: const Text('Apri'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openAndWaitForForms(WidgetTester tester) async {
  await tester.tap(find.text('Apri'));
  await tester.pump();
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    if (find.byType(LinearProgressIndicator).evaluate().isEmpty) return;
  }
  fail('Il caricamento delle forme non è terminato nel tempo previsto.');
}

void main() {
  testWidgets('mostra il selettore solo quando esistono più forme', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final alolan = _pokemon(
      id: 19,
      name: 'Rattata',
      types: const ['Dark', 'Normal'],
      assetSlug: 'alolan-rattata',
    );
    final pokemon = _pokemon(id: 19, name: 'Rattata', types: const ['Normal'])
        .copyWith(
          formDefinitions: [
            PokemonFormDefinition(
              key: 'alolan',
              displayName: 'Alolan Rattata',
              pokemon: alolan,
            ),
          ],
        );
    final entry = PokedexEntry.empty(19)
        .setFormState(
          formName: null,
          speciesName: 'Rattata',
          seen: true,
          caught: true,
        )
        .setFormState(
          formName: 'Alolan Rattata',
          speciesName: 'Rattata',
          seen: true,
          caught: true,
        );

    await tester.pumpWidget(_dialogHost(pokemon: pokemon, entry: entry));
    await _openAndWaitForForms(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Rattata #019'), findsOneWidget);
    expect(find.text('Base'), findsOneWidget);
    expect(find.text('Alola'), findsOneWidget);
  });

  testWidgets('non mostra Base quando il Pokémon ha una sola forma', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final pokemon = _pokemon(
      id: 1,
      name: 'Bulbasaur',
      types: const ['Grass', 'Poison'],
    );
    final entry = PokedexEntry.empty(1).setFormState(
      formName: null,
      speciesName: 'Bulbasaur',
      seen: true,
      caught: false,
    );

    await tester.pumpWidget(_dialogHost(pokemon: pokemon, entry: entry));
    await _openAndWaitForForms(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Bulbasaur #001'), findsOneWidget);
    expect(find.text('BASE'), findsNothing);
    expect(find.text('Base'), findsNothing);
    expect(find.text('SCHEDA'), findsOneWidget);
  });

  testWidgets('resta utilizzabile su schermo stretto con testo ingrandito', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final alolan = _pokemon(
      id: 52,
      name: 'Meowth',
      types: const ['Dark'],
      assetSlug: 'alolan-meowth',
      genus: 'The Scratch Cat Pokémon',
      description:
          'When its delicate pride is wounded, or when the gold coin on its '
          'forehead is dirtied, it flies into a hysterical rage.',
    );
    final pokemon = _pokemon(id: 52, name: 'Meowth', types: const ['Normal'])
        .copyWith(
          formDefinitions: [
            PokemonFormDefinition(
              key: 'alolan',
              displayName: 'Alolan Meowth',
              pokemon: alolan,
            ),
          ],
        );
    final entry = PokedexEntry.empty(52)
        .setFormState(
          formName: null,
          speciesName: 'Meowth',
          seen: true,
          caught: false,
        )
        .setFormState(
          formName: 'Alolan Meowth',
          speciesName: 'Meowth',
          seen: true,
          caught: false,
        );

    await tester.pumpWidget(
      _dialogHost(pokemon: pokemon, entry: entry, textScale: 1.5),
    );
    await _openAndWaitForForms(tester);
    await tester.tap(find.text('Alola'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Pokémon Graffimiao'), findsOneWidget);
    expect(find.textContaining('delicato orgoglio'), findsOneWidget);
    expect(find.text('VISTO'), findsOneWidget);
    expect(find.text('NON CATTURATO'), findsOneWidget);
    expect(find.text('SCHEDA'), findsOneWidget);
    expect(
      tester.getBottomRight(find.text('SCHEDA')).dy,
      lessThanOrEqualTo(640),
    );
  });
}
