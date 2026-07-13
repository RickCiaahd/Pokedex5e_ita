import 'dart:math';

import '../models/generated_pokemon.dart';
import '../models/level_progression.dart';
import '../models/pokedex_entry.dart';
import '../models/pokemon.dart';
import '../models/pokemon_nature.dart';
import '../models/pokemon_type_localization.dart';

class PokemonGeneratorService {
  const PokemonGeneratorService();

  List<Pokemon> filterPokemon(
    Iterable<Pokemon> pokemon,
    PokemonGeneratorFilters filters,
  ) {
    final query = filters.query.trim().toLowerCase();
    final minimumGeneration = min(filters.minGeneration, filters.maxGeneration);
    final maximumGeneration = max(filters.minGeneration, filters.maxGeneration);

    return pokemon
        .where((candidate) {
          if (candidate.id <= 0 || candidate.name.trim().isEmpty) return false;
          final generation = generationForPokemonId(candidate.id);
          if (generation < minimumGeneration ||
              generation > maximumGeneration) {
            return false;
          }

          final eligibleForms = eligibleFormNames(candidate, filters);
          if (eligibleForms.isEmpty) return false;
          if (query.isEmpty) return true;
          if (candidate.name.toLowerCase().contains(query) ||
              candidate.id.toString().contains(query)) {
            return true;
          }

          for (final formName in eligibleForms) {
            if (formName?.toLowerCase().contains(query) == true) return true;
            final variant = candidate.resolveVariant(formName: formName);
            if (variant.types.any((type) {
              return type.toLowerCase().contains(query) ||
                  PokemonTypeLocalization.italianLabel(
                    type,
                  ).toLowerCase().contains(query);
            })) {
              return true;
            }
          }
          return false;
        })
        .toList(growable: false)
      ..sort((a, b) => a.id.compareTo(b.id));
  }

  List<String?> eligibleFormNames(
    Pokemon pokemon,
    PokemonGeneratorFilters filters,
  ) {
    final forms = <String?>[null];
    final identities = <String>{'base'};

    if (filters.includeForms) {
      for (final definition in pokemon.formDefinitions) {
        if (definition.gender != null) continue;
        if (!PokedexEntry.isTrackableForm(
          definition.displayName,
          speciesName: pokemon.name,
        )) {
          continue;
        }
        final identity = PokedexEntry.formKey(
          definition.displayName,
          speciesName: pokemon.name,
        );
        if (identity == 'base' || !identities.add(identity)) continue;
        forms.add(definition.displayName);
      }
    }

    return forms
        .where((formName) {
          final variant = pokemon.resolveVariant(formName: formName);
          return _matchesVariantFilters(variant, filters);
        })
        .toList(growable: false);
  }

  GeneratedPokemon? generate({
    required Iterable<Pokemon> pokemon,
    required PokemonGeneratorFilters filters,
    Random? random,
  }) {
    final rng = random ?? Random();
    final candidates = filterPokemon(pokemon, filters);
    if (candidates.isEmpty) return null;

    final basePokemon = candidates[rng.nextInt(candidates.length)];
    return _generateCandidate(basePokemon, filters, rng);
  }

  GeneratedPokemon? generateForPokemon({
    required Pokemon pokemon,
    required PokemonGeneratorFilters filters,
    Random? random,
  }) {
    if (filterPokemon([pokemon], filters).isEmpty) return null;
    return _generateCandidate(pokemon, filters, random ?? Random());
  }

  GeneratedPokemon? generateForPokemonForm({
    required Pokemon pokemon,
    required String? formName,
    required PokemonGeneratorFilters filters,
    Random? random,
  }) {
    final requestedKey = PokedexEntry.formKey(
      formName,
      speciesName: pokemon.name,
    );
    String? matchedForm;
    var found = false;
    for (final eligibleForm in eligibleFormNames(pokemon, filters)) {
      final eligibleKey = PokedexEntry.formKey(
        eligibleForm,
        speciesName: pokemon.name,
      );
      if (eligibleKey != requestedKey) continue;
      matchedForm = eligibleForm;
      found = true;
      break;
    }
    if (!found) return null;

    return _generateCandidate(
      pokemon,
      filters,
      random ?? Random(),
      forceForm: true,
      forcedFormName: matchedForm,
    );
  }

