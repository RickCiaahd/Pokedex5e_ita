import 'package:hive_flutter/hive_flutter.dart';

import '../database/hive_boxes.dart';
import '../models/bag_inventory_entry.dart';

class BagInventoryRepository {
  Future<Box> _box() => Hive.openBox(HiveBoxes.bagItems);

  Future<List<BagInventoryEntry>> getInventory(String profileId) async {
    final box = await _box();

    return box.values
        .map((data) => BagInventoryEntry.fromJson(Map<String, dynamic>.from(data)))
        .where((entry) => entry.profileId == profileId && entry.quantity > 0)
        .toList(growable: false);
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
}
