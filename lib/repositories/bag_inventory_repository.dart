import 'package:hive_flutter/hive_flutter.dart';

import '../database/hive_boxes.dart';
import '../models/bag_inventory_entry.dart';

class BagInventoryRepository {
  Future<Box> _box() => Hive.openBox(HiveBoxes.bagItems);

  Future<List<BagInventoryEntry>> getInventory(String profileId) async {
    final box = await _box();
    await _migrateLegacyStartingItemIds(box, profileId);

    return box.values
        .map(
          (data) => BagInventoryEntry.fromJson(Map<String, dynamic>.from(data)),
        )
        .where((entry) => entry.profileId == profileId && entry.quantity > 0)
        .toList(growable: false);
  }

  Future<void> _migrateLegacyStartingItemIds(Box box, String profileId) async {
    const aliases = {
      'trainer-license': 'trainers-license',
      'trainer-pokedex': 'pokedex',
    };
    var changed = false;

    for (final alias in aliases.entries) {
      final legacyKey = BagInventoryEntry.keyFor(profileId, alias.key);
      final legacyJson = box.get(legacyKey);
      if (legacyJson == null) continue;

      final legacy = BagInventoryEntry.fromJson(
        Map<String, dynamic>.from(legacyJson),
      );
      final canonicalKey = BagInventoryEntry.keyFor(profileId, alias.value);
      final canonicalJson = box.get(canonicalKey);
      final canonical = canonicalJson == null
          ? BagInventoryEntry(
              profileId: profileId,
              itemId: alias.value,
              quantity: 0,
            )
          : BagInventoryEntry.fromJson(
              Map<String, dynamic>.from(canonicalJson),
            );

      await box.put(
        canonicalKey,
        canonical
            .copyWith(quantity: canonical.quantity + legacy.quantity)
            .toJson(),
      );
      await box.delete(legacyKey);
      changed = true;
    }

    if (changed) await box.flush();
  }

  Future<void> addItem({
    required String profileId,
    required String itemId,
    int quantity = 1,
  }) async {
    if (quantity <= 0) return;

    final box = await _box();
    final key = BagInventoryEntry.keyFor(profileId, itemId);
    final existingJson = box.get(key);
    final existing = existingJson == null
        ? BagInventoryEntry(profileId: profileId, itemId: itemId, quantity: 0)
        : BagInventoryEntry.fromJson(Map<String, dynamic>.from(existingJson));

    final updated = existing.copyWith(quantity: existing.quantity + quantity);

    await box.put(key, updated.toJson());
    await box.flush();
  }

  Future<void> addItems({
    required String profileId,
    required Map<String, int> quantities,
  }) async {
    final selected = quantities.entries
        .where((entry) => entry.key.trim().isNotEmpty && entry.value > 0)
        .toList(growable: false);
    if (selected.isEmpty) return;

    final box = await _box();
    final updates = <String, dynamic>{};

    for (final entry in selected) {
      final itemId = entry.key.trim();
      final key = BagInventoryEntry.keyFor(profileId, itemId);
      final existingJson = box.get(key);
      final existing = existingJson == null
          ? BagInventoryEntry(profileId: profileId, itemId: itemId, quantity: 0)
          : BagInventoryEntry.fromJson(Map<String, dynamic>.from(existingJson));
      updates[key] = existing
          .copyWith(quantity: existing.quantity + entry.value)
          .toJson();
    }

    await box.putAll(updates);
    await box.flush();
  }

  Future<bool> consumeItem({
    required String profileId,
    required String itemId,
    int quantity = 1,
  }) async {
    if (quantity <= 0) return true;

    final box = await _box();
    final key = BagInventoryEntry.keyFor(profileId, itemId);
    final existingJson = box.get(key);
    if (existingJson == null) return false;

    final existing = BagInventoryEntry.fromJson(
      Map<String, dynamic>.from(existingJson),
    );
    if (existing.quantity < quantity) return false;

    final updatedQuantity = existing.quantity - quantity;
    if (updatedQuantity <= 0) {
      await box.delete(key);
    } else {
      await box.put(key, existing.copyWith(quantity: updatedQuantity).toJson());
    }

    await box.flush();
    return true;
  }

  Future<void> replaceInventory({
    required String profileId,
    required Iterable<BagInventoryEntry> entries,
  }) async {
    final box = await _box();
    final keysToDelete = box.keys
        .where((key) {
          return key is String && key.startsWith('$profileId::');
        })
        .toList(growable: false);
    await box.deleteAll(keysToDelete);

    final updates = <String, dynamic>{};
    for (final entry in entries) {
      if (entry.quantity <= 0 || entry.itemId.trim().isEmpty) continue;
      final normalized = BagInventoryEntry(
        profileId: profileId,
        itemId: entry.itemId,
        quantity: entry.quantity,
      );
      updates[normalized.storageKey] = normalized.toJson();
    }
    if (updates.isNotEmpty) {
      await box.putAll(updates);
    }
    await box.flush();
  }

  Future<void> deleteInventory(String profileId) async {
    final box = await _box();
    final keysToDelete = box.keys
        .where((key) {
          return key is String && key.startsWith('$profileId::');
        })
        .toList(growable: false);
    await box.deleteAll(keysToDelete);
    await box.flush();
  }
}
