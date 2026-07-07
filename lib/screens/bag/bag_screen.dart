import 'package:flutter/material.dart';

import '../../models/bag_item.dart';
import '../../repositories/item_repository.dart';
import '../../widgets/navigation/home_leading_button.dart';

class BagScreen extends StatefulWidget {
  const BagScreen({super.key});

  @override
  State<BagScreen> createState() => _BagScreenState();
}

class _BagScreenState extends State<BagScreen> {
  final ItemRepository _itemRepository = ItemRepository();
  late final Future<List<BagItem>> _itemsFuture;

  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _itemsFuture = _itemRepository.getWebItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const HomeLeadingButton(),
        title: const Text('Zaino'),
      ),
      body: FutureBuilder<List<BagItem>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _BagError(message: snapshot.error.toString());
          }

          final items = snapshot.data ?? const <BagItem>[];
          if (items.isEmpty) {
            return const _BagEmpty();
          }

          return _BagContent(
            items: items,
            selectedType: _selectedType,
            onTypeSelected: (type) {
              setState(() {
                _selectedType = type;
              });
            },
          );
        },
      ),
    );
  }
}

class _BagContent extends StatelessWidget {
  const _BagContent({
    required this.items,
    required this.selectedType,
    required this.onTypeSelected,
  });

  final List<BagItem> items;
  final String? selectedType;
  final ValueChanged<String?> onTypeSelected;

  @override
  Widget build(BuildContext context) {
    final types = _orderedTypes(items);
    final activeType = types.contains(selectedType) ? selectedType : null;
    final filteredItems = activeType == null
        ? items
        : items.where((item) => item.type == activeType).toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _BagHeader(
          totalItems: items.length,
          shownItems: filteredItems.length,
          categoryCount: types.length,
        ),
        const SizedBox(height: 16),
        _BagTypeFilters(
          types: types,
          selectedType: activeType,
          onTypeSelected: onTypeSelected,
        ),
        const SizedBox(height: 12),
        for (final item in filteredItems) _BagItemCard(item: item),
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
    required this.totalItems,
    required this.shownItems,
    required this.categoryCount,
  });

  final int totalItems;
  final int shownItems;
  final int categoryCount;

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
                    '$shownItems oggetti mostrati su $totalItems totali in $categoryCount categorie.',
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
  const _BagItemCard({required this.item});

  final BagItem item;

  @override
  Widget build(BuildContext context) {
    final costLabel = item.cost == null ? 'Non acquistabile' : '₽ ${item.cost}';

    return Card(
      child: ExpansionTile(
        leading: _ItemSprite(item: item),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text('${_typeLabel(item.type)} • $costLabel'),
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
      width: 44,
      height: 44,
      child: Image.asset(
        spritePath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(_iconForType(item.type)),
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
        child: Text('Nessun oggetto disponibile nello zaino.'),
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
