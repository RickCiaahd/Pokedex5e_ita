import 'package:flutter/material.dart';

import '../../models/bag_item.dart';
import '../../models/evolution_data.dart';
import '../../models/level_progression.dart';
import '../../models/move_data.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_nature.dart';
import '../../models/team_slot.dart';
import '../../repositories/ability_repository.dart';
import '../../repositories/bag_inventory_repository.dart';
import '../../repositories/evolution_repository.dart';
import '../../repositories/feat_repository.dart';
import '../../repositories/item_repository.dart';
import '../../repositories/move_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../services/evolution_service.dart';
import '../../widgets/pokemon/pokemon_asset_image.dart';
import 'evolution_selector_sheet.dart';
import 'pokemon_edit_screen.dart';

class PokemonDetailScreen extends StatefulWidget {
  const PokemonDetailScreen({
    super.key,
    required this.pokemon,
    this.teamSlot,
    this.allPokemon = const [],
    this.team = const [],
    this.onTeamSlotChanged,
  });

  final Pokemon pokemon;
  final TeamSlot? teamSlot;
  final List<Pokemon> allPokemon;
  final List<TeamSlot> team;
  final ValueChanged<TeamSlot>? onTeamSlotChanged;

  @override
  State<PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}

class _StatusEffectInfo {
  const _StatusEffectInfo({
    required this.name,
    required this.shortLabel,
    required this.description,
    required this.assetCandidates,
  });

  final String name;
  final String shortLabel;
  final String description;
  final List<String> assetCandidates;
}

const _statusEffectInfos = [
  _StatusEffectInfo(
    name: 'Asleep',
    shortLabel: 'SLP',
    description:
        'Incapacitated and restrained, and rolls all saving throws with disadvantage. Lasts three rounds. When subject to forced movement and at the end of each of its turns, roll a d20. On 11 or higher, the condition ends.',
    assetCandidates: [
      'assets/textures/gui/status/sleep_down.png',
      'assets/textures/gui/status/sleep_up.png',
    ],
  ),
  _StatusEffectInfo(
    name: 'Burned',
    shortLabel: 'BRN',
    description:
        'Rolls all damage rolls twice and takes the lower result. Until cured or the creature becomes unconscious, it takes damage equal to its proficiency bonus at the end of each of its turns. Fire-type pokemon are immune to this condition.',
    assetCandidates: [
      'assets/textures/gui/status/burn_down.png',
      'assets/textures/gui/status/burn_up.png',
    ],
  ),
  _StatusEffectInfo(
    name: 'Confused',
    shortLabel: 'CNF',
    description:
        "Cannot take reactions. Lasts three rounds. At the start of the creature's turn, roll a d8 to determine its behavior. On an 8, the condition ends.",
    assetCandidates: [
      'assets/textures/gui/status/confuse_down.png',
      'assets/textures/gui/status/confuse_up.png',
    ],
  ),
  _StatusEffectInfo(
    name: 'Flinched',
    shortLabel: 'FLN',
    description:
        'Disadvantage on all attack rolls, ability checks, and saving throws until the end of its next turn. This status is shown for reference and is not manually selectable.',
    assetCandidates: [],
  ),
  _StatusEffectInfo(
    name: 'Frozen',
    shortLabel: 'FRZ',
    description:
        'Incapacitated and restrained. Ends if the creature breaks free, takes fire-type damage, or is affected by a move that can inflict Burned. Ice-type pokemon are immune.',
    assetCandidates: [
      'assets/textures/gui/status/frozen_down.png',
      'assets/textures/gui/status/frozen_up.png',
    ],
  ),
  _StatusEffectInfo(
    name: 'Paralyzed',
    shortLabel: 'PAR',
    description:
        'Disadvantage on STR and DEX saving throws, and moves at half speed. At the start of its turn, roll a d4. On a 1, it is incapacitated and restrained until the start of its next turn. Electric-type pokemon are immune.',
    assetCandidates: [
      'assets/textures/gui/status/paralyze_down.png',
      'assets/textures/gui/status/paralyze_up.png',
    ],
  ),
  _StatusEffectInfo(
    name: 'Poisoned',
    shortLabel: 'PSN',
    description:
        'Disadvantage on all ability checks and attack rolls. Until cured or unconscious, it takes damage equal to its proficiency bonus at the end of each of its turns. Poison- and Steel-type pokemon are immune.',
    assetCandidates: [
      'assets/textures/gui/status/poisoned_down.png',
      'assets/textures/gui/status/poisoned_up.png',
    ],
  ),
];

Map<String, _StatusEffectInfo> get _statusEffectInfoByName => {
      for (final info in _statusEffectInfos) info.name: info,
    };

class _PokemonDetailScreenState extends State<PokemonDetailScreen> {
  final MoveRepository _moveRepository = MoveRepository();
  final AbilityRepository _abilityRepository = AbilityRepository();
  final EvolutionRepository _evolutionRepository = EvolutionRepository();
  final FeatRepository _featRepository = FeatRepository();
  final BagInventoryRepository _bagInventoryRepository =
      BagInventoryRepository();
  final ItemRepository _itemRepository = ItemRepository();
  final ProfileRepository _profileRepository = ProfileRepository();
  final EvolutionService _evolutionService = const EvolutionService();

  late Pokemon _pokemon;
  late List<TeamSlot> _team;
  TeamSlot? _teamSlot;
  Map<String, MoveData?> _moves = {};
  Map<String, String> _abilities = {};
  Map<String, String> _featDescriptions = {};
  Map<String, BagItem> _itemCatalog = {};
  Map<String, EvolutionData> _evolutions = {};
  List<EvolutionEligibility> _evolutionChoices = const [];
  bool _isLoading = true;
  String? _message;

  bool get _isPartyMode => _teamSlot != null;
  int get _experience => _teamSlot?.experience ?? 0;
  int get _level => _teamSlot == null
      ? _pokemon.minLevelFound
      : LevelProgression.levelFromExperience(_experience);
  int get _loyalty => (_teamSlot?.loyalty ?? 0).clamp(-3, 3).toInt();
  int get _savingThrowLoyaltyBonus => _loyalty.clamp(-1, 1).toInt();
  List<String> get _currentStatusEffects =>
      _teamSlot?.statusEffects ?? const [];

  int get _maxHp => _maxHpFor(_pokemon, _teamSlot);

  int get _currentHp {
    final savedHp = _teamSlot?.currentHp ?? 0;
    return savedHp.clamp(0, _maxHp).toInt();
  }

  int get _armorClass {
    final natureScores = PokemonNature.forName(
      _teamSlot?.nature ?? 'No Nature',
    );
    return _pokemon.armorClass + (natureScores['AC'] ?? 0);
  }

  @override
  void initState() {
    super.initState();
    _pokemon = widget.pokemon;
    _team = [...widget.team];
    _teamSlot = widget.teamSlot;
    _ensureSelectedMovesIsSaved();
    _loadData();
  }

  int _loyaltyHpBonus(int loyalty, int level) {
    if (loyalty == 2) return (level / 2).ceil();
    if (loyalty == 3) return level;
    return 0;
  }

