import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/battle_session.dart';

void main() {
  test('battle form rule state survives session serialization', () {
    const state = BattlePokemonState(
      slotIndex: 2,
      pokemonId: 746,
      identityKey: 'wishiwashi',
      remainingPp: {},
      volatileStatuses: {},
      battleFormName: 'Base',
      formRuleState: {'wishiwashi-schooling-locked': 1},
    );

    final restored = BattlePokemonState.fromJson(state.toJson());

    expect(restored.battleFormName, 'Base');
    expect(restored.formRuleState['wishiwashi-schooling-locked'], 1);
  });

  test('old session state without form rules remains compatible', () {
    final restored = BattlePokemonState.fromJson(const {
      'slotIndex': 0,
      'pokemonId': 778,
      'identityKey': 'mimikyu',
      'remainingPp': <String, int>{},
      'volatileStatuses': <String>[],
    });

    expect(restored.formRuleState, isEmpty);
  });
}
