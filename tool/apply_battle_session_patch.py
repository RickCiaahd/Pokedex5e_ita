from pathlib import Path
import re


def replace_once(path: str, old: str, new: str) -> None:
    file_path = Path(path)
    text = file_path.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise RuntimeError(
            f"Expected one match in {path}, found {count}: {old[:120]!r}"
        )
    file_path.write_text(text.replace(old, new, 1), encoding="utf-8")


def replace_regex_once(path: str, pattern: str, replacement: str) -> None:
    file_path = Path(path)
    text = file_path.read_text(encoding="utf-8")
    updated, count = re.subn(pattern, replacement, text, count=1, flags=re.S)
    if count != 1:
        raise RuntimeError(f"Expected one regex match in {path}, found {count}: {pattern}")
    file_path.write_text(updated, encoding="utf-8")


battle = "lib/screens/battle/battle_screen.dart"

replace_once(battle, "import 'dart:math';", "import 'dart:async';\nimport 'dart:math';")
replace_once(
    battle,
    "import '../../models/bag_item.dart';\n",
    "import '../../models/bag_item.dart';\nimport '../../models/battle_session.dart';\n",
)
replace_once(
    battle,
    "import '../../repositories/bag_inventory_repository.dart';\n",
    "import '../../repositories/bag_inventory_repository.dart';\nimport '../../repositories/battle_session_repository.dart';\n",
)
replace_once(
    battle,
    "import '../../widgets/navigation/home_leading_button.dart';\n",
    "import '../../services/battle_quick_item_service.dart';\n"
    "import '../../widgets/navigation/home_leading_button.dart';\n",
)
replace_once(
    battle,
    "  final BagInventoryRepository _bagRepository = BagInventoryRepository();\n"
    "  final Random _random = Random();\n",
    "  final BagInventoryRepository _bagRepository = BagInventoryRepository();\n"
    "  final BattleSessionRepository _battleSessionRepository =\n"
    "      BattleSessionRepository();\n"
    "  final Random _random = Random();\n",
)
replace_once(
    battle,
    "  final List<_InitiativeEntry> _initiativeEntries = [];\n\n"
    "  int? _activeSlotIndex;\n"
    "  int _round = 1;\n"
    "  int _turnIndex = 0;\n"
    "  String? _message;\n",
    "  final List<BattleInitiativeEntry> _initiativeEntries = [];\n\n"
    "  int? _activeSlotIndex;\n"
    "  int _round = 1;\n"
    "  int _turnIndex = 0;\n"
    "  String? _message;\n"
    "  String? _restoredProfileId;\n",
)
replace_once(
    battle,
    "    return _BattleData(\n"
    "      profile: profile,\n"
    "      team: team,\n"
    "      pokemonById: pokemonById,\n"
    "      moves: moves,\n"
    "      items: items,\n"
    "      inventory: inventory,\n"
    "    );\n",
    "    final data = _BattleData(\n"
    "      profile: profile,\n"
    "      team: team,\n"
    "      pokemonById: pokemonById,\n"
    "      moves: moves,\n"
    "      items: items,\n"
    "      inventory: inventory,\n"
    "    );\n"
    "    await _restoreOrStartSession(data);\n"
    "    return data;\n",
)
replace_once(
    battle,
    "  TeamSlot? _activeSlotFor(_BattleData data) {\n",
    "  Future<void> _restoreOrStartSession(_BattleData data) async {\n"
    "    if (_restoredProfileId == data.profile.id) return;\n"
    "    _restoredProfileId = data.profile.id;\n\n"
    "    _remainingPpBySlot.clear();\n"
    "    _volatileStatusesBySlot.clear();\n"
    "    _initiativeEntries.clear();\n"
    "    _round = 1;\n"
    "    _turnIndex = 0;\n"
    "    _activeSlotIndex = null;\n\n"
    "    final session = await _battleSessionRepository.getSession(\n"
    "      data.profile.id,\n"
    "    );\n"
    "    if (session != null) {\n"
    "      _round = session.round;\n"
    "      _initiativeEntries.addAll(session.initiativeEntries);\n\n"
    "      for (final state in session.pokemonStates.values) {\n"
    "        TeamSlot? matchingSlot;\n"
    "        for (final slot in data.occupiedSlots) {\n"
    "          if (state.matches(slot)) {\n"
    "            matchingSlot = slot;\n"
    "            break;\n"
    "          }\n"
    "        }\n"
    "        if (matchingSlot == null) continue;\n"
    "        _remainingPpBySlot[matchingSlot.slotIndex] = {\n"
    "          ...state.remainingPp,\n"
    "        };\n"
    "        _volatileStatusesBySlot[matchingSlot.slotIndex] = {\n"
    "          ...state.volatileStatuses,\n"
    "        };\n"
    "      }\n\n"
    "      final savedActiveSlot = session.activeSlotIndex;\n"
    "      if (savedActiveSlot != null &&\n"
    "          data.occupiedSlots.any(\n"
    "            (slot) => slot.slotIndex == savedActiveSlot,\n"
    "          )) {\n"
    "        _activeSlotIndex = savedActiveSlot;\n"
    "      }\n"
    "      _turnIndex = _initiativeEntries.isEmpty\n"
    "          ? 0\n"
    "          : session.turnIndex\n"
    "                .clamp(0, _initiativeEntries.length - 1)\n"
    "                .toInt();\n"
    "    }\n\n"
    "    final activeSlot = _activeSlotFor(data);\n"
    "    if (activeSlot != null) {\n"
    "      _activeSlotIndex = activeSlot.slotIndex;\n"
    "      final pokemon = _pokemonForSlot(data, activeSlot);\n"
    "      if (pokemon != null) _ensureInitiative(data, activeSlot, pokemon);\n"
    "    }\n"
    "    await _saveSession(data);\n"
    "  }\n\n"
    "  Future<void> _saveSession(_BattleData data) async {\n"
    "    final states = <int, BattlePokemonState>{};\n"
    "    for (final slot in data.occupiedSlots) {\n"
    "      final pokemonId = slot.pokemonId;\n"
    "      if (pokemonId == null) continue;\n"
    "      states[slot.slotIndex] = BattlePokemonState(\n"
    "        slotIndex: slot.slotIndex,\n"
    "        pokemonId: pokemonId,\n"
    "        identityKey: BattlePokemonState.identityKeyFor(slot),\n"
    "        remainingPp: {\n"
    "          ...?_remainingPpBySlot[slot.slotIndex],\n"
    "        },\n"
    "        volatileStatuses: {\n"
    "          ...?_volatileStatusesBySlot[slot.slotIndex],\n"
    "        },\n"
    "      );\n"
    "    }\n\n"
    "    await _battleSessionRepository.saveSession(\n"
    "      BattleSession(\n"
    "        profileId: data.profile.id,\n"
    "        round: _round,\n"
    "        turnIndex: _turnIndex,\n"
    "        activeSlotIndex: _activeSlotIndex,\n"
    "        pokemonStates: states,\n"
    "        initiativeEntries: List<BattleInitiativeEntry>.from(\n"
    "          _initiativeEntries,\n"
    "        ),\n"
    "        updatedAt: DateTime.now(),\n"
    "      ),\n"
    "    );\n"
    "  }\n\n"
    "  void _scheduleSessionSave(_BattleData data) {\n"
    "    unawaited(_saveSession(data));\n"
    "  }\n\n"
    "  TeamSlot? _activeSlotFor(_BattleData data) {\n",
)
replace_once(
    battle,
    "  void _changePp(TeamSlot slot, String reference, MoveData? move, int delta) {\n",
    "  void _changePp(\n"
    "    _BattleData data,\n"
    "    TeamSlot slot,\n"
    "    String reference,\n"
    "    MoveData? move,\n"
    "    int delta,\n"
    "  ) {\n",
)
replace_once(
    battle,
    "    setState(() {\n"
    "      slotPp[key] = (current + delta).clamp(0, maxPp).toInt();\n"
    "    });\n"
    "  }\n\n"
    "  bool _hasNoPpLeft(\n",
    "    setState(() {\n"
    "      slotPp[key] = (current + delta).clamp(0, maxPp).toInt();\n"
    "    });\n"
    "    _scheduleSessionSave(data);\n"
    "  }\n\n"
    "  bool _hasNoPpLeft(\n",
)
replace_once(
    battle,
    "    await _teamRepository.updateSlot(\n"
    "      profileId: data.profile.id,\n"
    "      updatedSlot: slot.copyWith(\n"
    "        currentHp: _maxHpFor(pokemon, slot),\n"
    "        statusEffects: const [],\n"
    "      ),\n"
    "    );\n"
    "    await _reload(\n",
    "    await _teamRepository.updateSlot(\n"
    "      profileId: data.profile.id,\n"
    "      updatedSlot: slot.copyWith(\n"
    "        currentHp: _maxHpFor(pokemon, slot),\n"
    "        statusEffects: const [],\n"
    "      ),\n"
    "    );\n"
    "    await _saveSession(data);\n"
    "    await _reload(\n",
)
replace_once(
    battle,
    "    if (result != null) {\n"
    "      _volatileStatusesBySlot[slot.slotIndex] = result.volatileStatuses;\n"
    "    }\n"
    "    await _reload(\n"
    "      message:\n"
    "          result?.message ??\n"
    "          '${heldItem.name} è stata consumata. Applica manualmente il suo effetto se necessario.',\n"
    "    );\n",
    "    if (result != null) {\n"
    "      _volatileStatusesBySlot[slot.slotIndex] = result.volatileStatuses;\n"
    "    }\n"
    "    await _saveSession(data);\n"
    "    await _reload(\n"
    "      message:\n"
    "          result?.message ??\n"
    "          '${heldItem.name} è stata consumata. Applica manualmente il suo effetto se necessario.',\n"
    "    );\n",
)
replace_regex_once(
    battle,
    r"  Future<void> _openQuickBag\(_BattleData data, TeamSlot slot\) async \{.*?\n  \}\n\n  Future<void> _useBattleItem\(",
    "  Future<void> _openQuickBag(_BattleData data, TeamSlot slot) async {\n"
    "    final pokemon = _pokemonForSlot(data, slot);\n"
    "    if (pokemon == null) return;\n\n"
    "    try {\n"
    "      final inventory = await _bagRepository.getInventory(data.profile.id);\n"
    "      final items = BattleQuickItemService.resolve(\n"
    "        catalog: data.items,\n"
    "        inventory: inventory,\n"
    "      );\n"
    "      if (!mounted) return;\n\n"
    "      if (items.isEmpty) {\n"
    "        ScaffoldMessenger.of(context).showSnackBar(\n"
    "          const SnackBar(\n"
    "            content: Text(\n"
    "              'Non hai medicine, bacche utilizzabili o Poké Ball nello zaino.',\n"
    "            ),\n"
    "          ),\n"
    "        );\n"
    "        return;\n"
    "      }\n\n"
    "      final selected = await showModalBottomSheet<BattleQuickItem>(\n"
    "        context: context,\n"
    "        isScrollControlled: true,\n"
    "        useSafeArea: true,\n"
    "        showDragHandle: true,\n"
    "        builder: (_) => _QuickBagSheet(\n"
    "          items: items,\n"
    "          pokemonName: _displayName(slot, pokemon),\n"
    "          currentHp: _currentHpFor(slot, pokemon),\n"
    "          maxHp: _maxHpFor(pokemon, slot),\n"
    "          nonVolatileStatus: _nonVolatileStatusFor(slot),\n"
    "          volatileStatuses: _volatileStatusesFor(slot),\n"
    "        ),\n"
    "      );\n"
    "      if (!mounted || selected == null) return;\n\n"
    "      await _useBattleItem(data, slot, pokemon, selected);\n"
    "    } catch (error) {\n"
    "      if (!mounted) return;\n"
    "      ScaffoldMessenger.of(context).showSnackBar(\n"
    "        SnackBar(content: Text('Impossibile aprire lo zaino rapido: $error')),\n"
    "      );\n"
    "    }\n"
    "  }\n\n"
    "  Future<void> _useBattleItem(",
)
replace_once(
    battle,
    "    _OwnedBattleItem selected,\n",
    "    BattleQuickItem selected,\n",
)
replace_once(
    battle,
    "    if (item.type == 'pokeball') {\n",
    "    if (BattleQuickItemService.isPokeball(item)) {\n",
)
replace_once(
    battle,
    "    final isBerry = item.type == 'berry';\n",
    "    final isBerry = BattleQuickItemService.isBerry(item);\n",
)
replace_once(
    battle,
    "      _volatileStatusesBySlot[slot.slotIndex] = result.volatileStatuses;\n"
    "      await _reload(message: result.message);\n",
    "      _volatileStatusesBySlot[slot.slotIndex] = result.volatileStatuses;\n"
    "      await _saveSession(data);\n"
    "      await _reload(message: result.message);\n",
)
replace_once(
    battle,
    "    await _teamRepository.updateSlot(\n"
    "      profileId: data.profile.id,\n"
    "      updatedSlot: slot.copyWith(\n"
    "        statusEffects: result.nonVolatileStatus == null\n"
    "            ? const []\n"
    "            : [result.nonVolatileStatus!],\n"
    "      ),\n"
    "    );\n"
    "    await _reload();\n",
    "    await _teamRepository.updateSlot(\n"
    "      profileId: data.profile.id,\n"
    "      updatedSlot: slot.copyWith(\n"
    "        statusEffects: result.nonVolatileStatus == null\n"
    "            ? const []\n"
    "            : [result.nonVolatileStatus!],\n"
    "      ),\n"
    "    );\n"
    "    await _saveSession(data);\n"
    "    await _reload();\n",
)
replace_regex_once(
    battle,
    r"  void _rerollTrainerInitiative\(UserProfile profile\) \{.*?\n  \}\n\n  Future<void> _addInitiativeEntry\(\) async \{",
    "  void _rerollTrainerInitiative(_BattleData data) {\n"
    "    setState(() {\n"
    "      final index = _initiativeEntries.indexWhere(\n"
    "        (entry) => entry.isTrainerGroup,\n"
    "      );\n"
    "      final roll = _rollTrainerInitiative(data.profile);\n"
    "      if (index == -1) {\n"
    "        _initiativeEntries.add(\n"
    "          BattleInitiativeEntry(\n"
    "            id: 'trainer',\n"
    "            name: '${data.profile.name} + Pokémon',\n"
    "            initiative: roll,\n"
    "            isTrainerGroup: true,\n"
    "          ),\n"
    "        );\n"
    "      } else {\n"
    "        _initiativeEntries[index] = _initiativeEntries[index].copyWith(\n"
    "          initiative: roll,\n"
    "        );\n"
    "      }\n"
    "      _turnIndex = 0;\n"
    "      _sortInitiative();\n"
    "      _message = 'Iniziativa allenatore/Pokémon: $roll.';\n"
    "    });\n"
    "    _scheduleSessionSave(data);\n"
    "  }\n\n"
    "  Future<void> _addInitiativeEntry(_BattleData data) async {",
)
replace_once(
    battle,
    "        _InitiativeEntry(\n",
    "        BattleInitiativeEntry(\n",
)
replace_once(
    battle,
    "      _sortInitiative();\n"
    "    });\n"
    "  }\n\n"
    "  void _removeInitiativeEntry(_InitiativeEntry entry) {\n",
    "      _sortInitiative();\n"
    "    });\n"
    "    _scheduleSessionSave(data);\n"
    "  }\n\n"
    "  void _removeInitiativeEntry(\n"
    "    _BattleData data,\n"
    "    BattleInitiativeEntry entry,\n"
    "  ) {\n",
)
replace_once(
    battle,
    "      _initiativeEntries.removeWhere((candidate) => candidate.id == entry.id);\n"
    "      _sortInitiative();\n"
    "    });\n"
    "  }\n\n"
    "  void _nextTurn() {\n",
    "      _initiativeEntries.removeWhere((candidate) => candidate.id == entry.id);\n"
    "      _sortInitiative();\n"
    "    });\n"
    "    _scheduleSessionSave(data);\n"
    "  }\n\n"
    "  void _nextTurn(_BattleData data) {\n",
)
replace_once(
    battle,
    "    });\n"
    "  }\n\n"
    "  void _nextRound() {\n"
    "    setState(() {\n"
    "      _round += 1;\n"
    "      _turnIndex = 0;\n"
    "      _message = 'Round $_round iniziato.';\n"
    "    });\n"
    "  }\n\n"
    "  void _resetBattle() {\n"
    "    setState(() {\n"
    "      _round = 1;\n"
    "      _turnIndex = 0;\n"
    "      _remainingPpBySlot.clear();\n"
    "      _volatileStatusesBySlot.clear();\n"
    "      _message =\n"
    "          'Tracker combattimento azzerato. Gli status volatili sono stati rimossi.';\n"
    "    });\n"
    "  }\n",
    "    });\n"
    "    _scheduleSessionSave(data);\n"
    "  }\n\n"
    "  void _nextRound(_BattleData data) {\n"
    "    setState(() {\n"
    "      _round += 1;\n"
    "      _turnIndex = 0;\n"
    "      _message = 'Round $_round iniziato.';\n"
    "    });\n"
    "    _scheduleSessionSave(data);\n"
    "  }\n\n"
    "  Future<void> _endBattle(_BattleData data) async {\n"
    "    final confirmed = await showDialog<bool>(\n"
    "      context: context,\n"
    "      builder: (_) => AlertDialog(\n"
    "        title: const Text('Terminare la battaglia?'),\n"
    "        content: const Text(\n"
    "          'Round, iniziativa, PP temporanei e status volatili verranno rimossi. HP, status persistenti e oggetti consumati resteranno salvati.',\n"
    "        ),\n"
    "        actions: [\n"
    "          TextButton(\n"
    "            onPressed: () => Navigator.of(context).pop(false),\n"
    "            child: const Text('ANNULLA'),\n"
    "          ),\n"
    "          FilledButton(\n"
    "            onPressed: () => Navigator.of(context).pop(true),\n"
    "            child: const Text('TERMINA'),\n"
    "          ),\n"
    "        ],\n"
    "      ),\n"
    "    );\n"
    "    if (!mounted || confirmed != true) return;\n\n"
    "    await _battleSessionRepository.deleteSession(data.profile.id);\n"
    "    _remainingPpBySlot.clear();\n"
    "    _volatileStatusesBySlot.clear();\n"
    "    _initiativeEntries.clear();\n"
    "    if (!mounted) return;\n"
    "    Navigator.of(context).pop();\n"
    "  }\n",
)
replace_once(
    battle,
    "      appBar: AppBar(\n"
    "        leading: const HomeLeadingButton(),\n"
    "        title: const Text('Battle Companion'),\n"
    "        actions: [\n"
    "          IconButton(\n"
    "            tooltip: 'Reset combattimento',\n"
    "            onPressed: _resetBattle,\n"
    "            icon: const Icon(Icons.refresh),\n"
    "          ),\n"
    "        ],\n"
    "      ),\n",
    "      appBar: AppBar(\n"
    "        leading: const HomeLeadingButton(),\n"
    "        title: const Text('Battle Companion'),\n"
    "      ),\n",
)
replace_once(battle, "          _ensureInitiative(data, activeSlot, pokemon);\n\n", "")
replace_once(
    battle,
    "                  onNextRound: _nextRound,\n"
    "                  onReset: _resetBattle,\n",
    "                  onNextRound: () => _nextRound(data),\n"
    "                  onEnd: () => _endBattle(data),\n",
)
replace_once(
    battle,
    "                    setState(() {\n"
    "                      _activeSlotIndex = slotIndex;\n"
    "                      _message = null;\n"
    "                    });\n",
    "                    setState(() {\n"
    "                      _activeSlotIndex = slotIndex;\n"
    "                      _message = null;\n"
    "                    });\n"
    "                    _scheduleSessionSave(data);\n",
)
replace_once(
    battle,
    "                  onRollTrainer: () => _rerollTrainerInitiative(data.profile),\n"
    "                  onAddEntry: _addInitiativeEntry,\n"
    "                  onRemoveEntry: _removeInitiativeEntry,\n"
    "                  onNextTurn: _nextTurn,\n",
    "                  onRollTrainer: () => _rerollTrainerInitiative(data),\n"
    "                  onAddEntry: () => _addInitiativeEntry(data),\n"
    "                  onRemoveEntry: (entry) =>\n"
    "                      _removeInitiativeEntry(data, entry),\n"
    "                  onNextTurn: () => _nextTurn(data),\n",
)
replace_once(
    battle,
    "                    onUse: () => _changePp(\n"
    "                      activeSlot,\n",
    "                    onUse: () => _changePp(\n"
    "                      data,\n"
    "                      activeSlot,\n",
)
replace_once(
    battle,
    "                    onRestore: () => _changePp(\n"
    "                      activeSlot,\n",
    "                    onRestore: () => _changePp(\n"
    "                      data,\n"
    "                      activeSlot,\n",
)
replace_regex_once(
    battle,
    r"\nclass _OwnedBattleItem \{.*?\n\}\n\nclass _MedicineUseResult",
    "\nclass _MedicineUseResult",
)
replace_regex_once(
    battle,
    r"\nclass _InitiativeEntry \{.*?\n\}\n\nclass _InitiativeEntryInput",
    "\nclass _InitiativeEntryInput",
)
text = Path(battle).read_text(encoding="utf-8")
text = text.replace("_InitiativeEntry>", "BattleInitiativeEntry>")
text = text.replace("_InitiativeEntry entry", "BattleInitiativeEntry entry")
text = text.replace("List<_InitiativeEntry>", "List<BattleInitiativeEntry>")
text = text.replace("_OwnedBattleItem", "BattleQuickItem")
Path(battle).write_text(text, encoding="utf-8")
replace_regex_once(
    battle,
    r"  List<BattleQuickItem> get ownedQuickItems \{.*?\n  \}\n\n  BagItem\? heldItemFor",
    "  List<BattleQuickItem> get ownedQuickItems {\n"
    "    return BattleQuickItemService.resolve(\n"
    "      catalog: items,\n"
    "      inventory: inventory,\n"
    "    );\n"
    "  }\n\n"
    "  BagItem? heldItemFor",
)
replace_once(
    battle,
    "String _quickItemActionLabel(String type) {\n"
    "  return type == 'pokeball' ? 'LANCIA' : 'USA';\n"
    "}\n",
    "String _quickItemActionLabel(BagItem item) {\n"
    "  return BattleQuickItemService.isPokeball(item) ? 'LANCIA' : 'USA';\n"
    "}\n",
)
replace_once(
    battle,
    "  if (item.type == 'pokeball') {\n"
    "    return 'Lancia la Poké Ball. Dopo la risposta del Master verrà consumata.';\n"
    "  }\n",
    "  if (BattleQuickItemService.isPokeball(item)) {\n"
    "    return 'Lancia la Poké Ball. Dopo la risposta del Master verrà consumata.';\n"
    "  }\n",
)
replace_once(
    battle,
    "    required this.onReset,\n",
    "    required this.onEnd,\n",
)
replace_once(battle, "  final VoidCallback onReset;\n", "  final VoidCallback onEnd;\n")
replace_once(
    battle,
    "                    onPressed: onReset,\n"
    "                    icon: const Icon(Icons.refresh),\n"
    "                    label: const Text('RESET'),\n",
    "                    onPressed: onEnd,\n"
    "                    icon: const Icon(Icons.stop_circle_outlined),\n"
    "                    label: const Text('TERMINA'),\n",
)
replace_once(
    battle,
    "                ? 'Allenatore + Pokémon'\n"
    "                : 'Creatura / avversario',\n",
    "                ? 'Allenatore + Pokémon'\n"
    "                : 'Partecipante esterno',\n",
)
replace_once(
    battle,
    "            decoration: const InputDecoration(labelText: 'Nome creatura'),\n",
    "            decoration: const InputDecoration(labelText: 'Nome partecipante'),\n",
)
replace_once(
    battle,
    "                  trailing: Text(_quickItemActionLabel(entry.item.type)),\n",
    "                  trailing: Text(_quickItemActionLabel(entry.item)),\n",
)

