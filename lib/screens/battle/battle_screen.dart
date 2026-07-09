import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/bag_inventory_entry.dart';
import '../../models/bag_item.dart';
import '../../models/level_progression.dart';
import '../../models/move_data.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_nature.dart';
import '../../models/team_slot.dart';
import '../../models/user_profile.dart';
import '../../repositories/bag_inventory_repository.dart';
import '../../repositories/item_repository.dart';
import '../../repositories/move_repository.dart';
import '../../repositories/pokemon_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/team_repository.dart';
import '../../widgets/navigation/home_leading_button.dart';
import '../../widgets/pokemon/pokemon_asset_image.dart';

class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  final ProfileRepository _profiles = ProfileRepository();
  final TeamRepository _teams = TeamRepository();
  final PokemonRepository _pokemonRepo = PokemonRepository();
  final MoveRepository _movesRepo = MoveRepository();
  final ItemRepository _itemsRepo = ItemRepository();
  final BagInventoryRepository _bagRepo = BagInventoryRepository();
  final Random _random = Random();

  late Future<_BattleData> _future;
  final Map<int, Map<String, int>> _pp = {};
  final Map<int, Set<String>> _volatileBySlot = {};
  final List<_InitiativeEntry> _initiative = [];
  int? _activeSlotIndex;
  int _round = 1;
  int _turnIndex = 0;
  String? _message;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_BattleData> _load() async {
    final profile = await _profiles.getActiveProfile();
    final team = await _teams.getTeam(profile.id)..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
    final pokedex = await _pokemonRepo.getAllPokemon();
    final pokemonById = {for (final p in pokedex) p.id: p};
    final items = await _itemsRepo.getWebItems();
    final inventory = await _bagRepo.getInventory(profile.id);
    final moveRefs = <String>{'Struggle'};
    for (final slot in team) {
      final pokemon = slot.pokemonId == null ? null : pokemonById[slot.pokemonId];
      if (pokemon != null) moveRefs.addAll(_movesFor(slot, pokemon));
    }
    final moves = await _movesRepo.getMoves(moveRefs);
    return _BattleData(profile: profile, team: team, pokemonById: pokemonById, moves: moves, items: items, inventory: inventory);
  }

  Future<void> _reload({String? message}) async {
    if (!mounted) return;
    setState(() {
      _message = message;
      _future = _load();
    });
  }

  TeamSlot? _activeSlot(_BattleData data) {
    if (data.occupiedSlots.isEmpty) return null;
    return data.occupiedSlots.where((s) => s.slotIndex == _activeSlotIndex).firstOrNull ?? data.occupiedSlots.first;
  }

  Pokemon? _pokemonFor(_BattleData data, TeamSlot slot) => slot.pokemonId == null ? null : data.pokemonById[slot.pokemonId];

  List<String> _movesFor(TeamSlot slot, Pokemon pokemon) {
    if (slot.selectedMoves.isNotEmpty) return slot.selectedMoves.take(4).toList(growable: false);
    final names = <String>[...pokemon.moves.startingMoves];
    final learned = pokemon.moves.levelMoves.entries.where((e) => e.key <= _level(slot)).toList()..sort((a, b) => a.key.compareTo(b.key));
    for (final entry in learned) {
      names.addAll(entry.value);
    }
    return names.toSet().take(4).toList(growable: false);
  }

  int _level(TeamSlot slot) => LevelProgression.levelFromExperience(slot.experience);
  int _mod(int score) => ((score - 10) / 2).floor();
  int _trainerInitBonus(UserProfile profile) => _mod(profile.abilityScores['DEX'] ?? 10);
  int _rollTrainerInit(UserProfile profile) => _random.nextInt(20) + 1 + _trainerInitBonus(profile);

  int _maxPp(MoveData? move) {
    if (move == null) return 0;
    final direct = int.tryParse(move.pp.trim());
    if (direct != null) return direct;
    return int.tryParse(RegExp(r'\d+').firstMatch(move.pp)?.group(0) ?? '') ?? 0;
  }

  String _ppKey(String ref, MoveData? move) => move?.id ?? MoveData.referenceKey(ref);
  int _currentPp(TeamSlot slot, String ref, MoveData? move) {
    final max = _maxPp(move);
    return _pp.putIfAbsent(slot.slotIndex, () => {}).putIfAbsent(_ppKey(ref, move), () => max);
  }

  void _changePp(TeamSlot slot, String ref, MoveData? move, int delta) {
    final max = _maxPp(move);
    if (max <= 0) return;
    final slotPp = _pp.putIfAbsent(slot.slotIndex, () => {});
    final key = _ppKey(ref, move);
    setState(() => slotPp[key] = ((slotPp[key] ?? max) + delta).clamp(0, max).toInt());
  }

  bool _noPpLeft(TeamSlot slot, List<String> refs, Map<String, MoveData?> moves) {
    final tracked = refs.where((ref) => _maxPp(moves[ref]) > 0).toList();
    return tracked.isNotEmpty && tracked.every((ref) => _currentPp(slot, ref, moves[ref]) <= 0);
  }

  int _currentHp(TeamSlot slot, Pokemon pokemon) => slot.currentHp.clamp(0, _maxHp(pokemon, slot)).toInt();

  Future<void> _changeHp(_BattleData data, TeamSlot slot, int delta) async {
    final pokemon = _pokemonFor(data, slot);
    if (pokemon == null) return;
    final updated = (_currentHp(slot, pokemon) + delta).clamp(0, _maxHp(pokemon, slot)).toInt();
    await _teams.updateSlot(profileId: data.profile.id, updatedSlot: slot.copyWith(currentHp: updated));
    await _reload();
  }

  Future<void> _editHp(_BattleData data, TeamSlot slot) async {
    final pokemon = _pokemonFor(data, slot);
    if (pokemon == null) return;
    final input = await showDialog<String>(context: context, builder: (_) => _HpDialog(currentHp: _currentHp(slot, pokemon), maxHp: _maxHp(pokemon, slot)));
    if (!mounted || input == null) return;
    final trimmed = input.trim();
    final value = int.tryParse(trimmed);
    if (value == null) return;
    final updated = trimmed.startsWith('+') || trimmed.startsWith('-') ? (_currentHp(slot, pokemon) + value).clamp(0, _maxHp(pokemon, slot)).toInt() : value.clamp(0, _maxHp(pokemon, slot)).toInt();
    await _teams.updateSlot(profileId: data.profile.id, updatedSlot: slot.copyWith(currentHp: updated));
    await _reload();
  }

  Future<void> _healFull(_BattleData data, TeamSlot slot) async {
    final pokemon = _pokemonFor(data, slot);
    if (pokemon == null) return;
    _volatileBySlot.remove(slot.slotIndex);
    await _teams.updateSlot(profileId: data.profile.id, updatedSlot: slot.copyWith(currentHp: _maxHp(pokemon, slot), statusEffects: const []));
    await _reload(message: '${_name(slot, pokemon)} è pronto a combattere.');
  }

  Future<void> _useHeldBerry(_BattleData data, TeamSlot slot) async {
    final pokemon = _pokemonFor(data, slot);
    final item = data.heldItemFor(slot);
    if (pokemon == null || item == null || item.type != 'berry') return;
    final result = _applyMedicine(item: item, slot: slot, pokemon: pokemon, volatile: _volatile(slot));
    final updatedSlot = (result?.updatedSlot ?? slot).copyWith(heldItem: null);
    await _teams.updateSlot(profileId: data.profile.id, updatedSlot: updatedSlot);
    if (result != null) _volatileBySlot[slot.slotIndex] = result.volatile.toSet();
    await _reload(message: result?.message ?? '${item.name} è stata consumata. Applica manualmente il suo effetto se necessario.');
  }

  Future<void> _openQuickBag(_BattleData data, TeamSlot slot) async {
    final pokemon = _pokemonFor(data, slot);
    if (pokemon == null) return;
    final items = data.ownedConsumables;
    if (items.isEmpty) {
      await _reload(message: 'Non hai consumabili nello zaino.');
      return;
    }
    final selected = await showModalBottomSheet<_OwnedBattleItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _QuickBagSheet(items: items, pokemonName: _name(slot, pokemon), currentHp: _currentHp(slot, pokemon), maxHp: _maxHp(pokemon, slot), nonVolatile: _nonVolatile(slot), volatile: _volatile(slot)),
    );
    if (!mounted || selected == null) return;
    await _useBagItem(data, slot, pokemon, selected);
  }

  Future<void> _useBagItem(_BattleData data, TeamSlot slot, Pokemon pokemon, _OwnedBattleItem selected) async {
    final item = selected.item;
    final isBerry = item.type == 'berry';
    final result = _applyMedicine(item: item, slot: slot, pokemon: pokemon, volatile: _volatile(slot));
    if (result == null && !isBerry) {
      await _reload(message: '${item.name} non avrebbe effetto su ${_name(slot, pokemon)}.');
      return;
    }
    final consumed = await _bagRepo.consumeItem(profileId: data.profile.id, itemId: item.id);
    if (!consumed) {
      await _reload(message: 'Non hai più ${item.name} nello zaino.');
      return;
    }
    if (result != null) {
      await _teams.updateSlot(profileId: data.profile.id, updatedSlot: result.updatedSlot);
      _volatileBySlot[slot.slotIndex] = result.volatile.toSet();
      await _reload(message: result.message);
    } else {
      await _reload(message: '${item.name} è stata consumata. Applica manualmente il suo effetto se necessario.');
    }
  }

  _MedicineResult? _applyMedicine({required BagItem item, required TeamSlot slot, required Pokemon pokemon, required Set<String> volatile}) {
    if (!_isMedicine(item.id)) return null;
    final max = _maxHp(pokemon, slot);
    final current = slot.currentHp.clamp(0, max).toInt();
    final nonVol = [..._nonVolatileList(slot)];
    final vol = [...volatile];
    var hp = current;
    var updatedNonVol = [...nonVol];
    var updatedVol = [...vol];
    var hpText = '';
    var statusText = '';
    final heal = _healAmount(item.id);
    final revive = const {'revive', 'max-revive', 'revival-herb'}.contains(item.id);
    if (heal != null) {
      if (current <= 0 && !revive) return null;
      if (current > 0 && revive) return null;
      hp = (current + heal).clamp(0, max).toInt();
      if (hp != current) hpText = 'recupera ${hp - current} HP';
    }
    final curedNonVol = _curedBy(item.id, nonVol);
    final curedVol = _curedBy(item.id, vol);
    final cured = [...curedNonVol, ...curedVol];
    if (cured.isNotEmpty) {
      updatedNonVol = updatedNonVol.where((s) => !curedNonVol.contains(s)).toList();
      updatedVol = updatedVol.where((s) => !curedVol.contains(s)).toList();
      statusText = cured.length == nonVol.length + vol.length ? 'guarisce dagli status' : 'guarisce da ${cured.join(', ')}';
    }
    if (hp == current && _same(updatedNonVol, nonVol) && _same(updatedVol, vol)) return null;
    final effect = [hpText, statusText].where((s) => s.isNotEmpty).join(' e ');
    return _MedicineResult(updatedSlot: slot.copyWith(currentHp: hp, statusEffects: updatedNonVol), volatile: updatedVol, message: '${_name(slot, pokemon)} $effect usando ${item.name}.');
  }

  bool _isMedicine(String id) => _healingIds.contains(id) || _statusMedicineIds.contains(id) || _berryMedicineIds.contains(id);
  int? _healAmount(String id) {
    switch (id) {
      case 'potion':
      case 'revive':
      case 'oran-berry':
        return _dice(2, 4, 2);
      case 'super-potion':
      case 'energy-powder':
        return _dice(3, 6, 6);
      case 'hyper-potion':
      case 'energy-root':
      case 'max-revive':
      case 'revival-herb':
        return _dice(4, 12, 10);
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

  int _dice(int count, int sides, int bonus) {
    var total = bonus;
    for (var i = 0; i < count; i++) {
      total += _random.nextInt(sides) + 1;
    }
    return total;
  }

  List<String> _curedBy(String itemId, List<String> statuses) {
    final targets = _statusTargets[itemId];
    if (targets == null) return const [];
    if (targets.contains('*')) return List<String>.from(statuses);
    return statuses.where(targets.contains).toList(growable: false);
  }

  bool _same(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  List<String> _nonVolatileList(TeamSlot slot) => slot.statusEffects.where(_nonVolatileOptions.contains).take(1).toList(growable: false);
  String? _nonVolatile(TeamSlot slot) => _nonVolatileList(slot).firstOrNull;
  Set<String> _volatile(TeamSlot slot) => {...?_volatileBySlot[slot.slotIndex], ...slot.statusEffects.where(_volatileOptions.contains)};

  Future<void> _openStatusPicker(_BattleData data, TeamSlot slot) async {
    final result = await showModalBottomSheet<_StatusResult>(context: context, showDragHandle: true, builder: (_) => _StatusSheet(nonVolatile: _nonVolatile(slot), volatile: _volatile(slot)));
    if (!mounted || result == null) return;
    _volatileBySlot[slot.slotIndex] = result.volatile;
    await _teams.updateSlot(profileId: data.profile.id, updatedSlot: slot.copyWith(statusEffects: result.nonVolatile == null ? const [] : [result.nonVolatile!]));
    await _reload();
  }

  void _ensureInitiative(_BattleData data, TeamSlot slot, Pokemon pokemon) {
    final label = '${data.profile.name} + ${_name(slot, pokemon)}';
    final index = _initiative.indexWhere((e) => e.trainer);
    if (index == -1) {
      _initiative.add(_InitiativeEntry(id: 'trainer', name: label, initiative: _rollTrainerInit(data.profile), trainer: true));
      _sortInitiative();
    } else if (_initiative[index].name != label) {
      _initiative[index] = _initiative[index].copyWith(name: label);
    }
  }

  void _sortInitiative() {
    _initiative.sort((a, b) {
      final byInit = b.initiative.compareTo(a.initiative);
      if (byInit != 0) return byInit;
      if (a.trainer != b.trainer) return a.trainer ? -1 : 1;
      return a.name.compareTo(b.name);
    });
    _turnIndex = _initiative.isEmpty ? 0 : _turnIndex.clamp(0, _initiative.length - 1).toInt();
  }

  void _rerollTrainer(UserProfile profile) {
    setState(() {
      final index = _initiative.indexWhere((e) => e.trainer);
      final roll = _rollTrainerInit(profile);
      if (index == -1) {
        _initiative.add(_InitiativeEntry(id: 'trainer', name: '${profile.name} + Pokémon', initiative: roll, trainer: true));
      } else {
        _initiative[index] = _initiative[index].copyWith(initiative: roll);
      }
      _turnIndex = 0;
      _sortInitiative();
      _message = 'Iniziativa allenatore/Pokémon: $roll.';
    });
  }

  Future<void> _addInitiative() async {
    final input = await showDialog<_InitiativeInput>(context: context, builder: (_) => const _InitiativeDialog());
    if (!mounted || input == null) return;
    setState(() {
      _initiative.add(_InitiativeEntry(id: DateTime.now().microsecondsSinceEpoch.toString(), name: input.name, initiative: input.initiative, trainer: false));
      _sortInitiative();
    });
  }

  void _removeInitiative(_InitiativeEntry entry) => setState(() {
        _initiative.removeWhere((e) => e.id == entry.id);
        _sortInitiative();
      });

  void _nextTurn() => setState(() {
        if (_initiative.isEmpty) return;
        if (_turnIndex + 1 >= _initiative.length) {
          _turnIndex = 0;
          _round += 1;
          _message = 'Round $_round iniziato.';
        } else {
          _turnIndex += 1;
          _message = null;
        }
      });

  void _nextRound() => setState(() {
        _round += 1;
        _turnIndex = 0;
        _message = 'Round $_round iniziato.';
      });

  void _resetBattle() => setState(() {
        _round = 1;
        _turnIndex = 0;
        _pp.clear();
        _volatileBySlot.clear();
        _message = 'Tracker combattimento azzerato. Gli status volatili sono stati rimossi.';
      });

  int _maxHp(Pokemon pokemon, TeamSlot slot) {
    final level = _level(slot).clamp(1, LevelProgression.maxLevel).toInt();
    final minLevel = pokemon.minLevelFound <= 0 ? 1 : pokemon.minLevelFound;
    final gained = (level - minLevel).clamp(0, LevelProgression.maxLevel).toInt();
    final hitDieAverage = ((pokemon.hitDice + 1) / 2).ceil();
    final constitution = _attributes(pokemon, slot)['CON'] ?? 10;
    final loyalty = slot.loyalty == 2 ? (level / 2).ceil() : slot.loyalty == 3 ? level : 0;
    final tough = slot.feats.contains('Tough') ? level * 2 : 0;
    final hp = pokemon.hitPoints + hitDieAverage * gained + _mod(constitution) * level + tough + loyalty;
    return hp < 1 ? 1 : hp;
  }

  Map<String, int> _attributes(Pokemon pokemon, TeamSlot slot) {
    final custom = slot.customAbilityScores;
    final nature = PokemonNature.forName(slot.nature);
    return {
      'STR': pokemon.attributes.strength + (custom['STR'] ?? 0) + (nature['STR'] ?? 0),
      'DEX': pokemon.attributes.dexterity + (custom['DEX'] ?? 0) + (nature['DEX'] ?? 0),
      'CON': pokemon.attributes.constitution + (custom['CON'] ?? 0) + (nature['CON'] ?? 0),
      'INT': pokemon.attributes.intelligence + (custom['INT'] ?? 0) + (nature['INT'] ?? 0),
      'WIS': pokemon.attributes.wisdom + (custom['WIS'] ?? 0) + (nature['WIS'] ?? 0),
      'CHA': pokemon.attributes.charisma + (custom['CHA'] ?? 0) + (nature['CHA'] ?? 0),
    };
  }

  int _prof(int level) => level >= 17 ? 6 : level >= 13 ? 5 : level >= 9 ? 4 : level >= 5 ? 3 : 2;
  int _moveMod(MoveData move, Pokemon pokemon, TeamSlot slot) {
    final attrs = _attributes(pokemon, slot);
    final mods = move.movePowers.where(attrs.containsKey).map((p) => _mod(attrs[p]!)).toList()..sort();
    return mods.isEmpty ? 0 : mods.last;
  }

  String _moveStats(MoveData move, Pokemon pokemon, TeamSlot slot) {
    final level = _level(slot), mod = _moveMod(move, pokemon, slot), prof = _prof(level);
    final parts = <String>[];
    if (move.isAttack) parts.add('AB ${mod + prof >= 0 ? '+' : ''}${mod + prof}');
    if (move.save != null) parts.add('DC ${8 + prof + mod}');
    final damage = move.damageForLevel(level);
    if (damage != null) parts.add(damage.label);
    if (move.range != '-') parts.add(move.range);
    if (move.duration != '-') parts.add(move.duration);
    return parts.join(' • ');
  }

  String _name(TeamSlot slot, Pokemon pokemon) {
    final nick = slot.nickname?.trim();
    return nick == null || nick.isEmpty ? pokemon.name : nick;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const HomeLeadingButton(), title: const Text('Battle Companion'), actions: [IconButton(tooltip: 'Reset combattimento', onPressed: _resetBattle, icon: const Icon(Icons.refresh))]),
      body: FutureBuilder<_BattleData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return _BattleEmpty(icon: Icons.error_outline, title: 'Errore caricando il combattimento', message: snapshot.error.toString(), actionLabel: 'Riprova', onAction: () => _reload());
          final data = snapshot.data;
          if (data == null || data.occupiedSlots.isEmpty) return _BattleEmpty(icon: Icons.groups_outlined, title: 'Nessun Pokémon in squadra', message: 'Aggiungi almeno un Pokémon alla squadra prima di aprire il tracker.', actionLabel: 'Ricarica', onAction: () => _reload());
          final slot = _activeSlot(data)!;
          final pokemon = _pokemonFor(data, slot)!;
          _ensureInitiative(data, slot, pokemon);
          final moveRefs = _movesFor(slot, pokemon);
          final noPp = _noPpLeft(slot, moveRefs, data.moves);
          final heldItem = data.heldItemFor(slot);
          return RefreshIndicator(
            onRefresh: () => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _BattleHeader(round: _round, profile: data.profile, trainerInitiativeBonus: _trainerInitBonus(data.profile), onNextRound: _nextRound, onReset: _resetBattle),
                const SizedBox(height: 12),
                _PartyBar(slots: data.occupiedSlots, activeSlot: slot, pokemonForSlot: (s) => _pokemonFor(data, s), onSelected: (index) => setState(() { _activeSlotIndex = index; _message = null; })),
                const SizedBox(height: 12),
                _InitiativeTracker(round: _round, entries: _initiative, currentTurnIndex: _turnIndex, trainerInitiativeBonus: _trainerInitBonus(data.profile), onRollTrainer: () => _rerollTrainer(data.profile), onAddEntry: _addInitiative, onRemoveEntry: _removeInitiative, onNextTurn: _nextTurn),
                const SizedBox(height: 12),
                _ActiveCard(pokemon: pokemon, slot: slot, heldItem: heldItem, displayName: _name(slot, pokemon), level: _level(slot), currentHp: _currentHp(slot, pokemon), maxHp: _maxHp(pokemon, slot), nonVolatile: _nonVolatile(slot), volatile: _volatile(slot), message: _message, onMinusFive: () => _changeHp(data, slot, -5), onMinusOne: () => _changeHp(data, slot, -1), onPlusOne: () => _changeHp(data, slot, 1), onPlusFive: () => _changeHp(data, slot, 5), onEditHp: () => _editHp(data, slot), onHeal: () => _healFull(data, slot), onStatus: () => _openStatusPicker(data, slot), onUseHeldBerry: heldItem?.type == 'berry' ? () => _useHeldBerry(data, slot) : null, onOpenBag: () => _openQuickBag(data, slot)),
                const SizedBox(height: 12),
                Text('MOSSE DA COMBATTIMENTO', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                if (noPp) ...[_StruggleWarning(move: data.moves['Struggle']), const SizedBox(height: 8)],
                for (final ref in moveRefs)
                  _MoveCard(reference: ref, move: data.moves[ref], remainingPp: _currentPp(slot, ref, data.moves[ref]), maxPp: _maxPp(data.moves[ref]), stats: data.moves[ref] == null ? null : _moveStats(data.moves[ref]!, pokemon, slot), onUse: () => _changePp(slot, ref, data.moves[ref], -1), onRestore: () => _changePp(slot, ref, data.moves[ref], 1)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BattleData {
  const _BattleData({required this.profile, required this.team, required this.pokemonById, required this.moves, required this.items, required this.inventory});
  final UserProfile profile;
  final List<TeamSlot> team;
  final Map<int, Pokemon> pokemonById;
  final Map<String, MoveData?> moves;
  final List<BagItem> items;
  final List<BagInventoryEntry> inventory;
  List<TeamSlot> get occupiedSlots => team.where((slot) => slot.pokemonId != null && pokemonById[slot.pokemonId] != null).toList(growable: false);
  List<_OwnedBattleItem> get ownedConsumables {
    final owned = <_OwnedBattleItem>[];
    for (final entry in inventory) {
      final item = _itemByRef(entry.itemId);
      if (item != null && (item.type == 'berry' || item.type == 'medicine')) owned.add(_OwnedBattleItem(item: item, quantity: entry.quantity));
    }
    owned.sort((a, b) { final t = _itemTypeLabel(a.item.type).compareTo(_itemTypeLabel(b.item.type)); return t != 0 ? t : a.item.name.compareTo(b.item.name); });
    return owned;
  }
  BagItem? heldItemFor(TeamSlot slot) => slot.heldItem == null || slot.heldItem!.trim().isEmpty ? null : _itemByRef(slot.heldItem!);
  BagItem? _itemByRef(String ref) {
    final key = _itemKey(ref);
    for (final item in items) {
      if (item.id == ref || _itemKey(item.id) == key || _itemKey(item.name) == key) return item;
    }
    return null;
  }
}

class _OwnedBattleItem { const _OwnedBattleItem({required this.item, required this.quantity}); final BagItem item; final int quantity; }
class _MedicineResult { const _MedicineResult({required this.updatedSlot, required this.volatile, required this.message}); final TeamSlot updatedSlot; final List<String> volatile; final String message; }
class _InitiativeEntry { const _InitiativeEntry({required this.id, required this.name, required this.initiative, required this.trainer}); final String id; final String name; final int initiative; final bool trainer; _InitiativeEntry copyWith({String? name, int? initiative}) => _InitiativeEntry(id: id, name: name ?? this.name, initiative: initiative ?? this.initiative, trainer: trainer); }
class _InitiativeInput { const _InitiativeInput({required this.name, required this.initiative}); final String name; final int initiative; }
class _StatusResult { const _StatusResult({required this.nonVolatile, required this.volatile}); final String? nonVolatile; final Set<String> volatile; }
class _StatusInfo { const _StatusInfo(this.shortLabel, this.assetPath); final String shortLabel; final String? assetPath; }

const List<String> _nonVolatileOptions = ['Asleep', 'Burned', 'Frozen', 'Paralyzed', 'Poisoned'];
const List<String> _volatileOptions = ['Confused', 'Flinched'];
const Map<String, _StatusInfo> _statusInfo = {
  'Asleep': _StatusInfo('SLP', 'assets/textures/gui/status/sleep_down.png'),
  'Burned': _StatusInfo('BRN', 'assets/textures/gui/status/burn_down.png'),
  'Confused': _StatusInfo('CNF', 'assets/textures/gui/status/confuse_down.png'),
  'Flinched': _StatusInfo('FLN', null),
  'Frozen': _StatusInfo('FRZ', 'assets/textures/gui/status/frozen_down.png'),
  'Paralyzed': _StatusInfo('PAR', 'assets/textures/gui/status/paralyze_down.png'),
  'Poisoned': _StatusInfo('PSN', 'assets/textures/gui/status/poisoned_down.png'),
  'Badly Poisoned': _StatusInfo('PSN', 'assets/textures/gui/status/poisoned_down.png'),
};
const Set<String> _healingIds = {'potion', 'super-potion', 'hyper-potion', 'max-potion', 'full-restore', 'revive', 'max-revive', 'fresh-water', 'soda-pop', 'berry-juice', 'lemonade', 'moomoo-milk', 'energy-powder', 'energy-root', 'revival-herb'};
const Set<String> _berryMedicineIds = {'cheri-berry', 'chesto-berry', 'pecha-berry', 'rawst-berry', 'aspear-berry', 'persim-berry', 'lum-berry', 'oran-berry', 'sitrus-berry'};
const Set<String> _statusMedicineIds = {'antidote', 'burn-heal', 'ice-heal', 'awakening', 'paralyze-heal', 'full-heal', 'full-restore', 'heal-powder'};
const Map<String, Set<String>> _statusTargets = {
  'cheri-berry': {'Paralyzed'}, 'chesto-berry': {'Asleep'}, 'pecha-berry': {'Poisoned', 'Badly Poisoned'}, 'rawst-berry': {'Burned'}, 'aspear-berry': {'Frozen'}, 'persim-berry': {'Confused'}, 'lum-berry': {'*'},
  'antidote': {'Poisoned', 'Badly Poisoned'}, 'burn-heal': {'Burned'}, 'ice-heal': {'Frozen'}, 'awakening': {'Asleep'}, 'paralyze-heal': {'Paralyzed'}, 'full-heal': {'*'}, 'full-restore': {'*'}, 'heal-powder': {'*'},
};
String _itemKey(String v) => v.trim().toLowerCase().replaceAll(RegExp(r"[’']"), '').replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
String _fallbackStatus(String v) { final n = v.trim().toUpperCase(); return n.length <= 3 ? n : n.substring(0, 3); }
String _itemTypeLabel(String type) { switch (type) { case 'berry': return 'Bacca'; case 'held-item': return 'Strumento tenuto'; case 'medicine': return 'Medicina'; case 'pokeball': return 'Poké Ball'; case 'tm': return 'MT'; default: return type; } }
Color _hpColor(double value) => value <= 0.25 ? Colors.red : value <= 0.5 ? Colors.amber : Colors.green;

class _BattleHeader extends StatelessWidget {
  const _BattleHeader({required this.round, required this.profile, required this.trainerInitiativeBonus, required this.onNextRound, required this.onReset});
  final int round; final UserProfile profile; final int trainerInitiativeBonus; final VoidCallback onNextRound; final VoidCallback onReset;
  @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Row(children: [Expanded(child: Text('Round $round', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900))), Text('INIZ. ${trainerInitiativeBonus >= 0 ? '+' : ''}$trainerInitiativeBonus')]), const SizedBox(height: 4), Text('${profile.name} e il Pokémon usano un unico tiro iniziativa.'), const SizedBox(height: 12), Row(children: [Expanded(child: FilledButton.icon(onPressed: onNextRound, icon: const Icon(Icons.skip_next), label: const Text('NUOVO ROUND'))), const SizedBox(width: 8), Expanded(child: OutlinedButton.icon(onPressed: onReset, icon: const Icon(Icons.refresh), label: const Text('RESET')))]) ])));
}

class _PartyBar extends StatelessWidget {
  const _PartyBar({required this.slots, required this.activeSlot, required this.pokemonForSlot, required this.onSelected});
  final List<TeamSlot> slots; final TeamSlot activeSlot; final Pokemon? Function(TeamSlot) pokemonForSlot; final ValueChanged<int> onSelected;
  @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('SQUADRA', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 8), SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [for (final slot in slots) _PartyButton(slot: slot, pokemon: pokemonForSlot(slot), selected: slot.slotIndex == activeSlot.slotIndex, onTap: () => onSelected(slot.slotIndex))]))])));
}
class _PartyButton extends StatelessWidget {
  const _PartyButton({required this.slot, required this.pokemon, required this.selected, required this.onTap});
  final TeamSlot slot; final Pokemon? pokemon; final bool selected; final VoidCallback onTap;
  @override Widget build(BuildContext context) { final p = pokemon; if (p == null) return const SizedBox.shrink(); final cs = Theme.of(context).colorScheme; final name = slot.nickname?.trim().isNotEmpty == true ? slot.nickname! : p.name; return Padding(padding: const EdgeInsets.only(right: 8), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: DecoratedBox(decoration: BoxDecoration(color: selected ? cs.primaryContainer : cs.surface, border: Border.all(color: selected ? cs.primary : cs.outlineVariant, width: selected ? 2 : 1), borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), child: Column(mainAxisSize: MainAxisSize.min, children: [PokemonAssetImage(pokemon: p, size: 52, formName: slot.formName), const SizedBox(height: 2), SizedBox(width: 72, child: Text(name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800))) ]))))); }
}

