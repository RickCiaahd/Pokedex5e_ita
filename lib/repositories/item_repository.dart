import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/bag_item.dart';
import '../models/move_data.dart';
import '../models/tm_data.dart';
import 'move_repository.dart';
import 'tm_repository.dart';

class ItemRepository {
  final MoveRepository _moveRepository = MoveRepository();
  final TmRepository _tmRepository = TmRepository();

  Map<String, String>? _descriptionCache;
  List<BagItem>? _webItemCache;

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
    final json = Map<String, dynamic>.from(jsonDecode(jsonString));
    final itemsJson = List<dynamic>.from(json['items'] ?? const []);
    final items = itemsJson
        .map((value) => BagItem.fromWebJson(Map<String, dynamic>.from(value)))
        .where((item) => item.id.isNotEmpty)
        .toList(growable: true);

    items.addAll(await _getTmItems());

    _webItemCache = items
      ..sort((a, b) {
        final typeCompare = a.type.compareTo(b.type);
        if (typeCompare != 0) return typeCompare;
        return a.name.compareTo(b.name);
      });

    return _webItemCache!;
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
      '${tm.label}: insegna $moveName a un Pokémon compatibile.',
      if (move?.description.isNotEmpty == true) move!.description,
    ];

    return BagItem(
      id: tm.id,
      name: '${tm.label} - $moveName',
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

  String _labelFromId(String id) {
    return id
        .split('-')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
