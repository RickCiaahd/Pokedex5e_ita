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
      expect(inventory['trainers-license'], 1);
      expect(inventory['pokedex'], 1);
      expect(inventory['trainer-backpack'], 1);
    }
  });

  test('trainer equipment catalog contains every custom starting item', () {
    final catalogIds = TrainerStartingEquipment.catalogItems
        .map((item) => item.id)
        .toSet();
    final customInventoryIds = <String>{
      for (final pack in TrainerStartingEquipment.packInventory.values)
        ...pack.keys,
    };

    expect(catalogIds, containsAll(customInventoryIds));
  });

  test('starting inventory reuses the existing license and pokedex items', () {
    expect(TrainerStartingEquipment.baseInventory['trainers-license'], 1);
    expect(TrainerStartingEquipment.baseInventory['pokedex'], 1);
    expect(
      TrainerStartingEquipment.baseInventory,
      isNot(contains('trainer-license')),
    );
    expect(
      TrainerStartingEquipment.baseInventory,
      isNot(contains('trainer-pokedex')),
    );

    final generatedIds = TrainerStartingEquipment.catalogItems
        .map((item) => item.id)
        .toSet();
    expect(generatedIds, isNot(contains('trainers-license')));
    expect(generatedIds, isNot(contains('pokedex')));
  });
}