class _InitiativeTracker extends StatelessWidget {
  const _InitiativeTracker({required this.round, required this.entries, required this.currentTurnIndex, required this.trainerInitiativeBonus, required this.onRollTrainer, required this.onAddEntry, required this.onRemoveEntry, required this.onNextTurn});
  final int round; final List<_InitiativeEntry> entries; final int currentTurnIndex; final int trainerInitiativeBonus; final VoidCallback onRollTrainer; final VoidCallback onAddEntry; final ValueChanged<_InitiativeEntry> onRemoveEntry; final VoidCallback onNextTurn;
  @override Widget build(BuildContext context) { final current = entries.isEmpty ? null : entries[currentTurnIndex.clamp(0, entries.length - 1).toInt()]; return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Row(children: [Expanded(child: Text('INIZIATIVA', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))), Text('Round $round')]), const SizedBox(height: 4), Text(current == null ? 'Nessun turno impostato.' : 'Turno: ${current.name}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)), const SizedBox(height: 10), Wrap(spacing: 8, runSpacing: 8, children: [FilledButton.icon(onPressed: onNextTurn, icon: const Icon(Icons.navigate_next), label: const Text('PROSSIMO TURNO')), OutlinedButton.icon(onPressed: onRollTrainer, icon: const Icon(Icons.casino_outlined), label: Text('RITIRA TRAINER (${trainerInitiativeBonus >= 0 ? '+' : ''}$trainerInitiativeBonus)')), OutlinedButton.icon(onPressed: onAddEntry, icon: const Icon(Icons.add), label: const Text('AGGIUNGI'))]), const SizedBox(height: 10), for (final indexed in entries.indexed) _InitiativeTile(entry: indexed.$2, active: indexed.$1 == currentTurnIndex, onRemove: indexed.$2.trainer ? null : () => onRemoveEntry(indexed.$2)) ])))); }
}
class _InitiativeTile extends StatelessWidget { const _InitiativeTile({required this.entry, required this.active, required this.onRemove}); final _InitiativeEntry entry; final bool active; final VoidCallback? onRemove; @override Widget build(BuildContext context) { final cs = Theme.of(context).colorScheme; return Padding(padding: const EdgeInsets.only(bottom: 6), child: DecoratedBox(decoration: BoxDecoration(color: active ? cs.primaryContainer : cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)), child: ListTile(dense: true, leading: CircleAvatar(child: Text(entry.initiative.toString())), title: Text(entry.name, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(entry.trainer ? 'Allenatore + Pokémon' : 'Creatura / nemico'), trailing: onRemove == null ? null : IconButton(tooltip: 'Rimuovi', onPressed: onRemove, icon: const Icon(Icons.close))))); } }
class _InitiativeDialog extends StatefulWidget { const _InitiativeDialog(); @override State<_InitiativeDialog> createState() => _InitiativeDialogState(); }
class _InitiativeDialogState extends State<_InitiativeDialog> { final _name = TextEditingController(); final _init = TextEditingController(); @override void dispose() { _name.dispose(); _init.dispose(); super.dispose(); } void _submit() { final name = _name.text.trim(); final initiative = int.tryParse(_init.text.trim()); if (name.isEmpty || initiative == null) return; Navigator.of(context).pop(_InitiativeInput(name: name, initiative: initiative)); } @override Widget build(BuildContext context) => AlertDialog(title: const Text('Aggiungi iniziativa'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: _name, autofocus: true, decoration: const InputDecoration(labelText: 'Nome creatura'), onSubmitted: (_) => _submit()), const SizedBox(height: 10), TextField(controller: _init, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Iniziativa'), onSubmitted: (_) => _submit())]), actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annulla')), FilledButton(onPressed: _submit, child: const Text('Aggiungi'))]); }

