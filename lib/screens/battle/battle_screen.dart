// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../localization/ui_text.dart';
import '../../localization/user_facing_error.dart';
import '../../models/bag_inventory_entry.dart';
import '../../models/bag_item.dart';
import '../../models/battle_environment.dart';
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
import '../../services/trainer_path_passive_service.dart';
import '../../widgets/battle/battle_environment_card.dart';
import '../../widgets/battle/battle_status_assistance_card.dart';
import '../../widgets/battle/pokemon_battle_attributes_card.dart';
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
  final Map<int, int> _temporaryHpBySlot = {};
  final Map<int, bool> _temporaryHpEnabledBySlot = {};
  final Set<int> _temporaryHpInitializedSlots = {};
  final List<BattleInitiativeEntry> _initiativeEntries = [];

  BattleStatusMoment _statusMoment = BattleStatusMoment.turnStart;
  int? _activeSlotIndex;
  int _round = 1;
  int _turnIndex = 0;
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
      icon: Icons.format_list_numbered,
      title: context.uiText('Iniziativa e turni', 'Initiative and turns'),
      description: context.uiText(
        'Aggiungi partecipanti, modifica l’ordine e usa il comando del turno successivo. Quando il giro termina, il round avanza automaticamente.',
        'Add participants, change the order and use the next-turn command. When the cycle ends, the round advances automatically.',
      ),
      fallbackScrollFraction: .16,
    ),
    GuidedTourStepData(
      targetKey: _environmentKey,
      icon: Icons.public_outlined,
      title: context.uiText('Meteo e terreno', 'Weather and terrain'),
      description: context.uiText(
        'L’ambiente applica regole e modificatori a velocità, CA, tipi e danni. Puoi impostarlo manualmente o generare il meteo con il d100.',
        'The environment applies rules and modifiers to speed, AC, types and damage. Set it manually or roll weather with a d100.',
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
    _temporaryHpBySlot.clear();
    _temporaryHpEnabledBySlot.clear();
    _temporaryHpInitializedSlots.clear();
    _initiativeEntries.clear();
    _round = 1;
    _turnIndex = 0;
    _activeSlotIndex = null;
    _environment = const BattleEnvironment();

    final session = await _battleSessionRepository.getSession(data.profile.id);
    if (session != null) {
      _round = session.round;
      _environment = session.environment;
      _initiativeEntries.addAll(session.initiativeEntries);

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
      _turnIndex = _initiativeEntries.isEmpty
          ? 0
          : session.turnIndex.clamp(0, _initiativeEntries.length - 1).toInt();
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
    if (activeSlot != null) {
      _activeSlotIndex = activeSlot.slotIndex;
      final pokemon = _pokemonForSlot(data, activeSlot);
      if (pokemon != null) _ensureInitiative(data, activeSlot, pokemon);
    }
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
        turnIndex: _turnIndex,
        activeSlotIndex: _activeSlotIndex,
        pokemonStates: states,
        initiativeEntries: List<BattleInitiativeEntry>.from(_initiativeEntries),
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
    if (basePokemon.name == 'Palafin' &&
        BattleFormChangeService.canonicalFormKey(basePokemon, formName) ==
            'hero') {
      return basePokemon;
    }
    return basePokemon.resolveVariant(formName: formName, gender: slot.gender);
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

  int _rollTrainerInitiative(UserProfile profile) {
    return _random.nextInt(20) + 1 + _trainerInitiativeBonus(profile);
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

  Future<void> _changeHp(_BattleData data, TeamSlot slot, int delta) async {
    final pokemon = _pokemonForSlot(data, slot);
    if (pokemon == null) return;

    final maxHp = _maxHpFor(pokemon, slot);
    var hpDelta = delta;
    var absorbed = 0;
    final rule = _temporaryHpRule(data, slot);
    if (delta < 0 &&
        rule != null &&
        (_temporaryHpEnabledBySlot[slot.slotIndex] ?? false)) {
      final currentTemporaryHp = _temporaryHpBySlot[slot.slotIndex] ?? 0;
      absorbed = min(currentTemporaryHp, -delta);
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
    await _teamRepository.updateSlot(
      profileId: data.profile.id,
      updatedSlot: slot.copyWith(currentHp: updatedHp),
    );
    await _saveSession(data);
    final message = absorbed == 0
        ? null
        : (_temporaryHpBySlot[slot.slotIndex] ?? 0) > 0
        ? '$absorbed danni assorbiti dai PF temporanei.'
        : '$absorbed danni assorbiti: ${rule?.label ?? 'la protezione'} si spezza.';
    await _reload(message: message);
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

    final maxHp = _maxHpFor(pokemon, slot);
    final updatedHp =
        input.trim().startsWith('+') || input.trim().startsWith('-')
        ? (_currentHpFor(slot, pokemon) + value).clamp(0, maxHp).toInt()
        : value.clamp(0, maxHp).toInt();

    await _teamRepository.updateSlot(
      profileId: data.profile.id,
      updatedSlot: slot.copyWith(currentHp: updatedHp),
    );
    await _reload();
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
    await _teamRepository.updateSlot(
      profileId: data.profile.id,
      updatedSlot: slot.copyWith(
        currentHp: _maxHpFor(pokemon, slot),
        statusEffects: const [],
      ),
    );
    await _saveSession(data);
    await _reload(
      message: context.uiText(
        '${_displayName(slot, pokemon)} è pronto a combattere.',
        '${_displayName(slot, pokemon)} is ready to battle.',
      ),
    );
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
    if (result != null) {
      _volatileStatusesBySlot[slot.slotIndex] = result.volatileStatuses;
    }
    await _saveSession(data);
    await _reload(
      message:
          result?.message ??
          context.uiText(
            '${heldItem.name} è stato consumato. Applica manualmente il suo effetto se necessario.',
            '${heldItem.name} was consumed. Apply its effect manually if needed.',
          ),
    );
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
      _volatileStatusesBySlot[slot.slotIndex] = result.volatileStatuses;
      await _saveSession(data);
      await _reload(message: result.message);
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
    _volatileStatusesBySlot[slot.slotIndex] = result.volatileStatuses;
    await _teamRepository.updateSlot(
      profileId: data.profile.id,
      updatedSlot: slot.copyWith(
        statusEffects: result.nonVolatileStatus == null
            ? const []
            : [result.nonVolatileStatus!],
      ),
    );
    await _saveSession(data);
    await _reload();
  }

  void _ensureInitiative(_BattleData data, TeamSlot slot, Pokemon pokemon) {
    final label = '${data.profile.name} + ${_displayName(slot, pokemon)}';
    final index = _initiativeEntries.indexWhere(
      (entry) => entry.isTrainerGroup,
    );

    if (index == -1) {
      _initiativeEntries.add(
        BattleInitiativeEntry(
          id: 'trainer',
          name: label,
          initiative: _rollTrainerInitiative(data.profile),
          isTrainerGroup: true,
        ),
      );
      _sortInitiative();
    } else if (_initiativeEntries[index].name != label) {
      _initiativeEntries[index] = _initiativeEntries[index].copyWith(
        name: label,
      );
    }
  }

  void _sortInitiative() {
    _initiativeEntries.sort((a, b) {
      final initiativeCompare = b.initiative.compareTo(a.initiative);
      if (initiativeCompare != 0) return initiativeCompare;
      if (a.isTrainerGroup != b.isTrainerGroup) {
        return a.isTrainerGroup ? -1 : 1;
      }
      return a.name.compareTo(b.name);
    });
    _turnIndex = _initiativeEntries.isEmpty
        ? 0
        : _turnIndex.clamp(0, _initiativeEntries.length - 1).toInt();
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

  void _rollEnvironmentWeather(_BattleData data) {
    final roll = _random.nextInt(100) + 1;
    final weather = BattleEnvironmentService.rollWeather(
      _environment.season,
      roll,
    );
    setState(() {
      _environment = _environment.copyWith(
        weather: weather,
        weatherRoundsRemaining: 0,
        weatherSourceLevel: 0,
      );
      _message = context.uiText(
        'Meteo d100: $roll - ${weather.label}.',
        'Weather d100: $roll - ${weather.label}.',
      );
    });
    _scheduleSessionSave(data);
  }

  Future<void> _applyEnvironmentWeatherDamage(
    _BattleData data,
    TeamSlot slot,
  ) async {
    final pokemon = _pokemonForSlot(data, slot);
    if (pokemon == null) return;
    final damage = BattleEnvironmentService.startTurnWeatherDamage(
      pokemon: pokemon,
      slot: slot,
      environment: _environment,
    );
    if (damage == null || damage <= 0) return;
    final maxHp = _maxHpFor(pokemon, slot);
    final currentHp = _currentHpFor(slot, pokemon);
    final updatedHp = (currentHp - damage).clamp(0, maxHp).toInt();
    await _teamRepository.updateSlot(
      profileId: data.profile.id,
      updatedSlot: slot.copyWith(currentHp: updatedHp),
    );
    await _reload(
      message: context.uiText(
        '${_displayName(slot, pokemon)} subisce $damage danni da ${_environment.weather.label}.',
        '${_displayName(slot, pokemon)} takes $damage damage from ${_environment.weather.label}.',
      ),
    );
  }

  void _rerollTrainerInitiative(_BattleData data) {
    setState(() {
      final index = _initiativeEntries.indexWhere(
        (entry) => entry.isTrainerGroup,
      );
      final roll = _rollTrainerInitiative(data.profile);
      if (index == -1) {
        _initiativeEntries.add(
          BattleInitiativeEntry(
            id: 'trainer',
            name: '${data.profile.name} + Pokémon',
            initiative: roll,
            isTrainerGroup: true,
          ),
        );
      } else {
        _initiativeEntries[index] = _initiativeEntries[index].copyWith(
          initiative: roll,
        );
      }
      _turnIndex = 0;
      _sortInitiative();
      _message = context.uiText(
        'Iniziativa allenatore/Pokémon: $roll.',
        'Trainer/Pokémon initiative: $roll.',
      );
    });
    _scheduleSessionSave(data);
  }

  Future<void> _addInitiativeEntry(_BattleData data) async {
    final input = await showDialog<_InitiativeEntryInput>(
      context: context,
      builder: (_) => const _InitiativeEntryDialog(),
    );
    if (!mounted || input == null) return;

    setState(() {
      _initiativeEntries.add(
        BattleInitiativeEntry(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: input.name,
          initiative: input.initiative,
          isTrainerGroup: false,
        ),
      );
      _sortInitiative();
    });
    _scheduleSessionSave(data);
  }

  void _removeInitiativeEntry(_BattleData data, BattleInitiativeEntry entry) {
    setState(() {
      _initiativeEntries.removeWhere((candidate) => candidate.id == entry.id);
      _sortInitiative();
    });
    _scheduleSessionSave(data);
  }

  void _nextTurn(_BattleData data) {
    setState(() {
      _statusMoment = BattleStatusMoment.turnStart;
      if (_initiativeEntries.isEmpty) return;
      if (_turnIndex + 1 >= _initiativeEntries.length) {
        _turnIndex = 0;
        _round += 1;
        _environment = _environment.advanceRound();
        _message = context.uiText(
          'Round $_round iniziato.',
          'Round $_round started.',
        );
      } else {
        _turnIndex += 1;
        _message = null;
      }
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
            'Round, iniziativa, PP, PF temporanei, forme di battaglia e status volatili verranno rimossi. HP, status persistenti e oggetti consumati resteranno salvati.',
            'Rounds, initiative, PP, temporary HP, battle forms and volatile conditions will be cleared. HP, persistent conditions and consumed items will remain saved.',
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
    _temporaryHpBySlot.clear();
    _temporaryHpEnabledBySlot.clear();
    _temporaryHpInitializedSlots.clear();
    _initiativeEntries.clear();
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

  String _moveStats(
    MoveData move,
    Pokemon pokemon,
    TeamSlot slot,
    Pokemon basePokemon,
    String? formName,
  ) {
    final level = _levelForSlot(slot);
    final moveModifier = _bestMoveModifier(
      move,
      pokemon,
      slot,
      basePokemon: basePokemon,
      formName: formName,
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
          move: move,
          moveModifier: moveModifier,
        );
    final effectiveMoveType = BattleEnvironmentService.effectiveMoveType(
      move,
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
      move: move,
      pokemonLevel: level,
      moveTypeOverride: effectiveMoveType,
    );
    final parts = <String>[];

    if (move.isAttack) {
      final attackBonus =
          moveModifier +
          proficiency +
          attackPathBonus +
          terrainAttackBonus +
          formAttackBonus;
      parts.add('AB ${attackBonus >= 0 ? '+' : ''}$attackBonus');
    }
    if (move.save != null) parts.add('CD ${8 + proficiency + moveModifier}');

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
    }
    parts.addAll(
      BattleEnvironmentService.moveNotes(
        environment: _environment,
        move: move,
        moveModifier: moveModifier,
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
                      final effectiveArmorClass =
                          formArmorClass +
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
                                  _BattleHeader(
                                    round: _round,
                                    profile: data.profile,
                                    trainerInitiativeBonus:
                                        _trainerInitiativeBonus(data.profile),
                                    onEnd: () => _endBattle(data),
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
                                    onSelected: (slotIndex) {
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
                              key: _initiativeKey,
                              child: _InitiativeTracker(
                                round: _round,
                                entries: _initiativeEntries,
                                currentTurnIndex: _turnIndex,
                                trainerInitiativeBonus: _trainerInitiativeBonus(
                                  data.profile,
                                ),
                                onRollTrainer: () =>
                                    _rerollTrainerInitiative(data),
                                onAddEntry: () => _addInitiativeEntry(data),
                                onRemoveEntry: (entry) =>
                                    _removeInitiativeEntry(data, entry),
                                onNextTurn: () => _nextTurn(data),
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
                                onRollWeather: () =>
                                    _rollEnvironmentWeather(data),
                                onApplyWeatherDamage:
                                    BattleEnvironmentService.startTurnWeatherDamage(
                                          pokemon: pokemon,
                                          slot: activeSlot,
                                          environment: _environment,
                                        ) ==
                                        null
                                    ? null
                                    : () => _applyEnvironmentWeatherDamage(
                                        data,
                                        activeSlot,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            KeyedSubtree(
                              key: _activePokemonKey,
                              child: _ActivePokemonCard(
                                pokemon: pokemon,
                                imagePokemon: basePokemon,
                                slot: activeSlot,
                                formName: effectiveFormName,
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
                                displayName: _displayName(activeSlot, pokemon),
                                level: _levelForSlot(activeSlot),
                                baseArmorClass: formArmorClass,
                                effectiveArmorClass: effectiveArmorClass,
                                currentHp: _currentHpFor(activeSlot, pokemon),
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
                                onMinusFive: () =>
                                    _changeHp(data, activeSlot, -5),
                                onMinusOne: () =>
                                    _changeHp(data, activeSlot, -1),
                                onPlusOne: () => _changeHp(data, activeSlot, 1),
                                onPlusFive: () =>
                                    _changeHp(data, activeSlot, 5),
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
  });

  final UserProfile profile;
  final List<TeamSlot> team;
  final Map<int, Pokemon> pokemonById;
  final Map<String, MoveData?> moves;
  final List<BagItem> items;
  final List<BagInventoryEntry> inventory;

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

class _InitiativeEntryInput {
  const _InitiativeEntryInput({required this.name, required this.initiative});

  final String name;
  final int initiative;
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
    required this.onEnd,
  });

  final int round;
  final UserProfile profile;
  final int trainerInitiativeBonus;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Round $round',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
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
              ),
            ),
            IconButton(
              tooltip: context.uiText('Termina battaglia', 'End battle'),
              onPressed: onEnd,
              icon: const Icon(Icons.stop_circle_outlined),
            ),
          ],
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
    required this.onSelected,
  });

  final List<TeamSlot> slots;
  final TeamSlot activeSlot;
  final Pokemon? Function(TeamSlot slot) pokemonForSlot;
  final Pokemon? Function(TeamSlot slot) imagePokemonForSlot;
  final String? Function(TeamSlot slot) formNameForSlot;
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
    required this.selected,
    required this.onTap,
  });

  final TeamSlot slot;
  final Pokemon? pokemon;
  final Pokemon? imagePokemon;
  final String? formName;
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
                PokemonAssetImage(
                  pokemon: imagePokemon ?? pokemon,
                  size: 40,
                  formName: formName,
                  gender: slot.gender,
                  isShiny: slot.isShiny,
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

class _InitiativeTracker extends StatelessWidget {
  const _InitiativeTracker({
    required this.round,
    required this.entries,
    required this.currentTurnIndex,
    required this.trainerInitiativeBonus,
    required this.onRollTrainer,
    required this.onAddEntry,
    required this.onRemoveEntry,
    required this.onNextTurn,
  });

  final int round;
  final List<BattleInitiativeEntry> entries;
  final int currentTurnIndex;
  final int trainerInitiativeBonus;
  final VoidCallback onRollTrainer;
  final VoidCallback onAddEntry;
  final ValueChanged<BattleInitiativeEntry> onRemoveEntry;
  final VoidCallback onNextTurn;

  @override
  Widget build(BuildContext context) {
    final currentEntry = entries.isEmpty
        ? null
        : entries[currentTurnIndex.clamp(0, entries.length - 1).toInt()];

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.uiText('INIZIATIVA', 'INITIATIVE'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text('Round $round'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    currentEntry == null
                        ? context.uiText(
                            'Nessun turno impostato.',
                            'No turn is set.',
                          )
                        : context.uiText(
                            'Turno: ${currentEntry.name}',
                            'Turn: ${currentEntry.name}',
                          ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onNextTurn,
                  icon: const Icon(Icons.navigate_next),
                  label: Text(context.uiText('PROSSIMO TURNO', 'NEXT TURN')),
                ),
              ],
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              dense: true,
              visualDensity: VisualDensity.compact,
              title: Text(
                context.uiText(
                  'Ordine e comandi (${entries.length})',
                  'Order and commands (${entries.length})',
                ),
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: onRollTrainer,
                        icon: const Icon(Icons.casino_outlined),
                        label: Text(
                          '${context.uiText('RITIRA ALLENATORE', 'REROLL TRAINER')} '
                          '(${trainerInitiativeBonus >= 0 ? '+' : ''}$trainerInitiativeBonus)',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: onAddEntry,
                        icon: const Icon(Icons.add),
                        label: Text(context.uiText('AGGIUNGI', 'ADD')),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                for (final indexed in entries.indexed)
                  _InitiativeTile(
                    entry: indexed.$2,
                    active: indexed.$1 == currentTurnIndex,
                    onRemove: indexed.$2.isTrainerGroup
                        ? null
                        : () => onRemoveEntry(indexed.$2),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InitiativeTile extends StatelessWidget {
  const _InitiativeTile({
    required this.entry,
    required this.active,
    required this.onRemove,
  });

  final BattleInitiativeEntry entry;
  final bool active;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: active
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          dense: true,
          leading: CircleAvatar(child: Text(entry.initiative.toString())),
          title: Text(
            entry.name,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            entry.isTrainerGroup
                ? context.uiText('Allenatore + Pokémon', 'Trainer + Pokémon')
                : context.uiText(
                    'Partecipante esterno',
                    'External participant',
                  ),
          ),
          trailing: onRemove == null
              ? null
              : IconButton(
                  tooltip: context.uiText('Rimuovi', 'Remove'),
                  onPressed: onRemove,
                  icon: const Icon(Icons.close),
                ),
        ),
      ),
    );
  }
}

class _InitiativeEntryDialog extends StatefulWidget {
  const _InitiativeEntryDialog();

  @override
  State<_InitiativeEntryDialog> createState() => _InitiativeEntryDialogState();
}

class _InitiativeEntryDialogState extends State<_InitiativeEntryDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _initiativeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _initiativeController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final initiative = int.tryParse(_initiativeController.text.trim());
    if (name.isEmpty || initiative == null) return;
    Navigator.of(
      context,
    ).pop(_InitiativeEntryInput(name: name, initiative: initiative));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(context.uiText('Aggiungi iniziativa', 'Add initiative')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: context.uiText(
                'Nome partecipante',
                'Participant name',
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _initiativeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: context.uiText('Iniziativa', 'Initiative'),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.uiText('Annulla', 'Cancel')),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(context.uiText('Aggiungi', 'Add')),
        ),
      ],
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
    required this.onMinusFive,
    required this.onMinusOne,
    required this.onPlusOne,
    required this.onPlusFive,
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
  final VoidCallback onMinusFive;
  final VoidCallback onMinusOne;
  final VoidCallback onPlusOne;
  final VoidCallback onPlusFive;
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
                PokemonAssetImage(
                  pokemon: imagePokemon,
                  useLargeArtwork: true,
                  size: 96,
                  formName: formName,
                  gender: slot.gender,
                  isShiny: slot.isShiny,
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
                _SmallBattleButton(label: '-5', onTap: onMinusFive),
                _SmallBattleButton(label: '-1', onTap: onMinusOne),
                _SmallBattleButton(label: '+1', onTap: onPlusOne),
                _SmallBattleButton(label: '+5', onTap: onPlusFive),
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
    required this.remainingPp,
    required this.maxPp,
    required this.stats,
    required this.onUse,
    required this.onRestore,
  });

  final String reference;
  final MoveData? move;
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
              if (move != null) PokemonTypeBadge(type: move.type, height: 18),
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

class _SmallBattleButton extends StatelessWidget {
  const _SmallBattleButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: onTap, child: Text(label));
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
