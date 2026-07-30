// ignore_for_file: use_build_context_synchronously

import 'dart:math';

import 'package:flutter/material.dart';

import '../../localization/ui_text.dart';
import '../../localization/user_facing_error.dart';

import '../../models/bag_inventory_entry.dart';
import '../../models/bag_item.dart';
import '../../models/level_progression.dart';
import '../../models/move_data.dart';
import '../../models/pokemon.dart';
import '../../models/team_slot.dart';
import '../../models/user_profile.dart';
import '../../repositories/bag_inventory_repository.dart';
import '../../repositories/item_repository.dart';
import '../../repositories/move_repository.dart';
import '../../repositories/pokemon_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/team_repository.dart';
import '../../repositories/tm_repository.dart';
import '../../services/trainer_path_passive_service.dart';
import '../../widgets/layout/responsive_content.dart';
import '../../widgets/navigation/home_leading_button.dart';
import '../../widgets/pokemon/pokemon_asset_image.dart';

class BagScreen extends StatefulWidget {
  const BagScreen({super.key});

  @override
  State<BagScreen> createState() => _BagScreenState();
}

class _BagScreenState extends State<BagScreen> {
  final ItemRepository _itemRepository = ItemRepository();
  final ProfileRepository _profileRepository = ProfileRepository();
  final BagInventoryRepository _bagRepository = BagInventoryRepository();
  final MoveRepository _moveRepository = MoveRepository();
  final PokemonRepository _pokemonRepository = PokemonRepository();
  final TeamRepository _teamRepository = TeamRepository();
  final TmRepository _tmRepository = TmRepository();
  final Random _random = Random();

