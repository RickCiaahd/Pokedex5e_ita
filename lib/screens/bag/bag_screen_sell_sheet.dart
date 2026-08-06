part of 'bag_screen.dart';

class _SellItemPickerSheet extends StatefulWidget {
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
    final filteredItems = widget.items
        .where((entry) {
          return entry.item.matchesSearchQuery(
            _query,
            aliases: [_typeLabel(entry.item.type)],
          );
        })
        .toList(growable: false);

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