  List<GeneratedPokemon> generateSelected({
    required Iterable<Pokemon> pokemon,
    required PokemonGeneratorFilters filters,
    Random? random,
  }) {
    final rng = random ?? Random();
    final generated = <GeneratedPokemon>[];
    for (final candidate in pokemon) {
      final result = generateForPokemon(
        pokemon: candidate,
        filters: filters,
        random: rng,
      );
      if (result != null) generated.add(result);
    }
    return generated;
  }

  GeneratedPokemon? _generateCandidate(
    Pokemon basePokemon,
    PokemonGeneratorFilters filters,
    Random random, {
    bool forceForm = false,
    String? forcedFormName,
  }) {
    final eligibleForms = eligibleFormNames(basePokemon, filters);
    if (eligibleForms.isEmpty) return null;
    final formName = forceForm
        ? forcedFormName
        : eligibleForms[random.nextInt(eligibleForms.length)];
    final formPokemon = basePokemon.resolveVariant(formName: formName);
    var gender = _randomGender(formPokemon, random);
    var resolvedPokemon = basePokemon.resolveVariant(
      formName: formName,
      gender: gender,
    );
    if (!_matchesVariantFilters(resolvedPokemon, filters)) {
      gender = null;
      resolvedPokemon = formPokemon;
    }

    final level = _resolveLevel(resolvedPokemon, filters.level);
    final nature = _randomNature(random);
    final ability = _randomAbility(resolvedPokemon, random);
    final selectedMoves = _randomMoves(resolvedPokemon, level, random);
    final shinyChance = filters.shinyChance.clamp(0.0, 1.0).toDouble();
    final isShiny = random.nextDouble() < shinyChance;

    return GeneratedPokemon(
      basePokemon: basePokemon,
      pokemon: resolvedPokemon,
      formName: formName,
      level: level,
      gender: gender,
      nature: nature,
      ability: ability,
      selectedMoves: selectedMoves,
      isShiny: isShiny,
      maxHp: maxHpFor(pokemon: resolvedPokemon, level: level, nature: nature),
    );
  }

  List<String> availableTypes(Iterable<Pokemon> pokemon) {
    final typesByKey = <String, String>{};

    void addTypes(Iterable<String> types) {
      for (final type in types) {
        if (type.trim().isEmpty) continue;
        final key = PokemonTypeLocalization.canonicalKey(type);
        typesByKey.putIfAbsent(
          key,
          () => PokemonTypeLocalization.englishValue(type),
        );
      }
    }

    for (final candidate in pokemon) {
      addTypes(candidate.types);
      for (final definition in candidate.formDefinitions) {
        if (definition.gender == null &&
            !PokedexEntry.isTrackableForm(
              definition.displayName,
              speciesName: candidate.name,
            )) {
          continue;
        }
        addTypes(definition.pokemon.types);
      }
    }

    return typesByKey.values.toList(growable: false)
      ..sort(PokemonTypeLocalization.compareByItalianLabel);
  }

  double maximumSr(Iterable<Pokemon> pokemon) {
    var maximum = 1.0;
    for (final candidate in pokemon) {
      maximum = max(maximum, candidate.sr);
      for (final definition in candidate.formDefinitions) {
        if (definition.gender == null &&
            !PokedexEntry.isTrackableForm(
              definition.displayName,
              speciesName: candidate.name,
            )) {
          continue;
        }
        maximum = max(maximum, definition.pokemon.sr);
      }
    }
    return maximum.ceilToDouble();
  }

  int generationForPokemonId(int pokemonId) {
    if (pokemonId <= 151) return 1;
    if (pokemonId <= 251) return 2;
    if (pokemonId <= 386) return 3;
    if (pokemonId <= 493) return 4;
    if (pokemonId <= 649) return 5;
    if (pokemonId <= 721) return 6;
    if (pokemonId <= 809) return 7;
    if (pokemonId <= 905) return 8;
    return 9;
  }

  int maxHpFor({
    required Pokemon pokemon,
    required int level,
    required String nature,
  }) {
    final safeLevel = level.clamp(1, LevelProgression.maxLevel).toInt();
    final minimumLevel = pokemon.minLevelFound <= 0 ? 1 : pokemon.minLevelFound;
    final levelsGained = (safeLevel - minimumLevel)
        .clamp(0, LevelProgression.maxLevel)
        .toInt();
    final hitDieAverage = ((pokemon.hitDice + 1) / 2).ceil();
    final natureModifiers = PokemonNature.forName(nature);
    final constitution =
        pokemon.attributes.constitution + (natureModifiers['CON'] ?? 0);
    final constitutionModifier = ((constitution - 10) / 2).floor();
    final scaledHp =
        pokemon.hitPoints +
        (hitDieAverage * levelsGained) +
        (constitutionModifier * safeLevel);
    return max(1, scaledHp);
  }

