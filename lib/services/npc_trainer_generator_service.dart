import 'dart:math';

import '../localization/game_catalog_locale.dart';
import '../localization/ui_text.dart';

import '../models/bag_item.dart';
import '../models/generated_npc_trainer.dart';
import '../models/generated_pokemon.dart';
import '../models/pokemon.dart';
import '../models/pokemon_type_localization.dart';
import '../models/trainer_manual_content.dart';
import '../models/trainer_progression.dart';
import 'pokemon_generator_service.dart';
import 'pokemon_habitat_service.dart';

class NpcTrainerGeneratorService {
  const NpcTrainerGeneratorService({
    this.pokemonGeneratorService = const PokemonGeneratorService(),
    this.habitatService = const PokemonHabitatService(),
  });

  final PokemonGeneratorService pokemonGeneratorService;
  final PokemonHabitatService habitatService;

  static const Map<String, String> specializationTypes = {
    'Bird Keeper': 'Flying',
    'Bug Maniac': 'Bug',
    'Camper': 'Ground',
    'Dragon Tamer': 'Dragon',
    'Engineer': 'Electric',
    'Martial Artist': 'Fighting',
    'Mountaineer': 'Rock',
    'Mystic': 'Ghost',
    'Steel Worker': 'Steel',
    'Psychic': 'Psychic',
    'Swimmer': 'Water',
    'Charmer': 'Fairy',
    'Shadow': 'Dark',
    'Alchemist': 'Poison',
    'Team Player': 'Normal',
    'Ice Skater': 'Ice',
    'Pyromaniac': 'Fire',
    'Gardener': 'Grass',
  };

  GeneratedNpcTrainer? generate({
    required List<Pokemon> catalog,
    required NpcTrainerGeneratorOptions options,
    required List<String> specializations,
    required List<TrainerOrigin> origins,
    required List<TrainerPath> paths,
    List<BagItem> items = const [],
    Random? random,
  }) {
    final rng = random ?? Random();
    final availableSpecializations = specializations.isEmpty
        ? specializationTypes.keys.toList(growable: false)
        : specializations;
    final primarySpecialization = _resolvePrimarySpecialization(
      options.specialization,
      availableSpecializations,
      rng,
    );
    final preferredType =
        specializationTypes[primarySpecialization] ?? 'Normal';
    final selectedSpecializations = _selectSpecializations(
      primary: primarySpecialization,
      available: availableSpecializations,
      trainerLevel: options.trainerLevel,
      random: rng,
    );
    final team = _generateTeam(
      catalog: catalog,
      options: options,
      preferredType: preferredType,
      random: rng,
    );
    if (team == null || team.isEmpty) return null;

    final name = _pick(_names, rng);
    final origin = origins.isEmpty
        ? uiTextForLanguage('Viaggiatore', 'Traveler')
        : _pick(origins, rng).name;
    final path = paths.isEmpty
        ? uiTextForLanguage('Allenatore', 'Trainer')
        : _pick(paths, rng).name;
    final personality = _pick(
      GameCatalogLocale.isItalian ? _personalities : _personalitiesEn,
      rng,
    );
    final motivation = _pick(
      GameCatalogLocale.isItalian ? _motivations : _motivationsEn,
      rng,
    );
    final quirk = _pick(GameCatalogLocale.isItalian ? _quirks : _quirksEn, rng);
    final typeLabel = GameCatalogLocale.isItalian
        ? PokemonTypeLocalization.italianLabel(preferredType)
        : PokemonTypeLocalization.englishValue(preferredType);
    final epithet = _epithetFor(
      rank: options.rank,
      specialization: primarySpecialization,
      typeLabel: typeLabel,
    );

    return GeneratedNpcTrainer(
      name: name,
      epithet: epithet,
      trainerLevel: options.trainerLevel.clamp(1, 20).toInt(),
      rank: options.rank,
      origin: origin,
      path: path,
      specializations: selectedSpecializations,
      preferredType: preferredType,
      personality: personality,
      motivation: motivation,
      quirk: quirk,
      openingLine: _openingLine(name, options.rank, rng),
      tactics: _tacticsFor(
        rank: options.rank,
        composition: options.composition,
        preferredTypeLabel: typeLabel,
        random: rng,
      ),
      rewardMoney: _rewardMoney(options),
      rewards: _rewardItems(items, options.rank, rng),
      team: team,
      options: options,
      generatedAt: DateTime.now(),
    );
  }

