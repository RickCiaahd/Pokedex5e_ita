import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/localization/game_catalog_locale.dart';
import 'package:pokedex_5e_ita/repositories/ability_localization_repository.dart';
import 'package:pokedex_5e_ita/repositories/ability_repository.dart';
import 'package:pokedex_5e_ita/repositories/feat_repository.dart';
import 'package:pokedex_5e_ita/repositories/item_localization_repository.dart';
import 'package:pokedex_5e_ita/repositories/item_repository.dart';
import 'package:pokedex_5e_ita/repositories/move_localization_repository.dart';
import 'package:pokedex_5e_ita/repositories/move_repository.dart';
import 'package:pokedex_5e_ita/repositories/pokemon_localization_repository.dart';
import 'package:pokedex_5e_ita/repositories/pokemon_repository.dart';
import 'package:pokedex_5e_ita/repositories/tm_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final languageCode in const ['it', 'en']) {
    test('catalog runtime baseline $languageCode', () async {
      GameCatalogLocale.setLanguageCode(languageCode);
      _clearCatalogCaches();

      final cold = await _measureCatalogs('cold', languageCode);
      final warm = await _measureCatalogs('warm', languageCode);

      expect(cold.counts['pokemon'], greaterThan(1000));
      expect(cold.counts['moves'], 830);
      expect(cold.counts['abilities'], 330);
      expect(cold.counts['items'], greaterThanOrEqualTo(366));
      expect(cold.counts['feats'], 36);
      expect(warm.counts, cold.counts);

      debugPrint('CATALOG_RUNTIME_BASELINE ${jsonEncode(cold.toJson())}');
      debugPrint('CATALOG_RUNTIME_BASELINE ${jsonEncode(warm.toJson())}');
    });
  }
}

Future<_CatalogMeasurement> _measureCatalogs(
  String mode,
  String languageCode,
) async {
  final durations = <String, double>{};

  Future<T> measure<T>(String name, Future<T> Function() load) async {
    final stopwatch = Stopwatch()..start();
    final result = await load();
    stopwatch.stop();
    durations[name] = stopwatch.elapsedMicroseconds / 1000;
    return result;
  }

  final pokemon = await measure(
    'pokemonMs',
    () => PokemonRepository().getAllPokemon(includeSealed: true),
  );
  final moves = await measure('movesMs', () => MoveRepository().getAllMoves());
  final abilities = await measure(
    'abilitiesMs',
    () => AbilityRepository().getWebAbilities(includeDeprecated: true),
  );
  final items = await measure('itemsMs', () => ItemRepository().getWebItems());
  final feats = await measure(
    'featsMs',
    () => FeatRepository().getFeatDisplayNames(),
  );

  return _CatalogMeasurement(
    mode: mode,
    languageCode: languageCode,
    durationsMs: durations,
    counts: {
      'pokemon': pokemon.length,
      'moves': moves.length,
      'abilities': abilities.length,
      'items': items.length,
      'feats': feats.length,
    },
  );
}

void _clearCatalogCaches() {
  PokemonRepository.clearCache();
  PokemonLocalizationRepository.clearCache();
  MoveRepository.clearCache();
  MoveLocalizationRepository.clearCache();
  AbilityRepository.clearCache();
  AbilityLocalizationRepository.clearCache();
  ItemRepository.clearCache();
  ItemLocalizationRepository.clearCache();
  FeatRepository.clearCache();
  TmRepository.clearCache();
}

class _CatalogMeasurement {
  const _CatalogMeasurement({
    required this.mode,
    required this.languageCode,
    required this.durationsMs,
    required this.counts,
  });

  final String mode;
  final String languageCode;
  final Map<String, double> durationsMs;
  final Map<String, int> counts;

  Map<String, Object> toJson() {
    return {
      'mode': mode,
      'locale': languageCode,
      'durationsMs': durationsMs,
      'counts': counts,
    };
  }
}
