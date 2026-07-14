from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file_path = Path(path)
    text = file_path.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{path}: attesa 1 occorrenza, trovate {count}\n---\n{old}")
    file_path.write_text(text.replace(old, new, 1), encoding="utf-8")


battle = "lib/screens/battle/battle_screen.dart"
master = "lib/screens/battle/npc_battle_screen.dart"

replace_once(
    battle,
    "import '../../services/battle_quick_item_service.dart';\nimport '../../widgets/navigation/home_leading_button.dart';",
    "import '../../services/battle_quick_item_service.dart';\n"
    "import '../../services/battle_status_rules.dart';\n"
    "import '../../widgets/battle/battle_status_assistance_card.dart';\n"
    "import '../../widgets/navigation/home_leading_button.dart';",
)

replace_once(
    battle,
    "  final List<BattleInitiativeEntry> _initiativeEntries = [];\n\n"
    "  int? _activeSlotIndex;",
    "  final List<BattleInitiativeEntry> _initiativeEntries = [];\n\n"
    "  BattleStatusMoment _statusMoment = BattleStatusMoment.turnStart;\n"
    "  int? _activeSlotIndex;",
)

replace_once(
    battle,
    "    setState(() {\n"
    "      slotPp[key] = (current + delta).clamp(0, maxPp).toInt();\n"
    "    });\n"
    "    _scheduleSessionSave(data);",
    "    setState(() {\n"
    "      slotPp[key] = (current + delta).clamp(0, maxPp).toInt();\n"
    "      if (delta < 0) {\n"
    "        _statusMoment = BattleStatusMoment.actionAttempt;\n"
    "      }\n"
    "    });\n"
    "    _scheduleSessionSave(data);",
)

replace_once(
    battle,
    "    if (!mounted || result == null) return;\n\n"
    "    _volatileStatusesBySlot[slot.slotIndex] = result.volatileStatuses;",
    "    if (!mounted || result == null) return;\n\n"
    "    _statusMoment = BattleStatusMoment.turnStart;\n"
    "    _volatileStatusesBySlot[slot.slotIndex] = result.volatileStatuses;",
)

replace_once(
    battle,
    "  void _nextTurn(_BattleData data) {\n"
    "    setState(() {\n"
    "      if (_initiativeEntries.isEmpty) return;",
    "  void _nextTurn(_BattleData data) {\n"
    "    setState(() {\n"
    "      _statusMoment = BattleStatusMoment.turnStart;\n"
    "      if (_initiativeEntries.isEmpty) return;",
)

replace_once(
    battle,
    "  void _nextRound(_BattleData data) {\n"
    "    setState(() {\n"
    "      _round += 1;",
    "  void _nextRound(_BattleData data) {\n"
    "    setState(() {\n"
    "      _statusMoment = BattleStatusMoment.turnStart;\n"
    "      _round += 1;",
)

replace_once(
    battle,
    "                    setState(() {\n"
    "                      _activeSlotIndex = slotIndex;\n"
    "                      _message = null;\n"
    "                    });",
    "                    setState(() {\n"
    "                      _activeSlotIndex = slotIndex;\n"
    "                      _statusMoment = BattleStatusMoment.turnStart;\n"
    "                      _message = null;\n"
    "                    });",
)

