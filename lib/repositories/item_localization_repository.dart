import 'dart:convert';

import 'package:flutter/services.dart';

class ItemLocalization {
  const ItemLocalization({
    required this.sourceName,
    required this.name,
    required this.description,
  });

  final String sourceName;
  final String name;
  final List<String> description;
}

class ItemLocalizationRepository {
  static const List<String> assetPaths = [
    'assets/data/item_localization_it_pokeball_001_024.json',
    'assets/data/item_localization_it_medicine_025_055.json',
    'assets/data/item_localization_it_medicine_056_087.json',
    'assets/data/item_localization_it_berry_088_115.json',
    'assets/data/item_localization_it_evolution_116_154.json',
    'assets/data/item_localization_it_held_155_164.json',
    'assets/data/item_localization_it_held_165_174.json',
    'assets/data/item_localization_it_held_175_184.json',
    'assets/data/item_localization_it_held_185_194.json',
    'assets/data/item_localization_it_held_195_204.json',
    'assets/data/item_localization_it_held_205_214.json',
    'assets/data/item_localization_it_held_215_224.json',
    'assets/data/item_localization_it_held_225_234.json',
    'assets/data/item_localization_it_held_235_244.json',
    'assets/data/item_localization_it_held_245_254.json',
    'assets/data/item_localization_it_held_255_264.json',
    'assets/data/item_localization_it_held_265_274.json',
    'assets/data/item_localization_it_held_275_284.json',
    'assets/data/item_localization_it_held_285_294.json',
    'assets/data/item_localization_it_held_295_304.json',
    'assets/data/item_localization_it_held_305_314.json',
    'assets/data/item_localization_it_held_315_317.json',
    'assets/data/item_localization_it_trainer_gear_318_327.json',
    'assets/data/item_localization_it_trainer_gear_328_337.json',
    'assets/data/item_localization_it_trainer_gear_338_347.json',
    'assets/data/item_localization_it_trainer_gear_348_357.json',
    'assets/data/item_localization_it_trainer_gear_358_366.json',
  ];

  static const String sourceAssetPath = 'assets/data_webapp/items.json';
  static const int catalogCount = 366;
  static const int localizedCount = 366;

  static Map<String, ItemLocalization>? _cache;

  Future<Map<String, ItemLocalization>> getEntries() async {
    final cached = _cache;
    if (cached != null) {
      return Map<String, ItemLocalization>.unmodifiable(cached);
    }

    final result = <String, ItemLocalization>{};
    var declaredCount = 0;

    for (final path in assetPaths) {
      final document = await _loadDocument(path);
      declaredCount += _readInt(document['localizedCount']);

      final rawItems = document['items'];
      if (rawItems is! Map) {
        throw FormatException('$path non contiene la mappa items.');
      }

      for (final entry in rawItems.entries) {
        final itemId = entry.key.toString().trim();
        if (itemId.isEmpty || entry.value is! Map) {
          throw FormatException('Localizzazione oggetto non valida in $path.');
        }
        if (result.containsKey(itemId)) {
          throw FormatException('Localizzazione duplicata per l’oggetto $itemId.');
        }

        final item = Map<String, dynamic>.from(entry.value as Map);
        final sourceName = item['sourceName']?.toString().trim() ?? '';
        final name = item['name']?.toString().trim() ?? '';
        final rawDescription = item['description'];
        if (sourceName.isEmpty || name.isEmpty || rawDescription is! List) {
          throw FormatException(
            'Localizzazione incompleta per l’oggetto $itemId.',
          );
        }

        result[itemId] = ItemLocalization(
          sourceName: sourceName,
          name: name,
          description: List<String>.unmodifiable(
            rawDescription.map((value) => value.toString()),
          ),
        );
      }
    }

    if (declaredCount != localizedCount || result.length != localizedCount) {
      throw FormatException(
        'I cataloghi contengono ${result.length} oggetti anziché $localizedCount.',
      );
    }

    _cache = Map<String, ItemLocalization>.unmodifiable(result);
    return Map<String, ItemLocalization>.unmodifiable(result);
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
    final type = document['type']?.toString();
    if (!const {
      'pokeball',
      'medicine',
      'berry',
      'evolution',
      'held item',
      'trainer gear',
    }.contains(type)) {
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
