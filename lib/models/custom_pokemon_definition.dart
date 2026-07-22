import 'dart:convert';
import 'dart:typed_data';

import 'custom_pokemon_advanced_data.dart';
import 'move_data.dart';
import 'pokemon.dart';
import 'pokemon_attributes.dart';
import 'pokemon_moves.dart';

class CustomPokemonAbilityDefinition {
  const CustomPokemonAbilityDefinition({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;

  factory CustomPokemonAbilityDefinition.fromJson(Map<String, dynamic> json) {
    return CustomPokemonAbilityDefinition(
      id: json['id']?.toString().trim() ?? '',
      name: json['name']?.toString().trim() ?? '',
      description: json['description']?.toString().trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
  };

  void validate() {
    if (id.isEmpty || name.isEmpty || description.isEmpty) {
      throw const FormatException(
        'Ogni abilità esclusiva deve avere ID, nome e descrizione.',
      );
    }
  }
}

class CustomPokemonMoveDefinition {
  const CustomPokemonMoveDefinition({
    required this.id,
    required this.name,
    required this.type,
    required this.pp,
    required this.range,
    required this.duration,
    required this.moveTime,
    required this.description,
    this.scaling,
    this.damageByLevel = const {},
    this.movePowers = const [],
    this.isAttack = false,
    this.save,
    this.higherLevels,
    this.damageModifier,
    this.damageTypes = const [],
    this.attackScope,
  });

  final String id;
  final String name;
  final String type;
  final String pp;
  final String range;
  final String duration;
  final String moveTime;
  final String description;
  final String? scaling;
  final Map<int, String> damageByLevel;
  final List<String> movePowers;
  final bool isAttack;
  final String? save;
  final String? higherLevels;
  final String? damageModifier;
  final List<String> damageTypes;
  final String? attackScope;

  factory CustomPokemonMoveDefinition.fromJson(Map<String, dynamic> json) {
    final rawDamage = json['damageByLevel'];
    final damageByLevel = <int, String>{};
    if (rawDamage is Map) {
      for (final entry in rawDamage.entries) {
        final level = int.tryParse(entry.key.toString());
        final dice = entry.value?.toString().trim() ?? '';
        if (level != null && level > 0 && dice.isNotEmpty) {
          damageByLevel[level] = dice;
        }
      }
    }

    return CustomPokemonMoveDefinition(
      id: json['id']?.toString().trim() ?? '',
      name: json['name']?.toString().trim() ?? '',
      type: json['type']?.toString().trim() ?? 'Typeless',
      pp: json['pp']?.toString().trim() ?? '-',
      range: json['range']?.toString().trim() ?? '-',
      duration: json['duration']?.toString().trim() ?? '-',
      moveTime: json['moveTime']?.toString().trim() ?? '-',
      description: json['description']?.toString().trim() ?? '',
      scaling: _nullableText(json['scaling']),
      damageByLevel: damageByLevel,
      movePowers: _stringList(json['movePowers']),
      isAttack: json['isAttack'] == true,
      save: _nullableText(json['save']),
      higherLevels: _nullableText(json['higherLevels']),
      damageModifier: _nullableText(json['damageModifier']),
      damageTypes: _stringList(json['damageTypes']),
      attackScope: _nullableText(json['attackScope']),
    );
  }

  MoveData toMoveData() {
    return MoveData(
      id: id,
      name: name,
      type: type,
      pp: pp,
      range: range,
      duration: duration,
      moveTime: moveTime,
      description: description,
      scaling: scaling,
      higherLevels: higherLevels,
      damageByLevel: damageByLevel.map(
        (level, dice) => MapEntry(level, MoveDamage.fromDiceString(dice)),
      ),
      movePowers: List<String>.unmodifiable(movePowers),
      isAttack: isAttack,
      save: save,
      damageModifier: damageModifier,
      damageTypes: List<String>.unmodifiable(damageTypes),
      attackScope: attackScope,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'pp': pp,
    'range': range,
    'duration': duration,
    'moveTime': moveTime,
    'description': description,
    if (scaling != null) 'scaling': scaling,
    'damageByLevel': {
      for (final entry in damageByLevel.entries)
        entry.key.toString(): entry.value,
    },
    'movePowers': movePowers,
    'isAttack': isAttack,
    if (save != null) 'save': save,
    if (higherLevels != null) 'higherLevels': higherLevels,
    if (damageModifier != null) 'damageModifier': damageModifier,
    'damageTypes': damageTypes,
    if (attackScope != null) 'attackScope': attackScope,
  };

  void validate() {
    if (id.isEmpty || name.isEmpty || type.isEmpty || description.isEmpty) {
      throw const FormatException(
        'Ogni mossa esclusiva deve avere ID, nome, tipo e descrizione.',
      );
    }
    for (final entry in damageByLevel.entries) {
      if (entry.key <= 0 || entry.value.trim().isEmpty) {
        throw FormatException('Progressione danni non valida per $name.');
      }
    }
  }
}

class CustomPokemonDefinition {
  const CustomPokemonDefinition({
    required this.formatVersion,
    required this.stableId,
    required this.pokemonId,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    required this.author,
    required this.types,
    required this.armorClass,
    required this.hitPoints,
    required this.size,
    required this.speed,
    required this.attributes,
    required this.abilities,
    required this.skills,
    required this.savingThrows,
    required this.startingMoves,
    required this.levelMoves,
    required this.tmMoves,
    required this.eggMoves,
    this.eggGroups = const [],
    this.baseSpeciesId,
    required this.hitDice,
    required this.sr,
    required this.minLevelFound,
    this.hiddenAbility,
    this.description,
    this.genus,
    this.height,
    this.weight,
    this.genderRatio,
    this.creatorNotes,
    this.imageMimeType,
    this.imageBase64,
    this.shinyImageMimeType,
    this.shinyImageBase64,
    this.localMoves = const [],
    this.localAbilities = const [],
    this.advanced = const CustomPokemonAdvancedData(),
  });

  static const int currentFormatVersion = 2;
  static const int firstCustomPokemonId = 2000000;
  static const int maxImageBytes = 5 * 1024 * 1024;
  static const Set<String> supportedImageMimeTypes = {
    'image/png',
    'image/jpeg',
    'image/webp',
  };

  final int formatVersion;
  final String stableId;
  final int pokemonId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String name;
  final String author;
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
  final List<String> startingMoves;
  final Map<int, List<String>> levelMoves;
  final List<int> tmMoves;
  final List<String> eggMoves;
  final List<String> eggGroups;
  final int? baseSpeciesId;
  final int hitDice;
  final double sr;
  final int minLevelFound;
  final String? description;
  final String? genus;
  final int? height;
  final int? weight;
  final String? genderRatio;
  final String? creatorNotes;
  final String? imageMimeType;
  final String? imageBase64;
  final String? shinyImageMimeType;
  final String? shinyImageBase64;
  final List<CustomPokemonMoveDefinition> localMoves;
  final List<CustomPokemonAbilityDefinition> localAbilities;
  final CustomPokemonAdvancedData advanced;

  bool get hasImage => imageBase64 != null && imageBase64!.isNotEmpty;
  bool get hasShinyImage =>
      shinyImageBase64 != null && shinyImageBase64!.isNotEmpty;

  Uint8List? get imageBytes => _decodeImage(imageBase64);
  Uint8List? get shinyImageBytes => _decodeImage(shinyImageBase64);

  Pokemon toPokemon() {
    final referencedMoveKeys = <String>{
      ...startingMoves.map(MoveData.referenceKey),
      ...levelMoves.values.expand((moves) => moves).map(MoveData.referenceKey),
      ...eggMoves.map(MoveData.referenceKey),
    };
    final effectiveStartingMoves = <String>[...startingMoves];
    for (final localMove in localMoves) {
      final key = MoveData.referenceKey(localMove.name);
      if (key.isNotEmpty && referencedMoveKeys.add(key)) {
        effectiveStartingMoves.add(localMove.name);
      }
    }

    final basePokemon = Pokemon(
      id: pokemonId,
      name: name,
      types: List<String>.unmodifiable(types),
      armorClass: armorClass,
      hitPoints: hitPoints,
      size: size,
      speed: speed,
      attributes: attributes,
      abilities: List<String>.unmodifiable(abilities),
      hiddenAbility: hiddenAbility,
      skills: List<String>.unmodifiable(skills),
      savingThrows: List<String>.unmodifiable(savingThrows),
      moves: PokemonMoves(
        startingMoves: List<String>.unmodifiable(effectiveStartingMoves),
        levelMoves: {
          for (final entry in levelMoves.entries)
            entry.key: List<String>.unmodifiable(entry.value),
        },
        tmMoves: List<int>.unmodifiable(tmMoves),
        eggMoves: List<String>.unmodifiable(eggMoves),
      ),
      hitDice: hitDice,
      sr: sr,
      minLevelFound: minLevelFound,
      assetSlug: 'fakemon-$stableId',
      genderRatio: genderRatio,
      description: description,
      genus: genus,
      height: height,
      weight: weight,
    );
    return basePokemon.copyWith(
      formDefinitions: [
        for (final form in advanced.forms) form.toPokemonForm(basePokemon),
      ],
    );
  }

  Map<String, MoveData> localMoveCatalog() {
    final result = <String, MoveData>{};
    for (final definition in localMoves) {
      final move = definition.toMoveData();
      result[MoveData.referenceKey(definition.id)] = move;
      result[MoveData.referenceKey(definition.name)] = move;
    }
    return Map<String, MoveData>.unmodifiable(result);
  }

  Map<String, String> localAbilityCatalog() {
    final result = <String, String>{};
    for (final definition in localAbilities) {
      result[definition.name] = definition.description;
    }
    return Map<String, String>.unmodifiable(result);
  }

  factory CustomPokemonDefinition.fromJson(Map<String, dynamic> json) {
    final rawAttributes = json['attributes'];
    final rawLevelMoves = json['levelMoves'];
    final levelMoves = <int, List<String>>{};
    if (rawLevelMoves is Map) {
      for (final entry in rawLevelMoves.entries) {
        final level = int.tryParse(entry.key.toString());
        if (level != null && level > 0) {
          levelMoves[level] = _stringList(entry.value);
        }
      }
    }

    final definition = CustomPokemonDefinition(
      formatVersion: _readInt(json['formatVersion']),
      stableId: json['stableId']?.toString().trim() ?? '',
      pokemonId: _readInt(json['pokemonId']),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      name: json['name']?.toString().trim() ?? '',
      author: json['author']?.toString().trim() ?? '',
      types: _stringList(json['types']),
      armorClass: _readInt(json['armorClass']),
      hitPoints: _readInt(json['hitPoints']),
      size: json['size']?.toString().trim() ?? '',
      speed: _readInt(json['speed']),
      attributes: PokemonAttributes.fromJson(
        rawAttributes is Map
            ? Map<String, dynamic>.from(rawAttributes)
            : const <String, dynamic>{},
      ),
      abilities: _stringList(json['abilities']),
      hiddenAbility: _nullableText(json['hiddenAbility']),
      skills: _stringList(json['skills']),
      savingThrows: _stringList(json['savingThrows']),
      startingMoves: _stringList(json['startingMoves']),
      levelMoves: levelMoves,
      tmMoves: _intList(json['tmMoves']),
      eggMoves: _stringList(json['eggMoves']),
      eggGroups: _stringList(json['eggGroups']),
      baseSpeciesId: _nullableInt(json['baseSpeciesId']),
      hitDice: _readInt(json['hitDice']),
      sr: _readDouble(json['sr']),
      minLevelFound: _readInt(json['minLevelFound']),
      description: _nullableText(json['description']),
      genus: _nullableText(json['genus']),
      height: _nullableInt(json['height']),
      weight: _nullableInt(json['weight']),
      genderRatio: _nullableText(json['genderRatio']),
      creatorNotes: _nullableText(json['creatorNotes']),
      imageMimeType: _nullableText(json['imageMimeType']),
      imageBase64: _nullableText(json['imageBase64']),
      shinyImageMimeType: _nullableText(json['shinyImageMimeType']),
      shinyImageBase64: _nullableText(json['shinyImageBase64']),
      localMoves: _mapList(
        json['localMoves'],
      ).map(CustomPokemonMoveDefinition.fromJson).toList(growable: false),
      localAbilities: _mapList(
        json['localAbilities'],
      ).map(CustomPokemonAbilityDefinition.fromJson).toList(growable: false),
      advanced: json['advanced'] is Map
          ? CustomPokemonAdvancedData.fromJson(
              Map<String, dynamic>.from(json['advanced'] as Map),
            )
          : const CustomPokemonAdvancedData(),
    );
    definition.validate();
    return definition;
  }

  Map<String, dynamic> toJson() {
    validate();
    return {
      'formatVersion': formatVersion,
      'stableId': stableId,
      'pokemonId': pokemonId,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'name': name,
      'author': author,
      'types': types,
      'armorClass': armorClass,
      'hitPoints': hitPoints,
      'size': size,
      'speed': speed,
      'attributes': {
        'STR': attributes.strength,
        'DEX': attributes.dexterity,
        'CON': attributes.constitution,
        'INT': attributes.intelligence,
        'WIS': attributes.wisdom,
        'CHA': attributes.charisma,
      },
      'abilities': abilities,
      if (hiddenAbility != null) 'hiddenAbility': hiddenAbility,
      'skills': skills,
      'savingThrows': savingThrows,
      'startingMoves': startingMoves,
      'levelMoves': {
        for (final entry in levelMoves.entries)
          entry.key.toString(): entry.value,
      },
      'tmMoves': tmMoves,
      'eggMoves': eggMoves,
      'eggGroups': eggGroups,
      if (baseSpeciesId != null) 'baseSpeciesId': baseSpeciesId,
      'hitDice': hitDice,
      'sr': sr,
      'minLevelFound': minLevelFound,
      if (description != null) 'description': description,
      if (genus != null) 'genus': genus,
      if (height != null) 'height': height,
      if (weight != null) 'weight': weight,
      if (genderRatio != null) 'genderRatio': genderRatio,
      if (creatorNotes != null) 'creatorNotes': creatorNotes,
      if (imageMimeType != null) 'imageMimeType': imageMimeType,
      if (imageBase64 != null) 'imageBase64': imageBase64,
      if (shinyImageMimeType != null) 'shinyImageMimeType': shinyImageMimeType,
      if (shinyImageBase64 != null) 'shinyImageBase64': shinyImageBase64,
      if (!advanced.isEmpty) 'advanced': advanced.toJson(),
      'localMoves': localMoves.map((move) => move.toJson()).toList(),
      'localAbilities': localAbilities
          .map((ability) => ability.toJson())
          .toList(),
    };
  }

  void validate() {
    if (formatVersion < 1 || formatVersion > currentFormatVersion) {
      throw FormatException('Versione Fakemon non supportata: $formatVersion.');
    }
    if (stableId.isEmpty || name.isEmpty || author.isEmpty) {
      throw const FormatException(
        'ID, nome e autore del Fakemon sono obbligatori.',
      );
    }
    if (pokemonId < firstCustomPokemonId) {
      throw const FormatException(
        'Identificatore interno del Fakemon non valido.',
      );
    }
    if (types.isEmpty ||
        types.length > 2 ||
        types.any((type) => type.isEmpty)) {
      throw const FormatException(
        'Un Fakemon deve avere uno o due tipi validi.',
      );
    }
    if (eggGroups.length > 2 ||
        eggGroups.any((group) => group.trim().isEmpty) ||
        eggGroups.map((group) => group.trim().toLowerCase()).toSet().length !=
            eggGroups.length) {
      throw const FormatException(
        'Un Fakemon può avere al massimo due Gruppi Uova distinti.',
      );
    }
    if (baseSpeciesId != null && baseSpeciesId! <= 0) {
      throw const FormatException('ID della specie base non valido.');
    }
    if (armorClass <= 0 ||
        hitPoints <= 0 ||
        size.isEmpty ||
        speed < 0 ||
        hitDice <= 0 ||
        sr < 0 ||
        minLevelFound <= 0) {
      throw const FormatException('Statistiche base del Fakemon non valide.');
    }
    final scores = [
      attributes.strength,
      attributes.dexterity,
      attributes.constitution,
      attributes.intelligence,
      attributes.wisdom,
      attributes.charisma,
    ];
    if (scores.any((score) => score < 1 || score > 40)) {
      throw const FormatException(
        'Le caratteristiche del Fakemon devono essere comprese tra 1 e 40.',
      );
    }

    final mimeType = imageMimeType;
    final bytes = imageBytes;
    if ((mimeType == null) != (bytes == null)) {
      throw const FormatException('Immagine Fakemon incompleta o non valida.');
    }
    if (mimeType != null && !supportedImageMimeTypes.contains(mimeType)) {
      throw FormatException('Formato immagine non supportato: $mimeType.');
    }
    if (bytes != null && bytes.length > maxImageBytes) {
      throw const FormatException(
        'L’immagine del Fakemon supera il limite di 5 MB.',
      );
    }
    final shinyBytes = shinyImageBytes;
    if ((shinyImageMimeType == null) != (shinyBytes == null)) {
      throw const FormatException(
        'Immagine shiny Fakemon incompleta o non valida.',
      );
    }
    if (shinyImageMimeType != null &&
        !supportedImageMimeTypes.contains(shinyImageMimeType)) {
      throw FormatException(
        'Formato immagine shiny non supportato: $shinyImageMimeType.',
      );
    }
    if (shinyBytes != null && shinyBytes.length > maxImageBytes) {
      throw const FormatException(
        'L’immagine shiny del Fakemon supera il limite di 5 MB.',
      );
    }
    advanced.validate(currentPokemonId: pokemonId);

    final moveIds = <String>{};
    final moveNames = <String>{};
    for (final move in localMoves) {
      move.validate();
      if (!moveIds.add(MoveData.referenceKey(move.id)) ||
          !moveNames.add(MoveData.referenceKey(move.name))) {
        throw FormatException('Mossa esclusiva duplicata: ${move.name}.');
      }
    }

    final abilityIds = <String>{};
    final abilityNames = <String>{};
    for (final ability in localAbilities) {
      ability.validate();
      if (!abilityIds.add(MoveData.referenceKey(ability.id)) ||
          !abilityNames.add(MoveData.referenceKey(ability.name))) {
        throw FormatException('Abilità esclusiva duplicata: ${ability.name}.');
      }
    }
  }
}

Uint8List? _decodeImage(String? encoded) {
  if (encoded == null || encoded.isEmpty) return null;
  try {
    return Uint8List.fromList(base64Decode(encoded));
  } on FormatException {
    return null;
  }
}

String? _nullableText(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((entry) => entry.toString().trim())
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);
}

List<int> _intList(dynamic value) {
  if (value is! List) return const [];
  return value.map(_nullableInt).whereType<int>().toList(growable: false);
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((entry) => Map<String, dynamic>.from(entry))
      .toList(growable: false);
}

int _readInt(dynamic value) => _nullableInt(value) ?? 0;

double _readDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int? _nullableInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
