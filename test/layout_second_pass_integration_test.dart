import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('le schermate principali usano il secondo passaggio responsivo', () {
    final home = File('lib/screens/home/home_screen.dart').readAsStringSync();
    final pokedex = File(
      'lib/screens/pokedex/pokedex_screen.dart',
    ).readAsStringSync();
    final pc = File('lib/screens/pc/pokemon_pc_screen.dart').readAsStringSync();
    final bag = File('lib/screens/bag/bag_screen.dart').readAsStringSync();

    expect(home, contains('maxWidth: 1040'));
    expect(home, contains('_TrainerInfoChip'));
    expect(pokedex, contains('_buildFilterControls'));
    expect(pokedex, contains('maxWidth: 1440'));
    expect(pc, contains('maxWidth: 1280'));
    expect(pc, contains('? 112'));
    expect(bag, contains('maxWidth: 1180'));
    expect(bag, contains('_BagItemsLayout'));
  });
}