class _ActiveCard extends StatelessWidget {
  const _ActiveCard({required this.pokemon, required this.slot, required this.heldItem, required this.displayName, required this.level, required this.currentHp, required this.maxHp, required this.nonVolatile, required this.volatile, required this.message, required this.onMinusFive, required this.onMinusOne, required this.onPlusOne, required this.onPlusFive, required this.onEditHp, required this.onHeal, required this.onStatus, required this.onUseHeldBerry, required this.onOpenBag});
  final Pokemon pokemon; final TeamSlot slot; final BagItem? heldItem; final String displayName; final int level; final int currentHp; final int maxHp; final String? nonVolatile; final Set<String> volatile; final String? message; final VoidCallback onMinusFive; final VoidCallback onMinusOne; final VoidCallback onPlusOne; final VoidCallback onPlusFive; final VoidCallback onEditHp; final VoidCallback onHeal; final VoidCallback onStatus; final VoidCallback? onUseHeldBerry; final VoidCallback onOpenBag;
  @override Widget build(BuildContext context) { final hp = maxHp <= 0 ? 0.0 : (currentHp / maxHp).clamp(0.0, 1.0).toDouble(); return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Row(children: [PokemonAssetImage(pokemon: pokemon, useLargeArtwork: true, size: 96, formName: slot.formName), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(displayName.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text('#${pokemon.id.toString().padLeft(3, '0')}  |  Lv. $level'), const SizedBox(height: 6), Wrap(spacing: 6, runSpacing: 4, children: [for (final type in pokemon.types) PokemonTypeBadge(type: type, height: 20)])]))]), const SizedBox(height: 12), InkWell(onTap: onEditHp, borderRadius: BorderRadius.circular(8), child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [Text('HP $currentHp/$maxHp', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(width: 12), Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: hp, minHeight: 16, valueColor: AlwaysStoppedAnimation<Color>(_hpColor(hp)), backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest)))]))), const SizedBox(height: 10), Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: [_SmallButton(label: '-5', onTap: onMinusFive), _SmallButton(label: '-1', onTap: onMinusOne), _SmallButton(label: '+1', onTap: onPlusOne), _SmallButton(label: '+5', onTap: onPlusFive), FilledButton(onPressed: onHeal, child: const Text('POKÉMON CENTER'))]), const SizedBox(height: 10), _StatusPanel(nonVolatile: nonVolatile, volatile: volatile, onTap: onStatus), const SizedBox(height: 10), _HeldItemPanel(item: heldItem, onUseHeldBerry: onUseHeldBerry, onOpenBag: onOpenBag), if (message != null) ...[const SizedBox(height: 10), _InlineMessage(message: message!)] ]))); }
}

