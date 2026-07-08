import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/move_data.dart';

class MoveRepository {
  final Map<String, MoveData?> _cache = {};
  Map<String, MoveData>? _webMoveCache;

  Future<MoveData?> getMove(String name) async {
    if (_cache.containsKey(name)) {
      return _cache[name];
    }

    final webMoves = await _getWebMoveCatalog();
    final webMove = webMoves[_normalizeMoveKey(name)];
    if (webMove != null) {
      _cache[name] = webMove;
      return webMove;
    }

    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/moves/$name.json',
      );
      final json = Map<String, dynamic>.from(jsonDecode(jsonString));
      final move = MoveData.fromJson(name, json);
      _cache[name] = move;
      return move;
    } catch (_) {
      _cache[name] = null;
      return null;
    }
  }

  Future<Map<String, MoveData?>> getMoves(Iterable<String> names) async {
    final result = <String, MoveData?>{};

    for (final name in names) {
      result[name] = await getMove(name);
    }

    return result;
  }

  Future<List<MoveData>> getAllWebMoves() async {
    final catalog = await _getWebMoveCatalog();
    return catalog.values.toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));
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
      moves[_normalizeMoveKey(move.name)] = move;
    }

    _webMoveCache = moves;
    return _webMoveCache!;
  }

  String _normalizeMoveKey(String value) {
    return value.trim().toLowerCase();
  }
}
