import 'package:flutter/material.dart';

import '../../models/bag_inventory_entry.dart';
import '../../models/bag_item.dart';
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

  late Future<_BagData> _dataFuture;
  String? _selectedType;
  String? _message;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadBagData();
  }

  Future<_BagData> _loadBagData() async {
    final profile = await _profileRepository.getActiveProfile();
    final catalog = await _itemRepository.getWebItems();
    final inventory = await _bagRepository.getInventory(profile.id);

    return _BagData(profile: profile, catalog: catalog, inventory: inventory);
  }

  Future<void> _reload({String? message}) async {
    if (!mounted) return;

    setState(() {
      _message = message;
      _dataFuture = _loadBagData();
    });
  }

  Future<void> _openFinder(_BagData data, _BagAction action) async {
    final item = await showModalBottomSheet<BagItem>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ItemPickerSheet(
        action: action,
        items: data.catalog,
        availableMoney: data.profile.money,
      ),
    );

    if (!mounted || item == null) return;

    if (action == _BagAction.buy) {
      final cost = item.cost;
      if (cost == null) {
        await _reload(message: '${item.name} non si può acquistare.');
        return;
      }

      if (data.profile.money < cost) {
        await _reload(message: 'Pokédollari insufficienti per ${item.name}.');
        return;
      }

      await _profileRepository.saveProfile(
        data.profile.copyWith(money: data.profile.money - cost),
      );
      await _bagRepository.addItem(profileId: data.profile.id, itemId: item.id);
      await _reload(message: '${item.name} acquistato e aggiunto allo zaino.');
      return;
    }

    await _bagRepository.addItem(profileId: data.profile.id, itemId: item.id);
    await _reload(message: '${item.name} aggiunto allo zaino.');
  }

  Future<void> _useBagItem(_BagData data, _OwnedBagItem entry) async {
    final item = entry.item;

    if (item.type == 'tm') {
      await _useTm(data, entry);
      return;
    }

    await _reload(message: '${item.name} non è ancora utilizzabile dallo zaino.');
  }

  Future<void> _useTm(_BagData data, _OwnedBagItem entry) async {
    final tmNumber = _tmNumberFromItemId(entry.item.id);
    if (tmNumber == null) {
      await _reload(message: 'Questa MT non è collegata a una mossa valida.');
      return;
    }

    final tmMap = await _tmRepository.getTmMap();
    final tm = tmMap[tmNumber];
    if (tm == null) {
      await _reload(message: 'Dati della MT non disponibili.');
      return;
    }

    final move = await _moveRepository.getMove(tm.moveId);
    if (move == null) {
      await _reload(message: 'Dati della mossa non disponibili.');
      return;
    }

    final team = await _teamRepository.getTeam(data.profile.id);
    final pokemonList = await _pokemonRepository.getAllPokemon();
    final pokemonById = {for (final pokemon in pokemonList) pokemon.id: pokemon};
    final candidates = <_TmCandidate>[];

    for (final slot in team) {
      final pokemonId = slot.pokemonId;
      if (pokemonId == null) continue;

      final pokemon = pokemonById[pokemonId];
      if (pokemon == null) continue;

      if (pokemon.moves.tmMoves.contains(tm.number)) {
        candidates.add(_TmCandidate(slot: slot, pokemon: pokemon));
      }
    }

    if (candidates.isEmpty) {
      await _reload(
        message:
            'Nessun Pokémon in squadra può imparare ${move.name} tramite ${entry.item.name}.',
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
      await _reload(message: '$pokemonName conosce già ${move.name}.');
      return;
    }

    final learnedMoveReference = move.name;
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

      replacedMoveName = currentMoveData[updatedMoves[replaceIndex]]?.name ??
          updatedMoves[replaceIndex];
      updatedMoves[replaceIndex] = learnedMoveReference;
    }

    final consumed = await _bagRepository.consumeItem(
      profileId: data.profile.id,
      itemId: entry.item.id,
    );
    if (!consumed) {
      await _reload(message: 'Non hai più ${entry.item.name} nello zaino.');
      return;
    }

    await _teamRepository.updateSlot(
      profileId: data.profile.id,
      updatedSlot: candidate.slot.copyWith(selectedMoves: updatedMoves),
    );

    final pokemonName = candidate.slot.nickname ?? candidate.pokemon.name;
    final replacementText =
        replacedMoveName == null ? '' : ' al posto di $replacedMoveName';
    await _reload(
      message:
          '$pokemonName ha imparato ${move.name}$replacementText usando ${entry.item.name}.',
    );
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
        title: const Text('Zaino'),
      ),
      body: FutureBuilder<_BagData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _BagError(message: snapshot.error.toString());
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
          );
        },
      ),
    );
  }
}

