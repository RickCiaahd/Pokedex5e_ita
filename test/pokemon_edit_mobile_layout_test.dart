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

  test('nature and gender dropdowns stay within their mobile columns', () {
    final source = File(
      'lib/screens/pokemon/pokemon_edit_screen.dart',
    ).readAsStringSync();
    final fieldsStart = source.indexOf(
      'DropdownButtonFormField<String>(',
    );
    final fieldsEnd = source.indexOf(
      'SwitchListTile(',
      fieldsStart,
    );

    expect(fieldsStart, greaterThanOrEqualTo(0));
    expect(fieldsEnd, greaterThan(fieldsStart));

    final fieldsSource = source.substring(fieldsStart, fieldsEnd);
    expect('isExpanded: true'.allMatches(fieldsSource), hasLength(2));
    expect(fieldsSource, contains('maxLines: 1'));
    expect(fieldsSource, contains('overflow: TextOverflow.ellipsis'));
  });

  test('feat definitions are not truncated in the picker', () {
    final source = File(
      'lib/screens/pokemon/pokemon_edit_screen.dart',
    ).readAsStringSync();
    final featPickerStart = source.indexOf(
      "title: uiTextForLanguage(\n            'Scegli privilegio',",
    );
    final featPickerEnd = source.indexOf(
      '),\n      ),\n    );',
      featPickerStart,
    );

    expect(featPickerStart, greaterThanOrEqualTo(0));
    expect(featPickerEnd, greaterThan(featPickerStart));

    final featPickerSource = source.substring(
      featPickerStart,
      featPickerEnd,
    );
    expect(featPickerSource, contains('descriptionMaxLines: null'));
    expect(source, contains('maxLines: subtitleMaxLines'));
    expect(
      source,
      contains(
        'overflow: subtitleMaxLines == null\n'
        '                    ? TextOverflow.visible',
      ),
    );
  });
}
