import 'dart:convert';

import 'package:flutter/services.dart';

class MoveLocalization {
  const MoveLocalization({
    required this.sourceName,
    required this.name,
    required this.description,
    required this.higherLevels,
  });

  final String sourceName;
  final String name;
  final List<dynamic> description;
  final String? higherLevels;
}

class MoveLocalizationRepository {
  static const List<String> assetPaths = [
    'assets/data/move_localization_it_001_010.json',
    'assets/data/move_localization_it_011_020.json',
    'assets/data/move_localization_it_021_030.json',
    'assets/data/move_localization_it_031_040.json',
    'assets/data/move_localization_it_041_050.json',
  ];

  static const String sourceAssetPath = 'assets/data_webapp/moves.json';
  static const int catalogCount = 830;
  static const int localizedCount = 50;

  static Map<String, MoveLocalization>? _cache;

  Future<Map<String, MoveLocalization>> getEntries() async {
    final cached = _cache;
    if (cached != null) {
      return Map<String, MoveLocalization>.unmodifiable(cached);
    }

    final result = <String, MoveLocalization>{};
    var declaredCount = 0;

    for (final path in assetPaths) {
      final document = await _loadDocument(path);
      declaredCount += _readInt(document['localizedCount']);

      final rawItems = document['items'];
      if (rawItems is! Map) {
        throw FormatException('$path non contiene la mappa items.');
      }

      for (final entry in rawItems.entries) {
        final moveId = entry.key.toString().trim();
        if (moveId.isEmpty || entry.value is! Map) {
          throw FormatException('Localizzazione mossa non valida in $path.');
        }
        if (result.containsKey(moveId)) {
          throw FormatException('Localizzazione duplicata per la mossa $moveId.');
        }

        final move = Map<String, dynamic>.from(entry.value as Map);
        final sourceName = move['sourceName']?.toString().trim() ?? '';
        final name = move['name']?.toString().trim() ?? '';
        final rawDescription = move['description'];
        if (sourceName.isEmpty || name.isEmpty || rawDescription is! List) {
          throw FormatException(
            'Localizzazione incompleta per la mossa $moveId.',
          );
        }

        result[moveId] = MoveLocalization(
          sourceName: sourceName,
          name: name,
          description: List<dynamic>.unmodifiable(rawDescription),
          higherLevels: move['higherLevels']?.toString(),
        );
      }
    }

    if (declaredCount != localizedCount || result.length != localizedCount) {
      throw FormatException(
        'I cataloghi contengono ${result.length} mosse anziché $localizedCount.',
      );
    }

    _cache = Map<String, MoveLocalization>.unmodifiable(result);
    return Map<String, MoveLocalization>.unmodifiable(result);
  }

  Future<Map<String, dynamic>> _loadDocument(String path) async {
    final jsonString = await rootBundle.loadString(path);
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map) {
      throw FormatException('$path non contiene un oggetto JSON.');
    }

    final document = Map<String, dynamic>.from(decoded);
    if (document['locale']?.toString() != 'it') {
      throw FormatException('$path non dichiara la lingua italiana.');
    }
    if (document['source']?.toString() != sourceAssetPath) {
      throw FormatException('$path dichiara una sorgente non valida.');
    }
    if (document['type']?.toString() != 'move') {
      throw FormatException('$path dichiara un tipo non valido.');
    }
    if (_readInt(document['localizedCount']) <= 0) {
      throw FormatException('$path dichiara un conteggio non valido.');
    }

    return document;
  }

  static void clearCache() {
    _cache = null;
  }
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
