import '../models/bag_inventory_entry.dart';
import '../models/bag_item.dart';
import '../models/evolution_data.dart';
import '../models/level_progression.dart';
import '../models/pokemon.dart';
import '../models/team_slot.dart';

class EvolutionEligibility {
  const EvolutionEligibility({
    required this.option,
    required this.isAvailable,
    required this.missingRequirements,
    this.requiredItemId,
  });

  final EvolutionOption option;
  final bool isAvailable;
  final List<String> missingRequirements;
  final String? requiredItemId;
}

class EvolutionService {
  const EvolutionService();

  List<EvolutionEligibility> evaluateOptions({
    required Pokemon pokemon,
    required TeamSlot slot,
    required EvolutionData evolution,
    required List<BagInventoryEntry> inventory,
    required List<BagItem> itemCatalog,
  }) {
    final options = evolution.options.isEmpty
        ? _legacyOptions(pokemon: pokemon, evolution: evolution)
        : evolution.options;
    final ownedItemIds = inventory
        .where((entry) => entry.quantity > 0)
        .map((entry) => entry.itemId)
        .toSet();
    final itemByName = {
      for (final item in itemCatalog) _referenceKey(item.name): item,
      for (final item in itemCatalog) _referenceKey(item.id): item,
    };

    return [
      for (final option in options)
        _evaluateOption(
          option: option,
          slot: slot,
          ownedItemIds: ownedItemIds,
          itemByName: itemByName,
        ),
    ];
  }

  EvolutionEligibility _evaluateOption({
    required EvolutionOption option,
    required TeamSlot slot,
    required Set<String> ownedItemIds,
    required Map<String, BagItem> itemByName,
  }) {
    final missing = <String>[];
    String? requiredItemId;
    final level = LevelProgression.levelFromExperience(slot.experience);
    final selectedMoveKeys = slot.selectedMoves.map(_referenceKey).toSet();

    for (final condition in option.conditions) {
      switch (condition.type) {
        case 'level':
          final requiredLevel = condition.intValue;
          if (requiredLevel != null && level < requiredLevel) {
            missing.add('Richiede livello $requiredLevel');
          }
          break;
        case 'loyalty':
          final requiredLoyalty = condition.intValue;
          if (requiredLoyalty != null && slot.loyalty < requiredLoyalty) {
            missing.add('Richiede lealtà $requiredLoyalty');
          }
          break;
        case 'gender':
          final requiredGender = _referenceKey(condition.valueLabel);
          final currentGender = _referenceKey(slot.gender ?? '');
          if (requiredGender.isNotEmpty && currentGender != requiredGender) {
            missing.add('Richiede sesso ${condition.valueLabel}');
          }
          break;
        case 'move':
          final requiredMove = _referenceKey(condition.valueLabel);
          if (requiredMove.isNotEmpty && !selectedMoveKeys.contains(requiredMove)) {
            missing.add('Richiede la mossa ${condition.valueLabel}');
          }
          break;
        case 'item':
          final requiredItem = itemByName[_referenceKey(condition.valueLabel)];
          requiredItemId = requiredItem?.id;
          if (requiredItem == null) {
            missing.add('Oggetto richiesto non trovato: ${condition.valueLabel}');
          } else if (!ownedItemIds.contains(requiredItem.id)) {
            missing.add('Richiede ${requiredItem.name} nello zaino');
          }
          break;
        case 'biome':
          missing.add('Richiede bioma ${condition.valueLabel}');
          break;
        default:
          if (condition.valueLabel.isNotEmpty) {
            missing.add(condition.displayLabel);
          }
      }
    }

    return EvolutionEligibility(
      option: option,
      isAvailable: missing.isEmpty,
      missingRequirements: missing,
      requiredItemId: requiredItemId,
    );
  }

  List<EvolutionOption> _legacyOptions({
    required Pokemon pokemon,
    required EvolutionData evolution,
  }) {
    return [
      for (final toName in evolution.evolutions)
        EvolutionOption(
          id: '${_referenceKey(pokemon.name)}-to-${_referenceKey(toName)}',
          fromKey: _referenceKey(pokemon.name),
          toKey: _referenceKey(toName),
          toName: toName,
          conditions: [
            if (evolution.level != null)
              EvolutionRule(type: 'level', value: evolution.level),
          ],
          effects: [
            if (evolution.points != null)
              EvolutionRule(type: 'asi', value: evolution.points),
          ],
        ),
    ];
  }

  String _referenceKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r"[’']"), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}
