import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../localization/ui_text.dart';
import '../../localization/user_facing_error.dart';
import '../../models/battle_session.dart';
import '../../models/generated_pokemon.dart';
import '../../models/master_battle_session.dart';
import '../../models/move_data.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_form_choice.dart';
import '../../repositories/master_battle_session_repository.dart';
import '../../repositories/move_repository.dart';
import '../../services/battle_status_rules.dart';
import '../../services/master_battle_service.dart';
import '../../services/master_fight_summary_service.dart';
import '../../services/native_share_service.dart';
import '../../widgets/battle/battle_status_assistance_card.dart';
import '../../widgets/layout/responsive_content.dart';
import '../../widgets/navigation/home_leading_button.dart';
import '../../widgets/pokemon/pokemon_asset_image.dart';
import '../pokemon/pokemon_detail_screen.dart';

class NpcBattleScreen extends StatefulWidget {
  const NpcBattleScreen({
    super.key,
    required this.profileId,
    required this.catalog,
    required this.initialSession,
  });

  final String profileId;
  final List<Pokemon> catalog;
  final MasterBattleSession initialSession;

  @override
  State<NpcBattleScreen> createState() => _NpcBattleScreenState();
}

class _NpcBattleScreenState extends State<NpcBattleScreen> {
  final MasterBattleSessionRepository _repository =
      MasterBattleSessionRepository();
  final MasterBattleService _battleService = const MasterBattleService();
  final MasterFightSummaryService _summaryService =
      const MasterFightSummaryService();
  final NativeShareService _shareService = const NativeShareService();
  final MoveRepository _moveRepository = MoveRepository();
  final Random _random = Random();

  late MasterBattleSession _session;
  Map<String, MoveData?> _moves = const {};
  bool _isWorking = false;
  String? _message;
  BattleStatusMoment _statusMoment = BattleStatusMoment.turnStart;

  @override
  void initState() {
    super.initState();
    _session = widget.initialSession;
    _loadMoves();
  }

  Map<int, Pokemon> get _pokemonById => {
    for (final pokemon in widget.catalog) pokemon.id: pokemon,
  };

  MasterBattleParticipant get _selectedParticipant {
    for (final participant in _session.participants) {
      if (participant.trainerId == _session.selectedTrainerId) {
        return participant;
      }
    }
    return _session.participants.first;
  }

  MasterBattlePokemonState get _focusedState {
    final participant = _selectedParticipant;
    final focused = _session.focusedSlotIndex;
    if (focused != null) {
      for (final state in participant.team) {
        if (state.slotIndex == focused) return state;
      }
    }
    for (final state in participant.team) {
      if (participant.activeSlotIndices.contains(state.slotIndex)) return state;
    }
    return participant.team.first;
  }

  Future<void> _loadMoves() async {
    final referencesByPokemon = <int, Set<String>>{};
    for (final participant in _session.participants) {
      for (final state in participant.team) {
        referencesByPokemon
            .putIfAbsent(state.pokemon.pokemonId, () => <String>{'Struggle'})
            .addAll(state.pokemon.selectedMoves);
      }
    }
    final moves = await _moveRepository.getMovesByPokemon(referencesByPokemon);
    if (!mounted) return;
    setState(() => _moves = moves);
  }

  MoveData? _moveForState(MasterBattlePokemonState state, String reference) {
    return _moves[MoveRepository.contextualKey(
      state.pokemon.pokemonId,
      reference,
    )];
  }

  Future<void> _commit(MasterBattleSession next, {String? message}) async {
    final normalized = _withCatalogInitiativeNames(
      next,
    ).copyWith(updatedAt: DateTime.now());
    setState(() {
      _session = normalized;
      _message = message;
    });
    await _repository.saveSession(normalized);
  }

  MasterBattleSession _withCatalogInitiativeNames(MasterBattleSession session) {
    final participants = {
      for (final participant in session.participants)
        participant.trainerId: participant,
    };
    final entries = [
      for (final entry in session.initiativeEntries)
        if (!entry.isTrainerGroup)
          entry
        else
          entry.copyWith(name: _initiativeName(entry.id, participants)),
    ];
    return session.copyWith(initiativeEntries: entries);
  }

  String _initiativeName(
    String entryId,
    Map<String, MasterBattleParticipant> participants,
  ) {
    if (!entryId.startsWith('npc:')) {
      return uiTextForLanguage('Allenatore PNG', """NPC Trainer""");
    }
    final raw = entryId.substring(4);
    final separator = raw.lastIndexOf(':');
    if (separator <= 0) {
      return uiTextForLanguage('Allenatore PNG', """NPC Trainer""");
    }
    final trainerId = raw.substring(0, separator);
    final slotIndex = int.tryParse(raw.substring(separator + 1));
    final participant = participants[trainerId];
    if (participant == null || slotIndex == null) {
      return uiTextForLanguage('Allenatore PNG', """NPC Trainer""");
    }
    MasterBattlePokemonState? state;
    for (final candidate in participant.team) {
      if (candidate.slotIndex == slotIndex) {
        state = candidate;
        break;
      }
    }
    final pokemon = state == null
        ? null
        : _pokemonById[state.pokemon.pokemonId];
    final pokemonName = pokemon == null
        ? '#${state?.pokemon.pokemonId ?? '?'}'
        : pokemonFormDisplayName(pokemon.name, state!.pokemon.formName);
    return '${participant.name} + $pokemonName';
  }

