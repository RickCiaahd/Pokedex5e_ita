import 'dart:math';

import 'package:flutter/material.dart';

import '../../localization/ui_text.dart';
import '../../localization/user_facing_error.dart';
import '../../models/breeding_candidate.dart';
import '../../models/breeding_egg.dart';
import '../../models/breeding_species_data.dart';
import '../../models/bag_inventory_entry.dart';
import '../../models/level_progression.dart';
import '../../models/pc_pokemon.dart';
import '../../models/trainer_progression.dart';
import '../../models/pokemon.dart';
import '../../models/team_slot.dart';
import '../../models/user_profile.dart';
import '../../repositories/bag_inventory_repository.dart';
import '../../repositories/breeding_egg_repository.dart';
import '../../repositories/feat_repository.dart';
import '../../repositories/pokemon_pc_repository.dart';
import '../../repositories/pokemon_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/team_repository.dart';
import '../../services/breeding_service.dart';
import '../../services/trainer_path_passive_service.dart';
import '../../widgets/breeding/breeder_trait_dialogs.dart';
import '../../widgets/navigation/home_leading_button.dart';
import '../../widgets/pokemon/egg_asset_image.dart';

class BreedingScreen extends StatefulWidget {
  const BreedingScreen({super.key});

  @override
  State<BreedingScreen> createState() => _BreedingScreenState();
}

