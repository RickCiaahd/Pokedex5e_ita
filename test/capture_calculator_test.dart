import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/capture_calculator.dart';

void main() {
  group('CaptureCalculator', () {
    test('calculates the manual catch DC formula', () {
      final check = CaptureCalculator.check(
        trainerLevel: 5,
        pokemonLevel: 3,
        pokemonSr: 0.5,
        remainingHp: 15,
        statusConditions: const ['poisoned'],
      );

      expect(check.canAttempt, isTrue);
      expect(check.dc, 14);
      expect(check.hasAdvantage, isTrue);
    });

    test('blocks capture above trainer level', () {
      final check = CaptureCalculator.check(
        trainerLevel: 4,
        pokemonLevel: 5,
        pokemonSr: 1,
        remainingHp: 10,
      );

      expect(check.canAttempt, isFalse);
      expect(check.dc, isNull);
      expect(check.blockedReason, isNotNull);
    });

    test('blocks capture for fainted Pokemon', () {
      final check = CaptureCalculator.check(
        trainerLevel: 5,
        pokemonLevel: 3,
        pokemonSr: 1,
        remainingHp: 0,
      );

      expect(check.canAttempt, isFalse);
      expect(check.dc, isNull);
      expect(check.blockedReason, isNotNull);
    });

    test('applies pokeball bonus by lowering DC', () {
      expect(
        CaptureCalculator.catchDc(
          pokemonLevel: 3,
          pokemonSr: 1,
          remainingHp: 20,
          pokeballBonus: 2,
        ),
        14,
      );
    });
  });
}
