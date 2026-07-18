import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/pokemon.dart';
import '../models/pokemon_flavor.dart';
import 'custom_pokemon_repository.dart';
import 'pokemon_localization_repository.dart';

class PokemonRepository {
  static List<Pokemon>? _cachedAllPokemon;
  static int _cachedCustomRevision = -1;

  Future<List<Pokemon>> getAllPokemon() async {
    final customRevision = CustomPokemonRepository.revision;
    if (_cachedAllPokemon != null && _cachedCustomRevision == customRevision) {
      return List<Pokemon>.from(_cachedAllPokemon!);
    }

    final pokemonByNumber = <int, Pokemon>{};

    for (final pokemon in await _getLegacyPokemon()) {
      if (pokemon.id <= 0) continue;
      pokemonByNumber[pokemon.id] = pokemon;
    }

    for (final pokemon in await _getWebappPokemon()) {
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
      pokemonByNumber[definition.pokemonId] = definition.toPokemon();
    }

    final localizedTexts = await PokemonLocalizationRepository()
        .getPokemonTexts();
    final pokemonList = pokemonByNumber.values
        .map((pokemon) {
          final localized = localizedTexts[pokemon.id];
          if (localized == null) return pokemon;
          return pokemon.copyWith(
            genus: localized.genus,
            description: localized.description,
          );
        })
        .toList(growable: false)
      ..sort((a, b) => a.id.compareTo(b.id));
    _cachedAllPokemon = pokemonList;
    _cachedCustomRevision = customRevision;

    return List<Pokemon>.from(pokemonList);
  }

  static void clearCache() {
    _cachedAllPokemon = null;
    _cachedCustomRevision = -1;
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
    final speciesName = explicitBase?.name ?? Pokemon.labelFromId(speciesSlug);
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
        return 'Male';
      case 'f':
      case 'female':
        return 'Female';
      case 'alola':
      case 'alolan':
        return 'Alolan';
      case 'galar':
      case 'galarian':
        return 'Galarian';
      case 'hisui':
      case 'hisuian':
        return 'Hisuian';
      case 'paldea':
      case 'paldean':
        return 'Paldean';
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
    final localizedTexts = await PokemonLocalizationRepository()
        .getPokemonTexts();

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
