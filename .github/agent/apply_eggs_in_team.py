from pathlib import Path
import re


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: attesa 1 occorrenza, trovate {count}")
    return text.replace(old, new, 1)


def replace_regex(text: str, pattern: str, replacement: str, label: str) -> str:
    updated, count = re.subn(pattern, replacement, text, count=1, flags=re.S)
    if count != 1:
        raise RuntimeError(f"{label}: attesa 1 occorrenza, trovate {count}")
    return updated


TEAM_SLOT = r'''import 'pokemon_form_preferences.dart';

class TeamSlot {
  static const Object _unset = Object();

  final int slotIndex;
  final int? pokemonId;
  final String? eggId;
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

  TeamSlot({
    required this.slotIndex,
    required this.pokemonId,
    this.eggId,
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
  })  : assert(
          pokemonId == null || eggId == null,
          'Uno slot non può contenere contemporaneamente un Pokémon e un uovo.',
        ),
        gender = PokemonFormPreferences.normalizeGender(gender),
        formName = PokemonFormPreferences.normalizeFormName(
          formName: formName,
          gender: gender,
        ) {
    final pokemonId = this.pokemonId;
    if (pokemonId != null) {
      PokemonFormPreferences.setForm(
        pokemonId: pokemonId,
        formName: this.formName,
      );
      PokemonFormPreferences.setShiny(
        pokemonId: pokemonId,
        isShiny: isShiny,
      );
      PokemonFormPreferences.setGender(
        pokemonId: pokemonId,
        gender: this.gender,
      );
    }
  }

  bool get isPokemon => pokemonId != null;
  bool get isEgg => eggId != null;
  bool get isEmpty => pokemonId == null && eggId == null;

  Map<String, dynamic> toJson() {
    return {
      'slotIndex': slotIndex,
      'pokemonId': pokemonId,
      'eggId': eggId,
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
    };
  }

  factory TeamSlot.fromJson(Map<String, dynamic> json) {
    return TeamSlot(
      slotIndex: json['slotIndex'],
      pokemonId: json['pokemonId'],
      eggId: json['eggId']?.toString(),
      experience: json['experience'] ?? 0,
      currentHp: json['currentHp'] ?? 0,
      nickname: json['nickname'],
      selectedMoves: List<String>.from(json['selectedMoves'] ?? []),
      isShiny: json['isShiny'] ?? false,
      gender: json['gender'],
      formName: json['formName'],
      nature: json['nature'] ?? 'No Nature',
      heldItem: json['heldItem'],
      abilities: List<String>.from(json['abilities'] ?? []),
      feats: List<String>.from(json['feats'] ?? []),
      extraSkills: List<String>.from(json['extraSkills'] ?? []),
      statusEffects: List<String>.from(json['statusEffects'] ?? []),
      customAbilityScores: Map<String, int>.from(
        json['customAbilityScores'] ?? {},
      ),
      loyalty: json['loyalty'] ?? 0,
    );
  }

  TeamSlot copyWith({
    int? slotIndex,
    int? pokemonId,
    Object? eggId = _unset,
    int? experience,
    int? currentHp,
    Object? nickname = _unset,
    List<String>? selectedMoves,
    bool? isShiny,
    Object? gender = _unset,
    Object? formName = _unset,
    String? nature,
    Object? heldItem = _unset,
    List<String>? abilities,
    List<String>? feats,
    List<String>? extraSkills,
    List<String>? statusEffects,
    Map<String, int>? customAbilityScores,
    int? loyalty,
    bool clearPokemon = false,
    bool clearEgg = false,
  }) {
    final choosingPokemon = pokemonId != null;
    final choosingEgg = !identical(eggId, _unset) && eggId != null;
    final nextPokemonId = choosingEgg
        ? null
        : clearPokemon
            ? null
            : pokemonId ?? this.pokemonId;
    final nextEggId = choosingPokemon || clearEgg
        ? null
        : identical(eggId, _unset)
            ? this.eggId
            : eggId as String?;
    final pokemonChanged = pokemonId != null && pokemonId != this.pokemonId;
    final nextGender = choosingEgg || clearPokemon
        ? null
        : identical(gender, _unset)
            ? this.gender
            : gender as String?;
    final nextFormName = choosingEgg || clearPokemon ||
            (pokemonChanged && identical(formName, _unset))
        ? null
        : identical(formName, _unset)
            ? this.formName
            : formName as String?;

    return TeamSlot(
      slotIndex: slotIndex ?? this.slotIndex,
      pokemonId: nextPokemonId,
      eggId: nextEggId,
      experience: choosingEgg ? 0 : experience ?? this.experience,
      currentHp: choosingEgg ? 0 : currentHp ?? this.currentHp,
      nickname: choosingEgg
          ? null
          : identical(nickname, _unset)
              ? this.nickname
              : nickname as String?,
      selectedMoves: choosingEgg ? const [] : selectedMoves ?? this.selectedMoves,
      isShiny: choosingEgg ? false : isShiny ?? this.isShiny,
      gender: nextGender,
      formName: nextFormName,
      nature: choosingEgg ? 'No Nature' : nature ?? this.nature,
      heldItem: choosingEgg
          ? null
          : identical(heldItem, _unset)
              ? this.heldItem
              : heldItem as String?,
      abilities: choosingEgg ? const [] : abilities ?? this.abilities,
      feats: choosingEgg ? const [] : feats ?? this.feats,
      extraSkills: choosingEgg ? const [] : extraSkills ?? this.extraSkills,
      statusEffects: choosingEgg ? const [] : statusEffects ?? this.statusEffects,
      customAbilityScores:
          choosingEgg ? const {} : customAbilityScores ?? this.customAbilityScores,
      loyalty: choosingEgg ? 0 : loyalty ?? this.loyalty,
    );
  }
}
'''

