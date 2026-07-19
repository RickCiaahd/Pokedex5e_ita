import 'dart:convert';

import 'package:flutter/services.dart';

class PokemonLocalizedText {
  const PokemonLocalizedText({
    required this.genus,
    required this.description,
  });

  final String genus;
  final String description;

  factory PokemonLocalizedText.fromJson(Map<String, dynamic> json) {
    return PokemonLocalizedText(
      genus: _decodeProtectedText(json['genus']),
      description: _decodeProtectedText(json['description']),
    );
  }
}

String _decodeProtectedText(dynamic value) {
  return value?.toString().replaceAll('¦', '').trim() ?? '';
}

class PokemonLocalizationRepository {
  static const List<String> assetPaths = [
    'assets/data/pokemon_localization_it_gen1_001_050.json',
    'assets/data/pokemon_localization_it_gen1_051_100.json',
    'assets/data/pokemon_localization_it_gen1_101_151.json',
    'assets/data/pokemon_localization_it_gen2_152_200.json',
    'assets/data/pokemon_localization_it_gen2_201_251.json',
    'assets/data/pokemon_localization_it_gen3_252_300.json',
    'assets/data/pokemon_localization_it_gen3_301_350.json',
    'assets/data/pokemon_localization_it_gen3_351_386.json',
    'assets/data/pokemon_localization_it_gen4_387_425.json',
    'assets/data/pokemon_localization_it_gen4_426_465.json',
    'assets/data/pokemon_localization_it_gen4_466_493.json',
    'assets/data/pokemon_localization_it_gen5_494_545.json',
    'assets/data/pokemon_localization_it_gen5_546_597.json',
    'assets/data/pokemon_localization_it_gen5_598_649.json',
    'assets/data/pokemon_localization_it_gen6_650_685.json',
    'assets/data/pokemon_localization_it_gen6_686_721.json',
    'assets/data/pokemon_localization_it_gen7_722_765.json',
    'assets/data/pokemon_localization_it_gen7_766_809.json',
    'assets/data/pokemon_localization_it_gen8_810_841.json',
    'assets/data/pokemon_localization_it_gen8_842_873.json',
    'assets/data/pokemon_localization_it_gen8_874_905.json',
    'assets/data/pokemon_localization_it_gen9_906_935.json',
    'assets/data/pokemon_localization_it_gen9_936_936.json',
    'assets/data/pokemon_localization_it_gen9_937_937.json',
    'assets/data/pokemon_localization_it_gen9_938_943.json',
    'assets/data/pokemon_localization_it_gen9_944_944.json',
    'assets/data/pokemon_localization_it_gen9_945_945.json',
    'assets/data/pokemon_localization_it_gen9_946_947.json',
    'assets/data/pokemon_localization_it_gen9_948_949.json',
    'assets/data/pokemon_localization_it_gen9_950_955.json',
    'assets/data/pokemon_localization_it_gen9_956_959.json',
    'assets/data/pokemon_localization_it_gen9_960_964.json',
    'assets/data/pokemon_localization_it_gen9_965_965.json',
    'assets/data/pokemon_localization_it_gen9_966_975.json',
    'assets/data/pokemon_localization_it_gen9_976_985.json',
    'assets/data/pokemon_localization_it_gen9_986_995.json',
    'assets/data/pokemon_localization_it_gen9_996_1005.json',
    'assets/data/pokemon_localization_it_gen9_1006_1011.json',
    'assets/data/pokemon_localization_it_gen9_1012_1013.json',
    'assets/data/pokemon_localization_it_gen9_1014_1015.json',
    'assets/data/pokemon_localization_it_gen9_1016_1020.json',
    'assets/data/pokemon_localization_it_gen9_1021_1021.json',
    'assets/data/pokemon_localization_it_gen9_1022_1024.json',
    'assets/data/pokemon_localization_it_gen9_1025_1025.json',
  ];

  static Map<int, PokemonLocalizedText>? _cache;

  Future<Map<int, PokemonLocalizedText>> getPokemonTexts() async {
    final cached = _cache;
    if (cached != null) {
      return Map<int, PokemonLocalizedText>.unmodifiable(cached);
    }

    final result = <int, PokemonLocalizedText>{};
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

      final rawItems = document['items'];
      if (rawItems is! Map) {
        throw FormatException('$path non contiene la mappa items.');
      }

      for (final entry in rawItems.entries) {
        final pokemonId = int.tryParse(entry.key.toString());
        if (pokemonId == null || pokemonId <= 0) {
          throw FormatException('ID Pokémon non valido in $path: ${entry.key}.');
        }
        if (entry.value is! Map) {
          throw FormatException('Traduzione non valida per #$pokemonId in $path.');
        }
        if (result.containsKey(pokemonId)) {
          throw FormatException(
            'Traduzione duplicata per il Pokémon #$pokemonId.',
          );
        }

        final text = PokemonLocalizedText.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        );
        if (text.genus.isEmpty || text.description.isEmpty) {
          throw FormatException(
            'Traduzione incompleta per il Pokémon #$pokemonId in $path.',
          );
        }
        result[pokemonId] = text;
      }
    }

    _cache = Map<int, PokemonLocalizedText>.unmodifiable(result);
    return Map<int, PokemonLocalizedText>.unmodifiable(result);
  }

  static void clearCache() {
    _cache = null;
  }
}
