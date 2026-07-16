import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/move_data.dart';
import 'package:pokedex_5e_ita/repositories/move_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('il catalogo completo delle mosse contiene Surf', () async {
    final moves = await MoveRepository().getAllMoves();

    expect(
      moves.any((move) => MoveData.referenceKey(move.name) == 'surf'),
      isTrue,
    );
  });

  test('l editor separa learnset e scelta manuale globale', () {
    final source = File(
      'lib/screens/pokemon/pokemon_edit_screen.dart',
    ).readAsStringSync();

    expect(source, contains("label: 'TUTTE'"));
    expect(source, contains('Scelta manuale: la compatibilità'));
    expect(source, contains('_formPokemon.moves.eggMoves'));
    expect(source, contains('ListView.builder'));
  });
}
