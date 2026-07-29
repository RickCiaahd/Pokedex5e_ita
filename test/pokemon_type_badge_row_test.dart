import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/widgets/pokemon/pokemon_type_badge.dart';
import 'package:pokedex_5e_ita/widgets/pokemon/pokemon_type_badge_row.dart';

void main() {
  testWidgets('i due tipi restano affiancati negli spazi compatti', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 176,
              child: PokemonTypeBadgeRow(types: ['Bug', 'Poison']),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final badges = find.byType(PokemonTypeBadge);
    expect(badges, findsNWidgets(2));

    final first = tester.getRect(badges.at(0));
    final second = tester.getRect(badges.at(1));

    expect(first.top, second.top);
    expect(first.bottom, second.bottom);
    expect(first.right, lessThanOrEqualTo(second.left));
    expect(tester.takeException(), isNull);
  });
}
