import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/trainer_manual_options.dart';
import 'package:pokedex_5e_ita/models/trainer_starting_equipment.dart';
import 'package:pokedex_5e_ita/models/trainer_ui_localization.dart';

void main() {
  test('manual starting packs expose descriptions and inventory', () {
    expect(TrainerManualOptions.startingPacks, hasLength(3));
    TrainerStartingEquipment.validatePacks();

    for (final value in TrainerManualOptions.startingPacks) {
      expect(TrainerUiLocalization.startingPackDescriptions[value], isNotEmpty);
      final inventory = TrainerStartingEquipment.inventoryForPack(value);
      expect(inventory['poke-ball'], 5);
      expect(inventory['potion'], 1);
      expect(inventory['trainer-license'], 1);
      expect(inventory['trainer-pokedex'], 1);
      expect(inventory['trainer-backpack'], 1);
    }
  });

  test('trainer equipment catalog contains every custom starting item', () {
    final catalogIds = TrainerStartingEquipment.catalogItems
        .map((item) => item.id)
        .toSet();
    final customInventoryIds = <String>{
      ...TrainerStartingEquipment.baseInventory.keys,
      for (final pack in TrainerStartingEquipment.packInventory.values)
        ...pack.keys,
    }..removeAll({'poke-ball', 'potion'});

    expect(catalogIds, containsAll(customInventoryIds));
  });
}