  int _maxHpFor(Pokemon pokemon, TeamSlot? slot) {
    final level = slot == null
        ? pokemon.minLevelFound
        : LevelProgression.levelFromExperience(slot.experience);
    final safeLevel = level.clamp(1, LevelProgression.maxLevel).toInt();
    final minimumLevel = pokemon.minLevelFound <= 0 ? 1 : pokemon.minLevelFound;
    final levelsGained = (safeLevel - minimumLevel)
        .clamp(0, LevelProgression.maxLevel)
        .toInt();
    final hitDieAverage = ((pokemon.hitDice + 1) / 2).ceil();
    final attributes = _attributeScores(pokemon, slot);
    final constitutionModifier = _modifier(
      attributes['CON'] ?? pokemon.attributes.constitution,
    );
    final toughBonus = slot?.feats.contains('Tough') == true ? safeLevel * 2 : 0;
    final loyaltyBonus = _loyaltyHpBonus(slot?.loyalty ?? 0, safeLevel);
    final scaledHp = pokemon.hitPoints +
        (hitDieAverage * levelsGained) +
        (constitutionModifier * safeLevel) +
        toughBonus +
        loyaltyBonus;

    return scaledHp < 1 ? 1 : scaledHp;
  }

  void _replaceTeamSlot(TeamSlot updatedSlot) {
    final index = _team.indexWhere(
      (slot) => slot.slotIndex == updatedSlot.slotIndex,
    );
    if (index == -1) {
      _team = [..._team, updatedSlot];
      return;
    }

    _team = [..._team]..[index] = updatedSlot;
  }

  void _saveTeamSlot(TeamSlot updatedSlot) {
    setState(() {
      _teamSlot = updatedSlot;
      _replaceTeamSlot(updatedSlot);
    });
    widget.onTeamSlotChanged?.call(updatedSlot);
    _refreshEvolutionChoices();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    setState(() => _message = message);
  }

  Future<void> _loadData() async {
    final moveNames = <String>{
      ..._pokemon.moves.startingMoves,
      ..._pokemon.moves.levelMoves.values.expand((moves) => moves),
      ...?_teamSlot?.selectedMoves,
      ..._defaultSelectedMoves(_pokemon, _level),
      'Struggle',
    };

    final results = await Future.wait([
      _moveRepository.getMoves(moveNames),
      _abilityRepository.getAbilityDescriptions(),
      _evolutionRepository.getEvolutionData(),
      _featRepository.getFeatDescriptions(),
      _itemRepository.getWebItems(),
    ]);

    final evolutions = results[2] as Map<String, EvolutionData>;
    final items = results[4] as List<BagItem>;
    final evolutionChoices = await _buildEvolutionChoices(
      evolution: _evolutionForPokemon(_pokemon, evolutions),
      slot: _teamSlot,
    );

    if (!mounted) return;

    setState(() {
      _moves = results[0] as Map<String, MoveData?>;
      _abilities = results[1] as Map<String, String>;
      _evolutions = evolutions;
      _featDescriptions = results[3] as Map<String, String>;
      _itemCatalog = {for (final item in items) item.id: item};
      _evolutionChoices = evolutionChoices;
      _isLoading = false;
    });
  }

  Future<void> _refreshEvolutionChoices() async {
    final choices = await _buildEvolutionChoices(
      evolution: _evolutionForCurrentPokemon(),
      slot: _teamSlot,
    );
    if (!mounted) return;
    setState(() => _evolutionChoices = choices);
  }

  Future<List<EvolutionEligibility>> _buildEvolutionChoices({
    required EvolutionData? evolution,
    required TeamSlot? slot,
  }) async {
    if (!_isPartyMode || evolution == null || slot == null) return const [];

    final profile = await _profileRepository.getActiveProfile();
    final inventory = await _bagInventoryRepository.getInventory(profile.id);
    final itemCatalog = await _itemRepository.getWebItems();

    return _evolutionService.evaluateOptions(
      pokemon: _pokemon,
      slot: slot,
      evolution: evolution,
      inventory: inventory,
      itemCatalog: itemCatalog,
    );
  }

  List<String> _learnedMovesFor(Pokemon pokemon, int level) {
    final names = <String>[...pokemon.moves.startingMoves];
    final levelEntries = pokemon.moves.levelMoves.entries
        .where((entry) => entry.key <= level)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in levelEntries) {
      names.addAll(entry.value);
    }

