import 'package:flutter_test/flutter_test.dart';

import 'package:pokedex_5e_ita/models/team_slot.dart';

void main() {
  test('TeamSlot conserva un uovo e lo considera uno slot occupato', () {
    final slot = TeamSlot(slotIndex: 2, pokemonId: null, eggId: 'egg-42');
    final restored = TeamSlot.fromJson(slot.toJson());

    expect(restored.eggId, 'egg-42');
    expect(restored.isEgg, isTrue);
    expect(restored.isEmpty, isFalse);
    expect(restored.isPokemon, isFalse);
  });

  test('inserire un Pokémon rimuove l’uovo dallo slot', () {
    final slot = TeamSlot(slotIndex: 1, pokemonId: null, eggId: 'egg-1');
    final updated = slot.copyWith(pokemonId: 25, clearEgg: true);

    expect(updated.pokemonId, 25);
    expect(updated.eggId, isNull);
    expect(updated.isPokemon, isTrue);
  });
}
