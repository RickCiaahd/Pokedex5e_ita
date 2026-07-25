import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/localization/game_catalog_locale.dart';
import 'package:pokedex_5e_ita/localization/ui_text.dart';
import 'package:pokedex_5e_ita/models/trainer_ui_localization.dart';
import 'package:pokedex_5e_ita/widgets/pokemon/pokemon_asset_image.dart';

void main() {
  tearDown(() {
    GameCatalogLocale.setLanguageCode('it');
  });

  test('trainer labels follow the effective application language', () {
    GameCatalogLocale.setLanguageCode('it');
    expect(TrainerUiLocalization.abilityAbbreviation('STR'), 'FOR');
    expect(
      TrainerUiLocalization.skillName('Animal Handling'),
      'Addestrare Animali',
    );

    GameCatalogLocale.setLanguageCode('en');
    expect(TrainerUiLocalization.abilityAbbreviation('STR'), 'STR');
    expect(
      TrainerUiLocalization.skillName('Animal Handling'),
      'Animal Handling',
    );
    expect(TrainerUiLocalization.trainerPathName('Ace Trainer'), 'Ace Trainer');
  });

  test('type badges use English text instead of Italian image labels', () {
    GameCatalogLocale.setLanguageCode('en');
    expect(PokemonAssetPaths.localizedTypeLabel('fire'), 'Fire');
    expect(PokemonAssetPaths.typeCandidates('fire'), isEmpty);

    GameCatalogLocale.setLanguageCode('it');
    expect(PokemonAssetPaths.localizedTypeLabel('fire'), 'Fuoco');
    expect(PokemonAssetPaths.typeCandidates('fire'), isNotEmpty);
  });

  testWidgets('secondary UI helper follows the widget locale', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Text(context.uiText('Scheda', 'Sheet')),
        ),
      ),
    );

    expect(find.text('Sheet'), findsOneWidget);
    expect(find.text('Scheda'), findsNothing);
  });
}
