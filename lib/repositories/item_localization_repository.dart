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
  static const String assetPath =
      'assets/data/item_localization_it_pokeball_medicine.json';

  static const String sourceAssetPath = 'assets/data_webapp/items.json';
  static const int catalogCount = 366;
  static const int localizedCount = 87;

  static Map<String, ItemLocalization>? _cache;

  Future<Map<String, ItemLocalization>> getEntries() async {
    final cached = _cache;
    if (cached != null) {
      return Map<String, ItemLocalization>.unmodifiable(cached);
    }

    final jsonString = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map) {
      throw FormatException('$assetPath non contiene un oggetto JSON.');
    }

    final document = Map<String, dynamic>.from(decoded);
    if (document['locale']?.toString() != 'it') {
      throw FormatException('$assetPath non dichiara la lingua italiana.');
    }
    if (document['source']?.toString() != sourceAssetPath) {
      throw FormatException('$assetPath dichiara una sorgente non valida.');
    }
    if (_readInt(document['catalogCount']) != catalogCount ||
        _readInt(document['localizedCount']) != localizedCount) {
      throw FormatException('$assetPath contiene conteggi non validi.');
    }

    final rawTypes = List<dynamic>.from(document['types'] ?? const []);
    final types = rawTypes.map((value) => value.toString()).toSet();
    if (!types.containsAll(const {'pokeball', 'medicine'}) ||
        types.length != 2) {
      throw FormatException('$assetPath dichiara tipi non validi.');
    }

    final rawItems = document['items'];
    if (rawItems is! Map) {
      throw FormatException('$assetPath non contiene la mappa items.');
    }

    final result = <String, ItemLocalization>{};
    for (final entry in rawItems.entries) {
      final itemId = entry.key.toString().trim();
      if (itemId.isEmpty || entry.value is! Map) {
        throw FormatException('Localizzazione oggetto non valida in $assetPath.');
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

    if (result.length != localizedCount) {
      throw FormatException(
        '$assetPath contiene ${result.length} oggetti anziché $localizedCount.',
      );
    }

    _cache = Map<String, ItemLocalization>.unmodifiable(result);
    return Map<String, ItemLocalization>.unmodifiable(result);
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