  late Future<_BagData> _dataFuture;
  String? _selectedType;
  String? _message;
  UserProfile? _activeProfile;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadBagData();
  }

  Future<_BagData> _loadBagData() async {
    final profile = await _profileRepository.getActiveProfile();
    _activeProfile = profile;
    final catalog = await _itemRepository.getWebItems();
    final inventory = await _bagRepository.getInventory(profile.id);
    final team = await _teamRepository.getTeam(profile.id);
    final pokemonList = await _pokemonRepository.getAllPokemon();
    final pokemonById = {
      for (final pokemon in pokemonList) pokemon.id: pokemon,
    };

    return _BagData(
      profile: profile,
      catalog: catalog,
      inventory: inventory,
      team: team,
      pokemonById: pokemonById,
    );
  }

  Future<void> _reload({String? message}) async {
    if (!mounted) return;

    setState(() {
      _message = message;
      _dataFuture = _loadBagData();
    });
  }

  Future<void> _openFinder(_BagData data, _BagAction action) async {
    final result = await showModalBottomSheet<_ItemPickerResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ItemPickerSheet(
        action: action,
        items: data.catalog,
        availableMoney: data.profile.money,
      ),
    );

    if (!mounted || result == null) return;

    final item = result.item;
    final quantity = result.quantity.clamp(1, 99).toInt();

    if (action == _BagAction.buy) {
      final cost = item.cost;
      if (cost == null) {
        await _reload(
          message: context.uiText(
            '${item.name} non si può acquistare.',
            '${item.name} cannot be purchased.',
          ),
        );
        return;
      }

      final totalCost = cost * quantity;
      if (data.profile.money < totalCost) {
        await _reload(
          message: context.uiText(
            'Pokédollari insufficienti per acquistare ${item.name} x$quantity.',
            'Not enough Pokédollars to buy ${item.name} x$quantity.',
          ),
        );
        return;
      }

      await _profileRepository.saveProfile(
        data.profile.copyWith(money: data.profile.money - totalCost),
      );
    }

    for (var index = 0; index < quantity; index++) {
      await _bagRepository.addItem(profileId: data.profile.id, itemId: item.id);
    }

    final quantityText = quantity == 1 ? '' : ' x$quantity';
    await _reload(
      message: action == _BagAction.buy
          ? context.uiText(
              '${item.name}$quantityText acquistato e aggiunto allo zaino.',
              '${item.name}$quantityText purchased and added to the Bag.',
            )
          : context.uiText(
              '${item.name}$quantityText aggiunto allo zaino.',
              '${item.name}$quantityText added to the Bag.',
            ),
    );
  }

  Future<void> _useBagItem(_BagData data, _OwnedBagItem entry) async {
    final item = entry.item;

    if (item.type == 'tm') {
      await _useTm(data, entry);
      return;
    }

    if (item.type == 'medicine') {
      await _useMedicine(data, entry);
      return;
    }

    if (item.type == 'berry') {
      await _useBerry(data, entry);
      return;
    }

    if (item.type == 'held-item') {
      await _useHeldItem(data, entry);
      return;
    }

    await _reload(
      message: context.uiText(
        '${item.name} non è ancora utilizzabile dallo zaino.',
        '${item.name} cannot be used from the Bag yet.',
      ),
    );
  }

  Future<void> _useBerry(_BagData data, _OwnedBagItem entry) async {
    if (!_berryMedicineItemIds.contains(entry.item.id)) {
      await _reload(
        message: context.uiText(
          '${entry.item.name} può essere data a un Pokémon, ma non usata direttamente.',
          '${entry.item.name} can be given to a Pokémon, but cannot be used directly.',
        ),
      );
      return;
    }

    final candidates = <_MedicineCandidate>[];

    for (final slot in data.team) {
      final pokemonId = slot.pokemonId;
      if (pokemonId == null) continue;

      final basePokemon = data.pokemonById[pokemonId];
      if (basePokemon == null) continue;
      final pokemon = basePokemon.resolveVariant(
        formName: slot.formName,
        gender: slot.gender,
      );

      candidates.add(_MedicineCandidate(slot: slot, pokemon: pokemon));
    }

    if (candidates.isEmpty) {
      await _reload(
        message: context.uiText(
          'Non hai Pokémon in squadra su cui usare ${entry.item.name}.',
          'There are no Pokémon in the team that can use ${entry.item.name}.',
        ),
      );
      return;
    }

    if (!mounted) return;

    final candidate = await showModalBottomSheet<_MedicineCandidate>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MedicinePokemonPickerSheet(
        item: entry.item,
        candidates: candidates,
        maxHpBuilder: _maxHpFor,
      ),
    );

    if (!mounted || candidate == null) return;

    final result = _applyMedicine(
      item: entry.item,
      slot: candidate.slot,
      pokemon: candidate.pokemon,
    );

    final consumed = await _bagRepository.consumeItem(
      profileId: data.profile.id,
      itemId: entry.item.id,
    );
    if (!consumed) {
      await _reload(
        message: context.uiText(
          'Non hai più ${entry.item.name} nello zaino.',
          'You have no more ${entry.item.name} in the Bag.',
        ),
      );
      return;
    }

    if (result != null) {
      await _teamRepository.updateSlot(
        profileId: data.profile.id,
        updatedSlot: result.updatedSlot,
      );
      await _reload(message: result.message);
      return;
    }

    await _reload(
      message: context.uiText(
        '${candidate.displayName} ha consumato ${entry.item.name}, ma non ha avuto effetto.',
        '${candidate.displayName} consumed ${entry.item.name}, but it had no effect.',
      ),
    );
  }

  Future<void> _useHeldItem(_BagData data, _OwnedBagItem entry) async {
    final candidates = <_HeldItemCandidate>[];

    for (final slot in data.team) {
      final pokemonId = slot.pokemonId;
      if (pokemonId == null) continue;

      final basePokemon = data.pokemonById[pokemonId];
      if (basePokemon == null) continue;
      final pokemon = basePokemon.resolveVariant(
        formName: slot.formName,
        gender: slot.gender,
      );

      candidates.add(_HeldItemCandidate(slot: slot, pokemon: pokemon));
    }

    if (candidates.isEmpty) {
      await _reload(
        message: context.uiText(
          'Non hai Pokémon in squadra a cui dare ${entry.item.name}.',
          'There are no Pokémon in the team that can hold ${entry.item.name}.',
        ),
      );
      return;
    }

    if (!mounted) return;

    final candidate = await showModalBottomSheet<_HeldItemCandidate>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _HeldItemPokemonPickerSheet(
        item: entry.item,
        candidates: candidates,
        itemByReference: data.itemByReference,
      ),
    );

    if (!mounted || candidate == null) return;

    final previousItemReference = candidate.slot.heldItem;
    final previousItem = previousItemReference == null
        ? null
        : data.itemByReference(previousItemReference);

    if (previousItem?.id == entry.item.id) {
      await _reload(
        message: context.uiText(
          '${candidate.displayName} tiene già ${entry.item.name}.',
          '${candidate.displayName} is already holding ${entry.item.name}.',
        ),
      );
      return;
    }

    final consumed = await _bagRepository.consumeItem(
      profileId: data.profile.id,
      itemId: entry.item.id,
    );
    if (!consumed) {
      await _reload(
        message: context.uiText(
          'Non hai più ${entry.item.name} nello zaino.',
          'You have no more ${entry.item.name} in the Bag.',
        ),
      );
      return;
    }

    if (previousItem != null) {
      await _bagRepository.addItem(
        profileId: data.profile.id,
        itemId: previousItem.id,
      );
    }

    await _teamRepository.updateSlot(
      profileId: data.profile.id,
      updatedSlot: candidate.slot.copyWith(heldItem: entry.item.id),
    );

    final replacementText = previousItem == null
        ? ''
        : context.uiText(
            ' ${previousItem.name} è tornato nello zaino.',
            ' ${previousItem.name} was returned to the Bag.',
          );
    await _reload(
      message: context.uiText(
        '${candidate.displayName} ora tiene ${entry.item.name}.$replacementText',
        '${candidate.displayName} is now holding ${entry.item.name}.$replacementText',
      ),
    );
  }

  Future<void> _removeHeldItem(_BagData data, _EquippedHeldItem entry) async {
    await _bagRepository.addItem(
      profileId: data.profile.id,
      itemId: entry.item.id,
    );
    await _teamRepository.updateSlot(
      profileId: data.profile.id,
      updatedSlot: entry.slot.copyWith(heldItem: null),
    );

    await _reload(
      message: context.uiText(
        '${entry.displayName} non tiene più ${entry.item.name}. L’oggetto è tornato nello zaino.',
        '${entry.displayName} is no longer holding ${entry.item.name}. The item was returned to the Bag.',
      ),
    );
  }

  Future<void> _useTm(_BagData data, _OwnedBagItem entry) async {
    final tmNumber = _tmNumberFromItemId(entry.item.id);
    if (tmNumber == null) {
      await _reload(
        message: context.uiText(
          context.uiText(
            'Questa MT non è collegata a una mossa valida.',
            'This TM is not linked to a valid move.',
          ),
          'This TM is not linked to a valid move.',
        ),
      );
      return;
    }

    final tmMap = await _tmRepository.getTmMap();
    final tm = tmMap[tmNumber];
    if (tm == null) {
      await _reload(
        message: context.uiText(
          'Dati della MT non disponibili.',
          'TM data is unavailable.',
        ),
      );
      return;
    }

    final move = await _moveRepository.getMove(tm.moveId);
    if (move == null) {
      await _reload(
        message: context.uiText(
          context.uiText(
            'Dati della mossa non disponibili.',
            'Move data is not available.',
          ),
          'Move data is unavailable.',
        ),
      );
      return;
    }

    final team = await _teamRepository.getTeam(data.profile.id);
    final pokemonList = await _pokemonRepository.getAllPokemon();
    final pokemonById = {
      for (final pokemon in pokemonList) pokemon.id: pokemon,
    };
    final candidates = <_TmCandidate>[];

    for (final slot in team) {
      final pokemonId = slot.pokemonId;
      if (pokemonId == null) continue;

      final basePokemon = pokemonById[pokemonId];
      if (basePokemon == null) continue;
      final pokemon = basePokemon.resolveVariant(
        formName: slot.formName,
        gender: slot.gender,
      );

      if (pokemon.moves.tmMoves.contains(tm.number)) {
        candidates.add(_TmCandidate(slot: slot, pokemon: pokemon));
      }
    }

    if (candidates.isEmpty) {
      await _reload(
        message: context.uiText(
          'Nessun Pokémon in squadra può imparare ${move.name} tramite ${entry.item.name}.',
          'No Pokémon in the team can learn ${move.name} from ${entry.item.name}.',
        ),
      );
      return;
    }

    if (!mounted) return;

    final candidate = await showModalBottomSheet<_TmCandidate>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TmPokemonPickerSheet(
        item: entry.item,
        move: move,
        candidates: candidates,
      ),
    );

    if (!mounted || candidate == null) return;

    final selectedMoves = _normalizedMoves(candidate.slot.selectedMoves);
    if (_knowsMove(selectedMoves, move)) {
      final pokemonName = candidate.slot.nickname ?? candidate.pokemon.name;
      await _reload(
        message: context.uiText(
          context.uiText(
            '$pokemonName conosce già ${move.name}.',
            '$pokemonName already knows ${move.name}.',
          ),
          '$pokemonName already knows ${move.name}.',
        ),
      );
      return;
    }

    final learnedMoveReference = move.id;
    final updatedMoves = [...selectedMoves];
    String? replacedMoveName;

    if (updatedMoves.length < 4) {
      updatedMoves.add(learnedMoveReference);
    } else {
      final currentMoveData = <String, MoveData?>{};
      for (final reference in updatedMoves) {
        currentMoveData[reference] = await _moveRepository.getMove(reference);
      }

      if (!mounted) return;

      final replaceIndex = await showModalBottomSheet<int>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _MoveReplaceSheet(
          pokemonName: candidate.slot.nickname ?? candidate.pokemon.name,
          newMove: move,
          selectedMoves: updatedMoves,
          moveData: currentMoveData,
        ),
      );

      if (!mounted || replaceIndex == null) return;

      replacedMoveName =
          currentMoveData[updatedMoves[replaceIndex]]?.name ??
          updatedMoves[replaceIndex];
      updatedMoves[replaceIndex] = learnedMoveReference;
    }

    final consumed = await _bagRepository.consumeItem(
      profileId: data.profile.id,
      itemId: entry.item.id,
    );
    if (!consumed) {
      await _reload(
        message: context.uiText(
          'Non hai più ${entry.item.name} nello zaino.',
          'You have no more ${entry.item.name} in the Bag.',
        ),
      );
      return;
    }

    await _teamRepository.updateSlot(
      profileId: data.profile.id,
      updatedSlot: candidate.slot.copyWith(selectedMoves: updatedMoves),
    );

    final pokemonName = candidate.slot.nickname ?? candidate.pokemon.name;
    final replacementText = replacedMoveName == null
        ? ''
        : ' al posto di $replacedMoveName';
    await _reload(
      message:
          '$pokemonName ha imparato ${move.name}$replacementText usando ${entry.item.name}.',
    );
  }

  Future<void> _useMedicine(_BagData data, _OwnedBagItem entry) async {
    if (!_isSupportedMedicine(entry.item.id)) {
      await _reload(
        message: context.uiText(
          '${entry.item.name} non è ancora utilizzabile automaticamente.',
          '${entry.item.name} cannot be used automatically yet.',
        ),
      );
      return;
    }

    final team = await _teamRepository.getTeam(data.profile.id);
    final pokemonList = await _pokemonRepository.getAllPokemon();
    final pokemonById = {
      for (final pokemon in pokemonList) pokemon.id: pokemon,
    };
    final candidates = <_MedicineCandidate>[];

    for (final slot in team) {
      final pokemonId = slot.pokemonId;
      if (pokemonId == null) continue;

      final pokemon = pokemonById[pokemonId];
      if (pokemon == null) continue;

      candidates.add(_MedicineCandidate(slot: slot, pokemon: pokemon));
    }

    if (candidates.isEmpty) {
      await _reload(
        message: context.uiText(
          'Non hai Pokémon in squadra su cui usare ${entry.item.name}.',
          'There are no Pokémon in the team that can use ${entry.item.name}.',
        ),
      );
      return;
    }

    if (!mounted) return;

    final candidate = await showModalBottomSheet<_MedicineCandidate>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MedicinePokemonPickerSheet(
        item: entry.item,
        candidates: candidates,
        maxHpBuilder: _maxHpFor,
      ),
    );

    if (!mounted || candidate == null) return;

    final result = _applyMedicine(
      item: entry.item,
      slot: candidate.slot,
      pokemon: candidate.pokemon,
    );

    if (result == null) {
      await _reload(
        message:
            '${entry.item.name} non avrebbe effetto su ${candidate.displayName}.',
      );
      return;
    }

    final consumed = await _bagRepository.consumeItem(
      profileId: data.profile.id,
      itemId: entry.item.id,
    );
    if (!consumed) {
      await _reload(
        message: context.uiText(
          'Non hai più ${entry.item.name} nello zaino.',
          'You have no more ${entry.item.name} in the Bag.',
        ),
      );
      return;
    }

    await _teamRepository.updateSlot(
      profileId: data.profile.id,
      updatedSlot: result.updatedSlot,
    );

    await _reload(message: result.message);
  }

  _MedicineUseResult? _applyMedicine({
    required BagItem item,
    required TeamSlot slot,
    required Pokemon pokemon,
  }) {
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

    if (updatedHp == currentHp &&
        _sameStrings(updatedStatuses, statusEffects)) {
      return null;
    }

    final displayName = slot.nickname ?? pokemon.name;
    final effects = [
      healingText,
      statusText,
    ].where((part) => part.isNotEmpty).join(' e ');

    return _MedicineUseResult(
      updatedSlot: slot.copyWith(
        currentHp: updatedHp,
        statusEffects: updatedStatuses,
      ),
      message: context.uiText(
        '$displayName $effects usando ${item.name}.',
        '$displayName $effects using ${item.name}.',
      ),
    );
  }

  int _maxHpFor(Pokemon pokemon, TeamSlot slot) {
    return TrainerPathPassiveService.maxHp(
      profile: _activeProfile,
      pokemon: pokemon,
      slot: slot,
      level: LevelProgression.levelFromExperience(slot.experience),
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

  int? _tmNumberFromItemId(String itemId) {
    final match = RegExp(r'^tm-(\d+)$').firstMatch(itemId);
    if (match == null) return null;

    return int.tryParse(match.group(1) ?? '');
  }

  List<String> _normalizedMoves(List<String> moves) {
    return moves.where((move) => move.trim().isNotEmpty).take(4).toList();
  }

  bool _knowsMove(List<String> selectedMoves, MoveData move) {
    final moveKeys = {
      MoveData.referenceKey(move.id),
      MoveData.referenceKey(move.name),
    }..removeWhere((key) => key.isEmpty);

    return selectedMoves.any(
      (reference) => moveKeys.contains(MoveData.referenceKey(reference)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const HomeLeadingButton(),
        title: Text(context.uiText('Zaino', 'Bag')),
      ),
      body: ResponsiveContent(
        maxWidth: 1180,
        child: FutureBuilder<_BagData>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _BagError(
                message: context.userFacingError(
                  snapshot.error!,
                  action: UserFacingErrorAction.load,
                ),
              );
            }

            final data = snapshot.data;
            if (data == null) return const _BagEmpty();

            return _BagContent(
              data: data,
              selectedType: _selectedType,
              message: _message,
              onTypeSelected: (type) => setState(() => _selectedType = type),
              onFindItem: () => _openFinder(data, _BagAction.find),
              onBuyItem: () => _openFinder(data, _BagAction.buy),
              onUseItem: (entry) => _useBagItem(data, entry),
              onEquipItem: (entry) => _useHeldItem(data, entry),
              onRemoveHeldItem: (entry) => _removeHeldItem(data, entry),
            );
          },
        ),
      ),
    );
  }
}

