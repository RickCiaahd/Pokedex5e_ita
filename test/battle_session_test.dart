import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/battle_session.dart';
import 'package:pokedex_5e_ita/models/team_slot.dart';

void main() {
  test('battle session survives JSON round trip', () {
    final slot = TeamSlot(
      slotIndex: 2,
      pokemonId: 19,
      nickname: 'Morsi',
      formName: 'Alolan',
      selectedMoves: const ['Bite', 'Quick Attack'],
      isShiny: true,
    );
    final state = BattlePokemonState(
      slotIndex: slot.slotIndex,
      pokemonId: slot.pokemonId!,
      identityKey: BattlePokemonState.identityKeyFor(slot),
      remainingPp: const {'bite': 3},
      volatileStatuses: const {'Confused'},
    );
    final session = BattleSession(
      profileId: 'profile-1',
      round: 4,
      turnIndex: 1,
      activeSlotIndex: 2,
      pokemonStates: {2: state},
      initiativeEntries: const [
        BattleInitiativeEntry(
          id: 'trainer',
          name: 'Riccardo + Morsi',
          initiative: 16,
          isTrainerGroup: true,
        ),
        BattleInitiativeEntry(
          id: 'boss',
          name: 'Boss',
          initiative: 12,
          isTrainerGroup: false,
        ),
      ],
      updatedAt: DateTime.utc(2026, 7, 11),
    );

    final restored = BattleSession.fromJson(session.toJson());

    expect(restored.profileId, 'profile-1');
    expect(restored.round, 4);
    expect(restored.turnIndex, 1);
    expect(restored.activeSlotIndex, 2);
    expect(restored.pokemonStates[2]?.remainingPp['bite'], 3);
    expect(restored.pokemonStates[2]?.volatileStatuses, {'Confused'});
    expect(restored.initiativeEntries.last.name, 'Boss');
  });

  test(
    'saved transient state is rejected for a different Pokémon instance',
    () {
      final original = TeamSlot(
        slotIndex: 0,
        pokemonId: 19,
        nickname: 'Morsi',
        formName: 'Alolan',
      );
      final state = BattlePokemonState(
        slotIndex: 0,
        pokemonId: 19,
        identityKey: BattlePokemonState.identityKeyFor(original),
        remainingPp: const {'bite': 2},
        volatileStatuses: const {'Flinched'},
      );

      final replacement = TeamSlot(
        slotIndex: 0,
        pokemonId: 19,
        nickname: 'Un altro Rattata',
        formName: 'Alolan',
      );

      expect(state.matches(original), isTrue);
      expect(state.matches(replacement), isFalse);
    },
  );
}
