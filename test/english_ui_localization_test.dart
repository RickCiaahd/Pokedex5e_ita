import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/localization/game_catalog_locale.dart';
import 'package:pokedex_5e_ita/models/battle_transformation.dart';
import 'package:pokedex_5e_ita/models/trainer_ui_localization.dart';
import 'package:pokedex_5e_ita/services/battle_status_rules.dart';
import 'package:pokedex_5e_ita/services/battle_transformation_service.dart';

void main() {
  tearDown(() => GameCatalogLocale.setLanguageCode('it'));

  test('English mode localizes generated Battle Companion text', () {
    GameCatalogLocale.setLanguageCode('en');

    expect(BattleTransformationKind.mega.label, 'Mega Evolution');
    expect(BattleStatusMoment.turnStart.label, 'START OF TURN');
    expect(
      BattleTransformationService.effectSummary(
        const BattleTransformationState(kind: BattleTransformationKind.mega),
      ),
      contains('AC +2'),
    );

    final blocked = BattleTransformationService.eligibility(
      kind: BattleTransformationKind.mega,
      pokemonLevel: 10,
      isFinalEvolutionStage: true,
      heldItemId: null,
      inventory: const [],
      trainerUses: const {},
      pokemonAlreadyTransformed: false,
      hasActiveTransformation: false,
    );
    expect(
      blocked.missingRequirements,
      contains('Requires a Key Stone in the Bag'),
    );
  });

  test('English mode translates legacy Trainer Path display values only', () {
    GameCatalogLocale.setLanguageCode('en');

    expect(
      TrainerUiLocalization.optionLabel('+10 ft velocità'),
      '+10 ft Speed',
    );
    expect(
      TrainerUiLocalization.visibleText('Dadi battaglia d6'),
      'Battle Dice d6',
    );
  });

  test('Italian mode remains the default presentation', () {
    GameCatalogLocale.setLanguageCode('it');
    expect(BattleTransformationKind.mega.label, 'Mega Evoluzione');
    expect(BattleStatusMoment.turnStart.label, 'INIZIO TURNO');
  });
}
