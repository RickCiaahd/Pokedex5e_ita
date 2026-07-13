import 'generated_npc_trainer.dart';

class SavedNpcPokemon {
  const SavedNpcPokemon({
    required this.pokemonId,
    required this.level,
    required this.nature,
    required this.selectedMoves,
    required this.isShiny,
    required this.maxHp,
    this.formName,
    this.gender,
    this.ability,
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
  };

  factory SavedNpcPokemon.fromJson(Map<String, dynamic> json) {
    return SavedNpcPokemon(
      pokemonId: _readInt(json['pokemonId']),
      formName: _readNullableString(json['formName']),
      level: _readInt(json['level'], fallback: 1),
      gender: _readNullableString(json['gender']),
      nature: json['nature']?.toString() ?? 'No Nature',
      ability: _readNullableString(json['ability']),
      selectedMoves: [
        for (final value in _readList(json['selectedMoves']))
          if (value.toString().trim().isNotEmpty) value.toString(),
      ],
      isShiny: json['isShiny'] == true,
      maxHp: _readInt(json['maxHp'], fallback: 1),
    );
  }
}

class SavedNpcTrainer {
  const SavedNpcTrainer({
    required this.id,
    required this.name,
    required this.epithet,
    required this.trainerLevel,
    required this.rank,
    required this.origin,
    required this.path,
    required this.specializations,
    required this.preferredType,
    required this.personality,
    required this.motivation,
    required this.quirk,
    required this.openingLine,
    required this.tactics,
    required this.rewardMoney,
    required this.rewards,
    required this.team,
    required this.options,
    required this.createdAt,
    required this.updatedAt,
    this.notes = '',
  });

  final String id;
  final String name;
  final String epithet;
  final int trainerLevel;
  final NpcTrainerRank rank;
  final String origin;
  final String path;
  final List<String> specializations;
  final String preferredType;
  final String personality;
  final String motivation;
  final String quirk;
  final String openingLine;
  final String tactics;
  final int rewardMoney;
  final List<String> rewards;
  final List<SavedNpcPokemon> team;
  final NpcTrainerGeneratorOptions options;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String notes;

  String get displayName => '$name, $epithet';

  bool get isValid =>
      id.trim().isNotEmpty &&
      name.trim().isNotEmpty &&
      team.isNotEmpty &&
      team.every(
        (pokemon) =>
            pokemon.pokemonId > 0 &&
            pokemon.level > 0 &&
            pokemon.maxHp > 0 &&
            pokemon.nature.trim().isNotEmpty,
      );

  SavedNpcTrainer copyWith({
    String? id,
    String? name,
    String? notes,
    List<SavedNpcPokemon>? team,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavedNpcTrainer(
      id: id ?? this.id,
      name: name ?? this.name,
      epithet: epithet,
      trainerLevel: trainerLevel,
      rank: rank,
      origin: origin,
      path: path,
      specializations: specializations,
      preferredType: preferredType,
      personality: personality,
      motivation: motivation,
      quirk: quirk,
      openingLine: openingLine,
      tactics: tactics,
      rewardMoney: rewardMoney,
      rewards: rewards,
      team: team ?? this.team,
      options: options,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'epithet': epithet,
    'trainerLevel': trainerLevel,
    'rank': rank.name,
    'origin': origin,
    'path': path,
    'specializations': specializations,
    'preferredType': preferredType,
    'personality': personality,
    'motivation': motivation,
    'quirk': quirk,
    'openingLine': openingLine,
    'tactics': tactics,
    'rewardMoney': rewardMoney,
    'rewards': rewards,
    'team': team.map((pokemon) => pokemon.toJson()).toList(growable: false),
    'options': _optionsToJson(options),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'notes': notes,
  };

  factory SavedNpcTrainer.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final optionsJson = json['options'] is Map
        ? Map<String, dynamic>.from(json['options'] as Map)
        : const <String, dynamic>{};
    return SavedNpcTrainer(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      epithet: json['epithet']?.toString() ?? 'Allenatore',
      trainerLevel: _readInt(json['trainerLevel'], fallback: 1),
      rank: _rankFrom(json['rank']),
      origin: json['origin']?.toString() ?? 'Viaggiatore',
      path: json['path']?.toString() ?? 'Allenatore',
      specializations: [
        for (final value in _readList(json['specializations']))
          value.toString(),
      ],
      preferredType: json['preferredType']?.toString() ?? 'Normal',
      personality: json['personality']?.toString() ?? '',
      motivation: json['motivation']?.toString() ?? '',
      quirk: json['quirk']?.toString() ?? '',
      openingLine: json['openingLine']?.toString() ?? '',
      tactics: json['tactics']?.toString() ?? '',
      rewardMoney: _readInt(json['rewardMoney']),
      rewards: [
        for (final value in _readList(json['rewards'])) value.toString(),
      ],
      team: [
        for (final value in _readList(json['team']))
          if (value is Map)
            SavedNpcPokemon.fromJson(Map<String, dynamic>.from(value)),
      ],
      options: _optionsFromJson(optionsJson),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? now,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? now,
      notes: json['notes']?.toString() ?? '',
    );
  }
}

Map<String, dynamic> _optionsToJson(NpcTrainerGeneratorOptions options) => {
  'trainerLevel': options.trainerLevel,
  'pokemonLevel': options.pokemonLevel,
  'teamSize': options.teamSize,
  'rank': options.rank.name,
  'specialization': options.specialization,
  'composition': options.composition.name,
  'minGeneration': options.minGeneration,
  'maxGeneration': options.maxGeneration,
  'includeForms': options.includeForms,
  'allowLegendary': options.allowLegendary,
  'allowDuplicates': options.allowDuplicates,
};

NpcTrainerGeneratorOptions _optionsFromJson(Map<String, dynamic> json) {
  return NpcTrainerGeneratorOptions(
    trainerLevel: _readInt(json['trainerLevel'], fallback: 5),
    pokemonLevel: _readInt(json['pokemonLevel'], fallback: 5),
    teamSize: _readInt(json['teamSize'], fallback: 3),
    rank: _rankFrom(json['rank']),
    specialization: _readNullableString(json['specialization']),
    composition: _compositionFrom(json['composition']),
    minGeneration: _readInt(json['minGeneration'], fallback: 1),
    maxGeneration: _readInt(json['maxGeneration'], fallback: 9),
    includeForms: json['includeForms'] != false,
    allowLegendary: json['allowLegendary'] == true,
    allowDuplicates: json['allowDuplicates'] == true,
  );
}

NpcTrainerRank _rankFrom(dynamic value) {
  final name = value?.toString();
  return NpcTrainerRank.values.firstWhere(
    (candidate) => candidate.name == name,
    orElse: () => NpcTrainerRank.common,
  );
}

NpcTeamComposition _compositionFrom(dynamic value) {
  final name = value?.toString();
  return NpcTeamComposition.values.firstWhere(
    (candidate) => candidate.name == name,
    orElse: () => NpcTeamComposition.mixed,
  );
}

List<dynamic> _readList(dynamic value) =>
    value is List ? List<dynamic>.from(value) : const <dynamic>[];

int _readInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String? _readNullableString(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}