  double maxSrFor(NpcTrainerGeneratorOptions options) {
    final base = TrainerProgression.maxControlledSrForLevel(
      options.trainerLevel,
    );
    return min(20, base + options.rank.srBonus).toDouble();
  }

  String preferredTypeFor(String specialization) {
    return specializationTypes[specialization] ?? 'Normal';
  }

  String _resolvePrimarySpecialization(
    String? requested,
    List<String> available,
    Random random,
  ) {
    final normalized = requested?.trim() ?? '';
    if (normalized.isNotEmpty && available.contains(normalized)) {
      return normalized;
    }
    return _pick(available, random);
  }

  List<String> _selectSpecializations({
    required String primary,
    required List<String> available,
    required int trainerLevel,
    required Random random,
  }) {
    final desiredCount = trainerLevel >= 18
        ? 3
        : trainerLevel >= 7
        ? 2
        : 1;
    final selected = <String>[primary];
    final remaining = available.where((value) => value != primary).toList()
      ..shuffle(random);
    for (final specialization in remaining) {
      if (selected.length >= desiredCount) break;
      selected.add(specialization);
    }
    return selected;
  }

  List<GeneratedPokemon>? _generateTeam({
    required List<Pokemon> catalog,
    required NpcTrainerGeneratorOptions options,
    required String preferredType,
    required Random random,
  }) {
    final teamSize = options.teamSize.clamp(1, 6).toInt();
    final pokemonLevel = options.pokemonLevel.clamp(1, 20).toInt();
    final minimumGeneration = min(
      options.minGeneration,
      options.maxGeneration,
    ).clamp(1, 9).toInt();
    final maximumGeneration = max(
      options.minGeneration,
      options.maxGeneration,
    ).clamp(1, 9).toInt();
    final maxSr = maxSrFor(options);
    final generalFilters = PokemonGeneratorFilters(
      minSr: 0,
      maxSr: maxSr,
      minGeneration: minimumGeneration,
      maxGeneration: maximumGeneration,
      level: pokemonLevel,
      includeForms: options.includeForms,
      shinyChance: 0.01,
    );
    final themedFilters = generalFilters.copyWith(type: preferredType);
    final generalCandidates = pokemonGeneratorService
        .filterPokemon(catalog, generalFilters)
        .where(
          (pokemon) =>
              options.allowLegendary ||
              !habitatService.isLegendaryOrMythical(pokemon),
        )
        .toList(growable: true);
    final themedCandidates = pokemonGeneratorService
        .filterPokemon(catalog, themedFilters)
        .where(
          (pokemon) =>
              options.allowLegendary ||
              !habitatService.isLegendaryOrMythical(pokemon),
        )
        .toList(growable: true);
    if (generalCandidates.isEmpty) return null;
    if (options.composition == NpcTeamComposition.themed &&
        themedCandidates.isEmpty) {
      return null;
    }

    final themedSlots = switch (options.composition) {
      NpcTeamComposition.themed => teamSize,
      NpcTeamComposition.mixed => max(1, (teamSize * 0.6).ceil()),
      NpcTeamComposition.varied => 0,
    };
    final usedIds = <int>{};
    final generated = <GeneratedPokemon>[];

    for (var index = 0; index < teamSize; index++) {
      final wantsTheme = index < themedSlots;
      var pool = wantsTheme && themedCandidates.isNotEmpty
          ? themedCandidates
          : generalCandidates;
      if (!options.allowDuplicates) {
        pool = pool
            .where((pokemon) => !usedIds.contains(pokemon.id))
            .toList(growable: false);
      }
      if (pool.isEmpty) return null;

      final selected = _pickPokemonForRank(pool, options.rank, random);
      final generatedPokemon = pokemonGeneratorService.generateForPokemon(
        pokemon: selected,
        filters: wantsTheme ? themedFilters : generalFilters,
        random: random,
      );
      if (generatedPokemon == null) return null;
      generated.add(generatedPokemon);
      usedIds.add(selected.id);
    }

    if (options.composition == NpcTeamComposition.varied) {
      generated.shuffle(random);
    }
    return generated;
  }

