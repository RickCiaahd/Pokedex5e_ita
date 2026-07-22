import 'dart:convert';
import 'dart:typed_data';

import 'evolution_data.dart';
import 'pokemon.dart';
import 'pokemon_attributes.dart';

class CustomPokemonReference {
  const CustomPokemonReference({
    this.pokemonId,
    this.stableId,
    required this.name,
    this.formName,
  });

  final int? pokemonId;
  final String? stableId;
  final String name;
  final String? formName;

  factory CustomPokemonReference.fromJson(Map<String, dynamic> json) {
    return CustomPokemonReference(
      pokemonId: _nullableInt(json['pokemonId']),
      stableId: _nullableText(json['stableId']),
      name: json['name']?.toString().trim() ?? '',
      formName: _nullableText(json['formName']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (pokemonId != null) 'pokemonId': pokemonId,
        if (stableId != null) 'stableId': stableId,
        'name': name,
        if (formName != null) 'formName': formName,
      };

  void validate() {
    if ((pokemonId == null || pokemonId! <= 0) &&
        (stableId == null || stableId!.isEmpty) &&
        name.isEmpty) {
      throw const FormatException(
        'Ogni collegamento evolutivo deve indicare una specie valida.',
      );
    }
  }
}

class CustomPokemonEvolutionCondition {
  const CustomPokemonEvolutionCondition({
    required this.type,
    required this.value,
  });

  final String type;
  final Object? value;

  factory CustomPokemonEvolutionCondition.fromJson(Map<String, dynamic> json) {
    return CustomPokemonEvolutionCondition(
      type: json['type']?.toString().trim() ?? '',
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() => {'type': type, 'value': value};

  EvolutionRule toEvolutionRule() => EvolutionRule(type: type, value: value);

  void validate() {
    const supported = {'level', 'item', 'loyalty', 'gender', 'move'};
    if (!supported.contains(type)) {
      throw FormatException('Condizione evolutiva non supportata: $type.');
    }
    if (value == null || value.toString().trim().isEmpty) {
      throw const FormatException(
        'Ogni condizione evolutiva deve avere un valore.',
      );
    }
  }
}

class CustomPokemonEvolutionLink {
  const CustomPokemonEvolutionLink({
    required this.id,
    required this.pokemon,
    this.conditions = const [],
    this.asiPoints = 0,
    this.hint,
  });

  final String id;
  final CustomPokemonReference pokemon;
  final List<CustomPokemonEvolutionCondition> conditions;
  final int asiPoints;
  final String? hint;

  factory CustomPokemonEvolutionLink.fromJson(Map<String, dynamic> json) {
    final rawPokemon = json['pokemon'];
    return CustomPokemonEvolutionLink(
      id: json['id']?.toString().trim() ?? '',
      pokemon: CustomPokemonReference.fromJson(
        rawPokemon is Map
            ? Map<String, dynamic>.from(rawPokemon)
            : const <String, dynamic>{},
      ),
      conditions: _mapList(json['conditions'])
          .map(CustomPokemonEvolutionCondition.fromJson)
          .toList(growable: false),
      asiPoints: _readInt(json['asiPoints']),
      hint: _nullableText(json['hint']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pokemon': pokemon.toJson(),
        'conditions': conditions.map((condition) => condition.toJson()).toList(),
        if (asiPoints > 0) 'asiPoints': asiPoints,
        if (hint != null) 'hint': hint,
      };

  void validate() {
    if (id.isEmpty) {
      throw const FormatException('ID del collegamento evolutivo mancante.');
    }
    pokemon.validate();
    if (asiPoints < 0 || asiPoints > 20) {
      throw const FormatException('Punti ASI evolutivi non validi.');
    }
    for (final condition in conditions) {
      condition.validate();
    }
  }
}

enum CustomPokemonFormDuration {
  permanent,
  battle;

  static CustomPokemonFormDuration fromJson(dynamic value) {
    return value?.toString() == 'battle'
        ? CustomPokemonFormDuration.battle
        : CustomPokemonFormDuration.permanent;
  }
}

class CustomPokemonForm {
  const CustomPokemonForm({
    required this.id,
    required this.name,
    this.duration = CustomPokemonFormDuration.permanent,
    this.secretUntilActivated = false,
    this.trackInPokedex = true,
    this.activationHint,
    this.types = const [],
    this.armorClass,
    this.hitPoints,
    this.speed,
    this.attributes,
    this.abilities = const [],
    this.hiddenAbility,
    this.description,
    this.imageMimeType,
    this.imageBase64,
    this.shinyImageMimeType,
    this.shinyImageBase64,
  });

  static const int maxImageBytes = 5 * 1024 * 1024;
  static const Set<String> supportedImageMimeTypes = {
    'image/png',
    'image/jpeg',
    'image/webp',
  };

  final String id;
  final String name;
  final CustomPokemonFormDuration duration;
  final bool secretUntilActivated;
  final bool trackInPokedex;
  final String? activationHint;
  final List<String> types;
  final int? armorClass;
  final int? hitPoints;
  final int? speed;
  final PokemonAttributes? attributes;
  final List<String> abilities;
  final String? hiddenAbility;
  final String? description;
  final String? imageMimeType;
  final String? imageBase64;
  final String? shinyImageMimeType;
  final String? shinyImageBase64;

  Uint8List? get imageBytes => _decodeImage(imageBase64);
  Uint8List? get shinyImageBytes => _decodeImage(shinyImageBase64);

  factory CustomPokemonForm.fromJson(Map<String, dynamic> json) {
    final rawAttributes = json['attributes'];
    return CustomPokemonForm(
      id: json['id']?.toString().trim() ?? '',
      name: json['name']?.toString().trim() ?? '',
      duration: CustomPokemonFormDuration.fromJson(json['duration']),
      secretUntilActivated: json['secretUntilActivated'] == true,
      trackInPokedex: json['trackInPokedex'] != false,
      activationHint: _nullableText(json['activationHint']),
      types: _stringList(json['types']),
      armorClass: _nullableInt(json['armorClass']),
      hitPoints: _nullableInt(json['hitPoints']),
      speed: _nullableInt(json['speed']),
      attributes: rawAttributes is Map
          ? PokemonAttributes.fromJson(Map<String, dynamic>.from(rawAttributes))
          : null,
      abilities: _stringList(json['abilities']),
      hiddenAbility: _nullableText(json['hiddenAbility']),
      description: _nullableText(json['description']),
      imageMimeType: _nullableText(json['imageMimeType']),
      imageBase64: _nullableText(json['imageBase64']),
      shinyImageMimeType: _nullableText(json['shinyImageMimeType']),
      shinyImageBase64: _nullableText(json['shinyImageBase64']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'duration': duration.name,
        'secretUntilActivated': secretUntilActivated,
        'trackInPokedex': trackInPokedex,
        if (activationHint != null) 'activationHint': activationHint,
        'types': types,
        if (armorClass != null) 'armorClass': armorClass,
        if (hitPoints != null) 'hitPoints': hitPoints,
        if (speed != null) 'speed': speed,
        if (attributes != null)
          'attributes': {
            'STR': attributes!.strength,
            'DEX': attributes!.dexterity,
            'CON': attributes!.constitution,
            'INT': attributes!.intelligence,
            'WIS': attributes!.wisdom,
            'CHA': attributes!.charisma,
          },
        'abilities': abilities,
        if (hiddenAbility != null) 'hiddenAbility': hiddenAbility,
        if (description != null) 'description': description,
        if (imageMimeType != null) 'imageMimeType': imageMimeType,
        if (imageBase64 != null) 'imageBase64': imageBase64,
        if (shinyImageMimeType != null)
          'shinyImageMimeType': shinyImageMimeType,
        if (shinyImageBase64 != null) 'shinyImageBase64': shinyImageBase64,
      };

  PokemonFormDefinition toPokemonForm(Pokemon basePokemon) {
    final formPokemon = basePokemon.copyWith(
      types: types.isEmpty ? null : List<String>.unmodifiable(types),
      armorClass: armorClass,
      hitPoints: hitPoints,
      speed: speed,
      attributes: attributes,
      abilities: abilities.isEmpty ? null : List<String>.unmodifiable(abilities),
      hiddenAbility: hiddenAbility,
      description: description,
      formDefinitions: const [],
    );
    return PokemonFormDefinition(
      key: id,
      displayName: name,
      pokemon: formPokemon,
    );
  }

  void validate() {
    if (id.isEmpty || name.isEmpty) {
      throw const FormatException('Ogni forma deve avere ID e nome.');
    }
    if (types.length > 2 || types.any((type) => type.trim().isEmpty)) {
      throw FormatException('Tipi non validi per la forma $name.');
    }
    if (armorClass != null && armorClass! <= 0) {
      throw FormatException('CA non valida per la forma $name.');
    }
    if (hitPoints != null && hitPoints! <= 0) {
      throw FormatException('PF non validi per la forma $name.');
    }
    if (speed != null && speed! < 0) {
      throw FormatException('Velocità non valida per la forma $name.');
    }
    _validateImage(imageMimeType, imageBytes, name);
    _validateImage(shinyImageMimeType, shinyImageBytes, '$name shiny');
  }

  static void _validateImage(String? mimeType, Uint8List? bytes, String label) {
    if ((mimeType == null) != (bytes == null)) {
      throw FormatException('Immagine incompleta per la forma $label.');
    }
    if (mimeType != null && !supportedImageMimeTypes.contains(mimeType)) {
      throw FormatException('Formato immagine non supportato per $label.');
    }
    if (bytes != null && bytes.length > maxImageBytes) {
      throw FormatException('L’immagine della forma $label supera 5 MB.');
    }
  }
}

class CustomPokemonAdvancedData {
  const CustomPokemonAdvancedData({
    this.secretUntilDiscovered = false,
    this.sealedForPlayer = false,
    this.secretHint,
    this.evolvesFrom = const [],
    this.evolvesTo = const [],
    this.forms = const [],
  });

  final bool secretUntilDiscovered;
  final bool sealedForPlayer;
  final String? secretHint;
  final List<CustomPokemonEvolutionLink> evolvesFrom;
  final List<CustomPokemonEvolutionLink> evolvesTo;
  final List<CustomPokemonForm> forms;

  bool get isEmpty =>
      !secretUntilDiscovered &&
      !sealedForPlayer &&
      secretHint == null &&
      evolvesFrom.isEmpty &&
      evolvesTo.isEmpty &&
      forms.isEmpty;

  CustomPokemonAdvancedData copyWith({
    bool? secretUntilDiscovered,
    bool? sealedForPlayer,
    bool clearSealedForPlayer = false,
    String? secretHint,
    bool clearSecretHint = false,
    List<CustomPokemonEvolutionLink>? evolvesFrom,
    List<CustomPokemonEvolutionLink>? evolvesTo,
    List<CustomPokemonForm>? forms,
  }) {
    return CustomPokemonAdvancedData(
      secretUntilDiscovered:
          secretUntilDiscovered ?? this.secretUntilDiscovered,
      sealedForPlayer:
          clearSealedForPlayer ? false : sealedForPlayer ?? this.sealedForPlayer,
      secretHint: clearSecretHint ? null : secretHint ?? this.secretHint,
      evolvesFrom: evolvesFrom ?? this.evolvesFrom,
      evolvesTo: evolvesTo ?? this.evolvesTo,
      forms: forms ?? this.forms,
    );
  }

  factory CustomPokemonAdvancedData.fromJson(Map<String, dynamic> json) {
    return CustomPokemonAdvancedData(
      secretUntilDiscovered: json['secretUntilDiscovered'] == true,
      sealedForPlayer: json['sealedForPlayer'] == true,
      secretHint: _nullableText(json['secretHint']),
      evolvesFrom: _mapList(json['evolvesFrom'])
          .map(CustomPokemonEvolutionLink.fromJson)
          .toList(growable: false),
      evolvesTo: _mapList(json['evolvesTo'])
          .map(CustomPokemonEvolutionLink.fromJson)
          .toList(growable: false),
      forms: _mapList(json['forms'])
          .map(CustomPokemonForm.fromJson)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
        'secretUntilDiscovered': secretUntilDiscovered,
        'sealedForPlayer': sealedForPlayer,
        if (secretHint != null) 'secretHint': secretHint,
        'evolvesFrom': evolvesFrom.map((link) => link.toJson()).toList(),
        'evolvesTo': evolvesTo.map((link) => link.toJson()).toList(),
        'forms': forms.map((form) => form.toJson()).toList(),
      };

  void validate({required int currentPokemonId}) {
    final ids = <String>{};
    for (final link in [...evolvesFrom, ...evolvesTo]) {
      link.validate();
      if (!ids.add(link.id)) {
        throw FormatException('Collegamento evolutivo duplicato: ${link.id}.');
      }
      if (link.pokemon.pokemonId == currentPokemonId) {
        throw const FormatException(
          'Un Fakemon non può essere collegato evolutivamente a se stesso.',
        );
      }
    }

    final formIds = <String>{};
    final formNames = <String>{};
    for (final form in forms) {
      form.validate();
      if (!formIds.add(form.id) || !formNames.add(form.name.toLowerCase())) {
        throw FormatException('Forma duplicata: ${form.name}.');
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

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((entry) => Map<String, dynamic>.from(entry))
      .toList(growable: false);
}

int _readInt(dynamic value) => _nullableInt(value) ?? 0;

int? _nullableInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
