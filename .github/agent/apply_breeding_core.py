from __future__ import annotations

import csv
import io
import json
import re
import urllib.request
from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: attesa 1 occorrenza, trovate {count}")
    return text.replace(old, new, 1)


def download_csv(url: str) -> list[dict[str, str]]:
    with urllib.request.urlopen(url, timeout=60) as response:
        source = response.read().decode("utf-8")
    return list(csv.DictReader(io.StringIO(source)))


def generate_breeding_asset() -> None:
    base = "https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv"
    group_rows = download_csv(f"{base}/egg_groups.csv")
    pokemon_group_rows = download_csv(f"{base}/pokemon_egg_groups.csv")
    species_rows = download_csv(f"{base}/pokemon_species.csv")

    labels = {
        "monster": "Monster",
        "water1": "Water 1",
        "bug": "Bug",
        "flying": "Flying",
        "ground": "Field",
        "fairy": "Fairy",
        "plant": "Grass",
        "humanshape": "Human-Like",
        "water3": "Water 3",
        "mineral": "Mineral",
        "indeterminate": "Amorphous",
        "water2": "Water 2",
        "ditto": "Ditto",
        "dragon": "Dragon",
        "no-eggs": "Undiscovered",
    }
    group_by_id = {
        int(row["id"]): labels.get(row["identifier"], row["identifier"])
        for row in group_rows
    }
    groups_by_species: dict[int, list[str]] = {}
    for row in pokemon_group_rows:
        species_id = int(row["species_id"])
        groups_by_species.setdefault(species_id, []).append(
            group_by_id[int(row["egg_group_id"])]
        )

    parent_by_species: dict[int, int | None] = {}
    flags_by_species: dict[int, dict[str, bool]] = {}
    for row in species_rows:
        species_id = int(row["id"])
        parent = row["evolves_from_species_id"].strip()
        parent_by_species[species_id] = int(parent) if parent else None
        flags_by_species[species_id] = {
            "isBaby": row["is_baby"] == "1",
            "isLegendary": row["is_legendary"] == "1",
            "isMythical": row["is_mythical"] == "1",
        }

    def root_species(species_id: int) -> int:
        seen: set[int] = set()
        current = species_id
        while current not in seen:
            seen.add(current)
            parent = parent_by_species.get(current)
            if parent is None:
                return current
            current = parent
        return species_id

    items: dict[str, dict[str, object]] = {}
    for species_id, egg_groups in sorted(groups_by_species.items()):
        item: dict[str, object] = {
            "eggGroups": egg_groups,
            "baseSpeciesId": root_species(species_id),
        }
        item.update(flags_by_species.get(species_id, {}))
        items[str(species_id)] = item

    output = {
        "source": "PokeAPI CSV snapshot generated at build time",
        "items": items,
    }
    Path("assets/data/breeding_species.json").write_text(
        json.dumps(output, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )


BREEDING_EGG = r'''enum EggIncubator { none, basic, plus, super }

extension EggIncubatorDetails on EggIncubator {
  String get label => switch (this) {
    EggIncubator.none => 'Nessuno',
    EggIncubator.basic => 'Basic',
    EggIncubator.plus => 'Plus',
    EggIncubator.super => 'Super',
  };

  int get extraD20 => switch (this) {
    EggIncubator.none => 0,
    EggIncubator.basic => 1,
    EggIncubator.plus => 2,
    EggIncubator.super => 3,
  };
}

class BreedingEgg {
  static const Object _unset = Object();

  const BreedingEgg({
    required this.id,
    required this.speciesId,
    required this.parentNames,
    required this.createdAt,
    required this.hatchTime,
    required this.incubationRemaining,
    required this.nature,
    required this.gender,
    required this.ability,
    required this.selectedMoves,
    required this.inheritedMoves,
    this.formName,
    this.isShiny = false,
    this.incubator = EggIncubator.none,
    this.carriedEntireIncubation = true,
  });

  final String id;
  final int speciesId;
  final String? formName;
  final List<String> parentNames;
  final DateTime createdAt;
  final int hatchTime;
  final int incubationRemaining;
  final String nature;
  final String? gender;
  final String? ability;
  final List<String> selectedMoves;
  final List<String> inheritedMoves;
  final bool isShiny;
  final EggIncubator incubator;
  final bool carriedEntireIncubation;

  bool get isReady => incubationRemaining <= 0;

  double get progress {
    if (hatchTime <= 0) return 1;
    return (1 - incubationRemaining / hatchTime).clamp(0.0, 1.0);
  }

  BreedingEgg copyWith({
    int? incubationRemaining,
    EggIncubator? incubator,
    bool? carriedEntireIncubation,
    Object? formName = _unset,
  }) {
    return BreedingEgg(
      id: id,
      speciesId: speciesId,
      formName: identical(formName, _unset) ? this.formName : formName as String?,
      parentNames: parentNames,
      createdAt: createdAt,
      hatchTime: hatchTime,
      incubationRemaining:
          incubationRemaining ?? this.incubationRemaining,
      nature: nature,
      gender: gender,
      ability: ability,
      selectedMoves: selectedMoves,
      inheritedMoves: inheritedMoves,
      isShiny: isShiny,
      incubator: incubator ?? this.incubator,
      carriedEntireIncubation:
          carriedEntireIncubation ?? this.carriedEntireIncubation,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'speciesId': speciesId,
      'formName': formName,
      'parentNames': parentNames,
      'createdAt': createdAt.toIso8601String(),
      'hatchTime': hatchTime,
      'incubationRemaining': incubationRemaining,
      'nature': nature,
      'gender': gender,
      'ability': ability,
      'selectedMoves': selectedMoves,
      'inheritedMoves': inheritedMoves,
      'isShiny': isShiny,
      'incubator': incubator.name,
      'carriedEntireIncubation': carriedEntireIncubation,
    };
  }

  factory BreedingEgg.fromJson(Map<String, dynamic> json) {
    final incubatorName = json['incubator']?.toString() ?? 'none';
    return BreedingEgg(
      id: json['id']?.toString() ?? '',
      speciesId: _readInt(json['speciesId']),
      formName: json['formName']?.toString(),
      parentNames: List<String>.from(json['parentNames'] ?? const []),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      hatchTime: _readInt(json['hatchTime']),
      incubationRemaining: _readInt(json['incubationRemaining']),
      nature: json['nature']?.toString() ?? 'No Nature',
      gender: json['gender']?.toString(),
      ability: json['ability']?.toString(),
      selectedMoves: List<String>.from(json['selectedMoves'] ?? const []),
      inheritedMoves: List<String>.from(json['inheritedMoves'] ?? const []),
      isShiny: json['isShiny'] as bool? ?? false,
      incubator: EggIncubator.values.firstWhere(
        (value) => value.name == incubatorName,
        orElse: () => EggIncubator.none,
      ),
      carriedEntireIncubation:
          json['carriedEntireIncubation'] as bool? ?? true,
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
'''

BREEDING_CANDIDATE = r'''class BreedingCandidate {
  const BreedingCandidate({
    required this.key,
    required this.pokemonId,
    required this.displayName,
    required this.location,
    required this.loyalty,
    required this.selectedMoves,
    required this.abilities,
    this.formName,
    this.gender,
  });

  final String key;
  final int pokemonId;
  final String displayName;
  final String location;
  final int loyalty;
  final List<String> selectedMoves;
  final List<String> abilities;
  final String? formName;
  final String? gender;

  bool get isMale => gender?.toLowerCase() == 'male';
  bool get isFemale => gender?.toLowerCase() == 'female';
  bool get isGenderless => gender?.toLowerCase() == 'genderless';

  String get genderLabel => switch (gender?.toLowerCase()) {
    'male' => 'Maschio',
    'female' => 'Femmina',
    'genderless' => 'Senza sesso',
    _ => 'Sesso non impostato',
  };
}
'''

BREEDING_DATA = r'''import 'dart:convert';

import 'package:flutter/services.dart';

class BreedingSpeciesData {
  const BreedingSpeciesData({
    required this.speciesId,
    required this.eggGroups,
    required this.baseSpeciesId,
    required this.isBaby,
    required this.isLegendary,
    required this.isMythical,
  });

  final int speciesId;
  final List<String> eggGroups;
  final int baseSpeciesId;
  final bool isBaby;
  final bool isLegendary;
  final bool isMythical;

  bool get isDitto => eggGroups.contains('Ditto');
  bool get isUndiscovered => eggGroups.contains('Undiscovered');

  factory BreedingSpeciesData.fromJson(
    int speciesId,
    Map<String, dynamic> json,
  ) {
    return BreedingSpeciesData(
      speciesId: speciesId,
      eggGroups: List<String>.from(json['eggGroups'] ?? const []),
      baseSpeciesId: _readInt(json['baseSpeciesId'], fallback: speciesId),
      isBaby: json['isBaby'] as bool? ?? false,
      isLegendary: json['isLegendary'] as bool? ?? false,
      isMythical: json['isMythical'] as bool? ?? false,
    );
  }

  static int _readInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class BreedingDataService {
  static Map<int, BreedingSpeciesData>? _cache;

  Future<Map<int, BreedingSpeciesData>> load() async {
    final cached = _cache;
    if (cached != null) return Map<int, BreedingSpeciesData>.from(cached);

    final source = await rootBundle.loadString(
      'assets/data/breeding_species.json',
    );
    final decoded = Map<String, dynamic>.from(jsonDecode(source));
    final items = Map<String, dynamic>.from(decoded['items'] ?? const {});
    final result = <int, BreedingSpeciesData>{};
    for (final entry in items.entries) {
      final id = int.tryParse(entry.key);
      if (id == null || entry.value is! Map) continue;
      result[id] = BreedingSpeciesData.fromJson(
        id,
        Map<String, dynamic>.from(entry.value as Map),
      );
    }
    _cache = result;
    return Map<int, BreedingSpeciesData>.from(result);
  }
}
'''

BREEDING_REPOSITORY = r'''import 'package:hive_flutter/hive_flutter.dart';

import '../database/hive_boxes.dart';
import '../models/breeding_egg.dart';

class BreedingEggRepository {
  Future<Box> _box() => Hive.openBox(HiveBoxes.breedingEggs);

  Future<List<BreedingEgg>> getEggs(String profileId) async {
    final box = await _box();
    final raw = box.get(profileId);
    if (raw == null) return const [];
    final eggs = List<Map>.from(raw)
        .map((item) => BreedingEgg.fromJson(Map<String, dynamic>.from(item)))
        .where((egg) => egg.id.isNotEmpty && egg.speciesId > 0)
        .toList();
    eggs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return eggs;
  }

  Future<void> replaceEggs(String profileId, List<BreedingEgg> eggs) async {
    final box = await _box();
    await box.put(profileId, eggs.map((egg) => egg.toJson()).toList());
    await box.flush();
  }

  Future<void> saveEgg(String profileId, BreedingEgg egg) async {
    final eggs = await getEggs(profileId);
    final index = eggs.indexWhere((candidate) => candidate.id == egg.id);
    if (index == -1) {
      eggs.insert(0, egg);
    } else {
      eggs[index] = egg;
    }
    await replaceEggs(profileId, eggs);
  }

  Future<void> deleteEgg(String profileId, String eggId) async {
    final eggs = await getEggs(profileId);
    await replaceEggs(
      profileId,
      [for (final egg in eggs) if (egg.id != eggId) egg],
    );
  }

  Future<void> deleteEggs(String profileId) async {
    final box = await _box();
    await box.delete(profileId);
    await box.flush();
  }
}
'''

BREEDING_SERVICE = r'''import 'dart:math';

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
      errors.add('I dati dei Gruppi Uova non sono disponibili per uno dei genitori.');
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

    final shared = firstData.eggGroups
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
      final supportsForm = child?.formDefinitions.any(
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
    final rank = sr.ceil().clamp(1, 15);
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
    final female = first.isFemale ? first : second.isFemale ? second : null;
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
    final base = d100Rolls.reduce(max);
    final reduction = base + incubatorRolls.fold(0, (sum, value) => sum + value);
    return IncubationProgressResult(
      egg: egg.copyWith(
        incubationRemaining: max(0, egg.incubationRemaining - reduction),
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
    final firstMoves = {_moveKeys(first.selectedMoves)};
    final secondMoves = {_moveKeys(second.selectedMoves)};
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
'''

BREEDING_SCREEN = r'''import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/breeding_candidate.dart';
import '../../models/breeding_egg.dart';
import '../../models/breeding_species_data.dart';
import '../../models/level_progression.dart';
import '../../models/pc_pokemon.dart';
import '../../models/pokemon.dart';
import '../../models/team_slot.dart';
import '../../models/user_profile.dart';
import '../../repositories/breeding_egg_repository.dart';
import '../../repositories/pokemon_pc_repository.dart';
import '../../repositories/pokemon_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/team_repository.dart';
import '../../services/breeding_service.dart';
import '../../services/pokemon_generator_service.dart';
import '../../widgets/navigation/home_leading_button.dart';
import '../../widgets/pokemon/pokemon_asset_image.dart';

class BreedingScreen extends StatefulWidget {
  const BreedingScreen({super.key});

  @override
  State<BreedingScreen> createState() => _BreedingScreenState();
}

class _BreedingScreenState extends State<BreedingScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final PokemonRepository _pokemonRepository = PokemonRepository();
  final TeamRepository _teamRepository = TeamRepository();
  final PokemonPcRepository _pcRepository = PokemonPcRepository();
  final BreedingEggRepository _eggRepository = BreedingEggRepository();
  final BreedingDataService _dataService = BreedingDataService();
  final BreedingService _breedingService = const BreedingService();
  final PokemonGeneratorService _generator = const PokemonGeneratorService();
  final Random _random = Random();
  final TextEditingController _manualRollController = TextEditingController();

  late Future<_BreedingScreenData> _future;
  String? _firstKey;
  String? _secondKey;
  String? _message;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _manualRollController.dispose();
    super.dispose();
  }

  Future<_BreedingScreenData> _load() async {
    final profile = await _profileRepository.getActiveProfile();
    final results = await Future.wait([
      _pokemonRepository.getAllPokemon(),
      _teamRepository.getTeam(profile.id),
      _pcRepository.getPokemon(profile.id),
      _eggRepository.getEggs(profile.id),
      _dataService.load(),
    ]);
    final catalog = results[0] as List<Pokemon>;
    final team = results[1] as List<TeamSlot>;
    final pc = results[2] as List<PcPokemon>;
    final eggs = results[3] as List<BreedingEgg>;
    final speciesData = results[4] as Map<int, BreedingSpeciesData>;
    final byId = {for (final pokemon in catalog) pokemon.id: pokemon};
    final candidates = <BreedingCandidate>[];

    for (final slot in team) {
      final pokemonId = slot.pokemonId;
      if (pokemonId == null) continue;
      final base = byId[pokemonId];
      if (base == null) continue;
      final pokemon = base.resolveVariant(
        formName: slot.formName,
        gender: slot.gender,
      );
      candidates.add(
        BreedingCandidate(
          key: 'team:${slot.slotIndex}',
          pokemonId: pokemonId,
          formName: slot.formName,
          displayName: _displayName(
            nickname: slot.nickname,
            pokemon: pokemon,
            formName: slot.formName,
          ),
          location: 'Squadra ${slot.slotIndex + 1}',
          gender: slot.gender,
          loyalty: slot.loyalty,
          selectedMoves: _knownMoves(
            pokemon: pokemon,
            experience: slot.experience,
            selectedMoves: slot.selectedMoves,
          ),
          abilities: slot.abilities.isEmpty
              ? pokemon.abilities.take(1).toList()
              : slot.abilities,
        ),
      );
    }

    for (final stored in pc) {
      final base = byId[stored.pokemonId];
      if (base == null) continue;
      final pokemon = base.resolveVariant(
        formName: stored.formName,
        gender: stored.gender,
      );
      candidates.add(
        BreedingCandidate(
          key: 'pc:${stored.id}',
          pokemonId: stored.pokemonId,
          formName: stored.formName,
          displayName: _displayName(
            nickname: stored.nickname,
            pokemon: pokemon,
            formName: stored.formName,
          ),
          location: 'PC',
          gender: stored.gender,
          loyalty: stored.loyalty,
          selectedMoves: _knownMoves(
            pokemon: pokemon,
            experience: stored.experience,
            selectedMoves: stored.selectedMoves,
          ),
          abilities: stored.abilities.isEmpty
              ? pokemon.abilities.take(1).toList()
              : stored.abilities,
        ),
      );
    }

    candidates.sort((a, b) => a.displayName.compareTo(b.displayName));
    return _BreedingScreenData(
      profile: profile,
      catalog: catalog,
      catalogById: byId,
      team: team,
      candidates: candidates,
      eggs: eggs,
      speciesData: speciesData,
    );
  }

  Future<void> _reload({String? message}) async {
    if (!mounted) return;
    setState(() {
      _message = message;
      _future = _load();
    });
  }

  BreedingCandidate? _candidateFor(
    _BreedingScreenData data,
    String? key,
  ) {
    if (key == null) return null;
    for (final candidate in data.candidates) {
      if (candidate.key == key) return candidate;
    }
    return null;
  }

  BreedingCompatibility? _compatibility(_BreedingScreenData data) {
    final first = _candidateFor(data, _firstKey);
    final second = _candidateFor(data, _secondKey);
    if (first == null || second == null) return null;
    return _breedingService.compatibility(
      first: first,
      second: second,
      speciesData: data.speciesData,
      catalog: data.catalogById,
    );
  }

  Future<void> _attemptBreeding(
    _BreedingScreenData data, {
    int? manualRoll,
  }) async {
    final first = _candidateFor(data, _firstKey);
    final second = _candidateFor(data, _secondKey);
    final compatibility = _compatibility(data);
    if (first == null || second == null || compatibility == null) return;
    if (!compatibility.isCompatible) {
      setState(() => _message = compatibility.errors.join(' '));
      return;
    }

    final roll = manualRoll ?? _random.nextInt(20) + 1;
    if (roll < 1 || roll > 20) {
      setState(() => _message = 'Il risultato del d20 deve essere tra 1 e 20.');
      return;
    }
    final modifier = _breedingService.breedingRollModifier(data.profile);
    final dc = _breedingService.successDc(first.loyalty + second.loyalty);
    final total = roll + modifier;
    if (total < dc) {
      setState(() {
        _message = 'Tentativo fallito: d20 $roll ${_signed(modifier)} = $total contro CD $dc.';
      });
      return;
    }

    try {
      final egg = _breedingService.createEgg(
        first: first,
        second: second,
        compatibility: compatibility,
        catalog: data.catalogById,
        random: _random,
      );
      await _eggRepository.saveEgg(data.profile.id, egg);
      _manualRollController.clear();
      _firstKey = null;
      _secondKey = null;
      await _reload(
        message: 'Successo: d20 $roll ${_signed(modifier)} = $total contro CD $dc. Uovo creato.',
      );
    } catch (error) {
      setState(() => _message = error.toString());
    }
  }

  Future<void> _advanceEgg(
    _BreedingScreenData data,
    BreedingEgg egg,
  ) async {
    final result = _breedingService.advanceIncubation(
      egg: egg,
      profile: data.profile,
      random: _random,
    );
    await _eggRepository.saveEgg(data.profile.id, result.egg);
    final baseRoll = result.d100Rolls.join(' / ');
    final incubator = result.incubatorRolls.isEmpty
        ? ''
        : ' + incubatore ${result.incubatorRolls.join(' + ')}';
    await _reload(
      message:
          'Incubazione: d100 $baseRoll$incubator. Contatore ridotto di ${result.reduction}.',
    );
  }

  Future<void> _updateEgg(
    _BreedingScreenData data,
    BreedingEgg egg,
  ) async {
    await _eggRepository.saveEgg(data.profile.id, egg);
    await _reload();
  }

  Future<void> _deleteEgg(
    _BreedingScreenData data,
    BreedingEgg egg,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare l’uovo?'),
        content: const Text(
          'Il progresso di incubazione e i dati del Pokémon contenuto andranno persi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ANNULLA'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('ELIMINA'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    await _eggRepository.deleteEgg(data.profile.id, egg.id);
    await _reload(message: 'Uovo eliminato.');
  }

  Future<void> _hatchEgg(
    _BreedingScreenData data,
    BreedingEgg egg,
  ) async {
    if (!egg.isReady) return;
    final base = data.catalogById[egg.speciesId];
    if (base == null) {
      setState(() => _message = 'La specie dell’uovo non è nel catalogo.');
      return;
    }
    final pokemon = base.resolveVariant(
      formName: egg.formName,
      gender: egg.gender,
    );
    final level = max(1, pokemon.minLevelFound);
    final experience = LevelProgression.thresholdForLevel(level);
    final maxHp = _generator.maxHpFor(
      pokemon: pokemon,
      level: level,
      nature: egg.nature,
    );
    final loyalty = egg.carriedEntireIncubation ? 2 : 1;
    TeamSlot? emptySlot;
    for (final slot in data.team) {
      if (slot.pokemonId == null) {
        emptySlot = slot;
        break;
      }
    }

    if (emptySlot != null) {
      await _teamRepository.updateSlot(
        profileId: data.profile.id,
        updatedSlot: TeamSlot(
          slotIndex: emptySlot.slotIndex,
          pokemonId: egg.speciesId,
          experience: experience,
          currentHp: maxHp,
          selectedMoves: egg.selectedMoves,
          isShiny: egg.isShiny,
          gender: egg.gender,
          formName: egg.formName,
          nature: egg.nature,
          abilities: egg.ability == null ? const [] : [egg.ability!],
          loyalty: loyalty,
        ),
      );
    } else {
      await _pcRepository.depositPokemon(
        profileId: data.profile.id,
        pokemonId: egg.speciesId,
        experience: experience,
        currentHp: maxHp,
        selectedMoves: egg.selectedMoves,
        isShiny: egg.isShiny,
        gender: egg.gender,
        formName: egg.formName,
        nature: egg.nature,
        abilities: egg.ability == null ? const [] : [egg.ability!],
        loyalty: loyalty,
        notes: egg.inheritedMoves.isEmpty
            ? 'Nato da un uovo.'
            : 'Nato da un uovo. Mosse ereditate: ${egg.inheritedMoves.join(', ')}.',
      );
    }
    await _eggRepository.deleteEgg(data.profile.id, egg.id);
    await _reload(
      message:
          '${_displayName(pokemon: pokemon, formName: egg.formName)} si è schiuso ed è stato aggiunto ${emptySlot == null ? 'al PC' : 'alla squadra'} con Lealtà +$loyalty.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const HomeLeadingButton(),
        title: const Text('Allevamento e uova'),
        actions: const [HomeAppBarAction()],
      ),
      body: FutureBuilder<_BreedingScreenData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Errore: ${snapshot.error}'),
              ),
            );
          }
          final data = snapshot.data!;
          final compatibility = _compatibility(data);
          final first = _candidateFor(data, _firstKey);
          final second = _candidateFor(data, _secondKey);
          final modifier = _breedingService.breedingRollModifier(data.profile);
          final dc = first == null || second == null
              ? null
              : _breedingService.successDc(first.loyalty + second.loyalty);

          return RefreshIndicator(
            onRefresh: () => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _RulesCard(
                  profile: data.profile,
                  rollModifier: modifier,
                  incubationAdvantage:
                      _breedingService.hasIncubationAdvantage(data.profile),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'NUOVO TENTATIVO',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Seleziona due Pokémon posseduti. L’app controlla Lealtà, sesso, Ditto e Gruppi Uova.',
                        ),
                        const SizedBox(height: 12),
                        _CandidateDropdown(
                          label: 'Primo genitore',
                          value: _firstKey,
                          candidates: data.candidates,
                          onChanged: (value) => setState(() {
                            _firstKey = value;
                            _message = null;
                          }),
                        ),
                        const SizedBox(height: 10),
                        _CandidateDropdown(
                          label: 'Secondo genitore',
                          value: _secondKey,
                          candidates: data.candidates,
                          onChanged: (value) => setState(() {
                            _secondKey = value;
                            _message = null;
                          }),
                        ),
                        if (compatibility != null) ...[
                          const SizedBox(height: 12),
                          _CompatibilityCard(
                            compatibility: compatibility,
                            resultPokemon: compatibility.childSpeciesId == null
                                ? null
                                : data.catalogById[
                                    compatibility.childSpeciesId!
                                  ],
                            dc: dc,
                            modifier: modifier,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            FilledButton.icon(
                              onPressed: compatibility?.isCompatible == true
                                  ? () => _attemptBreeding(data)
                                  : null,
                              icon: const Icon(Icons.casino_outlined),
                              label: const Text('TIRA IL D20'),
                            ),
                            SizedBox(
                              width: 145,
                              child: TextField(
                                controller: _manualRollController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Risultato d20',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            OutlinedButton(
                              onPressed: compatibility?.isCompatible == true
                                  ? () {
                                      final roll = int.tryParse(
                                        _manualRollController.text.trim(),
                                      );
                                      if (roll == null) {
                                        setState(() {
                                          _message =
                                              'Inserisci il risultato del d20.';
                                        });
                                        return;
                                      }
                                      _attemptBreeding(
                                        data,
                                        manualRoll: roll,
                                      );
                                    }
                                  : null,
                              child: const Text('USA IL TIRO'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(_message!),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  'UOVA IN INCUBAZIONE (${data.eggs.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ogni uovo occupa un Pokéslot secondo il manuale. Il limite resta sotto il controllo del tavolo.',
                ),
                const SizedBox(height: 8),
                if (data.eggs.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Non ci sono uova. Completa con successo un tentativo di allevamento.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  for (final egg in data.eggs) ...[
                    _EggCard(
                      egg: egg,
                      pokemon: data.catalogById[egg.speciesId],
                      incubationAdvantage:
                          _breedingService.hasIncubationAdvantage(data.profile),
                      onAdvance: () => _advanceEgg(data, egg),
                      onHatch: () => _hatchEgg(data, egg),
                      onDelete: () => _deleteEgg(data, egg),
                      onIncubatorChanged: (incubator) => _updateEgg(
                        data,
                        egg.copyWith(incubator: incubator),
                      ),
                      onCarriedChanged: (value) => _updateEgg(
                        data,
                        egg.copyWith(carriedEntireIncubation: value),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }

  List<String> _knownMoves({
    required Pokemon pokemon,
    required int experience,
    required List<String> selectedMoves,
  }) {
    if (selectedMoves.isNotEmpty) return selectedMoves.take(4).toList();
    final level = LevelProgression.levelFromExperience(experience);
    final moves = <String>[...pokemon.moves.startingMoves];
    final learned = pokemon.moves.levelMoves.entries
        .where((entry) => entry.key <= level)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final entry in learned) {
      moves.addAll(entry.value);
    }
    return moves.toSet().take(4).toList();
  }

  String _displayName({
    String? nickname,
    required Pokemon pokemon,
    String? formName,
  }) {
    final trimmed = nickname?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;
    final form = formName?.trim() ?? '';
    return form.isEmpty ? pokemon.name : '${pokemon.name} ($form)';
  }

  String _signed(int value) => value >= 0 ? '+$value' : '$value';
}

class _RulesCard extends StatelessWidget {
  const _RulesCard({
    required this.profile,
    required this.rollModifier,
    required this.incubationAdvantage,
  });

  final UserProfile profile;
  final int rollModifier;
  final bool incubationAdvantage;

  @override
  Widget build(BuildContext context) {
    final breeder = profile.trainerPath == 'Pokémon Breeder';
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ALLEVAMENTO POKÉMON',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Servono Lealtà +2, sesso compatibile e un Gruppo Uova condiviso. Ditto ignora sesso e Gruppo Uova; Undiscovered non può riprodursi.',
            ),
            if (breeder || rollModifier != 0 || incubationAdvantage) ...[
              const SizedBox(height: 10),
              Text(
                'Pokémon Breeder: tiro di accoppiamento ${rollModifier >= 0 ? '+' : ''}$rollModifier${incubationAdvantage ? ' · vantaggio ai d100 di incubazione' : ''}.',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CandidateDropdown extends StatelessWidget {
  const _CandidateDropdown({
    required this.label,
    required this.value,
    required this.candidates,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<BreedingCandidate> candidates;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: candidates.any((candidate) => candidate.key == value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: [
        for (final candidate in candidates)
          DropdownMenuItem(
            value: candidate.key,
            child: Text(
              '${candidate.displayName} · ${candidate.genderLabel} · Lealtà ${candidate.loyalty >= 0 ? '+' : ''}${candidate.loyalty} · ${candidate.location}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _CompatibilityCard extends StatelessWidget {
  const _CompatibilityCard({
    required this.compatibility,
    required this.resultPokemon,
    required this.dc,
    required this.modifier,
  });

  final BreedingCompatibility compatibility;
  final Pokemon? resultPokemon;
  final int? dc;
  final int modifier;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final compatible = compatibility.isCompatible;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: compatible ? colors.primaryContainer : colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              compatible ? 'COMPATIBILI' : 'NON COMPATIBILI',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            if (compatible) ...[
              Text(
                'Gruppo: ${compatibility.sharedEggGroups.join(', ')} · Risultato: ${resultPokemon?.name ?? '#${compatibility.childSpeciesId}'}',
              ),
              if (dc != null)
                Text(
                  'Prova: d20 ${modifier >= 0 ? '+' : ''}$modifier contro CD $dc.',
                ),
            ] else
              for (final error in compatibility.errors) Text('• $error'),
          ],
        ),
      ),
    );
  }
}

class _EggCard extends StatelessWidget {
  const _EggCard({
    required this.egg,
    required this.pokemon,
    required this.incubationAdvantage,
    required this.onAdvance,
    required this.onHatch,
    required this.onDelete,
    required this.onIncubatorChanged,
    required this.onCarriedChanged,
  });

  final BreedingEgg egg;
  final Pokemon? pokemon;
  final bool incubationAdvantage;
  final VoidCallback onAdvance;
  final VoidCallback onHatch;
  final VoidCallback onDelete;
  final ValueChanged<EggIncubator> onIncubatorChanged;
  final ValueChanged<bool> onCarriedChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (pokemon != null)
                  PokemonAssetImage(
                    pokemon: pokemon!,
                    formName: egg.formName,
                    size: 64,
                  )
                else
                  const SizedBox(
                    width: 64,
                    height: 64,
                    child: Icon(Icons.egg_outlined, size: 48),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        egg.isReady
                            ? 'Uovo pronto a schiudersi'
                            : 'Uovo di ${pokemon?.name ?? '#${egg.speciesId}'}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text('Genitori: ${egg.parentNames.join(' + ')}'),
                      Text(
                        egg.isReady
                            ? 'Incubazione completata'
                            : '${egg.incubationRemaining}/${egg.hatchTime} punti rimanenti',
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Elimina uovo',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: egg.progress, minHeight: 8),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(egg.nature)),
                if (egg.gender != null) Chip(label: Text(egg.gender!)),
                if (egg.ability != null) Chip(label: Text(egg.ability!)),
              ],
            ),
            if (egg.inheritedMoves.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Mosse ereditate: ${egg.inheritedMoves.join(', ')}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
            const SizedBox(height: 10),
            DropdownButtonFormField<EggIncubator>(
              value: egg.incubator,
              decoration: const InputDecoration(
                labelText: 'Incubatore',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                for (final incubator in EggIncubator.values)
                  DropdownMenuItem(
                    value: incubator,
                    child: Text(
                      incubator.extraD20 == 0
                          ? incubator.label
                          : '${incubator.label} (+${incubator.extraD20}d20)',
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value != null) onIncubatorChanged(value);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Trasportato per tutta l’incubazione'),
              subtitle: const Text(
                'Attivo: nascerà con Lealtà +2. Disattivo: Lealtà +1.',
              ),
              value: egg.carriedEntireIncubation,
              onChanged: onCarriedChanged,
            ),
            const SizedBox(height: 4),
            if (egg.isReady)
              FilledButton.icon(
                onPressed: onHatch,
                icon: const Icon(Icons.egg_alt_outlined),
                label: const Text('FAI SCHIUDERE'),
              )
            else
              FilledButton.icon(
                onPressed: onAdvance,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  incubationAdvantage
                      ? 'AVANZA INCUBAZIONE (2d100, migliore)'
                      : 'AVANZA INCUBAZIONE (1d100)',
                ),
              ),
            if (egg.isReady) ...[
              const SizedBox(height: 6),
              Text(
                'Lo spazio libero in squadra viene usato per primo; altrimenti il Pokémon va nel PC.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BreedingScreenData {
  const _BreedingScreenData({
    required this.profile,
    required this.catalog,
    required this.catalogById,
    required this.team,
    required this.candidates,
    required this.eggs,
    required this.speciesData,
  });

  final UserProfile profile;
  final List<Pokemon> catalog;
  final Map<int, Pokemon> catalogById;
  final List<TeamSlot> team;
  final List<BreedingCandidate> candidates;
  final List<BreedingEgg> eggs;
  final Map<int, BreedingSpeciesData> speciesData;
}
'''

BREEDING_SERVICE_TEST = r'''import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:pokedex_5e_ita/models/breeding_candidate.dart';
import 'package:pokedex_5e_ita/models/breeding_egg.dart';
import 'package:pokedex_5e_ita/models/breeding_species_data.dart';
import 'package:pokedex_5e_ita/models/pokemon.dart';
import 'package:pokedex_5e_ita/models/pokemon_attributes.dart';
import 'package:pokedex_5e_ita/models/pokemon_moves.dart';
import 'package:pokedex_5e_ita/models/user_profile.dart';
import 'package:pokedex_5e_ita/services/breeding_service.dart';

void main() {
  const service = BreedingService();

  test('accetta sesso opposto, Lealtà +2 e Gruppo Uova condiviso', () {
    final result = service.compatibility(
      first: _candidate('a', gender: 'Male', pokemonId: 1),
      second: _candidate('b', gender: 'Female', pokemonId: 2),
      speciesData: {
        1: _species(1, ['Monster'], base: 1),
        2: _species(2, ['Monster'], base: 1),
      },
      catalog: {1: _pokemon(1), 2: _pokemon(2)},
    );

    expect(result.isCompatible, isTrue);
    expect(result.childSpeciesId, 1);
    expect(result.sharedEggGroups, ['Monster']);
  });

  test('rifiuta Lealtà insufficiente e stesso sesso', () {
    final result = service.compatibility(
      first: _candidate('a', gender: 'Male', pokemonId: 1, loyalty: 1),
      second: _candidate('b', gender: 'Male', pokemonId: 2),
      speciesData: {
        1: _species(1, ['Field'], base: 1),
        2: _species(2, ['Field'], base: 2),
      },
      catalog: {1: _pokemon(1), 2: _pokemon(2)},
    );

    expect(result.isCompatible, isFalse);
    expect(result.errors.join(' '), contains('Lealtà'));
    expect(result.errors.join(' '), contains('maschio'));
  });

  test('Ditto ignora sesso e Gruppo Uova ma non può accoppiarsi con Ditto', () {
    final accepted = service.compatibility(
      first: _candidate('ditto', gender: 'Genderless', pokemonId: 132),
      second: _candidate('other', gender: 'Male', pokemonId: 25),
      speciesData: {
        132: _species(132, ['Ditto'], base: 132),
        25: _species(25, ['Field', 'Fairy'], base: 172),
      },
      catalog: {25: _pokemon(25), 132: _pokemon(132), 172: _pokemon(172)},
    );
    expect(accepted.isCompatible, isTrue);
    expect(accepted.childSpeciesId, 172);

    final rejected = service.compatibility(
      first: _candidate('ditto-a', gender: 'Genderless', pokemonId: 132),
      second: _candidate('ditto-b', gender: 'Genderless', pokemonId: 132),
      speciesData: {132: _species(132, ['Ditto'], base: 132)},
      catalog: {132: _pokemon(132)},
    );
    expect(rejected.isCompatible, isFalse);
  });

  test('calcola CD e tempi di schiusa dalla tabella del manuale', () {
    expect(service.successDc(4), 19);
    expect(service.successDc(5), 18);
    expect(service.successDc(6), 17);
    expect(service.hatchTimeForSr(0.125), 125);
    expect(service.hatchTimeForSr(0.25), 250);
    expect(service.hatchTimeForSr(0.5), 500);
    expect(service.hatchTimeForSr(1), 600);
    expect(service.hatchTimeForSr(7), 1200);
    expect(service.hatchTimeForSr(15), 2000);
  });

  test('Pokémon Breeder applica WIS al tentativo e vantaggio al d100', () {
    final profile = _profile(path: 'Pokémon Breeder', level: 5, wisdom: 16);
    expect(service.breedingRollModifier(profile), 3);
    expect(service.hasIncubationAdvantage(profile), isTrue);

    final egg = BreedingEgg(
      id: 'egg',
      speciesId: 1,
      parentNames: const ['A', 'B'],
      createdAt: DateTime(2026),
      hatchTime: 500,
      incubationRemaining: 500,
      nature: 'Hardy',
      gender: 'Male',
      ability: null,
      selectedMoves: const [],
      inheritedMoves: const [],
      incubator: EggIncubator.super,
    );
    final result = service.advanceIncubation(
      egg: egg,
      profile: profile,
      random: Random(7),
    );
    expect(result.d100Rolls, hasLength(2));
    expect(result.incubatorRolls, hasLength(3));
    expect(result.egg.incubationRemaining, lessThan(500));
  });
}

BreedingCandidate _candidate(
  String key, {
  required String gender,
  required int pokemonId,
  int loyalty = 2,
}) {
  return BreedingCandidate(
    key: key,
    pokemonId: pokemonId,
    displayName: key,
    location: 'Squadra',
    gender: gender,
    loyalty: loyalty,
    selectedMoves: const [],
    abilities: const [],
  );
}

BreedingSpeciesData _species(int id, List<String> groups, {required int base}) {
  return BreedingSpeciesData(
    speciesId: id,
    eggGroups: groups,
    baseSpeciesId: base,
    isBaby: false,
    isLegendary: false,
    isMythical: false,
  );
}

Pokemon _pokemon(int id) {
  return Pokemon(
    id: id,
    name: 'Pokemon $id',
    types: const ['Normal'],
    armorClass: 10,
    hitPoints: 10,
    size: 'Tiny',
    speed: 30,
    attributes: const PokemonAttributes(
      strength: 10,
      dexterity: 10,
      constitution: 10,
      intelligence: 10,
      wisdom: 10,
      charisma: 10,
    ),
    abilities: const ['Ability'],
    hiddenAbility: null,
    skills: const [],
    savingThrows: const [],
    moves: const PokemonMoves(
      startingMoves: ['Tackle'],
      levelMoves: {},
      tmMoves: [],
      eggMoves: [],
    ),
    hitDice: 6,
    sr: 0.25,
    minLevelFound: 1,
  );
}

UserProfile _profile({
  required String path,
  required int level,
  required int wisdom,
}) {
  final now = DateTime(2026);
  return UserProfile(
    id: 'profile',
    name: 'Trainer',
    createdAt: now,
    updatedAt: now,
    trainerLevel: level,
    trainerPath: path,
    abilityScores: {
      'STR': 10,
      'DEX': 10,
      'CON': 10,
      'INT': 10,
      'WIS': wisdom,
      'CHA': 10,
    },
  );
}
'''

BREEDING_MODEL_TEST = r'''import 'package:flutter_test/flutter_test.dart';

import 'package:pokedex_5e_ita/models/breeding_egg.dart';

void main() {
  test('BreedingEgg mantiene incubazione e contenuto nel JSON', () {
    final source = BreedingEgg(
      id: 'egg-1',
      speciesId: 403,
      formName: 'Base',
      parentNames: const ['Raticate', 'Luxio'],
      createdAt: DateTime.utc(2026, 7, 14),
      hatchTime: 250,
      incubationRemaining: 120,
      nature: 'Jolly',
      gender: 'Female',
      ability: 'Rivalry',
      selectedMoves: const ['Tackle', 'Quick Attack'],
      inheritedMoves: const ['Quick Attack'],
      incubator: EggIncubator.plus,
      carriedEntireIncubation: false,
    );

    final decoded = BreedingEgg.fromJson(source.toJson());
    expect(decoded.id, 'egg-1');
    expect(decoded.speciesId, 403);
    expect(decoded.incubationRemaining, 120);
    expect(decoded.incubator, EggIncubator.plus);
    expect(decoded.inheritedMoves, ['Quick Attack']);
    expect(decoded.carriedEntireIncubation, isFalse);
    expect(decoded.progress, closeTo(0.52, 0.001));
  });
}
'''

BREEDING_DATA_TEST = r'''import 'package:flutter_test/flutter_test.dart';

import 'package:pokedex_5e_ita/models/breeding_species_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('il catalogo Gruppi Uova include specie comuni e casi speciali', () async {
    final data = await BreedingDataService().load();
    expect(data.length, greaterThan(900));
    expect(data[1]?.eggGroups, containsAll(['Monster', 'Grass']));
    expect(data[132]?.isDitto, isTrue);
    expect(data[150]?.isUndiscovered, isTrue);
    expect(data[26]?.baseSpeciesId, 172);
  });
}
'''


def write_new_files() -> None:
    files = {
        "lib/models/breeding_egg.dart": BREEDING_EGG,
        "lib/models/breeding_candidate.dart": BREEDING_CANDIDATE,
        "lib/models/breeding_species_data.dart": BREEDING_DATA,
        "lib/repositories/breeding_egg_repository.dart": BREEDING_REPOSITORY,
        "lib/services/breeding_service.dart": BREEDING_SERVICE,
        "lib/screens/breeding/breeding_screen.dart": BREEDING_SCREEN,
        "test/breeding_service_test.dart": BREEDING_SERVICE_TEST,
        "test/breeding_egg_test.dart": BREEDING_MODEL_TEST,
        "test/breeding_data_test.dart": BREEDING_DATA_TEST,
    }
    for relative_path, content in files.items():
        path = Path(relative_path)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")


def patch_pokemon_moves() -> None:
    path = Path("lib/models/pokemon_moves.dart")
    text = path.read_text(encoding="utf-8")
    text = replace_once(
        text,
        "    required this.tmMoves,\n  });",
        "    required this.tmMoves,\n    this.eggMoves = const [],\n  });",
        "pokemon moves constructor",
    )
    text = replace_once(
        text,
        "  final List<int> tmMoves;",
        "  final List<int> tmMoves;\n  final List<String> eggMoves;",
        "pokemon moves field",
    )
    text = replace_once(
        text,
        "      tmMoves: _readIntList(json['TM']),\n    );",
        "      tmMoves: _readIntList(json['TM']),\n      eggMoves: _readStringList(json['egg'] ?? json['Egg Moves']),\n    );",
        "legacy egg moves",
    )
    text = replace_once(
        text,
        "      tmMoves: _readIntList(json['tm']),\n    );",
        "      tmMoves: _readIntList(json['tm']),\n      eggMoves: _readStringList(json['egg'] ?? json['eggMoves']),\n    );",
        "web egg moves",
    )
    path.write_text(text, encoding="utf-8")


def patch_hive_boxes() -> None:
    path = Path("lib/database/hive_boxes.dart")
    text = path.read_text(encoding="utf-8")
    text = replace_once(
        text,
        "  static const masterBattleSessions = 'master_battle_sessions';",
        "  static const masterBattleSessions = 'master_battle_sessions';\n  static const breedingEggs = 'breeding_eggs';",
        "hive breeding box",
    )
    path.write_text(text, encoding="utf-8")


def patch_home() -> None:
    path = Path("lib/screens/home/home_screen.dart")
    text = path.read_text(encoding="utf-8")
    text = replace_once(
        text,
        "import '../capture/capture_pokemon_screen.dart';",
        "import '../capture/capture_pokemon_screen.dart';\nimport '../breeding/breeding_screen.dart';",
        "home breeding import",
    )
    anchor = """              _HomeActionButton(
                icon: Icons.computer,
                title: 'PC Pokémon',
                subtitle: 'Gestisci i Pokémon catturati fuori squadra.',
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PokemonPcScreen()),
                  );
                  await _loadDashboard();
                },
              ),
"""
    addition = anchor + """              _HomeActionButton(
                icon: Icons.egg_alt_outlined,
                title: 'Allevamento e uova',
                subtitle:
                    'Verifica i genitori, crea uova, avanza l’incubazione e fai schiudere i Pokémon.',
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BreedingScreen()),
                  );
                  await _loadDashboard();
                },
              ),
"""
    text = replace_once(text, anchor, addition, "home breeding action")
    path.write_text(text, encoding="utf-8")


def patch_profile_backup() -> None:
    path = Path("lib/models/profile_backup.dart")
    text = path.read_text(encoding="utf-8")
    text = replace_once(
        text,
        "import 'battle_session.dart';",
        "import 'battle_session.dart';\nimport 'breeding_egg.dart';",
        "backup egg import",
    )
    text = replace_once(
        text,
        "  static const int currentFormatVersion = 4;",
        "  static const int currentFormatVersion = 5;",
        "backup format",
    )
    text = replace_once(
        text,
        "    this.masterBattleSession,\n  });",
        "    this.masterBattleSession,\n    this.breedingEggs = const [],\n  });",
        "backup constructor eggs",
    )
    text = replace_once(
        text,
        "  final MasterBattleSession? masterBattleSession;",
        "  final MasterBattleSession? masterBattleSession;\n  final List<BreedingEgg> breedingEggs;",
        "backup eggs field",
    )
    text = replace_once(
        text,
        "      'masterBattleSession': masterBattleSession?.toJson(),",
        "      'masterBattleSession': masterBattleSession?.toJson(),\n      'breedingEggs': breedingEggs.map((egg) => egg.toJson()).toList(growable: false),",
        "backup eggs json",
    )
    text = replace_once(
        text,
        "      masterBattleSession: json['masterBattleSession'] is Map\n          ? MasterBattleSession.fromJson(\n              Map<String, dynamic>.from(json['masterBattleSession'] as Map),\n            )\n          : null,",
        "      masterBattleSession: json['masterBattleSession'] is Map\n          ? MasterBattleSession.fromJson(\n              Map<String, dynamic>.from(json['masterBattleSession'] as Map),\n            )\n          : null,\n      breedingEggs: [\n        for (final value in _readMapList(json['breedingEggs'], 'breedingEggs'))\n          BreedingEgg.fromJson(value),\n      ],",
        "backup eggs parsing",
    )
    validation_anchor = """    final savedEncounterIds = <String>{};
    for (final encounter in savedEncounters) {
"""
    validation = """    final eggIds = <String>{};
    for (final egg in breedingEggs) {
      if (egg.id.trim().isEmpty ||
          egg.speciesId <= 0 ||
          egg.hatchTime <= 0 ||
          egg.incubationRemaining < 0 ||
          egg.incubationRemaining > egg.hatchTime) {
        throw const FormatException(
          'Il backup contiene un uovo Pokémon non valido.',
        );
      }
      if (!eggIds.add(egg.id)) {
        throw FormatException('L’uovo ${egg.id} è presente più volte.');
      }
    }

""" + validation_anchor
    text = replace_once(text, validation_anchor, validation, "backup egg validation")
    path.write_text(text, encoding="utf-8")


def patch_profile_backup_service() -> None:
    path = Path("lib/services/profile_backup_service.dart")
    text = path.read_text(encoding="utf-8")
    text = replace_once(
        text,
        "import '../repositories/battle_session_repository.dart';",
        "import '../repositories/battle_session_repository.dart';\nimport '../repositories/breeding_egg_repository.dart';",
        "backup service egg import",
    )
    text = replace_once(
        text,
        "    MasterBattleSessionRepository? masterBattleSessionRepository,\n  })",
        "    MasterBattleSessionRepository? masterBattleSessionRepository,\n    BreedingEggRepository? breedingEggRepository,\n  })",
        "backup service constructor param",
    )
    text = replace_once(
        text,
        "        _masterBattleSessionRepository =\n            masterBattleSessionRepository ?? MasterBattleSessionRepository();",
        "        _masterBattleSessionRepository =\n            masterBattleSessionRepository ?? MasterBattleSessionRepository(),\n        _breedingEggRepository =\n            breedingEggRepository ?? BreedingEggRepository();",
        "backup service initializer",
    )
    text = replace_once(
        text,
        "  final MasterBattleSessionRepository _masterBattleSessionRepository;",
        "  final MasterBattleSessionRepository _masterBattleSessionRepository;\n  final BreedingEggRepository _breedingEggRepository;",
        "backup service egg field",
    )
    text = replace_once(
        text,
        "    final masterBattleSession = await _masterBattleSessionRepository.getSession(\n      profileId,\n    );",
        "    final masterBattleSession = await _masterBattleSessionRepository.getSession(\n      profileId,\n    );\n    final breedingEggs = await _breedingEggRepository.getEggs(profileId);",
        "backup service load eggs",
    )
    text = replace_once(
        text,
        "      masterBattleSession: masterBattleSession,\n    );",
        "      masterBattleSession: masterBattleSession,\n      breedingEggs: breedingEggs,\n    );",
        "backup service create eggs",
    )
    text = replace_once(
        text,
        "    await _savedNpcTrainerRepository.replaceTrainers(\n      destinationId,\n      backup.savedNpcTrainers,\n    );",
        "    await _savedNpcTrainerRepository.replaceTrainers(\n      destinationId,\n      backup.savedNpcTrainers,\n    );\n    await _breedingEggRepository.replaceEggs(\n      destinationId,\n      backup.breedingEggs,\n    );",
        "backup service restore eggs",
    )
    text = replace_once(
        text,
        "    await _masterBattleSessionRepository.deleteSession(profileId);",
        "    await _masterBattleSessionRepository.deleteSession(profileId);\n    await _breedingEggRepository.deleteEggs(profileId);",
        "backup service clear eggs",
    )
    path.write_text(text, encoding="utf-8")


def patch_backup_test() -> None:
    path = Path("test/profile_backup_test.dart")
    text = path.read_text(encoding="utf-8")
    text = replace_once(
        text,
        "import 'package:pokedex_5e_ita/models/battle_session.dart';",
        "import 'package:pokedex_5e_ita/models/battle_session.dart';\nimport 'package:pokedex_5e_ita/models/breeding_egg.dart';",
        "backup test egg import",
    )
    anchor = """      savedEncounters: [
        SavedEncounter(
"""
    # Add eggs before saved encounters to keep the existing fixture readable.
    eggs = """      breedingEggs: [
        BreedingEgg(
          id: 'egg-1',
          speciesId: 403,
          parentNames: const ['Raticate', 'Luxio'],
          createdAt: now,
          hatchTime: 250,
          incubationRemaining: 120,
          nature: 'Jolly',
          gender: 'Female',
          ability: 'Rivalry',
          selectedMoves: const ['Tackle', 'Quick Attack'],
          inheritedMoves: const ['Quick Attack'],
        ),
      ],
""" + anchor
    text = replace_once(text, anchor, eggs, "backup test eggs fixture")
    text = replace_once(
        text,
        "    expect(decoded.savedEncounters.single.name, 'Percorso 24');",
        "    expect(decoded.savedEncounters.single.name, 'Percorso 24');\n    expect(decoded.breedingEggs.single.speciesId, 403);\n    expect(decoded.breedingEggs.single.incubationRemaining, 120);",
        "backup test eggs assertions",
    )
    path.write_text(text, encoding="utf-8")


def patch_changelog() -> None:
    path = Path("CHANGELOG.md")
    text = path.read_text(encoding="utf-8")
    planned = "- sistema di allevamento, uova e incubazione;\n"
    if planned in text:
        text = text.replace(planned, "", 1)
    anchor = "- scheda compatta delle sei caratteristiche del Pokémon nel Battle Companion, con valori effettivi e modificatori pronti per prove e tiri salvezza."
    addition = anchor + "\n- sistema persistente di allevamento e uova con compatibilità dei genitori, Gruppi Uova, Ditto, tiri di successo, incubazione, incubatori e schiusa in squadra o nel PC."
    text = replace_once(text, anchor, addition, "changelog breeding")
    path.write_text(text, encoding="utf-8")


def main() -> None:
    generate_breeding_asset()
    write_new_files()
    patch_pokemon_moves()
    patch_hive_boxes()
    patch_home()
    patch_profile_backup()
    patch_profile_backup_service()
    patch_backup_test()
    patch_changelog()


if __name__ == "__main__":
    main()