class _BreedingScreenState extends State<BreedingScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final BagInventoryRepository _bagRepository = BagInventoryRepository();
  final FeatRepository _featRepository = FeatRepository();
  final PokemonRepository _pokemonRepository = PokemonRepository();
  final TeamRepository _teamRepository = TeamRepository();
  final PokemonPcRepository _pcRepository = PokemonPcRepository();
  final BreedingEggRepository _eggRepository = BreedingEggRepository();
  final BreedingDataService _dataService = BreedingDataService();
  final BreedingService _breedingService = const BreedingService();
  final Random _random = Random();
  final TextEditingController _manualRollController = TextEditingController();

  late Future<_BreedingScreenData> _future;
  String? _firstKey;
  String? _secondKey;
  String? _message;
  bool _useDayCare = false;

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
      _bagRepository.getInventory(profile.id),
      _featRepository.getFeatDescriptions(),
    ]);
    final catalog = results[0] as List<Pokemon>;
    var team = results[1] as List<TeamSlot>;
    var pc = results[2] as List<PcPokemon>;
    var eggs = results[3] as List<BreedingEgg>;
    final unlockedPokeslots = TrainerProgression.pokeslotsForLevel(
      profile.trainerLevel,
    );

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
      if (slot.slotIndex >= unlockedPokeslots ||
          egg.isInDayCare ||
          egg.isInPc) {
        await _teamRepository.clearSlot(
          profileId: profile.id,
          slotIndex: slot.slotIndex,
        );
        if (!egg.isInDayCare && !egg.isInPc) {
          await _eggRepository.saveEgg(
            profile.id,
            egg.copyWith(
              isInDayCare: true,
              isInPc: false,
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
      if (egg.isInDayCare || egg.isInPc) continue;
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
            isInPc: false,
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
    final inventory = results[5] as List<BagInventoryEntry>;
    final featDescriptions = results[6] as Map<String, String>;
    final incubatorQuantities = <EggIncubator, int>{
      for (final incubator in EggIncubator.values)
        incubator: incubator.itemId == null
            ? 0
            : inventory
                  .where((entry) => entry.itemId == incubator.itemId)
                  .fold<int>(0, (sum, entry) => sum + entry.quantity),
    };
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
          location: uiTextForLanguage(
            'Squadra ${slot.slotIndex + 1}',
            """Team ${slot.slotIndex + 1}""",
          ),
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
      incubatorQuantities: incubatorQuantities,
      featDescriptions: featDescriptions,
    );
  }

  Future<void> _reload({String? message}) async {
    if (!mounted) return;
    setState(() {
      _message = message;
      _future = _load();
    });
  }

  BreedingCandidate? _candidateFor(_BreedingScreenData data, String? key) {
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

    final unlockedPokeslots = TrainerProgression.pokeslotsForLevel(
      data.profile.trainerLevel,
    );
    final freeSlot = _breedingService.firstFreeUnlockedTeamSlot(
      team: data.team,
      unlockedPokeslots: unlockedPokeslots,
    );
    if (!_useDayCare && freeSlot == null) {
      setState(() {
        _message = uiTextForLanguage(
          'Non hai un Pokéslot libero. Libera uno slot oppure usa la Pensione Pokémon.',
          """You do not have a free Poké Slot. Free a slot or use the Pokémon Day Care.""",
        );
      });
      return;
    }

    final roll = manualRoll ?? _random.nextInt(20) + 1;
    if (roll < 1 || roll > 20) {
      setState(
        () => _message = uiTextForLanguage(
          'Il risultato del d20 deve essere tra 1 e 20.',
          """The d20 result must be between 1 and 20.""",
        ),
      );
      return;
    }
    final modifier = _breedingService.breedingRollModifier(data.profile);
    final dc = _breedingService.successDc(first.loyalty + second.loyalty);
    final total = roll + modifier;
    if (total < dc) {
      setState(() {
        _message = uiTextForLanguage(
          'Tentativo fallito: d20 $roll ${_signed(modifier)} = $total contro CD $dc.',
          """Attempt failed: d20 $roll ${_signed(modifier)} = $total against DC $dc.""",
        );
      });
      return;
    }

    try {
      MasterOfTraitsSelection? traitSelection;
      final childBase = compatibility.childSpeciesId == null
          ? null
          : data.catalogById[compatibility.childSpeciesId!];
      if (_breedingService.hasMasterOfTraits(data.profile) &&
          childBase != null) {
        final child = childBase.resolveVariant(
          formName: compatibility.childFormName,
        );
        final inheritedEggMoves = _breedingService.inheritedEggMoves(
          child: child,
          first: first,
          second: second,
        );
        traitSelection = await showMasterOfTraitsDialog(
          context: context,
          pokemon: child,
          genders: _breedingService.availableGenders(child),
          abilities: _breedingService.availableAbilities(child),
          replaceableEggMoveCount: inheritedEggMoves.length,
        );
        if (!mounted || traitSelection == null) return;
      }

      final created = _breedingService.createEgg(
        first: first,
        second: second,
        compatibility: compatibility,
        catalog: data.catalogById,
        selectedGender: traitSelection?.gender,
        selectedNature: traitSelection?.nature,
        selectedAbility: traitSelection?.ability,
        replacementEggMoves: traitSelection?.replacementEggMoves ?? const [],
        masterOfTraitsApplied: traitSelection != null,
        random: _random,
      );
      final egg = created.copyWith(
        isInDayCare: _useDayCare,
        isInPc: false,
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
          ? uiTextForLanguage(
              'affidato alla Pensione Pokémon',
              """placed in the Pokémon Day Care""",
            )
          : uiTextForLanguage(
              'inserito nello slot squadra ${freeSlot!.slotIndex + 1}',
              """placed in team slot ${freeSlot.slotIndex + 1}""",
            );
      _manualRollController.clear();
      _firstKey = null;
      _secondKey = null;
      _useDayCare = false;
      await _reload(
        message: uiTextForLanguage(
          'Successo: d20 $roll ${_signed(modifier)} = $total contro CD $dc. Uovo creato e $destination.',
          """Success: d20 $roll ${_signed(modifier)} = $total against DC $dc. Egg created and $destination.""",
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _message = context.userFacingError(
          error,
          action: UserFacingErrorAction.save,
        ),
      );
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
      egg.copyWith(
        isInDayCare: true,
        isInPc: false,
        carriedEntireIncubation: false,
      ),
    );
    await _reload(
      message: uiTextForLanguage(
        'Uovo affidato alla Pensione Pokémon.',
        """Egg placed in the Pokémon Day Care.""",
      ),
    );
  }

  Future<void> _moveEggToPc(_BreedingScreenData data, BreedingEgg egg) async {
    final slot = _teamSlotForEgg(data, egg);
    if (slot != null) {
      await _teamRepository.clearSlot(
        profileId: data.profile.id,
        slotIndex: slot.slotIndex,
      );
    }
    await _eggRepository.saveEgg(
      data.profile.id,
      egg.copyWith(
        isInDayCare: false,
        isInPc: true,
        carriedEntireIncubation: false,
      ),
    );
    await _reload(
      message: uiTextForLanguage(
        'Uovo depositato nel PC. L’incubazione resta in pausa.',
        """Egg deposited in the PC. Incubation is paused.""",
      ),
    );
  }

  Future<void> _moveEggToTeam(_BreedingScreenData data, BreedingEgg egg) async {
    final unlockedPokeslots = TrainerProgression.pokeslotsForLevel(
      data.profile.trainerLevel,
    );
    final freeSlot = _breedingService.firstFreeUnlockedTeamSlot(
      team: data.team,
      unlockedPokeslots: unlockedPokeslots,
    );
    if (freeSlot == null) {
      setState(
        () => _message = uiTextForLanguage(
          'Non hai un Pokéslot libero per ritirare l’uovo.',
          """You do not have a free Poké Slot for the egg.""",
        ),
      );
      return;
    }
    await _teamRepository.setEggInSlot(
      profileId: data.profile.id,
      slotIndex: freeSlot.slotIndex,
      eggId: egg.id,
    );
    await _eggRepository.saveEgg(
      data.profile.id,
      egg.copyWith(isInDayCare: false, isInPc: false),
    );
    await _reload(
      message: uiTextForLanguage(
        'Uovo ritirato nello slot squadra ${freeSlot.slotIndex + 1}.',
        """Egg moved to team slot ${freeSlot.slotIndex + 1}.""",
      ),
    );
  }

  Future<void> _advanceEgg(_BreedingScreenData data, BreedingEgg egg) async {
    if (egg.isInPc) {
      setState(() {
        _message = uiTextForLanguage(
          'Nel PC l’incubazione è in pausa. Ritira l’uovo in squadra oppure affidalo alla Pensione.',
          """Incubation is paused in the PC. Move the egg to the team or to the Day Care.""",
        );
      });
      return;
    }
    final result = _breedingService.advanceIncubation(
      egg: egg,
      profile: data.profile,
      random: _random,
    );
    await _eggRepository.saveEgg(data.profile.id, result.egg);
    final baseRoll = result.d100Rolls.join(' / ');
    final incubator = result.incubatorRolls.isEmpty
        ? ''
        : uiTextForLanguage(
            ' + incubatore ${result.incubatorRolls.join(' + ')}',
            """ + incubator ${result.incubatorRolls.join(' + ')}""",
          );
    await _reload(
      message: uiTextForLanguage(
        'Incubazione: d100 $baseRoll$incubator. Contatore ridotto di ${result.reduction}.',
        """Incubation: d100 $baseRoll$incubator. Counter reduced by ${result.reduction}.""",
      ),
    );
  }

  Future<void> _attachIncubator(
    _BreedingScreenData data,
    BreedingEgg egg,
    EggIncubator incubator,
  ) async {
    if (incubator == EggIncubator.none || incubator == egg.incubator) return;
    if (egg.incubator != EggIncubator.none) {
      setState(() {
        _message = uiTextForLanguage(
          'L’incubatore è già stato usato per questo uovo e non può essere trasferito.',
          """The incubator has already been used for this egg and cannot be transferred.""",
        );
      });
      return;
    }
    final itemId = incubator.itemId;
    if (itemId == null) return;
    final consumed = await _bagRepository.consumeItem(
      profileId: data.profile.id,
      itemId: itemId,
    );
    if (!consumed) {
      setState(() {
        _message = uiTextForLanguage(
          'Non possiedi un Incubatore ${incubator.label} nello zaino.',
          """You do not have a ${incubator.label} Incubator in the Bag.""",
        );
      });
      return;
    }
    await _eggRepository.saveEgg(
      data.profile.id,
      egg.copyWith(incubator: incubator),
    );
    await _reload(
      message: uiTextForLanguage(
        'Incubatore ${incubator.label} applicato e consumato: aggiunge ${incubator.extraD20}d20 a ogni avanzamento.',
        """${incubator.label} Incubator applied and consumed: it adds ${incubator.extraD20}d20 to each incubation advance.""",
      ),
    );
  }

  Future<void> _editEggHp(_BreedingScreenData data, BreedingEgg egg) async {
    final nextHp = await showEggHpDialog(
      context: context,
      currentHp: egg.currentHp,
      maxHp: BreedingEgg.maxHitPoints,
    );
    if (!mounted || nextHp == null || nextHp == egg.currentHp) return;

    if (nextHp <= 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(
            uiTextForLanguage('Distruggere l’uovo?', """Destroy the egg?"""),
          ),
          content: Text(
            uiTextForLanguage(
              'Secondo il manuale un uovo è distrutto quando raggiunge 0 PF. Questa operazione non può essere annullata.',
              """According to the manual, an egg is destroyed when it reaches 0 HP. This cannot be undone.""",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(uiTextForLanguage('ANNULLA', """CANCEL""")),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(uiTextForLanguage('PORTA A 0 PF', """SET TO 0 HP""")),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      final slot = _teamSlotForEgg(data, egg);
      if (slot != null) {
        await _teamRepository.clearSlot(
          profileId: data.profile.id,
          slotIndex: slot.slotIndex,
        );
      }
      await _eggRepository.deleteEgg(data.profile.id, egg.id);
      await _reload(
        message: uiTextForLanguage(
          'L’uovo ha raggiunto 0 PF ed è stato distrutto.',
          """The egg reached 0 HP and was destroyed.""",
        ),
      );
      return;
    }

    await _eggRepository.saveEgg(
      data.profile.id,
      egg.copyWith(currentHp: nextHp),
    );
    await _reload(
      message: uiTextForLanguage(
        'PF dell’uovo aggiornati a $nextHp/10.',
        """Egg HP updated to $nextHp/10.""",
      ),
    );
  }

  Future<void> _deleteEgg(_BreedingScreenData data, BreedingEgg egg) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          uiTextForLanguage('Eliminare l’uovo?', """Delete the egg?"""),
        ),
        content: Text(
          uiTextForLanguage(
            'Il progresso di incubazione e i dati del Pokémon contenuto andranno persi.',
            """Incubation progress and the contained Pokémon data will be lost.""",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(uiTextForLanguage('ANNULLA', """CANCEL""")),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(uiTextForLanguage('ELIMINA', """DELETE""")),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final slot = _teamSlotForEgg(data, egg);
    if (slot != null) {
      await _teamRepository.clearSlot(
        profileId: data.profile.id,
        slotIndex: slot.slotIndex,
      );
    }
    await _eggRepository.deleteEgg(data.profile.id, egg.id);
    await _reload(
      message: uiTextForLanguage('Uovo eliminato.', """Egg deleted."""),
    );
  }

  Future<void> _hatchEgg(_BreedingScreenData data, BreedingEgg egg) async {
    if (!egg.isReady) return;
    if (egg.isInPc) {
      setState(() {
        _message = uiTextForLanguage(
          'Un uovo depositato nel PC non può schiudersi. Ritiralo in squadra oppure spostalo in Pensione.',
          """An egg stored in the PC cannot hatch. Move it to the team or to the Day Care.""",
        );
      });
      return;
    }
    final base = data.catalogById[egg.speciesId];
    if (base == null) {
      setState(
        () => _message = uiTextForLanguage(
          'La specie dell’uovo non è nel catalogo.',
          """The egg species is not in the catalog.""",
        ),
      );
      return;
    }

    var hatchEgg = egg;
    final previewPokemon = base.resolveVariant(
      formName: hatchEgg.formName,
      gender: hatchEgg.gender,
    );
    if (_breedingService.hasGoodGenes(data.profile) &&
        !hatchEgg.hasGoodGenesSelection) {
      final selection = await showGoodGenesDialog(
        context: context,
        pokemonName: _displayName(
          pokemon: previewPokemon,
          formName: hatchEgg.formName,
        ),
        featDescriptions: data.featDescriptions,
      );
      if (!mounted || selection == null) return;
      hatchEgg = hatchEgg.copyWith(
        goodGenesAbilityBonuses: selection.abilityBonuses,
        goodGenesFeat: selection.feat,
      );
      await _eggRepository.saveEgg(data.profile.id, hatchEgg);
    }

    final pokemon = base.resolveVariant(
      formName: hatchEgg.formName,
      gender: hatchEgg.gender,
    );
    final level = max(1, pokemon.minLevelFound);
    final experience = LevelProgression.thresholdForLevel(level);
    final loyalty = hatchEgg.carriedEntireIncubation ? 2 : 1;
    final eggSlot = _teamSlotForEgg(data, hatchEgg);
    final feats = hatchEgg.goodGenesFeat == null
        ? const <String>[]
        : <String>[hatchEgg.goodGenesFeat!];
    final provisionalSlot = TeamSlot(
      slotIndex: eggSlot?.slotIndex ?? 0,
      pokemonId: hatchEgg.speciesId,
      experience: experience,
      currentHp: 1,
      selectedMoves: hatchEgg.selectedMoves,
      isShiny: hatchEgg.isShiny,
      gender: hatchEgg.gender,
      formName: hatchEgg.formName,
      nature: hatchEgg.nature,
      abilities: hatchEgg.ability == null ? const [] : [hatchEgg.ability!],
      feats: feats,
      customAbilityScores: hatchEgg.goodGenesAbilityBonuses,
      loyalty: loyalty,
    );
    final maxHp = TrainerPathPassiveService.maxHp(
      profile: data.profile,
      pokemon: pokemon,
      slot: provisionalSlot,
      level: level,
    );
    final bornSlot = provisionalSlot.copyWith(currentHp: maxHp);

    if (eggSlot != null) {
      await _teamRepository.updateSlot(
        profileId: data.profile.id,
        updatedSlot: bornSlot,
      );
    } else {
      final notes = <String>[
        uiTextForLanguage(
          'Nato da un uovo nella Pensione Pokémon.',
          """Hatched from an egg in the Pokémon Day Care.""",
        ),
        if (hatchEgg.inheritedMoves.isNotEmpty)
          uiTextForLanguage(
            'Mosse ereditate: ${hatchEgg.inheritedMoves.join(', ')}.',
            """Inherited moves: ${hatchEgg.inheritedMoves.join(', ')}.""",
          ),
        if (hatchEgg.goodGenesAbilityBonuses.isNotEmpty)
          'Good Genes: ${hatchEgg.goodGenesAbilityBonuses.entries.map((entry) => '${entry.key} +${entry.value}').join(', ')}.',
        if (hatchEgg.goodGenesFeat != null)
          'Good Genes: talento ${hatchEgg.goodGenesFeat}.',
      ].join(' ');
      await _pcRepository.depositPokemon(
        profileId: data.profile.id,
        pokemonId: hatchEgg.speciesId,
        experience: experience,
        currentHp: maxHp,
        selectedMoves: hatchEgg.selectedMoves,
        isShiny: hatchEgg.isShiny,
        gender: hatchEgg.gender,
        formName: hatchEgg.formName,
        nature: hatchEgg.nature,
        abilities: hatchEgg.ability == null ? const [] : [hatchEgg.ability!],
        feats: feats,
        customAbilityScores: hatchEgg.goodGenesAbilityBonuses,
        loyalty: loyalty,
        notes: notes,
      );
    }
    await _eggRepository.deleteEgg(data.profile.id, hatchEgg.id);
    final destination = eggSlot == null
        ? uiTextForLanguage(
            'è stato inviato al PC dalla Pensione Pokémon',
            """was sent to the PC from the Pokémon Day Care""",
          )
        : uiTextForLanguage(
            'ha sostituito l’uovo nello slot squadra ${eggSlot.slotIndex + 1}',
            """replaced the egg in team slot ${eggSlot.slotIndex + 1}""",
          );
    final goodGenes = hatchEgg.hasGoodGenesSelection
        ? hatchEgg.goodGenesFeat != null
              ? uiTextForLanguage(
                  ' Good Genes ha assegnato il talento ${hatchEgg.goodGenesFeat}.',
                  """ Good Genes granted the ${hatchEgg.goodGenesFeat} feat.""",
                )
              : uiTextForLanguage(
                  ' Good Genes ha applicato ${hatchEgg.goodGenesAbilityBonuses.entries.map((entry) => '${entry.key} +${entry.value}').join(', ')}.',
                  """ Good Genes applied ${hatchEgg.goodGenesAbilityBonuses.entries.map((entry) => '${entry.key} +${entry.value}').join(', ')}.""",
                )
        : '';
    await _reload(
      message: uiTextForLanguage(
        '${_displayName(pokemon: pokemon, formName: hatchEgg.formName)} si è schiuso, $destination, con Lealtà +$loyalty.$goodGenes',
        """${_displayName(pokemon: pokemon, formName: hatchEgg.formName)} hatched, $destination, with Loyalty +$loyalty.$goodGenes""",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const HomeLeadingButton(),
        title: Text(
          uiTextForLanguage('Allevamento e uova', """Breeding and Eggs"""),
        ),
        actions: [HomeAppBarAction()],
      ),
      body: FutureBuilder<_BreedingScreenData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  uiTextForLanguage(
                    'Errore: ${snapshot.error}',
                    """Error: ${snapshot.error}""",
                  ),
                ),
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
          final unlockedPokeslots = TrainerProgression.pokeslotsForLevel(
            data.profile.trainerLevel,
          );
          final freeSlot = _breedingService.firstFreeUnlockedTeamSlot(
            team: data.team,
            unlockedPokeslots: unlockedPokeslots,
          );
          final canStoreEgg = _useDayCare || freeSlot != null;

          return RefreshIndicator(
            onRefresh: () => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _RulesCard(
                  profile: data.profile,
                  rollModifier: modifier,
                  incubationAdvantage: _breedingService.hasIncubationAdvantage(
                    data.profile,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          uiTextForLanguage(
                            'NUOVO TENTATIVO',
                            """NEW ATTEMPT""",
                          ),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          uiTextForLanguage(
                            'Seleziona due Pokémon posseduti. L’app controlla Lealtà, sesso, Ditto e Gruppi Uova.',
                            """Select two owned Pokémon. The app checks Loyalty, gender, Ditto and Egg Groups.""",
                          ),
                        ),
                        const SizedBox(height: 12),
                        _CandidateDropdown(
                          label: uiTextForLanguage(
                            'Primo genitore',
                            """First parent""",
                          ),
                          value: _firstKey,
                          candidates: data.candidates,
                          onChanged: (value) => setState(() {
                            _firstKey = value;
                            _message = null;
                          }),
                        ),
                        const SizedBox(height: 10),
                        _CandidateDropdown(
                          label: uiTextForLanguage(
                            'Secondo genitore',
                            """Second parent""",
                          ),
                          value: _secondKey,
                          candidates: data.candidates,
                          onChanged: (value) => setState(() {
                            _secondKey = value;
                            _message = null;
                          }),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            uiTextForLanguage(
                              'Usa Pensione Pokémon',
                              """Use Pokémon Day Care""",
                            ),
                          ),
                          subtitle: Text(
                            _useDayCare
                                ? uiTextForLanguage(
                                    'L’uovo non occupa un Pokéslot e alla schiusa il Pokémon andrà nel PC.',
                                    """The egg does not occupy a Poké Slot and the Pokémon will go to the PC when it hatches.""",
                                  )
                                : freeSlot == null
                                ? uiTextForLanguage(
                                    'Nessun Pokéslot libero: attiva la Pensione per poter ottenere l’uovo.',
                                    """No free Poké Slot: enable the Day Care to receive the egg.""",
                                  )
                                : uiTextForLanguage(
                                    'L’uovo occuperà lo slot squadra ${freeSlot.slotIndex + 1}.',
                                    """The egg will occupy team slot ${freeSlot.slotIndex + 1}.""",
                                  ),
                          ),
                          value: _useDayCare,
                          onChanged: (value) => setState(() {
                            _useDayCare = value;
                            _message = null;
                          }),
                        ),
                        if (compatibility != null) ...[
                          const SizedBox(height: 12),
                          _CompatibilityCard(
                            compatibility: compatibility,
                            resultPokemon: compatibility.childSpeciesId == null
                                ? null
                                : data.catalogById[compatibility
                                      .childSpeciesId!],
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
                              onPressed:
                                  compatibility?.isCompatible == true &&
                                      canStoreEgg
                                  ? () => _attemptBreeding(data)
                                  : null,
                              icon: const Icon(Icons.casino_outlined),
                              label: Text(
                                uiTextForLanguage(
                                  'TIRA IL D20',
                                  """ROLL D20""",
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 145,
                              child: TextField(
                                controller: _manualRollController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: uiTextForLanguage(
                                    'Risultato d20',
                                    """d20 result""",
                                  ),
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            OutlinedButton(
                              onPressed:
                                  compatibility?.isCompatible == true &&
                                      canStoreEgg
                                  ? () {
                                      final roll = int.tryParse(
                                        _manualRollController.text.trim(),
                                      );
                                      if (roll == null) {
                                        setState(() {
                                          _message = uiTextForLanguage(
                                            'Inserisci il risultato del d20.',
                                            """Enter the d20 result.""",
                                          );
                                        });
                                        return;
                                      }
                                      _attemptBreeding(data, manualRoll: roll);
                                    }
                                  : null,
                              child: Text(
                                uiTextForLanguage(
                                  'USA IL TIRO',
                                  """USE ROLL""",
                                ),
                              ),
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
                  uiTextForLanguage(
                    'UOVA IN INCUBAZIONE (${data.eggs.length})',
                    """INCUBATING EGGS (${data.eggs.length})""",
                  ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  uiTextForLanguage(
                    'Un uovo trasportato occupa davvero un Pokéslot. Un uovo affidato alla Pensione resta fuori dalla squadra e alla schiusa il Pokémon viene inviato al PC.',
                    """A carried egg occupies a Poké Slot. An egg placed in the Day Care stays outside the team and the Pokémon is sent to the PC when it hatches.""",
                  ),
                ),
                const SizedBox(height: 8),
                if (data.eggs.isEmpty)
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        uiTextForLanguage(
                          'Non ci sono uova. Completa con successo un tentativo di allevamento.',
                          """There are no eggs. Complete a breeding attempt successfully.""",
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  for (final egg in data.eggs) ...[
                    _EggCard(
                      egg: egg,
                      pokemon: data.catalogById[egg.speciesId],
                      incubationAdvantage: _breedingService
                          .hasIncubationAdvantage(data.profile),
                      onAdvance: () => _advanceEgg(data, egg),
                      onHatch: () => _hatchEgg(data, egg),
                      teamSlotIndex: _teamSlotForEgg(data, egg)?.slotIndex,
                      canMoveToTeam: freeSlot != null,
                      onDelete: () => _deleteEgg(data, egg),
                      incubatorQuantities: data.incubatorQuantities,
                      onIncubatorChanged: (incubator) =>
                          _attachIncubator(data, egg, incubator),
                      onEditHp: () => _editEggHp(data, egg),
                      onMoveToDayCare: () => _moveEggToDayCare(data, egg),
                      onMoveToPc: () => _moveEggToPc(data, egg),
                      onMoveToTeam: () => _moveEggToTeam(data, egg),
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
    final learned =
        pokemon.moves.levelMoves.entries
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
    final goodGenes = breeder && profile.trainerLevel >= 9;
    final masterOfTraits = breeder && profile.trainerLevel >= 15;
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              uiTextForLanguage('ALLEVAMENTO POKÉMON', """POKÉMON BREEDING"""),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              uiTextForLanguage(
                'Servono Lealtà +2, sesso compatibile e un Gruppo Uova condiviso. Ditto ignora sesso e Gruppo Uova; Undiscovered non può riprodursi.',
                """Requires Loyalty +2, compatible genders and a shared Egg Group. Ditto ignores gender and Egg Groups; Undiscovered Pokémon cannot breed.""",
              ),
            ),
            if (breeder || rollModifier != 0 || incubationAdvantage) ...[
              const SizedBox(height: 10),
              Text(
                [
                  uiTextForLanguage(
                    'Pokémon Breeder: tiro di accoppiamento ${rollModifier >= 0 ? '+' : ''}$rollModifier',
                    """Pokémon Breeder: breeding check ${rollModifier >= 0 ? '+' : ''}$rollModifier""",
                  ),
                  if (incubationAdvantage)
                    uiTextForLanguage(
                      'vantaggio ai d100 di incubazione',
                      """advantage on incubation d100 rolls""",
                    ),
                  if (goodGenes)
                    uiTextForLanguage(
                      'Good Genes alla schiusa',
                      """Good Genes when hatching""",
                    ),
                  if (masterOfTraits)
                    uiTextForLanguage(
                      'Master of Traits sulle uova future',
                      """Master of Traits on future eggs""",
                    ),
                ].join(' · '),
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
      value: candidates.any((candidate) => candidate.key == value)
          ? value
          : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final candidate in candidates)
          DropdownMenuItem(
            value: candidate.key,
            child: Text(
              uiTextForLanguage(
                '${candidate.displayName} · ${candidate.genderLabel} · Lealtà ${candidate.loyalty >= 0 ? '+' : ''}${candidate.loyalty} · ${candidate.location}',
                """${candidate.displayName} · ${candidate.genderLabel} · Loyalty ${candidate.loyalty >= 0 ? '+' : ''}${candidate.loyalty} · ${candidate.location}""",
              ),
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
              compatible
                  ? uiTextForLanguage('COMPATIBILI', """COMPATIBLE""")
                  : uiTextForLanguage('NON COMPATIBILI', """NOT COMPATIBLE"""),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            if (compatible) ...[
              Text(
                uiTextForLanguage(
                  'Gruppo: ${compatibility.sharedEggGroups.join(', ')} · Risultato: ${resultPokemon?.name ?? '#${compatibility.childSpeciesId}'}',
                  """Group: ${compatibility.sharedEggGroups.join(', ')} · Result: ${resultPokemon?.name ?? '#${compatibility.childSpeciesId}'}""",
                ),
              ),
              if (dc != null)
                Text(
                  uiTextForLanguage(
                    'Prova: d20 ${modifier >= 0 ? '+' : ''}$modifier contro CD $dc.',
                    """Check: d20 ${modifier >= 0 ? '+' : ''}$modifier against DC $dc.""",
                  ),
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
    required this.teamSlotIndex,
    required this.canMoveToTeam,
    required this.onDelete,
    required this.incubatorQuantities,
    required this.onIncubatorChanged,
    required this.onEditHp,
    required this.onMoveToDayCare,
    required this.onMoveToPc,
    required this.onMoveToTeam,
  });

  final BreedingEgg egg;
  final Pokemon? pokemon;
  final bool incubationAdvantage;
  final VoidCallback onAdvance;
  final VoidCallback onHatch;
  final int? teamSlotIndex;
  final bool canMoveToTeam;
  final VoidCallback onDelete;
  final Map<EggIncubator, int> incubatorQuantities;
  final ValueChanged<EggIncubator> onIncubatorChanged;
  final VoidCallback onEditHp;
  final VoidCallback onMoveToDayCare;
  final VoidCallback onMoveToPc;
  final VoidCallback onMoveToTeam;

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
                const EggAssetImage(size: 54),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        egg.isReady
                            ? uiTextForLanguage(
                                'Uovo pronto a schiudersi',
                                """Egg ready to hatch""",
                              )
                            : uiTextForLanguage(
                                'Uovo di ${pokemon?.name ?? '#${egg.speciesId}'}',
                                """${pokemon?.name ?? '#${egg.speciesId}'} Egg""",
                              ),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        uiTextForLanguage(
                          'Genitori: ${egg.parentNames.join(' + ')}',
                          """Parents: ${egg.parentNames.join(' + ')}""",
                        ),
                      ),
                      Text(
                        egg.isReady
                            ? uiTextForLanguage(
                                'Incubazione completata',
                                """Incubation complete""",
                              )
                            : uiTextForLanguage(
                                '${egg.incubationRemaining}/${egg.hatchTime} punti rimanenti',
                                """${egg.incubationRemaining}/${egg.hatchTime} points remaining""",
                              ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: uiTextForLanguage('Elimina uovo', """Delete egg"""),
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
                Chip(
                  label: Text(
                    uiTextForLanguage(
                      'CA ${BreedingEgg.armorClass}',
                      """AC ${BreedingEgg.armorClass}""",
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    uiTextForLanguage(
                      'PF ${egg.currentHp}/${BreedingEgg.maxHitPoints}',
                      """HP ${egg.currentHp}/${BreedingEgg.maxHitPoints}""",
                    ),
                  ),
                ),
                if (egg.masterOfTraitsApplied)
                  Chip(label: Text('MASTER OF TRAITS')),
              ],
            ),
            if (egg.inheritedMoves.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                uiTextForLanguage(
                  'Mosse ereditate: ${egg.inheritedMoves.join(', ')}',
                  """Inherited moves: ${egg.inheritedMoves.join(', ')}""",
                ),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
            const SizedBox(height: 10),
            DropdownButtonFormField<EggIncubator>(
              value: egg.incubator,
              decoration: InputDecoration(
                labelText: uiTextForLanguage('Incubatore', """Incubator"""),
                border: const OutlineInputBorder(),
                isDense: true,
                helperText: egg.incubator == EggIncubator.none
                    ? uiTextForLanguage(
                        'Viene consumato quando lo assegni all’uovo.',
                        """It is consumed when assigned to the egg.""",
                      )
                    : uiTextForLanguage(
                        'Già consumato per questo uovo; non è trasferibile.',
                        """Already consumed for this egg; it cannot be transferred.""",
                      ),
              ),
              items: [
                for (final incubator in EggIncubator.values)
                  DropdownMenuItem(
                    value: incubator,
                    enabled:
                        incubator == EggIncubator.none ||
                        (incubatorQuantities[incubator] ?? 0) > 0,
                    child: Text(
                      incubator.extraD20 == 0
                          ? incubator.label
                          : '${incubator.label} (+${incubator.extraD20}d20) · x${incubatorQuantities[incubator] ?? 0}',
                    ),
                  ),
              ],
              onChanged: egg.incubator == EggIncubator.none
                  ? (value) {
                      if (value != null) onIncubatorChanged(value);
                    }
                  : null,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onEditHp,
              icon: const Icon(Icons.shield_outlined),
              label: Text(
                uiTextForLanguage('MODIFICA PF UOVO', """EDIT EGG HP"""),
              ),
            ),
            Card(
              margin: EdgeInsets.zero,
              color: colors.surfaceContainerHighest,
              child: ListTile(
                leading: Icon(
                  egg.isInPc
                      ? Icons.computer_outlined
                      : teamSlotIndex == null
                      ? Icons.home_work_outlined
                      : Icons.group_outlined,
                ),
                title: Text(
                  egg.isInPc
                      ? uiTextForLanguage('PC Pokémon', """Pokémon PC""")
                      : teamSlotIndex == null
                      ? uiTextForLanguage(
                          'Pensione Pokémon',
                          """Pokémon Day Care""",
                        )
                      : uiTextForLanguage(
                          'Squadra · Slot ${teamSlotIndex! + 1}',
                          """Team · Slot ${teamSlotIndex! + 1}""",
                        ),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  egg.isInPc
                      ? uiTextForLanguage(
                          'L’incubazione è in pausa e l’uovo non occupa un Pokéslot.',
                          """Incubation is paused and the egg does not occupy a Poké Slot.""",
                        )
                      : egg.carriedEntireIncubation
                      ? uiTextForLanguage(
                          'Occupa un Pokéslot e nascerà con Lealtà +2.',
                          """Occupies a Poké Slot and will hatch with Loyalty +2.""",
                        )
                      : uiTextForLanguage(
                          'Non ha trascorso tutta l’incubazione in squadra: Lealtà +1.',
                          """It did not spend the entire incubation in the team: Loyalty +1.""",
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (teamSlotIndex == null)
                  OutlinedButton.icon(
                    onPressed: canMoveToTeam ? onMoveToTeam : null,
                    icon: const Icon(Icons.login),
                    label: Text(
                      canMoveToTeam
                          ? uiTextForLanguage(
                              'RITIRA IN SQUADRA',
                              """MOVE TO TEAM""",
                            )
                          : uiTextForLanguage(
                              'NESSUN POKÉSLOT LIBERO',
                              """NO FREE POKÉ SLOT""",
                            ),
                    ),
                  ),
                if (teamSlotIndex != null || egg.isInDayCare)
                  OutlinedButton.icon(
                    onPressed: onMoveToPc,
                    icon: const Icon(Icons.computer_outlined),
                    label: Text(
                      uiTextForLanguage('DEPOSITA NEL PC', """DEPOSIT IN PC"""),
                    ),
                  ),
                if (teamSlotIndex != null || egg.isInPc)
                  OutlinedButton.icon(
                    onPressed: onMoveToDayCare,
                    icon: const Icon(Icons.home_work_outlined),
                    label: Text(
                      uiTextForLanguage(
                        'SPOSTA IN PENSIONE',
                        """MOVE TO DAY CARE""",
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            if (egg.isInPc)
              FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.pause_circle_outline),
                label: Text(
                  egg.isReady
                      ? uiTextForLanguage(
                          'RITIRA L’UOVO PER SCHIUDERLO',
                          """MOVE THE EGG TO HATCH IT""",
                        )
                      : uiTextForLanguage(
                          'INCUBAZIONE IN PAUSA NEL PC',
                          """INCUBATION PAUSED IN PC""",
                        ),
                ),
              )
            else if (egg.isReady)
              FilledButton.icon(
                onPressed: onHatch,
                icon: const Icon(Icons.egg_alt_outlined),
                label: Text(
                  uiTextForLanguage('FAI SCHIUDERE', """HATCH EGG"""),
                ),
              )
            else
              FilledButton.icon(
                onPressed: onAdvance,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  incubationAdvantage
                      ? uiTextForLanguage(
                          'AVANZA INCUBAZIONE (2d100, migliore)',
                          """ADVANCE INCUBATION (2d100, best)""",
                        )
                      : uiTextForLanguage(
                          'AVANZA INCUBAZIONE (1d100)',
                          """ADVANCE INCUBATION (1d100)""",
                        ),
                ),
              ),
            if (egg.isReady) ...[
              const SizedBox(height: 6),
              Text(
                egg.isInPc
                    ? uiTextForLanguage(
                        'Nel PC l’uovo resta conservato ma non può schiudersi.',
                        """The egg is safely stored in the PC but cannot hatch there.""",
                      )
                    : teamSlotIndex == null
                    ? uiTextForLanguage(
                        'Alla schiusa il Pokémon verrà inviato al PC dalla Pensione.',
                        """When it hatches, the Pokémon will be sent to the PC from the Day Care.""",
                      )
                    : uiTextForLanguage(
                        'Alla schiusa il Pokémon sostituirà l’uovo nello stesso Pokéslot.',
                        """When it hatches, the Pokémon will replace the egg in the same Poké Slot.""",
                      ),
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
    required this.incubatorQuantities,
    required this.featDescriptions,
  });

  final UserProfile profile;
  final List<Pokemon> catalog;
  final Map<int, Pokemon> catalogById;
  final List<TeamSlot> team;
  final List<BreedingCandidate> candidates;
  final List<BreedingEgg> eggs;
  final Map<int, BreedingSpeciesData> speciesData;
  final Map<EggIncubator, int> incubatorQuantities;
  final Map<String, String> featDescriptions;
}