    return names.toSet().toList();
  }

  List<String> _defaultSelectedMoves(Pokemon pokemon, int level) {
    return _learnedMovesFor(pokemon, level).take(4).toList();
  }

  List<String> _selectedMoves() {
    final slot = _teamSlot;
    if (slot == null || slot.selectedMoves.isEmpty) {
      return _defaultSelectedMoves(_pokemon, _level);
    }
    return slot.selectedMoves.take(4).toList();
  }

  void _ensureSelectedMovesIsSaved() {
    final slot = _teamSlot;
    if (slot == null || slot.selectedMoves.isNotEmpty) return;

    final updatedSlot = slot.copyWith(
      selectedMoves: _defaultSelectedMoves(_pokemon, _level),
    );
    _teamSlot = updatedSlot;
    _replaceTeamSlot(updatedSlot);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onTeamSlotChanged?.call(updatedSlot);
    });
  }

  Future<void> _editExperience() async {
    final slot = _teamSlot;
    if (slot == null) return;

    final oldMaxHp = _maxHp;
    final oldCurrentHp = _currentHp;
    final wasFullHp = oldCurrentHp >= oldMaxHp;

    final input = await showDialog<String>(
      context: context,
      builder: (_) => _ExperienceDialog(currentExperience: slot.experience),
    );
    if (!mounted || input == null) return;

    final oldLevel = LevelProgression.levelFromExperience(slot.experience);
    final updatedExperience = LevelProgression.applyExperienceInput(
      currentExperience: slot.experience,
      input: input,
    );
    final newLevel = LevelProgression.levelFromExperience(updatedExperience);
    var updatedSlot = slot.copyWith(experience: updatedExperience);

    final scaledMaxHp = _maxHpFor(_pokemon, updatedSlot);
    updatedSlot = updatedSlot.copyWith(
      currentHp: wasFullHp
          ? scaledMaxHp
          : oldCurrentHp.clamp(0, scaledMaxHp).toInt(),
    );

    if (newLevel > oldLevel) {
      updatedSlot = await _applyLevelUpMoves(updatedSlot, oldLevel, newLevel);
      if (!mounted) return;
      updatedSlot = await _applyLevelUpAbilityScores(
        updatedSlot,
        oldLevel,
        newLevel,
      );
      if (!mounted) return;
    }

    final finalMaxHp = _maxHpFor(_pokemon, updatedSlot);
    updatedSlot = updatedSlot.copyWith(
      currentHp: wasFullHp
          ? finalMaxHp
          : updatedSlot.currentHp.clamp(0, finalMaxHp).toInt(),
    );

    _saveTeamSlot(updatedSlot);
    await _loadData();
  }

  Future<void> _editHp() async {
    final slot = _teamSlot;
    if (slot == null) return;

    final input = await showDialog<String>(
      context: context,
      builder: (_) => _HpDialog(currentHp: _currentHp, maxHp: _maxHp),
    );
    if (!mounted || input == null) return;

    final updatedHp = _applyHpInput(
      currentHp: _currentHp,
      maxHp: _maxHp,
      input: input,
    );
    _saveTeamSlot(slot.copyWith(currentHp: updatedHp));
  }

  int _applyHpInput({
    required int currentHp,
    required int maxHp,
    required String input,
  }) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return currentHp;

    final value = int.tryParse(trimmed);
    if (value == null) return currentHp;

    if (trimmed.startsWith('+') || trimmed.startsWith('-')) {
      return (currentHp + value).clamp(0, maxHp).toInt();
    }

    return value.clamp(0, maxHp).toInt();
  }

  void _changeHp(int delta) {
    final slot = _teamSlot;
    if (slot == null) return;

    final updatedHp = (_currentHp + delta).clamp(0, _maxHp).toInt();
    _saveTeamSlot(slot.copyWith(currentHp: updatedHp));
  }

  void _changeLoyalty(int delta) {
    final slot = _teamSlot;
    if (slot == null) return;

    final oldMaxHp = _maxHp;
    final oldCurrentHp = _currentHp;
    final wasFullHp = oldCurrentHp >= oldMaxHp;
    final updatedLoyalty = (slot.loyalty + delta).clamp(-3, 3).toInt();
    final updatedSlot = slot.copyWith(loyalty: updatedLoyalty);
    final updatedMaxHp = _maxHpFor(_pokemon, updatedSlot);
    final updatedHp = wasFullHp
        ? updatedMaxHp
        : oldCurrentHp.clamp(0, updatedMaxHp).toInt();

    _saveTeamSlot(updatedSlot.copyWith(currentHp: updatedHp));
  }

  void _setStatusEffects(List<String> statuses) {
    final slot = _teamSlot;
    if (slot == null) return;
    _saveTeamSlot(slot.copyWith(statusEffects: statuses));
  }

  Future<void> _usePokemonCenter() async {
    final slot = _teamSlot;
    if (slot == null) return;

    final shouldHeal = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _PokemonCenterDialog(),
    );
    if (!mounted || shouldHeal != true) return;

    _saveTeamSlot(slot.copyWith(currentHp: _maxHp, statusEffects: const []));
    _showMessage('${_pokemon.name} è stato curato al Pokémon Center.');
  }

  String _heldItemDisplayLabel() {
    final heldItem = _teamSlot?.heldItem;
    if (heldItem == null || heldItem.trim().isEmpty) return 'NONE';

    return _itemByReference(heldItem)?.name.toUpperCase() ?? heldItem.toUpperCase();
  }

  BagItem? _itemByReference(String reference) {
    final trimmed = reference.trim();
    if (trimmed.isEmpty) return null;

    final direct = _itemCatalog[trimmed];
    if (direct != null) return direct;

    final target = _itemReferenceKey(trimmed);
    for (final item in _itemCatalog.values) {
      if (_itemReferenceKey(item.id) == target ||
          _itemReferenceKey(item.name) == target) {
        return item;
      }
    }

    return null;
  }

  Future<void> _changeHeldItemFromDetail() async {
    final slot = _teamSlot;
    if (slot == null) return;

    final profile = await _profileRepository.getActiveProfile();
    final inventory = await _bagInventoryRepository.getInventory(profile.id);
    final catalog = _itemCatalog.isEmpty
        ? {for (final item in await _itemRepository.getWebItems()) item.id: item}
        : _itemCatalog;

    final options = <_HeldItemInventoryOption>[];
    for (final entry in inventory) {
      final item = catalog[entry.itemId];
      if (item == null) continue;
      if (item.type != 'held-item' && item.type != 'berry') continue;
      options.add(_HeldItemInventoryOption(item: item, quantity: entry.quantity));
    }
    options.sort((a, b) => a.item.name.compareTo(b.item.name));

    final currentItem = slot.heldItem == null ? null : _itemByReference(slot.heldItem!);

    if (!mounted) return;

    final selection = await showModalBottomSheet<_HeldItemSelection>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _HeldItemPickerSheet(
        currentItem: currentItem,
        options: options,
      ),
    );

    if (!mounted || selection == null) return;

    if (selection.clear) {
      if (currentItem != null) {
        await _bagInventoryRepository.addItem(
          profileId: profile.id,
          itemId: currentItem.id,
        );
      }

      _saveTeamSlot(slot.copyWith(heldItem: null));
      _showMessage('${_pokemon.name} non tiene più strumenti.');
      await _loadData();
      return;
    }

    final selectedItem = selection.item;
    if (selectedItem == null) return;

    if (currentItem?.id == selectedItem.id) {
      _showMessage('${_pokemon.name} tiene già ${selectedItem.name}.');
      return;
    }

    final consumed = await _bagInventoryRepository.consumeItem(
      profileId: profile.id,
      itemId: selectedItem.id,
    );
    if (!consumed) {
      _showMessage('Non hai più ${selectedItem.name} nello zaino.');
      return;
    }

    if (currentItem != null) {
      await _bagInventoryRepository.addItem(
        profileId: profile.id,
        itemId: currentItem.id,
      );
    }

    _saveTeamSlot(slot.copyWith(heldItem: selectedItem.id));
    final replacementText =
        currentItem == null ? '' : ' ${currentItem.name} è tornato nello zaino.';
    _showMessage('${_pokemon.name} ora tiene ${selectedItem.name}.$replacementText');
    await _loadData();
  }

  Future<void> _pickStatusEffect() async {
    if (_teamSlot == null) return;

    final current = _currentStatusEffects;
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 12),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Text(
                'ADD STATUS EFFECT',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            for (final info in _statusEffectInfos.where(
              (info) => info.name != 'Flinched',
            ))
              CheckboxListTile(
                secondary: _StatusIcon(info: info, size: 28),
                title: Text(info.name.toUpperCase()),
                subtitle: Text(info.description),
                value: current.contains(info.name),
                onChanged: (_) => Navigator.of(context).pop(info.name),
              ),
            ListTile(
              leading: _StatusIcon(
                info: _statusEffectInfoByName['Flinched'],
                size: 28,
              ),
              title: const Text('FLINCHED'),
              subtitle: Text(_statusEffectInfoByName['Flinched']!.description),
            ),
            if (current.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('REMOVE ALL STATUS EFFECTS'),
                onTap: () => Navigator.of(context).pop('__clear__'),
              ),
          ],
        ),
      ),
    );

    if (!mounted || result == null) return;
    if (result == '__clear__') {
      _setStatusEffects([]);
      return;
    }

    final updated = [...current];
    if (updated.contains(result)) {
      updated.remove(result);
    } else {
      updated.add(result);
    }
    _setStatusEffects(updated);
  }

  Future<TeamSlot> _applyLevelUpMoves(
    TeamSlot slot,
    int oldLevel,
    int newLevel,
  ) async {
    var selectedMoves = slot.selectedMoves.isEmpty
        ? _defaultSelectedMoves(_pokemon, oldLevel)
        : slot.selectedMoves.take(4).toList();

    final learnedEntries = _pokemon.moves.levelMoves.entries
        .where((entry) => entry.key > oldLevel && entry.key <= newLevel)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in learnedEntries) {
      for (final move in entry.value) {
        if (selectedMoves.contains(move)) continue;
        if (selectedMoves.length < 4) {
          selectedMoves.add(move);
          continue;
        }

        final moveData = _moves[move] ?? await _moveRepository.getMove(move);
        if (!mounted) return slot.copyWith(selectedMoves: selectedMoves);

        final replacedMove = await _askMoveReplacement(
          move,
          selectedMoves,
          moveData,
        );
        if (replacedMove == null) continue;

        final replaceIndex = selectedMoves.indexOf(replacedMove);
        if (replaceIndex >= 0) selectedMoves[replaceIndex] = move;
      }
    }

    return slot.copyWith(selectedMoves: selectedMoves);
  }

  Future<TeamSlot> _applyLevelUpAbilityScores(
    TeamSlot slot,
    int oldLevel,
    int newLevel,
  ) async {
    if (_asiMilestoneCountForLevel(newLevel) <=
        _asiMilestoneCountForLevel(oldLevel)) {
      return slot;
    }

    var updatedSlot = slot;

    while (_availableAsiPointsForSlot(updatedSlot) > 0) {
      final remaining = _availableAsiPointsForSlot(updatedSlot);
      final attribute = await _pickAbilityScoreIncrease(updatedSlot, remaining);
      if (!mounted || attribute == null) break;

      final currentAttributes = _attributeScores(_pokemon, updatedSlot);
      if ((currentAttributes[attribute] ?? 0) >= 20) continue;

      final customScores = Map<String, int>.from(updatedSlot.customAbilityScores);
      customScores[attribute] = (customScores[attribute] ?? 0) + 1;
      updatedSlot = updatedSlot.copyWith(customAbilityScores: customScores);
    }

    return updatedSlot;
  }

  int _availableAsiPointsForSlot(TeamSlot slot) {
    final level = LevelProgression.levelFromExperience(slot.experience);
    final evolution = _evolutionForCurrentPokemon();
    final totalStages = (evolution?.totalStages ?? 1).clamp(1, 5).toInt();
    final pointsPerMilestone = (5 - totalStages).clamp(0, 4).toInt();
    final earnedPoints = _asiMilestoneCountForLevel(level) * pointsPerMilestone;
    final spentPoints = slot.customAbilityScores.values
        .where((value) => value > 0)
        .fold<int>(0, (sum, value) => sum + value);

    return (earnedPoints - spentPoints).clamp(0, 999).toInt();
  }

  int _asiMilestoneCountForLevel(int level) {
    if (level >= 20) return 5;
    if (level >= 16) return 4;
    if (level >= 12) return 3;
    if (level >= 8) return 2;
    if (level >= 4) return 1;
    return 0;
  }

  Future<String?> _pickAbilityScoreIncrease(
    TeamSlot slot,
    int remainingPoints,
  ) async {
    final attributes = _attributeScores(_pokemon, slot);
    const labels = ['STR', 'DEX', 'CON', 'INT', 'WIS', 'CHA'];

    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Aumento Ability Score'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Punti disponibili: $remainingPoints'),
              const SizedBox(height: 8),
              for (final label in labels)
                ListTile(
                  title: Text(label),
                  subtitle: Text(
                    '${attributes[label] ?? 0} → ${(attributes[label] ?? 0) + 1}',
                  ),
                  enabled: (attributes[label] ?? 0) < 20,
                  onTap: (attributes[label] ?? 0) >= 20
                      ? null
                      : () => Navigator.of(context).pop(label),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Più tardi'),
          ),
        ],
      ),
    );
  }

  Future<void> _distributePendingAsi() async {
    final slot = _teamSlot;
    if (slot == null) return;

    final oldMaxHp = _maxHp;
    final oldCurrentHp = _currentHp;
    final wasFullHp = oldCurrentHp >= oldMaxHp;
    var updatedSlot = slot;

    while (_availableAsiPointsForSlot(updatedSlot) > 0) {
      final remaining = _availableAsiPointsForSlot(updatedSlot);
      final attribute = await _pickAbilityScoreIncrease(updatedSlot, remaining);
      if (!mounted || attribute == null) break;

      final currentAttributes = _attributeScores(_pokemon, updatedSlot);
      if ((currentAttributes[attribute] ?? 0) >= 20) continue;

      final customScores = Map<String, int>.from(updatedSlot.customAbilityScores);
      customScores[attribute] = (customScores[attribute] ?? 0) + 1;
      updatedSlot = updatedSlot.copyWith(customAbilityScores: customScores);
    }

    final updatedMaxHp = _maxHpFor(_pokemon, updatedSlot);
    updatedSlot = updatedSlot.copyWith(
      currentHp: wasFullHp
          ? updatedMaxHp
          : oldCurrentHp.clamp(0, updatedMaxHp).toInt(),
    );

    _saveTeamSlot(updatedSlot);
    await _loadData();
  }

  Future<String?> _askMoveReplacement(
    String newMove,
    List<String> selectedMoves,
    MoveData? moveData,
  ) async {
    return showDialog<String?>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Vuoi imparare $newMove?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MoveCard(
                reference: newMove,
                move: moveData,
                stats: moveData == null ? null : _moveStats(moveData),
              ),
              const SizedBox(height: 8),
              const Text(
                'Il moveset è già pieno. Scegli una mossa da dimenticare.',
              ),
            ],
          ),
        ),
        actions: [
          for (final move in selectedMoves)
            TextButton(
              onPressed: () => Navigator.of(context).pop(move),
              child: Text('Dimentica ${_moveLabel(move)}'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Non imparare $newMove'),
          ),
        ],
      ),
    );
  }

  Pokemon? _pokemonById(int? pokemonId) {
    if (pokemonId == null) return null;
    for (final pokemon in widget.allPokemon) {
      if (pokemon.id == pokemonId) return pokemon;
    }
    return null;
  }

  Pokemon? _pokemonByName(String name) {
    final targetKey = _referenceKey(name);

    for (final pokemon in widget.allPokemon) {
      if (pokemon.name == name || _referenceKey(pokemon.name) == targetKey) {
        return pokemon;
      }
    }

    return null;
  }

  String _referenceKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('♀', '-f')
        .replaceAll('♂', '-m')
        .replaceAll(RegExp(r"[’']"), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  Future<void> _openEditScreen() async {
    final slot = _teamSlot;
    if (slot == null) return;

    final result = await Navigator.of(context).push<PokemonEditResult>(
      MaterialPageRoute(
        builder: (_) => PokemonEditScreen(
          pokemon: _pokemon,
          slot: slot,
          availableMoves: _learnedMovesFor(_pokemon, _level),
        ),
      ),
    );

    if (!mounted || result == null) return;

    _saveTeamSlot(result.slot);
    await _loadData();
  }

  EvolutionData? _evolutionForPokemon(
    Pokemon pokemon,
    Map<String, EvolutionData> evolutions,
  ) {
    return evolutions[pokemon.name] ?? evolutions[_referenceKey(pokemon.name)];
  }

  EvolutionData? _evolutionForCurrentPokemon() {
    return _evolutionForPokemon(_pokemon, _evolutions);
  }

  bool _canShowEvolutionButton() {
    return _isPartyMode && _evolutionChoices.isNotEmpty;
  }

  List<EvolutionEligibility> _availableEvolutionChoices() {
    return _evolutionChoices
        .where((choice) => choice.isAvailable && _pokemonByName(choice.option.toName) != null)
        .toList(growable: false);
  }

  String? _evolutionLabel() {
    if (!_canShowEvolutionButton()) return null;

    final availableChoices = _availableEvolutionChoices();
    if (availableChoices.isEmpty) return 'REQUISITI EVOLUZIONE';
    if (availableChoices.length == 1) return 'FAI EVOLVERE';
    return 'SCEGLI EVOLUZIONE';
  }

  Future<void> _evolveCurrentPokemon() async {
    final slot = _teamSlot;
    final evolution = _evolutionForCurrentPokemon();
    if (slot == null || evolution == null) return;

    final choices = await _buildEvolutionChoices(evolution: evolution, slot: slot);
    if (!mounted) return;

    setState(() => _evolutionChoices = choices);

    if (choices.isEmpty) {
      _showMessage('Nessuna evoluzione disponibile per ${_pokemon.name}.');
      return;
    }

    final selected = await showModalBottomSheet<EvolutionEligibility>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => EvolutionSelectorSheet(
        currentPokemon: _pokemon,
        choices: choices,
        pokemonByName: _pokemonByName,
      ),
    );

    if (!mounted || selected == null) return;

    await _evolveSlot(slot, selected);
  }

  Future<TeamSlot?> _evolveSlot(
    TeamSlot slot,
    EvolutionEligibility selected,
  ) async {
    if (!selected.isAvailable) return null;

    final evolvedPokemon = _pokemonByName(selected.option.toName);
    if (evolvedPokemon == null) {
      _showMessage(
        '${selected.option.toName} non è presente nel catalogo attuale.',
      );
      return null;
    }

    final profile = await _profileRepository.getActiveProfile();
    final requiredItemId = selected.requiredItemId;
    if (requiredItemId != null) {
      final consumed = await _bagInventoryRepository.consumeItem(
        profileId: profile.id,
        itemId: requiredItemId,
      );
      if (!consumed) {
        _showMessage('Oggetto evolutivo non disponibile nello zaino.');
        return null;
      }
    }

    final wasFullHp = _currentHp >= _maxHp;
    final oldName = _pokemon.name;
    final evolvedMaxHp = _maxHpFor(evolvedPokemon, slot);
    final updatedSlot = slot.copyWith(
      pokemonId: evolvedPokemon.id,
      currentHp: wasFullHp
          ? evolvedMaxHp
          : _currentHp.clamp(0, evolvedMaxHp).toInt(),
      selectedMoves: List<String>.from(slot.selectedMoves),
    );

    if (!mounted) return updatedSlot;

    setState(() {
      _pokemon = evolvedPokemon;
      _teamSlot = updatedSlot;
      _replaceTeamSlot(updatedSlot);
      _isLoading = true;
      _message = '$oldName si è evoluto in ${selected.option.toName}!';
    });

    widget.onTeamSlotChanged?.call(updatedSlot);
    await _loadData();

    return updatedSlot;
  }

  Future<void> _switchPartySlot(TeamSlot slot) async {
    final pokemon = _pokemonById(slot.pokemonId);
    if (pokemon == null) return;

    setState(() {
      _pokemon = pokemon;
      _teamSlot = slot;
      _isLoading = true;
      _message = null;
      _evolutionChoices = const [];
    });
    _ensureSelectedMovesIsSaved();
    await _loadData();
  }

  int _modifier(int score) => ((score - 10) / 2).floor();

  int _proficiency(int level) {
    if (level >= 17) return 6;
    if (level >= 13) return 5;
    if (level >= 9) return 4;
    if (level >= 5) return 3;
    return 2;
  }

  Map<String, int> _attributeScores(Pokemon pokemon, TeamSlot? slot) {
    final customScores = slot?.customAbilityScores ?? const <String, int>{};
    final natureScores = PokemonNature.forName(slot?.nature ?? 'No Nature');

    return {
      'STR': pokemon.attributes.strength +
          (customScores['STR'] ?? 0) +
          (natureScores['STR'] ?? 0),
      'DEX': pokemon.attributes.dexterity +
          (customScores['DEX'] ?? 0) +
          (natureScores['DEX'] ?? 0),
      'CON': pokemon.attributes.constitution +
          (customScores['CON'] ?? 0) +
          (natureScores['CON'] ?? 0),
      'INT': pokemon.attributes.intelligence +
          (customScores['INT'] ?? 0) +
          (natureScores['INT'] ?? 0),
      'WIS': pokemon.attributes.wisdom +
          (customScores['WIS'] ?? 0) +
          (natureScores['WIS'] ?? 0),
      'CHA': pokemon.attributes.charisma +
          (customScores['CHA'] ?? 0) +
          (natureScores['CHA'] ?? 0),
    };
  }

  int _bestMoveModifier(MoveData move) {
    final attributes = _attributeScores(_pokemon, _teamSlot);
    final modifiers = move.movePowers
        .where(attributes.containsKey)
        .map((power) => _modifier(attributes[power]!))
        .toList();

    if (modifiers.isEmpty) return 0;
    modifiers.sort();
    return modifiers.last;
  }

  String _moveStats(MoveData move) {
    final parts = <String>[];
    final moveModifier = _bestMoveModifier(move);
    final proficiency = _proficiency(_level);

    if (move.isAttack) {
      final attackBonus = moveModifier + proficiency;
      parts.add('AB: ${attackBonus >= 0 ? '+' : ''}$attackBonus');
    }
    if (move.save != null) {
      parts.add('DC: ${8 + proficiency + moveModifier}');
    }

    final damage = move.damageForLevel(_level);
    if (damage != null) parts.add(damage.label);
    if (move.range != '-') parts.add(move.range);
    if (move.duration != '-') parts.add(move.duration);

    return parts.join('  ||  ');
  }

  String _moveLabel(String reference) {
    return _moves[reference]?.name ?? reference;
  }

  @override
  Widget build(BuildContext context) {
    final pokemon = _pokemon;
    final attributes = _attributeScores(pokemon, _teamSlot);
    final evolutionLabel = _evolutionLabel();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_teamSlot?.nickname ?? pokemon.name),
          actions: [
            if (_isPartyMode)
              IconButton(
                tooltip: 'Modifica',
                onPressed: _openEditScreen,
                icon: const Icon(Icons.edit),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _Header(
                          pokemon: pokemon,
                          slot: _teamSlot,
                          level: _level,
                          armorClass: _armorClass,
                          experience: _experience,
                          currentHp: _currentHp,
                          maxHp: _maxHp,
                          loyalty: _loyalty,
                          isPartyMode: _isPartyMode,
                          attributes: attributes,
                          modifierBuilder: _modifier,
                          proficiency: _proficiency(_level),
                          savingThrowLoyaltyBonus: _savingThrowLoyaltyBonus,
                          statusEffects: _currentStatusEffects,
                          message: _message,
                          heldItemLabel: _heldItemDisplayLabel(),
                          onEditExperience: _editExperience,
                          onEditHp: _editHp,
                          onDecreaseHp: () => _changeHp(-1),
                          onIncreaseHp: () => _changeHp(1),
                          onDecreaseLoyalty: () => _changeLoyalty(-1),
                          onIncreaseLoyalty: () => _changeLoyalty(1),
                          onPokemonCenter: _usePokemonCenter,
                          onAddStatusEffect: _pickStatusEffect,
                          onEditHeldItem: _changeHeldItemFromDetail,
                          evolutionLabel: evolutionLabel,
                          onEvolve: _evolveCurrentPokemon,
                        ),
                        const TabBar(
                          tabs: [
                            Tab(text: 'MOSSE'),
                            Tab(text: 'FEATURES'),
                            Tab(text: 'TRAITS'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _MovesView(
                                selectedMoves: _selectedMoves(),
                                moves: _moves,
                                moveStatsBuilder: _moveStats,
                              ),
                              _FeaturesView(
                                pokemon: pokemon,
                                slot: _teamSlot,
                                abilityDescriptions: _abilities,
                                featDescriptions: _featDescriptions,
                              ),
                              _TraitsView(
                                pokemon: pokemon,
                                slot: _teamSlot,
                                attributes: attributes,
                                modifierBuilder: _modifier,
                                proficiency: _proficiency(_level),
                                availableAsiPoints: _teamSlot == null
                                    ? 0
                                    : _availableAsiPointsForSlot(_teamSlot!),
                                onDistributeAsi: _distributePendingAsi,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isPartyMode)
                    _PartySwitcher(
                      team: _team,
                      currentSlotIndex: _teamSlot!.slotIndex,
                      pokemonById: _pokemonById,
                      onSelect: _switchPartySlot,
                    ),
                ],
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.pokemon,
    required this.slot,
    required this.level,
    required this.armorClass,
    required this.experience,
    required this.currentHp,
    required this.maxHp,
    required this.loyalty,
    required this.isPartyMode,
    required this.attributes,
    required this.modifierBuilder,
    required this.proficiency,
    required this.savingThrowLoyaltyBonus,
    required this.statusEffects,
    required this.message,
    required this.heldItemLabel,
    required this.onEditExperience,
    required this.onEditHp,
    required this.onDecreaseHp,
    required this.onIncreaseHp,
    required this.onDecreaseLoyalty,
    required this.onIncreaseLoyalty,
    required this.onPokemonCenter,
    required this.onAddStatusEffect,
    required this.onEditHeldItem,
    required this.evolutionLabel,
    required this.onEvolve,
  });

  final Pokemon pokemon;
  final TeamSlot? slot;
  final int level;
  final int armorClass;
  final int experience;
  final int currentHp;
  final int maxHp;
  final int loyalty;
  final bool isPartyMode;
  final Map<String, int> attributes;
  final int Function(int score) modifierBuilder;
  final int proficiency;
  final int savingThrowLoyaltyBonus;
  final List<String> statusEffects;
  final String? message;
  final String heldItemLabel;
  final VoidCallback onEditExperience;
  final VoidCallback onEditHp;
  final VoidCallback onDecreaseHp;
  final VoidCallback onIncreaseHp;
  final VoidCallback onDecreaseLoyalty;
  final VoidCallback onIncreaseLoyalty;
  final VoidCallback onPokemonCenter;
  final VoidCallback onAddStatusEffect;
  final VoidCallback onEditHeldItem;
  final String? evolutionLabel;
  final VoidCallback onEvolve;

  @override
  Widget build(BuildContext context) {
    final number = '#${pokemon.id.toString().padLeft(3, '0')}';
    final nextThreshold = LevelProgression.nextThresholdForLevel(level);
    final currentThreshold = LevelProgression.thresholdForLevel(level);
    final range = nextThreshold - currentThreshold;
    final expProgress = range <= 0
        ? 1.0
        : ((experience - currentThreshold) / range).clamp(0.0, 1.0).toDouble();
    final hpProgress = maxHp <= 0
        ? 0.0
        : (currentHp / maxHp).clamp(0.0, 1.0).toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PokemonCenterButton(onTap: isPartyMode ? onPokemonCenter : null),
              const SizedBox(width: 6),
              Card(
                child: SizedBox(
                  width: 132,
                  height: 142,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      children: [
                        Expanded(
                          child: PokemonAssetImage(
                            pokemon: pokemon,
                            useLargeArtwork: true,
                            size: 112,
                          ),
                        ),
                        Text(
                          '$number ${pokemon.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      pokemon.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final type in pokemon.types)
                          PokemonTypeBadge(type: type, height: 20),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _LoyaltyRow(
                      loyalty: loyalty,
                      onDecrease: loyalty <= -3 ? null : onDecreaseLoyalty,
                      onIncrease: loyalty >= 3 ? null : onIncreaseLoyalty,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(child: _MetricBox(label: 'Lv.', value: '$level')),
                        const SizedBox(width: 6),
                        Expanded(child: _MetricBox(label: 'AC:', value: '$armorClass')),
                      ],
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: isPartyMode ? onEditExperience : null,
                      borderRadius: BorderRadius.circular(8),
                      child: _ProgressPanel(
                        label: 'EXP: $experience/$nextThreshold',
                        value: expProgress,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _FightStatsGrid(
            attributes: attributes,
            modifierBuilder: modifierBuilder,
          ),
          const SizedBox(height: 4),
          _SavingThrowsRow(
            attributes: attributes,
            savingThrows: pokemon.savingThrows,
            modifierBuilder: modifierBuilder,
            proficiency: proficiency,
            loyaltyBonus: savingThrowLoyaltyBonus,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _StatusPanelButton(
                  statuses: statusEffects,
                  onTap: isPartyMode ? onAddStatusEffect : null,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: InkWell(
                  onTap: isPartyMode ? onEditHeldItem : null,
                  borderRadius: BorderRadius.circular(8),
                  child: _PanelButton(label: 'ITEM: $heldItemLabel'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _FightIconButton(icon: Icons.remove, onPressed: onDecreaseHp),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: isPartyMode ? onEditHp : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Text(
                          'HP: $currentHp/$maxHp',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
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
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _FightIconButton(icon: Icons.add, onPressed: onIncreaseHp),
            ],
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            _InlineDetailMessage(message: message!),
          ],
          if (isPartyMode && evolutionLabel != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onEvolve,
                child: Text(evolutionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Color _hpProgressColor(double value) {
  if (value <= 0.25) return Colors.red;
  if (value <= 0.5) return Colors.amber;
  return Colors.green;
}

class _InlineDetailMessage extends StatelessWidget {
  const _InlineDetailMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colorScheme.onSecondaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _HeldItemInventoryOption {
  const _HeldItemInventoryOption({required this.item, required this.quantity});

  final BagItem item;
  final int quantity;
}

class _HeldItemSelection {
  const _HeldItemSelection._({this.item, this.clear = false});

  const _HeldItemSelection.item(BagItem item) : this._(item: item);
  const _HeldItemSelection.clear() : this._(clear: true);

  final BagItem? item;
  final bool clear;
}

class _HeldItemPickerSheet extends StatelessWidget {
  const _HeldItemPickerSheet({
    required this.currentItem,
    required this.options,
  });

  final BagItem? currentItem;
  final List<_HeldItemInventoryOption> options;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Strumento tenuto',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 4),
            const Text('Scegli solo tra gli oggetti presenti nello zaino.'),
            if (currentItem != null) ...[
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.remove_circle_outline),
                  title: Text('Togli ${currentItem!.name}'),
                  subtitle: const Text('Lo strumento torna nello zaino.'),
                  onTap: () =>
                      Navigator.of(context).pop(const _HeldItemSelection.clear()),
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (options.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Non hai strumenti tenuti o bacche nello zaino.'),
              )
            else
              for (final option in options)
                Card(
                  child: ListTile(
                    leading: Icon(
                      option.item.type == 'berry'
                          ? Icons.eco_outlined
                          : Icons.inventory_2_outlined,
                    ),
                    title: Text(option.item.name),
                    subtitle: Text(
                      '${_detailItemTypeLabel(option.item.type)} • x${option.quantity}',
                    ),
                    onTap: () => Navigator.of(context)
                        .pop(_HeldItemSelection.item(option.item)),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

String _detailItemTypeLabel(String type) {
  switch (type) {
    case 'berry':
      return 'Bacca';
    case 'held-item':
      return 'Oggetto tenuto';
    default:
      return type;
  }
}

String _itemReferenceKey(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r"[’']"), '')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

class _PokemonCenterButton extends StatelessWidget {
  const _PokemonCenterButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 46,
        height: 142,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 32,
              child: Center(
                child: Icon(Icons.local_hospital, color: colorScheme.primary),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      'POKÉMON CENTER',
                      maxLines: 1,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 9.5,
                      ),
                    ),
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

class _PokemonCenterDialog extends StatelessWidget {
  const _PokemonCenterDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pokémon Center'),
      content: const Text('Vuoi curare completamente questo Pokémon?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('NO'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('SÌ'),
        ),
      ],
    );
  }
}

class _LoyaltyRow extends StatelessWidget {
  const _LoyaltyRow({
    required this.loyalty,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int loyalty;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FightIconButton(icon: Icons.remove, onPressed: onDecrease),
        const SizedBox(width: 6),
        Expanded(
          child: _PanelButton(label: 'LEALTÀ: ${_signed(loyalty)}'),
        ),
        const SizedBox(width: 6),
        _FightIconButton(icon: Icons.add, onPressed: onIncrease),
      ],
    );
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _PanelButton(label: '$label $value');
  }
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 46,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.primary, width: 1.5),
      ),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          LinearProgressIndicator(value: value, minHeight: 6),
        ],
      ),
    );
  }
}

class _PanelButton extends StatelessWidget {
  const _PanelButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 36,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: label.startsWith('+')
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _FightIconButton extends StatelessWidget {
  const _FightIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: IconButton.filled(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(icon, size: 26),
      ),
    );
  }
}

class _FightStatsGrid extends StatelessWidget {
  const _FightStatsGrid({
    required this.attributes,
    required this.modifierBuilder,
  });

  final Map<String, int> attributes;
  final int Function(int score) modifierBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        return GridView.count(
          crossAxisCount: compact ? 3 : 6,
          childAspectRatio: compact ? 1.85 : 1.18,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final entry in attributes.entries)
              _FightStatBox(
                label: entry.key,
                score: entry.value,
                modifier: modifierBuilder(entry.value),
              ),
          ],
        );
      },
    );
  }
}

