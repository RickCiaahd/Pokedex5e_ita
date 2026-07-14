import 'package:flutter_test/flutter_test.dart';

import 'package:pokedex_5e_ita/models/breeding_egg.dart';

void main() {
  test('i salvataggi precedenti considerano l’uovo fuori dal PC', () {
    final egg = BreedingEgg.fromJson({
      'id': 'legacy-egg',
      'speciesId': 1,
      'parentNames': <String>[],
      'createdAt': DateTime.utc(2026, 7, 14).toIso8601String(),
      'hatchTime': 100,
      'incubationRemaining': 50,
      'nature': 'Hardy',
      'selectedMoves': <String>[],
      'inheritedMoves': <String>[],
    });

    expect(egg.isInPc, isFalse);
    expect(egg.isInDayCare, isFalse);
    expect(egg.isInTeam, isTrue);
  });

  test('deposito e ritiro dal PC mantengono il contenuto dell’uovo', () {
    final source = BreedingEgg(
      id: 'pc-egg',
      speciesId: 403,
      parentNames: const ['Luxio', 'Ditto'],
      createdAt: DateTime.utc(2026, 7, 14),
      hatchTime: 250,
      incubationRemaining: 100,
      nature: 'Jolly',
      gender: 'Female',
      ability: 'Rivalry',
      selectedMoves: const ['Tackle'],
      inheritedMoves: const ['Quick Attack'],
    );

    final stored = source.copyWith(
      isInPc: true,
      isInDayCare: false,
      carriedEntireIncubation: false,
    );
    final decoded = BreedingEgg.fromJson(stored.toJson());
    expect(decoded.isInPc, isTrue);
    expect(decoded.isInTeam, isFalse);
    expect(decoded.speciesId, source.speciesId);
    expect(decoded.selectedMoves, source.selectedMoves);
    expect(decoded.inheritedMoves, source.inheritedMoves);

    final withdrawn = decoded.copyWith(isInPc: false, isInDayCare: false);
    expect(withdrawn.isInTeam, isTrue);
    expect(withdrawn.carriedEntireIncubation, isFalse);
  });
}