TEAM_REPOSITORY = r'''import 'package:hive_flutter/hive_flutter.dart';

import '../database/hive_boxes.dart';
import '../models/pokedex_entry.dart';
import '../models/team_slot.dart';
import 'move_repository.dart';
import 'pokedex_repositry.dart';

class TeamRepository {
  TeamRepository({
    MoveRepository? moveRepository,
    PokedexRepository? pokedexRepository,
  }) : _moveRepository = moveRepository ?? MoveRepository(),
       _pokedexRepository = pokedexRepository ?? PokedexRepository();

  final MoveRepository _moveRepository;
  final PokedexRepository _pokedexRepository;

  Future<Box> _box() => Hive.openBox(HiveBoxes.teams);

  Future<List<TeamSlot>> getTeam(String profileId) async {
    final box = await _box();
    final data = box.get(profileId);

    if (data == null) {
      return List.generate(
        6,
        (index) => TeamSlot(slotIndex: index, pokemonId: null),
      );
    }

    final team = List<Map>.from(data)
        .map((item) => TeamSlot.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    final migratedTeam = await _migrateSavedMoveReferences(team);

    if (!_sameTeamMoveReferences(team, migratedTeam)) {
      await box.put(
        profileId,
        migratedTeam.map((slot) => slot.toJson()).toList(),
      );
      await box.flush();
    }

    return migratedTeam;
  }

  Future<List<TeamSlot>> _migrateSavedMoveReferences(
    List<TeamSlot> team,
  ) async {
    final migratedTeam = <TeamSlot>[];

    for (final slot in team) {
      if (!slot.isPokemon) {
        migratedTeam.add(slot);
        continue;
      }
      final migratedMoves = <String>[];

      for (final reference in slot.selectedMoves) {
        final trimmedReference = reference.trim();
        if (trimmedReference.isEmpty) continue;

        final move = await _moveRepository.getMove(trimmedReference);
        migratedMoves.add(move?.id ?? trimmedReference);
      }

      migratedTeam.add(slot.copyWith(selectedMoves: migratedMoves));
    }

    return migratedTeam;
  }

  bool _sameTeamMoveReferences(List<TeamSlot> a, List<TeamSlot> b) {
    if (a.length != b.length) return false;

    for (var index = 0; index < a.length; index++) {
      final aMoves = a[index].selectedMoves;
      final bMoves = b[index].selectedMoves;
      if (aMoves.length != bMoves.length) return false;

      for (var moveIndex = 0; moveIndex < aMoves.length; moveIndex++) {
        if (aMoves[moveIndex] != bMoves[moveIndex]) return false;
      }
    }

    return true;
  }

  Future<void> saveTeam(String profileId, List<TeamSlot> team) async {
    final box = await _box();

    await box.put(profileId, team.map((slot) => slot.toJson()).toList());
    await box.flush();
    await _pokedexRepository.registerCaughtMany(
      profileId: profileId,
      pokemon: [
        for (final slot in team)
          if (slot.pokemonId != null)
            PokedexOwnedForm(
              pokemonId: slot.pokemonId!,
              formName: slot.formName,
            ),
      ],
    );
  }

  Future<void> setPokemonInSlot({
    required String profileId,
    required int slotIndex,
    required int? pokemonId,
    int? initialCurrentHp,
  }) async {
    final team = await getTeam(profileId);

    final updatedTeam = team.map((slot) {
      if (slot.slotIndex == slotIndex) {
        final changedPokemon = slot.pokemonId != pokemonId || slot.isEgg;

        return slot.copyWith(
          pokemonId: pokemonId,
          clearPokemon: pokemonId == null,
          clearEgg: true,
          experience: changedPokemon ? 0 : slot.experience,
          currentHp: changedPokemon ? (initialCurrentHp ?? 0) : slot.currentHp,
          nickname: changedPokemon ? null : slot.nickname,
          selectedMoves: changedPokemon ? [] : slot.selectedMoves,
          isShiny: changedPokemon ? false : slot.isShiny,
          gender: changedPokemon ? null : slot.gender,
          formName: changedPokemon ? null : slot.formName,
          nature: changedPokemon ? 'No Nature' : slot.nature,
          heldItem: changedPokemon ? null : slot.heldItem,
          abilities: changedPokemon ? [] : slot.abilities,
          feats: changedPokemon ? [] : slot.feats,
          extraSkills: changedPokemon ? [] : slot.extraSkills,
          statusEffects: changedPokemon ? [] : slot.statusEffects,
          customAbilityScores: changedPokemon ? {} : slot.customAbilityScores,
          loyalty: changedPokemon ? 0 : slot.loyalty,
        );
      }

      return slot;
    }).toList();

    await saveTeam(profileId, updatedTeam);
  }

  Future<void> setEggInSlot({
    required String profileId,
    required int slotIndex,
    required String? eggId,
  }) async {
    final team = await getTeam(profileId);
    final updatedTeam = [
      for (final slot in team)
        if (slot.slotIndex == slotIndex)
          TeamSlot(slotIndex: slot.slotIndex, pokemonId: null, eggId: eggId)
        else
          slot,
    ];
    await saveTeam(profileId, updatedTeam);
  }

  Future<void> clearSlot({
    required String profileId,
    required int slotIndex,
  }) async {
    final team = await getTeam(profileId);
    final updatedTeam = [
      for (final slot in team)
        if (slot.slotIndex == slotIndex)
          TeamSlot(slotIndex: slot.slotIndex, pokemonId: null)
        else
          slot,
    ];
    await saveTeam(profileId, updatedTeam);
  }

  Future<void> updateSlot({
    required String profileId,
    required TeamSlot updatedSlot,
  }) async {
    final team = await getTeam(profileId);

    final updatedTeam = team.map((slot) {
      if (slot.slotIndex == updatedSlot.slotIndex) {
        return updatedSlot;
      }

      return slot;
    }).toList();

    await saveTeam(profileId, updatedTeam);
  }

  Future<void> deleteTeam(String profileId) async {
    final box = await _box();
    await box.delete(profileId);
    await box.flush();
  }
}
'''