class _FightStatBox extends StatelessWidget {
  const _FightStatBox({
    required this.label,
    required this.score,
    required this.modifier,
  });

  final String label;
  final int score;
  final int modifier;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(color: muted, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 5),
              Text(
                '$score',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          Text(
            _signed(modifier),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
          ),
        ],
      ),
    );
  }
}

class _SavingThrowsRow extends StatelessWidget {
  const _SavingThrowsRow({
    required this.attributes,
    required this.savingThrows,
    required this.modifierBuilder,
    required this.proficiency,
    required this.loyaltyBonus,
  });

  final Map<String, int> attributes;
  final List<String> savingThrows;
  final int Function(int score) modifierBuilder;
  final int proficiency;
  final int loyaltyBonus;

  @override
  Widget build(BuildContext context) {
    final labels = attributes.keys.toList();

    return Column(
      children: [
        Text(
          'SAVING THROWS',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            for (final label in labels) ...[
              Expanded(
                child: _SaveBox(
                  value: _savingThrowValue(label),
                  proficient: _isSavingThrowProficient(label),
                ),
              ),
              if (label != labels.last) const SizedBox(width: 4),
            ],
          ],
        ),
      ],
    );
  }

  int _savingThrowValue(String label) {
    final base = modifierBuilder(attributes[label] ?? 10) + loyaltyBonus;
    return _isSavingThrowProficient(label) ? base + proficiency : base;
  }

  bool _isSavingThrowProficient(String label) {
    return savingThrows.any((save) => save.toUpperCase().contains(label));
  }
}