  Pokemon _pickPokemonForRank(
    List<Pokemon> pool,
    NpcTrainerRank rank,
    Random random,
  ) {
    final ranked = [...pool]..sort((a, b) => a.sr.compareTo(b.sr));
    final startFraction = switch (rank) {
      NpcTrainerRank.common => 0.0,
      NpcTrainerRank.expert => 0.25,
      NpcTrainerRank.elite => 0.45,
      NpcTrainerRank.boss => 0.6,
    };
    final start = min(
      ranked.length - 1,
      (ranked.length * startFraction).floor(),
    );
    final eligible = ranked.sublist(start);
    return eligible[random.nextInt(eligible.length)];
  }

  String _epithetFor({
    required NpcTrainerRank rank,
    required String specialization,
    required String typeLabel,
  }) {
    return switch (rank) {
      NpcTrainerRank.common => specialization,
      NpcTrainerRank.expert => uiTextForLanguage(
        'Esperto $typeLabel',
        '$typeLabel Expert',
      ),
      NpcTrainerRank.elite => uiTextForLanguage(
        '$specialization d’élite',
        'Elite $specialization',
      ),
      NpcTrainerRank.boss => uiTextForLanguage(
        'Maestro del tipo $typeLabel',
        '$typeLabel Master',
      ),
    };
  }

  String _openingLine(String name, NpcTrainerRank rank, Random random) {
    final line = switch (rank) {
      NpcTrainerRank.common => _pick(
        GameCatalogLocale.isItalian
            ? _commonOpeningLines
            : _commonOpeningLinesEn,
        random,
      ),
      NpcTrainerRank.expert => _pick(
        GameCatalogLocale.isItalian
            ? _expertOpeningLines
            : _expertOpeningLinesEn,
        random,
      ),
      NpcTrainerRank.elite => _pick(
        GameCatalogLocale.isItalian ? _eliteOpeningLines : _eliteOpeningLinesEn,
        random,
      ),
      NpcTrainerRank.boss => _pick(
        GameCatalogLocale.isItalian ? _bossOpeningLines : _bossOpeningLinesEn,
        random,
      ),
    };
    return line.replaceAll('{name}', name);
  }

  String _tacticsFor({
    required NpcTrainerRank rank,
    required NpcTeamComposition composition,
    required String preferredTypeLabel,
    required Random random,
  }) {
    final compositionTactic = switch (composition) {
      NpcTeamComposition.themed => uiTextForLanguage(
        'Costruisce sinergie attorno al tipo $preferredTypeLabel e cerca di imporre subito il proprio terreno ideale.',
        'Builds synergy around the $preferredTypeLabel type and tries to establish ideal field conditions immediately.',
      ),
      NpcTeamComposition.mixed => uiTextForLanguage(
        'Apre con un Pokémon del proprio tema e conserva le coperture per rispondere alle debolezze più evidenti.',
        'Opens with a Pokémon that fits the theme and keeps coverage options for the most obvious weaknesses.',
      ),
      NpcTeamComposition.varied => uiTextForLanguage(
        'Cambia spesso approccio e usa la varietà della squadra per costringere l’avversario a reagire.',
        'Frequently changes approach and uses team variety to force the opponent to react.',
      ),
    };
    final rankTactic = switch (rank) {
      NpcTrainerRank.common => _pick(
        GameCatalogLocale.isItalian ? _commonTactics : _commonTacticsEn,
        random,
      ),
      NpcTrainerRank.expert => _pick(
        GameCatalogLocale.isItalian ? _expertTactics : _expertTacticsEn,
        random,
      ),
      NpcTrainerRank.elite => _pick(
        GameCatalogLocale.isItalian ? _eliteTactics : _eliteTacticsEn,
        random,
      ),
      NpcTrainerRank.boss => _pick(
        GameCatalogLocale.isItalian ? _bossTactics : _bossTacticsEn,
        random,
      ),
    };
    return '$compositionTactic $rankTactic';
  }

  int _rewardMoney(NpcTrainerGeneratorOptions options) {
    final base =
        options.trainerLevel.clamp(1, 20) * 120 +
        options.pokemonLevel.clamp(1, 20) * 45 +
        options.teamSize.clamp(1, 6) * 90;
    final adjusted = base * options.rank.rewardMultiplier;
    return max(100, (adjusted / 50).round() * 50);
  }

