part of 'bag_screen.dart';

class _BagContent extends StatelessWidget {
  const _BagContent({
    required this.data,
    required this.selectedType,
    required this.message,
    required this.onTypeSelected,
    required this.onUseItem,
    required this.onEquipItem,
    required this.onDiscardItem,
    required this.onRemoveHeldItem,
  });

  final _BagData data;
  final String? selectedType;
  final String? message;
  final ValueChanged<String?> onTypeSelected;
  final ValueChanged<_OwnedBagItem> onUseItem;
  final ValueChanged<_OwnedBagItem> onEquipItem;
  final ValueChanged<_OwnedBagItem> onDiscardItem;
  final ValueChanged<_EquippedHeldItem> onRemoveHeldItem;

  @override
  Widget build(BuildContext context) {
    final ownedItems = data.ownedItems;
    final types = _orderedTypes(ownedItems.map((entry) => entry.item).toList());
    final activeType = types.contains(selectedType) ? selectedType : null;
    final filteredItems = activeType == null
        ? ownedItems
        : ownedItems.where((entry) => entry.item.type == activeType).toList();
    final equippedItems = data.equippedHeldItems;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (message != null) ...[
          _InlineBagMessage(message: message!),
          const SizedBox(height: 12),
        ],
        if (types.isNotEmpty) ...[
          _BagTypeFilters(
            types: types,
            selectedType: activeType,
            onTypeSelected: onTypeSelected,
          ),
          const SizedBox(height: 12),
        ],
        if (filteredItems.isEmpty)
          const _BagEmpty()
        else
          _BagItemsLayout(
            items: filteredItems,
            onUseItem: onUseItem,
            onEquipItem: onEquipItem,
            onDiscardItem: onDiscardItem,
          ),
        if (equippedItems.isNotEmpty)
          _EquippedHeldItemsSection(
            equippedItems: equippedItems,
            onRemove: onRemoveHeldItem,
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
  const _BagActions({
    required this.onFindItem,
    required this.onBuyItem,
    required this.onSellItems,
  });

  final VoidCallback onFindItem;
  final VoidCallback onBuyItem;
  final VoidCallback onSellItems;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      elevation: 10,
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Row(
                children: [
                  Expanded(
                    child: _BagBottomAction(
                      icon: Icons.add_box_outlined,
                      label: context.uiText('Aggiungi', 'Add'),
                      onPressed: onFindItem,
                    ),
                  ),
                  Expanded(
                    child: _BagBottomAction(
                      icon: Icons.shopping_cart_outlined,
                      label: context.uiText('Compra', 'Buy'),
                      onPressed: onBuyItem,
                      highlighted: true,
                    ),
                  ),
                  Expanded(
                    child: _BagBottomAction(
                      icon: Icons.sell_outlined,
                      label: context.uiText('Vendi', 'Sell'),
                      onPressed: onSellItems,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BagBottomAction extends StatelessWidget {
  const _BagBottomAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final foreground = highlighted
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: label,
        child: Material(
          color: highlighted
              ? colorScheme.secondaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: foreground, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: foreground,
                      fontWeight: highlighted
                          ? FontWeight.w900
                          : FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
    required this.onDiscardItem,
  });

  final List<_OwnedBagItem> items;
  final ValueChanged<_OwnedBagItem> onUseItem;
  final ValueChanged<_OwnedBagItem> onEquipItem;
  final ValueChanged<_OwnedBagItem> onDiscardItem;

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
                  onDiscard: () => onDiscardItem(entry),
                ),
              ),
          ],
        );
      },
    );
  }
}