class _BagData {
  const _BagData({
    required this.profile,
    required this.catalog,
    required this.inventory,
    required this.team,
    required this.pokemonById,
  });

  final UserProfile profile;
  final List<BagItem> catalog;
  final List<BagInventoryEntry> inventory;
  final List<TeamSlot> team;
  final Map<int, Pokemon> pokemonById;

  Map<String, BagItem> get itemById => {
    for (final item in catalog) item.id: item,
  };

  BagItem? itemByReference(String reference) {
    final trimmed = reference.trim();
    if (trimmed.isEmpty) return null;

    final direct = itemById[trimmed];
    if (direct != null) return direct;

    final target = _itemReferenceKey(trimmed);
    for (final item in catalog) {
      if (_itemReferenceKey(item.id) == target ||
          _itemReferenceKey(item.name) == target) {
        return item;
      }
    }

    return null;
  }

  List<_OwnedBagItem> get ownedItems {
    final itemsById = itemById;
    final owned = <_OwnedBagItem>[];

    for (final entry in inventory) {
      final item = itemsById[entry.itemId];
      if (item != null) {
        owned.add(_OwnedBagItem(item: item, quantity: entry.quantity));
      }
    }

    owned.sort((a, b) {
      final typeCompare = a.item.type.compareTo(b.item.type);
      if (typeCompare != 0) return typeCompare;
      return a.item.name.compareTo(b.item.name);
    });

    return owned;
  }

