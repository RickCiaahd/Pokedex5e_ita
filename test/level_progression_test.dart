import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/level_progression.dart';

void main() {
  group('LevelProgression', () {
    test('adds experience with signed input and recalculates level', () {
      final experience = LevelProgression.applyExperienceInput(
        currentExperience: 0,
        input: '+2000',
      );

      expect(experience, 2000);
      expect(LevelProgression.levelFromExperience(experience), 4);
      expect(LevelProgression.nextThresholdForLevel(4), 6000);
    });

    test('sets absolute experience with unsigned input', () {
      final experience = LevelProgression.applyExperienceInput(
        currentExperience: 800,
        input: '12000',
      );

      expect(experience, 12000);
      expect(LevelProgression.levelFromExperience(experience), 6);
    });
  });
}