BREEDING_EGG = r'''enum EggIncubator { none, basic, plus, superIncubator }

extension EggIncubatorDetails on EggIncubator {
  String get label => switch (this) {
    EggIncubator.none => 'Nessuno',
    EggIncubator.basic => 'Basic',
    EggIncubator.plus => 'Plus',
    EggIncubator.superIncubator => 'Super',
  };

  int get extraD20 => switch (this) {
    EggIncubator.none => 0,
    EggIncubator.basic => 1,
    EggIncubator.plus => 2,
    EggIncubator.superIncubator => 3,
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
    this.isInDayCare = false,
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
  final bool isInDayCare;

  bool get isReady => incubationRemaining <= 0;

  double get progress {
    if (hatchTime <= 0) return 1;
    return (1 - incubationRemaining / hatchTime).clamp(0.0, 1.0);
  }

  BreedingEgg copyWith({
    int? incubationRemaining,
    EggIncubator? incubator,
    bool? carriedEntireIncubation,
    bool? isInDayCare,
    Object? formName = _unset,
  }) {
    return BreedingEgg(
      id: id,
      speciesId: speciesId,
      formName: identical(formName, _unset)
          ? this.formName
          : formName as String?,
      parentNames: parentNames,
      createdAt: createdAt,
      hatchTime: hatchTime,
      incubationRemaining: incubationRemaining ?? this.incubationRemaining,
      nature: nature,
      gender: gender,
      ability: ability,
      selectedMoves: selectedMoves,
      inheritedMoves: inheritedMoves,
      isShiny: isShiny,
      incubator: incubator ?? this.incubator,
      carriedEntireIncubation:
          carriedEntireIncubation ?? this.carriedEntireIncubation,
      isInDayCare: isInDayCare ?? this.isInDayCare,
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
      'isInDayCare': isInDayCare,
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
      isInDayCare: json['isInDayCare'] as bool? ?? false,
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
'''

Path('lib/models/team_slot.dart').write_text(TEAM_SLOT, encoding='utf-8')
Path('lib/repositories/team_repository.dart').write_text(TEAM_REPOSITORY, encoding='utf-8')
Path('lib/models/breeding_egg.dart').write_text(BREEDING_EGG, encoding='utf-8')

# Breeding service: eggs occupy team slots too.
path = Path('lib/services/breeding_service.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    '      if (slot.pokemonId == null) return slot;',
    '      if (slot.isEmpty) return slot;',
    'free team slot includes eggs',
)
text = replace_once(
    text,
    "  List<TeamSlot> occupiedLockedTeamSlots({",
    "  TeamSlot? teamSlotForEgg({\n"
    "    required List<TeamSlot> team,\n"
    "    required String eggId,\n"
    "  }) {\n"
    "    for (final slot in team) {\n"
    "      if (slot.eggId == eggId) return slot;\n"
    "    }\n"
    "    return null;\n"
    "  }\n\n"
    "  List<TeamSlot> occupiedLockedTeamSlots({",
    'team slot lookup for egg',
)
path.write_text(text, encoding='utf-8')

