import 'dart:math';

import '../models/encounter_collection.dart';
import '../models/generated_encounter.dart';
import '../models/generated_pokemon.dart';
import '../models/pokemon.dart';
import 'pokemon_generator_service.dart';
import 'pokemon_habitat_service.dart';

class EncounterGeneratorService {
  const EncounterGeneratorService({
    PokemonGeneratorService pokemonGeneratorService =
        const PokemonGeneratorService(),
    PokemonHabitatService habitatService = const PokemonHabitatService(),
  }) : _pokemonGeneratorService = pokemonGeneratorService,
       _habitatService = habitatService;

  final PokemonGeneratorService _pokemonGeneratorService;
  final PokemonHabitatService _habitatService;

  List<Pokemon> filterCandidates(
    Iterable<Pokemon> catalog,
    EncounterGeneratorFilters filters,
  ) {
    final pokemonFilters = _pokemonFilters(filters);
    return _pokemonGeneratorService
        .filterPokemon(catalog, pokemonFilters)
        .where(
          (pokemon) =>
              _habitatService.matches(pokemon, filters.habitat) &&
              (filters.allowLegendary ||
                  !_habitatService.isLegendaryOrMythical(pokemon)),
        )
        .toList(growable: false);
  }

  GeneratedEncounter? generateAutomatic({
    required List<Pokemon> catalog,
    required EncounterPartyProfile party,
    required EncounterGeneratorFilters filters,
    required EncounterDifficulty difficulty,
    required EncounterComposition composition,
    int minEnemies = 1,
    int maxEnemies = 6,
    Random? random,
  }) {
    final rng = random ?? Random();
    final candidates = filterCandidates(catalog, filters);
    if (candidates.isEmpty) return null;

    final safeMin = min(minEnemies, maxEnemies).clamp(1, 12);
    final safeMax = max(minEnemies, maxEnemies).clamp(safeMin, 12);
    final targetBudget = partyBudget(party) * difficulty.targetMultiplier;
    final generated = <GeneratedPokemon>[];

    switch (composition) {
      case EncounterComposition.single:
        final selected = _closestCandidate(
          candidates,
          targetBudget,
          filters.level,
        );
        final result = _pokemonGeneratorService.generateForPokemon(
          pokemon: selected,
          filters: _explicitPokemonFilters(filters),
          random: rng,
        );
        if (result != null) generated.add(result);
        break;
      case EncounterComposition.pack:
        final desiredCount = safeMax < 2 ? 1 : max(2, safeMin);
        final selected = _closestCandidate(
          candidates,
          targetBudget / desiredCount,
          filters.level,
        );
        final approximateUnit = _candidateCost(
          selected,
          filters.level <= 0 ? selected.minLevelFound : filters.level,
        );
        final count = (targetBudget / max(0.25, approximateUnit))
            .round()
            .clamp(safeMin, safeMax);
        for (var index = 0; index < count; index++) {
          final result = _pokemonGeneratorService.generateForPokemon(
            pokemon: selected,
            filters: _explicitPokemonFilters(filters),
            random: rng,
          );
          if (result != null) generated.add(result);
        }
        break;
      case EncounterComposition.mixed:
        final shuffled = [...candidates]..shuffle(rng);
        while (generated.length < safeMax) {
          final currentCost = encounterCost(generated);
          final remaining = targetBudget - currentCost;
          if (generated.length >= safeMin && remaining <= 0.15) break;

          final pool = shuffled.where((pokemon) {
            final level = filters.level <= 0
                ? max(1, pokemon.minLevelFound)
                : filters.level;
            final cost = _candidateCost(pokemon, level);
            return generated.length < safeMin || cost <= remaining * 1.35;
          }).toList(growable: false);
          if (pool.isEmpty) break;

          final selected = pool[rng.nextInt(pool.length)];
          final result = _pokemonGeneratorService.generateForPokemon(
            pokemon: selected,
            filters: _explicitPokemonFilters(filters),
            random: rng,
          );
          if (result == null) {
            shuffled.remove(selected);
            if (shuffled.isEmpty) break;
            continue;
          }
          generated.add(result);
          if (generated.length >= safeMin && encounterCost(generated) >= targetBudget) {
            break;
          }
        }
        break;
    }

    if (generated.isEmpty) return null;
    return buildEncounter(
      source: EncounterSource.automatic,
      title: 'Incontro ${composition.label}',
      party: party,
      filters: filters,
      targetDifficulty: difficulty,
      generated: generated,
    );
  }