class _BagData {
  const _BagData({
    required this.profile,
    required this.catalog,
    required this.inventory,
  });

  final UserProfile profile;
  final List<BagItem> catalog;
  final List<BagInventoryEntry> inventory;

  List<_OwnedBagItem> get ownedItems {
    final itemById = {for (final item in catalog) item.id: item};
    final owned = <_OwnedBagItem>[];

    for (final entry in inventory) {
      final item = itemById[entry.itemId];
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
}

class _OwnedBagItem {
  const _OwnedBagItem({required this.item, required this.quantity});

  final BagItem item;
  final int quantity;
}

class _TmCandidate {
  const _TmCandidate({required this.slot, required this.pokemon});

  final TeamSlot slot;
  final Pokemon pokemon;
}

enum _BagAction { find, buy }

class _BagContent extends StatelessWidget {
  const _BagContent({
    required this.data,
    required this.selectedType,
    required this.message,
    required this.onTypeSelected,
    required this.onFindItem,
    required this.onBuyItem,
    required this.onUseItem,
  });

  final _BagData data;
  final String? selectedType;
  final String? message;
  final ValueChanged<String?> onTypeSelected;
  final VoidCallback onFindItem;
  final VoidCallback onBuyItem;
  final ValueChanged<_OwnedBagItem> onUseItem;

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
          totalQuantity: ownedItems.fold<int>(0, (sum, entry) => sum + entry.quantity),
        ),
        if (message != null) ...[
          const SizedBox(height: 12),
          _InlineBagMessage(message: message!),
        ],
        const SizedBox(height: 16),
        _BagActions(onFindItem: onFindItem, onBuyItem: onBuyItem),
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
          for (final entry in filteredItems)
            _BagItemCard(entry: entry, onUse: () => onUseItem(entry)),
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
                    'Zaino allenatore',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$ownedCount tipi di oggetto, $totalQuantity oggetti totali • ₽ $money',
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
            label: const Text('Trova oggetto'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onBuyItem,
            icon: const Icon(Icons.shopping_cart_outlined),
            label: const Text('Compra oggetto'),
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
              label: const Text('Tutti'),
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

class _BagItemCard extends StatefulWidget {
  const _BagItemCard({required this.entry, required this.onUse});

  final _OwnedBagItem entry;
  final VoidCallback onUse;

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
    final costLabel = item.cost == null ? 'Non acquistabile' : '₽ ${item.cost}';

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
          Align(alignment: Alignment.centerLeft, child: Text(item.displayDescription)),
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
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Dettagli mossa non disponibili.'),
                  );
                }

                return _MoveDetailsCard(
                  move: move,
                  title: 'Mossa insegnata dalla MT',
                  initiallyExpanded: false,
                );
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: widget.onUse,
                icon: const Icon(Icons.school_outlined),
                label: const Text('Usa MT'),
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
    final remoteUrl = item.remoteSpriteUrl;
    if (remoteUrl == null) return Icon(_iconForType(item.type));

    return SizedBox(
      width: 42,
      height: 42,
      child: Image.network(
        remoteUrl,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Icon(_iconForType(item.type));
        },
        errorBuilder: (_, __, ___) => Icon(_iconForType(item.type)),
      ),
    );
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
              'Usa ${item.name}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 4),
            Text('Scegli un Pokémon compatibile con ${move.name}.'),
            const SizedBox(height: 12),
            _MoveDetailsCard(move: move, title: 'Dettagli della nuova mossa'),
            const SizedBox(height: 12),
            for (final candidate in candidates)
              Card(
                child: ListTile(
                  leading: PokemonAssetImage(pokemon: candidate.pokemon, size: 46),
                  title: Text(
                    candidate.slot.nickname ?? candidate.pokemon.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    'Slot ${candidate.slot.slotIndex + 1} • ${candidate.pokemon.name}',
                  ),
                  trailing: const Text('Scegli'),
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
              '$pokemonName sta imparando ${newMove.name}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 4),
            const Text('Il moveset è pieno. Controlla la nuova mossa e scegli quale dimenticare.'),
            const SizedBox(height: 12),
            _MoveDetailsCard(move: newMove, title: 'Nuova mossa'),
            const SizedBox(height: 16),
            Text(
              'Mosse da dimenticare',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
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
              child: const Text('Annulla'),
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
        trailing: const Text('Sostituisci'),
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
      if (move.range.trim().isNotEmpty && move.range != '-') 'Raggio ${move.range}',
      if (move.damageByLevel.isNotEmpty) 'Danni ${_damageSummary(move)}',
      if (move.save != null) 'TS ${move.save}',
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
    final details = _moveDetailRows(move);

    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: PokemonTypeBadge(type: move.type, height: 26),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(move.name.toUpperCase()),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final detail in details) _MoveInfoChip(label: detail.$1, value: detail.$2),
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

List<(String, String)> _moveDetailRows(MoveData move) {
  return <(String, String)>[
    ('Tipo', PokemonAssetPaths.localizedTypeLabel(move.type)),
    ('PP', move.pp),
    if (move.moveTime.trim().isNotEmpty && move.moveTime != '-')
      ('Tempo', move.moveTime),
    if (move.range.trim().isNotEmpty && move.range != '-') ('Raggio', move.range),
    if (move.duration.trim().isNotEmpty && move.duration != '-')
      ('Durata', move.duration),
    if (move.movePowers.isNotEmpty) ('Power', move.movePowers.join('/')),
    if (move.damageByLevel.isNotEmpty) ('Danni', _damageSummary(move)),
    if (move.damageTypes.isNotEmpty) ('Danno tipo', move.damageTypes.join('/')),
    if (move.damageModifier?.trim().isNotEmpty == true)
      ('Mod.', move.damageModifier!.trim()),
    if (move.save?.trim().isNotEmpty == true) ('TS', move.save!.trim()),
    if (move.attackScope?.trim().isNotEmpty == true)
      ('Bersaglio', move.attackScope!.trim()),
  ];
}

String _damageSummary(MoveData move) {
  final entries = move.damageByLevel.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));

  return entries.map((entry) => 'Lv.${entry.key} ${entry.value.label}').join(' / ');
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
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBuy = widget.action == _BagAction.buy;
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
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isBuy ? 'Compra oggetto' : 'Trova oggetto',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              if (isBuy) ...[
                const SizedBox(height: 4),
                Text('Pokédollari disponibili: ₽ ${widget.availableMoney}'),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Cerca oggetto',
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
                    final canBuy = !isBuy ||
                        (item.cost != null && item.cost! <= widget.availableMoney);
                    final costLabel = item.cost == null ? 'Non acquistabile' : '₽ ${item.cost}';

                    return ListTile(
                      leading: _ItemSprite(item: item),
                      title: Text(item.name),
                      subtitle: Text('${_typeLabel(item.type)} • $costLabel'),
                      trailing: Text(isBuy ? 'Compra' : 'Aggiungi'),
                      enabled: canBuy,
                      onTap: canBuy ? () => Navigator.of(context).pop(item) : null,
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
              'Non riesco a caricare gli oggetti dello zaino.',
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('Nessun oggetto nello zaino.'),
      ),
    );
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
      return 'Vitamine';
    case 'berry':
      return 'Bacche';
    case 'held-item':
      return 'Oggetti tenuti';
    case 'evolution':
      return 'Evoluzione';
    case 'trainer-gear':
      return 'Equipaggiamento';
    case 'key-item':
      return 'Oggetti chiave';
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
