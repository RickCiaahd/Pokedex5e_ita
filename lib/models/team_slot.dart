import 'pokemon_form_preferences.dart';

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
  final String? formName;
  final String nature;
  final String? heldItem;
  final List<String> abilities;
  final List<String> feats;
  final List<String> extraSkills;
  final List<String> statusEffects;
  final Map<String, int> customAbilityScores;
  final int loyalty;

  TeamSlot({
    required this.slotIndex,
    required this.pokemonId,
    this.experience = 0,
    this.currentHp = 0,
    this.nickname,
    this.selectedMoves = const [],
    this.isShiny = false,
    this.gender,
    this.formName,
    this.nature = 'No Nature',
    this.heldItem,
    this.abilities = const [],
    this.feats = const [],
    this.extraSkills = const [],
    this.statusEffects = const [],
    this.customAbilityScores = const {},
    this.loyalty = 0,
  }) {
    final pokemonId = this.pokemonId;
    if (pokemonId != null) {
      PokemonFormPreferences.setForm(
        pokemonId: pokemonId,
        formName: formName,
      );
      PokemonFormPreferences.setShiny(
        pokemonId: pokemonId,
        isShiny: isShiny,
      );
      PokemonFormPreferences.setGender(
        pokemonId: pokemonId,
        gender: gender,
      );
    }
  }

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
      'formName': formName,
      'nature': nature,
      'heldItem': heldItem,
      'abilities': abilities,
      'feats': feats,
      'extraSkills': extraSkills,
      'statusEffects': statusEffects,
      'customAbilityScores': customAbilityScores,
      'loyalty': loyalty,
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
      formName: json['formName'],
      nature: json['nature'] ?? 'No Nature',
      heldItem: json['heldItem'],
      abilities: List<String>.from(json['abilities'] ?? []),
      feats: List<String>.from(json['feats'] ?? []),
      extraSkills: List<String>.from(json['extraSkills'] ?? []),
      statusEffects: List<String>.from(json['statusEffects'] ?? []),
      customAbilityScores: Map<String, int>.from(
        json['customAbilityScores'] ?? {},
      ),
      loyalty: json['loyalty'] ?? 0,
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
    Object? formName = _unset,
    String? nature,
    Object? heldItem = _unset,
    List<String>? abilities,
    List<String>? feats,
    List<String>? extraSkills,
    List<String>? statusEffects,
    Map<String, int>? customAbilityScores,
    int? loyalty,
    bool clearPokemon = false,
  }) {
    final nextPokemonId = clearPokemon ? null : pokemonId ?? this.pokemonId;
    final pokemonChanged = pokemonId != null && pokemonId != this.pokemonId;
    final nextFormName = clearPokemon ||
            (pokemonChanged && identical(formName, _unset))
        ? null
        : identical(formName, _unset)
            ? this.formName
            : formName as String?;

    return TeamSlot(
      slotIndex: slotIndex ?? this.slotIndex,
      pokemonId: nextPokemonId,
      experience: experience ?? this.experience,
      currentHp: currentHp ?? this.currentHp,
      nickname: identical(nickname, _unset)
          ? this.nickname
          : nickname as String?,
      selectedMoves: selectedMoves ?? this.selectedMoves,
      isShiny: isShiny ?? this.isShiny,
      gender: identical(gender, _unset) ? this.gender : gender as String?,
      formName: nextFormName,
      nature: nature ?? this.nature,
      heldItem: identical(heldItem, _unset)
          ? this.heldItem
          : heldItem as String?,
      abilities: abilities ?? this.abilities,
      feats: feats ?? this.feats,
      extraSkills: extraSkills ?? this.extraSkills,
      statusEffects: statusEffects ?? this.statusEffects,
      customAbilityScores: customAbilityScores ?? this.customAbilityScores,
      loyalty: loyalty ?? this.loyalty,
    );
  }
}
