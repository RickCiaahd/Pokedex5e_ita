part of 'bag_screen.dart';

class _BagData {
  const _BagData({
    required this.profile,
    required this.catalog,
    required this.inventory,
    required this.team,
    required this.pokemonById,
  });

  final UserProfile profile;
  final List<BagItem> catalog;
  final List<BagInventoryEntry> inventory;
  final List<TeamSlot> team;
  final Map<int, Pokemon> pokemonById;

  Map<String, BagItem> get itemById => {
    for (final item in catalog) item.id: item,
  };

  BagItem? itemByReference(String reference) {
    final trimmed = reference.trim();
    if (trimmed.isEmpty) return null;

    final direct = itemById[trimmed];
    if (direct != null) return direct;

    final target = _itemReferenceKey(trimmed);
    for (final item in catalog) {
      if (_itemReferenceKey(item.id) == target ||
          _itemReferenceKey(item.name) == target) {
        return item;
      }
    }

    return null;
  }

  List<_OwnedBagItem> get ownedItems {
    final itemsById = itemById;
    final owned = <_OwnedBagItem>[];

    for (final entry in inventory) {
      final item = itemsById[entry.itemId];
      if (item != null) {
        owned.add(_OwnedBagItem(item: item, quantity: entry.quantity));
      }
    }

    owned.sort((a, b) {
      final typeCompare = a.item.type.compareTo(b.item.type);
      if (typeCompare != 0) return typeCompare;
      return a.item.name.compareTo(b.item.name);
    });

    return owned;
  }

  List<_EquippedHeldItem> get equippedHeldItems {
    final equipped = <_EquippedHeldItem>[];

    for (final slot in team) {
      final pokemonId = slot.pokemonId;
      final heldItemReference = slot.heldItem;
      if (pokemonId == null ||
          heldItemReference == null ||
          heldItemReference.trim().isEmpty) {
        continue;
      }

      final pokemon = pokemonById[pokemonId];
      final item = itemByReference(heldItemReference);
      if (pokemon == null || item == null) continue;

      equipped.add(_EquippedHeldItem(slot: slot, pokemon: pokemon, item: item));
    }

    equipped.sort((a, b) => a.slot.slotIndex.compareTo(b.slot.slotIndex));
    return equipped;
  }
}

class _OwnedBagItem {
  const _OwnedBagItem({required this.item, required this.quantity});

  final BagItem item;
  final int quantity;
}

class _HeldItemCandidate {
  const _HeldItemCandidate({required this.slot, required this.pokemon});

  final TeamSlot slot;
  final Pokemon pokemon;

  String get displayName => slot.nickname ?? pokemon.name;
}

class _EquippedHeldItem {
  const _EquippedHeldItem({
    required this.slot,
    required this.pokemon,
    required this.item,
  });

  final TeamSlot slot;
  final Pokemon pokemon;
  final BagItem item;

  String get displayName => slot.nickname ?? pokemon.name;
}

class _TmCandidate {
  const _TmCandidate({required this.slot, required this.pokemon});

  final TeamSlot slot;
  final Pokemon pokemon;
}

class _MedicineCandidate {
  const _MedicineCandidate({required this.slot, required this.pokemon});

  final TeamSlot slot;
  final Pokemon pokemon;

  String get displayName => slot.nickname ?? pokemon.name;
}

class _MedicineUseResult {
  const _MedicineUseResult({required this.updatedSlot, required this.message});

  final TeamSlot updatedSlot;
  final String message;
}

enum _BagAction { find, buy }

int _salePriceFor(BagItem item) {
  final cost = item.cost;
  if (cost == null || cost <= 0) return 0;
  return cost ~/ 2;
}

const Set<String> _healingItemIds = {
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
};

const Set<String> _berryMedicineItemIds = {
  'cheri-berry',
  'chesto-berry',
  'pecha-berry',
  'rawst-berry',
  'aspear-berry',
  'persim-berry',
  'lum-berry',
  'oran-berry',
  'sitrus-berry',
};

const Set<String> _statusMedicineItemIds = {
  'antidote',
  'burn-heal',
  'ice-heal',
  'awakening',
  'paralyze-heal',
  'full-heal',
  'full-restore',
  'heal-powder',
};

const Map<String, Set<String>> _statusTargetsByMedicine = {
  'cheri-berry': {'Paralyzed'},
  'chesto-berry': {'Asleep'},
  'pecha-berry': {'Poisoned', 'Badly Poisoned'},
  'rawst-berry': {'Burned'},
  'aspear-berry': {'Frozen'},
  'persim-berry': {'Confused'},
  'lum-berry': {'*'},
  'antidote': {'Poisoned', 'Badly Poisoned'},
  'burn-heal': {'Burned'},
  'ice-heal': {'Frozen'},
  'awakening': {'Asleep'},
  'paralyze-heal': {'Paralyzed'},
  'full-heal': {'*'},
  'full-restore': {'*'},
  'heal-powder': {'*'},
};
