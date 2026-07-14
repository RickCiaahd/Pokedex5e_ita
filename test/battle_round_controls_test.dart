import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ogni fight espone un solo controllo Prossimo turno', () {
    for (final path in [
      'lib/screens/battle/battle_screen.dart',
      'lib/screens/battle/npc_battle_screen.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect('PROSSIMO TURNO'.allMatches(source).length, 1, reason: path);
      expect(source, isNot(contains('NUOVO ROUND')), reason: path);
      expect(source, isNot(contains('onNextRound')), reason: path);
      expect(source, isNot(contains('_nextRound(')), reason: path);
    }
  });
}
