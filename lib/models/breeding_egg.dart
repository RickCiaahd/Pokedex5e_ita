enum EggIncubator { none, basic, plus, superIncubator }

extension EggIncubatorDetails on EggIncubator {
  String get label => switch (this) {
    EggIncubator.none => 'Nessuno',
    EggIncubator.basic => 'Basic',
    EggIncubator.plus => 'Plus',
    EggIncubator.superIncubator => 'Super',
  };

  int get extraD20 => switch (this) {
    EggIncubator.none => 0,
    EggIncubator.basic => 1,
    EggIncubator.plus => 2,
    EggIncubator.superIncubator => 3,
  };

  String? get itemId => switch (this) {
    EggIncubator.none => null,
    EggIncubator.basic => 'basic-incubator',
    EggIncubator.plus => 'plus-incubator',
    EggIncubator.superIncubator => 'super-incubator',
  };

  int get cost => switch (this) {
    EggIncubator.none => 0,
    EggIncubator.basic => 1000,
    EggIncubator.plus => 3000,
    EggIncubator.superIncubator => 10000,
  };
}

class BreedingEgg {
  static const Object _unset = Object();
  static const int armorClass = 8;
  static const int maxHitPoints = 10;

  const BreedingEgg({
    required this.id,
    required this.speciesId,
    required this.parentNames,
    required this.createdAt,
    required this.hatchTime,
    required this.incubationRemaining,
    required this.nature,
    required this.gender,
    required this.ability,
    required this.selectedMoves,
    required this.inheritedMoves,
    this.formName,
    this.isShiny = false,
    this.incubator = EggIncubator.none,
    this.currentHp = maxHitPoints,
    this.carriedEntireIncubation = true,
    this.isInDayCare = false,
    this.isInPc = false,
    this.goodGenesAbilityBonuses = const {},
    this.goodGenesFeat,
    this.masterOfTraitsApplied = false,
  });

  final String id;
  final int speciesId;
  final String? formName;
  final List<String> parentNames;
  final DateTime createdAt;
  final int hatchTime;
  final int incubationRemaining;
  final String nature;
  final String? gender;
  final String? ability;
  final List<String> selectedMoves;
  final List<String> inheritedMoves;
  final bool isShiny;
  final EggIncubator incubator;
  final int currentHp;
  final bool carriedEntireIncubation;
  final bool isInDayCare;
  final bool isInPc;
  final Map<String, int> goodGenesAbilityBonuses;
  final String? goodGenesFeat;
  final bool masterOfTraitsApplied;

  bool get isReady => incubationRemaining <= 0;
  bool get isDestroyed => currentHp <= 0;
  bool get isInTeam => !isInDayCare && !isInPc;
  bool get hasGoodGenesSelection =>
      goodGenesAbilityBonuses.values.fold<int>(
            0,
            (sum, value) => sum + value,
          ) ==
          2 ||
      (goodGenesFeat?.trim().isNotEmpty ?? false);

  double get progress {
    if (hatchTime <= 0) return 1;
    return (1 - incubationRemaining / hatchTime).clamp(0.0, 1.0);
  }

