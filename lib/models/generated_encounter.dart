import 'generated_pokemon.dart';

const Object _encounterUnset = Object();

enum EncounterDifficulty { easy, medium, hard, extreme }

enum EncounterComposition { single, pack, mixed }

enum EncounterSource { automatic, manual, collection }

extension EncounterDifficultyLabel on EncounterDifficulty {
  String get label => switch (this) {
    EncounterDifficulty.easy => 'Facile',
    EncounterDifficulty.medium => 'Media',
    EncounterDifficulty.hard => 'Difficile',
    EncounterDifficulty.extreme => 'Estrema',
  };

  String get englishLabel => switch (this) {
    EncounterDifficulty.easy => 'Easy',
    EncounterDifficulty.medium => 'Medium',
    EncounterDifficulty.hard => 'Hard',
    EncounterDifficulty.extreme => 'Extreme',
  };

  double get targetMultiplier => switch (this) {
    EncounterDifficulty.easy => 0.65,
    EncounterDifficulty.medium => 1.0,
    EncounterDifficulty.hard => 1.35,
    EncounterDifficulty.extreme => 1.75,
  };
}

extension EncounterCompositionLabel on EncounterComposition {
  String get label => switch (this) {
    EncounterComposition.single => 'Singolo potente',
    EncounterComposition.pack => 'Branco',
    EncounterComposition.mixed => 'Gruppo misto',
  };

  String get englishLabel => switch (this) {
    EncounterComposition.single => 'Powerful solo',
    EncounterComposition.pack => 'Pack',
    EncounterComposition.mixed => 'Mixed group',
  };
}

class EncounterPartyProfile {
  const EncounterPartyProfile({
    this.trainerCount = 1,
    this.activePokemon = 1,
    this.averageLevel = 5,
  });

  final int trainerCount;
  final int activePokemon;
  final int averageLevel;

  EncounterPartyProfile copyWith({
    int? trainerCount,
    int? activePokemon,
    int? averageLevel,
  }) {
    return EncounterPartyProfile(
      trainerCount: trainerCount ?? this.trainerCount,
      activePokemon: activePokemon ?? this.activePokemon,
      averageLevel: averageLevel ?? this.averageLevel,
    );
  }
}

class EncounterGeneratorFilters {
  const EncounterGeneratorFilters({
    this.habitat = 'Qualsiasi',
    this.type,
    this.minSr = 0,
    this.maxSr = 20,
    this.minGeneration = 1,
    this.maxGeneration = 9,
    this.level = 0,
    this.includeForms = true,
    this.allowLegendary = false,
  });

  final String habitat;
  final String? type;
  final double minSr;
  final double maxSr;
  final int minGeneration;
  final int maxGeneration;
  final int level;
  final bool includeForms;
  final bool allowLegendary;

  EncounterGeneratorFilters copyWith({
    String? habitat,
    Object? type = _encounterUnset,
    double? minSr,
    double? maxSr,
    int? minGeneration,
    int? maxGeneration,
    int? level,
    bool? includeForms,
    bool? allowLegendary,
  }) {
    return EncounterGeneratorFilters(
      habitat: habitat ?? this.habitat,
      type: identical(type, _encounterUnset) ? this.type : type as String?,
      minSr: minSr ?? this.minSr,
      maxSr: maxSr ?? this.maxSr,
      minGeneration: minGeneration ?? this.minGeneration,
      maxGeneration: maxGeneration ?? this.maxGeneration,
      level: level ?? this.level,
      includeForms: includeForms ?? this.includeForms,
      allowLegendary: allowLegendary ?? this.allowLegendary,
    );
  }
}

class EncounterManualSelection {
  const EncounterManualSelection({
    required this.pokemonId,
    required this.quantity,
    this.formName,
  });

  final int pokemonId;
  final int quantity;
  final String? formName;
}

class EncounterMember {
  const EncounterMember({required this.pokemon, this.isLocked = false});

  final GeneratedPokemon pokemon;
  final bool isLocked;

  EncounterMember copyWith({GeneratedPokemon? pokemon, bool? isLocked}) {
    return EncounterMember(
      pokemon: pokemon ?? this.pokemon,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}

class EncounterEstimate {
  const EncounterEstimate({
    required this.partyBudget,
    required this.encounterCost,
    required this.difficulty,
    required this.targetDifficulty,
    this.warnings = const [],
  });

  final double partyBudget;
  final double encounterCost;
  final EncounterDifficulty difficulty;
  final EncounterDifficulty targetDifficulty;
  final List<String> warnings;

  double get targetBudget => partyBudget * targetDifficulty.targetMultiplier;
}

class GeneratedEncounter {
  const GeneratedEncounter({
    required this.id,
    required this.source,
    required this.title,
    required this.party,
    required this.filters,
    required this.targetDifficulty,
    required this.members,
    required this.estimate,
    required this.createdAt,
    this.collectionId,
    this.collectionName,
  });

  final String id;
  final EncounterSource source;
  final String title;
  final EncounterPartyProfile party;
  final EncounterGeneratorFilters filters;
  final EncounterDifficulty targetDifficulty;
  final List<EncounterMember> members;
  final EncounterEstimate estimate;
  final DateTime createdAt;
  final String? collectionId;
  final String? collectionName;

  GeneratedEncounter copyWith({
    String? title,
    List<EncounterMember>? members,
    EncounterEstimate? estimate,
  }) {
    return GeneratedEncounter(
      id: id,
      source: source,
      title: title ?? this.title,
      party: party,
      filters: filters,
      targetDifficulty: targetDifficulty,
      members: members ?? this.members,
      estimate: estimate ?? this.estimate,
      createdAt: createdAt,
      collectionId: collectionId,
      collectionName: collectionName,
    );
  }
}
