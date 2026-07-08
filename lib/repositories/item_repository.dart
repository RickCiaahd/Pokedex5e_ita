import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/bag_item.dart';

class ItemRepository {
  Map<String, String>? _descriptionCache;
  List<BagItem>? _webItemCache;
  Set<String>? _assetPathCache;

  Future<Map<String, String>> getItemDescriptions() async {
    if (_descriptionCache != null) {
      return _descriptionCache!;
    }

    final jsonString = await rootBundle.loadString('assets/data/items.json');
    final json = Map<String, dynamic>.from(jsonDecode(jsonString));

    _descriptionCache = json.map((key, value) {
      final data = Map<String, dynamic>.from(value);
      return MapEntry(key, data['Effect']?.toString() ?? '');
    });

    return _descriptionCache!;
  }

  Future<List<BagItem>> getWebItems() async {
    if (_webItemCache != null) {
      return _webItemCache!;
    }

    final jsonString = await rootBundle.loadString(
      'assets/data_webapp/items.json',
    );
    final availableSpriteAssets = await _getAvailableAssetPaths();
    final json = Map<String, dynamic>.from(jsonDecode(jsonString));
    final itemsJson = List<dynamic>.from(json['items'] ?? const []);

    _webItemCache = itemsJson
        .map(
          (value) => BagItem.fromWebJson(
            Map<String, dynamic>.from(value),
            availableSpriteAssets: availableSpriteAssets,
          ),
        )
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false)
      ..sort((a, b) {
        final typeCompare = a.type.compareTo(b.type);
        if (typeCompare != 0) return typeCompare;
        return a.name.compareTo(b.name);
      });

    return _webItemCache!;
  }

  Future<Set<String>> _getAvailableAssetPaths() async {
    if (_assetPathCache != null) {
      return _assetPathCache!;
    }

    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    _assetPathCache = manifest.listAssets().toSet();

    return _assetPathCache!;
  }
}
