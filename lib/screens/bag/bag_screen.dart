import 'package:flutter/material.dart';

import '../../models/bag_inventory_entry.dart';
import '../../models/bag_item.dart';
import '../../models/user_profile.dart';
import '../../repositories/bag_inventory_repository.dart';
import '../../repositories/item_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../widgets/navigation/home_leading_button.dart';

class BagScreen extends StatefulWidget {
  const BagScreen({super.key});

  @override
  State<BagScreen> createState() => _BagScreenState();
}

class _BagScreenState extends State<BagScreen> {
  final ItemRepository _itemRepository = ItemRepository();
  final ProfileRepository _profileRepository = ProfileRepository();
  final BagInventoryRepository _bagRepository = BagInventoryRepository();

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

    return _BagData(
      profile: profile,
      catalog: catalog,
      inventory: inventory,
    );
  }

  Future<void> _reload({String? message}) async {
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

    if (item == null) return;

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
          if (data == null) {
            return const _BagEmpty();
          }

          return _BagContent(
            data: data,
            selectedType: _selectedType,
            message: _message,
            onTypeSelected: (type) {
              setState(() {
                _selectedType = type;
              });
            },
            onFindItem: () => _openFinder(data, _BagAction.find),
            onBuyItem: () => _openFinder(data, _BagAction.buy),
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

enum _BagAction { find, buy }

class _BagContent extends StatelessWidget {
  const _BagContent({
    required this.data,
    required this.selectedType,
    required this.message,
    required this.onTypeSelected,
    required this.onFindItem,
    required this.onBuyItem,
  });

  final _BagData data;
  final String? selectedType;
  final String? message;
  final ValueChanged<String?> onTypeSelected;
  final VoidCallback onFindItem;
  final VoidCallback onBuyItem;

  @override
  Widget build(BuildContext context) {
    final ownedItems = data.ownedItems;
    final types = _orderedTypes(ownedItems.map((entry) => entry.item).toList());
    final activeType = types.contains(selectedType) ? selectedType : null;
    final filteredItems = activeType == null
        ? ownedItems
        : ownedItems
              .where((entry) => entry.item.type == activeType)
              .toList(growable: false);

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
          for (final entry in filteredItems) _BagItemCard(entry: entry),
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

class _BagItemCard extends StatelessWidget {
  const _BagItemCard({required this.entry});

  final _OwnedBagItem entry;

  @override
  Widget build(BuildContext context) {
    final item = entry.item;
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
          'x${entry.quantity}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(item.displayDescription),
          ),
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
    final spritePath = item.spriteAssetPath;

    if (spritePath == null) {
      return Icon(_iconForType(item.type));
    }

    return SizedBox(
      width: 42,
      height: 42,
      child: Image.asset(
        spritePath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        errorBuilder: (_, __, ___) => _RemoteItemSprite(item: item),
      ),
    );
  }
}

class _RemoteItemSprite extends StatelessWidget {
  const _RemoteItemSprite({required this.item});

  final BagItem item;

  @override
  Widget build(BuildContext context) {
    final url = item.remoteSpriteUrl;
    if (url == null) {
      return Icon(_iconForType(item.type));
    }

    return Image.network(
      url,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Icon(_iconForType(item.type));
      },
      errorBuilder: (_, __, ___) => Icon(_iconForType(item.type)),
    );
  }
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
    }).toList(growable: false);

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
                    final costLabel = item.cost == null
                        ? 'Non acquistabile'
                        : '₽ ${item.cost}';

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
