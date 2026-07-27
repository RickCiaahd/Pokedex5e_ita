import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('settings exposes about licenses and privacy pages', () {
    final settings = File(
      'lib/screens/settings/settings_screen.dart',
    ).readAsStringSync();
    final legalScreen = File(
      'lib/screens/settings/legal_information_screen.dart',
    ).readAsStringSync();

    expect(settings, contains('LegalInformationSection.about'));
    expect(settings, contains('LegalInformationSection.licenses'));
    expect(settings, contains('LegalInformationSection.privacy'));
    expect(settings, contains("'Informazioni sull’app'"));
    expect(settings, contains("'Licenze e attribuzioni'"));
    expect(settings, contains("'Privacy'"));

    expect(legalScreen, contains('GPL-3.0-only'));
    expect(legalScreen, contains('showLicensePage'));
    expect(legalScreen, contains('https://github.com/Jerakin/Pokedex5E'));
    expect(legalScreen, contains('Android currently declares Internet permission'));
  });

  test('release compliance documents are present', () {
    final expectedFiles = <String>[
      'LICENSE',
      'docs/privacy-policy.md',
      'docs/google-play-data-safety-draft.md',
      'docs/compliance/code-and-license-audit.md',
      'docs/compliance/asset-inventory.md',
    ];

    for (final path in expectedFiles) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: '$path is missing');
      expect(file.readAsStringSync().trim(), isNotEmpty, reason: path);
    }

    final license = File('LICENSE').readAsStringSync();
    expect(license, contains('SPDX-License-Identifier: GPL-3.0-only'));
    expect(license, contains('Jerakin/Pokedex5E'));

    final audit = File(
      'docs/compliance/code-and-license-audit.md',
    ).readAsStringSync();
    expect(audit, contains('bloccante'));
    expect(audit, contains('codice sorgente corrispondente'));

    final dataSafety = File(
      'docs/google-play-data-safety-draft.md',
    ).readAsStringSync();
    expect(dataSafety, contains('Risposta finale sospesa'));
    expect(dataSafety, contains('fallback remoti'));
  });
}
