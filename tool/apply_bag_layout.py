from pathlib import Path
import re

path = Path('lib/screens/bag/bag_screen.dart')
text = path.read_text(encoding='utf-8')

if 'class _BagBottomAction extends StatelessWidget' in text and 'Zaino allenatore' not in text:
    print('Il nuovo layout dello Zaino è già applicato.')
    raise SystemExit(0)

new_build = r'''  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BagData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        final data = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            leading: const HomeLeadingButton(),
            title: Text(context.uiText('Zaino', 'Bag')),
            actions: [
              if (data != null)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Text(
                      '₽ ${data.profile.money}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: ResponsiveContent(
            maxWidth: 1180,
            child: Builder(
              builder: (context) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _BagError(
                    message: context.userFacingError(
                      snapshot.error!,
                      action: UserFacingErrorAction.load,
                    ),
                  );
                }

                if (data == null) return const _BagEmpty();

                return _BagContent(
                  data: data,
                  selectedType: _selectedType,
                  message: _message,
                  onTypeSelected: (type) => setState(() => _selectedType = type),
                  onUseItem: (entry) => _useBagItem(data, entry),
                  onEquipItem: (entry) => _useHeldItem(data, entry),
                  onDiscardItem: (entry) => _discardBagItem(data, entry),
                  onRemoveHeldItem: (entry) => _removeHeldItem(data, entry),
                );
              },
            ),
          ),
          bottomNavigationBar: data == null
              ? null
              : _BagActions(
                  onFindItem: () => _openFinder(data, _BagAction.find),
                  onBuyItem: () => _openFinder(data, _BagAction.buy),
                  onSellItems: () => _openSellCart(data),
                ),
        );
      },
    );
  }
'''

text, count = re.subn(
    r"  @override\n  Widget build\(BuildContext context\) \{\n    return Scaffold\(.*?\n  \}\n(?=\}\n\nclass _BagData)",
    new_build,
    text,
    count=1,
    flags=re.S,
)
if count != 1:
    raise SystemExit(f'BagScreen build replacement count: {count}')

new_content = r'''class _BagContent extends StatelessWidget {
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
        if (equippedItems.isNotEmpty) ...[
          const SizedBox(height: 16),
          _EquippedHeldItemsSection(
            equippedItems: equippedItems,
            onRemove: onRemoveHeldItem,
          ),
        ],
      ],
    );
  }

'''

text, count = re.subn(
    r"class _BagContent extends StatelessWidget \{.*?(?=  List<String> _orderedTypes)",
    new_content,
    text,
    count=1,
    flags=re.S,
)
if count != 1:
    raise SystemExit(f'BagContent replacement count: {count}')

text, count = re.subn(
    r"class _BagHeader extends StatelessWidget \{.*?(?=class _InlineBagMessage)",
    "",
    text,
    count=1,
    flags=re.S,
)
if count != 1:
    raise SystemExit(f'BagHeader removal count: {count}')

new_actions = r'''class _BagActions extends StatelessWidget {
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

'''

text, count = re.subn(
    r"class _BagActions extends StatelessWidget \{.*?(?=class _BagTypeFilters)",
    new_actions,
    text,
    count=1,
    flags=re.S,
)
if count != 1:
    raise SystemExit(f'BagActions replacement count: {count}')

path.write_text(text, encoding='utf-8')
print('Nuovo layout dello Zaino applicato.')