  Future<void> _selectTrainer(String trainerId) async {
    setState(() => _statusMoment = BattleStatusMoment.turnStart);
    final participant = _session.participants.firstWhere(
      (candidate) => candidate.trainerId == trainerId,
    );
    final focus = participant.activeSlotIndices.isNotEmpty
        ? participant.activeSlotIndices.first
        : participant.team.first.slotIndex;
    await _commit(
      _session.copyWith(selectedTrainerId: trainerId, focusedSlotIndex: focus),
    );
  }

  Future<void> _focusPokemon(int slotIndex) async {
    setState(() => _statusMoment = BattleStatusMoment.turnStart);
    await _commit(_session.copyWith(focusedSlotIndex: slotIndex));
  }

  Future<void> _toggleActive(int slotIndex) async {
    final participant = _selectedParticipant;
    final active = {...participant.activeSlotIndices};
    if (active.contains(slotIndex)) {
      if (active.length == 1) {
        setState(() {
          _message = uiTextForLanguage(
            'Ogni allenatore deve avere almeno un Pokémon attivo.',
            """Every trainer must have at least one active Pokémon.""",
          );
        });
        return;
      }
      active.remove(slotIndex);
    } else {
      if (active.length >= participant.activeLimit) {
        active.remove(active.first);
      }
      active.add(slotIndex);
    }
    final participants = [
      for (final candidate in _session.participants)
        candidate.trainerId == participant.trainerId
            ? candidate.copyWith(activeSlotIndices: active)
            : candidate,
    ];
    var next = _session.copyWith(
      participants: participants,
      focusedSlotIndex: slotIndex,
    );
    next = _battleService.syncInitiative(next, random: _random);
    await _commit(next);
  }

  Future<void> _updateFocusedState(
    MasterBattlePokemonState updated, {
    String? message,
  }) async {
    final participant = _selectedParticipant;
    final team = [
      for (final state in participant.team)
        state.slotIndex == updated.slotIndex ? updated : state,
    ];
    final participants = [
      for (final candidate in _session.participants)
        candidate.trainerId == participant.trainerId
            ? candidate.copyWith(team: team)
            : candidate,
    ];
    await _commit(
      _session.copyWith(participants: participants),
      message: message,
    );
  }

  Future<void> _changeHp(int delta) async {
    final state = _focusedState;
    final nextHp = (state.currentHp + delta)
        .clamp(0, state.pokemon.maxHp)
        .toInt();
    await _updateFocusedState(state.copyWith(currentHp: nextHp));
  }

  Future<void> _editHp() async {
    final state = _focusedState;
    final raw = await showDialog<String>(
      context: context,
      builder: (_) => _NpcHpInputDialog(
        currentHp: state.currentHp,
        maxHp: state.pokemon.maxHp,
      ),
    );
    if (!mounted || raw == null) return;

    final input = raw.trim();
    final value = int.tryParse(input);
    if (value == null) return;
    final updatedHp = input.startsWith('+') || input.startsWith('-')
        ? (state.currentHp + value).clamp(0, state.pokemon.maxHp).toInt()
        : value.clamp(0, state.pokemon.maxHp).toInt();
    await _updateFocusedState(state.copyWith(currentHp: updatedHp));
  }

  Future<void> _healFocused() async {
    final state = _focusedState;
    await _updateFocusedState(
      state.copyWith(
        currentHp: state.pokemon.maxHp,
        nonVolatileStatus: null,
        volatileStatuses: const {},
      ),
      message: uiTextForLanguage(
        'Pokémon ripristinato completamente.',
        """Pokémon fully restored.""",
      ),
    );
  }

  Future<void> _editStatuses() async {
    final state = _focusedState;
    final result = await showDialog<_StatusResult>(
      context: context,
      builder: (_) => _StatusDialog(
        nonVolatile: state.nonVolatileStatus,
        volatile: state.volatileStatuses,
      ),
    );
    if (result == null) return;
    setState(() => _statusMoment = BattleStatusMoment.turnStart);
    await _updateFocusedState(
      state.copyWith(
        nonVolatileStatus: result.nonVolatile,
        volatileStatuses: result.volatile,
      ),
    );
  }