class _SaveBox extends StatelessWidget {
  const _SaveBox({required this.value, required this.proficient});

  final int value;
  final bool proficient;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: proficient
            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.72)
            : Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Text(
        _signed(value),
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _StatusPanelButton extends StatelessWidget {
  const _StatusPanelButton({required this.statuses, required this.onTap});

  final List<String> statuses;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 42,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: statuses.isEmpty
            ? Text(
                '+ ADD STATUS EFFECTS',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final status in statuses.take(5)) ...[
                    _StatusIcon(info: _statusEffectInfoByName[status], size: 32),
                    const SizedBox(width: 4),
                  ],
                  if (statuses.length > 5)
                    Text(
                      '+${statuses.length - 5}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                ],
              ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.info, required this.size});

  final _StatusEffectInfo? info;
  final double size;

  @override
  Widget build(BuildContext context) {
    final statusInfo = info;
    if (statusInfo == null) return const SizedBox.shrink();

    return _FallbackAssetIcon(
      paths: statusInfo.assetCandidates,
      fallbackLabel: statusInfo.shortLabel,
      size: size,
    );
  }
}

class _FallbackAssetIcon extends StatelessWidget {
  const _FallbackAssetIcon({
    required this.paths,
    required this.fallbackLabel,
    required this.size,
    this.index = 0,
  });

