import 'dart:convert';

import 'package:flutter/services.dart';

import '../localization/game_catalog_locale.dart';
import '../models/bag_item.dart';
import '../models/move_data.dart';
import '../models/tm_data.dart';
import '../models/trainer_starting_equipment.dart';
import '../services/performance_trace.dart';
import 'item_localization_repository.dart';
import 'move_repository.dart';
import 'tm_repository.dart';

class ItemRepository {
  final MoveRepository _moveRepository = MoveRepository();
  final TmRepository _tmRepository = TmRepository();

  static Map<String, String>? _descriptionCache;
  static Future<Map<String, String>>? _descriptionFuture;
  static List<BagItem>? _webItemCache;
  static Future<List<BagItem>>? _webItemFuture;
  static int _catalogLocaleRevision = -1;

  Future<Map<String, String>> getItemDescriptions() async {
    _ensureLocaleCache();
    if (_descriptionCache != null) {
      return _descriptionCache!;
    }

    final loading = _descriptionFuture;
    if (loading != null) return loading;
    final future = _loadItemDescriptions();
    _descriptionFuture = future;
    try {
      final descriptions = await future;
      _descriptionCache = descriptions;
      return descriptions;
    } finally {
      if (identical(_descriptionFuture, future)) _descriptionFuture = null;
    }
  }

  Future<List<BagItem>> getWebItems() async {
    _ensureLocaleCache();
    if (_webItemCache != null) {
      return _webItemCache!;
    }
    final loading = _webItemFuture;
    if (loading != null) return loading;

    final localeRevision = GameCatalogLocale.revision;
    final future = _loadWebItems();
    _webItemFuture = future;
    try {
      final items = await future;
      if (_catalogLocaleRevision == localeRevision) {
        _webItemCache = items;
      }
      return items;
    } finally {
      if (identical(_webItemFuture, future)) _webItemFuture = null;
    }
  }

  Future<Map<String, String>> _loadItemDescriptions() async {
    final jsonString = await rootBundle.loadString('assets/data/items.json');
    final json = Map<String, dynamic>.from(jsonDecode(jsonString));
    return Map<String, String>.unmodifiable(
      json.map((key, value) {
        final data = Map<String, dynamic>.from(value);
        return MapEntry(key, data['Effect']?.toString() ?? '');
      }),
    );
  }

  Future<List<BagItem>> _loadWebItems() async {
    final performanceTrace = PerformanceTrace.start(
      'catalog.items.load',
      arguments: {'locale': GameCatalogLocale.languageCode},
    );
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data_webapp/items.json',
      );
      final json = Map<String, dynamic>.from(jsonDecode(jsonString));
      final itemsJson = List<dynamic>.from(json['items'] ?? const []);
      final localizations = GameCatalogLocale.isItalian
          ? await ItemLocalizationRepository().getEntries()
          : const <String, ItemLocalization>{};
      final items = itemsJson
          .map((value) => BagItem.fromWebJson(Map<String, dynamic>.from(value)))
          .where((item) => item.id.isNotEmpty)
          .map((item) => _localizedItem(item, localizations[item.id]))
          .toList(growable: true);

      items.addAll(await _getTmItems());
      items.addAll(TrainerStartingEquipment.catalogItems);

      items.sort((a, b) {
        final typeCompare = a.type.compareTo(b.type);
        if (typeCompare != 0) return typeCompare;
        return a.name.compareTo(b.name);
      });
      final result = List<BagItem>.unmodifiable(items);
      performanceTrace.finish(
        arguments: {'status': 'success', 'count': result.length},
      );
      return result;
    } catch (_) {
      performanceTrace.finish(arguments: {'status': 'error'});
      rethrow;
    }
  }

  BagItem _localizedItem(BagItem item, ItemLocalization? localization) {
    if (localization == null) return item;
    if (localization.sourceName != item.name) {
      throw FormatException(
        'Il nome tecnico di ${item.id} non coincide con la localizzazione.',
      );
    }

    return BagItem(
      id: item.id,
      name: localization.name,
      sourceName: item.name,
      type: item.type,
      description: localization.description,
      cost: item.cost,
      spriteAssetPath: item.spriteAssetPath,
    );
  }

  Future<List<BagItem>> _getTmItems() async {
    final tms = await _tmRepository.getTms();
    final items = <BagItem>[];

    for (final tm in tms) {
      items.add(await _tmToBagItem(tm));
    }

    return items;
  }

  Future<BagItem> _tmToBagItem(TmData tm) async {
    final move = await _moveRepository.getMove(tm.moveId);
    final moveName = move?.name ?? _labelFromId(tm.moveId);
    final description = <String>[
      GameCatalogLocale.isItalian
          ? '${tm.label}: insegna $moveName a un Pokémon compatibile.'
          : '${tm.label}: teaches $moveName to a compatible Pokémon.',
      if (move?.description.isNotEmpty == true) move!.description,
    ];

    return BagItem(
      id: tm.id,
      name: '${tm.label} - $moveName',
      sourceName: move == null
          ? '${tm.label} - ${tm.moveId}'
          : '${tm.label} - ${move.technicalName}',
      type: 'tm',
      description: description,
      cost: tm.cost,
      spriteAssetPath: _tmSpritePath(move),
    );
  }

  String _tmSpritePath(MoveData? move) {
    final type = _moveTypeFileName(move?.type ?? 'Normal');
    return 'assets/textures/textures_webapp/items/mt/${type}_TM_IX_sprite.png';
  }

  String _moveTypeFileName(String type) {
    final normalized = type.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '-',
    );

    return normalized
        .split('-')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join('-');
  }

  void _ensureLocaleCache() {
    final revision = GameCatalogLocale.revision;
    if (_catalogLocaleRevision == revision) return;
    _catalogLocaleRevision = revision;
    _descriptionCache = null;
    _descriptionFuture = null;
    _webItemCache = null;
    _webItemFuture = null;
  }

  static void clearCache() {
    _descriptionCache = null;
    _descriptionFuture = null;
    _webItemCache = null;
    _webItemFuture = null;
    _catalogLocaleRevision = -1;
  }

  String _labelFromId(String id) {
    return id
        .split('-')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