  int _maxPp(MoveData? move) {
    if (move == null) return 0;
    final direct = int.tryParse(move.pp.trim());
    if (direct != null) return direct;
    final match = RegExp(r'\d+').firstMatch(move.pp);
    return int.tryParse(match?.group(0) ?? '') ?? 0;
  }

  String _ppKey(String reference, MoveData? move) =>
      move?.id ?? MoveData.referenceKey(reference);

  int _remainingPp(
    MasterBattlePokemonState state,
    String reference,
    MoveData? move,
  ) {
    final maxPp = _maxPp(move);
    return (state.remainingPp[_ppKey(reference, move)] ?? maxPp)
        .clamp(0, maxPp)
        .toInt();
  }

  Future<void> _changePp(String reference, MoveData? move, int delta) async {
    final state = _focusedState;
    final maxPp = _maxPp(move);
    if (maxPp <= 0) return;
    final key = _ppKey(reference, move);
    final current = _remainingPp(state, reference, move);
    final remaining = {...state.remainingPp};
    remaining[key] = (current + delta).clamp(0, maxPp).toInt();
    if (delta < 0) {
      setState(() => _statusMoment = BattleStatusMoment.actionAttempt);
    }
    await _updateFocusedState(state.copyWith(remainingPp: remaining));
  }

  Future<void> _nextTurn() async {
    setState(() => _statusMoment = BattleStatusMoment.turnStart);
    final entries = _session.initiativeEntries;
    if (entries.isEmpty) return;
    var nextIndex = _session.turnIndex + 1;
    var nextRound = _session.round;
    if (nextIndex >= entries.length) {
      nextIndex = 0;
      nextRound++;
    }
    await _commit(_session.copyWith(round: nextRound, turnIndex: nextIndex));
  }

  Future<void> _rerollInitiative() async {
    final entries = [
      for (final entry in _session.initiativeEntries)
        entry.copyWith(initiative: _random.nextInt(20) + 1),
    ]..sort((a, b) => b.initiative.compareTo(a.initiative));
    await _commit(
      _session.copyWith(initiativeEntries: entries, turnIndex: 0),
      message: uiTextForLanguage(
        'Iniziativa rilanciata.',
        """Initiative rerolled.""",
      ),
    );
  }