  final List<String> paths;
  final String fallbackLabel;
  final double size;
  final int index;

  @override
  Widget build(BuildContext context) {
    if (index >= paths.length) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          fallbackLabel,
          style: TextStyle(fontSize: size * 0.32, fontWeight: FontWeight.w900),
        ),
      );
    }

    return Image.asset(
      paths[index],
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _FallbackAssetIcon(
        paths: paths,
        fallbackLabel: fallbackLabel,
        size: size,
        index: index + 1,
      ),
    );
  }
}

String _signed(int value) => value >= 0 ? '+$value' : '$value';

class _MovesView extends StatelessWidget {
  const _MovesView({
    required this.selectedMoves,
    required this.moves,
    required this.moveStatsBuilder,
  });

  final List<String> selectedMoves;
  final Map<String, MoveData?> moves;
  final String Function(MoveData move) moveStatsBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _MoveSection(
          title: 'Moveset',
          names: [...selectedMoves, 'Struggle'],
          moves: moves,
          moveStatsBuilder: moveStatsBuilder,
        ),
      ],
    );
  }
}

class _MoveSection extends StatelessWidget {
  const _MoveSection({
    required this.title,
    required this.names,
    required this.moves,
    required this.moveStatsBuilder,
  });

  final String title;
  final List<String> names;
  final Map<String, MoveData?> moves;
  final String Function(MoveData move) moveStatsBuilder;

