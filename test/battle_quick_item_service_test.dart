import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/bag_inventory_entry.dart';
import 'package:pokedex_5e_ita/models/bag_item.dart';
import 'package:pokedex_5e_ita/services/battle_quick_item_service.dart';

void main() {
  const catalog = [
    BagItem(
      id: 'potion',
      name: 'Potion',
      type: 'other',
      description: ['Cura HP.'],
      cost: 200,
      spriteAssetPath: null,
    ),
    BagItem(
      id: 'oran-berry',
      name: 'Oran Berry',
      type: 'berry',
      description: ['Cura HP.'],
      cost: null,
      spriteAssetPath: null,
    ),
    BagItem(
      id: 'great-ball',
      name: 'Great Ball',
      type: 'capture-item',
      description: ['Cattura Pokémon.'],
      cost: 600,
      spriteAssetPath: null,
    ),
    BagItem(
      id: 'leftovers',
      name: 'Leftovers',
      type: 'held-item',
      description: ['Strumento tenuto.'],
      cost: null,
      spriteAssetPath: null,
    ),
    BagItem(
      id: 'light-ball',
      name: 'Light Ball',
      type: 'held-item',
      description: ['Strumento tenuto.'],
      cost: null,
      spriteAssetPath: null,
    ),
  ];

  test('resolves usable battle items even with non-standard catalog types', () {
    const inventory = [
      BagInventoryEntry(profileId: 'p1', itemId: 'Potion', quantity: 2),
      BagInventoryEntry(profileId: 'p1', itemId: 'oran-berry', quantity: 1),
      BagInventoryEntry(profileId: 'p1', itemId: 'great ball', quantity: 3),
      BagInventoryEntry(profileId: 'p1', itemId: 'leftovers', quantity: 1),
      BagInventoryEntry(profileId: 'p1', itemId: 'light-ball', quantity: 1),
    ];

    final items = BattleQuickItemService.resolve(
      catalog: catalog,
      inventory: inventory,
    );

    expect(items.map((entry) => entry.item.id), {
      'potion',
      'oran-berry',
      'great-ball',
    });
    expect(items.firstWhere((entry) => entry.item.id == 'potion').quantity, 2);
  });

  test('classifies Poké Ball IDs without relying on the type field', () {
    expect(BattleQuickItemService.isPokeball(catalog[2]), isTrue);
    expect(BattleQuickItemService.isQuickBattleItem(catalog[3]), isFalse);
    expect(BattleQuickItemService.isPokeball(catalog[4]), isFalse);
  });
}