# Breeding screen.
path = Path('lib/screens/breeding/breeding_screen.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    "  String? _message;\n",
    "  String? _message;\n  bool _useDayCare = false;\n",
    'day care state',
)
new_load = r'''  Future<_BreedingScreenData> _load() async {
    final profile = await _profileRepository.getActiveProfile();
    final results = await Future.wait([
      _pokemonRepository.getAllPokemon(),
      _teamRepository.getTeam(profile.id),
      _pcRepository.getPokemon(profile.id),
      _eggRepository.getEggs(profile.id),
      _dataService.load(),
    ]);
    final catalog = results[0] as List<Pokemon>;
    var team = results[1] as List<TeamSlot>;
    var pc = results[2] as List<PcPokemon>;
    var eggs = results[3] as List<BreedingEgg>;
    final unlockedPokeslots =
        TrainerProgression.pokeslotsForLevel(profile.trainerLevel);

    final occupiedLockedSlots = _breedingService.occupiedLockedTeamSlots(
      team: team,
      unlockedPokeslots: unlockedPokeslots,
    );
    for (final slot in occupiedLockedSlots) {
      await _pcRepository.depositTeamSlot(profileId: profile.id, slot: slot);
      await _teamRepository.clearSlot(
        profileId: profile.id,
        slotIndex: slot.slotIndex,
      );
    }
    if (occupiedLockedSlots.isNotEmpty) {
      team = await _teamRepository.getTeam(profile.id);
      pc = await _pcRepository.getPokemon(profile.id);
    }

    var eggStorageChanged = false;
    var eggsById = {for (final egg in eggs) egg.id: egg};
    for (final slot in [...team]) {
      final eggId = slot.eggId;
      if (eggId == null) continue;
      final egg = eggsById[eggId];
      if (egg == null) {
        await _teamRepository.clearSlot(
          profileId: profile.id,
          slotIndex: slot.slotIndex,
        );
        eggStorageChanged = true;
        continue;
      }
      if (slot.slotIndex >= unlockedPokeslots || egg.isInDayCare) {
        await _teamRepository.clearSlot(
          profileId: profile.id,
          slotIndex: slot.slotIndex,
        );
        if (!egg.isInDayCare) {
          await _eggRepository.saveEgg(
            profile.id,
            egg.copyWith(
              isInDayCare: true,
              carriedEntireIncubation: false,
            ),
          );
        }
        eggStorageChanged = true;
      }
    }
    if (eggStorageChanged) {
      team = await _teamRepository.getTeam(profile.id);
      eggs = await _eggRepository.getEggs(profile.id);
      eggsById = {for (final egg in eggs) egg.id: egg};
    }

    for (final egg in [...eggs]) {
      if (egg.isInDayCare) continue;
      final assigned = _breedingService.teamSlotForEgg(
        team: team,
        eggId: egg.id,
      );
      if (assigned != null) continue;
      final freeSlot = _breedingService.firstFreeUnlockedTeamSlot(
        team: team,
        unlockedPokeslots: unlockedPokeslots,
      );
      if (freeSlot == null) {
        await _eggRepository.saveEgg(
          profile.id,
          egg.copyWith(
            isInDayCare: true,
            carriedEntireIncubation: false,
          ),
        );
      } else {
        await _teamRepository.setEggInSlot(
          profileId: profile.id,
          slotIndex: freeSlot.slotIndex,
          eggId: egg.id,
        );
      }
      eggStorageChanged = true;
      team = await _teamRepository.getTeam(profile.id);
    }
    if (eggStorageChanged) {
      eggs = await _eggRepository.getEggs(profile.id);
    }

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

'''
text = replace_regex(
    text,
    r"  Future<_BreedingScreenData> _load\(\) async \{.*?\n  \}\n\n  Future<void> _reload",
    new_load + "  Future<void> _reload",
    'replace breeding load',
)
new_attempt = r'''  Future<void> _attemptBreeding(
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

    final unlockedPokeslots = TrainerProgression.pokeslotsForLevel(
      data.profile.trainerLevel,
    );
    final freeSlot = _breedingService.firstFreeUnlockedTeamSlot(
      team: data.team,
      unlockedPokeslots: unlockedPokeslots,
    );
    if (!_useDayCare && freeSlot == null) {
      setState(() {
        _message =
            'Non hai un Pokéslot libero. Libera uno slot oppure usa la Pensione Pokémon.';
      });
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
        _message =
            'Tentativo fallito: d20 $roll ${_signed(modifier)} = $total contro CD $dc.';
      });
      return;
    }

    try {
      final created = _breedingService.createEgg(
        first: first,
        second: second,
        compatibility: compatibility,
        catalog: data.catalogById,
        random: _random,
      );
      final egg = created.copyWith(
        isInDayCare: _useDayCare,
        carriedEntireIncubation: !_useDayCare,
      );
      await _eggRepository.saveEgg(data.profile.id, egg);
      if (!_useDayCare && freeSlot != null) {
        await _teamRepository.setEggInSlot(
          profileId: data.profile.id,
          slotIndex: freeSlot.slotIndex,
          eggId: egg.id,
        );
      }
      final destination = _useDayCare
          ? 'affidato alla Pensione Pokémon'
          : 'inserito nello slot squadra ${freeSlot!.slotIndex + 1}';
      _manualRollController.clear();
      _firstKey = null;
      _secondKey = null;
      _useDayCare = false;
      await _reload(
        message:
            'Successo: d20 $roll ${_signed(modifier)} = $total contro CD $dc. Uovo creato e $destination.',
      );
    } catch (error) {
      setState(() => _message = error.toString());
    }
  }

  TeamSlot? _teamSlotForEgg(_BreedingScreenData data, BreedingEgg egg) {
    return _breedingService.teamSlotForEgg(team: data.team, eggId: egg.id);
  }

  Future<void> _moveEggToDayCare(
    _BreedingScreenData data,
    BreedingEgg egg,
  ) async {
    final slot = _teamSlotForEgg(data, egg);
    if (slot != null) {
      await _teamRepository.clearSlot(
        profileId: data.profile.id,
        slotIndex: slot.slotIndex,
      );
    }
    await _eggRepository.saveEgg(
      data.profile.id,
      egg.copyWith(isInDayCare: true, carriedEntireIncubation: false),
    );
    await _reload(message: 'Uovo affidato alla Pensione Pokémon.');
  }

  Future<void> _moveEggToTeam(
    _BreedingScreenData data,
    BreedingEgg egg,
  ) async {
    final unlockedPokeslots = TrainerProgression.pokeslotsForLevel(
      data.profile.trainerLevel,
    );
    final freeSlot = _breedingService.firstFreeUnlockedTeamSlot(
      team: data.team,
      unlockedPokeslots: unlockedPokeslots,
    );
    if (freeSlot == null) {
      setState(() => _message = 'Non hai un Pokéslot libero per ritirare l’uovo.');
      return;
    }
    await _teamRepository.setEggInSlot(
      profileId: data.profile.id,
      slotIndex: freeSlot.slotIndex,
      eggId: egg.id,
    );
    await _eggRepository.saveEgg(
      data.profile.id,
      egg.copyWith(isInDayCare: false),
    );
    await _reload(
      message: 'Uovo ritirato nello slot squadra ${freeSlot.slotIndex + 1}.',
    );
  }

'''
text = replace_regex(
    text,
    r"  Future<void> _attemptBreeding\(.*?\n  \}\n\n  Future<void> _advanceEgg",
    new_attempt + "  Future<void> _advanceEgg",
    'replace breeding attempt',
)
text = replace_once(
    text,
    "    if (!mounted || confirmed != true) return;\n    await _eggRepository.deleteEgg(data.profile.id, egg.id);",
    "    if (!mounted || confirmed != true) return;\n"
    "    final slot = _teamSlotForEgg(data, egg);\n"
    "    if (slot != null) {\n"
    "      await _teamRepository.clearSlot(\n"
    "        profileId: data.profile.id,\n"
    "        slotIndex: slot.slotIndex,\n"
    "      );\n"
    "    }\n"
    "    await _eggRepository.deleteEgg(data.profile.id, egg.id);",
    'delete egg clears slot',
)
new_hatch = r'''  Future<void> _hatchEgg(_BreedingScreenData data, BreedingEgg egg) async {
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
    final eggSlot = _teamSlotForEgg(data, egg);

    if (eggSlot != null) {
      await _teamRepository.updateSlot(
        profileId: data.profile.id,
        updatedSlot: TeamSlot(
          slotIndex: eggSlot.slotIndex,
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
            ? 'Nato da un uovo nella Pensione Pokémon.'
            : 'Nato da un uovo nella Pensione Pokémon. Mosse ereditate: ${egg.inheritedMoves.join(', ')}.',
      );
    }
    await _eggRepository.deleteEgg(data.profile.id, egg.id);
    final destination = eggSlot == null
        ? 'è stato inviato al PC dalla Pensione Pokémon'
        : 'ha sostituito l’uovo nello slot squadra ${eggSlot.slotIndex + 1}';
    await _reload(
      message:
          '${_displayName(pokemon: pokemon, formName: egg.formName)} si è schiuso, $destination, con Lealtà +$loyalty.',
    );
  }

'''
text = replace_regex(
    text,
    r"  Future<void> _hatchEgg\(.*?\n  \}\n\n  @override",
    new_hatch + "  @override",
    'replace hatch behavior',
)
text = replace_once(
    text,
    "          final dc = first == null || second == null\n              ? null\n              : _breedingService.successDc(first.loyalty + second.loyalty);",
    "          final dc = first == null || second == null\n"
    "              ? null\n"
    "              : _breedingService.successDc(first.loyalty + second.loyalty);\n"
    "          final unlockedPokeslots = TrainerProgression.pokeslotsForLevel(\n"
    "            data.profile.trainerLevel,\n"
    "          );\n"
    "          final freeSlot = _breedingService.firstFreeUnlockedTeamSlot(\n"
    "            team: data.team,\n"
    "            unlockedPokeslots: unlockedPokeslots,\n"
    "          );\n"
    "          final canStoreEgg = _useDayCare || freeSlot != null;",
    'build free slot',
)
text = replace_once(
    text,
    "                        if (compatibility != null) ...[",
    "                        SwitchListTile(\n"
    "                          contentPadding: EdgeInsets.zero,\n"
    "                          title: const Text('Usa Pensione Pokémon'),\n"
    "                          subtitle: Text(\n"
    "                            _useDayCare\n"
    "                                ? 'L’uovo non occupa un Pokéslot e alla schiusa il Pokémon andrà nel PC.'\n"
    "                                : freeSlot == null\n"
    "                                    ? 'Nessun Pokéslot libero: attiva la Pensione per poter ottenere l’uovo.'\n"
    "                                    : 'L’uovo occuperà lo slot squadra ${freeSlot.slotIndex + 1}.'\n"
    "                          ),\n"
    "                          value: _useDayCare,\n"
    "                          onChanged: (value) => setState(() {\n"
    "                            _useDayCare = value;\n"
    "                            _message = null;\n"
    "                          }),\n"
    "                        ),\n"
    "                        if (compatibility != null) ...[",
    'day care switch UI',
)
text = text.replace(
    "onPressed: compatibility?.isCompatible == true\n                                   ? () => _attemptBreeding(data)\n                                   : null,",
    "onPressed: compatibility?.isCompatible == true && canStoreEgg\n                                   ? () => _attemptBreeding(data)\n                                   : null,",
    1,
)
text = text.replace(
    "onPressed: compatibility?.isCompatible == true\n                                   ? () {",
    "onPressed: compatibility?.isCompatible == true && canStoreEgg\n                                   ? () {",
    1,
)
text = replace_once(
    text,
    "                  const Text(\n                    'Ogni uovo occupa un Pokéslot secondo il manuale. Il limite resta sotto il controllo del tavolo.',\n                  ),",
    "                  const Text(\n"
    "                    'Un uovo trasportato occupa davvero un Pokéslot. Un uovo affidato alla Pensione resta fuori dalla squadra e alla schiusa il Pokémon viene inviato al PC.',\n"
    "                  ),",
    'egg list explanation',
)
text = replace_once(
    text,
    "                      onDelete: () => _deleteEgg(data, egg),\n                      onIncubatorChanged: (incubator) =>\n                          _updateEgg(data, egg.copyWith(incubator: incubator)),\n                      onCarriedChanged: (value) => _updateEgg(\n                        data,\n                        egg.copyWith(carriedEntireIncubation: value),\n                      ),",
    "                      teamSlotIndex: _teamSlotForEgg(data, egg)?.slotIndex,\n"
    "                      canMoveToTeam: freeSlot != null,\n"
    "                      onDelete: () => _deleteEgg(data, egg),\n"
    "                      onIncubatorChanged: (incubator) =>\n"
    "                          _updateEgg(data, egg.copyWith(incubator: incubator)),\n"
    "                      onMoveToDayCare: () => _moveEggToDayCare(data, egg),\n"
    "                      onMoveToTeam: () => _moveEggToTeam(data, egg),",
    'egg card callbacks',
)
text = replace_once(
    text,
    "    required this.onDelete,\n    required this.onIncubatorChanged,\n    required this.onCarriedChanged,",
    "    required this.teamSlotIndex,\n"
    "    required this.canMoveToTeam,\n"
    "    required this.onDelete,\n"
    "    required this.onIncubatorChanged,\n"
    "    required this.onMoveToDayCare,\n"
    "    required this.onMoveToTeam,",
    'egg card constructor',
)
text = replace_once(
    text,
    "  final VoidCallback onDelete;\n  final ValueChanged<EggIncubator> onIncubatorChanged;\n  final ValueChanged<bool> onCarriedChanged;",
    "  final int? teamSlotIndex;\n"
    "  final bool canMoveToTeam;\n"
    "  final VoidCallback onDelete;\n"
    "  final ValueChanged<EggIncubator> onIncubatorChanged;\n"
    "  final VoidCallback onMoveToDayCare;\n"
    "  final VoidCallback onMoveToTeam;",
    'egg card fields',
)
old_carried = r'''            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Trasportato per tutta l’incubazione'),
              subtitle: const Text(
                'Attivo: nascerà con Lealtà +2. Disattivo: Lealtà +1.',
              ),
              value: egg.carriedEntireIncubation,
              onChanged: onCarriedChanged,
            ),'''