  GeneratedEncounter? generateManual({
    required List<Pokemon> catalog,
    required Map<int, int> quantities,
    required EncounterPartyProfile party,
    required EncounterGeneratorFilters filters,
    required EncounterDifficulty targetDifficulty,
    Random? random,
  }) {
    final rng = random ?? Random();
    final byId = {for (final pokemon in catalog) pokemon.id: pokemon};
    final generated = <GeneratedPokemon>[];

    for (final entry in quantities.entries) {
      final pokemon = byId[entry.key];
      if (pokemon == null || entry.value <= 0) continue;
      for (var index = 0; index < entry.value.clamp(0, 12); index++) {
        final result = _pokemonGeneratorService.generateForPokemon(
          pokemon: pokemon,
          filters: _explicitPokemonFilters(filters),
          random: rng,
        );
        if (result != null) generated.add(result);
      }
    }

    if (generated.isEmpty) return null;
    return buildEncounter(
      source: EncounterSource.manual,
      title: 'Incontro personalizzato',
      party: party,
      filters: filters,
      targetDifficulty: targetDifficulty,
      generated: generated,
    );
  }

  GeneratedEncounter? generateFromCollection({
    required List<Pokemon> catalog,
    required EncounterCollection collection,
    required int count,
    required bool allowDuplicates,
    required EncounterPartyProfile party,
    required EncounterGeneratorFilters filters,
    required EncounterDifficulty targetDifficulty,
    Random? random,
  }) {
    if (!collection.isReady) return null;
    final rng = random ?? Random();
    final byId = {for (final pokemon in catalog) pokemon.id: pokemon};
    final available = [...collection.entries];
    final generated = <GeneratedPokemon>[];
    final safeCount = allowDuplicates
        ? count.clamp(1, 12)
        : count.clamp(1, min(12, available.length));

    for (var index = 0; index < safeCount; index++) {
      if (available.isEmpty) break;
      final selected = _weightedPick(available, rng);
      final pokemon = byId[selected.pokemonId];
      if (pokemon != null) {
        final result = _pokemonGeneratorService.generateForPokemon(
          pokemon: pokemon,
          filters: _explicitPokemonFilters(filters),
          random: rng,
        );
        if (result != null) generated.add(result);
      }
      if (!allowDuplicates) available.remove(selected);
    }

    if (generated.isEmpty) return null;
    return GeneratedEncounter(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      source: EncounterSource.collection,
      title: collection.name,
      party: party,
      filters: filters,
      targetDifficulty: targetDifficulty,
      members: [for (final pokemon in generated) EncounterMember(pokemon: pokemon)],
      estimate: estimate(
        party: party,
        generated: generated,
        targetDifficulty: targetDifficulty,
      ),
      createdAt: DateTime.now(),
      collectionId: collection.id,
      collectionName: collection.name,
    );
  }

  GeneratedEncounter buildEncounter({
    required EncounterSource source,
    required String title,
    required EncounterPartyProfile party,
    required EncounterGeneratorFilters filters,
    required EncounterDifficulty targetDifficulty,
    required List<GeneratedPokemon> generated,
  }) {
    return GeneratedEncounter(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      source: source,
      title: title,
      party: party,
      filters: filters,
      targetDifficulty: targetDifficulty,
      members: [for (final pokemon in generated) EncounterMember(pokemon: pokemon)],
      estimate: estimate(
        party: party,
        generated: generated,
        targetDifficulty: targetDifficulty,
      ),
      createdAt: DateTime.now(),
    );
  }

