import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/trainer_progression.dart';

void main() {
  group('TrainerProgression', () {
    test('returns pokeslots from trainer level breakpoints', () {
      expect(TrainerProgression.pokeslotsForLevel(1), 3);
      expect(TrainerProgression.pokeslotsForLevel(4), 3);
      expect(TrainerProgression.pokeslotsForLevel(5), 4);
      expect(TrainerProgression.pokeslotsForLevel(10), 5);
      expect(TrainerProgression.pokeslotsForLevel(15), 6);
      expect(TrainerProgression.pokeslotsForLevel(30), 6);
    });

    test('returns max controlled SR from trainer level breakpoints', () {
      expect(TrainerProgression.maxControlledSrForLevel(1), 2);
      expect(TrainerProgression.maxControlledSrForLevel(3), 5);
      expect(TrainerProgression.maxControlledSrForLevel(6), 8);
      expect(TrainerProgression.maxControlledSrForLevel(8), 10);
      expect(TrainerProgression.maxControlledSrForLevel(11), 12);
      expect(TrainerProgression.maxControlledSrForLevel(14), 14);
      expect(TrainerProgression.maxControlledSrForLevel(17), 15);
    });

    test('checks if a trainer can control a Pokemon SR', () {
      expect(
        TrainerProgression.canControlSr(trainerLevel: 2, pokemonSr: 2),
        isTrue,
      );
      expect(
        TrainerProgression.canControlSr(trainerLevel: 2, pokemonSr: 2.5),
        isFalse,
      );
      expect(
        TrainerProgression.canControlSr(trainerLevel: 17, pokemonSr: 15),
        isTrue,
      );
    });
  });
}