new_location = r'''            Card(
              margin: EdgeInsets.zero,
              color: colors.surfaceContainerHighest,
              child: ListTile(
                leading: Icon(
                  teamSlotIndex == null ? Icons.home_work_outlined : Icons.group_outlined,
                ),
                title: Text(
                  teamSlotIndex == null
                      ? 'Pensione Pokémon'
                      : 'Squadra · Slot ${teamSlotIndex! + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  egg.carriedEntireIncubation
                      ? 'Occupa un Pokéslot e nascerà con Lealtà +2.'
                      : 'Non ha trascorso tutta l’incubazione in squadra: Lealtà +1.',
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (teamSlotIndex == null)
              OutlinedButton.icon(
                onPressed: canMoveToTeam ? onMoveToTeam : null,
                icon: const Icon(Icons.login),
                label: Text(
                  canMoveToTeam
                      ? 'RITIRA IN SQUADRA'
                      : 'NESSUN POKÉSLOT LIBERO',
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: onMoveToDayCare,
                icon: const Icon(Icons.home_work_outlined),
                label: const Text('SPOSTA IN PENSIONE'),
              ),'''
text = replace_once(text, old_carried, new_location, 'replace carried switch')
text = replace_once(
    text,
    "                'Lo spazio libero in squadra viene usato per primo; altrimenti il Pokémon va nel PC.',",
    "                teamSlotIndex == null\n"
    "                    ? 'Alla schiusa il Pokémon verrà inviato al PC dalla Pensione.'\n"
    "                    : 'Alla schiusa il Pokémon sostituirà l’uovo nello stesso Pokéslot.',",
    'hatch destination text',
)
path.write_text(text, encoding='utf-8')

