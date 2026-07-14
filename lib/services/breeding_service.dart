import 'dart:math';

import '../models/breeding_candidate.dart';
import '../models/breeding_egg.dart';
import '../models/breeding_species_data.dart';
import '../models/generated_pokemon.dart';
import '../models/pokemon.dart';
import '../models/pokemon_nature.dart';
import '../models/team_slot.dart';
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

  bool hasGoodGenes(UserProfile profile) {
    return TrainerPathPassiveService.hasFeature(
      profile,
      trainerPath: 'Pokémon Breeder',
      level: 9,
    );
  }

  bool hasMasterOfTraits(UserProfile profile) {
    return TrainerPathPassiveService.hasFeature(
      profile,
      trainerPath: 'Pokémon Breeder',
      level: 15,
    );
  }

  List<String> availableGenders(Pokemon pokemon) {
    final formGenders = pokemon.formDefinitions
        .map((definition) => definition.gender?.trim())
        .whereType<String>()
        .where((gender) => gender.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (formGenders.isNotEmpty) return formGenders..sort();

    final ratio = pokemon.genderRatio?.trim().toLowerCase() ?? '';
    if (ratio.contains('genderless') ||
        ratio.contains('senza sesso') ||
        ratio == 'none') {
      return const ['Genderless'];
    }
    if (ratio.contains('female only') || ratio.contains('100% female')) {
      return const ['Female'];
    }
    if (ratio.contains('male only') || ratio.contains('100% male')) {
      return const ['Male'];
    }
    return const ['Male', 'Female'];
  }

  List<String> availableAbilities(Pokemon pokemon) {
    final seen = <String>{};
    final result = <String>[];
    for (final ability in pokemon.abilities) {
      final trimmed = ability.trim();
      if (trimmed.isEmpty) continue;
      if (seen.add(trimmed.toLowerCase())) result.add(trimmed);
    }
    return result;
  }

  List<String> inheritedEggMoves({
    required Pokemon child,
    required BreedingCandidate first,
    required BreedingCandidate second,
  }) {
    return _inheritedEggMoves(child: child, first: first, second: second);
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
    String? selectedGender,
    String? selectedNature,
    String? selectedAbility,
    List<String> replacementEggMoves = const [],
    bool masterOfTraitsApplied = false,
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
    final formPokemon = basePokemon.resolveVariant(
      formName: compatibility.childFormName,
    );
    final level = max(1, formPokemon.minLevelFound);
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

    final genderOptions = availableGenders(formPokemon);
    final gender =
        selectedGender != null && genderOptions.contains(selectedGender)
        ? selectedGender
        : generated.gender;
    final resolved = basePokemon.resolveVariant(
      formName: compatibility.childFormName,
      gender: gender,
    );
    final nature =
        selectedNature != null &&
            selectedNature != 'No Nature' &&
            PokemonNature.names.contains(selectedNature)
        ? selectedNature
        : generated.nature;

    final inheritedEggMoves = _inheritedEggMoves(
      child: resolved,
      first: first,
      second: second,
    );
    final inheritedNaturalMoves = _inheritedNaturalMoves(
      child: resolved,
      first: first,
      second: second,
    );
    final replacementMoves = <String>[];
    for (final requested in replacementEggMoves) {
      final matching = _matchingMove(resolved.moves.eggMoves, requested);
      if (matching == null ||
          replacementMoves.any(
            (move) => _moveKey(move) == _moveKey(matching),
          )) {
        continue;
      }
      if (replacementMoves.length >= inheritedEggMoves.length) break;
      replacementMoves.add(matching);
    }
    final finalEggMoves = [...replacementMoves];
    for (final inherited in inheritedEggMoves) {
      if (finalEggMoves.length >= inheritedEggMoves.length) break;
      if (finalEggMoves.any((move) => _moveKey(move) == _moveKey(inherited))) {
        continue;
      }
      finalEggMoves.add(inherited);
    }
    final inheritedMoves = _uniqueMoves([
      ...finalEggMoves,
      ...inheritedNaturalMoves,
    ]);
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

    var ability = _randomNormalAbility(resolved, rng);
    final female = first.isFemale
        ? first
        : second.isFemale
        ? second
        : null;
    if (female != null && female.abilities.isNotEmpty && rng.nextBool()) {
      final inherited = female.abilities.first.trim();
      if (inherited.isNotEmpty &&
          availableAbilities(resolved).contains(inherited)) {
        ability = inherited;
      }
    }
    final abilities = availableAbilities(resolved);
    if (selectedAbility != null && abilities.contains(selectedAbility)) {
      ability = selectedAbility;
    }

    final knownMoves = masterOfTraitsApplied
        ? _uniqueMoves([
            ...finalEggMoves,
            ...inheritedNaturalMoves,
            ...resolved.moves.startingMoves,
          ])
        : startingPool;
    final hatchTime = hatchTimeForSr(resolved.sr);
    return BreedingEgg(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      speciesId: speciesId,
      formName: compatibility.childFormName,
      parentNames: [first.displayName, second.displayName],
      createdAt: DateTime.now(),
      hatchTime: hatchTime,
      incubationRemaining: hatchTime,
      nature: nature,
      gender: gender,
      ability: ability,
      selectedMoves: knownMoves.take(4).toList(growable: false),
      inheritedMoves: inheritedMoves,
      isShiny: false,
      masterOfTraitsApplied: masterOfTraitsApplied,
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

  TeamSlot? firstFreeUnlockedTeamSlot({
    required List<TeamSlot> team,
    required int unlockedPokeslots,
  }) {
    if (unlockedPokeslots <= 0) return null;
    final ordered = [...team]
      ..sort((first, second) => first.slotIndex.compareTo(second.slotIndex));
    for (final slot in ordered) {
      if (slot.slotIndex >= unlockedPokeslots) continue;
      if (slot.isEmpty) return slot;
    }
    return null;
  }

  TeamSlot? teamSlotForEgg({
    required List<TeamSlot> team,
    required String eggId,
  }) {
    for (final slot in team) {
      if (slot.eggId == eggId) return slot;
    }
    return null;
  }

  List<TeamSlot> occupiedLockedTeamSlots({
    required List<TeamSlot> team,
    required int unlockedPokeslots,
  }) {
    return [
      for (final slot in team)
        if (slot.slotIndex >= unlockedPokeslots && slot.pokemonId != null) slot,
    ]..sort((first, second) => first.slotIndex.compareTo(second.slotIndex));
  }

  List<String> _inheritedEggMoves({
    required Pokemon child,
    required BreedingCandidate first,
    required BreedingCandidate second,
  }) {
    final eitherParent = <String>{
      ..._moveKeys(first.selectedMoves),
      ..._moveKeys(second.selectedMoves),
    };
    return [
      for (final move in child.moves.eggMoves)
        if (eitherParent.contains(_moveKey(move))) move,
    ];
  }

  List<String> _inheritedNaturalMoves({
    required Pokemon child,
    required BreedingCandidate first,
    required BreedingCandidate second,
  }) {
    final bothParents = _moveKeys(
      first.selectedMoves,
    ).intersection(_moveKeys(second.selectedMoves));
    final naturalMoves = <String>[
      ...child.moves.startingMoves,
      for (final entry in child.moves.levelMoves.entries) ...entry.value,
    ];
    return _uniqueMoves([
      for (final move in naturalMoves)
        if (bothParents.contains(_moveKey(move))) move,
    ]);
  }

  List<String> _uniqueMoves(Iterable<String> moves) {
    final result = <String>[];
    final seen = <String>{};
    for (final move in moves) {
      if (seen.add(_moveKey(move))) result.add(move);
    }
    return result;
  }

  String? _matchingMove(Iterable<String> moves, String requested) {
    final key = _moveKey(requested);
    for (final move in moves) {
      if (_moveKey(move) == key) return move;
    }
    return null;
  }

  String? _randomNormalAbility(Pokemon pokemon, Random random) {
    final abilities = availableAbilities(pokemon);
    if (abilities.isEmpty) return null;
    return abilities[random.nextInt(abilities.length)];
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
