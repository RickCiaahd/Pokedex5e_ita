// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../localization/ui_text.dart';
import '../../localization/user_facing_error.dart';
import '../../models/bag_inventory_entry.dart';
import '../../models/bag_item.dart';
import '../../models/battle_environment.dart';
import '../../models/battle_transformation.dart';
import '../../models/evolution_data.dart';
import '../../models/custom_pokemon_advanced_data.dart';
import '../../models/battle_session.dart';
import '../../models/item_driven_pokemon_form.dart';
import '../../models/level_progression.dart';
import '../../models/move_data.dart';
import '../../models/pokemon.dart';
import '../../models/team_slot.dart';
import '../../models/user_profile.dart';
import '../../repositories/bag_inventory_repository.dart';
import '../../repositories/battle_session_repository.dart';
import '../../repositories/evolution_repository.dart';
import '../../repositories/item_repository.dart';
import '../../repositories/move_repository.dart';
import '../../repositories/pokemon_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/team_repository.dart';
import '../../services/battle_environment_service.dart';
import '../../services/battle_form_change_service.dart';
import '../../services/custom_pokemon_runtime_registry.dart';
import '../../services/guided_tour_service.dart';
import '../../services/battle_quick_item_service.dart';
import '../../services/battle_temporary_hp_service.dart';
import '../../services/battle_status_rules.dart';
import '../../services/battle_transformation_service.dart';
import '../../services/trainer_path_passive_service.dart';
import '../../services/pokemon_transform_asset_catalog.dart';
import '../../widgets/battle/battle_environment_card.dart';
import '../../widgets/battle/battle_status_assistance_card.dart';
import '../../widgets/battle/pokemon_battle_attributes_card.dart';
import '../../widgets/battle/pokemon_transformation_image.dart';
import '../../widgets/layout/responsive_content.dart';
import '../../widgets/navigation/home_leading_button.dart';
import '../../widgets/pokemon/pokemon_asset_image.dart';
import '../../widgets/tour/guided_tour.dart';
import '../../widgets/trainer/trainer_path_passive_card.dart';
import '../capture/capture_pokemon_screen.dart';