# Team selection: show eggs as real occupied entities.
path = Path('lib/screens/team/team_selection_screen.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    "import '../pokemon/pokemon_detail_screen.dart';",
    "import '../pokemon/pokemon_detail_screen.dart';\nimport '../breeding/breeding_screen.dart';",
    'team breeding import',
)
text = replace_once(
    text,
    "  Future<void> _openPokemonDetail(TeamSlot slot) async {\n    final pokemon = _pokemonById(slot.pokemonId);",
    "  Future<void> _openPokemonDetail(TeamSlot slot) async {\n"
    "    if (slot.isEgg) {\n"
    "      await Navigator.of(context).push(\n"
    "        MaterialPageRoute(builder: (_) => const BreedingScreen()),\n"
    "      );\n"
    "      await _loadTeam();\n"
    "      return;\n"
    "    }\n"
    "    final pokemon = _pokemonById(slot.pokemonId);",
    'open egg from team',
)
text = replace_once(
    text,
    "  Future<void> _openPokemonPicker(TeamSlot slot) async {\n    final selectedPokemonId",
    "  Future<void> _openPokemonPicker(TeamSlot slot) async {\n"
    "    if (slot.isEgg) return;\n"
    "    final selectedPokemonId",
    'block picker on egg',
)
text = replace_once(
    text,
    "    final filledSlots = visibleTeam\n        .where((slot) => slot.pokemonId != null)\n        .length;",
    "    final filledSlots = visibleTeam.where((slot) => !slot.isEmpty).length;",
    'team occupied count',
)
text = replace_once(
    text,
    "                   onRemove: slot.pokemonId == null\n                       ? null\n                       : () => _setPokemonInSlot(slot.slotIndex, null),",
    "                   onRemove: slot.isPokemon\n                       ? () => _setPokemonInSlot(slot.slotIndex, null)\n                       : null,",
    'team remove only pokemon',
)
text = replace_once(
    text,
    "                  '$filledSlots/$totalSlots Pokémon in squadra',",
    "                  '$filledSlots/$totalSlots Pokéslot occupati',",
    'team header wording',
)
text = replace_once(
    text,
    "    final title = nickname.isEmpty ? pokemon?.name ?? 'Slot vuoto' : nickname;",
    "    final title = slot.isEgg\n"
    "        ? 'Uovo in incubazione'\n"
    "        : nickname.isEmpty\n"
    "            ? pokemon?.name ?? 'Slot vuoto'\n"
    "            : nickname;",
    'team egg title',
)
text = replace_once(
    text,
    "                    if (pokemon == null)\n                      Text(\n                        'Tocca per scegliere un Pokémon',\n                        style: TextStyle(color: colorScheme.onSurfaceVariant),\n                      )\n                    else ...[",
    "                    if (slot.isEgg)\n"
    "                      Text(\n"
    "                        'Occupa un Pokéslot · Tocca per gestirlo',\n"
    "                        style: TextStyle(color: colorScheme.onSurfaceVariant),\n"
    "                      )\n"
    "                    else if (pokemon == null)\n"
    "                      Text(\n"
    "                        'Tocca per scegliere un Pokémon',\n"
    "                        style: TextStyle(color: colorScheme.onSurfaceVariant),\n"
    "                      )\n"
    "                    else ...[",
    'team egg subtitle',
)
text = replace_once(
    text,
    "              pokemon == null\n                  ? IconButton.filled(",
    "              slot.isEgg\n"
    "                  ? const Icon(Icons.chevron_right)\n"
    "                  : pokemon == null\n"
    "                  ? IconButton.filled(",
    'team egg trailing',
)
text = replace_once(
    text,
    "        child: pokemon == null\n            ? Text(\n                '${slot.slotIndex + 1}',",
    "        child: slot.isEgg\n"
    "            ? const Icon(Icons.egg_alt_outlined, size: 34)\n"
    "            : pokemon == null\n"
    "            ? Text(\n"
    "                '${slot.slotIndex + 1}',",
    'team egg avatar',
)
path.write_text(text, encoding='utf-8')

