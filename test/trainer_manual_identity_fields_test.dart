import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/trainer_manual_options.dart';
import 'package:pokedex_5e_ita/models/trainer_ui_localization.dart';

void main() {
  test('manual trainer fields expose descriptions', () {
    expect(TrainerManualOptions.startingPacks, hasLength(3));
    for (final value in TrainerManualOptions.startingPacks) {
      expect(TrainerUiLocalization.startingPackDescriptions[value], isNotEmpty);
    }
    expect(TrainerUiLocalization.backgroundOptions, hasLength(6));
    for (final value in TrainerUiLocalization.backgroundOptions) {
      expect(TrainerUiLocalization.backgroundLabels[value], isNotEmpty);
      expect(TrainerUiLocalization.backgroundDescriptions[value], isNotEmpty);
    }
  });
}
