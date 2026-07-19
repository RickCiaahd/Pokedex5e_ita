import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/pokemon_ability.dart';
import '../services/custom_pokemon_runtime_registry.dart';
import 'ability_localization_repository.dart';

class AbilityRepository {
  Map<String, String>? _descriptionCache;
  Map<String, String>? _displayNameCache;
  List<PokemonAbility>? _webAbilityCache;
  Set<String>? _deprecatedAbilityCache;

  Future<Map<String, String>> getAbilityDescriptions({int? pokemonId}) async {
    if (_descriptionCache == null) {
      final descriptions = <String, String>{};

      try {
        final oldJsonString = await rootBundle.loadString(
          'assets/data/abilities.json',
        );
        final oldJson = Map<String, dynamic>.from(jsonDecode(oldJsonString));
        descriptions.addAll(
          oldJson.map((key, value) {
            final data = Map<String, dynamic>.from(value);
            return MapEntry(key, data['Description']?.toString() ?? '');
          }),
        );
      } catch (_) {
        descriptions.addAll(const <String, String>{});
      }

      final webAbilities = await getWebAbilities(includeDeprecated: true);
      for (final ability in webAbilities) {
        descriptions[ability.name] = ability.description;
      }
      _descriptionCache = descriptions;
    }

    if (pokemonId == null) return _descriptionCache!;
    return {
      ..._descriptionCache!,
      ...CustomPokemonRuntimeRegistry.abilityCatalogFor(pokemonId),
    };
  }

  Future<Map<String, String>> getAbilityDisplayNames({int? pokemonId}) async {
    if (_displayNameCache == null) {
      final abilities = await getWebAbilities(includeDeprecated: true);
      _displayNameCache = {
        for (final ability in abilities) ability.name: ability.displayName,
      };
    }

    if (pokemonId == null) return _displayNameCache!;
    final customAbilities = CustomPokemonRuntimeRegistry.abilityCatalogFor(
      pokemonId,
    );
    return {
      ..._displayNameCache!,
      for (final name in customAbilities.keys) name: name,
    };
  }

  Future<List<PokemonAbility>> getWebAbilities({
    bool includeDeprecated = false,
  }) async {
    if (_webAbilityCache == null) {
      final jsonString = await rootBundle.loadString(
        'assets/data_webapp/abilities.json',
      );
      final json = Map<String, dynamic>.from(jsonDecode(jsonString));
      final abilityJson = List<dynamic>.from(json['items'] ?? const []);
      final localizationRepository = AbilityLocalizationRepository();
      final localizedDescriptions = await localizationRepository
          .getDescriptions();
      final localizedNames = await localizationRepository.getNames();

      _webAbilityCache =
          abilityJson
              .map(
                (value) => PokemonAbility.fromWebJson(
                  Map<String, dynamic>.from(value),
                ),
              )
              .where(
                (ability) => ability.id.isNotEmpty && ability.name.isNotEmpty,
              )
              .map(
                (ability) => PokemonAbility(
                  id: ability.id,
                  name: ability.name,
                  displayName: localizedNames[ability.id] ?? ability.name,
                  description:
                      localizedDescriptions[ability.id] ?? ability.description,
                  deprecated: ability.deprecated,
                ),
              )
              .toList(growable: false)
            ..sort(
              (a, b) => a.displayName.toLowerCase().compareTo(
                b.displayName.toLowerCase(),
              ),
            );
    }

    final abilities = _webAbilityCache!;
    if (includeDeprecated) return abilities;

    return abilities
        .where((ability) => !ability.deprecated)
        .toList(growable: false);
  }

  Future<Set<String>> getDeprecatedAbilityNames() async {
    if (_deprecatedAbilityCache != null) return _deprecatedAbilityCache!;

    final abilities = await getWebAbilities(includeDeprecated: true);
    _deprecatedAbilityCache = abilities
        .where((ability) => ability.deprecated)
        .map((ability) => ability.name)
        .toSet();

    return _deprecatedAbilityCache!;
  }
}
