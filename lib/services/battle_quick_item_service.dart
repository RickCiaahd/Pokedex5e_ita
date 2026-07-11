import '../models/bag_inventory_entry.dart';
import '../models/bag_item.dart';

class BattleQuickItem {
  const BattleQuickItem({required this.item, required this.quantity});

  final BagItem item;
  final int quantity;
}

class BattleQuickItemService {
  const BattleQuickItemService._();

  static List<BattleQuickItem> resolve({
    required List<BagItem> catalog,
    required List<BagInventoryEntry> inventory,
  }) {
    final itemsByReference = <String, BagItem>{};
    for (final item in catalog) {
      itemsByReference.putIfAbsent(_referenceKey(item.id), () => item);
      itemsByReference.putIfAbsent(_referenceKey(item.name), () => item);
    }

    final owned = <BattleQuickItem>[];
    for (final entry in inventory) {
      if (entry.quantity <= 0) continue;
      final item = itemsByReference[_referenceKey(entry.itemId)];
      if (item == null || !isQuickBattleItem(item)) continue;
      owned.add(BattleQuickItem(item: item, quantity: entry.quantity));
    }

    owned.sort((a, b) {
      final typeCompare = typeLabel(
        a.item.type,
      ).compareTo(typeLabel(b.item.type));
      if (typeCompare != 0) return typeCompare;
      return a.item.name.compareTo(b.item.name);
    });
    return owned;
  }

  static bool isQuickBattleItem(BagItem item) {
    return isBerry(item) || isMedicine(item) || isPokeball(item);
  }

  static bool isBerry(BagItem item) {
    return item.type == 'berry' || item.id.toLowerCase().endsWith('-berry');
  }

  static bool isPokeball(BagItem item) {
    final type = _referenceKey(item.type);
    final id = _referenceKey(item.id);
    return type == 'pokeball' ||
        type == 'poke-ball' ||
        id == 'poke-ball' ||
        id.endsWith('-ball');
  }

  static bool isMedicine(BagItem item) {
    return item.type == 'medicine' || _knownMedicineIds.contains(item.id);
  }

  static String typeLabel(String type) {
    switch (type) {
      case 'berry':
        return 'Bacca';
      case 'medicine':
        return 'Medicina';
      case 'pokeball':
        return 'Poké Ball';
      default:
        return type;
    }
  }

  static String _referenceKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r"[’']"), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  static const Set<String> _knownMedicineIds = {
    'potion',
    'super-potion',
    'hyper-potion',
    'max-potion',
    'full-restore',
    'revive',
    'max-revive',
    'fresh-water',
    'soda-pop',
    'berry-juice',
    'lemonade',
    'moomoo-milk',
    'energy-powder',
    'energy-root',
    'revival-herb',
    'antidote',
    'burn-heal',
    'ice-heal',
    'awakening',
    'paralyze-heal',
    'full-heal',
    'heal-powder',
  };
}
