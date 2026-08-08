import 'dart:convert';

import 'package:flutter/services.dart';

import '../localization/game_catalog_locale.dart';
import '../models/pokemon_ability.dart';
import '../services/custom_pokemon_runtime_registry.dart';
import '../services/performance_trace.dart';
import 'ability_localization_repository.dart';

class AbilityRepository {
  static const Set<String> _powerConstructVariantIds = {
    'power-construct-10',
    'power-construct-50',
    'power-construct-100',
  };

  static Map<String, String>? _descriptionCache;
  static Future<Map<String, String>>? _descriptionFuture;
  static Map<String, String>? _displayNameCache;
  static Future<Map<String, String>>? _displayNameFuture;
  static List<PokemonAbility>? _webAbilityCache;
  static Future<List<PokemonAbility>>? _webAbilityFuture;
  static Set<String>? _deprecatedAbilityCache;
  static int _catalogLocaleRevision = -1;

  Future<Map<String, String>> getAbilityDescriptions({int? pokemonId}) async {
    _ensureLocaleCache();
    if (_descriptionCache == null) {
      final loading = _descriptionFuture;
      if (loading != null) {
        _descriptionCache = await loading;
      } else {
        final future = _loadAbilityDescriptions();
        _descriptionFuture = future;
        try {
          _descriptionCache = await future;
        } finally {
          if (identical(_descriptionFuture, future)) {
            _descriptionFuture = null;
          }
        }
      }
    }

    if (pokemonId == null) return _descriptionCache!;
    return {
      ..._descriptionCache!,
      ...CustomPokemonRuntimeRegistry.abilityCatalogFor(pokemonId),
    };
  }

