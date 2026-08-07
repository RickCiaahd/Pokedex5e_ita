import '../models/bag_inventory_entry.dart';
import '../localization/ui_text.dart';
import '../models/bag_item.dart';
import '../models/evolution_data.dart';
import '../models/level_progression.dart';
import '../models/pokemon.dart';
import '../models/team_slot.dart';

class EvolutionEligibility {
  const EvolutionEligibility({
    required this.option,
    required this.isAvailable,
    required this.conditionLabels,
    required this.missingRequirements,
    this.requiredItemId,
    this.requiredMoney = 0,
  });

  final EvolutionOption option;
  final bool isAvailable;
  final List<String> conditionLabels;
  final List<String> missingRequirements;
  final String? requiredItemId;
  final int requiredMoney;
}

class EvolutionService {
  const EvolutionService();

  List<EvolutionEligibility> evaluateOptions({
    required Pokemon pokemon,
    required TeamSlot slot,
    required EvolutionData evolution,
    required List<BagInventoryEntry> inventory,
    required List<BagItem> itemCatalog,
    int trainerMoney = 0,
  }) {
    final options = evolution.options.isEmpty
        ? _legacyOptions(pokemon: pokemon, evolution: evolution)
        : evolution.options;
    final ownedItemIds = inventory
        .where((entry) => entry.quantity > 0)
        .map((entry) => entry.itemId)
        .toSet();
    final itemByName = {
      for (final item in itemCatalog) _referenceKey(item.technicalName): item,
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
          trainerMoney: trainerMoney,
        ),
    ];
  }

  EvolutionEligibility _evaluateOption({
    required EvolutionOption option,
    required TeamSlot slot,
    required Set<String> ownedItemIds,
    required Map<String, BagItem> itemByName,
    required int trainerMoney,
  }) {
    final conditionLabels = <String>[];
    final missing = <String>[];
    String? requiredItemId;
    var requiredMoney = 0;
    final level = LevelProgression.levelFromExperience(slot.experience);
    final selectedMoveKeys = slot.selectedMoves.map(_referenceKey).toSet();
    final manualEarlierCost = _manualEarlierCost(option.conditions);

    for (final condition in option.conditions) {
      switch (condition.type) {
        case 'level':
          final requiredLevel = condition.intValue;
          if (requiredLevel != null) {
            conditionLabels.add(
              uiTextForLanguage(
                'Livello $requiredLevel',
                'Level $requiredLevel',
              ),
            );
            if (level < requiredLevel) {
              if (manualEarlierCost != null) {
                requiredMoney = manualEarlierCost;
                if (trainerMoney < requiredMoney) {
                  missing.add(
                    uiTextForLanguage(
                      'Richiede ₽9.999 nel portafogli',
                      'Requires ₽9,999 in the wallet',
                    ),
                  );
                }
              } else {
                missing.add(
                  uiTextForLanguage(
                    'Richiede livello $requiredLevel',
                    'Requires level $requiredLevel',
                  ),
                );
              }
            }
          }
          break;
        case 'loyalty':
          final requiredLoyalty = condition.intValue;
          if (requiredLoyalty != null) {
            conditionLabels.add(
              uiTextForLanguage(
                'Lealtà $requiredLoyalty',
                'Loyalty $requiredLoyalty',
              ),
            );
            if (slot.loyalty < requiredLoyalty) {
              missing.add(
                uiTextForLanguage(
                  'Richiede lealtà $requiredLoyalty',
                  'Requires Loyalty $requiredLoyalty',
                ),
              );
            }
          }
          break;
        case 'gender':
          final requiredGender = _normalizeGender(condition.valueLabel);
          final currentGender = _normalizeGender(slot.gender ?? '');
          if (requiredGender.isNotEmpty) {
            conditionLabels.add(
              uiTextForLanguage(
                'Sesso: ${_genderLabel(requiredGender)}',
                'Gender: ${_genderLabel(requiredGender)}',
              ),
            );
            if (currentGender != requiredGender) {
              missing.add(
                uiTextForLanguage(
                  'Richiede sesso ${_genderLabel(requiredGender)}',
                  'Requires gender ${_genderLabel(requiredGender)}',
                ),
              );
            }
          }
          break;
        case 'move':
          final requiredMove = _referenceKey(condition.valueLabel);
          if (requiredMove.isNotEmpty) {
            conditionLabels.add(
              uiTextForLanguage(
                'Mossa: ${condition.valueLabel}',
                'Move: ${condition.valueLabel}',
              ),
            );
            if (!selectedMoveKeys.contains(requiredMove)) {
              missing.add(
                uiTextForLanguage(
                  'Richiede la mossa ${condition.valueLabel}',
                  'Requires the move ${condition.valueLabel}',
                ),
              );
            }
          }
          break;
        case 'item':
          final requiredItem = itemByName[_referenceKey(condition.valueLabel)];
          requiredItemId = requiredItem?.id;
          if (requiredItem == null) {
            conditionLabels.add(condition.valueLabel);
            missing.add(
              uiTextForLanguage(
                'Oggetto richiesto non trovato: ${condition.valueLabel}',
                'Required item not found: ${condition.valueLabel}',
              ),
            );
          } else {
            conditionLabels.add(requiredItem.name);
            if (!ownedItemIds.contains(requiredItem.id)) {
              missing.add(
                uiTextForLanguage(
                  'Richiede ${requiredItem.name} nello zaino',
                  'Requires ${requiredItem.name} in the Bag',
                ),
              );
            }
          }
          break;
        case 'special':
          final label = _specialConditionLabel(condition.valueLabel);
          if (label.isNotEmpty) conditionLabels.add(label);
          break;
        default:
          // Condizioni come giorno/notte, bioma, luogo o meteo non
          // verificabili automaticamente non devono bloccare l'evoluzione.
          break;
      }
    }

    return EvolutionEligibility(
      option: option,
      isAvailable: missing.isEmpty,
      conditionLabels: conditionLabels,
      missingRequirements: missing,
      requiredItemId: requiredItemId,
      requiredMoney: requiredMoney,
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

  int moneyAfterSuccessfulEvolution({
    required int currentMoney,
    required EvolutionEligibility eligibility,
  }) {
    if (!eligibility.isAvailable || eligibility.requiredMoney <= 0) {
      return currentMoney;
    }
    if (currentMoney < eligibility.requiredMoney) return currentMoney;
    return currentMoney - eligibility.requiredMoney;
  }

  int? _manualEarlierCost(List<EvolutionRule> conditions) {
    for (final condition in conditions) {
      if (_isManualEarlierAlternative(condition)) return 9999;
    }
    return null;
  }

  bool _isManualEarlierAlternative(EvolutionRule condition) {
    if (condition.type != 'special') return false;
    final value = condition.valueLabel.trim().toLowerCase();
    return value.startsWith('or ') &&
        value.contains('earlier than level') &&
        value.contains('9,999');
  }

  String _specialConditionLabel(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.contains('earlier than level 10') &&
        normalized.contains('9,999')) {
      return uiTextForLanguage(
        'Oppure prima del livello 10 consumando ₽9.999',
        'Or before level 10 by spending ₽9,999',
      );
    }
    return value.trim();
  }

  String _normalizeGender(String value) {
    final normalized = _referenceKey(value);
    switch (normalized) {
      case 'm':
      case 'male':
      case 'maschio':
        return 'male';
      case 'f':
      case 'female':
      case 'femmina':
        return 'female';
      case 'genderless':
      case 'none':
      case 'senza-sesso':
        return 'genderless';
      default:
        return normalized;
    }
  }

  String _genderLabel(String value) {
    switch (value) {
      case 'male':
        return uiTextForLanguage('Maschio', 'Male');
      case 'female':
        return uiTextForLanguage('Femmina', 'Female');
      case 'genderless':
        return uiTextForLanguage('Senza sesso', 'Genderless');
      default:
        return value;
    }
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
