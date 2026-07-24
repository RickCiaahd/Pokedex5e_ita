import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('il Professore del tour usa un ritaglio a tre quarti', () {
    final source = File('lib/widgets/tour/guided_tour.dart').readAsStringSync();

    expect(source, contains('final professorWidth = compact ? 112.0 : 168.0;'));
    expect(
      source,
      contains('final professorHeight = compact ? 148.0 : 210.0;'),
    );
    expect(source, contains('offset: const Offset(0, 8)'));
    expect(source, contains('fit: BoxFit.cover'));
    expect(source, contains('alignment: Alignment.topCenter'));
  });
}
