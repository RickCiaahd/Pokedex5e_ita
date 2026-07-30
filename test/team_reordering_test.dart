import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/team_slot.dart';
import 'package:pokedex_5e_ita/repositories/team_repository.dart';

void main() {
  test('reordering moves a Pokémon and shifts the intermediate slots', () {
    final bulbasaur = TeamSlot(
      slotIndex: 0,
      pokemonId: 1,
      nickname: 'Bulby',
      currentHp: 18,
      selectedMoves: const ['tackle', 'vine-whip'],
      isShiny: true,
      nature: 'Brave',
      heldItem: 'miracle-seed',
      abilities: const ['Overgrow'],
      feats: const ['Tough'],
      extraSkills: const ['Athletics'],
      customAbilityScores: const {'STR': 1},
      loyalty: 3,
    );
    final charmander = TeamSlot(slotIndex: 1, pokemonId: 4);
    final empty = TeamSlot(slotIndex: 2, pokemonId: null);

    final reordered = TeamRepository.reorderTeam(
      [empty, bulbasaur, charmander],
      fromSlotIndex: 0,
      toSlotIndex: 2,
    );

    expect(reordered.map((slot) => slot.slotIndex), [0, 1, 2]);
    expect(reordered.map((slot) => slot.pokemonId), [4, null, 1]);

    final moved = reordered[2];
    expect(moved.nickname, 'Bulby');
    expect(moved.currentHp, 18);
    expect(moved.selectedMoves, ['tackle', 'vine-whip']);
    expect(moved.isShiny, isTrue);
    expect(moved.nature, 'Brave');
    expect(moved.heldItem, 'miracle-seed');
    expect(moved.abilities, ['Overgrow']);
    expect(moved.feats, ['Tough']);
    expect(moved.extraSkills, ['Athletics']);
    expect(moved.customAbilityScores, {'STR': 1});
    expect(moved.loyalty, 3);
  });

  test('reordering supports moving a Pokémon towards the first slot', () {
    final team = [
      TeamSlot(slotIndex: 0, pokemonId: 1),
      TeamSlot(slotIndex: 1, pokemonId: 4),
      TeamSlot(slotIndex: 2, pokemonId: 7),
    ];

    final reordered = TeamRepository.reorderTeam(
      team,
      fromSlotIndex: 2,
      toSlotIndex: 0,
    );

    expect(reordered.map((slot) => slot.pokemonId), [7, 1, 4]);
    expect(reordered.map((slot) => slot.slotIndex), [0, 1, 2]);
  });

  test('reordering rejects unknown slots without changing the source list', () {
    final team = [
      TeamSlot(slotIndex: 0, pokemonId: 1),
      TeamSlot(slotIndex: 1, pokemonId: 4),
    ];

    expect(
      () => TeamRepository.reorderTeam(
        team,
        fromSlotIndex: 0,
        toSlotIndex: 5,
      ),
      throwsRangeError,
    );
    expect(team.map((slot) => slot.pokemonId), [1, 4]);
  });

  test('the team screen exposes long-press drag reordering in both languages', () {
    final source = File(
      'lib/screens/team/team_selection_screen.dart',
    ).readAsStringSync();

    for (final marker in [
      'DragTarget<int>',
      'LongPressDraggable<int>',
      'onDragUpdate: _autoScrollDuringDrag',
      'Tieni premuto un Pokémon e trascinalo per cambiare l’ordine.',
      'Press and hold a Pokémon, then drag it to change the order.',
      'Ordine della squadra aggiornato.',
      'Team order updated.',
    ]) {
      expect(source, contains(marker), reason: marker);
    }
  });
}
