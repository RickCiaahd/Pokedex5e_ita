from pathlib import Path


def read(path: str) -> str:
    return Path(path).read_text(encoding='utf-8')


def write(path: str, text: str) -> None:
    Path(path).write_text(text, encoding='utf-8')


def replace_once(text: str, old: str, new: str, path: str) -> str:
    if old not in text:
        raise RuntimeError(f'Blocco non trovato in {path}: {old[:160]!r}')
    return text.replace(old, new, 1)


# Rimozione multipla atomica dal punto di vista dell'inventario.
path = 'lib/repositories/bag_inventory_repository.dart'
text = read(path)
anchor = '''  Future<void> replaceInventory({
'''
method = '''  Future<bool> removeItems({
    required String profileId,
    required Map<String, int> quantities,
  }) async {
    final selected = quantities.entries
        .where((entry) => entry.key.trim().isNotEmpty && entry.value > 0)
        .toList(growable: false);
    if (selected.isEmpty) return true;

    final box = await _box();
    final existingByKey = <String, BagInventoryEntry>{};

    for (final entry in selected) {
      final itemId = entry.key.trim();
      final key = BagInventoryEntry.keyFor(profileId, itemId);
      final existingJson = box.get(key);
      if (existingJson == null) return false;

      final existing = BagInventoryEntry.fromJson(
        Map<String, dynamic>.from(existingJson),
      );
      if (existing.quantity < entry.value) return false;
      existingByKey[key] = existing;
    }

    final updates = <String, dynamic>{};
    final keysToDelete = <String>[];
    for (final entry in selected) {
      final itemId = entry.key.trim();
      final key = BagInventoryEntry.keyFor(profileId, itemId);
      final existing = existingByKey[key]!;
      final updatedQuantity = existing.quantity - entry.value;
      if (updatedQuantity <= 0) {
        keysToDelete.add(key);
      } else {
        updates[key] = existing.copyWith(quantity: updatedQuantity).toJson();
      }
    }

    if (keysToDelete.isNotEmpty) await box.deleteAll(keysToDelete);
    if (updates.isNotEmpty) await box.putAll(updates);
    await box.flush();
    return true;
  }

'''
text = replace_once(text, anchor, method + anchor, path)
write(path, text)


path = 'lib/screens/bag/bag_screen.dart'
text = read(path)

# Logica di vendita e rollback.
anchor = '''  Future<void> _discardBagItem(_BagData data, _OwnedBagItem entry) async {
'''
method = '''  Future<void> _openSellCart(_BagData data) async {
    final sellableItems = data.ownedItems
        .where((entry) => _salePriceFor(entry.item) > 0)
        .toList(growable: false);

    if (sellableItems.isEmpty) {
      await _reload(
        message: context.uiText(
          'Non hai oggetti con un valore di vendita disponibile.',
          'You have no items with an available sale value.',
        ),
      );
      return;
    }

    final result = await showModalBottomSheet<_ItemCartResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SellItemPickerSheet(items: sellableItems),
    );
    if (!mounted || result == null || result.quantities.isEmpty) return;

    final ownedById = {for (final entry in data.ownedItems) entry.item.id: entry};
    var totalValue = 0;
    var totalUnits = 0;
    var typeCount = 0;

    for (final entry in result.quantities.entries) {
      final owned = ownedById[entry.key];
      final quantity = entry.value;
      if (owned == null || quantity <= 0 || quantity > owned.quantity) {
        await _reload(
          message: context.uiText(
            'Lo Zaino è cambiato: riapri la vendita e controlla le quantità.',
            'The Bag changed: reopen the sale and check the quantities.',
          ),
        );
        return;
      }

      final unitValue = _salePriceFor(owned.item);
      if (unitValue <= 0) {
        await _reload(
          message: context.uiText(
            '${owned.item.name} non ha un valore di vendita.',
            '${owned.item.name} has no sale value.',
          ),
        );
        return;
      }

      totalValue += unitValue * quantity;
      totalUnits += quantity;
      typeCount += 1;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.uiText('Conferma vendita', 'Confirm sale')),
        content: Text(
          context.uiText(
            'Venderai $totalUnits oggetti di $typeCount tipi e riceverai ₽ $totalValue. Gli oggetti verranno rimossi dallo Zaino.',
            'You will sell $totalUnits items across $typeCount types and receive ₽ $totalValue. The items will be removed from the Bag.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.uiText('ANNULLA', 'CANCEL')),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.sell_outlined),
            label: Text(context.uiText('VENDI', 'SELL')),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    final removed = await _bagRepository.removeItems(
      profileId: data.profile.id,
      quantities: result.quantities,
    );
    if (!removed) {
      await _reload(
        message: context.uiText(
          'La vendita non è riuscita perché le quantità nello Zaino sono cambiate.',
          'The sale failed because the quantities in the Bag changed.',
        ),
      );
      return;
    }

    try {
      await _profileRepository.saveProfile(
        data.profile.copyWith(money: data.profile.money + totalValue),
      );
    } catch (error) {
      await _bagRepository.addItems(
        profileId: data.profile.id,
        quantities: result.quantities,
      );
      await _reload(
        message: context.userFacingError(
          error,
          action: UserFacingErrorAction.save,
        ),
      );
      return;
    }

    await _reload(
      message: context.uiText(
        '$totalUnits oggetti di $typeCount tipi venduti per ₽ $totalValue.',
        '$totalUnits items across $typeCount types sold for ₽ $totalValue.',
      ),
    );
  }

'''
text = replace_once(text, anchor, method + anchor, path)

