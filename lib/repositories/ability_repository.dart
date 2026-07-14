import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/pokemon_ability.dart';

class AbilityRepository {
  Map<String, String>? _descriptionCache;
  List<PokemonAbility>? _webAbilityCache;
  Set<String>? _deprecatedAbilityCache;

  Future<Map<String, String>> getAbilityDescriptions() async {
    if (_descriptionCache != null) return _descriptionCache!;

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
    return _descriptionCache!;
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

      _webAbilityCache = abilityJson
          .map(
            (value) => PokemonAbility.fromWebJson(
              Map<String, dynamic>.from(value),
            ),
          )
          .where((ability) => ability.id.isNotEmpty && ability.name.isNotEmpty)
          .toList(growable: false)
        ..sort((a, b) => a.name.compareTo(b.name));
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
