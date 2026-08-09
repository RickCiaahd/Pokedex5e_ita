import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bag move replacement and held-item labels expose English text', () {
    final source = _bagSource();

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

String _bagSource() {
  final files = Directory('lib/screens/bag')
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  return files.map((file) => file.readAsStringSync()).join('\n');
}
