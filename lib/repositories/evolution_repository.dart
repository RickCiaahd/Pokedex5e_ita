import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/custom_pokemon_advanced_data.dart';
import '../models/evolution_data.dart';
import '../services/custom_pokemon_runtime_registry.dart';

class EvolutionRepository {
  Map<String, EvolutionData>? _cache;

  Future<Map<String, EvolutionData>> getEvolutionData() async {
    if (_cache != null) return _cache!;

    try {
      _cache = _withCustomEvolutions(await _getWebappEvolutionData());
      return _cache!;
    } catch (_) {
      _cache = _withCustomEvolutions(await _getLegacyEvolutionData());
      return _cache!;
    }
  }

  Future<Map<String, EvolutionData>> _getWebappEvolutionData() async {
    final jsonString = await rootBundle.loadString(
      'assets/data_webapp/evolution.json',
    );
    final json = Map<String, dynamic>.from(jsonDecode(jsonString));
    final items = List<dynamic>.from(json['items'] ?? const []);
    final grouped = <String, List<EvolutionOption>>{};

    for (final item in items) {
      if (item is! Map) continue;
      final itemJson = Map<String, dynamic>.from(item);
      if (itemJson['nonCanon'] == true) continue;

      final option = EvolutionOption.fromWebJson(
        itemJson,
        displayNameBuilder: _displayNameFromKey,
      );
      if (option.fromKey.isEmpty || option.toKey.isEmpty) continue;

      grouped.putIfAbsent(option.fromKey, () => []).add(option);
    }

    final result = <String, EvolutionData>{};
    for (final entry in grouped.entries) {
      final data = EvolutionData.fromOptions(entry.value);
      result[entry.key] = data;
      result[_displayNameFromKey(entry.key)] = data;
    }

    return result;
  }

  Map<String, EvolutionData> _withCustomEvolutions(
    Map<String, EvolutionData> base,
  ) {
    final grouped = <String, List<EvolutionOption>>{};
    for (final entry in base.entries) {
      final options = grouped.putIfAbsent(
        _referenceKey(entry.key),
        () => <EvolutionOption>[],
      );
      options.addAll(entry.value.options);
    }

    for (final definition in CustomPokemonRuntimeRegistry.definitions) {
      for (final link in definition.advanced.evolvesFrom) {
        final source = _resolvedReference(link.pokemon);
        if (source.name.isEmpty) continue;
        _addCustomOption(
          grouped,
          sourceName: source.name,
          targetName: definition.name,
          targetPokemonId: definition.pokemonId,
          targetStableId: definition.stableId,
          targetFormName: null,
          secret: definition.advanced.sealedForPlayer,
          link: link,
        );
      }
      for (final link in definition.advanced.evolvesTo) {
        final target = _resolvedReference(link.pokemon);
        if (target.name.isEmpty) continue;
        _addCustomOption(
          grouped,
          sourceName: definition.name,
          targetName: target.name,
          targetPokemonId: target.pokemonId,
          targetStableId: target.stableId,
          targetFormName: link.pokemon.formName,
          secret: target.definition?.advanced.sealedForPlayer == true,
          link: link,
        );
      }
    }

    final result = <String, EvolutionData>{};
    for (final entry in grouped.entries) {
      if (entry.value.isEmpty) continue;
      final data = EvolutionData.fromOptions(entry.value);
      result[entry.key] = data;
      final display = _displayNameFromKey(entry.key);
      result[display] = data;
      for (final definition in CustomPokemonRuntimeRegistry.definitions) {
        if (_referenceKey(definition.name) == entry.key) {
          result[definition.name] = data;
        }
      }
    }
    return result;
  }

