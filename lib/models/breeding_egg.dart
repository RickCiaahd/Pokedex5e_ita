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
}

class BreedingEgg {
  static const Object _unset = Object();

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
    this.carriedEntireIncubation = true,
    this.isInDayCare = false,
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
  final bool carriedEntireIncubation;
  final bool isInDayCare;

  bool get isReady => incubationRemaining <= 0;

  double get progress {
    if (hatchTime <= 0) return 1;
    return (1 - incubationRemaining / hatchTime).clamp(0.0, 1.0);
  }

  BreedingEgg copyWith({
    int? incubationRemaining,
    EggIncubator? incubator,
    bool? carriedEntireIncubation,
    bool? isInDayCare,
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
      nature: nature,
      gender: gender,
      ability: ability,
      selectedMoves: selectedMoves,
      inheritedMoves: inheritedMoves,
      isShiny: isShiny,
      incubator: incubator ?? this.incubator,
      carriedEntireIncubation:
          carriedEntireIncubation ?? this.carriedEntireIncubation,
      isInDayCare: isInDayCare ?? this.isInDayCare,
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
      'carriedEntireIncubation': carriedEntireIncubation,
      'isInDayCare': isInDayCare,
    };
  }

  factory BreedingEgg.fromJson(Map<String, dynamic> json) {
    final incubatorName = json['incubator']?.toString() ?? 'none';
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
      carriedEntireIncubation: json['carriedEntireIncubation'] as bool? ?? true,
      isInDayCare: json['isInDayCare'] as bool? ?? false,
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
