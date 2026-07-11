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
    required this.conditionLabels,
    required this.missingRequirements,
    this.requiredItemId,
  });

  final EvolutionOption option;
  final bool isAvailable;
  final List<String> conditionLabels;
  final List<String> missingRequirements;
  final String? requiredItemId;
}

class EvolutionTarget {
  const EvolutionTarget({
    required this.basePokemon,
    required this.pokemon,
    required this.displayName,
    this.formName,
  });

  final Pokemon basePokemon;
  final Pokemon pokemon;
  final String displayName;
  final String? formName;
}

class EvolutionService {
  const EvolutionService();

  static const Set<String> _regionalFormKeys = {
    'alolan',
    'galarian',
    'hisuian',
    'paldean',
  };

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

  EvolutionTarget? resolveTarget({
    required EvolutionOption option,
    required Pokemon currentPokemon,
    required TeamSlot slot,
    required Iterable<Pokemon> catalog,
  }) {
    final targetKeys = {
      _referenceKey(option.toKey),
      _referenceKey(option.toName),
    }..removeWhere((key) => key.isEmpty);
    if (targetKeys.isEmpty) return null;

    Pokemon? exactBase;
    for (final candidate in catalog) {
      if (targetKeys.contains(_referenceKey(candidate.name))) {
        exactBase = candidate;
        break;
      }
    }

    if (exactBase != null) {
      final carriedForm = _regionalFormForTarget(
        targetPokemon: exactBase,
        currentPokemon: currentPokemon,
        currentFormName: slot.formName,
      );
      return _buildTarget(
        basePokemon: exactBase,
        form: carriedForm,
        gender: slot.gender,
      );
    }

    for (final candidate in catalog) {
      for (final definition in candidate.formDefinitions) {
        if (definition.gender != null) continue;
        final aliases = _targetAliases(candidate, definition);
        if (targetKeys.any(aliases.contains)) {
          return _buildTarget(
            basePokemon: candidate,
            form: definition,
            gender: slot.gender,
          );
        }
      }
    }

    return null;
  }

  EvolutionTarget _buildTarget({
    required Pokemon basePokemon,
    required PokemonFormDefinition? form,
    required String? gender,
  }) {
    final formName = form?.displayName;
    return EvolutionTarget(
      basePokemon: basePokemon,
      pokemon: basePokemon.resolveVariant(
        formName: formName,
        gender: gender,
      ),
      formName: formName,
      displayName: form == null
          ? basePokemon.name
          : _displayNameForForm(basePokemon, form),
    );
  }

  PokemonFormDefinition? _regionalFormForTarget({
    required Pokemon targetPokemon,
    required Pokemon currentPokemon,
    required String? currentFormName,
  }) {
    final sourceFormKey = Pokemon.formReferenceKey(
      currentFormName ?? '',
      currentPokemon.name,
    );
    if (!_regionalFormKeys.contains(sourceFormKey)) return null;

    for (final definition in targetPokemon.formDefinitions) {
      if (definition.gender != null) continue;
      final definitionKey = Pokemon.formReferenceKey(
        definition.key,
        targetPokemon.name,
      );
      final displayKey = Pokemon.formReferenceKey(
        definition.displayName,
        targetPokemon.name,
      );
      if (definitionKey == sourceFormKey || displayKey == sourceFormKey) {
        return definition;
      }
    }

    return null;
  }

  Set<String> _targetAliases(
    Pokemon pokemon,
    PokemonFormDefinition definition,
  ) {
    final speciesKey = _referenceKey(pokemon.name);
    final formKey = Pokemon.formReferenceKey(
      definition.displayName,
      pokemon.name,
    );
    final rawKey = Pokemon.formReferenceKey(definition.key, pokemon.name);
    final aliases = <String>{
      _referenceKey(definition.key),
      _referenceKey(definition.displayName),
      _referenceKey(definition.pokemon.assetSlug ?? ''),
      _referenceKey('${definition.displayName} ${pokemon.name}'),
      _referenceKey('${pokemon.name} ${definition.displayName}'),
    };

    for (final key in {formKey, rawKey}) {
      if (key.isEmpty || key == 'base') continue;
      aliases.add('$key-$speciesKey');
      aliases.add('$speciesKey-$key');
    }

    aliases.removeWhere((value) => value.isEmpty);
    return aliases;
  }

  String _displayNameForForm(
    Pokemon pokemon,
    PokemonFormDefinition definition,
  ) {
    final displayName = definition.displayName.trim();
    if (displayName.isEmpty) return pokemon.name;

    final displayKey = _referenceKey(displayName);
    final speciesKey = _referenceKey(pokemon.name);
    if (displayKey == speciesKey ||
        displayKey.startsWith('$speciesKey-') ||
        displayKey.endsWith('-$speciesKey')) {
      return displayName;
    }

    return '$displayName ${pokemon.name}';
  }

  EvolutionEligibility _evaluateOption({
    required EvolutionOption option,
    required TeamSlot slot,
    required Set<String> ownedItemIds,
    required Map<String, BagItem> itemByName,
  }) {
    final conditionLabels = <String>[];
    final missing = <String>[];
    String? requiredItemId;
    final level = LevelProgression.levelFromExperience(slot.experience);
    final selectedMoveKeys = slot.selectedMoves.map(_referenceKey).toSet();

    for (final condition in option.conditions) {
      switch (condition.type) {
        case 'level':
          final requiredLevel = condition.intValue;
          if (requiredLevel != null) {
            conditionLabels.add('Livello $requiredLevel');
            if (level < requiredLevel) {
              missing.add('Richiede livello $requiredLevel');
            }
          }
          break;
        case 'loyalty':
          final requiredLoyalty = condition.intValue;
          if (requiredLoyalty != null) {
            conditionLabels.add('Lealtà $requiredLoyalty');
            if (slot.loyalty < requiredLoyalty) {
              missing.add('Richiede lealtà $requiredLoyalty');
            }
          }
          break;
        case 'gender':
          final requiredGender = _normalizeGender(condition.valueLabel);
          final currentGender = _normalizeGender(slot.gender ?? '');
          if (requiredGender.isNotEmpty) {
            conditionLabels.add('Sesso: ${_genderLabel(requiredGender)}');
            if (currentGender != requiredGender) {
              missing.add('Richiede sesso ${_genderLabel(requiredGender)}');
            }
          }
          break;
        case 'move':
          final requiredMove = _referenceKey(condition.valueLabel);
          if (requiredMove.isNotEmpty) {
            conditionLabels.add('Mossa: ${condition.valueLabel}');
            if (!selectedMoveKeys.contains(requiredMove)) {
              missing.add('Richiede la mossa ${condition.valueLabel}');
            }
          }
          break;
        case 'item':
          final requiredItem = itemByName[_referenceKey(condition.valueLabel)];
          requiredItemId = requiredItem?.id;
          if (requiredItem == null) {
            conditionLabels.add(condition.valueLabel);
            missing.add('Oggetto richiesto non trovato: ${condition.valueLabel}');
          } else {
            conditionLabels.add(requiredItem.name);
            if (!ownedItemIds.contains(requiredItem.id)) {
              missing.add('Richiede ${requiredItem.name} nello zaino');
            }
          }
          break;
        default:
          // Condizioni come giorno/notte, bioma, luogo, meteo o altre regole
          // non visibili nell'app non devono bloccare l'evoluzione.
          break;
      }
    }

    return EvolutionEligibility(
      option: option,
      isAvailable: missing.isEmpty,
      conditionLabels: conditionLabels,
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
        return 'Maschio';
      case 'female':
        return 'Femmina';
      case 'genderless':
        return 'Genderless';
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