replace_once(
    battle,
    "                _ActivePokemonCard(\n"
    "                  pokemon: pokemon,\n"
    "                  slot: activeSlot,\n"
    "                  heldItem: heldItem,\n"
    "                  displayName: _displayName(activeSlot, pokemon),\n"
    "                  level: _levelForSlot(activeSlot),\n"
    "                  currentHp: _currentHpFor(activeSlot, pokemon),\n"
    "                  maxHp: _maxHpFor(pokemon, activeSlot),\n"
    "                  nonVolatileStatus: _nonVolatileStatusFor(activeSlot),\n"
    "                  volatileStatuses: _volatileStatusesFor(activeSlot),\n"
    "                  message: _message,\n"
    "                  onMinusFive: () => _changeHp(data, activeSlot, -5),\n"
    "                  onMinusOne: () => _changeHp(data, activeSlot, -1),\n"
    "                  onPlusOne: () => _changeHp(data, activeSlot, 1),\n"
    "                  onPlusFive: () => _changeHp(data, activeSlot, 5),\n"
    "                  onEditHp: () => _editHp(data, activeSlot),\n"
    "                  onHeal: () => _healFull(data, activeSlot),\n"
    "                  onStatus: () => _openStatusPicker(data, activeSlot),\n"
    "                  onUseHeldBerry: heldItem?.type == 'berry'\n"
    "                      ? () => _useHeldBerry(data, activeSlot)\n"
    "                      : null,\n"
    "                  onOpenBag: () => _openQuickBag(data, activeSlot),\n"
    "                ),\n"
    "                const SizedBox(height: 12),\n"
    "                Text(\n"
    "                  'MOSSE DA COMBATTIMENTO',",
    "                _ActivePokemonCard(\n"
    "                  pokemon: pokemon,\n"
    "                  slot: activeSlot,\n"
    "                  heldItem: heldItem,\n"
    "                  displayName: _displayName(activeSlot, pokemon),\n"
    "                  level: _levelForSlot(activeSlot),\n"
    "                  currentHp: _currentHpFor(activeSlot, pokemon),\n"
    "                  maxHp: _maxHpFor(pokemon, activeSlot),\n"
    "                  nonVolatileStatus: _nonVolatileStatusFor(activeSlot),\n"
    "                  volatileStatuses: _volatileStatusesFor(activeSlot),\n"
    "                  message: _message,\n"
    "                  onMinusFive: () => _changeHp(data, activeSlot, -5),\n"
    "                  onMinusOne: () => _changeHp(data, activeSlot, -1),\n"
    "                  onPlusOne: () => _changeHp(data, activeSlot, 1),\n"
    "                  onPlusFive: () => _changeHp(data, activeSlot, 5),\n"
    "                  onEditHp: () => _editHp(data, activeSlot),\n"
    "                  onHeal: () => _healFull(data, activeSlot),\n"
    "                  onStatus: () => _openStatusPicker(data, activeSlot),\n"
    "                  onUseHeldBerry: heldItem?.type == 'berry'\n"
    "                      ? () => _useHeldBerry(data, activeSlot)\n"
    "                      : null,\n"
    "                  onOpenBag: () => _openQuickBag(data, activeSlot),\n"
    "                ),\n"
    "                const SizedBox(height: 12),\n"
    "                BattleStatusAssistanceCard(\n"
    "                  key: ValueKey('player-status-${activeSlot.slotIndex}'),\n"
    "                  pokemonName: _displayName(activeSlot, pokemon),\n"
    "                  nonVolatileStatus: _nonVolatileStatusFor(activeSlot),\n"
    "                  volatileStatuses: _volatileStatusesFor(activeSlot),\n"
    "                  selectedMoment: _statusMoment,\n"
    "                  onMomentChanged: (moment) {\n"
    "                    setState(() => _statusMoment = moment);\n"
    "                  },\n"
    "                ),\n"
    "                const SizedBox(height: 12),\n"
    "                Text(\n"
    "                  'MOSSE DA COMBATTIMENTO',",
)

replace_once(
    master,
    "import '../../services/master_battle_service.dart';\nimport '../../widgets/navigation/home_leading_button.dart';",
    "import '../../services/battle_status_rules.dart';\n"
    "import '../../services/master_battle_service.dart';\n"
    "import '../../widgets/battle/battle_status_assistance_card.dart';\n"
    "import '../../widgets/navigation/home_leading_button.dart';",
)

replace_once(
    master,
    "  bool _isWorking = false;\n"
    "  String? _message;",
    "  bool _isWorking = false;\n"
    "  String? _message;\n"
    "  BattleStatusMoment _statusMoment = BattleStatusMoment.turnStart;",
)

replace_once(
    master,
    "  Future<void> _selectTrainer(String trainerId) async {\n"
    "    final participant = _session.participants.firstWhere(",
    "  Future<void> _selectTrainer(String trainerId) async {\n"
    "    setState(() => _statusMoment = BattleStatusMoment.turnStart);\n"
    "    final participant = _session.participants.firstWhere(",
)

replace_once(
    master,
    "  Future<void> _focusPokemon(int slotIndex) async {\n"
    "    await _commit(_session.copyWith(focusedSlotIndex: slotIndex));\n"
    "  }",
    "  Future<void> _focusPokemon(int slotIndex) async {\n"
    "    setState(() => _statusMoment = BattleStatusMoment.turnStart);\n"
    "    await _commit(_session.copyWith(focusedSlotIndex: slotIndex));\n"
    "  }",
)

