import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/bag_inventory_entry.dart';
import 'package:pokedex_5e_ita/models/battle_transformation.dart';
import 'package:pokedex_5e_ita/models/move_data.dart';
import 'package:pokedex_5e_ita/models/team_slot.dart';
import 'package:pokedex_5e_ita/services/battle_transformation_service.dart';
import 'package:pokedex_5e_ita/services/pokemon_transform_asset_catalog.dart';

void main() {
  group('BattleTransformationService', () {
    test('Mega Evolution enforces level, final stage and equipment', () {
      final unavailable = BattleTransformationService.eligibility(
        kind: BattleTransformationKind.mega,
        pokemonLevel: 9,
        isFinalEvolutionStage: false,
        heldItemId: null,
        inventory: const [],
        trainerUses: const {},
        pokemonAlreadyTransformed: false,
        hasActiveTransformation: false,
      );
      expect(unavailable.isAvailable, isFalse);
      expect(unavailable.missingRequirements.length, 4);

      final available = BattleTransformationService.eligibility(
        kind: BattleTransformationKind.mega,
        pokemonLevel: 10,
        isFinalEvolutionStage: true,
        heldItemId: 'megalite-stone',
        inventory: const [
          BagInventoryEntry(profileId: 'p', itemId: 'key-stone', quantity: 1),
        ],
        trainerUses: const {},
        pokemonAlreadyTransformed: false,
        hasActiveTransformation: false,
      );
      expect(available.isAvailable, isTrue);
    });

    test('Z-Move requires a matching known move and Z-Ring', () {
      const fireMove = MoveData(
        id: 'ember',
        name: 'Ember',
        type: 'Fire',
        pp: '10',
        range: '30 ft',
        duration: '-',
        moveTime: '1 action',
        description: '',
        scaling: null,
        damageByLevel: {},
        movePowers: ['CHA'],
        isAttack: true,
        save: null,
      );
      final available = BattleTransformationService.eligibility(
        kind: BattleTransformationKind.zMove,
        pokemonLevel: 6,
        isFinalEvolutionStage: false,
        heldItemId: 'firium-z',
        inventory: const [
          BagInventoryEntry(profileId: 'p', itemId: 'z-ring', quantity: 1),
        ],
        trainerUses: const {},
        pokemonAlreadyTransformed: false,
        hasActiveTransformation: false,
        knownMoves: const [fireMove],
      );
      expect(available.isAvailable, isTrue);
      expect(
        BattleTransformationService.zCrystalForHeldItem('firium-z')?.type,
        'Fire',
      );
    });

    test('Gigamax consumes the Dynamax trainer use', () {
      expect(BattleTransformationKind.gigamax.trainerUseId, 'dynamax');
      final blocked = BattleTransformationService.eligibility(
        kind: BattleTransformationKind.gigamax,
        pokemonLevel: 10,
        isFinalEvolutionStage: true,
        heldItemId: null,
        inventory: const [
          BagInventoryEntry(
            profileId: 'p',
            itemId: 'dynamax-band',
            quantity: 1,
          ),
        ],
        trainerUses: const {'dynamax'},
        pokemonAlreadyTransformed: false,
        hasActiveTransformation: false,
      );
      expect(blocked.isAvailable, isFalse);
    });

    test('pokemon usage key distinguishes team slots', () {
      final first = TeamSlot(slotIndex: 0, pokemonId: 25, nickname: 'Sparky');
      final second = TeamSlot(slotIndex: 1, pokemonId: 25, nickname: 'Sparky');
      expect(
        BattleTransformationService.pokemonUsageKey(first),
        isNot(BattleTransformationService.pokemonUsageKey(second)),
      );
    });
  });

  test('BattleTransformationState survives JSON persistence', () {
    const state = BattleTransformationState(
      kind: BattleTransformationKind.gigamax,
      formIdentifier: 'charizard-gmax',
      dynamaxTemporaryHp: 42,
    );
    final restored = BattleTransformationState.fromJson(state.toJson());
    expect(restored.kind, BattleTransformationKind.gigamax);
    expect(restored.formIdentifier, 'charizard-gmax');
    expect(restored.dynamaxTemporaryHp, 42);
  });

  test('2D art catalog exposes canonical Charizard transformations', () {
    final mega = PokemonTransformAssetCatalog.megaOptions(6);
    final gmax = PokemonTransformAssetCatalog.gigamaxOptions(6);
    expect(mega.map((art) => art.identifier), contains('charizard-mega-x'));
    expect(mega.map((art) => art.identifier), contains('charizard-mega-y'));
    expect(gmax.map((art) => art.identifier), contains('charizard-gmax'));
  });
}
