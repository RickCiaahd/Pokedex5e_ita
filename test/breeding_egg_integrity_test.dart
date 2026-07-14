import 'package:flutter_test/flutter_test.dart';

import 'package:pokedex_5e_ita/models/breeding_egg.dart';

void main() {
  test('i PF dell’uovo restano sempre tra zero e dieci', () {
    final egg = BreedingEgg(
      id: 'egg-integrity',
      speciesId: 1,
      parentNames: const ['Parent A', 'Parent B'],
      createdAt: DateTime.utc(2026, 7, 14),
      hatchTime: 100,
      incubationRemaining: 50,
      nature: 'Hardy',
      gender: 'Male',
      ability: 'Ability One',
      selectedMoves: const ['Tackle'],
      inheritedMoves: const [],
    );

    expect(egg.copyWith(currentHp: 99).currentHp, BreedingEgg.maxHitPoints);
    expect(egg.copyWith(currentHp: -5).currentHp, 0);
    expect(egg.copyWith(currentHp: 0).isDestroyed, isTrue);
  });
}
