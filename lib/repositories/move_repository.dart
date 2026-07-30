import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/move_data.dart';
import '../localization/game_catalog_locale.dart';
import '../services/custom_pokemon_runtime_registry.dart';
import '../services/performance_trace.dart';
import 'move_localization_repository.dart';

class MoveRepository {
  static final Map<String, MoveData?> _cache = {};
  static Map<String, MoveData>? _webMoveCache;
  static Future<Map<String, MoveData>>? _webMoveFuture;
  static int _catalogLocaleRevision = -1;

  Future<MoveData?> getMove(String reference, {int? pokemonId}) async {
    _ensureLocaleCache();
    if (pokemonId != null) {
      final localMove = CustomPokemonRuntimeRegistry.moveFor(
        pokemonId,
        reference,
      );
      if (localMove != null) return localMove;
    }

    final cacheKey = _normalizeMoveKey(reference);
    final webMoves = await _getWebMoveCatalog();
    final webMove = webMoves[cacheKey];
    if (webMove != null) {
      _cache[cacheKey] = webMove;
      return webMove;
    }

    final runtimeMove = CustomPokemonRuntimeRegistry.moveForAny(reference);
    if (runtimeMove != null) {
      return runtimeMove;
    }

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/moves/$reference.json',
      );
      final json = Map<String, dynamic>.from(jsonDecode(jsonString));
      final move = MoveData.fromJson(
        reference,
        json,
        localizeToItalian: GameCatalogLocale.isItalian,
      );
      _cache[cacheKey] = move;
      return move;
    } catch (_) {
      _cache[cacheKey] = null;
      return null;
    }
  }

  Future<Map<String, MoveData?>> getMoves(
    Iterable<String> names, {
    int? pokemonId,
  }) async {
    final result = <String, MoveData?>{};

    for (final name in names) {
      result[name] = await getMove(name, pokemonId: pokemonId);
    }

    return result;
  }

  /// Builds a collision-free key for a move resolved in a species context.
  static String contextualKey(int pokemonId, String reference) {
    return '$pokemonId:${MoveData.referenceKey(reference)}';
  }

  /// Resolves move references separately for every Pokémon species.
  Future<Map<String, MoveData?>> getMovesByPokemon(
    Map<int, Iterable<String>> referencesByPokemon,
  ) async {
    final result = <String, MoveData?>{};
    for (final entry in referencesByPokemon.entries) {
      for (final reference in entry.value) {
        result[contextualKey(entry.key, reference)] = await getMove(
          reference,
          pokemonId: entry.key,
        );
      }
    }
    return result;
  }

  /// Returns the complete global move catalog exposed by the app.
  /// Species-local Fakemon moves are intentionally excluded.
  Future<List<MoveData>> getAllMoves() => getAllWebMoves();

  Future<List<MoveData>> getAllWebMoves() async {
    final catalog = await _getWebMoveCatalog();
    final seen = <String>{};

    return catalog.values
        .where((move) => seen.add(move.id))
        .toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  List<MoveData> getLocalMovesForPokemon(int pokemonId) {
    final seen = <String>{};
    final moves = CustomPokemonRuntimeRegistry.moveCatalogFor(
      pokemonId,
    ).values.where((move) => seen.add(move.id)).toList(growable: false);
    moves.sort((a, b) => a.name.compareTo(b.name));
    return moves;
  }

  Future<Map<String, MoveData>> _getWebMoveCatalog() async {
    _ensureLocaleCache();
    if (_webMoveCache != null) return _webMoveCache!;
    final loading = _webMoveFuture;
    if (loading != null) return loading;

    final localeRevision = GameCatalogLocale.revision;
    final future = _loadWebMoveCatalog();
    _webMoveFuture = future;
    try {
      final catalog = await future;
      if (_catalogLocaleRevision == localeRevision) {
        _webMoveCache = catalog;
      }
      return catalog;
    } finally {
      if (identical(_webMoveFuture, future)) {
        _webMoveFuture = null;
      }
    }
  }

  Future<Map<String, MoveData>> _loadWebMoveCatalog() async {
    final performanceTrace = PerformanceTrace.start(
      'catalog.moves.load',
      arguments: {'locale': GameCatalogLocale.languageCode},
    );
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data_webapp/moves.json',
      );
      final json = Map<String, dynamic>.from(jsonDecode(jsonString));
      final movesJson = List<dynamic>.from(json['moves'] ?? const []);
      final localizations = GameCatalogLocale.isItalian
          ? await MoveLocalizationRepository().getEntries()
          : const <String, MoveLocalization>{};
      final moves = <String, MoveData>{};

      for (final value in movesJson) {
        final sourceJson = Map<String, dynamic>.from(value);
        final moveId = sourceJson['id']?.toString() ?? '';
        final move = MoveData.fromWebJson(
          _localizedMoveJson(sourceJson, localizations[moveId]),
          localizeToItalian: GameCatalogLocale.isItalian,
        );
        if (move.name.trim().isEmpty) continue;

        _registerMoveKey(moves, move.id, move);
        _registerMoveKey(moves, move.name, move);
        _registerMoveKey(moves, move.technicalName, move);
      }

      final result = Map<String, MoveData>.unmodifiable(moves);
      performanceTrace.finish(
        arguments: {
          'status': 'success',
          'count': {for (final move in moves.values) move.id}.length,
        },
      );
      return result;
    } catch (_) {
      performanceTrace.finish(arguments: {'status': 'error'});
      rethrow;
    }
  }

  Map<String, dynamic> _localizedMoveJson(
    Map<String, dynamic> source,
    MoveLocalization? localization,
  ) {
    if (localization == null) return source;

    final sourceName = source['name']?.toString() ?? '';
    if (localization.sourceName != sourceName) {
      throw FormatException(
        'Il nome tecnico di ${source['id']} non coincide con la localizzazione.',
      );
    }

    return <String, dynamic>{
      ...source,
      'sourceName': sourceName,
      'name': localization.name,
      'description': localization.description,
      'higherLevels': localization.higherLevels,
    };
  }

  void _ensureLocaleCache() {
    final revision = GameCatalogLocale.revision;
    if (_catalogLocaleRevision == revision) return;
    _catalogLocaleRevision = revision;
    _cache.clear();
    _webMoveCache = null;
    _webMoveFuture = null;
  }

  static void clearCache() {
    _cache.clear();
    _webMoveCache = null;
    _webMoveFuture = null;
    _catalogLocaleRevision = -1;
  }

  void _registerMoveKey(
    Map<String, MoveData> moves,
    String reference,
    MoveData move,
  ) {
    final key = _normalizeMoveKey(reference);
    if (key.isEmpty) return;

    moves[key] = move;
  }

  String _normalizeMoveKey(String value) {
    return MoveData.referenceKey(value);
  }
}
