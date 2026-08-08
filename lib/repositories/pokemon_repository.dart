import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../localization/game_catalog_locale.dart';
import '../models/pokemon.dart';
import '../models/pokemon_flavor.dart';
import '../services/custom_pokemon_discovery_service.dart';
import '../services/performance_trace.dart';
import 'custom_pokemon_repository.dart';
import 'pokemon_localization_repository.dart';

class PokemonRepository {
  static List<Pokemon>? _cachedAllPokemon;
  static int _cachedCustomRevision = -1;
  static int _cachedLocaleRevision = -1;
  static Future<List<Pokemon>>? _loadingAllPokemon;
  static int _loadingCustomRevision = -1;
  static int _loadingLocaleRevision = -1;

  Future<List<Pokemon>> getAllPokemon({bool includeSealed = false}) async {
    final customRevision = CustomPokemonRepository.revision;
    final localeRevision = GameCatalogLocale.revision;
    if (_cachedAllPokemon != null &&
        _cachedCustomRevision == customRevision &&
        _cachedLocaleRevision == localeRevision) {
      return _filterSealed(_cachedAllPokemon!, includeSealed: includeSealed);
    }

    var loading = _loadingAllPokemon;
    if (loading == null ||
        _loadingCustomRevision != customRevision ||
        _loadingLocaleRevision != localeRevision) {
      _loadingCustomRevision = customRevision;
      _loadingLocaleRevision = localeRevision;
      loading = _loadAllPokemon(
        customRevision: customRevision,
        localeRevision: localeRevision,
      );
      _loadingAllPokemon = loading;
    }

    try {
      final pokemon = await loading;
      return _filterSealed(pokemon, includeSealed: includeSealed);
    } finally {
      if (identical(_loadingAllPokemon, loading)) {
        _loadingAllPokemon = null;
        _loadingCustomRevision = -1;
        _loadingLocaleRevision = -1;
      }
    }
  }

  Future<List<Pokemon>> _loadAllPokemon({
    required int customRevision,
    required int localeRevision,
  }) async {
    final performanceTrace = PerformanceTrace.start(
      'catalog.pokemon.load',
      arguments: {'locale': GameCatalogLocale.languageCode},
    );
    final pokemonByNumber = <int, Pokemon>{};

    try {
      final sourceCatalogs = await Future.wait<List<Pokemon>>([
        _getLegacyPokemon(),
        _getWebappPokemon(),
      ]);
      for (final pokemon in sourceCatalogs[0]) {
        if (pokemon.id <= 0) continue;
        pokemonByNumber[pokemon.id] = pokemon;
      }

      for (final pokemon in sourceCatalogs[1]) {
        if (pokemon.id <= 0) continue;
        final existing = pokemonByNumber[pokemon.id];
        pokemonByNumber[pokemon.id] = existing == null
            ? pokemon
            : existing
                  .withMetadataFrom(pokemon)
                  .withAdditionalFormDefinitions(pokemon.formDefinitions);
      }

      final customDefinitions = await CustomPokemonRepository().getAll();
      for (final definition in customDefinitions) {
        if (definition.advanced.alternateFormOf != null) continue;
        pokemonByNumber[definition.pokemonId] = definition.toPokemon();
      }
      for (final definition in customDefinitions) {
        final parentReference = definition.advanced.alternateFormOf;
        if (parentReference == null) continue;
        final parentId = _resolveAlternateFormParentId(
          parentReference,
          customDefinitions,
          pokemonByNumber,
        );
        final parent = parentId == null ? null : pokemonByNumber[parentId];
        if (parent == null) continue;
        final formPokemon = definition.toPokemon().copyWith(
          name: parent.name,
          formDefinitions: const [],
        );
        pokemonByNumber[parent.id] = parent.withAdditionalFormDefinitions([
          PokemonFormDefinition(
            key: 'fakemon-${definition.stableId}',
            displayName: definition.name,
            pokemon: formPokemon,
          ),
        ]);
      }

      final localizedTexts = GameCatalogLocale.isItalian
          ? await PokemonLocalizationRepository().getPokemonTexts()
          : const <int, PokemonLocalizedText>{};
      final pokemonList =
          pokemonByNumber.values
              .map((pokemon) {
                final localized = localizedTexts[pokemon.id];
                if (localized == null) return pokemon;
                final localizedForms = pokemon.formDefinitions
                    .map(
                      (definition) => PokemonFormDefinition(
                        key: definition.key,
                        displayName: definition.displayName,
                        pokemon: definition.pokemon.copyWith(
                          genus: localized.genus,
                          description: localized.description,
                        ),
                        gender: definition.gender,
                      ),
                    )
                    .toList(growable: false);
                return pokemon.copyWith(
                  genus: localized.genus,
                  description: localized.description,
                  formDefinitions: localizedForms,
                );
              })
              .toList(growable: false)
            ..sort((a, b) => a.id.compareTo(b.id));

      if (CustomPokemonRepository.revision == customRevision &&
          GameCatalogLocale.revision == localeRevision) {
        _cachedAllPokemon = pokemonList;
        _cachedCustomRevision = customRevision;
        _cachedLocaleRevision = localeRevision;
      }
      performanceTrace.finish(
        arguments: {'status': 'success', 'count': pokemonList.length},
      );
      return pokemonList;
    } catch (_) {
      performanceTrace.finish(arguments: {'status': 'error'});
      rethrow;
    }
  }