  List<_EquippedHeldItem> get equippedHeldItems {
    final equipped = <_EquippedHeldItem>[];

    for (final slot in team) {
      final pokemonId = slot.pokemonId;
      final heldItemReference = slot.heldItem;
      if (pokemonId == null ||
          heldItemReference == null ||
          heldItemReference.trim().isEmpty) {
        continue;
      }

      final pokemon = pokemonById[pokemonId];
      final item = itemByReference(heldItemReference);
      if (pokemon == null || item == null) continue;

      equipped.add(_EquippedHeldItem(slot: slot, pokemon: pokemon, item: item));
    }

    equipped.sort((a, b) => a.slot.slotIndex.compareTo(b.slot.slotIndex));
    return equipped;
  }
}

class _OwnedBagItem {
  const _OwnedBagItem({required this.item, required this.quantity});

  final BagItem item;
  final int quantity;
}

class _HeldItemCandidate {
  const _HeldItemCandidate({required this.slot, required this.pokemon});

  final TeamSlot slot;
  final Pokemon pokemon;

  String get displayName => slot.nickname ?? pokemon.name;
}

class _EquippedHeldItem {
  const _EquippedHeldItem({
    required this.slot,
    required this.pokemon,
    required this.item,
  });

  final TeamSlot slot;
  final Pokemon pokemon;
  final BagItem item;

  String get displayName => slot.nickname ?? pokemon.name;
}

class _TmCandidate {
  const _TmCandidate({required this.slot, required this.pokemon});

  final TeamSlot slot;
  final Pokemon pokemon;
}

class _MedicineCandidate {
  const _MedicineCandidate({required this.slot, required this.pokemon});

  final TeamSlot slot;
  final Pokemon pokemon;

  String get displayName => slot.nickname ?? pokemon.name;
}

class _MedicineUseResult {
  const _MedicineUseResult({required this.updatedSlot, required this.message});

  final TeamSlot updatedSlot;
  final String message;
}

enum _BagAction { find, buy }

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

class _BagContent extends StatelessWidget {
  const _BagContent({
    required this.data,
    required this.selectedType,
    required this.message,
    required this.onTypeSelected,
    required this.onFindItem,
    required this.onBuyItem,
    required this.onUseItem,
    required this.onEquipItem,
    required this.onRemoveHeldItem,
  });

  final _BagData data;
  final String? selectedType;
  final String? message;
  final ValueChanged<String?> onTypeSelected;
  final VoidCallback onFindItem;
  final VoidCallback onBuyItem;
  final ValueChanged<_OwnedBagItem> onUseItem;
  final ValueChanged<_OwnedBagItem> onEquipItem;
  final ValueChanged<_EquippedHeldItem> onRemoveHeldItem;

