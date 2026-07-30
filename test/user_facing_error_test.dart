import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/l10n/app_localizations.dart';
import 'package:pokedex_5e_ita/localization/user_facing_error.dart';

void main() {
  testWidgets('technical exception details never reach the user interface', (
    tester,
  ) async {
    late String italianMessage;
    late String englishMessage;
    final technicalError = Exception('HiveError: box is already open');

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('it'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            italianMessage = context.userFacingError(
              technicalError,
              action: UserFacingErrorAction.load,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            englishMessage = context.userFacingError(
              technicalError,
              action: UserFacingErrorAction.load,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(italianMessage, 'Non è stato possibile caricare i dati. Riprova.');
    expect(englishMessage, 'The data could not be loaded. Try again.');
    expect(italianMessage, isNot(contains('HiveError')));
    expect(englishMessage, isNot(contains('HiveError')));
  });

  test('screens do not render caught exceptions directly', () {
    final violations = <String>[];

    for (final entity in Directory('lib/screens').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      if (RegExp(
        r'\b(?:error|exception|e)\.toString\(\)|snapshot\.error\.toString\(\)',
      ).hasMatch(source)) {
        violations.add(entity.path);
      }
    }

    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