  List<String> _rewardItems(
    List<BagItem> items,
    NpcTrainerRank rank,
    Random random,
  ) {
    final desired = switch (rank) {
      NpcTrainerRank.common => random.nextBool() ? 1 : 0,
      NpcTrainerRank.expert => 1,
      NpcTrainerRank.elite => 2,
      NpcTrainerRank.boss => 2,
    };
    if (desired == 0 || items.isEmpty) return const [];

    final maximumCost = switch (rank) {
      NpcTrainerRank.common => 1000,
      NpcTrainerRank.expert => 2500,
      NpcTrainerRank.elite => 8000,
      NpcTrainerRank.boss => 30000,
    };
    final candidates =
        items
            .where((item) {
              final cost = item.cost ?? 0;
              if (cost <= 0 || cost > maximumCost || item.name.trim().isEmpty) {
                return false;
              }
              return !const {
                'key-item',
                'trainer-gear',
                'evolution',
              }.contains(item.type);
            })
            .toList(growable: true)
          ..shuffle(random);

    return candidates
        .take(min(desired, candidates.length))
        .map((item) => item.name)
        .toList(growable: false);
  }

  T _pick<T>(List<T> values, Random random) {
    return values[random.nextInt(values.length)];
  }

  static const List<String> _names = [
    'Alessio',
    'Arianna',
    'Bruno',
    'Camilla',
    'Dario',
    'Elena',
    'Fabio',
    'Giada',
    'Irene',
    'Luca',
    'Marta',
    'Nicolò',
    'Oriana',
    'Pietro',
    'Rachele',
    'Samuele',
    'Teresa',
    'Viola',
  ];

  static const List<String> _personalities = [
    'Calmo e osservatore: parla poco, ma studia attentamente ogni scelta.',
    'Entusiasta e competitivo: considera ogni lotta un’occasione per migliorare.',
    'Cordiale fuori dal combattimento, spietatamente metodico quando inizia la sfida.',
    'Orgoglioso della propria squadra e sensibile a qualunque critica sui suoi Pokémon.',
    'Ironico e teatrale: commenta ogni mossa come se fosse davanti a un pubblico.',
    'Pragmatico e diretto: non spreca parole né turni.',
  ];

  static const List<String> _motivations = [
    'Vuole dimostrare che la preparazione conta più del talento naturale.',
    'Sta cercando un avversario capace di mettere davvero alla prova il suo asso.',
    'Protegge il territorio e non si fida degli sconosciuti che lo attraversano.',
    'Raccoglie dati per perfezionare una strategia ancora incompleta.',
    'Ha bisogno della ricompensa promessa per una vittoria importante.',
    'Desidera riscattarsi dopo una sconfitta che non ha mai accettato.',
  ];

  static const List<String> _quirks = [
    'Prende appunti su un taccuino dopo ogni turno.',
    'Chiama ogni Pokémon con un soprannome altisonante.',
    'Lancia la Poké Ball con un gesto studiato e sempre identico.',
    'Si scusa con i propri Pokémon anche per gli ordini corretti.',
    'Conta sottovoce i turni e le risorse consumate.',
    'Conserva un portafortuna legato alla sua prima cattura.',
  ];

  static const List<String> _commonOpeningLines = [
    '«Io sono {name}. Vediamo cosa sai fare davvero.»',
    '«Una lotta veloce? Prometto di non trattenere la mia squadra.»',
    '«Non serve essere famosi per combattere bene.»',
  ];

  static const List<String> _expertOpeningLines = [
    '«{name}. Ricorda il nome: dopo questa lotta capirai perché.»',
    '«Ho già studiato il tuo stile. Ora vediamo se sai adattarti.»',
    '«Ogni squadra ha una crepa. Io troverò la tua.»',
  ];

  static const List<String> _eliteOpeningLines = [
    '«Sei arrivato fin qui. Adesso affronta {name} senza esitazioni.»',
    '«La forza non basta: devi meritarti ogni singolo turno.»',
    '«La mia squadra non concede seconde occasioni.»',
  ];

