import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/evolution_data.dart';

class EvolutionRepository {
  Map<String, EvolutionData>? _cache;

  Future<Map<String, EvolutionData>> getEvolutionData() async {
    if (_cache != null) return _cache!;

    try {
      _cache = await _getWebappEvolutionData();
      return _cache!;
    } catch (_) {
      _cache = await _getLegacyEvolutionData();
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