  Future<Map<String, String>> getAbilityDisplayNames({int? pokemonId}) async {
    _ensureLocaleCache();
    if (_displayNameCache == null) {
      final loading = _displayNameFuture;
      if (loading != null) {
        _displayNameCache = await loading;
      } else {
        final future = _loadAbilityDisplayNames();
        _displayNameFuture = future;
        try {
          _displayNameCache = await future;
        } finally {
          if (identical(_displayNameFuture, future)) {
            _displayNameFuture = null;
          }
        }
      }
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
    _ensureLocaleCache();
    if (_webAbilityCache == null) {
      final loading = _webAbilityFuture;
      if (loading != null) {
        _webAbilityCache = await loading;
      } else {
        final localeRevision = GameCatalogLocale.revision;
        final future = _loadWebAbilities();
        _webAbilityFuture = future;
        try {
          final abilities = await future;
          if (_catalogLocaleRevision == localeRevision) {
            _webAbilityCache = abilities;
          }
          return includeDeprecated ? abilities : _visibleAbilities(abilities);
        } finally {
          if (identical(_webAbilityFuture, future)) {
            _webAbilityFuture = null;
          }
        }
      }
    }

    final abilities = _webAbilityCache!;
    if (includeDeprecated) return abilities;
    return _visibleAbilities(abilities);
  }

  Future<Set<String>> getDeprecatedAbilityNames() async {
    _ensureLocaleCache();
    if (_deprecatedAbilityCache != null) return _deprecatedAbilityCache!;

    final abilities = await getWebAbilities(includeDeprecated: true);
    _deprecatedAbilityCache = abilities
        .where((ability) => ability.deprecated)
        .map((ability) => ability.name)
        .toSet();

    return _deprecatedAbilityCache!;
  }

  Future<Map<String, String>> _loadAbilityDescriptions() async {
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
    descriptions['Power Construct'] = GameCatalogLocale.isItalian
        ? 'Quando Zygarde scende sotto la metà dei PF massimi, Sciamefusione ne cambia automaticamente la forma: dal 10% passa al 50%, mentre dal 50% passa alla Forma Perfetta. Al cambio recupera tutti i PF.'
        : 'When Zygarde drops below half of its maximum HP, Power Construct automatically changes its form: 10% becomes 50%, while 50% becomes Complete Form. It restores all HP when the form changes.';
    return Map<String, String>.unmodifiable(descriptions);
  }

  Future<Map<String, String>> _loadAbilityDisplayNames() async {
    final abilities = await getWebAbilities(includeDeprecated: true);
    final result = <String, String>{
      for (final ability in abilities) ability.name: ability.displayName,
    };
    final powerConstruct = _powerConstructReference(abilities);
    result['Power Construct'] = powerConstruct?.displayName ??
        (GameCatalogLocale.isItalian ? 'Sciamefusione' : 'Power Construct');
    return Map<String, String>.unmodifiable(result);
  }

  List<PokemonAbility> _visibleAbilities(List<PokemonAbility> abilities) {
    final result = abilities
        .where(
          (ability) =>
              !ability.deprecated &&
              !_powerConstructVariantIds.contains(ability.id),
        )
        .toList(growable: true);
    final powerConstruct = _powerConstructReference(abilities);
    if (powerConstruct != null) {
      result.add(
        PokemonAbility(
          id: 'power-construct',
          name: 'Power Construct',
          displayName: powerConstruct.displayName,
          description: GameCatalogLocale.isItalian
              ? 'Quando Zygarde scende sotto la metà dei PF massimi, Sciamefusione ne cambia automaticamente la forma e ripristina tutti i PF.'
              : 'When Zygarde drops below half of its maximum HP, Power Construct automatically changes its form and restores all HP.',
        ),
      );
    }
    result.sort(
      (a, b) => a.displayName.toLowerCase().compareTo(
        b.displayName.toLowerCase(),
      ),
    );
    return List<PokemonAbility>.unmodifiable(result);
  }

  PokemonAbility? _powerConstructReference(List<PokemonAbility> abilities) {
    for (final ability in abilities) {
      if (ability.id == 'power-construct-50') return ability;
    }
    for (final ability in abilities) {
      if (_powerConstructVariantIds.contains(ability.id)) return ability;
    }
    return null;
  }

  Future<List<PokemonAbility>> _loadWebAbilities() async {
    final performanceTrace = PerformanceTrace.start(
      'catalog.abilities.load',
      arguments: {'locale': GameCatalogLocale.languageCode},
    );
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data_webapp/abilities.json',
      );
      final json = Map<String, dynamic>.from(jsonDecode(jsonString));
      final abilityJson = List<dynamic>.from(json['items'] ?? const []);
      var localizedDescriptions = const <String, String>{};
      var localizedNames = const <String, String>{};
      if (GameCatalogLocale.isItalian) {
        final localizationRepository = AbilityLocalizationRepository();
        localizedDescriptions = await localizationRepository.getDescriptions();
        localizedNames = await localizationRepository.getNames();
      }

      final abilities =
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
              .toList(growable: true)
            ..sort(
              (a, b) => a.displayName.toLowerCase().compareTo(
                b.displayName.toLowerCase(),
              ),
            );
      final result = List<PokemonAbility>.unmodifiable(abilities);
      performanceTrace.finish(
        arguments: {'status': 'success', 'count': result.length},
      );
      return result;
    } catch (_) {
      performanceTrace.finish(arguments: {'status': 'error'});
      rethrow;
    }
  }

  void _ensureLocaleCache() {
    final revision = GameCatalogLocale.revision;
    if (_catalogLocaleRevision == revision) return;
    _catalogLocaleRevision = revision;
    _descriptionCache = null;
    _descriptionFuture = null;
    _displayNameCache = null;
    _displayNameFuture = null;
    _webAbilityCache = null;
    _webAbilityFuture = null;
    _deprecatedAbilityCache = null;
  }

  static void clearCache() {
    _descriptionCache = null;
    _descriptionFuture = null;
    _displayNameCache = null;
    _displayNameFuture = null;
    _webAbilityCache = null;
    _webAbilityFuture = null;
    _deprecatedAbilityCache = null;
    _catalogLocaleRevision = -1;
  }
}
