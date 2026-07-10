import 'pokemon_attributes.dart';
import 'pokemon_moves.dart';

class PokemonFormDefinition {
  const PokemonFormDefinition({
    required this.key,
    required this.displayName,
    required this.pokemon,
    this.gender,
  });

  final String key;
  final String displayName;
  final Pokemon pokemon;
  final String? gender;
}

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
    this.formDefinitions = const [],
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
  final List<PokemonFormDefinition> formDefinitions;

  factory Pokemon.fromJson(String name, Map<String, dynamic> json) {
    final baseJson = _copyMap(json)..remove('variant_data');
    final basePokemon = Pokemon._fromLegacyJson(name, baseJson);
    final formDefinitions = _readLegacyFormDefinitions(
      speciesName: name,
      baseJson: baseJson,
      variantData: json['variant_data'],
    );

    return basePokemon.copyWith(formDefinitions: formDefinitions);
  }

  factory Pokemon._fromLegacyJson(String name, Map<String, dynamic> json) {
    return Pokemon(
      id: _readInt(json['index']),
      name: name,
      types: _readStringList(json['Type']),
      armorClass: _readInt(json['AC']),
      hitPoints: _readInt(json['HP']),
      size: json['size']?.toString() ?? 'Unknown',
      speed: _readInt(json['WSp']),
      attributes: PokemonAttributes.fromJson(
        Map<String, dynamic>.from(json['attributes'] ?? const {}),
      ),
      abilities: _readStringList(json['Abilities']),
      hiddenAbility: json['Hidden Ability']?.toString(),
      skills: _readStringList(json['Skill']),
      savingThrows: _readStringList(json['saving_throws']),
      moves: PokemonMoves.fromJson(
        json['Moves'] is Map
            ? Map<String, dynamic>.from(json['Moves'] as Map)
            : null,
      ),
      hitDice: _readInt(json['Hit Dice']),
      sr: _readDouble(json['SR']),
      minLevelFound: _readInt(json['MIN LVL FD']),
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
      skills: _readStringList(json['skills']).map(labelFromId).toList(),
      savingThrows: _readStringList(
        json['savingThrows'],
      ).map((value) => value.toUpperCase()).toList(),
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

  Pokemon resolveVariant({String? formName, String? gender}) {
    final requestedForm = formReferenceKey(formName ?? '', name);
    final requestedGender = normalizeGenderValue(gender);

    PokemonFormDefinition? match;
    if (requestedForm.isNotEmpty && requestedForm != 'base') {
      for (final definition in formDefinitions) {
        if (definition.gender != null) continue;
        final key = formReferenceKey(definition.key, name);
        final displayKey = formReferenceKey(definition.displayName, name);
        if (requestedForm == key || requestedForm == displayKey) {
          match = definition;
          break;
        }
      }
    }

    if (match == null && requestedGender != null) {
      for (final definition in formDefinitions) {
        if (normalizeGenderValue(definition.gender) == requestedGender) {
          match = definition;
          break;
        }
      }
    }

    if (match == null) return this;
    return match.pokemon.copyWith(formDefinitions: formDefinitions);
  }

  Pokemon forForm(String? formName) => resolveVariant(formName: formName);

  Pokemon withAdditionalFormDefinitions(
    Iterable<PokemonFormDefinition> additionalDefinitions,
  ) {
    final definitionsByKey = <String, PokemonFormDefinition>{};

    String identity(PokemonFormDefinition definition) {
      final normalizedGender = normalizeGenderValue(definition.gender);
      if (normalizedGender != null) return 'gender:$normalizedGender';
      return 'form:${formReferenceKey(definition.key, name)}';
    }

    for (final definition in formDefinitions) {
      definitionsByKey.putIfAbsent(identity(definition), () => definition);
    }
    for (final definition in additionalDefinitions) {
      definitionsByKey.putIfAbsent(identity(definition), () => definition);
    }

    return copyWith(
      formDefinitions: definitionsByKey.values.toList(growable: false),
    );
  }

  Pokemon copyWith({
    int? id,
    String? name,
    List<String>? types,
    int? armorClass,
    int? hitPoints,
    String? size,
    int? speed,
    PokemonAttributes? attributes,
    List<String>? abilities,
    String? hiddenAbility,
    List<String>? skills,
    List<String>? savingThrows,
    PokemonMoves? moves,
    int? hitDice,
    double? sr,
    int? minLevelFound,
    String? assetSlug,
    String? genderRatio,
    String? description,
    List<PokemonFormDefinition>? formDefinitions,
  }) {
    return Pokemon(
      id: id ?? this.id,
      name: name ?? this.name,
      types: types ?? this.types,
      armorClass: armorClass ?? this.armorClass,
      hitPoints: hitPoints ?? this.hitPoints,
      size: size ?? this.size,
      speed: speed ?? this.speed,
      attributes: attributes ?? this.attributes,
      abilities: abilities ?? this.abilities,
      hiddenAbility: hiddenAbility ?? this.hiddenAbility,
      skills: skills ?? this.skills,
      savingThrows: savingThrows ?? this.savingThrows,
      moves: moves ?? this.moves,
      hitDice: hitDice ?? this.hitDice,
      sr: sr ?? this.sr,
      minLevelFound: minLevelFound ?? this.minLevelFound,
      assetSlug: assetSlug ?? this.assetSlug,
      genderRatio: genderRatio ?? this.genderRatio,
      description: description ?? this.description,
      formDefinitions: formDefinitions ?? this.formDefinitions,
    );
  }

  static List<PokemonFormDefinition> _readLegacyFormDefinitions({
    required String speciesName,
    required Map<String, dynamic> baseJson,
    required dynamic variantData,
  }) {
    if (variantData is! Map) return const [];

    final data = Map<String, dynamic>.from(variantData);
    final variantsValue = data['variants'];
    if (variantsValue is! Map) return const [];

    final defaultKey = data['default']?.toString() ?? '';
    final defaultIdentity = formReferenceKey(defaultKey, speciesName);
    final definitions = <PokemonFormDefinition>[];

    for (final entry in variantsValue.entries) {
      if (entry.value is! Map) continue;

      final key = entry.key.toString();
      final variant = Map<String, dynamic>.from(entry.value as Map);
      final displayName = variant['display']?.toString().trim();
      final resolvedDisplayName = displayName == null || displayName.isEmpty
          ? key
          : displayName;
      final keyIdentity = formReferenceKey(key, speciesName);
      final displayIdentity = formReferenceKey(
        resolvedDisplayName,
        speciesName,
      );
      final isDefault =
          keyIdentity == defaultIdentity ||
          displayIdentity == 'base' ||
          displayIdentity.isEmpty;
      if (isDefault) continue;

      final diff = variant['diff'] is Map
          ? Map<String, dynamic>.from(variant['diff'] as Map)
          : const <String, dynamic>{};
      final mergedJson = _deepMergeMaps(baseJson, diff);
      final formPokemon = Pokemon._fromLegacyJson(speciesName, mergedJson);
      final gender =
          normalizeGenderValue(key) ??
          normalizeGenderValue(resolvedDisplayName);

      definitions.add(
        PokemonFormDefinition(
          key: key,
          displayName: resolvedDisplayName,
          pokemon: formPokemon,
          gender: gender,
        ),
      );
    }

    return definitions;
  }

  static Map<String, dynamic> _deepMergeMaps(
    Map<String, dynamic> base,
    Map<String, dynamic> override,
  ) {
    final result = _copyMap(base);
    for (final entry in override.entries) {
      final current = result[entry.key];
      final next = entry.value;
      if (current is Map && next is Map) {
        result[entry.key] = _deepMergeMaps(
          Map<String, dynamic>.from(current),
          Map<String, dynamic>.from(next),
        );
      } else {
        result[entry.key] = _copyJsonValue(next);
      }
    }
    return result;
  }

  static Map<String, dynamic> _copyMap(Map<String, dynamic> value) {
    return value.map((key, item) => MapEntry(key, _copyJsonValue(item)));
  }

  static dynamic _copyJsonValue(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(key.toString(), _copyJsonValue(item)),
      );
    }
    if (value is List) {
      return value.map(_copyJsonValue).toList(growable: false);
    }
    return value;
  }

  static String formReferenceKey(String value, String speciesName) {
    var normalized = value
        .trim()
        .toLowerCase()
        .replaceAll('♀', ' female ')
        .replaceAll('♂', ' male ')
        .replaceAll(RegExp(r"[’']"), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final normalizedSpecies = speciesName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r"[’']"), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalizedSpecies.isNotEmpty) {
      normalized = normalized
          .replaceAll(
            RegExp('(^| )${RegExp.escape(normalizedSpecies)}( |\$)'),
            ' ',
          )
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }

    normalized = normalized
        .replaceAll(RegExp(r'\b(form|forme|style|mode)\b'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    switch (normalized) {
      case '':
      case 'base':
      case 'default':
      case 'regular':
      case 'normal':
      case 'kanto':
        return 'base';
      case 'alola':
      case 'alolan':
        return 'alolan';
      case 'galar':
      case 'galarian':
        return 'galarian';
      case 'hisui':
      case 'hisuian':
        return 'hisuian';
      case 'paldea':
      case 'paldean':
        return 'paldean';
      default:
        return normalized.replaceAll(' ', '-');
    }
  }

  static String? normalizeGenderValue(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'male':
      case 'm':
      case 'maschio':
        return 'male';
      case 'female':
      case 'f':
      case 'femmina':
        return 'female';
      case 'genderless':
      case 'senza sesso':
        return 'genderless';
      default:
        return null;
    }
  }

  static String labelFromId(String value) {
    final words = value
        .trim()
        .replaceAll('_', '-')
        .split('-')
        .where((word) => word.isNotEmpty);

    return words
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
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
        final baseSlug = rawSlug.substring(
          0,
          rawSlug.length - dashedSuffix.length,
        );
        if (baseSlug.isNotEmpty) return labelFromId(baseSlug);
      }
      if (idSlug.isNotEmpty &&
          rawSlug == idSlug &&
          idSlug.endsWith(dashedSuffix)) {
        final baseSlug = idSlug.substring(
          0,
          idSlug.length - dashedSuffix.length,
        );
        if (baseSlug.isNotEmpty) return labelFromId(baseSlug);
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

          final name = labelFromId(id);
          if (map['hidden'] == true) {
            hidden = name;
          } else {
            normal.add(name);
          }
        } else {
          final name = item.toString().trim();
          if (name.isNotEmpty) normal.add(labelFromId(name));
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
}

class _WebAbilities {
  const _WebAbilities({required this.normal, required this.hidden});

  final List<String> normal;
  final String? hidden;
}