  void _addCustomOption(
    Map<String, List<EvolutionOption>> grouped, {
    required String sourceName,
    required String targetName,
    required int? targetPokemonId,
    required String? targetStableId,
    required String? targetFormName,
    required bool secret,
    required CustomPokemonEvolutionLink link,
  }) {
    final sourceKey = _referenceKey(sourceName);
    final targetKey = _referenceKey(targetName);
    if (sourceKey.isEmpty || targetKey.isEmpty || sourceKey == targetKey) {
      return;
    }
    final options = grouped.putIfAbsent(sourceKey, () => <EvolutionOption>[]);
    if (options.any((option) => option.id == link.id)) return;
    options.add(
      EvolutionOption(
        id: link.id,
        fromKey: sourceKey,
        toKey: targetKey,
        toName: targetName,
        conditions: link.conditions
            .map((condition) => condition.toEvolutionRule())
            .toList(growable: false),
        effects: [
          if (link.asiPoints > 0)
            EvolutionRule(type: 'asi', value: link.asiPoints),
        ],
        targetPokemonId: targetPokemonId,
        targetStableId: targetStableId,
        targetFormName: targetFormName,
        isSecret: secret,
        secretHint: link.hint,
      ),
    );
  }

  _ResolvedCustomReference _resolvedReference(
    CustomPokemonReference reference,
  ) {
    final definition = CustomPokemonRuntimeRegistry.resolveReference(reference);
    return _ResolvedCustomReference(
      name: definition?.name ?? reference.name,
      pokemonId: definition?.pokemonId ?? reference.pokemonId,
      stableId: definition?.stableId ?? reference.stableId,
      definition: definition,
    );
  }

  String _referenceKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('♀', '-f')
        .replaceAll('♂', '-m')
        .replaceAll(RegExp(r"[’']"), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  Future<Map<String, EvolutionData>> _getLegacyEvolutionData() async {
    final jsonString = await rootBundle.loadString('assets/data/evolve.json');
    final Map<String, dynamic> json = jsonDecode(jsonString);

    return json.map(
      (name, data) => MapEntry(
        name,
        EvolutionData.fromJson(Map<String, dynamic>.from(data)),
      ),
    );
  }

  String _displayNameFromKey(String value) {
    switch (value) {
      case 'nidoran-f':
        return 'Nidoran ♀';
      case 'nidoran-m':
        return 'Nidoran ♂';
      case 'farfetchd':
        return "Farfetch'd";
      case 'sirfetchd':
        return "Sirfetch'd";
      case 'mr-mime':
        return 'Mr. Mime';
      case 'mime-jr':
        return 'Mime Jr.';
      case 'mr-rime':
        return 'Mr. Rime';
      case 'porygon-z':
        return 'Porygon-Z';
      case 'type-null':
        return 'Type: Null';
      case 'ho-oh':
        return 'Ho-Oh';
      case 'flabebe':
        return 'Flabébé';
      case 'jangmo-o':
        return 'Jangmo-o';
      case 'hakamo-o':
        return 'Hakamo-o';
      case 'kommo-o':
        return 'Kommo-o';
      case 'tapu-koko':
        return 'Tapu Koko';
      case 'tapu-lele':
        return 'Tapu Lele';
      case 'tapu-bulu':
        return 'Tapu Bulu';
      case 'tapu-fini':
        return 'Tapu Fini';
    }

    final parts = value
        .split('-')
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    const regionalLabels = <String, String>{
      'alola': 'Alolan',
      'alolan': 'Alolan',
      'galar': 'Galarian',
      'galarian': 'Galarian',
      'hisui': 'Hisuian',
      'hisuian': 'Hisuian',
      'paldea': 'Paldean',
      'paldean': 'Paldean',
    };
    if (parts.length > 1) {
      final leadingRegion = regionalLabels[parts.first];
      if (leadingRegion != null) {
        return '$leadingRegion ${_titleCase(parts.skip(1))}';
      }
      final trailingRegion = regionalLabels[parts.last];
      if (trailingRegion != null) {
        return '$trailingRegion ${_titleCase(parts.take(parts.length - 1))}';
      }
    }

    return _titleCase(parts);
  }

  String _titleCase(Iterable<String> parts) {
    return parts
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class _ResolvedCustomReference {
  const _ResolvedCustomReference({
    required this.name,
    required this.pokemonId,
    required this.stableId,
    required this.definition,
  });

  final String name;
  final int? pokemonId;
  final String? stableId;
  final dynamic definition;
}
