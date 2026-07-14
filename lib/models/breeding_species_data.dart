import 'dart:convert';

import 'package:flutter/services.dart';

class BreedingSpeciesData {
  const BreedingSpeciesData({
    required this.speciesId,
    required this.eggGroups,
    required this.baseSpeciesId,
    required this.isBaby,
    required this.isLegendary,
    required this.isMythical,
  });

  final int speciesId;
  final List<String> eggGroups;
  final int baseSpeciesId;
  final bool isBaby;
  final bool isLegendary;
  final bool isMythical;

  bool get isDitto => eggGroups.contains('Ditto');
  bool get isUndiscovered => eggGroups.contains('Undiscovered');

  factory BreedingSpeciesData.fromJson(
    int speciesId,
    Map<String, dynamic> json,
  ) {
    return BreedingSpeciesData(
      speciesId: speciesId,
      eggGroups: List<String>.from(json['eggGroups'] ?? const []),
      baseSpeciesId: _readInt(json['baseSpeciesId'], fallback: speciesId),
      isBaby: json['isBaby'] as bool? ?? false,
      isLegendary: json['isLegendary'] as bool? ?? false,
      isMythical: json['isMythical'] as bool? ?? false,
    );
  }

  static int _readInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class BreedingDataService {
  static Map<int, BreedingSpeciesData>? _cache;

  Future<Map<int, BreedingSpeciesData>> load() async {
    final cached = _cache;
    if (cached != null) return Map<int, BreedingSpeciesData>.from(cached);

    final source = await rootBundle.loadString(
      'assets/data/breeding_species.json',
    );
    final decoded = Map<String, dynamic>.from(jsonDecode(source));
    final items = Map<String, dynamic>.from(decoded['items'] ?? const {});
    final result = <int, BreedingSpeciesData>{};
    for (final entry in items.entries) {
      final id = int.tryParse(entry.key);
      if (id == null || entry.value is! Map) continue;
      result[id] = BreedingSpeciesData.fromJson(
        id,
        Map<String, dynamic>.from(entry.value as Map),
      );
    }
    _cache = result;
    return Map<int, BreedingSpeciesData>.from(result);
  }
}
