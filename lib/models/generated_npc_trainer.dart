import 'generated_pokemon.dart';

enum NpcTrainerRank { common, expert, elite, boss }

extension NpcTrainerRankLabel on NpcTrainerRank {
  String get label => switch (this) {
    NpcTrainerRank.common => 'Comune',
    NpcTrainerRank.expert => 'Esperto',
    NpcTrainerRank.elite => 'Élite',
    NpcTrainerRank.boss => 'Boss',
  };

  String get englishLabel => switch (this) {
    NpcTrainerRank.common => 'Common',
    NpcTrainerRank.expert => 'Expert',
    NpcTrainerRank.elite => 'Elite',
    NpcTrainerRank.boss => 'Boss',
  };

  String get description => switch (this) {
    NpcTrainerRank.common =>
      'Un allenatore ordinario, adatto a incontri rapidi o introduttivi.',
    NpcTrainerRank.expert =>
      'Una sfida preparata, con una squadra più selezionata e tattiche precise.',
    NpcTrainerRank.elite =>
      'Un avversario importante, con Pokémon forti e ricompense migliori.',
    NpcTrainerRank.boss =>
      'Un rivale, Capopalestra o antagonista pensato come scontro principale.',
  };

  String get englishDescription => switch (this) {
    NpcTrainerRank.common =>
      'An ordinary Trainer suited to quick or introductory encounters.',
    NpcTrainerRank.expert =>
      'A prepared challenge with a more selective team and precise tactics.',
    NpcTrainerRank.elite =>
      'An important opponent with strong Pokémon and better rewards.',
    NpcTrainerRank.boss =>
      'A rival, Gym Leader or antagonist designed as a major battle.',
  };

  double get rewardMultiplier => switch (this) {
    NpcTrainerRank.common => 1,
    NpcTrainerRank.expert => 1.5,
    NpcTrainerRank.elite => 2.25,
    NpcTrainerRank.boss => 3.25,
  };

  int get srBonus => switch (this) {
    NpcTrainerRank.common => 0,
    NpcTrainerRank.expert => 1,
    NpcTrainerRank.elite => 2,
    NpcTrainerRank.boss => 4,
  };
}

enum NpcTeamComposition { themed, mixed, varied }

extension NpcTeamCompositionLabel on NpcTeamComposition {
  String get label => switch (this) {
    NpcTeamComposition.themed => 'Tematica',
    NpcTeamComposition.mixed => 'Mista',
    NpcTeamComposition.varied => 'Variegata',
  };

  String get englishLabel => switch (this) {
    NpcTeamComposition.themed => 'Themed',
    NpcTeamComposition.mixed => 'Mixed',
    NpcTeamComposition.varied => 'Varied',
  };

  String get description => switch (this) {
    NpcTeamComposition.themed =>
      'Tutti i Pokémon condividono il tipo della specializzazione.',
    NpcTeamComposition.mixed =>
      'La maggioranza segue il tema, con alcune coperture differenti.',
    NpcTeamComposition.varied =>
      'La squadra privilegia varietà di specie e tipi.',
  };

  String get englishDescription => switch (this) {
    NpcTeamComposition.themed =>
      'Every Pokémon shares the specialization type.',
    NpcTeamComposition.mixed =>
      'Most of the team follows the theme, with a few different coverage options.',
    NpcTeamComposition.varied =>
      'The team favors a variety of species and types.',
  };
}

class NpcTrainerGeneratorOptions {
  const NpcTrainerGeneratorOptions({
    this.trainerLevel = 5,
    this.pokemonLevel = 5,
    this.teamSize = 3,
    this.rank = NpcTrainerRank.common,
    this.specialization,
    this.composition = NpcTeamComposition.mixed,
    this.minGeneration = 1,
    this.maxGeneration = 9,
    this.includeForms = true,
    this.allowLegendary = false,
    this.allowDuplicates = false,
  });

  final int trainerLevel;
  final int pokemonLevel;
  final int teamSize;
  final NpcTrainerRank rank;
  final String? specialization;
  final NpcTeamComposition composition;
  final int minGeneration;
  final int maxGeneration;
  final bool includeForms;
  final bool allowLegendary;
  final bool allowDuplicates;

  NpcTrainerGeneratorOptions copyWith({
    int? trainerLevel,
    int? pokemonLevel,
    int? teamSize,
    NpcTrainerRank? rank,
    Object? specialization = _unset,
    NpcTeamComposition? composition,
    int? minGeneration,
    int? maxGeneration,
    bool? includeForms,
    bool? allowLegendary,
    bool? allowDuplicates,
  }) {
    return NpcTrainerGeneratorOptions(
      trainerLevel: trainerLevel ?? this.trainerLevel,
      pokemonLevel: pokemonLevel ?? this.pokemonLevel,
      teamSize: teamSize ?? this.teamSize,
      rank: rank ?? this.rank,
      specialization: identical(specialization, _unset)
          ? this.specialization
          : specialization as String?,
      composition: composition ?? this.composition,
      minGeneration: minGeneration ?? this.minGeneration,
      maxGeneration: maxGeneration ?? this.maxGeneration,
      includeForms: includeForms ?? this.includeForms,
      allowLegendary: allowLegendary ?? this.allowLegendary,
      allowDuplicates: allowDuplicates ?? this.allowDuplicates,
    );
  }

  static const Object _unset = Object();
}

class GeneratedNpcTrainer {
  const GeneratedNpcTrainer({
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
    required this.generatedAt,
  });

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
  final List<GeneratedPokemon> team;
  final NpcTrainerGeneratorOptions options;
  final DateTime generatedAt;

  String get displayName => '$name, $epithet';
}