  @override
  Widget build(BuildContext context) {
    final ownedItems = data.ownedItems;
    final types = _orderedTypes(ownedItems.map((entry) => entry.item).toList());
    final activeType = types.contains(selectedType) ? selectedType : null;
    final filteredItems = activeType == null
        ? ownedItems
        : ownedItems.where((entry) => entry.item.type == activeType).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _BagHeader(
          money: data.profile.money,
          ownedCount: ownedItems.length,
          totalQuantity: ownedItems.fold<int>(
            0,
            (sum, entry) => sum + entry.quantity,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 12),
          _InlineBagMessage(message: message!),
        ],
        const SizedBox(height: 16),
        _BagActions(onFindItem: onFindItem, onBuyItem: onBuyItem),
        _EquippedHeldItemsSection(
          equippedItems: data.equippedHeldItems,
          onRemove: onRemoveHeldItem,
        ),
        if (types.isNotEmpty) ...[
          const SizedBox(height: 16),
          _BagTypeFilters(
            types: types,
            selectedType: activeType,
            onTypeSelected: onTypeSelected,
          ),
        ],
        const SizedBox(height: 12),
        if (filteredItems.isEmpty)
          const _BagEmpty()
        else
          _BagItemsLayout(
            items: filteredItems,
            onUseItem: onUseItem,
            onEquipItem: onEquipItem,
          ),
      ],
    );
  }

  List<String> _orderedTypes(List<BagItem> items) {
    final types = items.map((item) => item.type).toSet().toList();
    const priority = [
      'pokeball',
      'medicine',
      'vitamin',
      'berry',
      'held-item',
      'evolution',
      'trainer-gear',
      'key-item',
      'tm',
    ];

    types.sort((a, b) {
      final aIndex = priority.indexOf(a);
      final bIndex = priority.indexOf(b);

      if (aIndex != -1 || bIndex != -1) {
        if (aIndex == -1) return 1;
        if (bIndex == -1) return -1;
        return aIndex.compareTo(bIndex);
      }

      return _typeLabel(a).compareTo(_typeLabel(b));
    });

    return types;
  }
}

class _BagHeader extends StatelessWidget {
  const _BagHeader({
    required this.money,
    required this.ownedCount,
    required this.totalQuantity,
  });

  final int money;
  final int ownedCount;
  final int totalQuantity;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(
              Icons.backpack,
              color: colorScheme.onTertiaryContainer,
              size: 42,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.uiText('Zaino allenatore', 'Trainer Bag'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.uiText(
                      '$ownedCount tipi di oggetto, $totalQuantity oggetti totali • ₽ $money',
                      '$ownedCount item types, $totalQuantity total items • ₽ $money',
                    ),
                    style: TextStyle(color: colorScheme.onTertiaryContainer),
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

class _InlineBagMessage extends StatelessWidget {
  const _InlineBagMessage({required this.message});

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
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          style: TextStyle(color: colorScheme.onSecondaryContainer),
        ),
      ),
    );
  }
}

class _BagActions extends StatelessWidget {
  const _BagActions({required this.onFindItem, required this.onBuyItem});

  final VoidCallback onFindItem;
  final VoidCallback onBuyItem;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onFindItem,
            icon: const Icon(Icons.search),
            label: Text(context.uiText('Trova oggetto', 'Find item')),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onBuyItem,
            icon: const Icon(Icons.shopping_cart_outlined),
            label: Text(context.uiText('Compra oggetto', 'Buy item')),
          ),
        ),
      ],
    );
  }
}

class _BagTypeFilters extends StatelessWidget {
  const _BagTypeFilters({
    required this.types,
    required this.selectedType,
    required this.onTypeSelected,
  });

  final List<String> types;
  final String? selectedType;
  final ValueChanged<String?> onTypeSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(context.uiText('Tutti', 'All')),
              selected: selectedType == null,
              onSelected: (_) => onTypeSelected(null),
            ),
          ),
          for (final type in types)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Icon(_iconForType(type), size: 18),
                label: Text(_typeLabel(type)),
                selected: selectedType == type,
                onSelected: (_) => onTypeSelected(type),
              ),
            ),
        ],
      ),
    );
  }
}

class _BagItemsLayout extends StatelessWidget {
  const _BagItemsLayout({
    required this.items,
    required this.onUseItem,
    required this.onEquipItem,
  });

  final List<_OwnedBagItem> items;
  final ValueChanged<_OwnedBagItem> onUseItem;
  final ValueChanged<_OwnedBagItem> onEquipItem;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final twoColumns = constraints.maxWidth >= 760;
        final itemWidth = twoColumns
            ? (constraints.maxWidth - spacing) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: 0,
          children: [
            for (final entry in items)
              SizedBox(
                width: itemWidth,
                child: _BagItemCard(
                  entry: entry,
                  onUse: () => onUseItem(entry),
                  onEquip: () => onEquipItem(entry),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BagItemCard extends StatefulWidget {
  const _BagItemCard({required this.entry, required this.onUse, this.onEquip});

  final _OwnedBagItem entry;
  final VoidCallback onUse;
  final VoidCallback? onEquip;

  @override
  State<_BagItemCard> createState() => _BagItemCardState();
}

class _BagItemCardState extends State<_BagItemCard> {
  final MoveRepository _moveRepository = MoveRepository();
  final TmRepository _tmRepository = TmRepository();
  late Future<MoveData?> _tmMoveFuture;

  @override
  void initState() {
    super.initState();
    _tmMoveFuture = _loadTmMove();
  }

  @override
  void didUpdateWidget(covariant _BagItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.item.id != widget.entry.item.id) {
      _tmMoveFuture = _loadTmMove();
    }
  }

  Future<MoveData?> _loadTmMove() async {
    final item = widget.entry.item;
    if (item.type != 'tm') return null;

    final tmNumber = _tmNumberFromItemId(item.id);
    if (tmNumber == null) return null;

    final tmMap = await _tmRepository.getTmMap();
    final tm = tmMap[tmNumber];
    if (tm == null) return null;

    return _moveRepository.getMove(tm.moveId);
  }

  int? _tmNumberFromItemId(String itemId) {
    final match = RegExp(r'^tm-(\d+)$').firstMatch(itemId);
    if (match == null) return null;
    return int.tryParse(match.group(1) ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.entry.item;
    final costLabel = item.cost == null
        ? context.uiText('Non acquistabile', 'Not for sale')
        : '₽ ${item.cost}';
    final canUse =
        item.type == 'tm' ||
        item.type == 'medicine' ||
        item.type == 'held-item' ||
        item.type == 'berry';

    return Card(
      child: ExpansionTile(
        leading: _ItemSprite(item: item),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text('${_typeLabel(item.type)} • $costLabel'),
        trailing: Text(
          'x${widget.entry.quantity}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(item.displayDescription),
          ),
          if (item.type == 'tm') ...[
            const SizedBox(height: 12),
            FutureBuilder<MoveData?>(
              future: _tmMoveFuture,
              builder: (context, snapshot) {
                final move = snapshot.data;
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    ),
                  );
                }

                if (move == null) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      context.uiText(
                        context.uiText(
                          'Dettagli mossa non disponibili.',
                          'Move details are not available.',
                        ),
                        'Move details are unavailable.',
                      ),
                    ),
                  );
                }

                return _MoveDetailsCard(
                  move: move,
                  title: context.uiText(
                    'Mossa insegnata dalla MT',
                    'Move taught by the TM',
                  ),
                  initiallyExpanded: false,
                );
              },
            ),
          ],
          if (canUse) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: item.type == 'berry'
                  ? Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: widget.onUse,
                          icon: const Icon(Icons.medical_services_outlined),
                          label: Text(
                            uiTextForLanguage('Usa bacca', 'Use Berry'),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: widget.onEquip,
                          icon: const Icon(Icons.inventory_2_outlined),
                          label: Text(
                            uiTextForLanguage(
                              'Dai a Pokémon',
                              'Give to Pokémon',
                            ),
                          ),
                        ),
                      ],
                    )
                  : FilledButton.icon(
                      onPressed: widget.onUse,
                      icon: Icon(_useIconForItemType(item.type)),
                      label: Text(_useLabelForItemType(item.type)),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ItemSprite extends StatelessWidget {
  const _ItemSprite({required this.item});

  final BagItem item;

  @override
  Widget build(BuildContext context) {
    final assetPath = item.spriteAssetPath;
    if (assetPath == null || !assetPath.startsWith('assets/')) {
      return Icon(_iconForType(item.type));
    }

    return SizedBox(
      width: 42,
      height: 42,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        errorBuilder: (_, __, ___) => Icon(_iconForType(item.type)),
      ),
    );
  }
}

