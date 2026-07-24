import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/localization/game_catalog_locale.dart';

void main() {
  tearDown(() {
    GameCatalogLocale.setLanguageCode('it');
  });

  test('normalizza le lingue supportate e usa inglese come fallback', () {
    GameCatalogLocale.setLanguageCode('it');
    expect(GameCatalogLocale.languageCode, 'it');
    expect(GameCatalogLocale.isItalian, isTrue);

    GameCatalogLocale.setLanguageCode('en-US');
    expect(GameCatalogLocale.languageCode, 'en');
    expect(GameCatalogLocale.isEnglish, isTrue);

    GameCatalogLocale.setLanguageCode('fr');
    expect(GameCatalogLocale.languageCode, 'en');
  });

  test('incrementa la revisione soltanto quando cambia lingua effettiva', () {
    GameCatalogLocale.setLanguageCode('it');
    final initialRevision = GameCatalogLocale.revision;

    expect(GameCatalogLocale.setLanguageCode('it-IT'), isFalse);
    expect(GameCatalogLocale.revision, initialRevision);

    expect(GameCatalogLocale.setLanguageCode('en'), isTrue);
    expect(GameCatalogLocale.revision, initialRevision + 1);
  });
}
