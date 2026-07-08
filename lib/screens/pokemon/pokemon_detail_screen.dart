import 'package:flutter/material.dart';

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
  Map<String, EvolutionData> _evolutions = {};
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

  int get _maxHp => _pokemon.hitPoints + _loyaltyHpBonus(_loyalty, _level);

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
    ]);

    if (!mounted) return;

    setState(() {
      _moves = results[0] as Map<String, MoveData?>;
      _abilities = results[1] as Map<String, String>;
      _evolutions = results[2] as Map<String, EvolutionData>;
      _featDescriptions = results[3] as Map<String, String>;
      _isLoading = false;
    });
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

    final input = await showDialog<String>(
      context: context,
      builder: (_) => _ExperienceDialog(currentExperience: slot.experience),
    );
    if (input == null) return;

    final oldLevel = LevelProgression.levelFromExperience(slot.experience);
    final updatedExperience = LevelProgression.applyExperienceInput(
      currentExperience: slot.experience,
      input: input,
    );
    final newLevel = LevelProgression.levelFromExperience(updatedExperience);
    var updatedSlot = slot.copyWith(experience: updatedExperience);

    if (newLevel > oldLevel) {
      updatedSlot = await _applyLevelUpMoves(updatedSlot, oldLevel, newLevel);
    }

    _saveTeamSlot(updatedSlot);
  }

  Future<void> _editHp() async {
    final slot = _teamSlot;
    if (slot == null) return;

    final input = await showDialog<String>(
      context: context,
      builder: (_) => _HpDialog(currentHp: _currentHp, maxHp: _maxHp),
    );
    if (input == null) return;

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
    final updatedLoyalty = (slot.loyalty + delta).clamp(-3, 3).toInt();
    final updatedMaxHp =
        _pokemon.hitPoints + _loyaltyHpBonus(updatedLoyalty, _level);
    final updatedHp = oldCurrentHp >= oldMaxHp
        ? updatedMaxHp
        : oldCurrentHp.clamp(0, updatedMaxHp).toInt();

    _saveTeamSlot(slot.copyWith(loyalty: updatedLoyalty, currentHp: updatedHp));
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
    if (shouldHeal != true || !mounted) return;

    _saveTeamSlot(slot.copyWith(currentHp: _maxHp, statusEffects: const []));
    _showMessage('${_pokemon.name} è stato curato al Pokémon Center.');
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
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
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

    if (result == null) return;
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
        final replacedMove = await _askMoveReplacement(
          move,
          selectedMoves,
          moveData,
        );
        if (replacedMove == null) continue;

        final replaceIndex = selectedMoves.indexOf(replacedMove);
        if (replaceIndex >= 0) {
          selectedMoves[replaceIndex] = move;
        }
      }
    }

    return slot.copyWith(selectedMoves: selectedMoves);
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

    if (result == null) return;

    _saveTeamSlot(result.slot);
    await _loadData();
  }

  EvolutionData? _evolutionForCurrentPokemon() {
    return _evolutions[_pokemon.name] ?? _evolutions[_referenceKey(_pokemon.name)];
  }

  bool _canEvolveCurrentPokemon() {
    final evolution = _evolutionForCurrentPokemon();
    if (!_isPartyMode || evolution == null) return false;
    return evolution.options.isNotEmpty || evolution.evolutions.isNotEmpty;
  }

  String? _evolutionLabel() {
    final evolution = _evolutionForCurrentPokemon();
    if (!_isPartyMode || evolution == null) return null;

    final count = evolution.options.isEmpty
        ? evolution.evolutions.length
        : evolution.options.length;
    if (count == 0) return null;

    if (count == 1) {
      final name = evolution.options.isEmpty
          ? evolution.evolutions.first
          : evolution.options.first.toName;
      return 'FAI EVOLVERE IN ${name.toUpperCase()}';
    }

    return 'SCEGLI EVOLUZIONE';
  }

  Future<void> _evolveCurrentPokemon() async {
    final slot = _teamSlot;
    final evolution = _evolutionForCurrentPokemon();
    if (slot == null || evolution == null) return;

    final profile = await _profileRepository.getActiveProfile();
    final inventory = await _bagInventoryRepository.getInventory(profile.id);
    final itemCatalog = await _itemRepository.getWebItems();
    final choices = _evolutionService.evaluateOptions(
      pokemon: _pokemon,
      slot: slot,
      evolution: evolution,
      inventory: inventory,
      itemCatalog: itemCatalog,
    );

    if (!mounted) return;

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

    await _evolveSlot(slot, selected, profile.id);
  }

  Future<TeamSlot?> _evolveSlot(
    TeamSlot slot,
    EvolutionEligibility selected,
    String profileId,
  ) async {
    if (!selected.isAvailable) return null;

    final evolvedPokemon = _pokemonByName(selected.option.toName);
    if (evolvedPokemon == null) {
      _showMessage(
        '${selected.option.toName} non è presente nel catalogo attuale.',
      );
      return null;
    }

    final requiredItemId = selected.requiredItemId;
    if (requiredItemId != null) {
      final consumed = await _bagInventoryRepository.consumeItem(
        profileId: profileId,
        itemId: requiredItemId,
      );
      if (!consumed) {
        _showMessage('Oggetto evolutivo non disponibile nello zaino.');
        return null;
      }
    }

    final wasFullHp = _currentHp >= _maxHp;
    final oldName = _pokemon.name;
    final evolvedMaxHp =
        evolvedPokemon.hitPoints + _loyaltyHpBonus(slot.loyalty, _level);
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
                          onEditExperience: _editExperience,
                          onEditHp: _editHp,
                          onDecreaseHp: () => _changeHp(-1),
                          onIncreaseHp: () => _changeHp(1),
                          onDecreaseLoyalty: () => _changeLoyalty(-1),
                          onIncreaseLoyalty: () => _changeLoyalty(1),
                          onPokemonCenter: _usePokemonCenter,
                          onAddStatusEffect: _pickStatusEffect,
                          canEvolve: _canEvolveCurrentPokemon(),
                          evolutionLabel: _evolutionLabel(),
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
    required this.onEditExperience,
    required this.onEditHp,
    required this.onDecreaseHp,
    required this.onIncreaseHp,
    required this.onDecreaseLoyalty,
    required this.onIncreaseLoyalty,
    required this.onPokemonCenter,
    required this.onAddStatusEffect,
    required this.canEvolve,
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
  final VoidCallback onEditExperience;
  final VoidCallback onEditHp;
  final VoidCallback onDecreaseHp;
  final VoidCallback onIncreaseHp;
  final VoidCallback onDecreaseLoyalty;
  final VoidCallback onIncreaseLoyalty;
  final VoidCallback onPokemonCenter;
  final VoidCallback onAddStatusEffect;
  final bool canEvolve;
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
    final itemLabel = slot?.heldItem == null || slot!.heldItem!.trim().isEmpty
        ? 'NONE'
        : slot!.heldItem!.toUpperCase();

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
              Expanded(child: _PanelButton(label: 'ITEM: $itemLabel')),
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
                              backgroundColor:
                                  Theme.of(context).colorScheme.surfaceContainerHighest,
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
          if (isPartyMode && canEvolve && evolutionLabel != null) ...[
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
              Text('$score', style: const TextStyle(fontWeight: FontWeight.w900)),
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
  });

  final Pokemon pokemon;
  final TeamSlot? slot;
  final Map<String, int> attributes;
  final int Function(int score) modifierBuilder;
  final int proficiency;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
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
              _InfoRow(label: 'Tiri salvezza', value: pokemon.savingThrows.join(', ')),
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