  static const List<String> _bossOpeningLines = [
    '«Io sono {name}. Questa lotta deciderà molto più di una semplice vittoria.»',
    '«Hai superato le prove minori. Ora resta soltanto la mia squadra.»',
    '«Da questo momento, ogni scelta avrà un prezzo.»',
  ];

  static const List<String> _commonTactics = [
    'Preferisce mosse affidabili e raramente cambia Pokémon senza necessità.',
    'Tende a concentrarsi sul bersaglio già indebolito.',
  ];

  static const List<String> _expertTactics = [
    'Sfrutta condizioni e resistenze prima di mandare in campo il proprio asso.',
    'Conserva almeno una risposta contro il tipo che minaccia maggiormente la squadra.',
  ];

  static const List<String> _eliteTactics = [
    'Alterna pressione offensiva e controllo, evitando di mostrare subito tutte le risorse.',
    'Protegge il Pokémon più importante finché non può entrare con un vantaggio concreto.',
  ];

  static const List<String> _bossTactics = [
    'Tratta la lotta come uno scontro a fasi: apre per leggere il gruppo, poi accelera con il proprio asso.',
    'Usa cambi, condizioni e coperture per isolare il bersaglio più pericoloso prima del colpo decisivo.',
  ];

  static const List<String> _personalitiesEn = [
    'Calm and observant: speaks little, but carefully studies every choice.',
    'Enthusiastic and competitive: treats every battle as a chance to improve.',
    'Friendly outside battle, ruthlessly methodical once the challenge begins.',
    'Proud of the team and sensitive to any criticism of their Pokémon.',
    'Witty and theatrical: comments on every move as though performing for an audience.',
    'Pragmatic and direct: wastes neither words nor turns.',
  ];

  static const List<String> _motivationsEn = [
    'Wants to prove that preparation matters more than natural talent.',
    'Is looking for an opponent capable of truly testing their ace.',
    'Protects the territory and distrusts strangers passing through it.',
    'Collects data to perfect a strategy that is still incomplete.',
    'Needs the promised reward for an important victory.',
    'Wants redemption after a defeat they never accepted.',
  ];

  static const List<String> _quirksEn = [
    'Takes notes in a notebook after every turn.',
    'Calls every Pokémon by a grandiose nickname.',
    'Throws each Poké Ball with the same carefully practiced motion.',
    'Apologizes to their Pokémon even when giving the correct order.',
    'Quietly counts turns and spent resources.',
    'Keeps a lucky charm tied to their first catch.',
  ];

  static const List<String> _commonOpeningLinesEn = [
    '“I am {name}. Let us see what you can really do.”',
    '“A quick battle? I promise my team will not hold back.”',
    '“You do not need to be famous to battle well.”',
  ];

  static const List<String> _expertOpeningLinesEn = [
    '“{name}. Remember the name: after this battle, you will understand why.”',
    '“I have already studied your style. Now let us see whether you can adapt.”',
    '“Every team has a weakness. I will find yours.”',
  ];

  static const List<String> _eliteOpeningLinesEn = [
    '“You made it this far. Now face {name} without hesitation.”',
    '“Strength is not enough: you must earn every single turn.”',
    '“My team does not offer second chances.”',
  ];

  static const List<String> _bossOpeningLinesEn = [
    '“I am {name}. This battle will decide far more than a simple victory.”',
    '“You passed the lesser trials. Now only my team remains.”',
    '“From this moment on, every choice will have a price.”',
  ];

  static const List<String> _commonTacticsEn = [
    'Prefers reliable moves and rarely switches Pokémon without a reason.',
    'Tends to focus on an already weakened target.',
  ];

  static const List<String> _expertTacticsEn = [
    'Uses conditions and resistances before sending out the ace.',
    'Keeps at least one answer to the type that threatens the team most.',
  ];

  static const List<String> _eliteTacticsEn = [
    'Alternates offensive pressure and control without revealing every resource immediately.',
    'Protects the most important Pokémon until it can enter with a concrete advantage.',
  ];

  static const List<String> _bossTacticsEn = [
    'Treats the battle as a phased encounter: opens by reading the group, then accelerates with the ace.',
    'Uses switches, conditions, and coverage to isolate the most dangerous target before the decisive blow.',
  ];
}