class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final TeamRepository _teamRepository = TeamRepository();
  final PokemonRepository _pokemonRepository = PokemonRepository();
  final MoveRepository _moveRepository = MoveRepository();
  final ItemRepository _itemRepository = ItemRepository();
  final BagInventoryRepository _bagRepository = BagInventoryRepository();
  final EvolutionRepository _evolutionRepository = EvolutionRepository();
  final BattleSessionRepository _battleSessionRepository =
      BattleSessionRepository();
  final Random _random = Random();
  final GuidedTourController _tourController = GuidedTourController(
    tourId: GuidedTourIds.battle,
  );
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _battleHeaderKey = GlobalKey();
  final GlobalKey _initiativeKey = GlobalKey();
  final GlobalKey _environmentKey = GlobalKey();
  final GlobalKey _activePokemonKey = GlobalKey();
  final GlobalKey _movesKey = GlobalKey();

  late Future<_BattleData> _future;
  final Map<int, Map<String, int>> _remainingPpBySlot = {};
  final Map<int, Set<String>> _volatileStatusesBySlot = {};
  final Map<int, String> _battleFormBySlot = {};
  final Map<int, BattleTransformationState> _transformationBySlot = {};
  final Set<String> _trainerTransformationUses = {};
  final Set<String> _transformedPokemonKeys = {};
  final Map<int, int> _temporaryHpBySlot = {};
  final Map<int, bool> _temporaryHpEnabledBySlot = {};
  final Set<int> _temporaryHpInitializedSlots = {};

  BattleStatusMoment _statusMoment = BattleStatusMoment.turnStart;
  int? _activeSlotIndex;
  int _round = 1;
  BattleEnvironment _environment = const BattleEnvironment();
  String? _message;
  String? _restoredProfileId;
  UserProfile? _activeProfile;
  bool _isBattleReady = false;

  List<GuidedTourStepData> get _tourSteps => [
    GuidedTourStepData(
      targetKey: _battleHeaderKey,
      icon: Icons.groups_outlined,
      title: context.uiText('Squadra e round', 'Team and round'),
      description: context.uiText(
        'In alto controlli il round, termini la battaglia e scegli quale Pokémon della squadra è attivo. La sessione viene conservata finché non la chiudi.',
        'At the top you control the round, end the battle and choose the active Pokémon. The session is preserved until you close it.',
      ),
    ),
    GuidedTourStepData(
      targetKey: _initiativeKey,
      icon: Icons.timelapse_outlined,
      title: context.uiText('Round personale', 'Personal round'),
      description: context.uiText(
        'Quando il Master comunica che torna il tuo turno, usa il pulsante per avanzare il round personale. Non devi gestire l’ordine completo dell’iniziativa.',
        'When the GM says your turn has come back, use the button to advance your personal round. You do not need to manage the full initiative order.',
      ),
      fallbackScrollFraction: .16,
    ),
    GuidedTourStepData(
      targetKey: _environmentKey,
      icon: Icons.public_outlined,
      title: context.uiText('Meteo e terreno', 'Weather and terrain'),
      description: context.uiText(
        'Registra il meteo e il terreno comunicati dal Master. Il Battle Companion applica al Pokémon i modificatori conosciuti, senza generare la scena al posto del Master.',
        'Record the weather and terrain communicated by the GM. The Battle Companion applies known modifiers to the Pokémon without generating the scene for the GM.',
      ),
      fallbackScrollFraction: .30,
    ),
    GuidedTourStepData(
      targetKey: _activePokemonKey,
      icon: Icons.favorite_outline,
      title: context.uiText('Pokémon attivo', 'Active Pokémon'),
      description: context.uiText(
        'Qui gestisci PF, PF temporanei, status, forma di battaglia, oggetto tenuto e Zaino rapido del Pokémon selezionato.',
        'Manage HP, temporary HP, conditions, battle form, held item and the selected Pokémon’s quick Bag.',
      ),
      fallbackScrollFraction: .50,
    ),
    GuidedTourStepData(
      targetKey: _movesKey,
      icon: Icons.flash_on_outlined,
      title: context.uiText('Mosse e PP', 'Moves and PP'),
      description: context.uiText(
        'Le mosse mostrano tiro, CD, danni e PP rimanenti. Usa e ripristina i PP dai pulsanti; quando finiscono, il tracker segnala Struggle.',
        'Moves show rolls, DC, damage and remaining PP. Spend or restore PP with the buttons; when all are depleted, the tracker warns you to use Struggle.',
      ),
      fallbackScrollFraction: 1,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _future = _loadBattleData();
  }

  @override
  void dispose() {
    _tourController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<_BattleData> _loadBattleData() async {
    final profile = await _profileRepository.getActiveProfile();
    _activeProfile = profile;
    final team = await _teamRepository.getTeam(profile.id);
    team.sort((a, b) => a.slotIndex.compareTo(b.slotIndex));

    final pokemonList = await _pokemonRepository.getAllPokemon();
    final pokemonById = {
      for (final pokemon in pokemonList) pokemon.id: pokemon,
    };
    final items = await _itemRepository.getWebItems();
    final inventory = await _bagRepository.getInventory(profile.id);
    final evolutionData = await _evolutionRepository.getEvolutionData();
    final referencesByPokemon = <int, Set<String>>{};
    for (final slot in team) {
      final pokemonId = slot.pokemonId;
      if (pokemonId == null) continue;
      final pokemon = pokemonById[pokemonId];
      if (pokemon == null) continue;
      final references = referencesByPokemon.putIfAbsent(
        pokemonId,
        () => <String>{'Struggle'},
      );
      references.addAll(_movesForSlot(slot, pokemon));
      for (final definition in pokemon.formDefinitions) {
        references.addAll(_movesForSlot(slot, definition.pokemon));
      }
    }
    final moves = await _moveRepository.getMovesByPokemon(referencesByPokemon);

    final data = _BattleData(
      profile: profile,
      team: team,
      pokemonById: pokemonById,
      moves: moves,
      items: items,
      inventory: inventory,
      evolutionData: evolutionData,
    );
    await _restoreOrStartSession(data);
    if (mounted) {
      setState(() => _isBattleReady = data.occupiedSlots.isNotEmpty);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _tourController.showAutomaticallyIfNeeded(ready: _isBattleReady);
      });
    }
    return data;
  }

  Future<void> _reload({String? message}) async {
    if (!mounted) return;
    setState(() {
      _message = message;
      _isBattleReady = false;
      _future = _loadBattleData();
    });
  }

  Future<void> _restoreOrStartSession(_BattleData data) async {
    if (_restoredProfileId == data.profile.id) return;
    _restoredProfileId = data.profile.id;

    _remainingPpBySlot.clear();
    _volatileStatusesBySlot.clear();
    _battleFormBySlot.clear();
    _transformationBySlot.clear();
    _trainerTransformationUses
      ..clear()
      ..addAll(data.profile.transformationUses);
    _transformedPokemonKeys
      ..clear()
      ..addAll(data.profile.transformedPokemonKeys);
    _temporaryHpBySlot.clear();
    _temporaryHpEnabledBySlot.clear();
    _temporaryHpInitializedSlots.clear();
    _round = 1;
    _activeSlotIndex = null;
    _environment = const BattleEnvironment();

    final session = await _battleSessionRepository.getSession(data.profile.id);
    if (session != null) {
      _round = session.round;
      _environment = session.environment;

      for (final state in session.pokemonStates.values) {
        TeamSlot? matchingSlot;
        for (final slot in data.occupiedSlots) {
          if (state.matches(slot)) {
            matchingSlot = slot;
            break;
          }
        }
        if (matchingSlot == null) continue;
        _remainingPpBySlot[matchingSlot.slotIndex] = {...state.remainingPp};
        _volatileStatusesBySlot[matchingSlot.slotIndex] = {
          ...state.volatileStatuses,
        };
        final battleFormName = state.battleFormName;
        if (battleFormName != null && battleFormName.trim().isNotEmpty) {
          _battleFormBySlot[matchingSlot.slotIndex] = battleFormName;
        }
        final transformation = state.transformation;
        if (transformation != null) {
          _transformationBySlot[matchingSlot.slotIndex] = transformation;
        }
        _temporaryHpBySlot[matchingSlot.slotIndex] = state.temporaryHp;
        _temporaryHpEnabledBySlot[matchingSlot.slotIndex] =
            state.temporaryHpEnabled;
        if (state.temporaryHpInitialized) {
          _temporaryHpInitializedSlots.add(matchingSlot.slotIndex);
        }
      }

      final savedActiveSlot = session.activeSlotIndex;
      if (savedActiveSlot != null &&
          data.occupiedSlots.any((slot) => slot.slotIndex == savedActiveSlot)) {
        _activeSlotIndex = savedActiveSlot;
      }
    }

    for (final slot in data.occupiedSlots) {
      if (_temporaryHpInitializedSlots.contains(slot.slotIndex)) continue;
      final pokemonId = slot.pokemonId;
      if (pokemonId == null) continue;
      final basePokemon = data.pokemonById[pokemonId];
      if (basePokemon == null) continue;
      final rule = BattleTemporaryHpService.ruleFor(basePokemon, slot);
      _temporaryHpInitializedSlots.add(slot.slotIndex);
      if (rule == null) continue;
      _temporaryHpEnabledBySlot[slot.slotIndex] = true;
      _temporaryHpBySlot[slot.slotIndex] = rule.maximumForLevel(
        _levelForSlot(slot),
      );
      if (basePokemon.name == 'Mimikyu') {
        _battleFormBySlot[slot.slotIndex] = 'Base';
      }
    }

    final activeSlot = _activeSlotFor(data);
    if (activeSlot != null) _activeSlotIndex = activeSlot.slotIndex;
    await _saveSession(data);
  }

  Future<void> _saveSession(_BattleData data) async {
    final states = <int, BattlePokemonState>{};
    for (final slot in data.occupiedSlots) {
      final pokemonId = slot.pokemonId;
      if (pokemonId == null) continue;
      states[slot.slotIndex] = BattlePokemonState(
        slotIndex: slot.slotIndex,
        pokemonId: pokemonId,
        identityKey: BattlePokemonState.identityKeyFor(slot),
        remainingPp: {...?_remainingPpBySlot[slot.slotIndex]},
        volatileStatuses: {...?_volatileStatusesBySlot[slot.slotIndex]},
        battleFormName: _battleFormBySlot[slot.slotIndex],
        transformation: _transformationBySlot[slot.slotIndex],
        temporaryHp: _temporaryHpBySlot[slot.slotIndex] ?? 0,
        temporaryHpEnabled: _temporaryHpEnabledBySlot[slot.slotIndex] ?? false,
        temporaryHpInitialized: _temporaryHpInitializedSlots.contains(
          slot.slotIndex,
        ),
      );
    }

    await _battleSessionRepository.saveSession(
      BattleSession(
        profileId: data.profile.id,
        round: _round,
        turnIndex: 0,
        activeSlotIndex: _activeSlotIndex,
        pokemonStates: states,
        initiativeEntries: const [],
        environment: _environment,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void _scheduleSessionSave(_BattleData data) {
    unawaited(_saveSession(data));
  }

  TeamSlot? _activeSlotFor(_BattleData data) {
    if (data.occupiedSlots.isEmpty) return null;
    for (final slot in data.occupiedSlots) {
      if (slot.slotIndex == _activeSlotIndex) return slot;
    }
    return data.occupiedSlots.first;
  }

  String? _effectiveFormName(TeamSlot slot) {
    if (ItemDrivenPokemonForm.usesHeldItemForm(slot.pokemonId)) {
      return slot.effectiveFormName;
    }
    if (_battleFormBySlot.containsKey(slot.slotIndex)) {
      return _battleFormBySlot[slot.slotIndex];
    }
    return slot.effectiveFormName;
  }

  Pokemon? _pokemonForSlot(_BattleData data, TeamSlot slot) {
    final pokemonId = slot.pokemonId;
    if (pokemonId == null) return null;
    final basePokemon = data.pokemonById[pokemonId];
    if (basePokemon == null) return null;
    final formName = _effectiveFormName(slot);
    final resolved =
        basePokemon.name == 'Palafin' &&
            BattleFormChangeService.canonicalFormKey(basePokemon, formName) ==
                'hero'
        ? basePokemon
        : basePokemon.resolveVariant(formName: formName, gender: slot.gender);
    return _pokemonWithTransformation(resolved, slot);
  }

  Pokemon _pokemonWithTransformation(Pokemon pokemon, TeamSlot slot) {
    final state = _transformationBySlot[slot.slotIndex];
    if (state == null) return pokemon;

    var types = pokemon.types;
    var size = pokemon.size;
    if (state.kind == BattleTransformationKind.mega &&
        state.formIdentifier != null) {
      final art = PokemonTransformAssetCatalog.byIdentifier(
        state.formIdentifier!,
      );
      if (art != null && art.types.isNotEmpty) types = art.types;
    }
    if (state.kind == BattleTransformationKind.terastal) {
      final teraType = state.teraType;
      if (teraType != null && teraType != 'Stellar') {
        types = [teraType];
      }
    }
    if (state.isDynamaxLike) size = 'Gargantuan';

    return pokemon.copyWith(types: types, size: size);
  }

  List<PokemonFormChoice> _normalizedBattleFormChoices(
    Pokemon pokemon,
    TeamSlot slot,
    List<PokemonFormChoice> choices,
  ) {
    final byKey = <String, PokemonFormChoice>{};
    for (final choice in choices) {
      if (!BattleFormChangeService.isAllowedChoice(
        pokemon: pokemon,
        slot: slot,
        formName: choice.name,
      )) {
        continue;
      }
      final key = BattleFormChangeService.canonicalFormKey(
        pokemon,
        choice.name,
      );
      byKey.putIfAbsent(
        key,
        () => PokemonFormChoice(
          name: BattleFormChangeService.normalizedChoiceName(
            pokemon,
            choice.name,
          ),
          assetPath: choice.assetPath,
        ),
      );
    }
    final result = byKey.values.toList(growable: false)
      ..sort(
        (a, b) => BattleFormChangeService.formSortWeight(
          pokemon,
          a.name,
        ).compareTo(BattleFormChangeService.formSortWeight(pokemon, b.name)),
      );
    return result;
  }

  Future<void> _openBattleFormPicker(_BattleData data, TeamSlot slot) async {
    final pokemonId = slot.pokemonId;
    if (pokemonId == null) return;
    final basePokemon = data.pokemonById[pokemonId];
    if (basePokemon == null || !BattleFormChangeService.supports(basePokemon)) {
      return;
    }

    final allChoices = await PokemonAssetPaths.formChoices(basePokemon);
    final customDefinition = CustomPokemonRuntimeRegistry.definitionFor(
      basePokemon.id,
    );
    final customTemporaryChoices = [
      for (final form in customDefinition?.advanced.forms ?? const [])
        if (form.duration == CustomPokemonFormDuration.battle)
          PokemonFormChoice(name: form.name, assetPath: ''),
    ];
    final choices = _normalizedBattleFormChoices(basePokemon, slot, [
      ...allChoices,
      ...customTemporaryChoices,
    ]);
    if (!mounted || choices.length <= 1) return;

    final selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _BattleFormPickerSheet(
        pokemon: basePokemon,
        slot: slot,
        currentFormName: _effectiveFormName(slot),
        choices: choices,
      ),
    );
    if (!mounted || selected == null) return;

    setState(() {
      _battleFormBySlot[slot.slotIndex] = selected;
      _message =
          '${_displayName(slot, basePokemon)} assume la ${BattleFormChangeService.formLabel(basePokemon, selected)}.';
    });
    await _saveSession(data);
  }

  bool _isFinalEvolutionStage(_BattleData data, Pokemon pokemon) {
    final direct = data.evolutionData[pokemon.name];
    if (direct != null) return direct.evolutions.isEmpty;
    final wanted = MoveData.referenceKey(pokemon.name);
    for (final entry in data.evolutionData.entries) {
      if (MoveData.referenceKey(entry.key) == wanted) {
        return entry.value.evolutions.isEmpty;
      }
    }
    return true;
  }

  List<MoveData> _knownMoveData(
    _BattleData data,
    TeamSlot slot,
    Pokemon pokemon,
  ) {
    final result = <MoveData>[];
    for (final reference in _movesForSlot(slot, pokemon)) {
      final move =
          data.moves[MoveRepository.contextualKey(slot.pokemonId!, reference)];
      if (move != null) result.add(_contextualMove(move, slot));
    }
    return result;
  }

  TransformationEligibility _transformationEligibility(
    BattleTransformationKind kind,
    _BattleData data,
    TeamSlot slot,
    Pokemon pokemon,
  ) {
    return BattleTransformationService.eligibility(
      kind: kind,
      pokemonLevel: _levelForSlot(slot),
      isFinalEvolutionStage: _isFinalEvolutionStage(
        data,
        data.pokemonById[slot.pokemonId!]!,
      ),
      heldItemId: data.heldItemFor(slot)?.id,
      inventory: data.inventory,
      trainerUses: _trainerTransformationUses,
      pokemonAlreadyTransformed: _transformedPokemonKeys.contains(
        BattleTransformationService.pokemonUsageKey(slot),
      ),
      hasActiveTransformation: _transformationBySlot.containsKey(
        slot.slotIndex,
      ),
      knownMoves: _knownMoveData(data, slot, pokemon),
    );
  }

  void _showTransformationBlocked(TransformationEligibility eligibility) {
    if (!mounted || eligibility.missingRequirements.isEmpty) return;
    setState(() {
      _message = eligibility.missingRequirements.join(' · ');
    });
  }

  Future<void> _recordTransformationUse(
    _BattleData data,
    TeamSlot slot,
    BattleTransformationKind kind,
  ) async {
    _trainerTransformationUses.add(kind.trainerUseId);
    _transformedPokemonKeys.add(
      BattleTransformationService.pokemonUsageKey(slot),
    );
    final currentProfile = await _profileRepository.getActiveProfile();
    if (currentProfile.id != data.profile.id) return;
    final updated = currentProfile.copyWith(
      transformationUses: _trainerTransformationUses.toList()..sort(),
      transformedPokemonKeys: _transformedPokemonKeys.toList()..sort(),
    );
    await _profileRepository.saveProfile(updated);
    _activeProfile = updated;
  }

  Future<void> _activateMega(
    _BattleData data,
    TeamSlot slot,
    Pokemon pokemon,
  ) async {
    final eligibility = _transformationEligibility(
      BattleTransformationKind.mega,
      data,
      slot,
      pokemon,
    );
    if (!eligibility.isAvailable) {
      _showTransformationBlocked(eligibility);
      return;
    }
    if (_currentHpFor(slot, pokemon) <= 0) {
      setState(() => _message = 'Un Pokémon esausto non può megaevolversi.');
      return;
    }

    final options = PokemonTransformAssetCatalog.megaOptions(
      pokemon.id,
      formName: _effectiveFormName(slot),
      gender: slot.gender,
    );
    PokemonTransformArt? selected;
    if (options.length == 1) {
      selected = options.first;
    } else if (options.length > 1) {
      selected = await showModalBottomSheet<PokemonTransformArt>(
        context: context,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => _TransformArtPickerSheet(
          title: 'Scegli la Mega Evoluzione',
          pokemonName: pokemon.name,
          options: options,
          isShiny: slot.isShiny,
        ),
      );
      if (!mounted || selected == null) return;
    }

    final state = BattleTransformationState(
      kind: BattleTransformationKind.mega,
      formIdentifier: selected?.identifier,
    );
    setState(() {
      _transformationBySlot[slot.slotIndex] = state;
      _message =
          '${_displayName(slot, pokemon)} attiva ${selected?.label ?? 'Mega Evoluzione'}.';
    });
    await _recordTransformationUse(data, slot, state.kind);
    await _saveSession(data);
  }

  Future<void> _activateDynamax(
    _BattleData data,
    TeamSlot slot,
    Pokemon pokemon,
  ) async {
    final eligibility = _transformationEligibility(
      BattleTransformationKind.dynamax,
      data,
      slot,
      pokemon,
    );
    if (!eligibility.isAvailable) {
      _showTransformationBlocked(eligibility);
      return;
    }
    final currentHp = _currentHpFor(slot, pokemon);
    if (currentHp <= 0) {
      setState(() => _message = 'Un Pokémon esausto non può Dynamaxizzarsi.');
      return;
    }

    final gmaxOptions = PokemonTransformAssetCatalog.gigamaxOptions(
      pokemon.id,
      formName: _effectiveFormName(slot),
      gender: slot.gender,
    );
    final choice = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _DynamaxPickerSheet(
        pokemonName: pokemon.name,
        gigamaxOptions: gmaxOptions,
        isShiny: slot.isShiny,
      ),
    );
    if (!mounted || choice == null) return;
    final selectedArt = choice == 'dynamax'
        ? null
        : PokemonTransformAssetCatalog.byIdentifier(choice);
    final kind = selectedArt == null
        ? BattleTransformationKind.dynamax
        : BattleTransformationKind.gigamax;
    final state = BattleTransformationState(
      kind: kind,
      formIdentifier: selectedArt?.identifier,
      dynamaxTemporaryHp: currentHp,
    );
    setState(() {
      _transformationBySlot[slot.slotIndex] = state;
      _message =
          '${_displayName(slot, pokemon)} attiva ${selectedArt?.label ?? 'Dynamax'} e ottiene $currentHp PF temporanei.';
    });
    await _recordTransformationUse(data, slot, kind);
    await _saveSession(data);
  }

  Future<void> _activateTerastal(
    _BattleData data,
    TeamSlot slot,
    Pokemon pokemon,
  ) async {
    final eligibility = _transformationEligibility(
      BattleTransformationKind.terastal,
      data,
      slot,
      pokemon,
    );
    if (!eligibility.isAvailable) {
      _showTransformationBlocked(eligibility);
      return;
    }
    if (_currentHpFor(slot, pokemon) <= 0) {
      setState(
        () => _message = 'Un Pokémon esausto non può teracristallizzarsi.',
      );
      return;
    }

    final teraType = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _TeraTypePickerSheet(
        pokemonName: pokemon.name,
        initialType: pokemon.types.isEmpty ? null : pokemon.types.first,
      ),
    );
    if (!mounted || teraType == null) return;

    final state = BattleTransformationState(
      kind: BattleTransformationKind.terastal,
      teraType: teraType,
    );
    setState(() {
      _transformationBySlot[slot.slotIndex] = state;
      _message =
          '${_displayName(slot, pokemon)} si teracristallizza nel tipo $teraType.';
    });
    await _recordTransformationUse(data, slot, state.kind);
    await _saveSession(data);
  }

  Future<void> _useZMove(
    _BattleData data,
    TeamSlot slot,
    Pokemon pokemon,
  ) async {
    final eligibility = _transformationEligibility(
      BattleTransformationKind.zMove,
      data,
      slot,
      pokemon,
    );
    if (!eligibility.isAvailable) {
      _showTransformationBlocked(eligibility);
      return;
    }
    if (_currentHpFor(slot, pokemon) <= 0) {
      setState(
        () => _message = 'Un Pokémon esausto non può usare una Mossa Z.',
      );
      return;
    }

    final crystal = BattleTransformationService.zCrystalForHeldItem(
      data.heldItemFor(slot)?.id,
    );
    if (crystal == null) return;
    final choices = <_ZMoveChoice>[];
    for (final reference in _movesForSlot(slot, pokemon)) {
      final rawMove =
          data.moves[MoveRepository.contextualKey(slot.pokemonId!, reference)];
      if (rawMove == null) continue;
      final move = _contextualMove(rawMove, slot);
      if (MoveData.referenceKey(move.type) !=
          MoveData.referenceKey(crystal.type)) {
        continue;
      }
      final maxPp = _maxPpFor(rawMove);
      if (maxPp > 0 && _remainingPp(slot, reference, rawMove) <= 0) continue;
      choices.add(
        _ZMoveChoice(reference: reference, move: move, rawMove: rawMove),
      );
    }
    if (choices.isEmpty) {
      setState(
        () => _message = 'Nessuna Mossa Z compatibile ha PP disponibili.',
      );
      return;
    }

    final selected = await showModalBottomSheet<_ZMoveChoice>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _ZMovePickerSheet(
        pokemonName: pokemon.name,
        crystalType: crystal.type,
        choices: choices,
      ),
    );
    if (!mounted || selected == null) return;

    final state = BattleTransformationState(
      kind: BattleTransformationKind.zMove,
      zMoveReference: selected.reference,
    );
    setState(() {
      _transformationBySlot[slot.slotIndex] = state;
    });
    if (_maxPpFor(selected.rawMove) > 0) {
      _changePp(data, slot, selected.reference, selected.rawMove, -1);
    }
    setState(() {
      _message =
          'Mossa Z · ${selected.move.name}: ${BattleTransformationService.zMoveSummary(selected.move)}.';
    });
    await _recordTransformationUse(data, slot, state.kind);
    await _saveSession(data);
  }

  Future<void> _openTransformationMenu({
    required _BattleData data,
    required TeamSlot slot,
    required Pokemon pokemon,
    required Pokemon basePokemon,
    required String? effectiveFormName,
    required BattleTransformationState? currentState,
    required TransformationEligibility megaEligibility,
    required TransformationEligibility zMoveEligibility,
    required TransformationEligibility dynamaxEligibility,
    required TransformationEligibility terastalEligibility,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        child: _TransformationPanel(
          currentState: currentState,
          megaEligibility: megaEligibility,
          zMoveEligibility: zMoveEligibility,
          dynamaxEligibility: dynamaxEligibility,
          terastalEligibility: terastalEligibility,
          hasCanonicalMega: PokemonTransformAssetCatalog.megaOptions(
            basePokemon.id,
            formName: effectiveFormName,
            gender: slot.gender,
          ).isNotEmpty,
          hasGigamax: PokemonTransformAssetCatalog.gigamaxOptions(
            basePokemon.id,
            formName: effectiveFormName,
            gender: slot.gender,
          ).isNotEmpty,
          onMega: () {
            Navigator.of(sheetContext).pop();
            _activateMega(data, slot, pokemon);
          },
          onZMove: () {
            Navigator.of(sheetContext).pop();
            _useZMove(data, slot, pokemon);
          },
          onDynamax: () {
            Navigator.of(sheetContext).pop();
            _activateDynamax(data, slot, pokemon);
          },
          onTerastal: () {
            Navigator.of(sheetContext).pop();
            _activateTerastal(data, slot, pokemon);
          },
        ),
      ),
    );
  }

  List<String> _movesForSlot(TeamSlot slot, Pokemon pokemon) {
    if (slot.selectedMoves.isNotEmpty) {
      return slot.selectedMoves.take(4).toList(growable: false);
    }

    final names = <String>[...pokemon.moves.startingMoves];
    final learnedMoves =
        pokemon.moves.levelMoves.entries
            .where((entry) => entry.key <= _levelForSlot(slot))
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in learnedMoves) {
      names.addAll(entry.value);
    }

    return names.toSet().take(4).toList(growable: false);
  }

  int _levelForSlot(TeamSlot slot) {
    return LevelProgression.levelFromExperience(slot.experience);
  }

  int _modifier(int score) => ((score - 10) / 2).floor();

  int _trainerInitiativeBonus(UserProfile profile) {
    return _modifier(profile.abilityScores['DEX'] ?? 10);
  }

  int _maxPpFor(MoveData? move) {
    if (move == null) return 0;
    final direct = int.tryParse(move.pp.trim());
    if (direct != null) return direct;
    final match = RegExp(r'\d+').firstMatch(move.pp);
    return int.tryParse(match?.group(0) ?? '') ?? 0;
  }

  String _ppKey(String reference, MoveData? move) {
    return move?.id ?? MoveData.referenceKey(reference);
  }

  int _remainingPp(TeamSlot slot, String reference, MoveData? move) {
    final maxPp = _maxPpFor(move);
    final slotPp = _remainingPpBySlot.putIfAbsent(slot.slotIndex, () => {});
    return slotPp.putIfAbsent(_ppKey(reference, move), () => maxPp);
  }

  void _changePp(
    _BattleData data,
    TeamSlot slot,
    String reference,
    MoveData? move,
    int delta,
  ) {
    final maxPp = _maxPpFor(move);
    if (maxPp <= 0) return;

    final slotPp = _remainingPpBySlot.putIfAbsent(slot.slotIndex, () => {});
    final key = _ppKey(reference, move);
    final current = slotPp[key] ?? maxPp;

    setState(() {
      slotPp[key] = (current + delta).clamp(0, maxPp).toInt();
      if (delta < 0) {
        _statusMoment = BattleStatusMoment.actionAttempt;
        if (BattleEnvironmentService.isEnvironmentMove(move)) {
          _environment = BattleEnvironmentService.applyMove(
            environment: _environment,
            move: move!,
            sourceLevel: _levelForSlot(slot),
            heldItemId: data.heldItemFor(slot)?.id,
          );
          _message = BattleEnvironmentService.environmentMoveMessage(move);
        }
      }
    });
    _scheduleSessionSave(data);
  }

  bool _hasNoPpLeft(
    TeamSlot slot,
    List<String> moveReferences,
    Map<String, MoveData?> moves,
  ) {
    final pokemonId = slot.pokemonId;
    if (pokemonId == null) return false;
    MoveData? resolve(String reference) =>
        moves[MoveRepository.contextualKey(pokemonId, reference)];
    final trackableMoves = moveReferences
        .where((reference) => _maxPpFor(resolve(reference)) > 0)
        .toList(growable: false);

    return trackableMoves.isNotEmpty &&
        trackableMoves.every((reference) {
          return _remainingPp(slot, reference, resolve(reference)) <= 0;
        });
  }

  int _currentHpFor(TeamSlot slot, Pokemon pokemon) {
    return slot.currentHp.clamp(0, _maxHpFor(pokemon, slot)).toInt();
  }

  BattleTemporaryHpRule? _temporaryHpRule(_BattleData data, TeamSlot slot) {
    final pokemonId = slot.pokemonId;
    if (pokemonId == null) return null;
    final basePokemon = data.pokemonById[pokemonId];
    if (basePokemon == null) return null;
    return BattleTemporaryHpService.ruleFor(basePokemon, slot);
  }

  Future<void> _toggleTemporaryHpRule(
    _BattleData data,
    TeamSlot slot,
    bool enabled,
  ) async {
    final rule = _temporaryHpRule(data, slot);
    if (rule == null) return;
    final basePokemon = data.pokemonById[slot.pokemonId!]!;
    setState(() {
      _temporaryHpInitializedSlots.add(slot.slotIndex);
      _temporaryHpEnabledBySlot[slot.slotIndex] = enabled;
      _temporaryHpBySlot[slot.slotIndex] = enabled
          ? rule.maximumForLevel(_levelForSlot(slot))
          : 0;
      if (basePokemon.name == 'Mimikyu') {
        _battleFormBySlot[slot.slotIndex] = enabled
            ? 'Base'
            : rule.brokenFormName ?? 'Busted';
      }
      _message = enabled
          ? context.uiText(
              '${rule.label} attivato: ${_temporaryHpBySlot[slot.slotIndex]} PF temporanei.',
              '${rule.label} enabled: ${_temporaryHpBySlot[slot.slotIndex]} temporary HP.',
            )
          : context.uiText(
              '${rule.label} disattivato.',
              '${rule.label} disabled.',
            );
    });
    await _saveSession(data);
  }

  void _replaceTeamSlot(_BattleData data, TeamSlot updatedSlot) {
    final index = data.team.indexWhere(
      (candidate) => candidate.slotIndex == updatedSlot.slotIndex,
    );
    if (index >= 0) data.team[index] = updatedSlot;
  }

  Future<void> _changeHp(_BattleData data, TeamSlot slot, int delta) async {
    final pokemon = _pokemonForSlot(data, slot);
    if (pokemon == null) return;

    final maxHp = _maxHpFor(pokemon, slot);
    var hpDelta = delta;
    var dynamaxAbsorbed = 0;
    var absorbed = 0;

    final transformation = _transformationBySlot[slot.slotIndex];
    if (delta < 0 && transformation?.isDynamaxLike == true) {
      final currentTemporaryHp = transformation!.dynamaxTemporaryHp;
      dynamaxAbsorbed = min(currentTemporaryHp, -hpDelta);
      if (dynamaxAbsorbed > 0) {
        final remainingTemporaryHp = currentTemporaryHp - dynamaxAbsorbed;
        hpDelta += dynamaxAbsorbed;
        if (remainingTemporaryHp <= 0) {
          _transformationBySlot.remove(slot.slotIndex);
        } else {
          _transformationBySlot[slot.slotIndex] = transformation.copyWith(
            dynamaxTemporaryHp: remainingTemporaryHp,
          );
        }
      }
    }

    final rule = _temporaryHpRule(data, slot);
    if (hpDelta < 0 &&
        rule != null &&
        (_temporaryHpEnabledBySlot[slot.slotIndex] ?? false)) {
      final currentTemporaryHp = _temporaryHpBySlot[slot.slotIndex] ?? 0;
      absorbed = min(currentTemporaryHp, -hpDelta);
      if (absorbed > 0) {
        final remainingTemporaryHp = currentTemporaryHp - absorbed;
        _temporaryHpBySlot[slot.slotIndex] = remainingTemporaryHp;
        hpDelta += absorbed;
        if (remainingTemporaryHp == 0) {
          _temporaryHpEnabledBySlot[slot.slotIndex] = false;
          final basePokemon = data.pokemonById[slot.pokemonId!];
          if (basePokemon?.name == 'Mimikyu') {
            _battleFormBySlot[slot.slotIndex] = rule.brokenFormName ?? 'Busted';
          }
        }
      }
    }

    final updatedHp = (_currentHpFor(slot, pokemon) + hpDelta)
        .clamp(0, maxHp)
        .toInt();
    if (updatedHp == 0) {
      _transformationBySlot.remove(slot.slotIndex);
    }
    final updatedSlot = slot.copyWith(currentHp: updatedHp);
    await _teamRepository.updateSlot(
      profileId: data.profile.id,
      updatedSlot: updatedSlot,
    );
    _replaceTeamSlot(data, updatedSlot);
    await _saveSession(data);

    final messages = <String>[];
    if (dynamaxAbsorbed > 0) {
      final stillActive =
          _transformationBySlot[slot.slotIndex]?.isDynamaxLike == true;
      messages.add(
        stillActive
            ? '$dynamaxAbsorbed danni assorbiti dai PF Dynamax.'
            : '$dynamaxAbsorbed danni assorbiti: Dynamax/Gigamax termina.',
      );
    }
    if (absorbed > 0) {
      messages.add(
        (_temporaryHpBySlot[slot.slotIndex] ?? 0) > 0
            ? '$absorbed danni assorbiti dai PF temporanei.'
            : '$absorbed danni assorbiti: ${rule?.label ?? 'la protezione'} si spezza.',
      );
    }
    if (!mounted) return;
    setState(() {
      _message = messages.isEmpty ? null : messages.join(' ');
    });
  }

  Future<void> _editHp(_BattleData data, TeamSlot slot) async {
    final pokemon = _pokemonForSlot(data, slot);
    if (pokemon == null) return;

    final input = await showDialog<String>(
      context: context,
      builder: (_) => _HpInputDialog(
        currentHp: _currentHpFor(slot, pokemon),
        maxHp: _maxHpFor(pokemon, slot),
      ),
    );
    if (!mounted || input == null) return;

    final value = int.tryParse(input.trim());
    if (value == null) return;

    final trimmedInput = input.trim();
    if (trimmedInput.startsWith('+') || trimmedInput.startsWith('-')) {
      await _changeHp(data, slot, value);
      return;
    }

    final maxHp = _maxHpFor(pokemon, slot);
    final updatedHp = value.clamp(0, maxHp).toInt();

    if (updatedHp == 0) {
      _transformationBySlot.remove(slot.slotIndex);
    }
    final updatedSlot = slot.copyWith(currentHp: updatedHp);
    await _teamRepository.updateSlot(
      profileId: data.profile.id,
      updatedSlot: updatedSlot,
    );
    _replaceTeamSlot(data, updatedSlot);
    await _saveSession(data);
    if (!mounted) return;
    setState(() => _message = null);
  }

  Future<void> _healFull(_BattleData data, TeamSlot slot) async {
    final pokemon = _pokemonForSlot(data, slot);
    if (pokemon == null) return;

    _volatileStatusesBySlot.remove(slot.slotIndex);
    final rule = _temporaryHpRule(data, slot);
    if (rule != null) {
      _temporaryHpInitializedSlots.add(slot.slotIndex);
      _temporaryHpEnabledBySlot[slot.slotIndex] = true;
      _temporaryHpBySlot[slot.slotIndex] = rule.maximumForLevel(
        _levelForSlot(slot),
      );
      final basePokemon = data.pokemonById[slot.pokemonId!];
      if (basePokemon?.name == 'Mimikyu') {
        _battleFormBySlot[slot.slotIndex] = 'Base';
      }
    }
    final updatedSlot = slot.copyWith(
      currentHp: _maxHpFor(pokemon, slot),
      statusEffects: const [],
    );
    await _teamRepository.updateSlot(
      profileId: data.profile.id,
      updatedSlot: updatedSlot,
    );
    _replaceTeamSlot(data, updatedSlot);
    await _saveSession(data);
    if (!mounted) return;
    setState(() {
      _message = context.uiText(
        '${_displayName(updatedSlot, pokemon)} è pronto a combattere.',
        '${_displayName(updatedSlot, pokemon)} is ready to battle.',
      );
    });
  }

  Future<void> _useHeldBerry(_BattleData data, TeamSlot slot) async {
    final pokemon = _pokemonForSlot(data, slot);
    final heldItem = data.heldItemFor(slot);
    if (pokemon == null || heldItem == null || heldItem.type != 'berry') return;

    final result = _applyMedicine(
      item: heldItem,
      slot: slot,
      pokemon: pokemon,
      volatileStatuses: _volatileStatusesFor(slot),
    );
    final updatedSlot = (result?.updatedSlot ?? slot).copyWith(heldItem: null);

    await _teamRepository.updateSlot(
      profileId: data.profile.id,
      updatedSlot: updatedSlot,
    );
    _replaceTeamSlot(data, updatedSlot);
    if (result != null) {
      _volatileStatusesBySlot[slot.slotIndex] = result.volatileStatuses;
    }
    await _saveSession(data);
    if (!mounted) return;
    setState(() {
      _message =
          result?.message ??
          context.uiText(
            '${heldItem.name} è stato consumato. Applica manualmente il suo effetto se necessario.',
            '${heldItem.name} was consumed. Apply its effect manually if needed.',
          );
    });
  }

  Future<void> _openQuickBag(_BattleData data, TeamSlot slot) async {
    final pokemon = _pokemonForSlot(data, slot);
    if (pokemon == null) return;

    try {
      final inventory = await _bagRepository.getInventory(data.profile.id);
      final items = BattleQuickItemService.resolve(
        catalog: data.items,
        inventory: inventory,
      );
      if (!mounted) return;

      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.uiText(
                'Non hai medicine, bacche utilizzabili o Poké Ball nello zaino.',
                'You have no medicine, usable Berries or Poké Balls in the Bag.',
              ),
            ),
          ),
        );
        return;
      }

      final selected = await showModalBottomSheet<BattleQuickItem>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => _QuickBagSheet(
          items: items,
          pokemonName: _displayName(slot, pokemon),
          currentHp: _currentHpFor(slot, pokemon),
          maxHp: _maxHpFor(pokemon, slot),
          nonVolatileStatus: _nonVolatileStatusFor(slot),
          volatileStatuses: _volatileStatusesFor(slot),
        ),
      );
      if (!mounted || selected == null) return;

      await _useBattleItem(data, slot, pokemon, selected);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.uiText(
              'Impossibile aprire lo zaino rapido: $error',
              'Could not open the quick Bag: $error',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _useBattleItem(
    _BattleData data,
    TeamSlot slot,
    Pokemon pokemon,
    BattleQuickItem selected,
  ) async {
    final item = selected.item;

    if (BattleQuickItemService.isPokeball(item)) {
      await _throwPokeball(data, item);
      return;
    }

    final isBerry = BattleQuickItemService.isBerry(item);
    final result = _applyMedicine(
      item: item,
      slot: slot,
      pokemon: pokemon,
      volatileStatuses: _volatileStatusesFor(slot),
    );

    if (result == null && !isBerry) {
      await _reload(
        message:
            '${item.name} non avrebbe effetto su ${_displayName(slot, pokemon)}.',
      );
      return;
    }

    final consumed = await _bagRepository.consumeItem(
      profileId: data.profile.id,
      itemId: item.id,
    );
    if (!consumed) {
      await _reload(
        message: context.uiText(
          'Non hai più ${item.name} nello zaino.',
          'You have no more ${item.name} in the Bag.',
        ),
      );
      return;
    }

    if (result != null) {
      await _teamRepository.updateSlot(
        profileId: data.profile.id,
        updatedSlot: result.updatedSlot,
      );
      _replaceTeamSlot(data, result.updatedSlot);
      _volatileStatusesBySlot[slot.slotIndex] = result.volatileStatuses;
      await _saveSession(data);
      if (!mounted) return;
      setState(() => _message = result.message);
      return;
    }

    await _reload(
      message: context.uiText(
        '${item.name} è stato consumato. Applica manualmente il suo effetto se necessario.',
        '${item.name} was consumed. Apply its effect manually if needed.',
      ),
    );
  }

  Future<void> _throwPokeball(_BattleData data, BagItem ball) async {
    final caught = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        scrollable: true,
        title: Text(
          context.uiText('Lancia ${ball.name}?', 'Throw ${ball.name}?'),
        ),
        content: Text(
          context.uiText(
            'Dopo il tiro, inserisci l’esito comunicato dal Master. La Poké Ball verrà consumata in ogni caso.',
            'After the roll, enter the result given by the GM. The Poké Ball will be consumed either way.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.uiText('Annulla', 'Cancel')),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.uiText('NO, FALLITA', 'NO, FAILED')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.uiText('SÌ, CATTURATO', 'YES, CAUGHT')),
          ),
        ],
      ),
    );

    if (!mounted || caught == null) return;

    final consumed = await _bagRepository.consumeItem(
      profileId: data.profile.id,
      itemId: ball.id,
    );
    if (!consumed) {
      await _reload(
        message: context.uiText(
          'Non hai più ${ball.name} nello zaino.',
          'You have no more ${ball.name} in the Bag.',
        ),
      );
      return;
    }

    if (!caught) {
      await _reload(
        message: context.uiText(
          '${ball.name} consumata. Cattura fallita.',
          '${ball.name} consumed. Catch failed.',
        ),
      );
      return;
    }

    await _reload(
      message: context.uiText(
        '${ball.name} consumata. Registra il Pokémon catturato.',
        '${ball.name} consumed. Record the caught Pokémon.',
      ),
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CapturePokemonScreen()),
    );
    await _reload();
  }

  _MedicineUseResult? _applyMedicine({
    required BagItem item,
    required TeamSlot slot,
    required Pokemon pokemon,
    required Set<String> volatileStatuses,
  }) {
    if (!_isMedicine(item.id)) return null;

    final maxHp = _maxHpFor(pokemon, slot);
    final currentHp = slot.currentHp.clamp(0, maxHp).toInt();
    final nonVolatileStatuses = [..._nonVolatileStatusesFromSlot(slot)];
    final currentVolatileStatuses = [...volatileStatuses];
    var updatedHp = currentHp;
    var updatedNonVolatile = [...nonVolatileStatuses];
    var updatedVolatile = [...currentVolatileStatuses];
    var hpText = '';
    var statusText = '';

    final healingAmount = _healingAmount(item.id);
    final isRevive = _reviveItemIds.contains(item.id);

    if (healingAmount != null) {
      if (currentHp <= 0 && !isRevive) return null;
      if (currentHp > 0 && isRevive) return null;
      updatedHp = (currentHp + healingAmount).clamp(0, maxHp).toInt();
      if (updatedHp != currentHp) {
        hpText = 'recupera ${updatedHp - currentHp} HP';
      }
    }

    final curedNonVolatile = _statusesCuredBy(item.id, nonVolatileStatuses);
    final curedVolatile = _statusesCuredBy(item.id, currentVolatileStatuses);
    final curedStatuses = [...curedNonVolatile, ...curedVolatile];

    if (curedStatuses.isNotEmpty) {
      updatedNonVolatile = updatedNonVolatile
          .where((status) => !curedNonVolatile.contains(status))
          .toList(growable: false);
      updatedVolatile = updatedVolatile
          .where((status) => !curedVolatile.contains(status))
          .toList(growable: false);
      statusText =
          curedStatuses.length ==
              nonVolatileStatuses.length + currentVolatileStatuses.length
          ? 'guarisce dagli status'
          : 'guarisce da ${curedStatuses.join(', ')}';
    }

    if (updatedHp == currentHp &&
        _sameStrings(updatedNonVolatile, nonVolatileStatuses) &&
        _sameStrings(updatedVolatile, currentVolatileStatuses)) {
      return null;
    }

    final effects = [
      hpText,
      statusText,
    ].where((effect) => effect.isNotEmpty).join(' e ');

    return _MedicineUseResult(
      updatedSlot: slot.copyWith(
        currentHp: updatedHp,
        statusEffects: updatedNonVolatile,
      ),
      volatileStatuses: updatedVolatile.toSet(),
      message: context.uiText(
        '${_displayName(slot, pokemon)} $effects usando ${item.name}.',
        '${_displayName(slot, pokemon)} $effects using ${item.name}.',
      ),
    );
  }

  bool _isMedicine(String itemId) {
    return _healingItemIds.contains(itemId) ||
        _statusMedicineItemIds.contains(itemId) ||
        _berryMedicineItemIds.contains(itemId);
  }

  int? _healingAmount(String itemId) {
    switch (itemId) {
      case 'potion':
      case 'revive':
      case 'oran-berry':
        return _rollDice(2, 4, 2);
      case 'super-potion':
      case 'energy-powder':
        return _rollDice(3, 6, 6);
      case 'hyper-potion':
      case 'energy-root':
      case 'max-revive':
      case 'revival-herb':
        return _rollDice(4, 12, 10);
      case 'max-potion':
      case 'full-restore':
        return 70;
      case 'sitrus-berry':
      case 'lemonade':
        return 30;
      case 'fresh-water':
        return 7;
      case 'soda-pop':
        return 10;
      case 'berry-juice':
        return 20;
      case 'moomoo-milk':
        return 50;
      default:
        return null;
    }
  }

  int _rollDice(int count, int sides, int bonus) {
    var total = bonus;
    for (var i = 0; i < count; i++) {
      total += _random.nextInt(sides) + 1;
    }
    return total;
  }

  List<String> _statusesCuredBy(String itemId, List<String> statuses) {
    final targets = _statusTargetsByItem[itemId];
    if (targets == null) return const [];
    if (targets.contains('*')) return List<String>.from(statuses);
    return statuses.where(targets.contains).toList(growable: false);
  }

  bool _sameStrings(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  List<String> _nonVolatileStatusesFromSlot(TeamSlot slot) {
    return slot.statusEffects
        .where(_nonVolatileStatusOptions.contains)
        .take(1)
        .toList(growable: false);
  }

  String? _nonVolatileStatusFor(TeamSlot slot) {
    final statuses = _nonVolatileStatusesFromSlot(slot);
    return statuses.isEmpty ? null : statuses.first;
  }

  Set<String> _volatileStatusesFor(TeamSlot slot) {
    return {
      ...?_volatileStatusesBySlot[slot.slotIndex],
      ...slot.statusEffects.where(_volatileStatusOptions.contains),
    };
  }

  Future<void> _openStatusPicker(_BattleData data, TeamSlot slot) async {
    final result = await showModalBottomSheet<_StatusPickerResult>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _StatusPickerSheet(
        initialNonVolatileStatus: _nonVolatileStatusFor(slot),
        initialVolatileStatuses: _volatileStatusesFor(slot),
      ),
    );
    if (!mounted || result == null) return;

    _statusMoment = BattleStatusMoment.turnStart;
    final blocksVolatile = BattleTransformationService.isDynamaxLike(
      _transformationBySlot[slot.slotIndex],
    );
    _volatileStatusesBySlot[slot.slotIndex] = blocksVolatile
        ? <String>{}
        : result.volatileStatuses;
    await _teamRepository.updateSlot(
      profileId: data.profile.id,
      updatedSlot: slot.copyWith(
        statusEffects: result.nonVolatileStatus == null
            ? const []
            : [result.nonVolatileStatus!],
      ),
    );
    await _saveSession(data);
    await _reload(
      message: blocksVolatile && result.volatileStatuses.isNotEmpty
          ? context.uiText(
              'Dynamax/Gigamax è immune agli status volatili.',
              'Dynamax/Gigamax is immune to volatile conditions.',
            )
          : null,
    );
  }

  Future<void> _editEnvironment(_BattleData data) async {
    final result = await showBattleEnvironmentDialog(
      context: context,
      initial: _environment,
    );
    if (!mounted || result == null) return;
    setState(() {
      _environment = result;
      _message = context.uiText(
        'Meteo e terreno aggiornati.',
        'Weather and terrain updated.',
      );
    });
    _scheduleSessionSave(data);
  }

  void _nextPlayerRound(_BattleData data) {
    setState(() {
      _statusMoment = BattleStatusMoment.turnStart;
      _round += 1;
      _environment = _environment.advanceRound();
      _message = context.uiText(
        'Round $_round iniziato.',
        'Round $_round started.',
      );
    });
    _scheduleSessionSave(data);
  }

  Future<void> _endBattle(_BattleData data) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        scrollable: true,
        title: Text(
          context.uiText('Terminare la battaglia?', 'End the battle?'),
        ),
        content: Text(
          context.uiText(
            'Round personale, PP, PF temporanei, forme di battaglia, trasformazioni attive e status volatili verranno rimossi. Gli utilizzi di Mega/Z/Dynamax/Tera resteranno consumati fino al prossimo riposo lungo.',
            'Personal round, PP, temporary HP, battle forms, active transformations and volatile conditions will be cleared. Mega/Z/Dynamax/Tera uses remain spent until the next long rest.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.uiText('ANNULLA', 'CANCEL')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.uiText('TERMINA', 'END')),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    await _battleSessionRepository.deleteSession(data.profile.id);
    _remainingPpBySlot.clear();
    _volatileStatusesBySlot.clear();
    _battleFormBySlot.clear();
    _transformationBySlot.clear();
    _temporaryHpBySlot.clear();
    _temporaryHpEnabledBySlot.clear();
    _temporaryHpInitializedSlots.clear();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  int _maxHpFor(Pokemon pokemon, TeamSlot slot) {
    return TrainerPathPassiveService.maxHp(
      profile: _activeProfile,
      pokemon: pokemon,
      slot: slot,
      level: _levelForSlot(slot),
    );
  }

  Map<String, int> _attributeScores(
    Pokemon pokemon,
    TeamSlot slot, {
    Pokemon? basePokemon,
    String? formName,
  }) {
    final scores = TrainerPathPassiveService.effectiveAttributeScores(
      profile: _activeProfile,
      pokemon: pokemon,
      slot: slot,
    );
    final sourcePokemon = basePokemon ?? pokemon;
    return BattleFormChangeService.applyAttributeScoreModifiers(
      sourcePokemon,
      formName,
      scores,
    );
  }

  int _proficiency(int level) {
    if (level >= 17) return 6;
    if (level >= 13) return 5;
    if (level >= 9) return 4;
    if (level >= 5) return 3;
    return 2;
  }

  int _bestMoveModifier(
    MoveData move,
    Pokemon pokemon,
    TeamSlot slot, {
    required Pokemon basePokemon,
    required String? formName,
  }) {
    final attributes = _attributeScores(
      pokemon,
      slot,
      basePokemon: basePokemon,
      formName: formName,
    );
    final modifiers =
        move.movePowers
            .where(attributes.containsKey)
            .map((power) => _modifier(attributes[power]!))
            .toList()
          ..sort();

    return modifiers.isEmpty ? 0 : modifiers.last;
  }

  MoveData _contextualMove(MoveData move, TeamSlot slot) {
    final type = ItemDrivenPokemonForm.effectiveMoveType(
      pokemonId: slot.pokemonId,
      moveReference: move.technicalName,
      heldItem: slot.heldItem,
      fallbackType: move.type,
    );
    return type == move.type ? move : move.copyWith(type: type);
  }

  String _effectiveMoveType(MoveData move, TeamSlot slot) {
    return BattleEnvironmentService.effectiveMoveType(
      _contextualMove(move, slot),
      _environment,
    );
  }

  String _moveStats(
    MoveData move,
    Pokemon pokemon,
    TeamSlot slot,
    Pokemon basePokemon,
    String? formName,
    BattleTransformationState? transformation,
  ) {
    final contextualMove = _contextualMove(move, slot);
    final level = _levelForSlot(slot);
    final moveModifier = _bestMoveModifier(
      move,
      pokemon,
      slot,
      basePokemon: basePokemon,
      formName: formName,
    );
    final effectiveMoveModifier = BattleTransformationService.megaModifier(
      moveModifier,
      transformation,
    );
    final proficiency = _proficiency(level);
    final attackPathBonus = TrainerPathPassiveService.attackRollBonus(
      profile: _activeProfile,
      pokemon: pokemon,
      slot: slot,
    );
    final terrainAttackBonus = BattleEnvironmentService.terrainAttackRollBonus(
      slot: slot,
      environment: _environment,
    );
    final damagePathBonus = TrainerPathPassiveService.damageRollBonus(
      profile: _activeProfile,
      slot: slot,
    );
    final abilityDamageBonus = BattleEnvironmentService.damageRollBonus(
      pokemon: pokemon,
      slot: slot,
      environment: _environment,
    );
    final terrainDamageBonus =
        BattleEnvironmentService.terrainMoveModifierBonus(
          environment: _environment,
          move: contextualMove,
          moveModifier: effectiveMoveModifier,
        );
    final effectiveMoveType = BattleEnvironmentService.effectiveMoveType(
      contextualMove,
      _environment,
    );
    final formAttackBonus = BattleFormChangeService.attackRollBonus(
      pokemon,
      formName,
    );
    final stab = TrainerPathPassiveService.stabEffect(
      profile: _activeProfile,
      pokemon: pokemon,
      slot: slot,
      move: contextualMove,
      pokemonLevel: level,
      moveTypeOverride: effectiveMoveType,
    );
    final originalPokemon = basePokemon.resolveVariant(
      formName: formName,
      gender: slot.gender,
    );
    final originalStab =
        transformation?.kind == BattleTransformationKind.terastal
        ? TrainerPathPassiveService.stabEffect(
            profile: _activeProfile,
            pokemon: originalPokemon,
            slot: slot,
            move: contextualMove,
            pokemonLevel: level,
            moveTypeOverride: effectiveMoveType,
          )
        : null;
    final parts = <String>[];

    if (move.isAttack) {
      final attackBonus =
          effectiveMoveModifier +
          proficiency +
          attackPathBonus +
          terrainAttackBonus +
          formAttackBonus;
      parts.add('AB ${attackBonus >= 0 ? '+' : ''}$attackBonus');
    }
    if (move.save != null) {
      parts.add('CD ${8 + proficiency + effectiveMoveModifier}');
    }

    final damage = move.damageForLevel(level);
    if (damage != null) {
      final totalBonus =
          damagePathBonus + abilityDamageBonus + terrainDamageBonus;
      final bonus = totalBonus == 0
          ? ''
          : ' ${totalBonus > 0 ? '+' : ''}$totalBonus';
      parts.add('${damage.label}$bonus');
    }
    if (stab.applies) {
      final source = stab.extendedByPath ? 'STAB esteso' : 'STAB';
      final bonus = stab.pathBonus == 0 ? '' : ' Path +${stab.pathBonus}';
      parts.add('$source$bonus');
    } else if (originalStab?.applies == true) {
      parts.add('STAB originale');
    }
    if (transformation?.kind == BattleTransformationKind.terastal &&
        transformation?.teraType != null &&
        originalPokemon.types.any(
          (type) =>
              MoveData.referenceKey(type) ==
              MoveData.referenceKey(transformation!.teraType!),
        ) &&
        MoveData.referenceKey(effectiveMoveType) ==
            MoveData.referenceKey(transformation!.teraType!)) {
      parts.add('STAB Tera ×2');
    }
    if (transformation?.kind == BattleTransformationKind.mega &&
        MoveData.referenceKey(move.damageModifier ?? '') == 'move') {
      parts.add('Mega: modificatore MOVE ×2');
    }
    if (transformation?.isDynamaxLike == true && damage != null) {
      parts.add('Dynamax: tira i danni 2 volte');
    }
    parts.addAll(
      BattleEnvironmentService.moveNotes(
        environment: _environment,
        move: contextualMove,
        moveModifier: effectiveMoveModifier,
      ),
    );
    if (move.range != '-') parts.add(move.range);
    if (move.duration != '-') parts.add(move.duration);

    return parts.join(' • ');
  }

  String _displayName(TeamSlot slot, Pokemon pokemon) {
    final nickname = slot.nickname?.trim();
    return nickname == null || nickname.isEmpty ? pokemon.name : nickname;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const HomeLeadingButton(),
        title: Text('Battle Companion'),
        actions: [
          GuidedTourInfoAction(
            controller: _tourController,
            enabled: _isBattleReady,
          ),
          const HomeAppBarAction(),
        ],
      ),
      body: AnimatedBuilder(
        animation: _tourController,
        builder: (context, _) {
          return Stack(
            children: [
              Positioned.fill(
                child: ResponsiveContent(
                  maxWidth: 1280,
                  child: FutureBuilder<_BattleData>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return _BattleEmptyState(
                          icon: Icons.error_outline,
                          title: context.uiText(
                            'Errore caricando il combattimento',
                            'Error loading battle',
                          ),
                          message: context.userFacingError(
                            snapshot.error!,
                            action: UserFacingErrorAction.load,
                          ),
                          actionLabel: context.uiText('Riprova', 'Retry'),
                          onAction: () => _reload(),
                        );
                      }

                      final data = snapshot.data;
                      if (data == null || data.occupiedSlots.isEmpty) {
                        return _BattleEmptyState(
                          icon: Icons.groups_outlined,
                          title: context.uiText(
                            'Nessun Pokémon in squadra',
                            'No Pokémon in the team',
                          ),
                          message: context.uiText(
                            'Aggiungi almeno un Pokémon alla squadra prima di aprire il tracker.',
                            'Add at least one Pokémon to the team before opening the tracker.',
                          ),
                          actionLabel: context.uiText('Ricarica', 'Reload'),
                          onAction: () => _reload(),
                        );
                      }

                      final activeSlot = _activeSlotFor(data)!;
                      final basePokemon =
                          data.pokemonById[activeSlot.pokemonId!]!;
                      final effectiveFormName = _effectiveFormName(activeSlot);
                      final pokemon = _pokemonForSlot(data, activeSlot)!;
                      final canChangeForm = BattleFormChangeService.supports(
                        basePokemon,
                      );
                      final moveReferences = _movesForSlot(activeSlot, pokemon);
                      final noPpLeft = _hasNoPpLeft(
                        activeSlot,
                        moveReferences,
                        data.moves,
                      );
                      MoveData? moveForActive(String reference) =>
                          data.moves[MoveRepository.contextualKey(
                            activeSlot.pokemonId!,
                            reference,
                          )];
                      final heldItem = data.heldItemFor(activeSlot);
                      final transformationState =
                          _transformationBySlot[activeSlot.slotIndex];
                      final megaEligibility = _transformationEligibility(
                        BattleTransformationKind.mega,
                        data,
                        activeSlot,
                        pokemon,
                      );
                      final zMoveEligibility = _transformationEligibility(
                        BattleTransformationKind.zMove,
                        data,
                        activeSlot,
                        pokemon,
                      );
                      final dynamaxEligibility = _transformationEligibility(
                        BattleTransformationKind.dynamax,
                        data,
                        activeSlot,
                        pokemon,
                      );
                      final terastalEligibility = _transformationEligibility(
                        BattleTransformationKind.terastal,
                        data,
                        activeSlot,
                        pokemon,
                      );
                      final passiveNotes =
                          TrainerPathPassiveService.passiveNotes(
                            profile: data.profile,
                            pokemon: pokemon,
                            slot: activeSlot,
                          );
                      final attributes = _attributeScores(
                        pokemon,
                        activeSlot,
                        basePokemon: basePokemon,
                        formName: effectiveFormName,
                      );
                      final temporaryHpRule = _temporaryHpRule(
                        data,
                        activeSlot,
                      );
                      final temporaryHp =
                          _temporaryHpBySlot[activeSlot.slotIndex] ?? 0;
                      final temporaryHpEnabled =
                          _temporaryHpEnabledBySlot[activeSlot.slotIndex] ??
                          false;
                      final baseArmorClass =
                          BattleEnvironmentService.baseArmorClass(
                            pokemon,
                            activeSlot,
                          );
                      final formArmorClass =
                          baseArmorClass +
                          BattleFormChangeService.armorClassBonus(
                            basePokemon,
                            effectiveFormName,
                          );
                      final transformationArmorClass =
                          formArmorClass +
                          BattleTransformationService.armorClassBonus(
                            transformationState,
                          );
                      final effectiveArmorClass =
                          transformationArmorClass +
                          BattleEnvironmentService.armorClassBonus(
                            pokemon: pokemon,
                            slot: activeSlot,
                            environment: _environment,
                          );

                      return RefreshIndicator(
                        onRefresh: () => _reload(),
                        child: ListView(
                          controller: _scrollController,
                          padding: EdgeInsets.fromLTRB(
                            12,
                            8,
                            12,
                            _tourController.isVisible ? 340 : 24,
                          ),
                          children: [
                            KeyedSubtree(
                              key: _battleHeaderKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  KeyedSubtree(
                                    key: _initiativeKey,
                                    child: _BattleHeader(
                                      round: _round,
                                      profile: data.profile,
                                      trainerInitiativeBonus:
                                          _trainerInitiativeBonus(data.profile),
                                      onNextRound: () => _nextPlayerRound(data),
                                      onEnd: () => _endBattle(data),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _PartyBar(
                                    slots: data.occupiedSlots,
                                    activeSlot: activeSlot,
                                    pokemonForSlot: (slot) =>
                                        _pokemonForSlot(data, slot),
                                    imagePokemonForSlot: (slot) =>
                                        data.pokemonById[slot.pokemonId],
                                    formNameForSlot: _effectiveFormName,
                                    transformationForSlot: (slot) =>
                                        _transformationBySlot[slot.slotIndex],
                                    onSelected: (slotIndex) {
                                      if (slotIndex != activeSlot.slotIndex &&
                                          BattleTransformationService.isDynamaxLike(
                                            _transformationBySlot[activeSlot
                                                .slotIndex],
                                          )) {
                                        setState(() {
                                          _message = context.uiText(
                                            'Un Pokémon Dynamax/Gigamax non può essere richiamato o sostituito.',
                                            'A Dynamax/Gigamax Pokémon cannot be recalled or switched.',
                                          );
                                        });
                                        return;
                                      }
                                      setState(() {
                                        _activeSlotIndex = slotIndex;
                                        _statusMoment =
                                            BattleStatusMoment.turnStart;
                                        _message = null;
                                      });
                                      _scheduleSessionSave(data);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            KeyedSubtree(
                              key: _environmentKey,
                              child: BattleEnvironmentCard(
                                environment: _environment,
                                pokemon: pokemon,
                                slot: activeSlot,
                                level: _levelForSlot(activeSlot),
                                proficiency: _proficiency(
                                  _levelForSlot(activeSlot),
                                ),
                                baseSpeed:
                                    TrainerPathPassiveService.effectiveSpeed(
                                      profile: data.profile,
                                      pokemon: pokemon,
                                      slot: activeSlot,
                                    ),
                                onEdit: () => _editEnvironment(data),
                              ),
                            ),
                            const SizedBox(height: 12),
                            KeyedSubtree(
                              key: _activePokemonKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _ActivePokemonCard(
                                    pokemon: pokemon,
                                    imagePokemon: basePokemon,
                                    slot: activeSlot,
                                    formName: effectiveFormName,
                                    transformation:
                                        _transformationBySlot[activeSlot
                                            .slotIndex],
                                    formLabel: canChangeForm
                                        ? BattleFormChangeService.formLabel(
                                            basePokemon,
                                            effectiveFormName,
                                          )
                                        : null,
                                    formNote: canChangeForm
                                        ? BattleFormChangeService.effectNote(
                                            basePokemon,
                                            effectiveFormName,
                                          )
                                        : null,
                                    heldItem: heldItem,
                                    displayName: _displayName(
                                      activeSlot,
                                      pokemon,
                                    ),
                                    level: _levelForSlot(activeSlot),
                                    baseArmorClass: formArmorClass,
                                    effectiveArmorClass: effectiveArmorClass,
                                    currentHp: _currentHpFor(
                                      activeSlot,
                                      pokemon,
                                    ),
                                    maxHp: _maxHpFor(pokemon, activeSlot),
                                    temporaryHp: temporaryHp,
                                    temporaryHpRule: temporaryHpRule,
                                    temporaryHpEnabled: temporaryHpEnabled,
                                    nonVolatileStatus: _nonVolatileStatusFor(
                                      activeSlot,
                                    ),
                                    volatileStatuses: _volatileStatusesFor(
                                      activeSlot,
                                    ),
                                    message: _message,
                                    onTransformations: () {
                                      _openTransformationMenu(
                                        data: data,
                                        slot: activeSlot,
                                        pokemon: pokemon,
                                        basePokemon: basePokemon,
                                        effectiveFormName: effectiveFormName,
                                        currentState: transformationState,
                                        megaEligibility: megaEligibility,
                                        zMoveEligibility: zMoveEligibility,
                                        dynamaxEligibility: dynamaxEligibility,
                                        terastalEligibility:
                                            terastalEligibility,
                                      );
                                    },
                                    onEditHp: () => _editHp(data, activeSlot),
                                    onHeal: () => _healFull(data, activeSlot),
                                    onStatus: () =>
                                        _openStatusPicker(data, activeSlot),
                                    onUseHeldBerry: heldItem?.type == 'berry'
                                        ? () => _useHeldBerry(data, activeSlot)
                                        : null,
                                    onOpenBag: () =>
                                        _openQuickBag(data, activeSlot),
                                    onToggleTemporaryHp: temporaryHpRule == null
                                        ? null
                                        : (enabled) => _toggleTemporaryHpRule(
                                            data,
                                            activeSlot,
                                            enabled,
                                          ),
                                    onChangeForm: canChangeForm
                                        ? () => _openBattleFormPicker(
                                            data,
                                            activeSlot,
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                            if (passiveNotes.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              TrainerPathPassiveCard(
                                trainerPath: data.profile.trainerPath,
                                notes: passiveNotes,
                              ),
                            ],
                            const SizedBox(height: 12),
                            BattleStatusAssistanceCard(
                              key: ValueKey(
                                'player-status-${activeSlot.slotIndex}',
                              ),
                              pokemonName: _displayName(activeSlot, pokemon),
                              nonVolatileStatus: _nonVolatileStatusFor(
                                activeSlot,
                              ),
                              volatileStatuses: _volatileStatusesFor(
                                activeSlot,
                              ),
                              selectedMoment: _statusMoment,
                              onMomentChanged: (moment) {
                                setState(() => _statusMoment = moment);
                              },
                            ),
                            const SizedBox(height: 12),
                            PokemonBattleAttributesCard(attributes: attributes),
                            const SizedBox(height: 12),
                            KeyedSubtree(
                              key: _movesKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    context.uiText(
                                      'MOSSE DA COMBATTIMENTO',
                                      'BATTLE MOVES',
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 8),
                                  if (noPpLeft) ...[
                                    _StruggleWarning(
                                      move: moveForActive('Struggle'),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  for (final reference in moveReferences)
                                    _MoveCard(
                                      reference: reference,
                                      move: moveForActive(reference),
                                      moveType: moveForActive(reference) == null
                                          ? null
                                          : _effectiveMoveType(
                                              moveForActive(reference)!,
                                              activeSlot,
                                            ),
                                      remainingPp: _remainingPp(
                                        activeSlot,
                                        reference,
                                        moveForActive(reference),
                                      ),
                                      maxPp: _maxPpFor(
                                        moveForActive(reference),
                                      ),
                                      stats: moveForActive(reference) == null
                                          ? null
                                          : _moveStats(
                                              moveForActive(reference)!,
                                              pokemon,
                                              activeSlot,
                                              basePokemon,
                                              effectiveFormName,
                                              transformationState,
                                            ),
                                      onUse: () => _changePp(
                                        data,
                                        activeSlot,
                                        reference,
                                        moveForActive(reference),
                                        -1,
                                      ),
                                      onRestore: () => _changePp(
                                        data,
                                        activeSlot,
                                        reference,
                                        moveForActive(reference),
                                        1,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              GuidedTourLayer(
                controller: _tourController,
                steps: _tourSteps,
                scrollController: _scrollController,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BattleData {
  const _BattleData({
    required this.profile,
    required this.team,
    required this.pokemonById,
    required this.moves,
    required this.items,
    required this.inventory,
    required this.evolutionData,
  });

  final UserProfile profile;
  final List<TeamSlot> team;
  final Map<int, Pokemon> pokemonById;
  final Map<String, MoveData?> moves;
  final List<BagItem> items;
  final List<BagInventoryEntry> inventory;
  final Map<String, EvolutionData> evolutionData;

  List<TeamSlot> get occupiedSlots {
    return team
        .where(
          (slot) =>
              slot.pokemonId != null && pokemonById[slot.pokemonId] != null,
        )
        .toList(growable: false);
  }

  List<BattleQuickItem> get ownedQuickItems {
    return BattleQuickItemService.resolve(catalog: items, inventory: inventory);
  }

  BagItem? heldItemFor(TeamSlot slot) {
    final reference = slot.heldItem;
    if (reference == null || reference.trim().isEmpty) return null;
    return _itemByReference(reference);
  }

  BagItem? _itemByReference(String reference) {
    final key = _itemReferenceKey(reference);
    for (final item in items) {
      if (item.id == reference ||
          _itemReferenceKey(item.id) == key ||
          _itemReferenceKey(item.name) == key) {
        return item;
      }
    }
    return null;
  }
}

class _MedicineUseResult {
  const _MedicineUseResult({
    required this.updatedSlot,
    required this.volatileStatuses,
    required this.message,
  });

  final TeamSlot updatedSlot;
  final Set<String> volatileStatuses;
  final String message;
}

class _StatusPickerResult {
  const _StatusPickerResult({
    required this.nonVolatileStatus,
    required this.volatileStatuses,
  });

  final String? nonVolatileStatus;
  final Set<String> volatileStatuses;
}

class _StatusInfo {
  const _StatusInfo({required this.shortLabel, required this.assetPath});

  final String shortLabel;
  final String? assetPath;
}

const List<String> _nonVolatileStatusOptions = [
  'Asleep',
  'Burned',
  'Frozen',
  'Paralyzed',
  'Poisoned',
];

const List<String> _volatileStatusOptions = ['Confused', 'Flinched'];

const Map<String, _StatusInfo> _statusInfoByName = {
  'Asleep': _StatusInfo(
    shortLabel: 'SLP',
    assetPath: 'assets/textures/gui/status/sleep_down.png',
  ),
  'Burned': _StatusInfo(
    shortLabel: 'BRN',
    assetPath: 'assets/textures/gui/status/burn_down.png',
  ),
  'Confused': _StatusInfo(
    shortLabel: 'CNF',
    assetPath: 'assets/textures/gui/status/confuse_down.png',
  ),
  'Flinched': _StatusInfo(shortLabel: 'FLN', assetPath: null),
  'Frozen': _StatusInfo(
    shortLabel: 'FRZ',
    assetPath: 'assets/textures/gui/status/frozen_down.png',
  ),
  'Paralyzed': _StatusInfo(
    shortLabel: 'PAR',
    assetPath: 'assets/textures/gui/status/paralyze_down.png',
  ),
  'Poisoned': _StatusInfo(
    shortLabel: 'PSN',
    assetPath: 'assets/textures/gui/status/poisoned_down.png',
  ),
  'Badly Poisoned': _StatusInfo(
    shortLabel: 'PSN',
    assetPath: 'assets/textures/gui/status/poisoned_down.png',
  ),
};

const Set<String> _healingItemIds = {
  'potion',
  'super-potion',
  'hyper-potion',
  'max-potion',
  'full-restore',
  'revive',
  'max-revive',
  'fresh-water',
  'soda-pop',
  'berry-juice',
  'lemonade',
  'moomoo-milk',
  'energy-powder',
  'energy-root',
  'revival-herb',
};

const Set<String> _berryMedicineItemIds = {
  'cheri-berry',
  'chesto-berry',
  'pecha-berry',
  'rawst-berry',
  'aspear-berry',
  'persim-berry',
  'lum-berry',
  'oran-berry',
  'sitrus-berry',
};

const Set<String> _statusMedicineItemIds = {
  'antidote',
  'burn-heal',
  'ice-heal',
  'awakening',
  'paralyze-heal',
  'full-heal',
  'full-restore',
  'heal-powder',
};

const Set<String> _reviveItemIds = {'revive', 'max-revive', 'revival-herb'};

const Map<String, Set<String>> _statusTargetsByItem = {
  'cheri-berry': {'Paralyzed'},
  'chesto-berry': {'Asleep'},
  'pecha-berry': {'Poisoned', 'Badly Poisoned'},
  'rawst-berry': {'Burned'},
  'aspear-berry': {'Frozen'},
  'persim-berry': {'Confused'},
  'lum-berry': {'*'},
  'antidote': {'Poisoned', 'Badly Poisoned'},
  'burn-heal': {'Burned'},
  'ice-heal': {'Frozen'},
  'awakening': {'Asleep'},
  'paralyze-heal': {'Paralyzed'},
  'full-heal': {'*'},
  'full-restore': {'*'},
  'heal-powder': {'*'},
};

String _itemReferenceKey(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r"[’']"), '')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

String _fallbackStatusLabel(String value) {
  final normalized = value.trim().toUpperCase();
  if (normalized.length <= 3) return normalized;
  return normalized.substring(0, 3);
}

String _itemTypeLabel(String type) {
  switch (type) {
    case 'berry':
      return uiTextForLanguage('Bacca', 'Berry');
    case 'held-item':
      return uiTextForLanguage('Strumento tenuto', 'Held item');
    case 'medicine':
      return uiTextForLanguage('Medicina', 'Medicine');
    case 'pokeball':
      return 'Poké Ball';
    case 'tm':
      return uiTextForLanguage('MT', 'TM');
    default:
      return type;
  }
}

String _quickItemActionLabel(BagItem item) {
  return BattleQuickItemService.isPokeball(item)
      ? uiTextForLanguage('LANCIA', 'THROW')
      : uiTextForLanguage('USA', 'USE');
}

String _quickItemDescription(BagItem item) {
  if (BattleQuickItemService.isPokeball(item)) {
    return uiTextForLanguage(
      'Lancia la Poké Ball. Dopo la risposta del Master verrà consumata.',
      'Throw the Poké Ball. It will be consumed after the GM reports the result.',
    );
  }
  return item.displayDescription;
}

Color _hpProgressColor(double value) {
  if (value <= 0.25) return Colors.red;
  if (value <= 0.5) return Colors.amber;
  return Colors.green;
}

class _BattleHeader extends StatelessWidget {
  const _BattleHeader({
    required this.round,
    required this.profile,
    required this.trainerInitiativeBonus,
    required this.onNextRound,
    required this.onEnd,
  });

  final int round;
  final UserProfile profile;
  final int trainerInitiativeBonus;
  final VoidCallback onNextRound;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'ROUND $round',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        Text(
          context.uiText(
            '${profile.name} · INIZ. ${trainerInitiativeBonus >= 0 ? '+' : ''}$trainerInitiativeBonus',
            '${profile.name} · INIT. ${trainerInitiativeBonus >= 0 ? '+' : ''}$trainerInitiativeBonus',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    final nextButton = FilledButton.icon(
      onPressed: onNextRound,
      icon: const Icon(Icons.navigate_next),
      label: Text(
        context.uiText('PROSSIMO MIO TURNO', 'NEXT MY TURN'),
        maxLines: 1,
      ),
    );

    final endButton = IconButton(
      tooltip: context.uiText('Termina battaglia', 'End battle'),
      onPressed: onEnd,
      icon: const Icon(Icons.stop_circle_outlined),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 460) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: info),
                      endButton,
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(width: double.infinity, child: nextButton),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: info),
                nextButton,
                const SizedBox(width: 4),
                endButton,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PartyBar extends StatelessWidget {
  const _PartyBar({
    required this.slots,
    required this.activeSlot,
    required this.pokemonForSlot,
    required this.imagePokemonForSlot,
    required this.formNameForSlot,
    required this.transformationForSlot,
    required this.onSelected,
  });

  final List<TeamSlot> slots;
  final TeamSlot activeSlot;
  final Pokemon? Function(TeamSlot slot) pokemonForSlot;
  final Pokemon? Function(TeamSlot slot) imagePokemonForSlot;
  final String? Function(TeamSlot slot) formNameForSlot;
  final BattleTransformationState? Function(TeamSlot slot)
  transformationForSlot;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Text(
              context.uiText('SQUADRA', 'TEAM'),
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final slot in slots)
                      _PartyPokemonButton(
                        slot: slot,
                        pokemon: pokemonForSlot(slot),
                        imagePokemon: imagePokemonForSlot(slot),
                        formName: formNameForSlot(slot),
                        transformation: transformationForSlot(slot),
                        selected: slot.slotIndex == activeSlot.slotIndex,
                        onTap: () => onSelected(slot.slotIndex),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartyPokemonButton extends StatelessWidget {
  const _PartyPokemonButton({
    required this.slot,
    required this.pokemon,
    required this.imagePokemon,
    required this.formName,
    required this.transformation,
    required this.selected,
    required this.onTap,
  });

  final TeamSlot slot;
  final Pokemon? pokemon;
  final Pokemon? imagePokemon;
  final String? formName;
  final BattleTransformationState? transformation;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pokemon = this.pokemon;
    if (pokemon == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final nickname = slot.nickname?.trim();
    final name = nickname == null || nickname.isEmpty ? pokemon.name : nickname;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primaryContainer
                : colorScheme.surface,
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PokemonTransformationImage(
                  pokemon: imagePokemon ?? pokemon,
                  size: 40,
                  formName: formName,
                  gender: slot.gender,
                  isShiny: slot.isShiny,
                  transformation: transformation,
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 64,
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BattleFormPickerSheet extends StatelessWidget {
  const _BattleFormPickerSheet({
    required this.pokemon,
    required this.slot,
    required this.currentFormName,
    required this.choices,
  });

  final Pokemon pokemon;
  final TeamSlot slot;
  final String? currentFormName;
  final List<PokemonFormChoice> choices;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.78,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text(
            context.uiText('Cambia forma in battaglia', 'Change battle form'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(BattleFormChangeService.changeHint(pokemon)),
          const SizedBox(height: 12),
          for (final choice in choices)
            Card(
              child: ListTile(
                leading: PokemonAssetImage(
                  pokemon: pokemon,
                  formName: choice.name,
                  gender: slot.gender,
                  isShiny: slot.isShiny,
                  size: 54,
                ),
                title: Text(
                  BattleFormChangeService.formLabel(pokemon, choice.name),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle:
                    BattleFormChangeService.effectNote(pokemon, choice.name) ==
                        null
                    ? null
                    : Text(
                        BattleFormChangeService.effectNote(
                          pokemon,
                          choice.name,
                        )!,
                      ),
                trailing:
                    BattleFormChangeService.sameForm(
                      pokemon,
                      currentFormName,
                      choice.name,
                    )
                    ? const Icon(Icons.check_circle)
                    : const Icon(Icons.radio_button_unchecked),
                onTap: () => Navigator.of(context).pop(choice.name),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivePokemonCard extends StatelessWidget {
  const _ActivePokemonCard({
    required this.pokemon,
    required this.imagePokemon,
    required this.slot,
    required this.formName,
    required this.transformation,
    required this.formLabel,
    required this.formNote,
    required this.heldItem,
    required this.displayName,
    required this.level,
    required this.baseArmorClass,
    required this.effectiveArmorClass,
    required this.currentHp,
    required this.maxHp,
    required this.temporaryHp,
    required this.temporaryHpRule,
    required this.temporaryHpEnabled,
    required this.nonVolatileStatus,
    required this.volatileStatuses,
    required this.message,
    required this.onTransformations,
    required this.onEditHp,
    required this.onHeal,
    required this.onStatus,
    required this.onUseHeldBerry,
    required this.onOpenBag,
    required this.onToggleTemporaryHp,
    required this.onChangeForm,
  });

  final Pokemon pokemon;
  final Pokemon imagePokemon;
  final TeamSlot slot;
  final String? formName;
  final BattleTransformationState? transformation;
  final String? formLabel;
  final String? formNote;
  final BagItem? heldItem;
  final String displayName;
  final int level;
  final int baseArmorClass;
  final int effectiveArmorClass;
  final int currentHp;
  final int maxHp;
  final int temporaryHp;
  final BattleTemporaryHpRule? temporaryHpRule;
  final bool temporaryHpEnabled;
  final String? nonVolatileStatus;
  final Set<String> volatileStatuses;
  final String? message;
  final VoidCallback onTransformations;
  final VoidCallback onEditHp;
  final VoidCallback onHeal;
  final VoidCallback onStatus;
  final VoidCallback? onUseHeldBerry;
  final VoidCallback onOpenBag;
  final ValueChanged<bool>? onToggleTemporaryHp;
  final VoidCallback? onChangeForm;

  @override
  Widget build(BuildContext context) {
    final hpProgress = maxHp <= 0
        ? 0.0
        : (currentHp / maxHp).clamp(0.0, 1.0).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                PokemonTransformationImage(
                  pokemon: imagePokemon,
                  useLargeArtwork: true,
                  size: 96,
                  formName: formName,
                  gender: slot.gender,
                  isShiny: slot.isShiny,
                  transformation: transformation,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _ArmorClassBadge(
                            baseArmorClass: baseArmorClass,
                            effectiveArmorClass: effectiveArmorClass,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '#${pokemon.id.toString().padLeft(3, '0')}  |  Lv. $level',
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final type in pokemon.types)
                            PokemonTypeBadge(type: type, height: 20),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (onChangeForm != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Chip(
                    avatar: const Icon(Icons.change_circle_outlined, size: 18),
                    label: Text(formLabel ?? context.uiText('Forma', 'Form')),
                  ),
                  OutlinedButton.icon(
                    onPressed: onChangeForm,
                    icon: const Icon(Icons.swap_horiz),
                    label: Text(context.uiText('CAMBIA FORMA', 'CHANGE FORM')),
                  ),
                ],
              ),
              if (formNote != null) ...[
                const SizedBox(height: 6),
                Text(formNote!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
            if (transformation != null) ...[
              const SizedBox(height: 10),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.auto_awesome),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              transformation!.kind.label.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              BattleTransformationService.effectSummary(
                                transformation!,
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            InkWell(
              onTap: onEditHp,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Text(
                      temporaryHp > 0
                          ? 'HP $currentHp/$maxHp  +$temporaryHp TEMP'
                          : 'HP $currentHp/$maxHp',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: hpProgress,
                          minHeight: 16,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _hpProgressColor(hpProgress),
                          ),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: onTransformations,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: Text(context.uiText('TRASFORMA', 'TRANSFORM')),
                ),
                FilledButton(
                  onPressed: onHeal,
                  child: Text(
                    context.uiText('POKÉMON CENTER', 'POKÉMON CENTER'),
                  ),
                ),
              ],
            ),
            if (temporaryHpRule != null) ...[
              const SizedBox(height: 10),
              _TemporaryHpPanel(
                rule: temporaryHpRule!,
                currentHp: temporaryHp,
                enabled: temporaryHpEnabled,
                onChanged: onToggleTemporaryHp,
              ),
            ],
            const SizedBox(height: 10),
            _StatusPanel(
              nonVolatileStatus: nonVolatileStatus,
              volatileStatuses: volatileStatuses,
              onTap: onStatus,
            ),
            const SizedBox(height: 10),
            _HeldItemPanel(
              item: heldItem,
              onUseHeldBerry: onUseHeldBerry,
              onOpenBag: onOpenBag,
            ),
            if (message != null) ...[
              const SizedBox(height: 10),
              _InlineBattleMessage(message: message!),
            ],
          ],
        ),
      ),
    );
  }
}

class _TemporaryHpPanel extends StatelessWidget {
  const _TemporaryHpPanel({
    required this.rule,
    required this.currentHp,
    required this.enabled,
    required this.onChanged,
  });

  final BattleTemporaryHpRule rule;
  final int currentHp;
  final bool enabled;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.shield_moon_outlined),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${rule.label}: $currentHp PF temporanei',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    rule.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Switch(value: enabled, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _ArmorClassBadge extends StatelessWidget {
  const _ArmorClassBadge({
    required this.baseArmorClass,
    required this.effectiveArmorClass,
  });

  final int baseArmorClass;
  final int effectiveArmorClass;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bonus = effectiveArmorClass - baseArmorClass;
    final hasBonus = bonus != 0;
    final signedBonus = bonus > 0 ? '+$bonus' : bonus.toString();

    return Tooltip(
      message: hasBonus
          ? 'Classe Armatura: $baseArmorClass $signedBonus'
          : 'Classe Armatura',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: hasBonus
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: hasBonus ? colorScheme.primary : colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            hasBonus
                ? '${context.uiText('CA', 'AC')} $effectiveArmorClass ($signedBonus)'
                : '${context.uiText('CA', 'AC')} $effectiveArmorClass',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.nonVolatileStatus,
    required this.volatileStatuses,
    required this.onTap,
  });

  final String? nonVolatileStatus;
  final Set<String> volatileStatuses;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasStatuses =
        nonVolatileStatus != null || volatileStatuses.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: hasStatuses
              ? Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(context.uiText('STATUS:', 'CONDITIONS:')),
                    if (nonVolatileStatus != null)
                      _StatusChip(
                        status: nonVolatileStatus!,
                        prefix: 'NON-VOLATILE',
                      ),
                    for (final status in volatileStatuses)
                      _StatusChip(status: status, prefix: 'VOLATILE'),
                  ],
                )
              : Text(context.uiText('STATUS: nessuno', 'CONDITIONS: none')),
        ),
      ),
    );
  }
}

class _StatusPickerSheet extends StatefulWidget {
  const _StatusPickerSheet({
    required this.initialNonVolatileStatus,
    required this.initialVolatileStatuses,
  });

  final String? initialNonVolatileStatus;
  final Set<String> initialVolatileStatuses;

  @override
  State<_StatusPickerSheet> createState() => _StatusPickerSheetState();
}

class _StatusPickerSheetState extends State<_StatusPickerSheet> {
  String? _nonVolatileStatus;
  late Set<String> _volatileStatuses;

  @override
  void initState() {
    super.initState();
    _nonVolatileStatus = widget.initialNonVolatileStatus;
    _volatileStatuses = {...widget.initialVolatileStatuses};
  }

  void _finish() {
    Navigator.of(context).pop(
      _StatusPickerResult(
        nonVolatileStatus: _nonVolatileStatus,
        volatileStatuses: {..._volatileStatuses},
      ),
    );
  }

  void _selectNonVolatile(String? status) {
    _nonVolatileStatus = status;
    _finish();
  }

  void _toggleVolatile(String status, bool selected) {
    if (selected) {
      _volatileStatuses.add(status);
    } else {
      _volatileStatuses.remove(status);
    }
    _finish();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              context.uiText('STATUS IN COMBATTIMENTO', 'BATTLE CONDITIONS'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              context.uiText(
                'Tocca uno status per applicarlo subito. Un solo status non-volatile alla volta; gli status volatili terminano fuori dal combattimento.',
                'Tap a condition to apply it immediately. Only one non-volatile condition can be active at a time; volatile conditions end outside battle.',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'NON-VOLATILE',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(context.uiText('NESSUNO', 'NONE')),
                  selected: _nonVolatileStatus == null,
                  onSelected: (_) => _selectNonVolatile(null),
                ),
                for (final status in _nonVolatileStatusOptions)
                  ChoiceChip(
                    avatar: _StatusIcon(status: status, size: 22),
                    label: Text(status.toUpperCase()),
                    selected: _nonVolatileStatus == status,
                    onSelected: (_) => _selectNonVolatile(status),
                  ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'VOLATILE',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          for (final status in _volatileStatusOptions)
            CheckboxListTile(
              secondary: _StatusIcon(status: status, size: 28),
              title: Text(status.toUpperCase()),
              value: _volatileStatuses.contains(status),
              onChanged: (value) => _toggleVolatile(status, value == true),
            ),
          if (_nonVolatileStatus != null || _volatileStatuses.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.clear),
              title: Text(context.uiText('RIMUOVI TUTTI', 'REMOVE ALL')),
              onTap: () => Navigator.of(context).pop(
                const _StatusPickerResult(
                  nonVolatileStatus: null,
                  volatileStatuses: <String>{},
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeldItemPanel extends StatelessWidget {
  const _HeldItemPanel({
    required this.item,
    required this.onUseHeldBerry,
    required this.onOpenBag,
  });

  final BagItem? item;
  final VoidCallback? onUseHeldBerry;
  final VoidCallback onOpenBag;

  @override
  Widget build(BuildContext context) {
    final item = this.item;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            if (item == null)
              const Icon(Icons.inventory_2_outlined)
            else
              _ItemSprite(item: item, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item == null
                        ? 'ITEM: NONE'
                        : 'ITEM: ${item.name.toUpperCase()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    item == null
                        ? context.uiText(
                            'Apri lo zaino rapido per usare un consumabile o lanciare una Poké Ball.',
                            'Open the quick Bag to use a consumable or throw a Poké Ball.',
                          )
                        : item.type == 'berry'
                        ? context.uiText(
                            'Bacca tenuta: puoi consumarla subito in combattimento.',
                            'Held Berry: you can consume it immediately in battle.',
                          )
                        : context.uiText(
                            'Strumento tenuto: ${_itemTypeLabel(item.type)}.',
                            'Held item: ${_itemTypeLabel(item.type)}.',
                          ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (item?.type == 'berry')
              OutlinedButton(
                onPressed: onUseHeldBerry,
                child: Text(context.uiText('USA', 'USE')),
              ),
            const SizedBox(width: 6),
            FilledButton(
              onPressed: onOpenBag,
              child: Text(context.uiText('ZAINO', 'BAG')),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickBagSheet extends StatelessWidget {
  const _QuickBagSheet({
    required this.items,
    required this.pokemonName,
    required this.currentHp,
    required this.maxHp,
    required this.nonVolatileStatus,
    required this.volatileStatuses,
  });

  final List<BattleQuickItem> items;
  final String pokemonName;
  final int currentHp;
  final int maxHp;
  final String? nonVolatileStatus;
  final Set<String> volatileStatuses;

  @override
  Widget build(BuildContext context) {
    final statusParts = [?nonVolatileStatus, ...volatileStatuses];
    final statusText = statusParts.isEmpty
        ? context.uiText('nessuno status', 'no conditions')
        : statusParts.join(', ');

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.78,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          children: [
            Text(
              context.uiText('Zaino rapido', 'Quick Bag'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text('$pokemonName • HP $currentHp/$maxHp • $statusText'),
            const SizedBox(height: 12),
            for (final entry in items)
              Card(
                child: ListTile(
                  leading: _ItemSprite(item: entry.item, size: 42),
                  title: Text(
                    entry.item.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${_itemTypeLabel(entry.item.type)} • x${entry.quantity}\n${_quickItemDescription(entry.item)}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(_quickItemActionLabel(entry.item)),
                  onTap: () => Navigator.of(context).pop(entry),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MoveCard extends StatelessWidget {
  const _MoveCard({
    required this.reference,
    required this.move,
    required this.moveType,
    required this.remainingPp,
    required this.maxPp,
    required this.stats,
    required this.onUse,
    required this.onRestore,
  });

  final String reference;
  final MoveData? move;
  final String? moveType;
  final int remainingPp;
  final int maxPp;
  final String? stats;
  final VoidCallback onUse;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final move = this.move;
    final title = move?.name ?? reference;
    final canTrackPp = maxPp > 0;

    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            if (canTrackPp) _PpBadge(remainingPp: remainingPp, maxPp: maxPp),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (move != null)
                PokemonTypeBadge(type: moveType ?? move.type, height: 18),
              if (stats != null && stats!.isNotEmpty) Text(stats!),
            ],
          ),
        ),
        trailing: canTrackPp
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: context.uiText('Recupera PP', 'Restore PP'),
                    onPressed: remainingPp >= maxPp ? null : onRestore,
                    icon: const Icon(Icons.add),
                  ),
                  IconButton(
                    tooltip: context.uiText('Usa mossa', 'Use move'),
                    onPressed: remainingPp <= 0 ? null : onUse,
                    icon: const Icon(Icons.remove),
                  ),
                ],
              )
            : null,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        children: [
          if (move == null)
            Text(
              context.uiText(
                'Dettagli mossa non disponibili.',
                'Move details are unavailable.',
              ),
            )
          else ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.uiText(
                  'Tempo: ${move.moveTime}  |  Durata: ${move.duration}',
                  'Time: ${move.moveTime}  |  Duration: ${move.duration}',
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(move.description),
            ),
          ],
        ],
      ),
    );
  }
}

class _PpBadge extends StatelessWidget {
  const _PpBadge({required this.remainingPp, required this.maxPp});

  final int remainingPp;
  final int maxPp;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = maxPp <= 0 ? 0.0 : remainingPp / maxPp;
    final background = remainingPp <= 0
        ? colorScheme.errorContainer
        : progress <= 0.33
        ? Colors.amber.shade200
        : colorScheme.primaryContainer;
    final foreground = remainingPp <= 0
        ? colorScheme.onErrorContainer
        : progress <= 0.33
        ? Colors.black87
        : colorScheme.onPrimaryContainer;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          'PP $remainingPp/$maxPp',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.prefix});

  final String status;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: _StatusIcon(status: status, size: 22),
      label: Text('$prefix: ${status.toUpperCase()}'),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status, required this.size});

  final String status;
  final double size;

  @override
  Widget build(BuildContext context) {
    final info = _statusInfoByName[status];
    final assetPath = info?.assetPath;
    final fallbackLabel = info?.shortLabel ?? _fallbackStatusLabel(status);

    if (assetPath == null) {
      return _StatusFallback(label: fallbackLabel, size: size);
    }

    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        errorBuilder: (_, __, ___) =>
            _StatusFallback(label: fallbackLabel, size: size),
      ),
    );
  }
}

class _StatusFallback extends StatelessWidget {
  const _StatusFallback({required this.label, required this.size});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      child: Text(
        label,
        style: TextStyle(fontSize: size * 0.32, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _ItemSprite extends StatelessWidget {
  const _ItemSprite({required this.item, this.size = 42});

  final BagItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    final assetPath = item.spriteAssetPath;
    if (assetPath == null || !assetPath.startsWith('assets/')) {
      return Icon(Icons.inventory_2_outlined, size: size);
    }

    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.inventory_2_outlined, size: size),
      ),
    );
  }
}

class _HpInputDialog extends StatefulWidget {
  const _HpInputDialog({required this.currentHp, required this.maxHp});

  final int currentHp;
  final int maxHp;

  @override
  State<_HpInputDialog> createState() => _HpInputDialogState();
}

class _HpInputDialogState extends State<_HpInputDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(context.uiText('Modifica HP', 'Change HP')),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(signed: true),
        decoration: InputDecoration(
          labelText: context.uiText('HP o modifica', 'HP or change'),
          helperText: context.uiText(
            'Esempi: -12, +8 oppure 35. Attuali ${widget.currentHp}/${widget.maxHp}',
            'Examples: -12, +8 or 35. Current ${widget.currentHp}/${widget.maxHp}',
          ),
        ),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.uiText('Annulla', 'Cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(context.uiText('Salva', 'Save')),
        ),
      ],
    );
  }
}

class _StruggleWarning extends StatelessWidget {
  const _StruggleWarning({required this.move});

  final MoveData? move;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              uiTextForLanguage(
                'STRUGGLE DISPONIBILE',
                """STRUGGLE AVAILABLE""",
              ),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              move?.description ??
                  context.uiText(
                    'Tutti i PP delle mosse tracciabili sono a zero. Usa Struggle.',
                    'All tracked move PP are at zero. Use Struggle.',
                  ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineBattleMessage extends StatelessWidget {
  const _InlineBattleMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          message,
          style: TextStyle(color: colorScheme.onSecondaryContainer),
        ),
      ),
    );
  }
}

class _BattleEmptyState extends StatelessWidget {
  const _BattleEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _TransformationPanel extends StatelessWidget {
  const _TransformationPanel({
    required this.currentState,
    required this.megaEligibility,
    required this.zMoveEligibility,
    required this.dynamaxEligibility,
    required this.terastalEligibility,
    required this.hasCanonicalMega,
    required this.hasGigamax,
    required this.onMega,
    required this.onZMove,
    required this.onDynamax,
    required this.onTerastal,
  });

  final BattleTransformationState? currentState;
  final TransformationEligibility megaEligibility;
  final TransformationEligibility zMoveEligibility;
  final TransformationEligibility dynamaxEligibility;
  final TransformationEligibility terastalEligibility;
  final bool hasCanonicalMega;
  final bool hasGigamax;
  final VoidCallback onMega;
  final VoidCallback onZMove;
  final VoidCallback onDynamax;
  final VoidCallback onTerastal;

  @override
  Widget build(BuildContext context) {
    final state = currentState;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.uiText('TRASFORMAZIONI', 'TRANSFORMATIONS'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              context.uiText(
                'Regole 2024: un Pokémon può trasformarsi una sola volta per riposo lungo; l’Allenatore può usare ogni tipo una volta per riposo lungo.',
                '2024 rules: a Pokémon can transform once per long rest; its Trainer can use each transformation type once per long rest.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (state != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  state.isDynamaxLike
                      ? '${state.kind.label} attiva · ${state.dynamaxTemporaryHp} PF Dynamax'
                      : state.kind == BattleTransformationKind.terastal
                      ? '${state.kind.label} attiva · ${state.teraType}'
                      : state.kind == BattleTransformationKind.zMove
                      ? 'Mossa Z già usata in questo riposo lungo'
                      : '${state.kind.label} attiva',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
            const SizedBox(height: 10),
            _TransformationActionTile(
              icon: Icons.bolt,
              title: context.uiText('MEGA EVOLUZIONE', 'MEGA EVOLUTION'),
              hint: hasCanonicalMega
                  ? context.uiText(
                      'Artwork Mega canonico disponibile.',
                      'Canonical Mega artwork available.',
                    )
                  : context.uiText(
                      'La regola permette la Mega anche senza una forma canonica dedicata.',
                      'The rule allows Mega Evolution even without a dedicated canonical form.',
                    ),
              eligibility: megaEligibility,
              onPressed: onMega,
            ),
            _TransformationActionTile(
              icon: Icons.flash_on,
              title: context.uiText('MOSSA Z', 'Z-MOVE'),
              hint: context.uiText(
                'Scegli una mossa compatibile con il Cristallo Z tenuto.',
                'Choose a move matching the held Z-Crystal.',
              ),
              eligibility: zMoveEligibility,
              onPressed: onZMove,
            ),
            _TransformationActionTile(
              icon: Icons.expand,
              title: hasGigamax ? 'DYNAMAX / GIGAMAX' : 'DYNAMAX',
              hint: hasGigamax
                  ? context.uiText(
                      'Questa specie dispone anche dell’aspetto Gigamax.',
                      'This species also has a Gigantamax appearance.',
                    )
                  : context.uiText(
                      'Conferma manualmente che ci sia spazio per una creatura Gargantuan.',
                      'Manually confirm there is room for a Gargantuan creature.',
                    ),
              eligibility: dynamaxEligibility,
              onPressed: onDynamax,
            ),
            _TransformationActionTile(
              icon: Icons.diamond_outlined,
              title: context.uiText('TERACRISTAL', 'TERASTALLIZATION'),
              hint: context.uiText(
                'Scegli il Tera Tipo da applicare per questa trasformazione.',
                'Choose the Tera Type used for this transformation.',
              ),
              eligibility: terastalEligibility,
              onPressed: onTerastal,
            ),
          ],
        ),
      ),
    );
  }
}

class _TransformationActionTile extends StatelessWidget {
  const _TransformationActionTile({
    required this.icon,
    required this.title,
    required this.hint,
    required this.eligibility,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String hint;
  final TransformationEligibility eligibility;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final available = eligibility.isAvailable;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(hint, style: Theme.of(context).textTheme.bodySmall),
                    if (!available &&
                        eligibility.missingRequirements.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        eligibility.missingRequirements.join(' · '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: available ? onPressed : null,
                child: Text(context.uiText('USA', 'USE')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransformArtPickerSheet extends StatelessWidget {
  const _TransformArtPickerSheet({
    required this.title,
    required this.pokemonName,
    required this.options,
    required this.isShiny,
  });

  final String title;
  final String pokemonName;
  final List<PokemonTransformArt> options;
  final bool isShiny;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(pokemonName),
          const SizedBox(height: 10),
          for (final option in options)
            Card(
              child: ListTile(
                leading: Image.asset(
                  option.assetPath(shiny: isShiny),
                  width: 52,
                  height: 52,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(Icons.auto_awesome),
                ),
                title: Text('${option.label} $pokemonName'),
                subtitle: Text(option.types.join(' / ')),
                onTap: () => Navigator.of(context).pop(option),
              ),
            ),
        ],
      ),
    );
  }
}

class _DynamaxPickerSheet extends StatelessWidget {
  const _DynamaxPickerSheet({
    required this.pokemonName,
    required this.gigamaxOptions,
    required this.isShiny,
  });

  final String pokemonName;
  final List<PokemonTransformArt> gigamaxOptions;
  final bool isShiny;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text(
            context.uiText('Dynamax / Gigamax', 'Dynamax / Gigantamax'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            context.uiText(
              'Prosegui solo se attorno a $pokemonName c’è spazio sufficiente per una creatura Gargantuan.',
              'Continue only if there is enough room around $pokemonName for a Gargantuan creature.',
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.expand),
              title: const Text('DYNAMAX'),
              onTap: () => Navigator.of(context).pop('dynamax'),
            ),
          ),
          for (final option in gigamaxOptions)
            Card(
              child: ListTile(
                leading: Image.asset(
                  option.assetPath(shiny: isShiny),
                  width: 52,
                  height: 52,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(Icons.auto_awesome),
                ),
                title: Text('${option.label.toUpperCase()} $pokemonName'),
                onTap: () => Navigator.of(context).pop(option.identifier),
              ),
            ),
        ],
      ),
    );
  }
}

class _TeraTypePickerSheet extends StatelessWidget {
  const _TeraTypePickerSheet({
    required this.pokemonName,
    required this.initialType,
  });

  final String pokemonName;
  final String? initialType;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.uiText('Scegli il Tera Tipo', 'Choose the Tera Type'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(pokemonName),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final type in BattleTransformationService.teraTypes)
                      ActionChip(
                        avatar: type == initialType
                            ? const Icon(Icons.check, size: 18)
                            : const Icon(Icons.diamond_outlined, size: 18),
                        label: Text(type),
                        onPressed: () => Navigator.of(context).pop(type),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZMoveChoice {
  const _ZMoveChoice({
    required this.reference,
    required this.move,
    required this.rawMove,
  });

  final String reference;
  final MoveData move;
  final MoveData rawMove;
}

class _ZMovePickerSheet extends StatelessWidget {
  const _ZMovePickerSheet({
    required this.pokemonName,
    required this.crystalType,
    required this.choices,
  });

  final String pokemonName;
  final String crystalType;
  final List<_ZMoveChoice> choices;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text(
            context.uiText('Usa una Mossa Z', 'Use a Z-Move'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text('$pokemonName · Cristallo Z $crystalType'),
          const SizedBox(height: 10),
          for (final choice in choices)
            Card(
              child: ListTile(
                leading: const Icon(Icons.flash_on),
                title: Text(choice.move.name),
                subtitle: Text(
                  BattleTransformationService.zMoveSummary(choice.move),
                ),
                onTap: () => Navigator.of(context).pop(choice),
              ),
            ),
        ],
      ),
    );
  }
}
