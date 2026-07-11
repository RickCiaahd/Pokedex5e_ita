import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/pokedex_entry.dart';
import 'package:pokedex_5e_ita/models/pokemon.dart';
import 'package:pokedex_5e_ita/models/pokemon_attributes.dart';
import 'package:pokedex_5e_ita/models/pokemon_moves.dart';
import 'package:pokedex_5e_ita/widgets/pokedex/pokemon_summary_dialog.dart';

Pokemon _pokemon({
  required int id,
  required String name,
  required List<String> types,
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
  );
}

void main() {
  testWidgets('Pokédex summary dialog lays out the horizontal form selector', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final alolan = _pokemon(
      id: 19,
      name: 'Rattata',
      types: const ['Dark', 'Normal'],
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

    await tester.pumpWidget(
      MaterialApp(
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
      ),
    );

    await tester.tap(find.text('Apri'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Rattata #019'), findsOneWidget);
    expect(find.text('Base'), findsOneWidget);
    expect(find.text('Alolan'), findsOneWidget);
  });
}