class _StatusPanel extends StatelessWidget { const _StatusPanel({required this.nonVolatile, required this.volatile, required this.onTap}); final String? nonVolatile; final Set<String> volatile; final VoidCallback onTap; @override Widget build(BuildContext context) { final has = nonVolatile != null || volatile.isNotEmpty; return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10), child: DecoratedBox(decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.outlineVariant), borderRadius: BorderRadius.circular(10)), child: Padding(padding: const EdgeInsets.all(10), child: has ? Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [const Text('STATUS:'), if (nonVolatile != null) _StatusChip(status: nonVolatile!, prefix: 'NON-VOLATILE'), for (final status in volatile) _StatusChip(status: status, prefix: 'VOLATILE')]) : const Text('STATUS: nessuno')))); } }
class _StatusSheet extends StatefulWidget { const _StatusSheet({required this.nonVolatile, required this.volatile}); final String? nonVolatile; final Set<String> volatile; @override State<_StatusSheet> createState() => _StatusSheetState(); }
class _StatusSheetState extends State<_StatusSheet> { String? _nonVolatile; late Set<String> _volatile; @override void initState() { super.initState(); _nonVolatile = widget.nonVolatile; _volatile = {...widget.volatile}; } @override Widget build(BuildContext context) => SafeArea(child: ListView(shrinkWrap: true, padding: const EdgeInsets.only(bottom: 12), children: [Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 4), child: Text('STATUS IN COMBATTIMENTO', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))), const Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 8), child: Text('Un solo status non-volatile alla volta. Gli status volatili terminano fuori dal combattimento.')), Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 4), child: Text('NON-VOLATILE', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900))), RadioListTile<String>(title: const Text('NESSUNO'), value: '', groupValue: _nonVolatile ?? '', onChanged: (_) => setState(() => _nonVolatile = null)), for (final status in _nonVolatileOptions) RadioListTile<String>(secondary: _StatusIcon(status: status, size: 28), title: Text(status.toUpperCase()), value: status, groupValue: _nonVolatile ?? '', onChanged: (value) => setState(() => _nonVolatile = value)), const Divider(), Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 4), child: Text('VOLATILE', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900))), for (final status in _volatileOptions) CheckboxListTile(secondary: _StatusIcon(status: status, size: 28), title: Text(status.toUpperCase()), value: _volatile.contains(status), onChanged: (value) => setState(() => value == true ? _volatile.add(status) : _volatile.remove(status))), const Divider(), ListTile(leading: const Icon(Icons.save_outlined), title: const Text('SALVA STATUS'), onTap: () => Navigator.of(context).pop(_StatusResult(nonVolatile: _nonVolatile, volatile: _volatile))), if (_nonVolatile != null || _volatile.isNotEmpty) ListTile(leading: const Icon(Icons.clear), title: const Text('RIMUOVI TUTTI'), onTap: () => Navigator.of(context).pop(const _StatusResult(nonVolatile: null, volatile: <String>{}))) ])); }

