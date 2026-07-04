class TeamSlot {
  static const Object _unset = Object();

  final int slotIndex;
  final int? pokemonId;
  final int experience;
  final int currentHp;
  final String? nickname;
  final List<String> selectedMoves;
  final bool isShiny;
  final String? gender;
  final String nature;
  final String? heldItem;
  final List<String> feats;
  final List<String> extraSkills;
  final Map<String, int> customAbilityScores;

  TeamSlot({
    required this.slotIndex,
    required this.pokemonId,
    this.experience = 0,
    this.currentHp = 0,
    this.nickname,
    this.selectedMoves = const [],
    this.isShiny = false,
    this.gender,
    this.nature = 'No Nature',
    this.heldItem,
    this.feats = const [],
    this.extraSkills = const [],
    this.customAbilityScores = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'slotIndex': slotIndex,
      'pokemonId': pokemonId,
      'experience': experience,
      'currentHp': currentHp,
      'nickname': nickname,
      'selectedMoves': selectedMoves,
      'isShiny': isShiny,
      'gender': gender,
      'nature': nature,
      'heldItem': heldItem,
      'feats': feats,
      'extraSkills': extraSkills,
      'customAbilityScores': customAbilityScores,
    };
  }

  factory TeamSlot.fromJson(Map<String, dynamic> json) {
    return TeamSlot(
      slotIndex: json['slotIndex'],
      pokemonId: json['pokemonId'],
      experience: json['experience'] ?? 0,
      currentHp: json['currentHp'] ?? 0,
      nickname: json['nickname'],
      selectedMoves: List<String>.from(json['selectedMoves'] ?? []),
      isShiny: json['isShiny'] ?? false,
      gender: json['gender'],
      nature: json['nature'] ?? 'No Nature',
      heldItem: json['heldItem'],
      feats: List<String>.from(json['feats'] ?? []),
      extraSkills: List<String>.from(json['extraSkills'] ?? []),
      customAbilityScores: Map<String, int>.from(
        json['customAbilityScores'] ?? {},
      ),
    );
  }

  TeamSlot copyWith({
    int? slotIndex,
    int? pokemonId,
    int? experience,
    int? currentHp,
    Object? nickname = _unset,
    List<String>? selectedMoves,
    bool? isShiny,
    Object? gender = _unset,
    String? nature,
    Object? heldItem = _unset,
    List<String>? feats,
    List<String>? extraSkills,
    Map<String, int>? customAbilityScores,
    bool clearPokemon = false,
  }) {
    return TeamSlot(
      slotIndex: slotIndex ?? this.slotIndex,
      pokemonId: clearPokemon ? null : pokemonId ?? this.pokemonId,
      experience: experience ?? this.experience,
      currentHp: currentHp ?? this.currentHp,
      nickname: identical(nickname, _unset)
          ? this.nickname
          : nickname as String?,
      selectedMoves: selectedMoves ?? this.selectedMoves,
      isShiny: isShiny ?? this.isShiny,
      gender: identical(gender, _unset) ? this.gender : gender as String?,
      nature: nature ?? this.nature,
      heldItem: identical(heldItem, _unset)
          ? this.heldItem
          : heldItem as String?,
      feats: feats ?? this.feats,
      extraSkills: extraSkills ?? this.extraSkills,
      customAbilityScores: customAbilityScores ?? this.customAbilityScores,
    );
  }
}