# Capture and PC must not treat an egg slot as empty.
path = Path('lib/screens/capture/capture_pokemon_screen.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    '      if (slot.pokemonId == null) return slot;',
    '      if (slot.isEmpty) return slot;',
    'capture free slot',
)
path.write_text(text, encoding='utf-8')

path = Path('lib/screens/pc/pokemon_pc_screen.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    '      if (slot.pokemonId == null) return slot;',
    '      if (slot.isEmpty) return slot;',
    'pc free slot',
)
text = replace_once(
    text,
    '    return _visibleTeam.where((slot) => slot.pokemonId != null).length;',
    '    return _visibleTeam.where((slot) => !slot.isEmpty).length;',
    'pc occupied count',
)
text = replace_once(
    text,
    '                onDeposit: slot.pokemonId == null ? null : () => onDeposit(slot),',
    '                onDeposit: slot.isPokemon ? () => onDeposit(slot) : null,',
    'pc deposit only pokemon',
)
text = replace_once(
    text,
    "    final name = pokemon == null\n        ? 'Slot ${slot.slotIndex + 1}'\n        : nickname.isEmpty\n            ? pokemon.name\n            : nickname;",
    "    final name = slot.isEgg\n"
    "        ? 'Uovo'\n"
    "        : pokemon == null\n"
    "            ? 'Slot ${slot.slotIndex + 1}'\n"
    "            : nickname.isEmpty\n"
    "                ? pokemon.name\n"
    "                : nickname;",
    'pc egg name',
)
text = replace_once(
    text,
    "                pokemon == null\n                    ? CircleAvatar(\n                        radius: spriteSize / 2,\n                        backgroundColor: colorScheme.surfaceContainerHighest,\n                        child: Text('${slot.slotIndex + 1}'),\n                      )",
    "                slot.isEgg\n"
    "                    ? CircleAvatar(\n"
    "                        radius: spriteSize / 2,\n"
    "                        backgroundColor: colorScheme.tertiaryContainer,\n"
    "                        child: const Icon(Icons.egg_alt_outlined),\n"
    "                      )\n"
    "                    : pokemon == null\n"
    "                    ? CircleAvatar(\n"
    "                        radius: spriteSize / 2,\n"
    "                        backgroundColor: colorScheme.surfaceContainerHighest,\n"
    "                        child: Text('${slot.slotIndex + 1}'),\n"
    "                      )",
    'pc egg avatar',
)
text = replace_once(
    text,
    "                        pokemon == null ? 'Vuoto' : '#${pokemon.id.toString().padLeft(3, '0')}',",
    "                        slot.isEgg\n"
    "                            ? 'In incubazione'\n"
    "                            : pokemon == null\n"
    "                                ? 'Vuoto'\n"
    "                                : '#${pokemon.id.toString().padLeft(3, '0')}',",
    'pc egg subtitle',
)
path.write_text(text, encoding='utf-8')

