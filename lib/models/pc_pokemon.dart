import 'pokemon_form_preferences.dart';
import 'team_slot.dart';

class PcPokemon {
  PcPokemon({
    required this.id,
    required this.pokemonId,
    DateTime? capturedAt,
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
    this.notes = '',
  }) : capturedAt = capturedAt ?? DateTime.now(),
       gender = PokemonFormPreferences.normalizeGender(gender),
       formName = PokemonFormPreferences.normalizeFormName(
         formName: formName,
         gender: gender,
       ) {
    PokemonFormPreferences.setForm(
      pokemonId: pokemonId,
      formName: this.formName,
    );
    PokemonFormPreferences.setShiny(pokemonId: pokemonId, isShiny: isShiny);
    PokemonFormPreferences.setGender(pokemonId: pokemonId, gender: this.gender);
  }

  final String id;
  final int pokemonId;
  final DateTime capturedAt;
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
  final String notes;

  String get displayName {
    final trimmed = nickname?.trim() ?? '';
    return trimmed.isEmpty ? '' : trimmed;
  }

  TeamSlot toTeamSlot({required int slotIndex, int fallbackCurrentHp = 0}) {
    return TeamSlot(
      slotIndex: slotIndex,
      pokemonId: pokemonId,
      experience: experience,
      currentHp: currentHp > 0 ? currentHp : fallbackCurrentHp,
      nickname: nickname,
      selectedMoves: selectedMoves,
      isShiny: isShiny,
      gender: gender,
      formName: formName,
      nature: nature,
      heldItem: heldItem,
      abilities: abilities,
      feats: feats,
      extraSkills: extraSkills,
      statusEffects: statusEffects,
      customAbilityScores: customAbilityScores,
      loyalty: loyalty,
    );
  }

  factory PcPokemon.fromTeamSlot(TeamSlot slot) {
    final pokemonId = slot.pokemonId;
    if (pokemonId == null) {
      throw ArgumentError('Cannot store an empty team slot in the PC.');
    }

    return PcPokemon(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      pokemonId: pokemonId,
      experience: slot.experience,
      currentHp: slot.currentHp,
      nickname: slot.nickname,
      selectedMoves: slot.selectedMoves,
      isShiny: slot.isShiny,
      gender: slot.gender,
      formName: slot.formName,
      nature: slot.nature,
      heldItem: slot.heldItem,
      abilities: slot.abilities,
      feats: slot.feats,
      extraSkills: slot.extraSkills,
      statusEffects: slot.statusEffects,
      customAbilityScores: slot.customAbilityScores,
      loyalty: slot.loyalty,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pokemonId': pokemonId,
      'capturedAt': capturedAt.toIso8601String(),
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
      'notes': notes,
    };
  }

  factory PcPokemon.fromJson(Map<String, dynamic> json) {
    return PcPokemon(
      id:
          json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      pokemonId: _readInt(json['pokemonId']),
      capturedAt:
          DateTime.tryParse(json['capturedAt']?.toString() ?? '') ??
          DateTime.now(),
      experience: _readInt(json['experience']),
      currentHp: _readInt(json['currentHp']),
      nickname: json['nickname'] as String?,
      selectedMoves: List<String>.from(json['selectedMoves'] ?? const []),
      isShiny: json['isShiny'] as bool? ?? false,
      gender: json['gender'] as String?,
      formName: json['formName'] as String?,
      nature: json['nature'] as String? ?? 'No Nature',
      heldItem: json['heldItem'] as String?,
      abilities: List<String>.from(json['abilities'] ?? const []),
      feats: List<String>.from(json['feats'] ?? const []),
      extraSkills: List<String>.from(json['extraSkills'] ?? const []),
      statusEffects: List<String>.from(json['statusEffects'] ?? const []),
      customAbilityScores: Map<String, int>.from(
        json['customAbilityScores'] ?? const {},
      ),
      loyalty: _readInt(json['loyalty']),
      notes: json['notes'] as String? ?? '',
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
