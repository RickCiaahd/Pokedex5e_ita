import 'dart:convert';

import 'package:flutter/services.dart';

class FeatRepository {
  Map<String, String>? _cache;

  Future<Map<String, String>> getFeatDescriptions() async {
    if (_cache != null) {
      return _cache!;
    }

    final jsonString = await rootBundle.loadString('assets/data/feats.json');
    final json = Map<String, dynamic>.from(jsonDecode(jsonString));

    _cache = json.map((key, value) {
      final data = Map<String, dynamic>.from(value);
      return MapEntry(key, data['Description']?.toString() ?? '');
    });

    return _cache!;
  }
}
