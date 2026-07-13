import 'generated_encounter.dart';

class SavedEncounterMember {
  const SavedEncounterMember({
    required this.pokemonId,
    required this.level,
    required this.nature,
    required this.selectedMoves,
    required this.isShiny,
    required this.maxHp,
    this.formName,
    this.gender,
    this.ability,
    this.isLocked = false,
  });

  final int pokemonId;
  final String? formName;
  final int level;
  final String? gender;
  final String nature;
  final String? ability;
  final List<String> selectedMoves;
  final bool isShiny;
  final int maxHp;
  final bool isLocked;

  Map<String, dynamic> toJson() => {
    'pokemonId': pokemonId,
    'formName': formName,
    'level': level,
    'gender': gender,
    'nature': nature,
    'ability': ability,
    'selectedMoves': selectedMoves,
    'isShiny': isShiny,
    'maxHp': maxHp,
    'isLocked': isLocked,
  };

  factory SavedEncounterMember.fromJson(Map<String, dynamic> json) {
    return SavedEncounterMember(
      pokemonId: _readInt(json['pokemonId']),
      formName: _readNullableString(json['formName']),
      level: _readInt(json['level'], fallback: 1),
      gender: _readNullableString(json['gender']),
      nature: json['nature']?.toString() ?? 'No Nature',
      ability: _readNullableString(json['ability']),
      selectedMoves: [
        for (final value
            in json['selectedMoves'] is List
                ? List<dynamic>.from(json['selectedMoves'] as List)
                : const <dynamic>[])
          if (value.toString().trim().isNotEmpty) value.toString(),
      ],
      isShiny: json['isShiny'] == true,
      maxHp: _readInt(json['maxHp'], fallback: 1),
      isLocked: json['isLocked'] == true,
    );
  }
}

class SavedEncounter {
  const SavedEncounter({
    required this.id,
    required this.name,
    required this.source,
    required this.party,
    required this.filters,
    required this.targetDifficulty,
    required this.members,
    required this.createdAt,
    required this.updatedAt,
    this.notes = '',
    this.collectionId,
    this.collectionName,
  });

  final String id;
  final String name;
  final String notes;
  final EncounterSource source;
  final EncounterPartyProfile party;
  final EncounterGeneratorFilters filters;
  final EncounterDifficulty targetDifficulty;
  final List<SavedEncounterMember> members;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? collectionId;
  final String? collectionName;

  int get enemyCount => members.length;

  double get averageEnemyLevel {
    if (members.isEmpty) return 0;
    return members.fold<int>(0, (sum, member) => sum + member.level) /
        members.length;
  }

  bool get isValid =>
      id.trim().isNotEmpty &&
      name.trim().isNotEmpty &&
      members.isNotEmpty &&
      members.every(
        (member) =>
            member.pokemonId > 0 &&
            member.level > 0 &&
            member.maxHp > 0 &&
            member.nature.trim().isNotEmpty,
      );

  SavedEncounter copyWith({
    String? id,
    String? name,
    String? notes,
    List<SavedEncounterMember>? members,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavedEncounter(
      id: id ?? this.id,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      source: source,
      party: party,
      filters: filters,
      targetDifficulty: targetDifficulty,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      collectionId: collectionId,
      collectionName: collectionName,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'notes': notes,
    'source': source.name,
    'party': {
      'trainerCount': party.trainerCount,
      'activePokemon': party.activePokemon,
      'averageLevel': party.averageLevel,
    },
    'filters': {
      'habitat': filters.habitat,
      'type': filters.type,
      'minSr': filters.minSr,
      'maxSr': filters.maxSr,
      'minGeneration': filters.minGeneration,
      'maxGeneration': filters.maxGeneration,
      'level': filters.level,
      'includeForms': filters.includeForms,
      'allowLegendary': filters.allowLegendary,
    },
    'targetDifficulty': targetDifficulty.name,
    'members': members.map((member) => member.toJson()).toList(growable: false),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'collectionId': collectionId,
    'collectionName': collectionName,
  };

  factory SavedEncounter.fromJson(Map<String, dynamic> json) {
    final partyJson = json['party'] is Map
        ? Map<String, dynamic>.from(json['party'] as Map)
        : const <String, dynamic>{};
    final filtersJson = json['filters'] is Map
        ? Map<String, dynamic>.from(json['filters'] as Map)
        : const <String, dynamic>{};
    final now = DateTime.now();
    return SavedEncounter(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      source: _sourceFrom(json['source']),
      party: EncounterPartyProfile(
        trainerCount: _readInt(partyJson['trainerCount'], fallback: 1),
        activePokemon: _readInt(partyJson['activePokemon'], fallback: 1),
        averageLevel: _readInt(partyJson['averageLevel'], fallback: 5),
      ),
      filters: EncounterGeneratorFilters(
        habitat: filtersJson['habitat']?.toString() ?? 'Qualsiasi',
        type: _readNullableString(filtersJson['type']),
        minSr: _readDouble(filtersJson['minSr']),
        maxSr: _readDouble(filtersJson['maxSr'], fallback: 20),
        minGeneration: _readInt(filtersJson['minGeneration'], fallback: 1),
        maxGeneration: _readInt(filtersJson['maxGeneration'], fallback: 9),
        level: _readInt(filtersJson['level']),
        includeForms: filtersJson['includeForms'] != false,
        allowLegendary: filtersJson['allowLegendary'] == true,
      ),
      targetDifficulty: _difficultyFrom(json['targetDifficulty']),
      members: [
        for (final value
            in json['members'] is List
                ? List<dynamic>.from(json['members'] as List)
                : const <dynamic>[])
          if (value is Map)
            SavedEncounterMember.fromJson(Map<String, dynamic>.from(value)),
      ],
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? now,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? now,
      collectionId: _readNullableString(json['collectionId']),
      collectionName: _readNullableString(json['collectionName']),
    );
  }
}

EncounterSource _sourceFrom(dynamic value) {
  final name = value?.toString();
  return EncounterSource.values.firstWhere(
    (candidate) => candidate.name == name,
    orElse: () => EncounterSource.manual,
  );
}

EncounterDifficulty _difficultyFrom(dynamic value) {
  final name = value?.toString();
  return EncounterDifficulty.values.firstWhere(
    (candidate) => candidate.name == name,
    orElse: () => EncounterDifficulty.medium,
  );
}

int _readInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _readDouble(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

String? _readNullableString(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}