# Collegamento della nuova azione allo schermo.
text = replace_once(
    text,
    '''              onBuyItem: () => _openFinder(data, _BagAction.buy),
              onUseItem: (entry) => _useBagItem(data, entry),
''',
    '''              onBuyItem: () => _openFinder(data, _BagAction.buy),
              onSellItems: () => _openSellCart(data),
              onUseItem: (entry) => _useBagItem(data, entry),
''',
    path,
)

# Helper prezzo di vendita.
text = replace_once(
    text,
    '''enum _BagAction { find, buy }

''',
    '''enum _BagAction { find, buy }

int _salePriceFor(BagItem item) {
  final cost = item.cost;
  if (cost == null || cost <= 0) return 0;
  return cost ~/ 2;
}

''',
    path,
)

# Proprietà e callback in _BagContent.
text = replace_once(
    text,
    '''    required this.onFindItem,
    required this.onBuyItem,
    required this.onUseItem,
''',
    '''    required this.onFindItem,
    required this.onBuyItem,
    required this.onSellItems,
    required this.onUseItem,
''',
    path,
)
text = replace_once(
    text,
    '''  final VoidCallback onFindItem;
  final VoidCallback onBuyItem;
  final ValueChanged<_OwnedBagItem> onUseItem;
''',
    '''  final VoidCallback onFindItem;
  final VoidCallback onBuyItem;
  final VoidCallback onSellItems;
  final ValueChanged<_OwnedBagItem> onUseItem;
''',
    path,
)
text = replace_once(
    text,
    '''        _BagActions(onFindItem: onFindItem, onBuyItem: onBuyItem),
''',
    '''        _BagActions(
          onFindItem: onFindItem,
          onBuyItem: onBuyItem,
          onSellItems: onSellItems,
        ),
''',
    path,
)

# Tre azioni responsive: aggiungi, compra, vendi.
old_actions = '''class _BagActions extends StatelessWidget {
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
            label: Text(context.uiText('Aggiungi oggetti', 'Add items')),
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
'''
new_actions = '''class _BagActions extends StatelessWidget {
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
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final singleColumn = constraints.maxWidth < 620;
        final buttonWidth = singleColumn
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing * 2) / 3;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: buttonWidth,
              child: FilledButton.icon(
                onPressed: onFindItem,
                icon: const Icon(Icons.add_box_outlined),
                label: Text(context.uiText('Aggiungi oggetti', 'Add items')),
              ),
            ),
            SizedBox(
              width: buttonWidth,
              child: OutlinedButton.icon(
                onPressed: onBuyItem,
                icon: const Icon(Icons.shopping_cart_outlined),
                label: Text(context.uiText('Compra oggetti', 'Buy items')),
              ),
            ),
            SizedBox(
              width: buttonWidth,
              child: OutlinedButton.icon(
                onPressed: onSellItems,
                icon: const Icon(Icons.sell_outlined),
                label: Text(context.uiText('Vendi oggetti', 'Sell items')),
              ),
            ),
          ],
        );
      },
    );
  }
}
'''
text = replace_once(text, old_actions, new_actions, path)

