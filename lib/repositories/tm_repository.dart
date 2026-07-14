import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/tm_data.dart';

class TmRepository {
  List<TmData>? _cache;

  Future<List<TmData>> getTms() async {
    if (_cache != null) return _cache!;

    final jsonString = await rootBundle.loadString(
      'assets/data_webapp/tms.json',
    );
    final json = Map<String, dynamic>.from(jsonDecode(jsonString));
    final tmsJson = List<dynamic>.from(json['tms'] ?? const []);

    _cache = tmsJson
        .map((value) => TmData.fromWebJson(Map<String, dynamic>.from(value)))
        .where((tm) => tm.number > 0 && tm.moveId.trim().isNotEmpty)
        .toList(growable: false)
      ..sort((a, b) => a.number.compareTo(b.number));

    return _cache!;
  }

  Future<Map<int, TmData>> getTmMap() async {
    final tms = await getTms();
    return {for (final tm in tms) tm.number: tm};
  }
}
