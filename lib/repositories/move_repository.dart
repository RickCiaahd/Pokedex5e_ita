import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/move_data.dart';
import '../services/custom_pokemon_runtime_registry.dart';

class MoveRepository {
  final Map<String, MoveData?> _cache = {};
  Map<String, MoveData>? _webMoveCache;

  Future<MoveData?> getMove(String reference, {int? pokemonId}) async {
    if (pokemonId != null) {
      final localMove = CustomPokemonRuntimeRegistry.moveFor(
        pokemonId,
        reference,
      );
      if (localMove != null) return localMove;
    }

    final cacheKey = _normalizeMoveKey(reference);
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    final webMoves = await _getWebMoveCatalog();
    final webMove = webMoves[cacheKey];
    if (webMove != null) {
      _cache[cacheKey] = webMove;
      return webMove;
    }

    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/moves/$reference.json',
      );
      final json = Map<String, dynamic>.from(jsonDecode(jsonString));
      final move = MoveData.fromJson(reference, json);
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
    final moves = CustomPokemonRuntimeRegistry.moveCatalogFor(pokemonId)
        .values
        .where((move) => seen.add(move.id))
        .toList(growable: false);
    moves.sort((a, b) => a.name.compareTo(b.name));
    return moves;
  }

  Future<Map<String, MoveData>> _getWebMoveCatalog() async {
    if (_webMoveCache != null) return _webMoveCache!;

    final jsonString = await rootBundle.loadString(
      'assets/data_webapp/moves.json',
    );
    final json = Map<String, dynamic>.from(jsonDecode(jsonString));
    final movesJson = List<dynamic>.from(json['moves'] ?? const []);
    final moves = <String, MoveData>{};

    for (final value in movesJson) {
      final move = MoveData.fromWebJson(Map<String, dynamic>.from(value));
      if (move.name.trim().isEmpty) continue;

      _registerMoveKey(moves, move.id, move);
      _registerMoveKey(moves, move.name, move);
    }

    _webMoveCache = moves;
    return _webMoveCache!;
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
