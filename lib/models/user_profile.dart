class UserProfile {
  static const defaultProfileId = 'default';
  static const defaultAbilityScores = {
    'STR': 10,
    'DEX': 10,
    'CON': 10,
    'INT': 10,
    'WIS': 10,
    'CHA': 10,
  };

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int trainerLevel;
  final int money;
  final Map<String, int> abilityScores;
  final int armorClass;
  final int maxHp;
  final int currentHp;
  final int speed;
  final String trainerRace;
  final String background;
  final String starterPokemon;
  final String startingPack;
  final List<String> skillProficiencies;
  final List<String> specializations;
  final String trainerPath;

  UserProfile({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.trainerLevel = 1,
    this.money = 0,
    Map<String, int>? abilityScores,
    this.armorClass = 10,
    this.maxHp = 8,
    this.currentHp = 8,
    this.speed = 30,
    this.trainerRace = '',
    this.background = '',
    this.starterPokemon = '',
    this.startingPack = '',
    this.skillProficiencies = const [],
    this.specializations = const [],
    this.trainerPath = '',
  }) : abilityScores = Map.unmodifiable(
         abilityScores ?? defaultAbilityScores,
       );

  factory UserProfile.create(String name) {
    final now = DateTime.now();

    return UserProfile(
      id: now.microsecondsSinceEpoch.toString(),
      name: name,
      createdAt: now,
      updatedAt: now,
      trainerLevel: 1,
      money: 0,
      abilityScores: defaultAbilityScores,
      armorClass: 10,
      maxHp: 8,
      currentHp: 8,
      speed: 30,
      trainerRace: '',
      background: '',
      starterPokemon: '',
      startingPack: '',
      skillProficiencies: const [],
      specializations: const [],
      trainerPath: '',
    );
  }

  factory UserProfile.defaultProfile() {
    final now = DateTime.now();

    return UserProfile(
      id: defaultProfileId,
      name: 'Allenatore',
      createdAt: now,
      updatedAt: now,
      trainerLevel: 1,
      money: 0,
      abilityScores: defaultAbilityScores,
      armorClass: 10,
      maxHp: 8,
      currentHp: 8,
      speed: 30,
      trainerRace: '',
      background: '',
      starterPokemon: '',
      startingPack: '',
      skillProficiencies: const [],
      specializations: const [],
      trainerPath: '',
    );
  }

  UserProfile copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? trainerLevel,
    int? money,
    Map<String, int>? abilityScores,
    int? armorClass,
    int? maxHp,
    int? currentHp,
    int? speed,
    String? trainerRace,
    String? background,
    String? starterPokemon,
    String? startingPack,
    List<String>? skillProficiencies,
    List<String>? specializations,
    String? trainerPath,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      trainerLevel: trainerLevel ?? this.trainerLevel,
      money: money ?? this.money,
      abilityScores: abilityScores ?? this.abilityScores,
      armorClass: armorClass ?? this.armorClass,
      maxHp: maxHp ?? this.maxHp,
      currentHp: currentHp ?? this.currentHp,
      speed: speed ?? this.speed,
      trainerRace: trainerRace ?? this.trainerRace,
      background: background ?? this.background,
      starterPokemon: starterPokemon ?? this.starterPokemon,
      startingPack: startingPack ?? this.startingPack,
      skillProficiencies: skillProficiencies ?? this.skillProficiencies,
      specializations: specializations ?? this.specializations,
      trainerPath: trainerPath ?? this.trainerPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'trainerLevel': trainerLevel,
      'money': money,
      'abilityScores': abilityScores,
      'armorClass': armorClass,
      'maxHp': maxHp,
      'currentHp': currentHp,
      'speed': speed,
      'trainerRace': trainerRace,
      'background': background,
      'starterPokemon': starterPokemon,
      'startingPack': startingPack,
      'skillProficiencies': skillProficiencies,
      'specializations': specializations,
      'trainerPath': trainerPath,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      trainerLevel: json['trainerLevel'] ?? 1,
      money: json['money'] ?? 0,
      abilityScores: _readAbilityScores(json['abilityScores']),
      armorClass: json['armorClass'] ?? 10,
      maxHp: json['maxHp'] ?? 8,
      currentHp: json['currentHp'] ?? json['maxHp'] ?? 8,
      speed: json['speed'] ?? 30,
      trainerRace: json['trainerRace'] ?? '',
      background: json['background'] ?? '',
      starterPokemon: json['starterPokemon'] ?? '',
      startingPack: json['startingPack'] ?? '',
      skillProficiencies: List<String>.from(json['skillProficiencies'] ?? []),
      specializations: List<String>.from(json['specializations'] ?? []),
      trainerPath: json['trainerPath'] ?? '',
    );
  }

  static Map<String, int> _readAbilityScores(dynamic rawScores) {
    if (rawScores is! Map) {
      return defaultAbilityScores;
    }

    return {
      for (final entry in defaultAbilityScores.entries)
        entry.key: rawScores[entry.key] is int ? rawScores[entry.key] : entry.value,
    };
  }
}
