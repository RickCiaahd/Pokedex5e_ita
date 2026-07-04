import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/move_data.dart';

class MoveRepository {
  final Map<String, MoveData?> _cache = {};

  Future<MoveData?> getMove(String name) async {
    if (_cache.containsKey(name)) {
      return _cache[name];
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
}