  Future<void> _addInitiativeEntry() async {
    final nameController = TextEditingController();
    final initiativeController = TextEditingController(
      text: '${_random.nextInt(20) + 1}',
    );
    final result = await showDialog<_InitiativeInput>(
      context: context,
      builder: (_) => AlertDialog(
        scrollable: true,
        title: Text(
          uiTextForLanguage(
            'Aggiungi partecipante esterno',
            """Add external participant""",
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: uiTextForLanguage('Nome', """Name"""),
              ),
            ),
            TextField(
              controller: initiativeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: uiTextForLanguage('Iniziativa', """Initiative"""),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(uiTextForLanguage('Annulla', """Cancel""")),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final initiative = int.tryParse(initiativeController.text.trim());
              if (name.isEmpty || initiative == null) return;
              Navigator.of(
                context,
              ).pop(_InitiativeInput(name: name, initiative: initiative));
            },
            child: Text(uiTextForLanguage('Aggiungi', """Add""")),
          ),
        ],
      ),
    );
    nameController.dispose();
    initiativeController.dispose();
    if (result == null) return;
    final entries = [
      ..._session.initiativeEntries,
      BattleInitiativeEntry(
        id: 'external:${DateTime.now().microsecondsSinceEpoch}',
        name: result.name,
        initiative: result.initiative,
        isTrainerGroup: false,
      ),
    ]..sort((a, b) => b.initiative.compareTo(a.initiative));
    await _commit(_session.copyWith(initiativeEntries: entries, turnIndex: 0));
  }

  Future<void> _removeInitiativeEntry(BattleInitiativeEntry entry) async {
    if (entry.isTrainerGroup) return;
    final entries = [
      for (final candidate in _session.initiativeEntries)
        if (candidate.id != entry.id) candidate,
    ];
    await _commit(
      _session.copyWith(
        initiativeEntries: entries,
        turnIndex: entries.isEmpty
            ? 0
            : _session.turnIndex.clamp(0, entries.length - 1).toInt(),
      ),
    );
  }

  Future<void> _resetFight() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        scrollable: true,
        title: Text(
          uiTextForLanguage('Azzera il fight?', """Reset the fight?"""),
        ),
        content: Text(
          uiTextForLanguage(
            'PF, PP, status, Pokémon attivi, iniziativa e round verranno riportati allo stato iniziale.',
            """HP, PP, statuses, active Pokémon, initiative and round will be reset to their initial state.""",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(uiTextForLanguage('Annulla', """Cancel""")),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(uiTextForLanguage('Azzera', """Reset""")),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _commit(
      _battleService.reset(_session, random: _random),
      message: uiTextForLanguage('Fight azzerato.', 'Fight reset.'),
    );
  }

  Future<void> _exportSummary() async {
    if (_isWorking) return;
    setState(() => _isWorking = true);
    try {
      final exportedAt = DateTime.now();
      final summary = _summaryService.build(
        session: _session,
        pokemonById: _pokemonById,
        exportedAt: exportedAt,
      );
      final path = await FilePicker.platform.saveFile(
        dialogTitle: uiTextForLanguage(
          'Esporta riepilogo del Fight del Master',
          """Export Master Fight summary""",
        ),
        fileName: _summaryService.fileName(_session, exportedAt: exportedAt),
        type: FileType.custom,
        allowedExtensions: const ['txt'],
        bytes: Uint8List.fromList(utf8.encode(summary)),
      );
      if (!mounted) return;
      setState(() {
        _message = path == null
            ? uiTextForLanguage(
                'Esportazione annullata.',
                """Export cancelled.""",
              )
            : uiTextForLanguage(
                'Riepilogo del fight esportato correttamente.',
                """Fight summary exported successfully.""",
              );
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = context.userFacingError(
          error,
          action: UserFacingErrorAction.exportFile,
        );
      });
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _shareSummary() async {
    if (_isWorking) return;
    setState(() => _isWorking = true);
    try {
      final exportedAt = DateTime.now();
      final summary = _summaryService.build(
        session: _session,
        pokemonById: _pokemonById,
        exportedAt: exportedAt,
      );
      final outcome = await _shareService.shareTextFile(
        context: context,
        content: summary,
        fileName: _summaryService.fileName(_session, exportedAt: exportedAt),
        mimeType: 'text/plain',
        title: uiTextForLanguage(
          'Condividi il riepilogo del Fight del Master',
          """Share the Master Fight summary""",
        ),
        subject: uiTextForLanguage(
          'Riepilogo Fight del Master · Trainer Atlas 5e',
          """Master Fight Summary · Trainer Atlas 5e""",
        ),
        text: uiTextForLanguage(
          'Riepilogo esportato da Trainer Atlas 5e.',
          """Summary exported by Trainer Atlas 5e.""",
        ),
      );
      if (!mounted) return;
      setState(() {
        _message = _shareService.feedback(
          outcome,
          successMessage: uiTextForLanguage(
            'Riepilogo del fight condiviso correttamente.',
            """Fight summary shared successfully.""",
          ),
        );
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = context.userFacingError(
          error,
          action: UserFacingErrorAction.share,
        );
      });
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _endFight() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        scrollable: true,
        title: Text(uiTextForLanguage('Terminare il fight?', 'End the fight?')),
        content: Text(
          uiTextForLanguage(
            'La sessione del Master verrà eliminata. Gli Allenatori PNG salvati rimarranno intatti nella libreria.',
            """The Master session will be deleted. Saved NPC Trainers will remain in the library.""",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(uiTextForLanguage('Annulla', """Cancel""")),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(uiTextForLanguage('Termina fight', """End fight""")),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isWorking = true);
    await _repository.deleteSession(widget.profileId);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  GeneratedPokemon _generatedFor(MasterBattlePokemonState state) {
    final base = _pokemonById[state.pokemon.pokemonId];
    if (base == null) {
      throw StateError(
        uiTextForLanguage(
          'Pokémon #${state.pokemon.pokemonId} non disponibile.',
          """Pokémon #${state.pokemon.pokemonId} is unavailable.""",
        ),
      );
    }
    return GeneratedPokemon(
      basePokemon: base,
      pokemon: base.resolveVariant(
        formName: state.pokemon.formName,
        gender: state.pokemon.gender,
      ),
      formName: state.pokemon.formName,
      level: state.pokemon.level,
      gender: state.pokemon.gender,
      nature: state.pokemon.nature,
      ability: state.pokemon.ability,
      selectedMoves: state.pokemon.selectedMoves,
      isShiny: state.pokemon.isShiny,
      maxHp: state.pokemon.maxHp,
    );
  }

  Future<void> _openDetails() async {
    final generated = _generatedFor(_focusedState);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PokemonDetailScreen(
          pokemon: generated.basePokemon,
          teamSlot: generated
              .toTeamSlot(slotIndex: _focusedState.slotIndex)
              .copyWith(
                currentHp: _focusedState.currentHp,
                statusEffects: [
                  if (_focusedState.nonVolatileStatus != null)
                    _focusedState.nonVolatileStatus!,
                  ..._focusedState.volatileStatuses,
                ],
              ),
          allPokemon: widget.catalog,
          team: const [],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final participant = _selectedParticipant;
    final state = _focusedState;
    final generated = _generatedFor(state);
    final activeCount = _session.participants.fold<int>(
      0,
      (sum, trainer) => sum + trainer.activeSlotIndices.length,
    );
    return Scaffold(
      appBar: AppBar(
        leading: const HomeLeadingButton(),
        title: Text(uiTextForLanguage('Fight del Master', 'Master Fight')),
        actions: [
          const HomeAppBarAction(),
          PopupMenuButton<_FightSummaryAction>(
            enabled: !_isWorking,
            tooltip: uiTextForLanguage(
              'Esporta o condividi riepilogo',
              """Export or share summary""",
            ),
            icon: const Icon(Icons.ios_share_outlined),
            onSelected: (action) {
              switch (action) {
                case _FightSummaryAction.export:
                  _exportSummary();
                  break;
                case _FightSummaryAction.share:
                  _shareSummary();
                  break;
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _FightSummaryAction.export,
                child: Text(
                  uiTextForLanguage('Salva riepilogo', """Save summary"""),
                ),
              ),
              PopupMenuItem(
                value: _FightSummaryAction.share,
                child: Text(
                  uiTextForLanguage('Condividi riepilogo', """Share summary"""),
                ),
              ),
            ],
          ),
          PopupMenuButton<_FightSessionAction>(
            enabled: !_isWorking,
            tooltip: uiTextForLanguage('Azioni del fight', """Fight actions"""),
            onSelected: (action) {
              switch (action) {
                case _FightSessionAction.reset:
                  _resetFight();
                  break;
                case _FightSessionAction.end:
                  _endFight();
                  break;
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _FightSessionAction.reset,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.restart_alt),
                  title: Text(
                    uiTextForLanguage('Azzera fight', """Reset fight"""),
                  ),
                ),
              ),
              PopupMenuItem(
                value: _FightSessionAction.end,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.stop_circle_outlined),
                  title: Text(
                    uiTextForLanguage('Termina fight', """End fight"""),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: ResponsiveContent(
        maxWidth: 1320,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _FightHeader(
              round: _session.round,
              trainerCount: _session.participants.length,
              activePokemonCount: activeCount,
              onEnd: _endFight,
            ),
            if (_message != null) ...[
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_message!),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _session.participants.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final trainer = _session.participants[index];
                  return ChoiceChip(
                    selected: trainer.trainerId == participant.trainerId,
                    avatar: const Icon(Icons.person, size: 18),
                    label: Text(trainer.name),
                    onSelected: (_) => _selectTrainer(trainer.trainerId),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            _TrainerFightCard(participant: participant),
            const SizedBox(height: 12),
            _InitiativeCard(
              round: _session.round,
              entries: _session.initiativeEntries,
              turnIndex: _session.turnIndex,
              onNextTurn: _nextTurn,
              onReroll: _rerollInitiative,
              onAdd: _addInitiativeEntry,
              onRemove: _removeInitiativeEntry,
            ),
            const SizedBox(height: 14),
            Text(
              uiTextForLanguage(
                'SQUADRA DI ${participant.name.toUpperCase()}',
                """${participant.name.toUpperCase()}'S TEAM""",
              ),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            for (final member in participant.team) ...[
              _TeamMemberCard(
                state: member,
                pokemon: _pokemonById[member.pokemon.pokemonId],
                selected: member.slotIndex == state.slotIndex,
                active: participant.activeSlotIndices.contains(
                  member.slotIndex,
                ),
                activeLimit: participant.activeLimit,
                onFocus: () => _focusPokemon(member.slotIndex),
                onToggleActive: () => _toggleActive(member.slotIndex),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 6),
            _FocusedPokemonCard(
              generated: generated,
              state: state,
              active: participant.activeSlotIndices.contains(state.slotIndex),
              onMinusFive: () => _changeHp(-5),
              onMinusOne: () => _changeHp(-1),
              onPlusOne: () => _changeHp(1),
              onPlusFive: () => _changeHp(5),
              onEditHp: _editHp,
              onHeal: _healFocused,
              onStatus: _editStatuses,
              onDetails: _openDetails,
              onToggleActive: () => _toggleActive(state.slotIndex),
            ),
            const SizedBox(height: 12),
            BattleStatusAssistanceCard(
              key: ValueKey(
                'master-status-${participant.trainerId}-${state.slotIndex}',
              ),
              pokemonName: pokemonFormDisplayName(
                generated.basePokemon.name,
                generated.formName,
              ),
              nonVolatileStatus: state.nonVolatileStatus,
              volatileStatuses: state.volatileStatuses,
              selectedMoment: _statusMoment,
              onMomentChanged: (moment) {
                setState(() => _statusMoment = moment);
              },
            ),
            const SizedBox(height: 12),
            Text(
              uiTextForLanguage('MOSSE DA COMBATTIMENTO', """BATTLE MOVES"""),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            for (final reference in state.pokemon.selectedMoves)
              _NpcMoveCard(
                reference: reference,
                move: _moveForState(state, reference),
                level: state.pokemon.level,
                remainingPp: _remainingPp(
                  state,
                  reference,
                  _moveForState(state, reference),
                ),
                maxPp: _maxPp(_moveForState(state, reference)),
                onUse: () =>
                    _changePp(reference, _moveForState(state, reference), -1),
                onRestore: () =>
                    _changePp(reference, _moveForState(state, reference), 1),
              ),
            if (state.pokemon.selectedMoves.isEmpty)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    uiTextForLanguage(
                      'Nessuna mossa selezionata.',
                      """No moves selected.""",
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FightHeader extends StatelessWidget {
  const _FightHeader({
    required this.round,
    required this.trainerCount,
    required this.activePokemonCount,
    required this.onEnd,
  });

  final int round;
  final int trainerCount;
  final int activePokemonCount;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'ROUND $round',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onEnd,
                  tooltip: uiTextForLanguage('Termina fight', """End fight"""),
                  icon: Icon(
                    Icons.stop_circle_outlined,
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            Text(
              uiTextForLanguage(
                '$trainerCount Allenatori PNG · $activePokemonCount Pokémon attivi · nessun avversario gestito dall’app',
                """$trainerCount NPC Trainers · $activePokemonCount active Pokémon · no app-managed opponent""",
              ),
              style: TextStyle(color: colors.onPrimaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainerFightCard extends StatelessWidget {
  const _TrainerFightCard({required this.participant});

  final MasterBattleParticipant participant;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              participant.displayName,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            Text(
              uiTextForLanguage(
                '${participant.rank} · ${participant.activeLimit} Pokémon attivi contemporaneamente',
                """${participant.rank} · ${participant.activeLimit} Pokémon active at the same time""",
              ),
            ),
            if (participant.personality.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                uiTextForLanguage(
                  'Personalità: ${participant.personality}',
                  """Personality: ${participant.personality}""",
                ),
              ),
            ],
            if (participant.tactics.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                uiTextForLanguage(
                  'Tattiche: ${participant.tactics}',
                  'Tactics: ${participant.tactics}',
                ),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InitiativeCard extends StatelessWidget {
  const _InitiativeCard({
    required this.round,
    required this.entries,
    required this.turnIndex,
    required this.onNextTurn,
    required this.onReroll,
    required this.onAdd,
    required this.onRemove,
  });

  final int round;
  final List<BattleInitiativeEntry> entries;
  final int turnIndex;
  final VoidCallback onNextTurn;
  final VoidCallback onReroll;
  final VoidCallback onAdd;
  final ValueChanged<BattleInitiativeEntry> onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    uiTextForLanguage(
                      'INIZIATIVA COMUNE',
                      """SHARED INITIATIVE""",
                    ),
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  onPressed: onReroll,
                  tooltip: uiTextForLanguage(
                    'Rilancia iniziativa',
                    """Reroll initiative""",
                  ),
                  icon: const Icon(Icons.casino_outlined),
                ),
                IconButton(
                  onPressed: onAdd,
                  tooltip: uiTextForLanguage(
                    'Aggiungi voce esterna',
                    """Add external entry""",
                  ),
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                ),
              ],
            ),
            if (entries.isEmpty)
              Text(
                uiTextForLanguage(
                  'Nessuna voce nell’iniziativa.',
                  """No initiative entries.""",
                ),
              )
            else
              for (var index = 0; index < entries.length; index++)
                ListTile(
                  dense: true,
                  selected: index == turnIndex,
                  leading: CircleAvatar(
                    child: Text('${entries[index].initiative}'),
                  ),
                  title: Text(entries[index].name),
                  subtitle: Text(
                    entries[index].isTrainerGroup
                        ? uiTextForLanguage(
                            'Pokémon controllato dal Master',
                            """Master-controlled Pokémon""",
                          )
                        : uiTextForLanguage(
                            'Partecipante esterno non gestito',
                            'External participant not managed by the app',
                          ),
                  ),
                  trailing: entries[index].isTrainerGroup
                      ? null
                      : IconButton(
                          onPressed: () => onRemove(entries[index]),
                          icon: const Icon(Icons.close),
                        ),
                ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: entries.isEmpty ? null : onNextTurn,
              icon: const Icon(Icons.skip_next),
              label: Text(
                uiTextForLanguage(
                  'PROSSIMO TURNO · ROUND $round',
                  """NEXT TURN · ROUND $round""",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamMemberCard extends StatelessWidget {
  const _TeamMemberCard({
    required this.state,
    required this.pokemon,
    required this.selected,
    required this.active,
    required this.activeLimit,
    required this.onFocus,
    required this.onToggleActive,
  });

  final MasterBattlePokemonState state;
  final Pokemon? pokemon;
  final bool selected;
  final bool active;
  final int activeLimit;
  final VoidCallback onFocus;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final name = pokemon == null
        ? '#${state.pokemon.pokemonId}'
        : pokemonFormDisplayName(pokemon!.name, state.pokemon.formName);
    return Card(
      color: selected ? colors.secondaryContainer : null,
      child: InkWell(
        onTap: onFocus,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              if (pokemon != null)
                PokemonAssetImage(
                  pokemon: pokemon!,
                  formName: state.pokemon.formName,
                  isShiny: state.pokemon.isShiny,
                  size: 54,
                )
              else
                const SizedBox(width: 54, height: 54),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        if (active)
                          Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text(
                              uiTextForLanguage('ATTIVO', """ACTIVE"""),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      context.uiText(
                        'Lv. ${state.pokemon.level} · PF ${state.currentHp}/${state.pokemon.maxHp}${state.isFainted ? ' · ESAUSTO' : ''}',
                        'Lv. ${state.pokemon.level} · HP ${state.currentHp}/${state.pokemon.maxHp}${state.isFainted ? ' · FAINTED' : ''}',
                      ),
                    ),
                    LinearProgressIndicator(
                      value: state.pokemon.maxHp <= 0
                          ? 0
                          : state.currentHp / state.pokemon.maxHp,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onToggleActive,
                tooltip: active
                    ? uiTextForLanguage(
                        'Rimuovi dagli attivi',
                        """Remove from active""",
                      )
                    : uiTextForLanguage(
                        'Rendi attivo (massimo $activeLimit)',
                        """Make active (maximum $activeLimit)""",
                      ),
                icon: Icon(
                  active ? Icons.visibility : Icons.visibility_outlined,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusedPokemonCard extends StatelessWidget {
  const _FocusedPokemonCard({
    required this.generated,
    required this.state,
    required this.active,
    required this.onMinusFive,
    required this.onMinusOne,
    required this.onPlusOne,
    required this.onPlusFive,
    required this.onEditHp,
    required this.onHeal,
    required this.onStatus,
    required this.onDetails,
    required this.onToggleActive,
  });

  final GeneratedPokemon generated;
  final MasterBattlePokemonState state;
  final bool active;
  final VoidCallback onMinusFive;
  final VoidCallback onMinusOne;
  final VoidCallback onPlusOne;
  final VoidCallback onPlusFive;
  final VoidCallback onEditHp;
  final VoidCallback onHeal;
  final VoidCallback onStatus;
  final VoidCallback onDetails;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final pokemon = generated.pokemon;
    final statuses = [
      if (state.nonVolatileStatus != null) state.nonVolatileStatus!,
      ...state.volatileStatuses,
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                PokemonAssetImage(
                  pokemon: generated.basePokemon,
                  formName: generated.formName,
                  isShiny: generated.isShiny,
                  size: 82,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pokemonFormDisplayName(
                          generated.basePokemon.name,
                          generated.formName,
                        ),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Lv. ${generated.level} · SR ${pokemon.sr} · ${generated.nature}',
                      ),
                      Text(
                        generated.ability ??
                            uiTextForLanguage(
                              'Nessuna abilità',
                              """No abilities""",
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDetails,
                  tooltip: uiTextForLanguage(
                    'Scheda completa',
                    """Full sheet""",
                  ),
                  icon: const Icon(Icons.open_in_new),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              context.uiText(
                'PF ${state.currentHp}/${state.pokemon.maxHp}',
                'HP ${state.currentHp}/${state.pokemon.maxHp}',
              ),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              minHeight: 10,
              value: state.pokemon.maxHp <= 0
                  ? 0
                  : state.currentHp / state.pokemon.maxHp,
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                OutlinedButton(onPressed: onMinusFive, child: Text('-5')),
                OutlinedButton(onPressed: onMinusOne, child: Text('-1')),
                OutlinedButton(
                  onPressed: onEditHp,
                  child: Text(uiTextForLanguage('MODIFICA', """EDIT""")),
                ),
                OutlinedButton(onPressed: onPlusOne, child: Text('+1')),
                OutlinedButton(onPressed: onPlusFive, child: Text('+5')),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final status in statuses) Chip(label: Text(status)),
                ActionChip(
                  avatar: const Icon(
                    Icons.health_and_safety_outlined,
                    size: 18,
                  ),
                  label: Text('STATUS'),
                  onPressed: onStatus,
                ),
                ActionChip(
                  avatar: const Icon(Icons.favorite, size: 18),
                  label: Text(uiTextForLanguage('RIPRISTINA', 'RESTORE')),
                  onPressed: onHeal,
                ),
                ActionChip(
                  avatar: Icon(
                    active ? Icons.visibility : Icons.visibility_outlined,
                    size: 18,
                  ),
                  label: Text(
                    active
                        ? uiTextForLanguage('ATTIVO', """ACTIVE""")
                        : uiTextForLanguage('RENDI ATTIVO', """MAKE ACTIVE"""),
                  ),
                  onPressed: onToggleActive,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NpcMoveCard extends StatelessWidget {
  const _NpcMoveCard({
    required this.reference,
    required this.move,
    required this.level,
    required this.remainingPp,
    required this.maxPp,
    required this.onUse,
    required this.onRestore,
  });

  final String reference;
  final MoveData? move;
  final int level;
  final int remainingPp;
  final int maxPp;
  final VoidCallback onUse;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final move = this.move;
    final damage = move?.damageForLevel(level)?.label;
    final save = move?.save;
    final details = <String?>[
      damage,
      move?.range == '-' ? null : move?.range,
      save == null ? null : uiTextForLanguage('TS $save', 'Save $save'),
    ].whereType<String>().join(' · ');
    return Card(
      child: ExpansionTile(
        title: Text(
          move?.name ?? reference,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (move != null) PokemonTypeBadge(type: move.type, height: 18),
              if (details.isNotEmpty) Text(details),
              if (maxPp > 0) Text('PP $remainingPp/$maxPp'),
            ],
          ),
        ),
        trailing: maxPp <= 0
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: remainingPp <= 0 ? null : onUse,
                    tooltip: uiTextForLanguage('Usa mossa', """Use move"""),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  IconButton(
                    onPressed: remainingPp >= maxPp ? null : onRestore,
                    tooltip: uiTextForLanguage('Ripristina PP', 'Restore PP'),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
        children: [
          if (move != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(move.description),
            ),
        ],
      ),
    );
  }
}

class _NpcHpInputDialog extends StatefulWidget {
  const _NpcHpInputDialog({required this.currentHp, required this.maxHp});

  final int currentHp;
  final int maxHp;

  @override
  State<_NpcHpInputDialog> createState() => _NpcHpInputDialogState();
}

class _NpcHpInputDialogState extends State<_NpcHpInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.currentHp}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(uiTextForLanguage('Modifica PF', """Edit HP""")),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(signed: true),
        decoration: InputDecoration(
          labelText: uiTextForLanguage('PF o modifica', """HP or adjustment"""),
          helperText: uiTextForLanguage(
            'Esempi: -12, +8 oppure 35. Attuali ${widget.currentHp}/${widget.maxHp}',
            'Examples: -12, +8 or 35. Current ${widget.currentHp}/${widget.maxHp}',
          ),
        ),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(uiTextForLanguage('Annulla', """Cancel""")),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(uiTextForLanguage('Conferma', """Confirm""")),
        ),
      ],
    );
  }
}

class _StatusDialog extends StatefulWidget {
  const _StatusDialog({required this.nonVolatile, required this.volatile});

  final String? nonVolatile;
  final Set<String> volatile;

  @override
  State<_StatusDialog> createState() => _StatusDialogState();
}

class _StatusDialogState extends State<_StatusDialog> {
  late String? _nonVolatile = widget.nonVolatile;
  late final Set<String> _volatile = {...widget.volatile};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(
        uiTextForLanguage('Status del Pokémon', """Pokémon Status"""),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String?>(
            initialValue: _nonVolatile,
            decoration: InputDecoration(
              labelText: uiTextForLanguage(
                'Status persistente',
                'Persistent condition',
              ),
              border: OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(uiTextForLanguage('Nessuno', """None""")),
              ),
              for (final status in _nonVolatileStatuses)
                DropdownMenuItem<String?>(value: status, child: Text(status)),
            ],
            onChanged: (value) => setState(() => _nonVolatile = value),
          ),
          const SizedBox(height: 12),
          Text(
            uiTextForLanguage('Status temporanei', 'Temporary conditions'),
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final status in _volatileStatuses)
                FilterChip(
                  label: Text(status),
                  selected: _volatile.contains(status),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _volatile.add(status);
                      } else {
                        _volatile.remove(status);
                      }
                    });
                  },
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(uiTextForLanguage('Annulla', """Cancel""")),
        ),
        TextButton(
          onPressed: () => Navigator.of(
            context,
          ).pop(const _StatusResult(nonVolatile: null, volatile: {})),
          child: Text('Pulisci'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(
            context,
          ).pop(_StatusResult(nonVolatile: _nonVolatile, volatile: _volatile)),
          child: Text(uiTextForLanguage('Conferma', """Confirm""")),
        ),
      ],
    );
  }
}

class _StatusResult {
  const _StatusResult({required this.nonVolatile, required this.volatile});

  final String? nonVolatile;
  final Set<String> volatile;
}

class _InitiativeInput {
  const _InitiativeInput({required this.name, required this.initiative});

  final String name;
  final int initiative;
}

const List<String> _nonVolatileStatuses = [
  'Asleep',
  'Burned',
  'Frozen',
  'Paralyzed',
  'Poisoned',
  'Badly Poisoned',
];

const List<String> _volatileStatuses = ['Confused', 'Flinched'];

enum _FightSummaryAction { export, share }

enum _FightSessionAction { reset, end }
