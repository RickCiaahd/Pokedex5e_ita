import 'dart:math';

import '../models/breeding_candidate.dart';
import '../models/breeding_egg.dart';
import '../models/breeding_species_data.dart';
import '../models/generated_pokemon.dart';
import '../models/pokemon.dart';
import '../models/user_profile.dart';
import 'pokemon_generator_service.dart';
import 'trainer_path_passive_service.dart';

class BreedingCompatibility {
  const BreedingCompatibility({
    required this.errors,
    required this.sharedEggGroups,
    this.childSpeciesId,
    this.childFormName,
  });

  final List<String> errors;
  final List<String> sharedEggGroups;
  final int? childSpeciesId;
  final String? childFormName;

  bool get isCompatible => errors.isEmpty && childSpeciesId != null;
}

class IncubationProgressResult {
  const IncubationProgressResult({
    required this.egg,
    required this.d100Rolls,
    required this.incubatorRolls,
    required this.reduction,
  });

  final BreedingEgg egg;
  final List<int> d100Rolls;
  final List<int> incubatorRolls;
  final int reduction;
}

class BreedingService {
  const BreedingService({PokemonGeneratorService? generator})
    : _generator = generator ?? const PokemonGeneratorService();

  final PokemonGeneratorService _generator;

  BreedingCompatibility compatibility({
    required BreedingCandidate first,
    required BreedingCandidate second,
    required Map<int, BreedingSpeciesData> speciesData,
    required Map<int, Pokemon> catalog,
  }) {
    final errors = <String>[];
    final firstData = speciesData[first.pokemonId];
    final secondData = speciesData[second.pokemonId];

    if (first.key == second.key) {
      errors.add('Seleziona due Pokémon diversi.');
    }
    if (first.loyalty < 2 || second.loyalty < 2) {
      errors.add('Entrambi i Pokémon devono avere Lealtà almeno +2.');
    }
    if (firstData == null || secondData == null) {
      errors.add(
        'I dati dei Gruppi Uova non sono disponibili per uno dei genitori.',
      );
      return BreedingCompatibility(errors: errors, sharedEggGroups: const []);
    }
    if (firstData.isUndiscovered || secondData.isUndiscovered) {
      errors.add('I Pokémon del gruppo Undiscovered non possono riprodursi.');
    }
    if (firstData.isDitto && secondData.isDitto) {
      errors.add('Due Ditto non possono produrre un uovo.');
    }

    final hasDitto = firstData.isDitto || secondData.isDitto;
    if (!hasDitto) {
      final oppositeGender =
          (first.isMale && second.isFemale) ||
          (first.isFemale && second.isMale);
      if (!oppositeGender) {
        errors.add('Senza Ditto servono un Pokémon maschio e uno femmina.');
      }
    }

    final shared =
        firstData.eggGroups
            .where(
              (group) =>
                  group != 'Undiscovered' &&
                  group != 'Ditto' &&
                  secondData.eggGroups.contains(group),
            )
            .toSet()
            .toList()
          ..sort();
    if (!hasDitto && shared.isEmpty) {
      errors.add('I due Pokémon non condividono alcun Gruppo Uova.');
    }

    final source = firstData.isDitto
        ? second
        : secondData.isDitto
        ? first
        : first.isFemale
        ? first
        : second;
    final sourceData = speciesData[source.pokemonId];
    final childSpeciesId = sourceData?.baseSpeciesId;
    String? childFormName;
    if (childSpeciesId != null && source.formName != null) {
      final child = catalog[childSpeciesId];
      final requested = source.formName!.trim().toLowerCase();
      final supportsForm =
          child?.formDefinitions.any(
            (definition) =>
                definition.displayName.trim().toLowerCase() == requested ||
                definition.key.trim().toLowerCase() == requested,
          ) ??
          false;
      if (supportsForm) childFormName = source.formName;
    }

    return BreedingCompatibility(
      errors: errors,
      sharedEggGroups: hasDitto ? const ['Ditto'] : shared,
      childSpeciesId: childSpeciesId,
      childFormName: childFormName,
    );
  }

  int successDc(int totalLoyalty) {
    return (23 - totalLoyalty.clamp(4, 6)).clamp(17, 19).toInt();
  }

  int breedingRollModifier(UserProfile profile) {
    if (!TrainerPathPassiveService.hasFeature(
      profile,
      trainerPath: 'Pokémon Breeder',
      level: 2,
    )) {
      return 0;
    }
    final wisdom = profile.abilityScores['WIS'] ?? 10;
    return ((wisdom - 10) / 2).floor();
  }

  bool hasIncubationAdvantage(UserProfile profile) {
    return TrainerPathPassiveService.hasFeature(
      profile,
      trainerPath: 'Pokémon Breeder',
      level: 5,
    );
  }