class _EquippedHeldItemsSection extends StatelessWidget {
  const _EquippedHeldItemsSection({
    required this.equippedItems,
    required this.onRemove,
  });

  final List<_EquippedHeldItem> equippedItems;
  final ValueChanged<_EquippedHeldItem> onRemove;

  @override
  Widget build(BuildContext context) {
    if (equippedItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text(
          context.uiText('Strumenti tenuti', 'Held items'),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        for (final equipped in equippedItems)
          Card(
            child: ListTile(
              leading: _ItemSprite(item: equipped.item),
              title: Text(
                equipped.displayName,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                context.uiText(
                  'Slot ${equipped.slot.slotIndex + 1} • Tiene ${equipped.item.name}',
                  'Slot ${equipped.slot.slotIndex + 1} • Holds ${equipped.item.name}',
                ),
              ),
              trailing: OutlinedButton(
                onPressed: () => onRemove(equipped),
                child: Text(context.uiText('TOGLI', 'REMOVE')),
              ),
            ),
          ),
      ],
    );
  }
}

class _HeldItemPokemonPickerSheet extends StatelessWidget {
  const _HeldItemPokemonPickerSheet({
    required this.item,
    required this.candidates,
    required this.itemByReference,
  });

  final BagItem item;
  final List<_HeldItemCandidate> candidates;
  final BagItem? Function(String reference) itemByReference;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              context.uiText('Dai ${item.name}', 'Give ${item.name}'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              context.uiText(
                'Scegli il Pokémon a cui far tenere questo strumento. Se ha già uno strumento, quello vecchio torna nello zaino.',
                'Choose the Pokémon that will hold this item. If it already holds one, the previous item returns to the Bag.',
              ),
            ),
            const SizedBox(height: 12),
            for (final candidate in candidates)
              Card(
                child: ListTile(
                  leading: PokemonAssetImage(
                    pokemon: candidate.pokemon,
                    size: 46,
                  ),
                  title: Text(
                    candidate.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(_heldItemCandidateSummary(candidate)),
                  trailing: Text(context.uiText('Scegli', 'Choose')),
                  onTap: () => Navigator.of(context).pop(candidate),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _heldItemCandidateSummary(_HeldItemCandidate candidate) {
    final heldItemReference = candidate.slot.heldItem;
    final heldItem = heldItemReference == null
        ? null
        : itemByReference(heldItemReference);

    return uiTextForLanguage(
      'Slot ${candidate.slot.slotIndex + 1} • Tiene: ${heldItem?.name ?? 'nessuno strumento'}',
      """Slot ${candidate.slot.slotIndex + 1} • Holding: ${heldItem?.name ?? 'no item'}""",
    );
  }
}

class _MedicinePokemonPickerSheet extends StatelessWidget {
  const _MedicinePokemonPickerSheet({
    required this.item,
    required this.candidates,
    required this.maxHpBuilder,
  });

  final BagItem item;
  final List<_MedicineCandidate> candidates;
  final int Function(Pokemon pokemon, TeamSlot slot) maxHpBuilder;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              context.uiText('Usa ${item.name}', 'Use ${item.name}'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              context.uiText(
                'Scegli il Pokémon della squadra.',
                'Choose a Pokémon from the team.',
              ),
            ),
            const SizedBox(height: 12),
            for (final candidate in candidates)
              Card(
                child: ListTile(
                  leading: PokemonAssetImage(
                    pokemon: candidate.pokemon,
                    size: 46,
                  ),
                  title: Text(
                    candidate.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(_medicineCandidateSummary(candidate)),
                  trailing: Text(context.uiText('Scegli', 'Choose')),
                  onTap: () => Navigator.of(context).pop(candidate),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _medicineCandidateSummary(_MedicineCandidate candidate) {
    final maxHp = maxHpBuilder(candidate.pokemon, candidate.slot);
    final currentHp = candidate.slot.currentHp.clamp(0, maxHp).toInt();
    final statuses = candidate.slot.statusEffects;
    final statusText = statuses.isEmpty
        ? uiTextForLanguage('nessuno status', 'no conditions')
        : statuses.join(', ');

    return 'Slot ${candidate.slot.slotIndex + 1} • HP $currentHp/$maxHp • $statusText';
  }
}

class _TmPokemonPickerSheet extends StatelessWidget {
  const _TmPokemonPickerSheet({
    required this.item,
    required this.move,
    required this.candidates,
  });

  final BagItem item;
  final MoveData move;
  final List<_TmCandidate> candidates;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              context.uiText('Usa ${item.name}', 'Use ${item.name}'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              context.uiText(
                'Scegli un Pokémon compatibile con ${move.name}.',
                'Choose a Pokémon compatible with ${move.name}.',
              ),
            ),
            const SizedBox(height: 12),
            _MoveDetailsCard(
              move: move,
              title: context.uiText(
                context.uiText(
                  'Dettagli della nuova mossa',
                  'New move details',
                ),
                'New move details',
              ),
            ),
            const SizedBox(height: 12),
            for (final candidate in candidates)
              Card(
                child: ListTile(
                  leading: PokemonAssetImage(
                    pokemon: candidate.pokemon,
                    size: 46,
                  ),
                  title: Text(
                    candidate.slot.nickname ?? candidate.pokemon.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    'Slot ${candidate.slot.slotIndex + 1} • ${candidate.pokemon.name}',
                  ),
                  trailing: Text(context.uiText('Scegli', 'Choose')),
                  onTap: () => Navigator.of(context).pop(candidate),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MoveReplaceSheet extends StatelessWidget {
  const _MoveReplaceSheet({
    required this.pokemonName,
    required this.newMove,
    required this.selectedMoves,
    required this.moveData,
  });

  final String pokemonName;
  final MoveData newMove;
  final List<String> selectedMoves;
  final Map<String, MoveData?> moveData;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.82,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              context.uiText(
                '$pokemonName sta imparando ${newMove.name}',
                '$pokemonName is learning ${newMove.name}',
              ),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              context.uiText(
                'Il moveset è pieno. Controlla la nuova mossa e scegli quale dimenticare.',
                'The moveset is full. Review the new move and choose one to forget.',
              ),
            ),
            const SizedBox(height: 12),
            _MoveDetailsCard(
              move: newMove,
              title: context.uiText('Nuova mossa', 'New move'),
            ),
            const SizedBox(height: 16),
            Text(
              context.uiText('Mosse da dimenticare', 'Moves to forget'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            for (final entry in selectedMoves.asMap().entries)
              _MoveReplacementTile(
                index: entry.key,
                reference: entry.value,
                move: moveData[entry.value],
              ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(uiTextForLanguage('Annulla', 'Cancel')),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoveReplacementTile extends StatelessWidget {
  const _MoveReplacementTile({
    required this.index,
    required this.reference,
    required this.move,
  });

  final int index;
  final String reference;
  final MoveData? move;

  @override
  Widget build(BuildContext context) {
    final move = this.move;

    return Card(
      child: ListTile(
        leading: move == null
            ? const Icon(Icons.radio_button_unchecked)
            : PokemonTypeBadge(type: move.type, height: 24),
        title: Text((move?.name ?? reference).toUpperCase()),
        subtitle: move == null ? null : _MoveCompactInfo(move: move),
        trailing: Text(context.uiText('Sostituisci', 'Replace')),
        onTap: () => Navigator.of(context).pop(index),
      ),
    );
  }
}

class _MoveCompactInfo extends StatelessWidget {
  const _MoveCompactInfo({required this.move});

  final MoveData move;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      'PP ${move.pp}',
      if (move.range.trim().isNotEmpty && move.range != '-')
        context.uiText('Raggio ${move.range}', 'Range ${move.range}'),
      if (move.damageByLevel.isNotEmpty)
        context.uiText(
          'Danni ${_damageSummary(move)}',
          'Damage ${_damageSummary(move)}',
        ),
      if (move.save != null)
        context.uiText('TS ${move.save}', 'Save ${move.save}'),
    ];

    return Text(
      parts.join(' • '),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _MoveDetailsCard extends StatelessWidget {
  const _MoveDetailsCard({
    required this.move,
    required this.title,
    this.initiallyExpanded = true,
  });

  final MoveData move;
  final String title;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = _moveDetailRows(context, move);

    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: PokemonTypeBadge(type: move.type, height: 26),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(move.name.toUpperCase()),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final detail in details)
                _MoveInfoChip(label: detail.$1, value: detail.$2),
            ],
          ),
          if (move.description.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(move.description.trim()),
            ),
          ],
        ],
      ),
    );
  }
}

class _MoveInfoChip extends StatelessWidget {
  const _MoveInfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          '$label: $value',
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ),
    );
  }
}

List<(String, String)> _moveDetailRows(BuildContext context, MoveData move) {
  return <(String, String)>[
    (
      context.uiText('Tipo', 'Type'),
      PokemonAssetPaths.localizedTypeLabel(move.type),
    ),
    ('PP', move.pp),
    if (move.moveTime.trim().isNotEmpty && move.moveTime != '-')
      (context.uiText('Tempo', 'Time'), move.moveTime),
    if (move.range.trim().isNotEmpty && move.range != '-')
      (context.uiText('Raggio', 'Range'), move.range),
    if (move.duration.trim().isNotEmpty && move.duration != '-')
      (context.uiText('Durata', 'Duration'), move.duration),
    if (move.movePowers.isNotEmpty) ('Power', move.movePowers.join('/')),
    if (move.damageByLevel.isNotEmpty)
      (context.uiText('Danni', 'Damage'), _damageSummary(move)),
    if (move.damageTypes.isNotEmpty)
      (
        uiTextForLanguage('Danno tipo', 'Damage type'),
        move.damageTypes.join('/'),
      ),
    if (move.damageModifier?.trim().isNotEmpty == true)
      ('Mod.', move.damageModifier!.trim()),
    if (move.save?.trim().isNotEmpty == true)
      (context.uiText('TS', 'Save'), move.save!.trim()),
    if (move.attackScope?.trim().isNotEmpty == true)
      (context.uiText('Bersaglio', 'Target'), move.attackScope!.trim()),
  ];
}

String _damageSummary(MoveData move) {
  final entries = move.damageByLevel.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));

