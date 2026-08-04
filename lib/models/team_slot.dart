import 'item_driven_pokemon_form.dart';
import 'pokemon_form_preferences.dart';

class TeamSlot {
  static const Object _unset = Object();

  final int slotIndex;
  final int? pokemonId;
  final String? eggId;
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
    this.eggId,
    this.experience = 0,
    this.currentHp = 0,
    this.nickname,
    this.selectedMoves = const [],
    this.isShiny = false,
    String? gender,
    String? formName,
    this.nature = 'No Nature',
    this.heldItem,
    this.abilities = const [],
    this.feats = const [],
    this.extraSkills = const [],
    this.statusEffects = const [],
    this.customAbilityScores = const {},
    this.loyalty = 0,
  }) : assert(
         pokemonId == null || eggId == null,
         'Uno slot non può contenere contemporaneamente un Pokémon e un uovo.',
       ),
       gender = PokemonFormPreferences.normalizeGender(gender),
       formName = ItemDrivenPokemonForm.normalizePersistedFormName(
         pokemonId: pokemonId,
         formName: PokemonFormPreferences.normalizeFormName(
           formName: formName,
           gender: gender,
         ),
       ) {
    final pokemonId = this.pokemonId;
    if (pokemonId != null) {
      PokemonFormPreferences.setForm(
        pokemonId: pokemonId,
        formName: this.formName,
      );
      PokemonFormPreferences.setShiny(pokemonId: pokemonId, isShiny: isShiny);
      PokemonFormPreferences.setGender(
        pokemonId: pokemonId,
        gender: this.gender,
      );
    }
  }

  bool get isPokemon => pokemonId != null;
  bool get isEgg => eggId != null;
  bool get isEmpty => pokemonId == null && eggId == null;

  String? get effectiveFormName => ItemDrivenPokemonForm.effectiveFormName(
    pokemonId: pokemonId,
    persistedFormName: formName,
    heldItem: heldItem,
  );

  Map<String, dynamic> toJson() {
    return {
      'slotIndex': slotIndex,
      'pokemonId': pokemonId,
      'eggId': eggId,
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
      eggId: json['eggId']?.toString(),
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
    Object? eggId = _unset,
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
    bool clearEgg = false,
  }) {
    final choosingPokemon = pokemonId != null;
    final choosingEgg = !identical(eggId, _unset) && eggId != null;
    final nextPokemonId = choosingEgg
        ? null
        : clearPokemon
        ? null
        : pokemonId ?? this.pokemonId;
    final nextEggId = choosingPokemon || clearEgg
        ? null
        : identical(eggId, _unset)
        ? this.eggId
        : eggId as String?;
    final pokemonChanged = pokemonId != null && pokemonId != this.pokemonId;
    final nextGender = choosingEgg || clearPokemon
        ? null
        : identical(gender, _unset)
        ? this.gender
        : gender as String?;
    final nextFormName =
        choosingEgg ||
            clearPokemon ||
            (pokemonChanged && identical(formName, _unset))
        ? null
        : identical(formName, _unset)
        ? this.formName
        : formName as String?;

    return TeamSlot(
      slotIndex: slotIndex ?? this.slotIndex,
      pokemonId: nextPokemonId,
      eggId: nextEggId,
      experience: choosingEgg ? 0 : experience ?? this.experience,
      currentHp: choosingEgg ? 0 : currentHp ?? this.currentHp,
      nickname: choosingEgg
          ? null
          : identical(nickname, _unset)
          ? this.nickname
          : nickname as String?,
      selectedMoves: choosingEgg
          ? const []
          : selectedMoves ?? this.selectedMoves,
      isShiny: choosingEgg ? false : isShiny ?? this.isShiny,
      gender: nextGender,
      formName: nextFormName,
      nature: choosingEgg ? 'No Nature' : nature ?? this.nature,
      heldItem: choosingEgg
          ? null
          : identical(heldItem, _unset)
          ? this.heldItem
          : heldItem as String?,
      abilities: choosingEgg ? const [] : abilities ?? this.abilities,
      feats: choosingEgg ? const [] : feats ?? this.feats,
      extraSkills: choosingEgg ? const [] : extraSkills ?? this.extraSkills,
      statusEffects: choosingEgg
          ? const []
          : statusEffects ?? this.statusEffects,
      customAbilityScores: choosingEgg
          ? const {}
          : customAbilityScores ?? this.customAbilityScores,
      loyalty: choosingEgg ? 0 : loyalty ?? this.loyalty,
    );
  }
}