class _HeldItemPanel extends StatelessWidget { const _HeldItemPanel({required this.item, required this.onUseHeldBerry, required this.onOpenBag}); final BagItem? item; final VoidCallback? onUseHeldBerry; final VoidCallback onOpenBag; @override Widget build(BuildContext context) { final item = this.item; return DecoratedBox(decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.outlineVariant), borderRadius: BorderRadius.circular(10)), child: Padding(padding: const EdgeInsets.all(10), child: Row(children: [if (item == null) const Icon(Icons.inventory_2_outlined) else _ItemSprite(item: item, size: 36), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item == null ? 'ITEM: NONE' : 'ITEM: ${item.name.toUpperCase()}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)), Text(item == null ? 'Apri lo zaino rapido per usare un consumabile.' : item.type == 'berry' ? 'Bacca tenuta: puoi consumarla subito in combattimento.' : 'Strumento tenuto: ${_itemTypeLabel(item.type)}.', maxLines: 2, overflow: TextOverflow.ellipsis)])), const SizedBox(width: 8), if (item?.type == 'berry') OutlinedButton(onPressed: onUseHeldBerry, child: const Text('USA')), const SizedBox(width: 6), FilledButton(onPressed: onOpenBag, child: const Text('ZAINO'))]))); } }
class _QuickBagSheet extends StatelessWidget { const _QuickBagSheet({required this.items, required this.pokemonName, required this.currentHp, required this.maxHp, required this.nonVolatile, required this.volatile}); final List<_OwnedBattleItem> items; final String pokemonName; final int currentHp; final int maxHp; final String? nonVolatile; final Set<String> volatile; @override Widget build(BuildContext context) { final statusParts = [if (nonVolatile != null) nonVolatile!, ...volatile]; final statusText = statusParts.isEmpty ? 'nessuno status' : statusParts.join(', '); return SafeArea(child: SizedBox(height: MediaQuery.of(context).size.height * 0.78, child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 18), children: [Text('Zaino rapido', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text('$pokemonName • HP $currentHp/$maxHp • $statusText'), const SizedBox(height: 12), for (final entry in items) Card(child: ListTile(leading: _ItemSprite(item: entry.item, size: 42), title: Text(entry.item.name, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('${_itemTypeLabel(entry.item.type)} • x${entry.quantity}\n${entry.item.displayDescription}', maxLines: 3, overflow: TextOverflow.ellipsis), trailing: const Text('USA'), onTap: () => Navigator.of(context).pop(entry))) ]))); } }

class _MoveCard extends StatelessWidget { const _MoveCard({required this.reference, required this.move, required this.remainingPp, required this.maxPp, required this.stats, required this.onUse, required this.onRestore}); final String reference; final MoveData? move; final int remainingPp; final int maxPp; final String? stats; final VoidCallback onUse; final VoidCallback onRestore; @override Widget build(BuildContext context) { final move = this.move; final title = move?.name ?? reference; final canTrack = maxPp > 0; return Card(child: ExpansionTile(tilePadding: const EdgeInsets.fromLTRB(16, 8, 8, 8), title: Row(children: [Expanded(child: Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900))), if (canTrack) _PpBadge(remainingPp: remainingPp, maxPp: maxPp)]), subtitle: Padding(padding: const EdgeInsets.only(top: 6), child: Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [if (move != null) PokemonTypeBadge(type: move.type, height: 18), if (stats != null && stats!.isNotEmpty) Text(stats!)])), trailing: canTrack ? Row(mainAxisSize: MainAxisSize.min, children: [IconButton(tooltip: 'Recupera PP', onPressed: remainingPp >= maxPp ? null : onRestore, icon: const Icon(Icons.add)), IconButton(tooltip: 'Usa mossa', onPressed: remainingPp <= 0 ? null : onUse, icon: const Icon(Icons.remove))]) : null, childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14), children: [if (move == null) const Text('Dettagli mossa non disponibili.') else ...[Align(alignment: Alignment.centerLeft, child: Text('Tempo: ${move.moveTime}  |  Durata: ${move.duration}')), const SizedBox(height: 8), Align(alignment: Alignment.centerLeft, child: Text(move.description))]])); } }
class _PpBadge extends StatelessWidget { const _PpBadge({required this.remainingPp, required this.maxPp}); final int remainingPp; final int maxPp; @override Widget build(BuildContext context) { final cs = Theme.of(context).colorScheme; final progress = maxPp <= 0 ? 0.0 : remainingPp / maxPp; final bg = remainingPp <= 0 ? cs.errorContainer : progress <= 0.33 ? Colors.amber.shade200 : cs.primaryContainer; final fg = remainingPp <= 0 ? cs.onErrorContainer : progress <= 0.33 ? Colors.black87 : cs.onPrimaryContainer; return DecoratedBox(decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), child: Text('PP $remainingPp/$maxPp', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w900)))); } }