  int? _resolveAlternateFormParentId(
    dynamic reference,
    List<dynamic> customDefinitions,
    Map<int, Pokemon> pokemonByNumber,
  ) {
    final directId = reference.pokemonId as int?;
    if (directId != null && pokemonByNumber.containsKey(directId)) {
      return directId;
    }
    final stableId = reference.stableId as String?;
    if (stableId != null && stableId.isNotEmpty) {
      for (final definition in customDefinitions) {
        if (definition.stableId == stableId) return definition.pokemonId as int;
      }
    }
    final name = (reference.name as String).trim().toLowerCase();
    if (name.isEmpty) return null;
    for (final entry in pokemonByNumber.entries) {
      if (entry.value.name.trim().toLowerCase() == name) return entry.key;
    }
    return null;
  }

  Future<List<Pokemon>> _filterSealed(
    List<Pokemon> pokemon, {
    required bool includeSealed,
  }) async {
    if (includeSealed) return List<Pokemon>.from(pokemon);
    final customDefinitions = await CustomPokemonRepository().getAll();
    final sealedDefinitions = customDefinitions
        .where((definition) => definition.advanced.sealedForPlayer)
        .toList(growable: false);
    if (sealedDefinitions.isEmpty) return List<Pokemon>.from(pokemon);

    final visible = await CustomPokemonDiscoveryService().visibleDefinitions(
      sealedDefinitions,
    );
    final visibleIds = visible
        .map((definition) => definition.pokemonId)
        .toSet();
    final hiddenIds = sealedDefinitions
        .map((definition) => definition.pokemonId)
        .where((pokemonId) => !visibleIds.contains(pokemonId))
        .toSet();
    return pokemon
        .where((entry) => !hiddenIds.contains(entry.id))
        .map((entry) {
          final visibleForms = entry.formDefinitions
              .where((form) => !hiddenIds.contains(form.pokemon.id))
              .toList(growable: false);
          if (visibleForms.length == entry.formDefinitions.length) return entry;
          return entry.copyWith(formDefinitions: visibleForms);
        })
        .toList(growable: false);
  }

  static void clearCache() {
    _cachedAllPokemon = null;
    _cachedCustomRevision = -1;
    _cachedLocaleRevision = -1;
    _loadingAllPokemon = null;
    _loadingCustomRevision = -1;
    _loadingLocaleRevision = -1;
  }

