import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/bag_item.dart';
import '../../models/level_progression.dart';
import '../../models/move_data.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_nature.dart';
import '../../models/team_slot.dart';
import '../../models/user_profile.dart';
import '../../repositories/item_repository.dart';
import '../../repositories/move_repository.dart';
import '../../repositories/pokemon_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/team_repository.dart';
import '../../widgets/navigation/home_leading_button.dart';
import '../../widgets/pokemon/pokemon_asset_image.dart';
import '../bag/bag_screen.dart';

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
  final Random _random = Random();

  late Future<_BattleData> _dataFuture;
  final Map<int, Map<String, int>> _remainingPpBySlot = {};

  int? _activeSlotIndex;
  int _round = 1;
  String? _message;

  static const List<String> _statusOptions = [
    'Asleep',
    'Burned',
    'Confused',
    'Frozen',
    'Paralyzed',
    'Poisoned',
  ];

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadBattleData();
  }

  Future<_BattleData> _loadBattleData() async {
    final profile = await _profileRepository.getActiveProfile();
    final team = await _teamRepository.getTeam(profile.id);
    team.sort((a, b) => a.slotIndex.compareTo(b.slotIndex));

    final pokemonList = await _pokemonRepository.getAllPokemon();
    final pokemonById = {for (final pokemon in pokemonList) pokemon.id: pokemon};
    final items = await _itemRepository.getWebItems();
    final moveReferences = <String>{'Struggle'};

    for (final slot in team) {
      final pokemonId = slot.pokemonId;
      if (pokemonId == null) continue;

      final pokemon = pokemonById[pokemonId];
      if (pokemon == null) continue;

      moveReferences.addAll(_movesForSlot(slot, pokemon));
    }

    final moves = await _moveRepository.getMoves(moveReferences);

    return _BattleData(
      profile: profile,
      team: team,
      pokemonById: pokemonById,
      moves: moves,
      items: items,
    );
  }

  Future<void> _reload({String? message}) async {
    if (!mounted) return;

    setState(() {
      _message = message;
      _dataFuture = _loadBattleData();
    });
  }

  TeamSlot? _activeSlotFor(_BattleData data) {
    if (data.occupiedSlots.isEmpty) return null;

    for (final slot in data.occupiedSlots) {
      if (slot.slotIndex == _activeSlotIndex) return slot;
    }

    return data.occupiedSlots.first;
  }

  Pokemon? _pokemonForSlot(_BattleData data, TeamSlot slot) {
    final pokemonId = slot.pokemonId;
    if (pokemonId == null) return null;
    return data.pokemonById[pokemonId];
  }

  List<String> _movesForSlot(TeamSlot slot, Pokemon pokemon) {
    if (slot.selectedMoves.isNotEmpty) {
      return slot.selectedMoves.take(4).toList(growable: false);
    }

    return _defaultSelectedMoves(pokemon, _levelForSlot(slot));
  }

  List<String> _defaultSelectedMoves(Pokemon pokemon, int level) {
    final names = <String>[...pokemon.moves.startingMoves];
    final levelEntries = pokemon.moves.levelMoves.entries
        .where((entry) => entry.key <= level)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in levelEntries) {
      names.addAll(entry.value);
    }

    return names.toSet().take(4).toList(growable: false);
  }

  int _levelForSlot(TeamSlot slot) {
    return LevelProgression.levelFromExperience(slot.experience);
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

  void _changePp(TeamSlot slot, String reference, MoveData? move, int delta) {
    final maxPp = _maxPpFor(move);
    if (maxPp <= 0) return;

    final slotPp = _remainingPpBySlot.putIfAbsent(slot.slotIndex, () => {});
    final key = _ppKey(reference, move);
    final current = slotPp[key] ?? maxPp;

    setState(() {
      slotPp[key] = (current + delta).clamp(0, maxPp).toInt();
    });
  }

  bool _hasNoPpLeft(
    TeamSlot slot,
    List<String> moveReferences,
    Map<String, MoveData?> moves,
  ) {
    final trackableMoves = moveReferences.where((reference) {
      return _maxPpFor(moves[reference]) > 0;
    }).toList(growable: false);

    if (trackableMoves.isEmpty) return false;

    return trackableMoves.every((reference) {
      return _remainingPp(slot, reference, moves[reference]) <= 0;
    });
  }

  Future<void> _changeHp(_BattleData data, TeamSlot slot, int delta) async {
    final pokemon = _pokemonForSlot(data, slot);
    if (pokemon == null) return;

    final maxHp = _maxHpFor(pokemon, slot);
    final updatedHp = (_currentHpFor(slot, pokemon) + delta).clamp(0, maxHp).toInt();

    await _teamRepository.updateSlot(
      profileId: data.profile.id,
      updatedSlot: slot.copyWith(currentHp: updatedHp),
    );
    await _reload();
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

    final updatedHp = _applyHpInput(
      currentHp: _currentHpFor(slot, pokemon),
      maxHp: _maxHpFor(pokemon, slot),
      input: input,
    );

    await _teamRepository.updateSlot(
      profileId: data.profile.id,
      updatedSlot: slot.copyWith(currentHp: updatedHp),
    );
    await _reload();
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

  Future<void> _healFull(_BattleData data, TeamSlot slot) async {
    final pokemon = _pokemonForSlot(data, slot);
    if (pokemon == null) return;

    await _teamRepository.updateSlot(
      profileId: data.profile.id,
      updatedSlot: slot.copyWith(
        currentHp: _maxHpFor(pokemon, slot),
        statusEffects: const [],
      ),
    );
    await _reload(message: '${_displayName(slot, pokemon)} è pronto a combattere.');
  }

  Future<void> _useHeldBerry(_BattleData data, TeamSlot slot) async {
    final pokemon = _pokemonForSlot(data, slot);
    final heldItem = data.heldItemFor(slot);
    if (pokemon == null || heldItem == null || heldItem.type != 'berry') return;

    final result = _applyMedicine(item: heldItem, slot: slot, pokemon: pokemon);
    if (result == null) {
      await _reload(message: '${heldItem.name} non avrebbe effetto su ${_displayName(slot, pokemon)}.');
      return;
    }

    await _teamRepository.updateSlot(
      profileId: data.profile.id,
      updatedSlot: result.updatedSlot.copyWith(heldItem: null),
    );
    await _reload(message: '${result.message} ${heldItem.name} è stata consumata.');
  }

  Future<void> _openBag() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BagScreen()),
    );
    await _reload();
  }

  _MedicineUseResult? _applyMedicine({
    required BagItem item,
    required TeamSlot slot,
    required Pokemon pokemon,
  }) {
    if (!_isSupportedMedicine(item.id)) return null;

    final maxHp = _maxHpFor(pokemon, slot);
    final currentHp = slot.currentHp.clamp(0, maxHp).toInt();
    final statusEffects = [...slot.statusEffects];
    var updatedHp = currentHp;
    var updatedStatuses = [...statusEffects];
    var healingText = '';
    var statusText = '';

    final healAmount = _healingAmount(item.id);
    final isReviveItem = _isReviveMedicine(item.id);

    if (healAmount != null) {
      if (currentHp <= 0 && !isReviveItem) return null;
      if (currentHp > 0 && isReviveItem) return null;

      updatedHp = (currentHp + healAmount).clamp(0, maxHp).toInt();
      if (updatedHp != currentHp) {
        healingText = 'recupera ${updatedHp - currentHp} HP';
      }
    }

    final curedStatuses = _statusesCuredBy(item.id, statusEffects);
    if (curedStatuses.isNotEmpty) {
      updatedStatuses = updatedStatuses
          .where((status) => !curedStatuses.contains(status))
          .toList(growable: false);
      statusText = curedStatuses.length == statusEffects.length
          ? 'guarisce dagli status'
          : 'guarisce da ${curedStatuses.join(', ')}';
    }

    if (updatedHp == currentHp && _sameStrings(updatedStatuses, statusEffects)) {
      return null;
    }

    final effects = [healingText, statusText]
        .where((part) => part.isNotEmpty)
        .join(' e ');

    return _MedicineUseResult(
      updatedSlot: slot.copyWith(
        currentHp: updatedHp,
        statusEffects: updatedStatuses,
      ),
      message: '${_displayName(slot, pokemon)} $effects usando ${item.name}.',
    );
  }

  bool _isSupportedMedicine(String itemId) {
    return _healingItemIds.contains(itemId) ||
        _statusMedicineItemIds.contains(itemId) ||
        _berryMedicineItemIds.contains(itemId);
  }

  bool _isReviveMedicine(String itemId) {
    return const {'revive', 'max-revive', 'revival-herb'}.contains(itemId);
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
        return 30;
      case 'fresh-water':
        return 7;
      case 'soda-pop':
        return 10;
      case 'berry-juice':
        return 20;
      case 'lemonade':
        return 30;
      case 'moomoo-milk':
        return 50;
      default:
        return null;
    }
  }

  int _rollDice(int diceCount, int sides, int bonus) {
    var total = bonus;
    for (var i = 0; i < diceCount; i++) {
      total += _random.nextInt(sides) + 1;
    }
    return total;
  }

  List<String> _statusesCuredBy(String itemId, List<String> statuses) {
    final targets = _statusTargetsByMedicine[itemId];
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

  Future<void> _setStatusEffects(
    _BattleData data,
    TeamSlot slot,
    List<String> statuses,
  ) async {
    await _teamRepository.updateSlot(
      profileId: data.profile.id,
      updatedSlot: slot.copyWith(statusEffects: statuses),
    );
    await _reload();
  }

  Future<void> _openStatusPicker(_BattleData data, TeamSlot slot) async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final selected = slot.statusEffects.toSet();

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                    child: Text(
                      'STATUS IN COMBATTIMENTO',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  for (final status in _statusOptions)
                    CheckboxListTile(
                      secondary: _StatusIcon(status: status, size: 28),
                      title: Text(status.toUpperCase()),
                      value: selected.contains(status),
                      onChanged: (value) {
                        setSheetState(() {
                          if (value == true) {
                            selected.add(status);
                          } else {
                            selected.remove(status);
                          }
                        });
                      },
                    ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.save_outlined),
                    title: const Text('SALVA STATUS'),
                    onTap: () => Navigator.of(context).pop(selected.toList()),
                  ),
                  if (selected.isNotEmpty)
                    ListTile(
                      leading: const Icon(Icons.clear),
                      title: const Text('RIMUOVI TUTTI'),
                      onTap: () => Navigator.of(context).pop(const []),
                    ),
                ],
              ),
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;
    await _setStatusEffects(data, slot, result);
  }

  void _nextRound() {
    setState(() {
      _round += 1;
      _message = 'Round $_round iniziato.';
    });
  }

  void _resetBattle() {
    setState(() {
      _round = 1;
      _remainingPpBySlot.clear();
      _message = 'Tracker combattimento azzerato.';
    });
  }

  int _currentHpFor(TeamSlot slot, Pokemon pokemon) {
    return slot.currentHp.clamp(0, _maxHpFor(pokemon, slot)).toInt();
  }

  int _loyaltyHpBonus(int loyalty, int level) {
    if (loyalty == 2) return (level / 2).ceil();
    if (loyalty == 3) return level;
    return 0;
  }

  int _maxHpFor(Pokemon pokemon, TeamSlot slot) {
    final level = _levelForSlot(slot).clamp(1, LevelProgression.maxLevel).toInt();
    final minimumLevel = pokemon.minLevelFound <= 0 ? 1 : pokemon.minLevelFound;
    final levelsGained = (level - minimumLevel).clamp(0, LevelProgression.maxLevel).toInt();
    final hitDieAverage = ((pokemon.hitDice + 1) / 2).ceil();
    final attributes = _attributeScores(pokemon, slot);
    final constitutionModifier = _modifier(attributes['CON'] ?? 10);
    final toughBonus = slot.feats.contains('Tough') ? level * 2 : 0;
    final loyaltyBonus = _loyaltyHpBonus(slot.loyalty, level);
    final scaledHp = pokemon.hitPoints +
        (hitDieAverage * levelsGained) +
        (constitutionModifier * level) +
        toughBonus +
        loyaltyBonus;

    return scaledHp < 1 ? 1 : scaledHp;
  }

  Map<String, int> _attributeScores(Pokemon pokemon, TeamSlot slot) {
    final customScores = slot.customAbilityScores;
    final natureScores = PokemonNature.forName(slot.nature);

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

  int _modifier(int score) => ((score - 10) / 2).floor();

  int _proficiency(int level) {
    if (level >= 17) return 6;
    if (level >= 13) return 5;
    if (level >= 9) return 4;
    if (level >= 5) return 3;
    return 2;
  }

  int _bestMoveModifier(MoveData move, Pokemon pokemon, TeamSlot slot) {
    final attributes = _attributeScores(pokemon, slot);
    final modifiers = move.movePowers
        .where(attributes.containsKey)
        .map((power) => _modifier(attributes[power]!))
        .toList();

    if (modifiers.isEmpty) return 0;
    modifiers.sort();
    return modifiers.last;
  }

  String _moveStats(MoveData move, Pokemon pokemon, TeamSlot slot) {
    final level = _levelForSlot(slot);
    final moveModifier = _bestMoveModifier(move, pokemon, slot);
    final proficiency = _proficiency(level);
    final parts = <String>[];

    if (move.isAttack) {
      final attackBonus = moveModifier + proficiency;
      parts.add('AB: ${attackBonus >= 0 ? '+' : ''}$attackBonus');
    }
    if (move.save != null) {
      parts.add('DC: ${8 + proficiency + moveModifier}');
    }

    final damage = move.damageForLevel(level);
    if (damage != null) parts.add(damage.label);
    if (move.range != '-') parts.add(move.range);
    if (move.duration != '-') parts.add(move.duration);

    return parts.join('  ||  ');
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
        title: const Text('Battle Companion'),
        actions: [
          IconButton(
            tooltip: 'Reset combattimento',
            onPressed: _resetBattle,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<_BattleData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _BattleEmptyState(
              icon: Icons.error_outline,
              title: 'Errore caricando il combattimento',
              message: snapshot.error.toString(),
              actionLabel: 'Riprova',
              onAction: () => _reload(),
            );
          }

          final data = snapshot.data;
          if (data == null || data.occupiedSlots.isEmpty) {
            return _BattleEmptyState(
              icon: Icons.groups_outlined,
              title: 'Nessun Pokémon in squadra',
              message:
                  'Aggiungi almeno un Pokémon alla squadra prima di aprire il tracker.',
              actionLabel: 'Ricarica',
              onAction: () => _reload(),
            );
          }

          final activeSlot = _activeSlotFor(data)!;
          final pokemon = _pokemonForSlot(data, activeSlot)!;
          final moveReferences = _movesForSlot(activeSlot, pokemon);
          final noPpLeft = _hasNoPpLeft(activeSlot, moveReferences, data.moves);
          final heldItem = data.heldItemFor(activeSlot);

          return RefreshIndicator(
            onRefresh: () => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _BattleHeader(
                  round: _round,
                  profile: data.profile,
                  activeSlot: activeSlot,
                  occupiedSlots: data.occupiedSlots,
                  pokemonForSlot: (slot) => _pokemonForSlot(data, slot),
                  onActiveSlotChanged: (slotIndex) {
                    setState(() {
                      _activeSlotIndex = slotIndex;
                      _message = null;
                    });
                  },
                  onNextRound: _nextRound,
                  onReset: _resetBattle,
                ),
                const SizedBox(height: 12),
                _ActivePokemonCard(
                  pokemon: pokemon,
                  slot: activeSlot,
                  heldItem: heldItem,
                  displayName: _displayName(activeSlot, pokemon),
                  level: _levelForSlot(activeSlot),
                  currentHp: _currentHpFor(activeSlot, pokemon),
                  maxHp: _maxHpFor(pokemon, activeSlot),
                  statuses: activeSlot.statusEffects,
                  message: _message,
                  onMinusFive: () => _changeHp(data, activeSlot, -5),
                  onMinusOne: () => _changeHp(data, activeSlot, -1),
                  onPlusOne: () => _changeHp(data, activeSlot, 1),
                  onPlusFive: () => _changeHp(data, activeSlot, 5),
                  onEditHp: () => _editHp(data, activeSlot),
                  onHeal: () => _healFull(data, activeSlot),
                  onStatus: () => _openStatusPicker(data, activeSlot),
                  onUseHeldBerry: heldItem?.type == 'berry'
                      ? () => _useHeldBerry(data, activeSlot)
                      : null,
                  onOpenBag: _openBag,
                ),
                const SizedBox(height: 12),
                Text(
                  'MOSSE DA COMBATTIMENTO',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                if (noPpLeft) ...[
                  _StruggleWarning(move: data.moves['Struggle']),
                  const SizedBox(height: 8),
                ],
                for (final reference in moveReferences)
                  _BattleMoveCard(
                    reference: reference,
                    move: data.moves[reference],
                    remainingPp: _remainingPp(
                      activeSlot,
                      reference,
                      data.moves[reference],
                    ),
                    maxPp: _maxPpFor(data.moves[reference]),
                    stats: data.moves[reference] == null
                        ? null
                        : _moveStats(data.moves[reference]!, pokemon, activeSlot),
                    onUse: () => _changePp(
                      activeSlot,
                      reference,
                      data.moves[reference],
                      -1,
                    ),
                    onRestore: () => _changePp(
                      activeSlot,
                      reference,
                      data.moves[reference],
                      1,
                    ),
                  ),
              ],
            ),
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
  });

  final UserProfile profile;
  final List<TeamSlot> team;
  final Map<int, Pokemon> pokemonById;
  final Map<String, MoveData?> moves;
  final List<BagItem> items;

  List<TeamSlot> get occupiedSlots {
    return team
        .where(
          (slot) => slot.pokemonId != null && pokemonById[slot.pokemonId] != null,
        )
        .toList(growable: false);
  }

  BagItem? heldItemFor(TeamSlot slot) {
    final reference = slot.heldItem;
    if (reference == null || reference.trim().isEmpty) return null;

    final normalizedReference = _itemReferenceKey(reference);
    for (final item in items) {
      if (item.id == reference ||
          _itemReferenceKey(item.id) == normalizedReference ||
          _itemReferenceKey(item.name) == normalizedReference) {
        return item;
      }
    }

    return null;
  }
}

