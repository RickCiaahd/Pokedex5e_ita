import 'level_progression.dart';
import 'pokemon.dart';
import 'team_slot.dart';

class PokemonGeneratorFilters {
  const PokemonGeneratorFilters({
    this.query = '',
    this.type,
    this.minSr = 0,
    this.maxSr = 20,
    this.minGeneration = 1,
    this.maxGeneration = 9,
    this.level = 0,
    this.includeForms = true,
    this.shinyChance = 0.01,
  });

  final String query;
  final String? type;
  final double minSr;
  final double maxSr;
  final int minGeneration;
  final int maxGeneration;
  final int level;
  final bool includeForms;
  final double shinyChance;

  PokemonGeneratorFilters copyWith({
    String? query,
    Object? type = _unset,
    double? minSr,
    double? maxSr,
    int? minGeneration,
    int? maxGeneration,
    int? level,
    bool? includeForms,
    double? shinyChance,
  }) {
    return PokemonGeneratorFilters(
      query: query ?? this.query,
      type: identical(type, _unset) ? this.type : type as String?,
      minSr: minSr ?? this.minSr,
      maxSr: maxSr ?? this.maxSr,
      minGeneration: minGeneration ?? this.minGeneration,
      maxGeneration: maxGeneration ?? this.maxGeneration,
      level: level ?? this.level,
      includeForms: includeForms ?? this.includeForms,
      shinyChance: shinyChance ?? this.shinyChance,
    );
  }

  static const Object _unset = Object();
}

class GeneratedPokemon {
  const GeneratedPokemon({
    required this.basePokemon,
    required this.pokemon,
    required this.formName,
    required this.level,
    required this.gender,
    required this.nature,
    required this.ability,
    required this.selectedMoves,
    required this.isShiny,
    required this.maxHp,
  });

  final Pokemon basePokemon;
  final Pokemon pokemon;
  final String? formName;
  final int level;
  final String? gender;
  final String nature;
  final String? ability;
  final List<String> selectedMoves;
  final bool isShiny;
  final int maxHp;

  int get experience => LevelProgression.thresholdForLevel(level);

  String get formLabel => formName ?? 'Base';

  TeamSlot toTeamSlot({required int slotIndex}) {
    return TeamSlot(
      slotIndex: slotIndex,
      pokemonId: basePokemon.id,
      experience: experience,
      currentHp: maxHp,
      selectedMoves: selectedMoves,
      isShiny: isShiny,
      gender: gender,
      formName: formName,
      nature: nature,
      abilities: ability == null ? const [] : [ability!],
    );
  }
}