home = "lib/screens/home/home_screen.dart"
replace_once(
    home,
    "import '../../repositories/pokemon_repository.dart';\n",
    "import '../../repositories/battle_session_repository.dart';\n"
    "import '../../repositories/pokemon_repository.dart';\n",
)
replace_once(
    home,
    "  final ProfileRepository _profileRepository = ProfileRepository();\n",
    "  final ProfileRepository _profileRepository = ProfileRepository();\n"
    "  final BattleSessionRepository _battleSessionRepository =\n"
    "      BattleSessionRepository();\n",
)
replace_once(
    home,
    "  bool _isLoading = true;\n"
    "  String? _errorMessage;\n",
    "  bool _isLoading = true;\n"
    "  bool _hasActiveBattle = false;\n"
    "  String? _errorMessage;\n",
)
replace_once(
    home,
    "      final entries = await _profileStorageService.loadPokedexEntries();\n",
    "      final entries = await _profileStorageService.loadPokedexEntries();\n"
    "      final hasActiveBattle = await _battleSessionRepository.hasSession(\n"
    "        profile.id,\n"
    "      );\n",
)
replace_once(
    home,
    "        _entries = entries;\n"
    "        _isLoading = false;\n",
    "        _entries = entries;\n"
    "        _hasActiveBattle = hasActiveBattle;\n"
    "        _isLoading = false;\n",
)
replace_once(
    home,
    "                title: 'Battle Companion',\n"
    "                subtitle: 'Traccia round, HP, status e PP durante il combattimento.',\n",
    "                title: _hasActiveBattle\n"
    "                    ? 'Riprendi battaglia'\n"
    "                    : 'Battle Companion',\n"
    "                subtitle: _hasActiveBattle\n"
    "                    ? 'Continua dal round, turno, PP e status salvati.'\n"
    "                    : 'Traccia round, HP, status e PP durante il combattimento.',\n",
)
