import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('long Pokémon edit section titles can wrap on narrow screens', () {
    final source = File(
      'lib/screens/pokemon/pokemon_edit_screen.dart',
    ).readAsStringSync();
    final sectionStart = source.indexOf(
      'class _CollapsibleEditSection extends StatelessWidget',
    );
    final sectionEnd = source.indexOf(
      'class _MoveSlotGrid extends StatelessWidget',
    );

    expect(sectionStart, greaterThanOrEqualTo(0));
    expect(sectionEnd, greaterThan(sectionStart));

    final sectionSource = source.substring(sectionStart, sectionEnd);
    expect(sectionSource, contains('Flexible('));
    expect(sectionSource, contains('textAlign: TextAlign.center'));
    expect(sectionSource, contains('softWrap: true'));
  });
}