  Future<List<Pokemon>> _getLegacyPokemon() async {
    final indexString = await rootBundle.loadString(
      'assets/data/index_order.json',
    );

    final Map<String, dynamic> indexMap = jsonDecode(indexString);
    final List<Pokemon> pokemonList = [];

    final orderedKeys = indexMap.keys.toList()
      ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

    for (final key in orderedKeys) {
      final List<dynamic> names = indexMap[key];

      for (final dynamic name in names) {
        final pokemonName = name.toString();

        try {
          final fileName = _normalizePokemonFileName(pokemonName);

          final jsonString = await rootBundle.loadString(
            'assets/data/pokemon/$fileName.json',
          );

          final Map<String, dynamic> json = jsonDecode(jsonString);

          pokemonList.add(Pokemon.fromJson(pokemonName, json));
        } catch (e) {
          debugPrint('Errore caricando $pokemonName: $e');
        }
      }
    }

    return pokemonList;
  }

  Future<List<Pokemon>> _getWebappPokemon() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data_webapp/pokemon.json',
      );
      final json = Map<String, dynamic>.from(jsonDecode(jsonString));
      final items = List<dynamic>.from(json['items'] ?? const []);
      final physicalMetadata = await _getWebappPhysicalMetadata();
      final grouped = <int, List<Pokemon>>{};

      for (final item in items) {
        if (item is! Map) continue;

        try {
          final itemJson = Map<String, dynamic>.from(item);
          final assetSlug = itemJson['id']?.toString();
          final pokemon = Pokemon.fromWebJson(
            itemJson,
            physicalMetadata: assetSlug == null
                ? null
                : physicalMetadata[assetSlug],
          );
          if (pokemon.id > 0 && pokemon.name.trim().isNotEmpty) {
            grouped.putIfAbsent(pokemon.id, () => []).add(pokemon);
          }
        } catch (error) {
          debugPrint('Errore convertendo Pokemon webapp: $error');
        }
      }

      return [for (final group in grouped.values) _mergeWebFormGroup(group)];
    } catch (error) {
      debugPrint('Catalogo Pokemon webapp non disponibile: $error');
      return const [];
    }
  }

  Future<Map<String, Map<String, dynamic>>> _getWebappPhysicalMetadata() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data_webapp/pokemon_physical.json',
      );
      final json = Map<String, dynamic>.from(jsonDecode(jsonString));
      final rawItems = json['items'];
      if (rawItems is! Map) return const {};

      return {
        for (final entry in rawItems.entries)
          if (entry.value is Map)
            entry.key.toString(): Map<String, dynamic>.from(entry.value as Map),
      };
    } catch (error) {
      debugPrint('Metadati fisici delle forme non disponibili: $error');
      return const {};
    }
  }

  Pokemon _mergeWebFormGroup(List<Pokemon> group) {
    if (group.length <= 1) return group.first;

    final speciesSlug = _commonSlugPrefix(
      group.map((pokemon) => pokemon.assetSlug ?? _slug(pokemon.name)),
    );
    Pokemon? explicitBase;
    for (final pokemon in group) {
      if ((pokemon.assetSlug ?? _slug(pokemon.name)) == speciesSlug) {
        explicitBase = pokemon;
        break;
      }
    }

    final sorted = [...group]
      ..sort((a, b) {
        final aSlug = a.assetSlug ?? _slug(a.name);
        final bSlug = b.assetSlug ?? _slug(b.name);
        final lengthCompare = aSlug.length.compareTo(bSlug.length);
        return lengthCompare != 0 ? lengthCompare : aSlug.compareTo(bSlug);
      });
    final selectedBase = explicitBase ?? sorted.first;
    final defaultSpeciesName =
        explicitBase?.name ?? Pokemon.labelFromId(speciesSlug);
    final speciesName =
        GameCatalogLocale.isItalian &&
            explicitBase?.assetSlug == 'gimmighoul'
        ? 'Gimmighoul (Scrigno)'
        : defaultSpeciesName;
    final definitions = <PokemonFormDefinition>[];

    for (final candidate in group) {
      final candidateSlug = candidate.assetSlug ?? _slug(candidate.name);
      if (explicitBase != null && identical(candidate, explicitBase)) continue;
      if (candidateSlug == speciesSlug) continue;

      final rawSuffix = candidateSlug.startsWith('$speciesSlug-')
          ? candidateSlug.substring(speciesSlug.length + 1)
          : candidateSlug;
      if (rawSuffix.isEmpty) continue;

      final gender = Pokemon.normalizeGenderValue(rawSuffix);
      definitions.add(
        PokemonFormDefinition(
          key: rawSuffix,
          displayName: _webFormLabel(rawSuffix),
          pokemon: candidate.copyWith(
            name: speciesName,
            formDefinitions: const [],
          ),
          gender: gender,
        ),
      );
    }

    return selectedBase.copyWith(
      name: speciesName,
      formDefinitions: definitions,
    );
  }

  String _commonSlugPrefix(Iterable<String> values) {
    final tokenLists = values
        .map(
          (value) =>
              value.split('-').where((token) => token.isNotEmpty).toList(),
        )
        .where((tokens) => tokens.isNotEmpty)
        .toList(growable: false);
    if (tokenLists.isEmpty) return '';

    final common = <String>[];
    final shortestLength = tokenLists
        .map((tokens) => tokens.length)
        .reduce((a, b) => a < b ? a : b);
    for (var index = 0; index < shortestLength; index++) {
      final token = tokenLists.first[index];
      if (tokenLists.every((tokens) => tokens[index] == token)) {
        common.add(token);
      } else {
        break;
      }
    }

    return common.isEmpty ? tokenLists.first.first : common.join('-');
  }

  String _webFormLabel(String rawSuffix) {
    switch (rawSuffix) {
      case 'm':
      case 'male':
        return GameCatalogLocale.isItalian ? 'Maschio' : 'Male';
      case 'f':
      case 'female':
        return GameCatalogLocale.isItalian ? 'Femmina' : 'Female';
      case 'alola':
      case 'alolan':
        return 'Alola';
      case 'galar':
      case 'galarian':
        return 'Galar';
      case 'hisui':
      case 'hisuian':
        return 'Hisui';
      case 'paldea':
      case 'paldean':
        return 'Paldea';
      default:
        return Pokemon.labelFromId(rawSuffix);
    }
  }

  String _slug(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('♀', '-f')
        .replaceAll('♂', '-m')
        .replaceAll(RegExp(r"[’']"), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  Future<Map<int, PokemonFlavor>> getPokemonFlavors() async {
    final jsonString = await rootBundle.loadString(
      'assets/data/pokemon_flavor.json',
    );

    final Map<String, dynamic> json = jsonDecode(jsonString);
    final flavors = json.map<int, PokemonFlavor>(
      (key, value) => MapEntry(
        int.parse(key),
        PokemonFlavor.fromJson(value as Map<String, dynamic>),
      ),
    );
    final localizedTexts = GameCatalogLocale.isItalian
        ? await PokemonLocalizationRepository().getPokemonTexts()
        : const <int, PokemonLocalizedText>{};

    return flavors.map((pokemonId, flavor) {
      final localized = localizedTexts[pokemonId];
      if (localized == null) return MapEntry(pokemonId, flavor);
      return MapEntry(
        pokemonId,
        PokemonFlavor(
          flavor: localized.description,
          height: flavor.height,
          weight: flavor.weight,
          genus: localized.genus,
        ),
      );
    });
  }

  String _normalizePokemonFileName(String name) {
    return name
        .replaceAll(' ♀', '-f')
        .replaceAll(' ♂', '-m')
        .replaceAll(':', '')
        .replaceAll('é', 'e');
  }
}
