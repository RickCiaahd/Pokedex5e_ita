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
      final option = EvolutionOption.fromWebJson(
        Map<String, dynamic>.from(item),
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
      case 'mr-mime':
        return 'Mr. Mime';
      case 'mime-jr':
        return 'Mime Jr.';
      case 'type-null':
        return 'Type: Null';
      case 'tapu-koko':
        return 'Tapu Koko';
      case 'tapu-lele':
        return 'Tapu Lele';
      case 'tapu-bulu':
        return 'Tapu Bulu';
      case 'tapu-fini':
        return 'Tapu Fini';
    }

    return value
        .split('-')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
