import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bag move replacement and held-item labels expose English text', () {
    final source = File('lib/screens/bag/bag_screen.dart').readAsStringSync();

    for (final englishText in [
      "'REMOVE'",
      "'Replace'",
      "'Range",
      "'Damage",
      "'Time'",
      "'Duration'",
      "'Target'",
      'is learning',
    ]) {
      expect(source, contains(englishText), reason: englishText);
    }

    expect(source, isNot(contains("trailing: Text('Sostituisci')")));
    expect(source, isNot(contains("child: Text('TOGLI')")));
  });
}