class _StatusChip extends StatelessWidget { const _StatusChip({required this.status, required this.prefix}); final String status; final String prefix; @override Widget build(BuildContext context) => Chip(avatar: _StatusIcon(status: status, size: 22), label: Text('$prefix: ${status.toUpperCase()}')); }
class _StatusIcon extends StatelessWidget { const _StatusIcon({required this.status, required this.size}); final String status; final double size; @override Widget build(BuildContext context) { final info = _statusInfo[status]; final asset = info?.assetPath; final fallback = info?.shortLabel ?? _fallbackStatus(status); if (asset == null) return _StatusFallback(label: fallback, size: size); return SizedBox(width: size, height: size, child: Image.asset(asset, fit: BoxFit.contain, filterQuality: FilterQuality.none, errorBuilder: (_, __, ___) => _StatusFallback(label: fallback, size: size))); } }
class _StatusFallback extends StatelessWidget { const _StatusFallback({required this.label, required this.size}); final String label; final double size; @override Widget build(BuildContext context) => CircleAvatar(radius: size / 2, child: Text(label, style: TextStyle(fontSize: size * 0.32, fontWeight: FontWeight.w900))); }
class _ItemSprite extends StatelessWidget { const _ItemSprite({required this.item, this.size = 42}); final BagItem item; final double size; @override Widget build(BuildContext context) { final url = item.remoteSpriteUrl; if (url == null) return Icon(Icons.inventory_2_outlined, size: size); return SizedBox(width: size, height: size, child: Image.network(url, fit: BoxFit.contain, filterQuality: FilterQuality.none, loadingBuilder: (context, child, progress) => progress == null ? child : Icon(Icons.inventory_2_outlined, size: size), errorBuilder: (_, __, ___) => Icon(Icons.inventory_2_outlined, size: size))); } }
class _HpDialog extends StatefulWidget { const _HpDialog({required this.currentHp, required this.maxHp}); final int currentHp; final int maxHp; @override State<_HpDialog> createState() => _HpDialogState(); }
class _HpDialogState extends State<_HpDialog> { final _controller = TextEditingController(); @override void dispose() { _controller.dispose(); super.dispose(); } @override Widget build(BuildContext context) => AlertDialog(title: const Text('Modifica HP'), content: TextField(controller: _controller, autofocus: true, keyboardType: const TextInputType.numberWithOptions(signed: true), decoration: InputDecoration(labelText: 'HP o modifica', helperText: 'Esempi: -12, +8 oppure 35. Attuali ${widget.currentHp}/${widget.maxHp}'), onSubmitted: (value) => Navigator.of(context).pop(value)), actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annulla')), FilledButton(onPressed: () => Navigator.of(context).pop(_controller.text), child: const Text('Salva'))]); }
class _StruggleWarning extends StatelessWidget { const _StruggleWarning({required this.move}); final MoveData? move; @override Widget build(BuildContext context) => Card(color: Theme.of(context).colorScheme.errorContainer, child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('STRUGGLE DISPONIBILE', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onErrorContainer, fontWeight: FontWeight.w900)), const SizedBox(height: 6), Text(move?.description ?? 'Tutti i PP delle mosse tracciabili sono a zero. Usa Struggle.', style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer))]))); }
class _SmallButton extends StatelessWidget { const _SmallButton({required this.label, required this.onTap}); final String label; final VoidCallback onTap; @override Widget build(BuildContext context) => OutlinedButton(onPressed: onTap, child: Text(label)); }
class _InlineMessage extends StatelessWidget { const _InlineMessage({required this.message}); final String message; @override Widget build(BuildContext context) { final cs = Theme.of(context).colorScheme; return DecoratedBox(decoration: BoxDecoration(color: cs.secondaryContainer, borderRadius: BorderRadius.circular(10)), child: Padding(padding: const EdgeInsets.all(10), child: Text(message, style: TextStyle(color: cs.onSecondaryContainer)))); } }
class _BattleEmpty extends StatelessWidget { const _BattleEmpty({required this.icon, required this.title, required this.message, required this.actionLabel, required this.onAction}); final IconData icon; final String title; final String message; final String actionLabel; final VoidCallback onAction; @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 56), const SizedBox(height: 16), Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 8), Text(message, textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton(onPressed: onAction, child: Text(actionLabel))]))); }