  return entries
      .map((entry) => 'Lv.${entry.key} ${entry.value.label}')
      .join(' / ');
}

class _ItemPickerResult {
  const _ItemPickerResult({required this.item, required this.quantity});

  final BagItem item;
  final int quantity;
}

class _ItemPickerSheet extends StatefulWidget {
  const _ItemPickerSheet({
    required this.action,
    required this.items,
    required this.availableMoney,
  });

  final _BagAction action;
  final List<BagItem> items;
  final int availableMoney;

  @override
  State<_ItemPickerSheet> createState() => _ItemPickerSheetState();
}

class _ItemPickerSheetState extends State<_ItemPickerSheet> {
  final TextEditingController _controller = TextEditingController();
  final Map<String, int> _quantities = {};
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isBuy => widget.action == _BagAction.buy;

  int _quantityFor(BagItem item) => _quantities[item.id] ?? 1;

  int _maxQuantityFor(BagItem item) {
    if (!_isBuy) return 99;

    final cost = item.cost;
    if (cost == null || cost <= 0) return 0;

    return (widget.availableMoney ~/ cost).clamp(0, 99).toInt();
  }

  void _setQuantity(BagItem item, int value) {
    final maxQuantity = _maxQuantityFor(item);
    if (maxQuantity <= 0) return;

    setState(() {
      _quantities[item.id] = value.clamp(1, maxQuantity).toInt();
    });
  }

