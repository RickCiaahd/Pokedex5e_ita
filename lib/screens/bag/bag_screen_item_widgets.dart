part of 'bag_screen.dart';

class _BagItemCard extends StatefulWidget {
  const _BagItemCard({
    required this.entry,
    required this.onUse,
    required this.onDiscard,
    this.onEquip,
  });

  final _OwnedBagItem entry;
  final VoidCallback onUse;
  final VoidCallback onDiscard;
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
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: widget.onDiscard,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(context.uiText('Scarta', 'Discard')),
                ),
                if (canUse && item.type == 'berry') ...[
                  OutlinedButton.icon(
                    onPressed: widget.onUse,
                    icon: const Icon(Icons.medical_services_outlined),
                    label: Text(uiTextForLanguage('Usa bacca', 'Use Berry')),
                  ),
                  FilledButton.icon(
                    onPressed: widget.onEquip,
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: Text(
                      uiTextForLanguage('Dai a Pokémon', 'Give to Pokémon'),
                    ),
                  ),
                ] else if (canUse)
                  FilledButton.icon(
                    onPressed: widget.onUse,
                    icon: Icon(_useIconForItemType(item.type)),
                    label: Text(_useLabelForItemType(item.type)),
                  ),
              ],
            ),
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
