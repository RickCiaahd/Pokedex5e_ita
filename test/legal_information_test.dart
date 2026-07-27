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
    expect(
      legalScreen,
      contains(
        'The current version does not load game images or data from remote hosts',
      ),
    );
  });

  test('release compliance documents are present', () {
    final expectedFiles = <String>[
      'LICENSE',
      'NOTICE.md',
      'docs/privacy-policy.md',
      'docs/google-play-data-safety-draft.md',
      'docs/compliance/code-and-license-audit.md',
      'docs/compliance/asset-inventory.md',
      'docs/compliance/dependency-licenses.md',
      'docs/compliance/dependency-licenses.csv',
      'docs/compliance/asset-audit-summary.md',
      'docs/compliance/asset-manifest.csv',
    ];

    for (final path in expectedFiles) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: '$path is missing');
      expect(file.readAsStringSync().trim(), isNotEmpty, reason: path);
    }

    final license = File('LICENSE').readAsStringSync();
    expect(license, contains('GNU GENERAL PUBLIC LICENSE'));
    expect(license, contains('Version 3, 29 June 2007'));
    expect(license, contains('END OF TERMS AND CONDITIONS'));
    expect(
      license,
      contains('How to Apply These Terms to Your New Programs'),
    );

    final notice = File('NOTICE.md').readAsStringSync();
    expect(notice, contains('GPL-3.0-only'));
    expect(notice, contains('Jerakin/Pokedex5E'));
    expect(notice, contains('corresponding source code'));

    final dependencyReport = File(
      'docs/compliance/dependency-licenses.md',
    ).readAsStringSync();
    expect(dependencyReport, contains('Packages in lockfile'));
    expect(dependencyReport, contains('Detected licence families'));

    final assetReport = File(
      'docs/compliance/asset-audit-summary.md',
    ).readAsStringSync();
    expect(assetReport, contains('Asset files'));
    expect(assetReport, contains('Machine-readable inventory'));

    final audit = File(
      'docs/compliance/code-and-license-audit.md',
    ).readAsStringSync();
    expect(audit, contains('bloccante'));
    expect(audit, contains('codice sorgente corrispondente'));

    final dataSafety = File(
      'docs/google-play-data-safety-draft.md',
    ).readAsStringSync();
    expect(dataSafety, contains('Risposta finale sospesa'));
    expect(dataSafety, contains('permesso Android `INTERNET` assente'));
    expect(dataSafety, contains('fallback remoti delle immagini eliminati'));
  });
}