  int hatchTimeForSr(double sr) {
    if (sr <= 0.125) return 125;
    if (sr <= 0.25) return 250;
    if (sr <= 0.5) return 500;
    final rank = sr.ceil().clamp(1, 15).toInt();
    return 500 + rank * 100;
  }

  BreedingEgg createEgg({
    required BreedingCandidate first,
    required BreedingCandidate second,
    required BreedingCompatibility compatibility,
    required Map<int, Pokemon> catalog,
    Random? random,
  }) {
    if (!compatibility.isCompatible) {
      throw StateError('I genitori selezionati non sono compatibili.');
    }
    final rng = random ?? Random();
    final speciesId = compatibility.childSpeciesId!;
    final basePokemon = catalog[speciesId];
    if (basePokemon == null) {
      throw StateError('La specie risultante non è presente nel catalogo.');
    }
    final resolved = basePokemon.resolveVariant(
      formName: compatibility.childFormName,
    );
    final level = max(1, resolved.minLevelFound);
    final generated = _generator.generateForPokemonForm(
      pokemon: basePokemon,
      formName: compatibility.childFormName,
      filters: PokemonGeneratorFilters(
        minSr: 0,
        maxSr: 100,
        minGeneration: 1,
        maxGeneration: 9,
        level: level,
        includeForms: true,
        shinyChance: 0,
      ),
      random: rng,
    );
    if (generated == null) {
      throw StateError('Impossibile generare il contenuto dell’uovo.');
    }

    final inheritedMoves = _inheritedMoves(
      child: resolved,
      first: first,
      second: second,
    );
    final startingPool = <String>[];
    final seen = <String>{};
    void addMove(String value) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return;
      final key = _moveKey(trimmed);
      if (seen.add(key)) startingPool.add(trimmed);
    }

    for (final move in resolved.moves.startingMoves) {
      addMove(move);
    }
    for (final move in inheritedMoves) {
      addMove(move);
    }

    var ability = generated.ability;
    final female = first.isFemale
        ? first
        : second.isFemale
        ? second
        : null;
    if (female != null && female.abilities.isNotEmpty && rng.nextBool()) {
      final inherited = female.abilities.first.trim();
      if (inherited.isNotEmpty && resolved.abilities.contains(inherited)) {
        ability = inherited;
      }
    }

    final hatchTime = hatchTimeForSr(resolved.sr);
    return BreedingEgg(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      speciesId: speciesId,
      formName: compatibility.childFormName,
      parentNames: [first.displayName, second.displayName],
      createdAt: DateTime.now(),
      hatchTime: hatchTime,
      incubationRemaining: hatchTime,
      nature: generated.nature,
      gender: generated.gender,
      ability: ability,
      selectedMoves: startingPool.take(4).toList(growable: false),
      inheritedMoves: inheritedMoves,
      isShiny: false,
    );
  }

  IncubationProgressResult advanceIncubation({
    required BreedingEgg egg,
    required UserProfile profile,
    Random? random,
  }) {
    final rng = random ?? Random();
    final d100Rolls = <int>[rng.nextInt(100) + 1];
    if (hasIncubationAdvantage(profile)) {
      d100Rolls.add(rng.nextInt(100) + 1);
    }
    final incubatorRolls = <int>[
      for (var index = 0; index < egg.incubator.extraD20; index++)
        rng.nextInt(20) + 1,
    ];
    final base = d100Rolls.reduce(
      (first, second) => first >= second ? first : second,
    );
    final reduction =
        base + incubatorRolls.fold<int>(0, (sum, value) => sum + value);
    return IncubationProgressResult(
      egg: egg.copyWith(
        incubationRemaining: (egg.incubationRemaining - reduction)
            .clamp(0, egg.hatchTime)
            .toInt(),
      ),
      d100Rolls: d100Rolls,
      incubatorRolls: incubatorRolls,
      reduction: reduction,
    );
  }

  List<String> _inheritedMoves({
    required Pokemon child,
    required BreedingCandidate first,
    required BreedingCandidate second,
  }) {
    final firstMoves = _moveKeys(first.selectedMoves);
    final secondMoves = _moveKeys(second.selectedMoves);
    final eitherParent = <String>{...firstMoves, ...secondMoves};
    final bothParents = firstMoves.intersection(secondMoves);
    final result = <String>[];
    final seen = <String>{};

    void add(String move) {
      if (seen.add(_moveKey(move))) result.add(move);
    }

    for (final move in child.moves.eggMoves) {
      if (eitherParent.contains(_moveKey(move))) add(move);
    }
    final naturalMoves = <String>[
      ...child.moves.startingMoves,
      for (final entry in child.moves.levelMoves.entries) ...entry.value,
    ];
    for (final move in naturalMoves) {
      if (bothParents.contains(_moveKey(move))) add(move);
    }
    return result;
  }

  Set<String> _moveKeys(Iterable<String> moves) {
    return moves.map(_moveKey).where((key) => key.isNotEmpty).toSet();
  }

  String _moveKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r"[’']"), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }
}