  @override
  Widget build(BuildContext context) {
    if (names.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
          child: Text(title.toUpperCase()),
        ),
        for (final name in names)
          _MoveCard(
            reference: name,
            move: moves[name],
            stats: moves[name] == null ? null : moveStatsBuilder(moves[name]!),
          ),
      ],
    );
  }
}

class _MoveCard extends StatelessWidget {
  const _MoveCard({
    required this.reference,
    required this.move,
    required this.stats,
  });

  final String reference;
  final MoveData? move;
  final String? stats;

  @override
  Widget build(BuildContext context) {
    final move = this.move;
    final name = move?.name ?? reference;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.radio_button_unchecked, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name.toUpperCase(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (move != null) Text('PP ${move.pp}'),
              ],
            ),
            const SizedBox(height: 8),
            if (move == null)
              const Text('Dettagli mossa non disponibili.')
            else ...[
              if (stats != null && stats!.isNotEmpty) Text(stats!),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  PokemonTypeBadge(type: move.type, height: 24),
                  Chip(label: Text(move.moveTime)),
                ],
              ),
              if (move.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(move.description),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _FeaturesView extends StatelessWidget {
  const _FeaturesView({
    required this.pokemon,
    required this.slot,
    required this.abilityDescriptions,
    required this.featDescriptions,
  });

  final Pokemon pokemon;
  final TeamSlot? slot;
  final Map<String, String> abilityDescriptions;
  final Map<String, String> featDescriptions;

  @override
  Widget build(BuildContext context) {
    final feats = slot?.feats ?? const <String>[];
    final abilities = slot?.abilities.isNotEmpty == true
        ? slot!.abilities
        : [
            ...pokemon.abilities,
            if (pokemon.hiddenAbility != null && feats.contains('Hidden Ability'))
              pokemon.hiddenAbility!,
          ];

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final ability in abilities)
          _InfoCard(
            title: ability,
            child: Text(
              abilityDescriptions[ability] ?? 'Descrizione non disponibile.',
            ),
          ),
        for (final feat in feats)
          _InfoCard(
            title: feat,
            child: Text(
              featDescriptions[feat] ?? 'Descrizione non disponibile.',
            ),
          ),
        if (abilities.isEmpty && feats.isEmpty)
          const _InfoCard(
            title: 'Features',
            child: Text('Nessuna feature disponibile.'),
          ),
      ],
    );
  }
}

