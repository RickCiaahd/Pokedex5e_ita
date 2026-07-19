import 'dart:convert';

import 'package:flutter/services.dart';

class AbilityLocalizationRepository {
  static const List<String> assetPaths = [
    'assets/data/ability_localization_it_001_110.json',
    'assets/data/ability_localization_it_111_120.json',
    'assets/data/ability_localization_it_121_128.json',
    'assets/data/ability_localization_it_129_130.json',
    'assets/data/ability_localization_it_131_140.json',
    'assets/data/ability_localization_it_141_150.json',
    'assets/data/ability_localization_it_151_160.json',
    'assets/data/ability_localization_it_161_170.json',
    'assets/data/ability_localization_it_171_180.json',
    'assets/data/ability_localization_it_181_190.json',
    'assets/data/ability_localization_it_191_200.json',
    'assets/data/ability_localization_it_201_210.json',
    'assets/data/ability_localization_it_211_220.json',
    'assets/data/ability_localization_it_221_230.json',
    'assets/data/ability_localization_it_231_240.json',
    'assets/data/ability_localization_it_241_250.json',
    'assets/data/ability_localization_it_251_260.json',
    'assets/data/ability_localization_it_261_270.json',
    'assets/data/ability_localization_it_271_280.json',
    'assets/data/ability_localization_it_281_290.json',
    'assets/data/ability_localization_it_291_300.json',
    'assets/data/ability_localization_it_301_310.json',
    'assets/data/ability_localization_it_311_320.json',
    'assets/data/ability_localization_it_321_330.json',
  ];

  static Map<String, String>? _cache;

  Future<Map<String, String>> getDescriptions() async {
    final cached = _cache;
    if (cached != null) {
      return Map<String, String>.unmodifiable(cached);
    }

    final result = <String, String>{};
    for (final path in assetPaths) {
      final jsonString = await rootBundle.loadString(path);
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map) {
        throw FormatException('$path non contiene un oggetto JSON.');
      }

      final document = Map<String, dynamic>.from(decoded);
      if (document['locale']?.toString() != 'it') {
        throw FormatException('$path non dichiara la lingua italiana.');
      }
      if (document['source']?.toString() !=
          'assets/data_webapp/abilities.json') {
        throw FormatException('$path dichiara una sorgente non valida.');
      }

      final rawItems = document['items'];
      if (rawItems is! Map) {
        throw FormatException('$path non contiene la mappa items.');
      }

      for (final entry in rawItems.entries) {
        final abilityId = entry.key.toString().trim();
        if (abilityId.isEmpty) {
          throw FormatException('ID abilità vuoto in $path.');
        }
        if (entry.value is! Map) {
          throw FormatException(
            'Traduzione non valida per l’abilità $abilityId in $path.',
          );
        }
        if (result.containsKey(abilityId)) {
          throw FormatException(
            'Traduzione duplicata per l’abilità $abilityId.',
          );
        }

        final item = Map<String, dynamic>.from(entry.value as Map);
        final description = item['description']?.toString().trim() ?? '';
        if (description.isEmpty) {
          throw FormatException(
            'Descrizione incompleta per l’abilità $abilityId in $path.',
          );
        }
        result[abilityId] = description;
      }
    }

    _cache = Map<String, String>.unmodifiable(result);
    return Map<String, String>.unmodifiable(result);
  }

  static void clearCache() {
    _cache = null;
  }
}