  void _confirm(BagItem item) {
    final maxQuantity = _maxQuantityFor(item);
    if (maxQuantity <= 0) return;

    final quantity = _quantityFor(item).clamp(1, maxQuantity).toInt();
    Navigator.of(
      context,
    ).pop(_ItemPickerResult(item: item, quantity: quantity));
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = widget.items.where((item) {
      final query = _query.trim().toLowerCase();
      if (query.isEmpty) return true;

      return item.name.toLowerCase().contains(query) ||
          item.type.toLowerCase().contains(query) ||
          _typeLabel(item.type).toLowerCase().contains(query);
    }).toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.78,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isBuy
                    ? context.uiText('Compra oggetto', 'Buy item')
                    : context.uiText('Trova oggetto', 'Find item'),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              if (_isBuy) ...[
                const SizedBox(height: 4),
                Text(
                  context.uiText(
                    'Pokédollari disponibili: ₽ ${widget.availableMoney}',
                    'Available Pokédollars: ₽ ${widget.availableMoney}',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                autofocus: true,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: context.uiText('Cerca oggetto', 'Search items'),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final maxQuantity = _maxQuantityFor(item);
                    final canSelect = maxQuantity > 0;
                    final quantity = _quantityFor(
                      item,
                    ).clamp(1, maxQuantity <= 0 ? 1 : maxQuantity).toInt();
                    final costLabel = item.cost == null
                        ? context.uiText('Non acquistabile', 'Not for sale')
                        : '₽ ${item.cost}';
                    final totalLabel = _isBuy && item.cost != null
                        ? context.uiText(
                            'Totale ₽ ${item.cost! * quantity}',
                            'Total ₽ ${item.cost! * quantity}',
                          )
                        : context.uiText(
                            'Quantità $quantity',
                            'Quantity $quantity',
                          );

                    return Card(
                      child: ListTile(
                        leading: _ItemSprite(item: item),
                        title: Text(item.name),
                        subtitle: Text(
                          '${_typeLabel(item.type)} • $costLabel • $totalLabel',
                        ),
                        enabled: canSelect,
                        onTap: canSelect ? () => _confirm(item) : null,
                        trailing: _QuantitySelector(
                          quantity: quantity,
                          canDecrease: canSelect && quantity > 1,
                          canIncrease: canSelect && quantity < maxQuantity,
                          onDecrease: () => _setQuantity(item, quantity - 1),
                          onIncrease: () => _setQuantity(item, quantity + 1),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  const _QuantitySelector({
    required this.quantity,
    required this.canDecrease,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final bool canDecrease;
  final bool canIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            visualDensity: Theme.of(context).visualDensity,
            onPressed: canDecrease ? onDecrease : null,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            visualDensity: Theme.of(context).visualDensity,
            onPressed: canIncrease ? onIncrease : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _BagError extends StatelessWidget {
  const _BagError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(
              context.uiText(
                'Non riesco a caricare gli oggetti dello zaino.',
                'Could not load Bag items.',
              ),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _BagEmpty extends StatelessWidget {
  const _BagEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          context.uiText('Nessun oggetto nello zaino.', 'No items in the Bag.'),
        ),
      ),
    );
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

IconData _useIconForItemType(String type) {
  switch (type) {
    case 'tm':
      return Icons.school_outlined;
    case 'medicine':
      return Icons.medical_services_outlined;
    case 'held-item':
      return Icons.inventory_2_outlined;
    case 'berry':
      return Icons.eco_outlined;
    default:
      return Icons.play_arrow;
  }
}

String _useLabelForItemType(String type) {
  switch (type) {
    case 'tm':
      return uiTextForLanguage('Usa MT', 'Use TM');
    case 'medicine':
      return uiTextForLanguage('Usa oggetto', 'Use item');
    case 'held-item':
      return uiTextForLanguage('Dai a Pokémon', 'Give to Pokémon');
    case 'berry':
      return uiTextForLanguage('Usa bacca', 'Use Berry');
    default:
      return uiTextForLanguage('Usa', 'Use');
  }
}

IconData _iconForType(String type) {
  switch (type) {
    case 'pokeball':
      return Icons.catching_pokemon;
    case 'medicine':
      return Icons.medical_services_outlined;
    case 'berry':
      return Icons.eco_outlined;
    case 'held-item':
      return Icons.inventory_2_outlined;
    case 'evolution':
      return Icons.auto_awesome;
    case 'trainer-gear':
      return Icons.hiking_outlined;
    case 'key-item':
      return Icons.vpn_key_outlined;
    case 'tm':
      return Icons.album_outlined;
    default:
      return Icons.category_outlined;
  }
}

String _typeLabel(String type) {
  switch (type) {
    case 'pokeball':
      return 'Poké Ball';
    case 'medicine':
      return 'Medicine';
    case 'vitamin':
      return uiTextForLanguage('Vitamine', 'Vitamins');
    case 'berry':
      return uiTextForLanguage('Bacche', 'Berries');
    case 'held-item':
      return uiTextForLanguage('Oggetti tenuti', 'Held items');
    case 'evolution':
      return uiTextForLanguage('Evoluzione', 'Evolution');
    case 'trainer-gear':
      return uiTextForLanguage('Equipaggiamento', 'Trainer gear');
    case 'key-item':
      return uiTextForLanguage('Oggetti chiave', 'Key items');
    case 'tm':
      return 'MT';
    default:
      return type
          .split('-')
          .where((part) => part.isNotEmpty)
          .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
          .join(' ');
  }
}
