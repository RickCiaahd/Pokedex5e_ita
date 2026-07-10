import 'pokemon_attributes.dart';
import 'pokemon_moves.dart';

class Pokemon {
  const Pokemon({
    required this.id,
    required this.name,
    required this.types,
    required this.armorClass,
    required this.hitPoints,
    required this.size,
    required this.speed,
    required this.attributes,
    required this.abilities,
    required this.hiddenAbility,
    required this.skills,
    required this.savingThrows,
    required this.moves,
    required this.hitDice,
    required this.sr,
    required this.minLevelFound,
    this.assetSlug,
    this.genderRatio,
    this.description,
  });

  final int id;
  final String name;
  final List<String> types;
  final int armorClass;
  final int hitPoints;
  final String size;
  final int speed;
  final PokemonAttributes attributes;
  final List<String> abilities;
  final String? hiddenAbility;
  final List<String> skills;
  final List<String> savingThrows;
  final PokemonMoves moves;
  final int hitDice;
  final double sr;
  final int minLevelFound;
  final String? assetSlug;
  final String? genderRatio;
  final String? description;

  factory Pokemon.fromJson(String name, Map<String, dynamic> json) {
    return Pokemon(
      id: json['index'] ?? 0,
      name: name,
      types: List<String>.from(json['Type'] ?? []),
      armorClass: json['AC'] ?? 0,
      hitPoints: json['HP'] ?? 0,
      size: json['size'] ?? 'Unknown',
      speed: json['WSp'] ?? 0,
      attributes: PokemonAttributes.fromJson(
        Map<String, dynamic>.from(json['attributes'] ?? {}),
      ),
      abilities: List<String>.from(json['Abilities'] ?? []),
      hiddenAbility: json['Hidden Ability'],
      skills: List<String>.from(json['Skill'] ?? []),
      savingThrows: List<String>.from(json['saving_throws'] ?? []),
      moves: PokemonMoves.fromJson(json['Moves']),
      hitDice: json['Hit Dice'] ?? 0,
      sr: (json['SR'] ?? 0).toDouble(),
      minLevelFound: json['MIN LVL FD'] ?? 0,
    );
  }

  factory Pokemon.fromWebJson(Map<String, dynamic> json) {
    final abilities = _readWebAbilities(json['abilities']);
    final assetSlug = json['id']?.toString();

    return Pokemon(
      id: _readInt(json['number']),
      name: _readWebDisplayName(json),
      types: _readStringList(json['type']),
      armorClass: _readInt(json['ac']),
      hitPoints: _readInt(json['hp']),
      size: json['size']?.toString() ?? 'Unknown',
      speed: _readWebSpeed(json['speed']),
      attributes: PokemonAttributes.fromWebJson(
        Map<String, dynamic>.from(json['attributes'] ?? const {}),
      ),
      abilities: abilities.normal,
      hiddenAbility: abilities.hidden,
      skills: _readStringList(json['skills']).map(_labelFromId).toList(),
      savingThrows: _readStringList(json['savingThrows'])
          .map((value) => value.toUpperCase())
          .toList(),
      moves: PokemonMoves.fromWebJson(
        Map<String, dynamic>.from(json['moves'] ?? const {}),
      ),
      hitDice: _readHitDice(json['hitDice']),
      sr: _readDouble(json['sr']),
      minLevelFound: _readInt(json['minLevel']),
      assetSlug: assetSlug,
      genderRatio: json['gender']?.toString(),
      description: json['description']?.toString(),
    );
  }

  static String _readWebDisplayName(Map<String, dynamic> json) {
    final rawName = json['name']?.toString().trim() ?? 'Unknown';
    if (rawName.isEmpty) return 'Unknown';

    final rawSlug = _slug(rawName);
    final idSlug = _slug(json['id']?.toString() ?? '');

    const removableSuffixes = [
      'amped',
      'low-key',
      'low-key-form',
      'male',
      'female',
      'm',
      'f',
      'single',
      'rapid',
      'single-strike-style',
      'rapid-strike-style',
      'incarnate',
      'therian',
      'incarnate-forme',
      'therian-forme',
      'altered-forme',
      'origin-forme',
    ];

    for (final suffix in removableSuffixes) {
      final dashedSuffix = '-$suffix';
      if (rawSlug.endsWith(dashedSuffix)) {
        final baseSlug = rawSlug.substring(0, rawSlug.length - dashedSuffix.length);
        if (baseSlug.isNotEmpty) return _labelFromId(baseSlug);
      }
      if (idSlug.isNotEmpty && rawSlug == idSlug && idSlug.endsWith(dashedSuffix)) {
        final baseSlug = idSlug.substring(0, idSlug.length - dashedSuffix.length);
        if (baseSlug.isNotEmpty) return _labelFromId(baseSlug);
      }
    }

    return rawName;
  }

  static _WebAbilities _readWebAbilities(dynamic value) {
    final normal = <String>[];
    String? hidden;

    if (value is List) {
      for (final item in value) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final id = map['id']?.toString() ?? '';
          if (id.trim().isEmpty) continue;

          final name = _labelFromId(id);
          if (map['hidden'] == true) {
            hidden = name;
          } else {
            normal.add(name);
          }
        } else {
          final name = item.toString().trim();
          if (name.isNotEmpty) normal.add(_labelFromId(name));
        }
      }
    }

    return _WebAbilities(normal: normal, hidden: hidden);
  }

  static int _readWebSpeed(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is List) {
      for (final item in value) {
        if (item is! Map) continue;

        final map = Map<String, dynamic>.from(item);
        final type = map['type']?.toString().toLowerCase() ?? '';
        if (type == 'walking' || type == 'walk') {
          return _readInt(map['value']);
        }
      }

      if (value.isNotEmpty && value.first is Map) {
        return _readInt(Map<String, dynamic>.from(value.first)['value']);
      }
    }

    return _readInt(value);
  }

  static int _readHitDice(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    final text = value?.toString().toLowerCase().trim() ?? '';
    if (text.startsWith('d')) {
      return int.tryParse(text.substring(1)) ?? 0;
    }

    return int.tryParse(text) ?? 0;
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _readDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static List<String> _readStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList(growable: false);
    }

    return const [];
  }

  static String _slug(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('_', '-')
        .replaceAll(' ♀', '-f')
        .replaceAll('♀', '-f')
        .replaceAll(' ♂', '-m')
        .replaceAll('♂', '-m')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  static String _labelFromId(String value) {
    final words = value
        .trim()
        .replaceAll('_', '-')
        .split('-')
        .where((word) => word.isNotEmpty);

    return words
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}

class _WebAbilities {
  const _WebAbilities({required this.normal, required this.hidden});

  final List<String> normal;
  final String? hidden;
}