  EncounterEstimate estimate({
    required EncounterPartyProfile party,
    required Iterable<GeneratedPokemon> generated,
    required EncounterDifficulty targetDifficulty,
  }) {
    final list = generated.toList(growable: false);
    final budget = partyBudget(party);
    final cost = encounterCost(list);
    final ratio = budget <= 0 ? 0.0 : cost / budget;
    final difficulty = ratio < 0.8
        ? EncounterDifficulty.easy
        : ratio < 1.15
        ? EncounterDifficulty.medium
        : ratio < 1.55
        ? EncounterDifficulty.hard
        : EncounterDifficulty.extreme;
    final warnings = <String>[];

    if (list.length >= party.activePokemon + 3) {
      warnings.add(
        'Il numero elevato di avversari aumenta il vantaggio nelle azioni.',
      );
    }
    if (list.any((pokemon) => pokemon.pokemon.sr > budget * 0.9)) {
      warnings.add(
        'Un singolo avversario ha un SR molto alto rispetto al gruppo.',
      );
    }
    if (list.any((pokemon) => pokemon.level >= party.averageLevel + 5)) {
      warnings.add(
        'Almeno un avversario supera di molto il livello medio degli alleati.',
      );
    }

    return EncounterEstimate(
      partyBudget: budget,
      encounterCost: cost,
      difficulty: difficulty,
      targetDifficulty: targetDifficulty,
      warnings: warnings,
    );
  }

  double partyBudget(EncounterPartyProfile party) {
    final active = party.activePokemon.clamp(1, 12);
    final level = party.averageLevel.clamp(1, 20);
    final trainers = party.trainerCount.clamp(1, 12);
    return max(1.0, active * (0.75 + level * 0.55) + trainers * 0.25);
  }

  double encounterCost(Iterable<GeneratedPokemon> generated) {
    final list = generated.toList(growable: false);
    if (list.isEmpty) return 0;
    final base = list.fold<double>(
      0,
      (total, pokemon) =>
          total + _candidateCost(pokemon.pokemon, pokemon.level),
    );
    final multiplier = switch (list.length) {
      <= 1 => 1.0,
      2 => 1.12,
      3 => 1.25,
      4 => 1.38,
      5 => 1.5,
      _ => 1.65,
    };
    return base * multiplier;
  }

  PokemonGeneratorFilters _pokemonFilters(EncounterGeneratorFilters filters) {
    return PokemonGeneratorFilters(
      type: filters.type,
      minSr: filters.minSr,
      maxSr: filters.maxSr,
      minGeneration: filters.minGeneration,
      maxGeneration: filters.maxGeneration,
      level: filters.level,
      includeForms: filters.includeForms,
      shinyChance: 0.01,
    );
  }

  PokemonGeneratorFilters _explicitPokemonFilters(
    EncounterGeneratorFilters filters,
  ) {
    return PokemonGeneratorFilters(
      minSr: 0,
      maxSr: 100,
      minGeneration: 1,
      maxGeneration: 9,
      level: filters.level,
      includeForms: filters.includeForms,
      shinyChance: 0.01,
    );
  }

  Pokemon _closestCandidate(
    List<Pokemon> candidates,
    double targetCost,
    int requestedLevel,
  ) {
    var best = candidates.first;
    var bestDistance = double.infinity;
    for (final candidate in candidates) {
      final level = requestedLevel <= 0
          ? max(1, candidate.minLevelFound)
          : requestedLevel;
      final distance = (_candidateCost(candidate, level) - targetCost).abs();
      if (distance < bestDistance) {
        best = candidate;
        bestDistance = distance;
      }
    }
    return best;
  }

  double _candidateCost(Pokemon pokemon, int level) {
    final safeLevel = max(1, level);
    final minimumLevel = max(1, pokemon.minLevelFound);
    final gainedLevels = max(0, safeLevel - minimumLevel);
    final levelMultiplier = 1 + gainedLevels * 0.06;
    return max(0.25, pokemon.sr) * levelMultiplier;
  }

  EncounterCollectionEntry _weightedPick(
    List<EncounterCollectionEntry> entries,
    Random random,
  ) {
    final total = entries.fold<int>(0, (sum, entry) => sum + entry.weight);
    var roll = random.nextInt(max(1, total));
    for (final entry in entries) {
      if (roll < entry.weight) return entry;
      roll -= entry.weight;
    }
    return entries.last;
  }
}