class _MedicineUseResult {
  const _MedicineUseResult({required this.updatedSlot, required this.message});

  final TeamSlot updatedSlot;
  final String message;
}

class _StatusEffectInfo {
  const _StatusEffectInfo({
    required this.name,
    required this.shortLabel,
    required this.assetPath,
  });

  final String name;
  final String shortLabel;
  final String? assetPath;
}

const Map<String, _StatusEffectInfo> _statusInfoByName = {
  'Asleep': _StatusEffectInfo(
    name: 'Asleep',
    shortLabel: 'SLP',
    assetPath: 'assets/textures/gui/status/sleep_down.png',
  ),
  'Burned': _StatusEffectInfo(
    name: 'Burned',
    shortLabel: 'BRN',
    assetPath: 'assets/textures/gui/status/burn_down.png',
  ),
  'Confused': _StatusEffectInfo(
    name: 'Confused',
    shortLabel: 'CNF',
    assetPath: 'assets/textures/gui/status/confuse_down.png',
  ),
  'Frozen': _StatusEffectInfo(
    name: 'Frozen',
    shortLabel: 'FRZ',
    assetPath: 'assets/textures/gui/status/frozen_down.png',
  ),
  'Paralyzed': _StatusEffectInfo(
    name: 'Paralyzed',
    shortLabel: 'PAR',
    assetPath: 'assets/textures/gui/status/paralyze_down.png',
  ),
  'Poisoned': _StatusEffectInfo(
    name: 'Poisoned',
    shortLabel: 'PSN',
    assetPath: 'assets/textures/gui/status/poisoned_down.png',
  ),
  'Badly Poisoned': _StatusEffectInfo(
    name: 'Badly Poisoned',
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

const Map<String, Set<String>> _statusTargetsByMedicine = {
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

class _BattleHeader extends StatelessWidget {
  const _BattleHeader({
    required this.round,
    required this.profile,
    required this.activeSlot,
    required this.occupiedSlots,
    required this.pokemonForSlot,
    required this.onActiveSlotChanged,
    required this.onNextRound,
    required this.onReset,
  });

  final int round;
  final UserProfile profile;
  final TeamSlot activeSlot;
  final List<TeamSlot> occupiedSlots;
  final Pokemon? Function(TeamSlot slot) pokemonForSlot;
  final ValueChanged<int> onActiveSlotChanged;
  final VoidCallback onNextRound;
  final VoidCallback onReset;

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
                    'Round $round',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                Text('Allenatore Lv. ${profile.trainerLevel}'),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              key: ValueKey(activeSlot.slotIndex),
              initialValue: activeSlot.slotIndex,
              decoration: const InputDecoration(labelText: 'Pokémon attivo'),
              items: [
                for (final slot in occupiedSlots)
                  DropdownMenuItem<int>(
                    value: slot.slotIndex,
                    child: Text(
                      '${slot.slotIndex + 1}. ${_slotLabel(slot, pokemonForSlot(slot))}',
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                onActiveSlotChanged(value);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onNextRound,
                    icon: const Icon(Icons.skip_next),
                    label: const Text('NUOVO ROUND'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReset,
                    icon: const Icon(Icons.refresh),
                    label: const Text('RESET PP'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _slotLabel(TeamSlot slot, Pokemon? pokemon) {
    if (pokemon == null) return 'Slot ${slot.slotIndex + 1}';

    final nickname = slot.nickname?.trim();
    if (nickname != null && nickname.isNotEmpty) {
      return '$nickname (${pokemon.name})';
    }

    return pokemon.name;
  }
}

class _ActivePokemonCard extends StatelessWidget {
  const _ActivePokemonCard({
    required this.pokemon,
    required this.slot,
    required this.heldItem,
    required this.displayName,
    required this.level,
    required this.currentHp,
    required this.maxHp,
    required this.statuses,
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
  });

  final Pokemon pokemon;
  final TeamSlot slot;
  final BagItem? heldItem;
  final String displayName;
  final int level;
  final int currentHp;
  final int maxHp;
  final List<String> statuses;
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
                  pokemon: pokemon,
                  useLargeArtwork: true,
                  size: 96,
                  formName: slot.formName,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text('#${pokemon.id.toString().padLeft(3, '0')}  |  Lv. $level'),
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
            const SizedBox(height: 12),
            InkWell(
              onTap: onEditHp,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Text(
                      'HP $currentHp/$maxHp',
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
                  child: const Text('POKÉMON CENTER'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: onStatus,
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
                  child: statuses.isEmpty
                      ? const Text('STATUS: nessuno')
                      : Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            const Text('STATUS:'),
                            for (final status in statuses)
                              _StatusChip(status: status),
                          ],
                        ),
                ),
              ),
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

Color _hpProgressColor(double value) {
  if (value <= 0.25) return Colors.red;
  if (value <= 0.5) return Colors.amber;
  return Colors.green;
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
                    item == null ? 'ITEM: NONE' : 'ITEM: ${item.name.toUpperCase()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    item == null
                        ? 'Apri lo zaino per usare consumabili o assegnare strumenti.'
                        : item.type == 'berry'
                            ? 'Bacca tenuta: puoi usarla subito in combattimento.'
                            : 'Strumento tenuto: ${_itemTypeLabel(item.type)}.',
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
                child: const Text('USA'),
              ),
            const SizedBox(width: 6),
            FilledButton(
              onPressed: onOpenBag,
              child: const Text('ZAINO'),
            ),
          ],
        ),
      ),
    );
  }
}

String _itemTypeLabel(String type) {
  switch (type) {
    case 'berry':
      return 'Bacca';
    case 'held-item':
      return 'Strumento tenuto';
    case 'medicine':
      return 'Medicina';
    case 'pokeball':
      return 'Poké Ball';
    case 'tm':
      return 'MT';
    default:
      return type;
  }
}

class _BattleMoveCard extends StatelessWidget {
  const _BattleMoveCard({
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
        leading: move == null
            ? const Icon(Icons.radio_button_unchecked)
            : PokemonTypeBadge(type: move.type, height: 24),
        title: Text(
          title.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (move != null) PokemonTypeBadge(type: move.type, height: 18),
              if (stats != null && stats!.isNotEmpty) Text(stats!),
              if (canTrackPp) Text('PP $remainingPp/$maxPp'),
            ],
          ),
        ),
        trailing: canTrackPp
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Recupera PP',
                    onPressed: remainingPp >= maxPp ? null : onRestore,
                    icon: const Icon(Icons.add),
                  ),
                  IconButton(
                    tooltip: 'Usa mossa',
                    onPressed: remainingPp <= 0 ? null : onUse,
                    icon: const Icon(Icons.remove),
                  ),
                ],
              )
            : null,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        children: [
          if (move == null)
            const Text('Dettagli mossa non disponibili.')
          else ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Tempo: ${move.moveTime}  |  Durata: ${move.duration}'),
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: _StatusIcon(status: status, size: 22),
      label: Text(status.toUpperCase()),
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

    if (assetPath == null) {
      return _StatusFallback(label: info?.shortLabel ?? status.characters.take(3).toString(), size: size);
    }

    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        errorBuilder: (_, __, ___) => _StatusFallback(
          label: info?.shortLabel ?? status.characters.take(3).toString(),
          size: size,
        ),
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
    final remoteUrl = item.remoteSpriteUrl;
    if (remoteUrl == null) return Icon(Icons.inventory_2_outlined, size: size);

    return SizedBox(
      width: size,
      height: size,
      child: Image.network(
        remoteUrl,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Icon(Icons.inventory_2_outlined, size: size);
        },
        errorBuilder: (_, __, ___) => Icon(Icons.inventory_2_outlined, size: size),
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
      title: const Text('Modifica HP'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(signed: true),
        decoration: InputDecoration(
          labelText: 'HP o modifica',
          helperText: 'Esempi: -12, +8 oppure 35. Attuali ${widget.currentHp}/${widget.maxHp}',
        ),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Salva'),
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
              'STRUGGLE DISPONIBILE',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              move?.description ??
                  'Tutti i PP delle mosse tracciabili sono a zero. Usa Struggle.',
              style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
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
    return OutlinedButton(
      onPressed: onTap,
      child: Text(label),
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
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
