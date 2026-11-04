import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/localization/game_catalog_locale.dart';
import 'package:pokedex_5e_ita/models/trainer_manual_content.dart';

void main() {
  final originalLanguage = GameCatalogLocale.languageCode;
  tearDown(() => GameCatalogLocale.setLanguageCode(originalLanguage));

  test(
    'all bundled path descriptions follow language changes without reload',
    () {
      final data =
          jsonDecode(File('assets/data/trainer_paths.json').readAsStringSync())
              as List;
      expect(data, hasLength(14));
      for (final raw in data) {
        final path = TrainerPath.fromJson(
          Map<String, dynamic>.from(raw as Map),
        );
        expect(path.features, hasLength(4));
        for (var i = 0; i < path.features.length; i++) {
          final feature = path.features[i];
          final source = raw['features'][i];
          expect(source['descriptionEn'], isNotEmpty);
          expect(source['descriptionEn'], isNot(source['description']));
          GameCatalogLocale.setLanguageCode('en');
          expect(feature.description, source['descriptionEn']);
          GameCatalogLocale.setLanguageCode('it');
          expect(feature.description, source['description']);
          expect(feature.title, source['title']);
          expect(feature.level, source['level']);
        }
      }
    },
  );

  test('legacy features retain their description without an English field', () {
    final feature = TrainerPathFeature.fromJson({
      'level': 2,
      'title': 'Custom',
      'description': 'Custom description',
    });
    GameCatalogLocale.setLanguageCode('en');
    expect(feature.description, 'Custom description');
  });
}