class _TraitsView extends StatelessWidget {
  const _TraitsView({
    required this.pokemon,
    required this.slot,
    required this.attributes,
    required this.modifierBuilder,
    required this.proficiency,
    required this.availableAsiPoints,
    required this.onDistributeAsi,
  });

  final Pokemon pokemon;
  final TeamSlot? slot;
  final Map<String, int> attributes;
  final int Function(int score) modifierBuilder;
  final int proficiency;
  final int availableAsiPoints;
  final VoidCallback onDistributeAsi;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _PendingAsiCard(
          availablePoints: availableAsiPoints,
          onDistribute: onDistributeAsi,
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              children: [
                for (final entry in attributes.entries)
                  _AttributeBox(
                    label: entry.key,
                    score: entry.value,
                    modifier: modifierBuilder(entry.value),
                  ),
              ],
            ),
          ),
        ),
        _InfoCard(
          title: 'Dettagli',
          child: Column(
            children: [
              _InfoRow(label: 'Taglia', value: pokemon.size),
              _InfoRow(label: 'Velocità', value: '${pokemon.speed} ft'),
              _InfoRow(label: 'Dado vita', value: 'd${pokemon.hitDice}'),
              _InfoRow(label: 'Competenza', value: '+$proficiency'),
              _InfoRow(label: 'Livello minimo', value: '${pokemon.minLevelFound}'),
              _InfoRow(
                label: 'Tiri salvezza',
                value: pokemon.savingThrows.join(', '),
              ),
              _InfoRow(
                label: 'Competenze',
                value: [...pokemon.skills, ...?slot?.extraSkills].join(', '),
              ),
              _InfoRow(label: 'Natura', value: slot?.nature ?? 'No Nature'),
              _InfoRow(label: 'Forma', value: slot?.formName ?? '-'),
              _InfoRow(label: 'Shiny', value: slot?.isShiny == true ? 'Si' : 'No'),
              _InfoRow(label: 'Sesso', value: slot?.gender ?? '-'),
            ],
          ),
        ),
      ],
    );
  }
}

class _PendingAsiCard extends StatelessWidget {
  const _PendingAsiCard({
    required this.availablePoints,
    required this.onDistribute,
  });

  final int availablePoints;
  final VoidCallback onDistribute;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasPoints = availablePoints > 0;

    return Card(
      color: hasPoints ? colorScheme.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.trending_up,
              color: hasPoints ? colorScheme.onPrimaryContainer : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ASI DISPONIBILI',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: hasPoints ? colorScheme.onPrimaryContainer : null,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasPoints
                        ? 'Hai $availablePoints punti accumulati da distribuire.'
                        : 'Nessun punto ASI disponibile.',
                    style: TextStyle(
                      color: hasPoints ? colorScheme.onPrimaryContainer : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: hasPoints ? onDistribute : null,
              child: const Text('DISTRIBUISCI'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttributeBox extends StatelessWidget {
  const _AttributeBox({
    required this.label,
    required this.score,
    required this.modifier,
  });

  final String label;
  final int score;
  final int modifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$label $score'),
        Text(
          _signed(modifier),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }
}

class _PartySwitcher extends StatelessWidget {
  const _PartySwitcher({
    required this.team,
    required this.currentSlotIndex,
    required this.pokemonById,
    required this.onSelect,
  });

  final List<TeamSlot> team;
  final int currentSlotIndex;
  final Pokemon? Function(int? pokemonId) pokemonById;
  final ValueChanged<TeamSlot> onSelect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sortedTeam = [...team]
      ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));

    return SafeArea(
      top: false,
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: Row(
          children: [
            for (final slot in sortedTeam)
              Expanded(
                child: _PartySlotButton(
                  slot: slot,
                  pokemon: pokemonById(slot.pokemonId),
                  isActive: slot.slotIndex == currentSlotIndex,
                  onTap: slot.pokemonId == null ? null : () => onSelect(slot),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PartySlotButton extends StatelessWidget {
  const _PartySlotButton({
    required this.slot,
    required this.pokemon,
    required this.isActive,
    required this.onTap,
  });

  final TeamSlot slot;
  final Pokemon? pokemon;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pokemon = this.pokemon;

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? colorScheme.primary : colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            pokemon == null
                ? Icon(Icons.radio_button_unchecked, color: colorScheme.outline)
                : PokemonAssetImage(pokemon: pokemon, size: 30),
            const SizedBox(height: 2),
            Text(
              pokemon == null
                  ? '${slot.slotIndex + 1}'
                  : '#${pokemon.id.toString().padLeft(3, '0')}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExperienceDialog extends StatefulWidget {
  const _ExperienceDialog({required this.currentExperience});

  final int currentExperience;

  @override
  State<_ExperienceDialog> createState() => _ExperienceDialogState();
}

class _ExperienceDialogState extends State<_ExperienceDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifica esperienza'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Esperienza',
          helperText: 'Usa +2000 per aggiungere, 2000 per impostare.',
          hintText: widget.currentExperience.toString(),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Salva')),
      ],
    );
  }
}

class _HpDialog extends StatefulWidget {
  const _HpDialog({required this.currentHp, required this.maxHp});

  final int currentHp;
  final int maxHp;

  @override
  State<_HpDialog> createState() => _HpDialogState();
}

class _HpDialogState extends State<_HpDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifica HP'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'HP',
          helperText: 'Usa +5 per curare, -5 per danneggiare, 5 per impostare.',
          hintText: widget.currentHp.toString(),
          suffixText: '/ ${widget.maxHp}',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Salva')),
      ],
    );
  }
}
