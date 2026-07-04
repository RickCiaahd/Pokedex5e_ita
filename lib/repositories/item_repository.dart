import 'dart:convert';

import 'package:flutter/services.dart';

class ItemRepository {
  Map<String, String>? _cache;

  Future<Map<String, String>> getItemDescriptions() async {
    if (_cache != null) {
      return _cache!;
    }

    final jsonString = await rootBundle.loadString('assets/data/items.json');
    final json = Map<String, dynamic>.from(jsonDecode(jsonString));

    _cache = json.map((key, value) {
      final data = Map<String, dynamic>.from(value);
      return MapEntry(key, data['Effect']?.toString() ?? '');
    });

    return _cache!;
  }
}
