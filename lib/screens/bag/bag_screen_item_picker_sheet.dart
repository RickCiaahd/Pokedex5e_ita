part of 'bag_screen.dart';

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

  int _quantityFor(BagItem item) => _quantities[item.id] ?? 0;

  int get _selectedTypeCount =>
      _quantities.values.where((quantity) => quantity > 0).length;

  int get _selectedUnitCount =>
      _quantities.values.fold<int>(0, (sum, quantity) => sum + quantity);

  int get _totalCost {
    if (!_isBuy) return 0;
    final byId = {for (final item in widget.items) item.id: item};
    var total = 0;
    for (final entry in _quantities.entries) {
      if (entry.value <= 0) continue;
      final cost = byId[entry.key]?.cost;
      if (cost != null) total += cost * entry.value;
    }
    return total;
  }

  bool get _canConfirm {
    if (_selectedUnitCount <= 0) return false;
    return !_isBuy || _totalCost <= widget.availableMoney;
  }

  int _maxQuantityFor(BagItem item) {
    if (!_isBuy) return 99;
    final cost = item.cost;
    if (cost == null || cost <= 0) return 0;
    return (widget.availableMoney ~/ cost).clamp(0, 99).toInt();
  }

  bool _canIncrease(BagItem item) {
    final quantity = _quantityFor(item);
    if (quantity >= _maxQuantityFor(item)) return false;
    if (!_isBuy) return true;
    final cost = item.cost;
    return cost != null && _totalCost + cost <= widget.availableMoney;
  }

  void _setQuantity(BagItem item, int value) {
    final maxQuantity = _maxQuantityFor(item);
    final next = value.clamp(0, maxQuantity).toInt();
    setState(() {
      if (next == 0) {
        _quantities.remove(item.id);
      } else {
        _quantities[item.id] = next;
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
    if (!_canConfirm) return;
    Navigator.of(context).pop(
      _ItemCartResult(quantities: Map<String, int>.unmodifiable(_quantities)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = widget.items.where((item) {
      if (_isBuy && (item.cost == null || item.cost! <= 0)) return false;
      return item.matchesSearchQuery(_query, aliases: [_typeLabel(item.type)]);
    }).toList();

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
                _isBuy
                    ? context.uiText('Compra oggetti', 'Buy items')
                    : context.uiText('Aggiungi oggetti', 'Add items'),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                _isBuy
                    ? context.uiText(
                        'Prepara il carrello. Disponibili: ₽ ${widget.availableMoney}',
                        'Prepare the cart. Available: ₽ ${widget.availableMoney}',
                      )
                    : context.uiText(
                        'Imposta le quantità desiderate, poi conferma una sola volta.',
                        'Set the desired quantities, then confirm once.',
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
                child: ListView.builder(
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final quantity = _quantityFor(item);
                    final maxQuantity = _maxQuantityFor(item);
                    final canSelect = maxQuantity > 0;
                    final costLabel = _isBuy
                        ? '₽ ${item.cost}'
                        : context.uiText(
                            'Gestione manuale',
                            'Manual management',
                          );
                    final selectionLabel = quantity <= 0
                        ? context.uiText(
                            'Quantità da aggiungere: 0',
                            'Quantity to add: 0',
                          )
                        : _isBuy && item.cost != null
                        ? context.uiText(
                            'Nel carrello: $quantity • ₽ ${item.cost! * quantity}',
                            'In cart: $quantity • ₽ ${item.cost! * quantity}',
                          )
                        : context.uiText(
                            'Da aggiungere: $quantity',
                            'To add: $quantity',
                          );

                    return Card(
                      child: ListTile(
                        leading: _ItemSprite(item: item),
                        title: Text(item.name),
                        subtitle: Text(
                          '${_typeLabel(item.type)} • $costLabel\n$selectionLabel',
                        ),
                        isThreeLine: true,
                        onTap: () => _showItemDetails(item),
                        trailing: _QuantitySelector(
                          quantity: quantity,
                          canDecrease: quantity > 0,
                          canIncrease: canSelect && _canIncrease(item),
                          onDecrease: () => _setQuantity(item, quantity - 1),
                          onIncrease: () => _setQuantity(item, quantity + 1),
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
                      _isBuy
                          ? context.uiText(
                              '$_selectedTypeCount tipi • $_selectedUnitCount unità • Totale ₽ $_totalCost',
                              '$_selectedTypeCount types • $_selectedUnitCount units • Total ₽ $_totalCost',
                            )
                          : context.uiText(
                              '$_selectedTypeCount tipi • $_selectedUnitCount unità',
                              '$_selectedTypeCount types • $_selectedUnitCount units',
                            ),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _canConfirm ? _confirmCart : null,
                    icon: Icon(
                      _isBuy ? Icons.shopping_cart_checkout : Icons.add_box,
                    ),
                    label: Text(
                      _isBuy
                          ? context.uiText('COMPRA', 'BUY')
                          : context.uiText('AGGIUNGI', 'ADD'),
                    ),
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
