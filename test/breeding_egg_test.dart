import 'package:flutter_test/flutter_test.dart';

import 'package:pokedex_5e_ita/models/breeding_egg.dart';

void main() {
  test('BreedingEgg mantiene incubazione e contenuto nel JSON', () {
    final source = BreedingEgg(
      id: 'egg-1',
      speciesId: 403,
      formName: 'Base',
      parentNames: const ['Raticate', 'Luxio'],
      createdAt: DateTime.utc(2026, 7, 14),
      hatchTime: 250,
      incubationRemaining: 120,
      nature: 'Jolly',
      gender: 'Female',
      ability: 'Rivalry',
      selectedMoves: const ['Tackle', 'Quick Attack'],
      inheritedMoves: const ['Quick Attack'],
      incubator: EggIncubator.plus,
      carriedEntireIncubation: false,
    );

    final decoded = BreedingEgg.fromJson(source.toJson());
    expect(decoded.id, 'egg-1');
    expect(decoded.speciesId, 403);
    expect(decoded.incubationRemaining, 120);
    expect(decoded.incubator, EggIncubator.plus);
    expect(decoded.incubator.label, 'Plus');
    expect(decoded.incubator.extraD20, 2);
    expect(decoded.inheritedMoves, ['Quick Attack']);
    expect(decoded.carriedEntireIncubation, isFalse);
    expect(decoded.isReady, isFalse);
    expect(decoded.progress, closeTo(0.52, 0.001));
  });
}