  bool _matchesVariantFilters(
    Pokemon variant,
    PokemonGeneratorFilters filters,
  ) {
    final minimumSr = min(filters.minSr, filters.maxSr);
    final maximumSr = max(filters.minSr, filters.maxSr);
    if (variant.sr < minimumSr || variant.sr > maximumSr) return false;
    if (filters.level > 0 && variant.minLevelFound > filters.level) {
      return false;
    }

    final selectedType = filters.type?.trim();
    if (selectedType != null &&
        selectedType.isNotEmpty &&
        !variant.types.any(
          (type) => PokemonTypeLocalization.sameType(type, selectedType),
        )) {
      return false;
    }
    return true;
  }

  int _resolveLevel(Pokemon pokemon, int requestedLevel) {
    final minimum = max(1, pokemon.minLevelFound);
    if (requestedLevel <= 0) {
      return minimum.clamp(1, LevelProgression.maxLevel).toInt();
    }
    return max(
      minimum,
      requestedLevel,
    ).clamp(1, LevelProgression.maxLevel).toInt();
  }

  String? _randomGender(Pokemon pokemon, Random random) {
    final ratio = pokemon.genderRatio?.trim().toLowerCase() ?? '';
    if (ratio.contains('genderless') ||
        ratio.contains('senza sesso') ||
        ratio == 'none') {
      return 'Genderless';
    }

    final femalePercentage = _percentageFor(ratio, 'female');
    final malePercentage = _percentageFor(ratio, 'male');
    if (femalePercentage != null || malePercentage != null) {
      final female = femalePercentage ?? max(0, 100 - (malePercentage ?? 50));
      final male = malePercentage ?? max(0, 100 - female);
      final total = female + male;
      if (total <= 0) return null;
      return random.nextDouble() * total < female ? 'Female' : 'Male';
    }

    if (ratio.contains('female only') || ratio.contains('100% female')) {
      return 'Female';
    }
    if (ratio.contains('male only') || ratio.contains('100% male')) {
      return 'Male';
    }
    return random.nextBool() ? 'Male' : 'Female';
  }

  double? _percentageFor(String value, String gender) {
    if (value.isEmpty) return null;
    final expression = RegExp(
      '(\\d+(?:\\.\\d+)?)\\s*%?\\s*$gender\\b',
      caseSensitive: false,
    );
    final match = expression.firstMatch(value);
    return double.tryParse(match?.group(1) ?? '');
  }

  String _randomNature(Random random) {
    final natures = PokemonNature.names
        .where((nature) => nature != 'No Nature')
        .toList(growable: false);
    if (natures.isEmpty) return 'No Nature';
    return natures[random.nextInt(natures.length)];
  }

  String? _randomAbility(Pokemon pokemon, Random random) {
    final normal = pokemon.abilities
        .map((ability) => ability.trim())
        .where((ability) => ability.isNotEmpty)
        .toList(growable: false);
    final hidden = pokemon.hiddenAbility?.trim();
    if (hidden != null && hidden.isNotEmpty && random.nextInt(8) == 0) {
      return hidden;
    }
    if (normal.isNotEmpty) return normal[random.nextInt(normal.length)];
    return hidden == null || hidden.isEmpty ? null : hidden;
  }

  List<String> _randomMoves(Pokemon pokemon, int level, Random random) {
    final moves = <String>[];
    final seen = <String>{};

    void addMove(String reference) {
      final trimmed = reference.trim();
      if (trimmed.isEmpty) return;
      final key = trimmed
          .toLowerCase()
          .replaceAll(RegExp(r"[’']"), '')
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-');
      if (seen.add(key)) moves.add(trimmed);
    }

    for (final move in pokemon.moves.startingMoves) {
      addMove(move);
    }
    final levelEntries = pokemon.moves.levelMoves.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final entry in levelEntries) {
      if (entry.key > level) continue;
      for (final move in entry.value) {
        addMove(move);
      }
    }

    moves.shuffle(random);
    return moves.take(4).toList(growable: false);
  }
}