# Tests.
path = Path('test/breeding_service_test.dart')
text = path.read_text(encoding='utf-8')
insert = r'''

  test('un uovo occupa un Pokéslot e viene ritrovato nello stesso slot', () {
    final team = [
      TeamSlot(slotIndex: 0, pokemonId: 1),
      TeamSlot(slotIndex: 1, pokemonId: null, eggId: 'egg-1'),
      TeamSlot(slotIndex: 2, pokemonId: null),
    ];

    expect(
      service.firstFreeUnlockedTeamSlot(team: team, unlockedPokeslots: 3)?.slotIndex,
      2,
    );
    expect(
      service.teamSlotForEgg(team: team, eggId: 'egg-1')?.slotIndex,
      1,
    );
  });
'''
text = replace_once(text, "  test('Pokémon Breeder applica WIS al tentativo e vantaggio al d100', () {", insert + "\n  test('Pokémon Breeder applica WIS al tentativo e vantaggio al d100', () {", 'breeding egg slot test')
path.write_text(text, encoding='utf-8')

Path('test/team_slot_egg_test.dart').write_text(r'''import 'package:flutter_test/flutter_test.dart';

import 'package:pokedex_5e_ita/models/team_slot.dart';

void main() {
  test('TeamSlot conserva un uovo e lo considera uno slot occupato', () {
    final slot = TeamSlot(slotIndex: 2, pokemonId: null, eggId: 'egg-42');
    final restored = TeamSlot.fromJson(slot.toJson());

    expect(restored.eggId, 'egg-42');
    expect(restored.isEgg, isTrue);
    expect(restored.isEmpty, isFalse);
    expect(restored.isPokemon, isFalse);
  });

  test('inserire un Pokémon rimuove l’uovo dallo slot', () {
    final slot = TeamSlot(slotIndex: 1, pokemonId: null, eggId: 'egg-1');
    final updated = slot.copyWith(pokemonId: 25, clearEgg: true);

    expect(updated.pokemonId, 25);
    expect(updated.eggId, isNull);
    expect(updated.isPokemon, isTrue);
  });
}
''', encoding='utf-8')

# Changelog.
path = Path('CHANGELOG.md')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    "- sistema persistente di allevamento e uova integrato nei profili e nei backup, con compatibilità dei genitori, Gruppi Uova, Ditto, tiri di successo, incubazione, incubatori e schiusa in squadra o nel PC.",
    "- sistema persistente di allevamento e uova integrato nei profili e nei backup, con compatibilità dei genitori, Gruppi Uova, Ditto, tiri di successo, incubazione, incubatori e schiusa in squadra o nel PC;\n"
    "- uova come entità reali della squadra: occupano un Pokéslot, possono essere affidate alla Pensione Pokémon e alla schiusa vengono sostituite dal Pokémon nato nello stesso slot.",
    'changelog egg team entity',
)
path.write_text(text, encoding='utf-8')