  BreedingEgg copyWith({
    int? incubationRemaining,
    EggIncubator? incubator,
    int? currentHp,
    bool? carriedEntireIncubation,
    bool? isInDayCare,
    bool? isInPc,
    String? nature,
    Object? gender = _unset,
    Object? ability = _unset,
    List<String>? selectedMoves,
    List<String>? inheritedMoves,
    Map<String, int>? goodGenesAbilityBonuses,
    Object? goodGenesFeat = _unset,
    bool? masterOfTraitsApplied,
    Object? formName = _unset,
  }) {
    return BreedingEgg(
      id: id,
      speciesId: speciesId,
      formName: identical(formName, _unset)
          ? this.formName
          : formName as String?,
      parentNames: parentNames,
      createdAt: createdAt,
      hatchTime: hatchTime,
      incubationRemaining: incubationRemaining ?? this.incubationRemaining,
      nature: nature ?? this.nature,
      gender: identical(gender, _unset) ? this.gender : gender as String?,
      ability: identical(ability, _unset) ? this.ability : ability as String?,
      selectedMoves: selectedMoves ?? this.selectedMoves,
      inheritedMoves: inheritedMoves ?? this.inheritedMoves,
      isShiny: isShiny,
      incubator: incubator ?? this.incubator,
      currentHp: (currentHp ?? this.currentHp).clamp(0, maxHitPoints).toInt(),
      carriedEntireIncubation:
          carriedEntireIncubation ?? this.carriedEntireIncubation,
      isInDayCare: isInDayCare ?? this.isInDayCare,
      isInPc: isInPc ?? this.isInPc,
      goodGenesAbilityBonuses:
          goodGenesAbilityBonuses ?? this.goodGenesAbilityBonuses,
      goodGenesFeat: identical(goodGenesFeat, _unset)
          ? this.goodGenesFeat
          : goodGenesFeat as String?,
      masterOfTraitsApplied:
          masterOfTraitsApplied ?? this.masterOfTraitsApplied,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'speciesId': speciesId,
      'formName': formName,
      'parentNames': parentNames,
      'createdAt': createdAt.toIso8601String(),
      'hatchTime': hatchTime,
      'incubationRemaining': incubationRemaining,
      'nature': nature,
      'gender': gender,
      'ability': ability,
      'selectedMoves': selectedMoves,
      'inheritedMoves': inheritedMoves,
      'isShiny': isShiny,
      'incubator': incubator.name,
      'currentHp': currentHp,
      'carriedEntireIncubation': carriedEntireIncubation,
      'isInDayCare': isInDayCare,
      'isInPc': isInPc,
      'goodGenesAbilityBonuses': goodGenesAbilityBonuses,
      'goodGenesFeat': goodGenesFeat,
      'masterOfTraitsApplied': masterOfTraitsApplied,
    };
  }

  factory BreedingEgg.fromJson(Map<String, dynamic> json) {
    final incubatorName = json['incubator']?.toString() ?? 'none';
    final feat = json['goodGenesFeat']?.toString().trim();
    return BreedingEgg(
      id: json['id']?.toString() ?? '',
      speciesId: _readInt(json['speciesId']),
      formName: json['formName']?.toString(),
      parentNames: List<String>.from(json['parentNames'] ?? const []),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      hatchTime: _readInt(json['hatchTime']),
      incubationRemaining: _readInt(json['incubationRemaining']),
      nature: json['nature']?.toString() ?? 'No Nature',
      gender: json['gender']?.toString(),
      ability: json['ability']?.toString(),
      selectedMoves: List<String>.from(json['selectedMoves'] ?? const []),
      inheritedMoves: List<String>.from(json['inheritedMoves'] ?? const []),
      isShiny: json['isShiny'] as bool? ?? false,
      incubator: EggIncubator.values.firstWhere(
        (value) => value.name == incubatorName,
        orElse: () => EggIncubator.none,
      ),
      currentHp: json.containsKey('currentHp')
          ? _readInt(json['currentHp']).clamp(0, maxHitPoints).toInt()
          : maxHitPoints,
      carriedEntireIncubation: json['carriedEntireIncubation'] as bool? ?? true,
      isInDayCare: json['isInDayCare'] as bool? ?? false,
      isInPc: json['isInPc'] as bool? ?? false,
      goodGenesAbilityBonuses: _readStringIntMap(
        json['goodGenesAbilityBonuses'],
      ),
      goodGenesFeat: feat == null || feat.isEmpty ? null : feat,
      masterOfTraitsApplied: json['masterOfTraitsApplied'] as bool? ?? false,
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static Map<String, int> _readStringIntMap(dynamic value) {
    if (value is! Map) return const {};
    return {
      for (final entry in value.entries)
        if (entry.key is String) entry.key as String: _readInt(entry.value),
    }..removeWhere((_, amount) => amount <= 0);
  }
}