replace_once(
    master,
    "    if (result == null) return;\n"
    "    await _updateFocusedState(",
    "    if (result == null) return;\n"
    "    setState(() => _statusMoment = BattleStatusMoment.turnStart);\n"
    "    await _updateFocusedState(",
)

replace_once(
    master,
    "    final remaining = {...state.remainingPp};\n"
    "    remaining[key] = (current + delta).clamp(0, maxPp).toInt();\n"
    "    await _updateFocusedState(state.copyWith(remainingPp: remaining));",
    "    final remaining = {...state.remainingPp};\n"
    "    remaining[key] = (current + delta).clamp(0, maxPp).toInt();\n"
    "    if (delta < 0) {\n"
    "      setState(() => _statusMoment = BattleStatusMoment.actionAttempt);\n"
    "    }\n"
    "    await _updateFocusedState(state.copyWith(remainingPp: remaining));",
)

replace_once(
    master,
    "  Future<void> _nextTurn() async {\n"
    "    final entries = _session.initiativeEntries;",
    "  Future<void> _nextTurn() async {\n"
    "    setState(() => _statusMoment = BattleStatusMoment.turnStart);\n"
    "    final entries = _session.initiativeEntries;",
)

replace_once(
    master,
    "  Future<void> _nextRound() async {\n"
    "    await _commit(_session.copyWith(round: _session.round + 1, turnIndex: 0));\n"
    "  }",
    "  Future<void> _nextRound() async {\n"
    "    setState(() => _statusMoment = BattleStatusMoment.turnStart);\n"
    "    await _commit(_session.copyWith(round: _session.round + 1, turnIndex: 0));\n"
    "  }",
)

replace_once(
    master,
    "          _FocusedPokemonCard(\n"
    "            generated: generated,\n"
    "            state: state,\n"
    "            active: participant.activeSlotIndices.contains(state.slotIndex),\n"
    "            onMinusFive: () => _changeHp(-5),\n"
    "            onMinusOne: () => _changeHp(-1),\n"
    "            onPlusOne: () => _changeHp(1),\n"
    "            onPlusFive: () => _changeHp(5),\n"
    "            onEditHp: _editHp,\n"
    "            onHeal: _healFocused,\n"
    "            onStatus: _editStatuses,\n"
    "            onDetails: _openDetails,\n"
    "            onToggleActive: () => _toggleActive(state.slotIndex),\n"
    "          ),\n"
    "          const SizedBox(height: 12),\n"
    "          Text(\n"
    "            'MOSSE DA COMBATTIMENTO',",
    "          _FocusedPokemonCard(\n"
    "            generated: generated,\n"
    "            state: state,\n"
    "            active: participant.activeSlotIndices.contains(state.slotIndex),\n"
    "            onMinusFive: () => _changeHp(-5),\n"
    "            onMinusOne: () => _changeHp(-1),\n"
    "            onPlusOne: () => _changeHp(1),\n"
    "            onPlusFive: () => _changeHp(5),\n"
    "            onEditHp: _editHp,\n"
    "            onHeal: _healFocused,\n"
    "            onStatus: _editStatuses,\n"
    "            onDetails: _openDetails,\n"
    "            onToggleActive: () => _toggleActive(state.slotIndex),\n"
    "          ),\n"
    "          const SizedBox(height: 12),\n"
    "          BattleStatusAssistanceCard(\n"
    "            key: ValueKey(\n"
    "              'master-status-${participant.trainerId}-${state.slotIndex}',\n"
    "            ),\n"
    "            pokemonName: pokemonFormDisplayName(\n"
    "              generated.basePokemon.name,\n"
    "              generated.formName,\n"
    "            ),\n"
    "            nonVolatileStatus: state.nonVolatileStatus,\n"
    "            volatileStatuses: state.volatileStatuses,\n"
    "            selectedMoment: _statusMoment,\n"
    "            onMomentChanged: (moment) {\n"
    "              setState(() => _statusMoment = moment);\n"
    "            },\n"
    "          ),\n"
    "          const SizedBox(height: 12),\n"
    "          Text(\n"
    "            'MOSSE DA COMBATTIMENTO',",
)

print("Status assistance integrated into battle screens.")
