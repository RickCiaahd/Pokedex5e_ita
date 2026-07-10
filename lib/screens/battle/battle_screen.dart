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
  final Random _random = Random();

  late Future<_BattleData> _future;
  final Map<int, Map<String, int>> _remainingPpBySlot = {};
  final Map<int, Set<String>> _volatileStatusesBySlot = {};
  final List<_InitiativeEntry> _initiativeEntries = [];

  int? _activeSlotIndex;
  int _round = 1;
  int _turnIndex = 0;
  String? _message;

  @override
  void initState() {
    super.initState();
    _future = _loadBattleData();
  }

  Future<_BattleData> _loadBattleData() async {
    final profile = await _profileRepository.getActiveProfile();
    final team = await _teamRepository.getTeam(profile.id);
    team.sort((a, b) => a.slotIndex.compareTo(b.slotIndex));

    final pokemonList = await _pokemonRepository.getAllPokemon();
    final pokemonById = {
      for (final pokemon in pokemonList) pokemon.id: pokemon,
    };
    final items = await _itemRepository.getWebItems();
    final inventory = await _bagRepository.getInventory(profile.id);
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
      inventory: inventory,
    );
  }

  Future<void> _reload({String? message}) async {
    if (!mounted) return;
    setState(() {
      _message = message;
      _future = _loadBattleData();
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
    return data.pokemonById[pokemonId]?.resolveVariant(
      formName: slot.formName,
      gender: slot.gender,
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
    final trackableMoves = moveReferences
        .where((reference) => _maxPpFor(moves[reference]) > 0)
        .toList(growable: false);

    return trackableMoves.isNotEmpty &&
        trackableMoves.every((reference) {
          return _remainingPp(slot, reference, moves[reference]) <= 0;
        });
  }

  int _currentHpFor(TeamSlot slot, Pokemon pokemon) {
    return slot.currentHp.clamp(0, _maxHpFor(pokemon, slot)).toInt();
  }

  Future<void> _changeHp(_BattleData data, TeamSlot slot, int delta) async {
    final pokemon = _pokemonForSlot(data, slot);
    if (pokemon == null) return;

    final maxHp = _maxHpFor(pokemon, slot);
    final updatedHp = (_currentHpFor(slot, pokemon) + delta)
        .clamp(0, maxHp)
        .toInt();

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
    await _teamRepository.updateSlot(
      profileId: data.profile.id,
      updatedSlot: slot.copyWith(
        currentHp: _maxHpFor(pokemon, slot),
        statusEffects: const [],
      ),
    );
    await _reload(
      message: '${_displayName(slot, pokemon)} è pronto a combattere.',
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
    await _reload(
      message:
          result?.message ??
          '${heldItem.name} è stata consumata. Applica manualmente il suo effetto se necessario.',
    );
  }

  Future<void> _openQuickBag(_BattleData data, TeamSlot slot) async {
    final pokemon = _pokemonForSlot(data, slot);
    if (pokemon == null) return;

    final items = data.ownedQuickItems;
    if (items.isEmpty) {
      await _reload(message: 'Non hai consumabili o Poké Ball nello zaino.');
      return;
    }

    final selected = await showModalBottomSheet<_OwnedBattleItem>(
      context: context,
      isScrollControlled: true,
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
  }

  Future<void> _useBattleItem(
    _BattleData data,
    TeamSlot slot,
    Pokemon pokemon,
    _OwnedBattleItem selected,
  ) async {
    final item = selected.item;

    if (item.type == 'pokeball') {
      await _throwPokeball(data, item);
      return;
    }

    final isBerry = item.type == 'berry';
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
      await _reload(message: 'Non hai più ${item.name} nello zaino.');
      return;
    }

    if (result != null) {
      await _teamRepository.updateSlot(
        profileId: data.profile.id,
        updatedSlot: result.updatedSlot,
      );
      _volatileStatusesBySlot[slot.slotIndex] = result.volatileStatuses;
      await _reload(message: result.message);
      return;
    }

    await _reload(
      message:
          '${item.name} è stata consumata. Applica manualmente il suo effetto se necessario.',
    );
  }

  Future<void> _throwPokeball(_BattleData data, BagItem ball) async {
    final caught = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Lancia ${ball.name}?'),
        content: const Text(
          'Dopo il tiro, inserisci l’esito comunicato dal Master. La Poké Ball verrà consumata in ogni caso.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('NO, FALLITA'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('SÌ, CATTURATO'),
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
      await _reload(message: 'Non hai più ${ball.name} nello zaino.');
      return;
    }

    if (!caught) {
      await _reload(message: '${ball.name} consumata. Cattura fallita.');
      return;
    }

    await _reload(
      message: '${ball.name} consumata. Registra il Pokémon catturato.',
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
      message: '${_displayName(slot, pokemon)} $effects usando ${item.name}.',
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
      showDragHandle: true,
      builder: (_) => _StatusPickerSheet(
        initialNonVolatileStatus: _nonVolatileStatusFor(slot),
        initialVolatileStatuses: _volatileStatusesFor(slot),
      ),
    );
    if (!mounted || result == null) return;

    _volatileStatusesBySlot[slot.slotIndex] = result.volatileStatuses;
    await _teamRepository.updateSlot(
      profileId: data.profile.id,
      updatedSlot: slot.copyWith(
        statusEffects: result.nonVolatileStatus == null
            ? const []
            : [result.nonVolatileStatus!],
      ),
    );
    await _reload();
  }

  void _ensureInitiative(_BattleData data, TeamSlot slot, Pokemon pokemon) {
    final label = '${data.profile.name} + ${_displayName(slot, pokemon)}';
    final index = _initiativeEntries.indexWhere(
      (entry) => entry.isTrainerGroup,
    );

    if (index == -1) {
      _initiativeEntries.add(
        _InitiativeEntry(
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

  void _rerollTrainerInitiative(UserProfile profile) {
    setState(() {
      final index = _initiativeEntries.indexWhere(
        (entry) => entry.isTrainerGroup,
      );
      final roll = _rollTrainerInitiative(profile);
      if (index == -1) {
        _initiativeEntries.add(
          _InitiativeEntry(
            id: 'trainer',
            name: '${profile.name} + Pokémon',
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
      _message = 'Iniziativa allenatore/Pokémon: $roll.';
    });
  }

  Future<void> _addInitiativeEntry() async {
    final input = await showDialog<_InitiativeEntryInput>(
      context: context,
      builder: (_) => const _InitiativeEntryDialog(),
    );
    if (!mounted || input == null) return;

    setState(() {
      _initiativeEntries.add(
        _InitiativeEntry(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: input.name,
          initiative: input.initiative,
          isTrainerGroup: false,
        ),
      );
      _sortInitiative();
    });
  }

  void _removeInitiativeEntry(_InitiativeEntry entry) {
    setState(() {
      _initiativeEntries.removeWhere((candidate) => candidate.id == entry.id);
      _sortInitiative();
    });
  }

  void _nextTurn() {
    setState(() {
      if (_initiativeEntries.isEmpty) return;
      if (_turnIndex + 1 >= _initiativeEntries.length) {
        _turnIndex = 0;
        _round += 1;
        _message = 'Round $_round iniziato.';
      } else {
        _turnIndex += 1;
        _message = null;
      }
    });
  }

  void _nextRound() {
    setState(() {
      _round += 1;
      _turnIndex = 0;
      _message = 'Round $_round iniziato.';
    });
  }

  void _resetBattle() {
    setState(() {
      _round = 1;
      _turnIndex = 0;
      _remainingPpBySlot.clear();
      _volatileStatusesBySlot.clear();
      _message =
          'Tracker combattimento azzerato. Gli status volatili sono stati rimossi.';
    });
  }

  int _maxHpFor(Pokemon pokemon, TeamSlot slot) {
    final level = _levelForSlot(
      slot,
    ).clamp(1, LevelProgression.maxLevel).toInt();
    final minimumLevel = pokemon.minLevelFound <= 0 ? 1 : pokemon.minLevelFound;
    final levelsGained = (level - minimumLevel)
        .clamp(0, LevelProgression.maxLevel)
        .toInt();
    final hitDieAverage = ((pokemon.hitDice + 1) / 2).ceil();
    final attributes = _attributeScores(pokemon, slot);
    final constitutionModifier = _modifier(attributes['CON'] ?? 10);
    final toughBonus = slot.feats.contains('Tough') ? level * 2 : 0;
    final loyaltyBonus = slot.loyalty == 2
        ? (level / 2).ceil()
        : slot.loyalty == 3
        ? level
        : 0;
    final hp =
        pokemon.hitPoints +
        (hitDieAverage * levelsGained) +
        (constitutionModifier * level) +
        toughBonus +
        loyaltyBonus;

    return hp < 1 ? 1 : hp;
  }

  Map<String, int> _attributeScores(Pokemon pokemon, TeamSlot slot) {
    final custom = slot.customAbilityScores;
    final nature = PokemonNature.forName(slot.nature);

    return {
      'STR':
          pokemon.attributes.strength +
          (custom['STR'] ?? 0) +
          (nature['STR'] ?? 0),
      'DEX':
          pokemon.attributes.dexterity +
          (custom['DEX'] ?? 0) +
          (nature['DEX'] ?? 0),
      'CON':
          pokemon.attributes.constitution +
          (custom['CON'] ?? 0) +
          (nature['CON'] ?? 0),
      'INT':
          pokemon.attributes.intelligence +
          (custom['INT'] ?? 0) +
          (nature['INT'] ?? 0),
      'WIS':
          pokemon.attributes.wisdom +
          (custom['WIS'] ?? 0) +
          (nature['WIS'] ?? 0),
      'CHA':
          pokemon.attributes.charisma +
          (custom['CHA'] ?? 0) +
          (nature['CHA'] ?? 0),
    };
  }

  int _proficiency(int level) {
    if (level >= 17) return 6;
    if (level >= 13) return 5;
    if (level >= 9) return 4;
    if (level >= 5) return 3;
    return 2;
  }

  int _bestMoveModifier(MoveData move, Pokemon pokemon, TeamSlot slot) {
    final attributes = _attributeScores(pokemon, slot);
    final modifiers =
        move.movePowers
            .where(attributes.containsKey)
            .map((power) => _modifier(attributes[power]!))
            .toList()
          ..sort();

    return modifiers.isEmpty ? 0 : modifiers.last;
  }

  String _moveStats(MoveData move, Pokemon pokemon, TeamSlot slot) {
    final level = _levelForSlot(slot);
    final moveModifier = _bestMoveModifier(move, pokemon, slot);
    final proficiency = _proficiency(level);
    final parts = <String>[];

    if (move.isAttack) {
      final attackBonus = moveModifier + proficiency;
      parts.add('AB ${attackBonus >= 0 ? '+' : ''}$attackBonus');
    }
    if (move.save != null) parts.add('DC ${8 + proficiency + moveModifier}');

    final damage = move.damageForLevel(level);
    if (damage != null) parts.add(damage.label);
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
        future: _future,
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
          _ensureInitiative(data, activeSlot, pokemon);

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
                  trainerInitiativeBonus: _trainerInitiativeBonus(data.profile),
                  onNextRound: _nextRound,
                  onReset: _resetBattle,
                ),
                const SizedBox(height: 12),
                _PartyBar(
                  slots: data.occupiedSlots,
                  activeSlot: activeSlot,
                  pokemonForSlot: (slot) => _pokemonForSlot(data, slot),
                  onSelected: (slotIndex) {
                    setState(() {
                      _activeSlotIndex = slotIndex;
                      _message = null;
                    });
                  },
                ),
                const SizedBox(height: 12),
                _InitiativeTracker(
                  round: _round,
                  entries: _initiativeEntries,
                  currentTurnIndex: _turnIndex,
                  trainerInitiativeBonus: _trainerInitiativeBonus(data.profile),
                  onRollTrainer: () => _rerollTrainerInitiative(data.profile),
                  onAddEntry: _addInitiativeEntry,
                  onRemoveEntry: _removeInitiativeEntry,
                  onNextTurn: _nextTurn,
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
                  nonVolatileStatus: _nonVolatileStatusFor(activeSlot),
                  volatileStatuses: _volatileStatusesFor(activeSlot),
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
                  onOpenBag: () => _openQuickBag(data, activeSlot),
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
                  _MoveCard(
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
                        : _moveStats(
                            data.moves[reference]!,
                            pokemon,
                            activeSlot,
                          ),
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

  List<_OwnedBattleItem> get ownedQuickItems {
    final owned = <_OwnedBattleItem>[];
    for (final entry in inventory) {
      final item = _itemByReference(entry.itemId);
      if (item == null) continue;
      if (item.type == 'berry' ||
          item.type == 'medicine' ||
          item.type == 'pokeball') {
        owned.add(_OwnedBattleItem(item: item, quantity: entry.quantity));
      }
    }

    owned.sort((a, b) {
      final typeCompare = _itemTypeLabel(
        a.item.type,
      ).compareTo(_itemTypeLabel(b.item.type));
      if (typeCompare != 0) return typeCompare;
      return a.item.name.compareTo(b.item.name);
    });
    return owned;
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

class _OwnedBattleItem {
  const _OwnedBattleItem({required this.item, required this.quantity});

  final BagItem item;
  final int quantity;
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

class _InitiativeEntry {
  const _InitiativeEntry({
    required this.id,
    required this.name,
    required this.initiative,
    required this.isTrainerGroup,
  });

  final String id;
  final String name;
  final int initiative;
  final bool isTrainerGroup;

  _InitiativeEntry copyWith({String? name, int? initiative}) {
    return _InitiativeEntry(
      id: id,
      name: name ?? this.name,
      initiative: initiative ?? this.initiative,
      isTrainerGroup: isTrainerGroup,
    );
  }
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

String _quickItemActionLabel(String type) {
  return type == 'pokeball' ? 'LANCIA' : 'USA';
}

String _quickItemDescription(BagItem item) {
  if (item.type == 'pokeball') {
    return 'Lancia la Poké Ball. Dopo la risposta del Master verrà consumata.';
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
    required this.onReset,
  });

  final int round;
  final UserProfile profile;
  final int trainerInitiativeBonus;
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
                Text(
                  'INIZ. ${trainerInitiativeBonus >= 0 ? '+' : ''}$trainerInitiativeBonus',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${profile.name} e il Pokémon usano un unico tiro iniziativa.',
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
                    label: const Text('RESET'),
                  ),
                ),
              ],
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
    required this.onSelected,
  });

  final List<TeamSlot> slots;
  final TeamSlot activeSlot;
  final Pokemon? Function(TeamSlot slot) pokemonForSlot;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SQUADRA',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final slot in slots)
                    _PartyPokemonButton(
                      slot: slot,
                      pokemon: pokemonForSlot(slot),
                      selected: slot.slotIndex == activeSlot.slotIndex,
                      onTap: () => onSelected(slot.slotIndex),
                    ),
                ],
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
    required this.selected,
    required this.onTap,
  });

  final TeamSlot slot;
  final Pokemon? pokemon;
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
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PokemonAssetImage(
                  pokemon: pokemon,
                  size: 52,
                  formName: slot.formName,
                  gender: slot.gender,
                  isShiny: slot.isShiny,
                ),
                const SizedBox(height: 2),
                SizedBox(
                  width: 72,
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
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
  final List<_InitiativeEntry> entries;
  final int currentTurnIndex;
  final int trainerInitiativeBonus;
  final VoidCallback onRollTrainer;
  final VoidCallback onAddEntry;
  final ValueChanged<_InitiativeEntry> onRemoveEntry;
  final VoidCallback onNextTurn;

  @override
  Widget build(BuildContext context) {
    final currentEntry = entries.isEmpty
        ? null
        : entries[currentTurnIndex.clamp(0, entries.length - 1).toInt()];

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
                    'INIZIATIVA',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text('Round $round'),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              currentEntry == null
                  ? 'Nessun turno impostato.'
                  : 'Turno: ${currentEntry.name}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onNextTurn,
                  icon: const Icon(Icons.navigate_next),
                  label: const Text('PROSSIMO TURNO'),
                ),
                OutlinedButton.icon(
                  onPressed: onRollTrainer,
                  icon: const Icon(Icons.casino_outlined),
                  label: Text(
                    'RITIRA TRAINER (${trainerInitiativeBonus >= 0 ? '+' : ''}$trainerInitiativeBonus)',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onAddEntry,
                  icon: const Icon(Icons.add),
                  label: const Text('AGGIUNGI'),
                ),
              ],
            ),
            const SizedBox(height: 10),
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

  final _InitiativeEntry entry;
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
                ? 'Allenatore + Pokémon'
                : 'Creatura / avversario',
          ),
          trailing: onRemove == null
              ? null
              : IconButton(
                  tooltip: 'Rimuovi',
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
      title: const Text('Aggiungi iniziativa'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nome creatura'),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _initiativeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Iniziativa'),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Aggiungi')),
      ],
    );
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
  });

  final Pokemon pokemon;
  final TeamSlot slot;
  final BagItem? heldItem;
  final String displayName;
  final int level;
  final int currentHp;
  final int maxHp;
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
                  gender: slot.gender,
                  isShiny: slot.isShiny,
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
                  child: const Text('POKÉMON CENTER'),
                ),
              ],
            ),
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
                    const Text('STATUS:'),
                    if (nonVolatileStatus != null)
                      _StatusChip(
                        status: nonVolatileStatus!,
                        prefix: 'NON-VOLATILE',
                      ),
                    for (final status in volatileStatuses)
                      _StatusChip(status: status, prefix: 'VOLATILE'),
                  ],
                )
              : const Text('STATUS: nessuno'),
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
              'STATUS IN COMBATTIMENTO',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Un solo status non-volatile alla volta. Gli status volatili terminano fuori dal combattimento.',
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
                  label: const Text('NESSUNO'),
                  selected: _nonVolatileStatus == null,
                  onSelected: (_) => setState(() => _nonVolatileStatus = null),
                ),
                for (final status in _nonVolatileStatusOptions)
                  ChoiceChip(
                    avatar: _StatusIcon(status: status, size: 22),
                    label: Text(status.toUpperCase()),
                    selected: _nonVolatileStatus == status,
                    onSelected: (_) =>
                        setState(() => _nonVolatileStatus = status),
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
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _volatileStatuses.add(status);
                  } else {
                    _volatileStatuses.remove(status);
                  }
                });
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.save_outlined),
            title: const Text('SALVA STATUS'),
            onTap: () => Navigator.of(context).pop(
              _StatusPickerResult(
                nonVolatileStatus: _nonVolatileStatus,
                volatileStatuses: _volatileStatuses,
              ),
            ),
          ),
          if (_nonVolatileStatus != null || _volatileStatuses.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.clear),
              title: const Text('RIMUOVI TUTTI'),
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
                        ? 'Apri lo zaino rapido per usare un consumabile o lanciare una Poké Ball.'
                        : item.type == 'berry'
                        ? 'Bacca tenuta: puoi consumarla subito in combattimento.'
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
            FilledButton(onPressed: onOpenBag, child: const Text('ZAINO')),
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

  final List<_OwnedBattleItem> items;
  final String pokemonName;
  final int currentHp;
  final int maxHp;
  final String? nonVolatileStatus;
  final Set<String> volatileStatuses;

  @override
  Widget build(BuildContext context) {
    final statusParts = [?nonVolatileStatus, ...volatileStatuses];
    final statusText = statusParts.isEmpty
        ? 'nessuno status'
        : statusParts.join(', ');

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.78,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          children: [
            Text(
              'Zaino rapido',
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
                  trailing: Text(_quickItemActionLabel(entry.item.type)),
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
              child: Text(
                'Tempo: ${move.moveTime}  |  Durata: ${move.duration}',
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
      title: const Text('Modifica HP'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(signed: true),
        decoration: InputDecoration(
          labelText: 'HP o modifica',
          helperText:
              'Esempi: -12, +8 oppure 35. Attuali ${widget.currentHp}/${widget.maxHp}',
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