# Pannello a carrello per gli oggetti posseduti e prezzati.
anchor = '''class _QuantitySelector extends StatelessWidget {
'''
sell_sheet = '''class _SellItemPickerSheet extends StatefulWidget {
  const _SellItemPickerSheet({required this.items});

  final List<_OwnedBagItem> items;

  @override
  State<_SellItemPickerSheet> createState() => _SellItemPickerSheetState();
}

class _SellItemPickerSheetState extends State<_SellItemPickerSheet> {
  final TextEditingController _controller = TextEditingController();
  final Map<String, int> _quantities = {};
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _quantityFor(_OwnedBagItem entry) => _quantities[entry.item.id] ?? 0;

  int get _selectedTypeCount =>
      _quantities.values.where((quantity) => quantity > 0).length;

  int get _selectedUnitCount =>
      _quantities.values.fold<int>(0, (sum, quantity) => sum + quantity);

  int get _totalValue {
    final byId = {for (final entry in widget.items) entry.item.id: entry};
    var total = 0;
    for (final entry in _quantities.entries) {
      final owned = byId[entry.key];
      if (owned == null || entry.value <= 0) continue;
      total += _salePriceFor(owned.item) * entry.value;
    }
    return total;
  }

  void _setQuantity(_OwnedBagItem entry, int value) {
    final next = value.clamp(0, entry.quantity).toInt();
    setState(() {
      if (next == 0) {
        _quantities.remove(entry.item.id);
      } else {
        _quantities[entry.item.id] = next;
      }
    });
  }

  void _showItemDetails(BagItem item) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            _ItemSprite(item: item),
            const SizedBox(width: 12),
            Expanded(child: Text(item.name)),
          ],
        ),
        content: SingleChildScrollView(child: Text(item.displayDescription)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.uiText('CHIUDI', 'CLOSE')),
          ),
        ],
      ),
    );
  }

  void _confirmCart() {
    if (_selectedUnitCount <= 0 || _totalValue <= 0) return;
    Navigator.of(context).pop(
      _ItemCartResult(quantities: Map<String, int>.unmodifiable(_quantities)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = widget.items.where((entry) {
      return entry.item.matchesSearchQuery(
        _query,
        aliases: [_typeLabel(entry.item.type)],
      );
    }).toList(growable: false);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.84,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.uiText('Vendi oggetti', 'Sell items'),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                context.uiText(
                  'Seleziona gli oggetti posseduti. Il valore di vendita è metà del prezzo, arrotondato per difetto. Gli oggetti senza prezzo non compaiono.',
                  'Select owned items. Sale value is half the price, rounded down. Items without a price are not shown.',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                autofocus: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  labelText: context.uiText('Cerca oggetto', 'Search items'),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filteredItems.isEmpty
                    ? Center(
                        child: Text(
                          context.uiText(
                            'Nessun oggetto vendibile corrisponde alla ricerca.',
                            'No sellable items match the search.',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final entry = filteredItems[index];
                          final item = entry.item;
                          final quantity = _quantityFor(entry);
                          final unitValue = _salePriceFor(item);
                          final selectedValue = unitValue * quantity;
                          final selectionLabel = quantity <= 0
                              ? context.uiText(
                                  'Quantità da vendere: 0',
                                  'Quantity to sell: 0',
                                )
                              : context.uiText(
                                  'Da vendere: $quantity • Ricavo ₽ $selectedValue',
                                  'To sell: $quantity • Proceeds ₽ $selectedValue',
                                );

                          return Card(
                            child: ListTile(
                              leading: _ItemSprite(item: item),
                              title: Text(item.name),
                              subtitle: Text(
                                '${_typeLabel(item.type)} • Posseduti x${entry.quantity} • Vendita ₽ $unitValue\n$selectionLabel',
                              ),
                              isThreeLine: true,
                              onTap: () => _showItemDetails(item),
                              trailing: _QuantitySelector(
                                quantity: quantity,
                                canDecrease: quantity > 0,
                                canIncrease: quantity < entry.quantity,
                                onDecrease: () =>
                                    _setQuantity(entry, quantity - 1),
                                onIncrease: () =>
                                    _setQuantity(entry, quantity + 1),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const Divider(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.uiText(
                        '$_selectedTypeCount tipi • $_selectedUnitCount unità • Ricevi ₽ $_totalValue',
                        '$_selectedTypeCount types • $_selectedUnitCount units • Receive ₽ $_totalValue',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _selectedUnitCount > 0 && _totalValue > 0
                        ? _confirmCart
                        : null,
                    icon: const Icon(Icons.sell_outlined),
                    label: Text(context.uiText('VENDI', 'SELL')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

'''
text = replace_once(text, anchor, sell_sheet + anchor, path)
write(path, text)
