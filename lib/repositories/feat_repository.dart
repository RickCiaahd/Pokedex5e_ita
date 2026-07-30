import 'dart:convert';

import 'package:flutter/services.dart';

import '../localization/feat_description_overrides.dart';
import '../localization/game_catalog_locale.dart';

class FeatRepository {
  static const String sourceAssetPath = 'assets/data/feats.json';
  static const String localizationAssetPath =
      'assets/data/feat_localization_it.json';

  Map<String, String>? _sourceDescriptions;
  Map<String, String>? _localizedDescriptions;
  Map<String, String>? _localizedNames;

  Future<Map<String, String>> getFeatDescriptions() async {
    final source = await _loadSourceDescriptions();
    if (!GameCatalogLocale.isItalian) {
      return Map<String, String>.unmodifiable({
        for (final entry in source.entries)
          entry.key: featDescriptionOverridesEn[entry.key] ?? entry.value,
      });
    }
    await _loadItalianLocalization(source.keys.toSet());
    return Map<String, String>.unmodifiable({
      for (final entry in _localizedDescriptions!.entries)
        entry.key: featDescriptionOverridesIt[entry.key] ?? entry.value,
    });
  }

  Future<Map<String, String>> getFeatDisplayNames() async {
    final source = await _loadSourceDescriptions();
    if (!GameCatalogLocale.isItalian) {
      return Map<String, String>.unmodifiable({
        for (final name in source.keys) name: name,
      });
    }
    await _loadItalianLocalization(source.keys.toSet());
    return Map<String, String>.unmodifiable(_localizedNames!);
  }

  Future<Map<String, String>> _loadSourceDescriptions() async {
    final cached = _sourceDescriptions;
    if (cached != null) return cached;

    final jsonString = await rootBundle.loadString(sourceAssetPath);
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map) {
      throw FormatException('$sourceAssetPath non contiene un oggetto JSON.');
    }
    final source = <String, String>{};
    for (final entry in decoded.entries) {
      if (entry.value is! Map) {
        throw FormatException('Privilegio ${entry.key} non valido.');
      }
      final item = Map<String, dynamic>.from(entry.value as Map);
      final description = item['Description']?.toString().trim() ?? '';
      if (description.isEmpty) {
        throw FormatException('Descrizione mancante per ${entry.key}.');
      }
      source[entry.key.toString()] = description;
    }
    _sourceDescriptions = Map<String, String>.unmodifiable(source);
    return _sourceDescriptions!;
  }

  Future<void> _loadItalianLocalization(Set<String> sourceNames) async {
    if (_localizedDescriptions != null && _localizedNames != null) return;

    final jsonString = await rootBundle.loadString(localizationAssetPath);
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map) {
      throw FormatException(
        '$localizationAssetPath non contiene un oggetto JSON.',
      );
    }
    final document = Map<String, dynamic>.from(decoded);
    if (document['locale']?.toString() != 'it' ||
        document['source']?.toString() != sourceAssetPath ||
        _readInt(document['catalogCount']) != sourceNames.length) {
      throw FormatException(
        '$localizationAssetPath contiene metadati non validi.',
      );
    }
    final rawItems = document['items'];
    if (rawItems is! Map) {
      throw FormatException('$localizationAssetPath non contiene items.');
    }

    final names = <String, String>{};
    final descriptions = <String, String>{};
    for (final entry in rawItems.entries) {
      final technicalName = entry.key.toString().trim();
      if (technicalName.isEmpty || entry.value is! Map) {
        throw FormatException('Localizzazione privilegio non valida.');
      }
      final item = Map<String, dynamic>.from(entry.value as Map);
      final name = item['name']?.toString().trim() ?? '';
      final description = item['description']?.toString().trim() ?? '';
      if (name.isEmpty || description.isEmpty) {
        throw FormatException(
          'Localizzazione incompleta per $technicalName.',
        );
      }
      names[technicalName] = name;
      descriptions[technicalName] = description;
    }

    final localizedNames = names.keys.toSet();
    if (localizedNames.difference(sourceNames).isNotEmpty ||
        sourceNames.difference(localizedNames).isNotEmpty) {
      throw FormatException(
        '$localizationAssetPath non copre esattamente il catalogo sorgente.',
      );
    }
    _localizedNames = Map<String, String>.unmodifiable(names);
    _localizedDescriptions = Map<String, String>.unmodifiable(descriptions);
  }
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
