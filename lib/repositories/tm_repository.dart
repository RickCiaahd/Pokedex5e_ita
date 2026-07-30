import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/tm_data.dart';

class TmRepository {
  static List<TmData>? _cache;
  static Future<List<TmData>>? _loading;

  Future<List<TmData>> getTms() async {
    if (_cache != null) return _cache!;
    final loading = _loading;
    if (loading != null) return loading;

    final future = _loadTms();
    _loading = future;
    try {
      final tms = await future;
      _cache = tms;
      return tms;
    } finally {
      if (identical(_loading, future)) _loading = null;
    }
  }

  Future<List<TmData>> _loadTms() async {
    final jsonString = await rootBundle.loadString(
      'assets/data_webapp/tms.json',
    );
    final json = Map<String, dynamic>.from(jsonDecode(jsonString));
    final tmsJson = List<dynamic>.from(json['tms'] ?? const []);

    final result = tmsJson
        .map((value) => TmData.fromWebJson(Map<String, dynamic>.from(value)))
        .where((tm) => tm.number > 0 && tm.moveId.trim().isNotEmpty)
        .toList(growable: true)
      ..sort((a, b) => a.number.compareTo(b.number));
    return List<TmData>.unmodifiable(result);
  }

  Future<Map<int, TmData>> getTmMap() async {
    final tms = await getTms();
    return {for (final tm in tms) tm.number: tm};
  }

  static void clearCache() {
    _cache = null;
    _loading = null;
  }
}
