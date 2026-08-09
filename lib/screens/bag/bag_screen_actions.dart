part of 'bag_screen.dart';

extension _BagScreenActions on _BagScreenState {
  Future<void> _openFinder(_BagData data, _BagAction action) async {
    final result = await showModalBottomSheet<_ItemCartResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ItemPickerSheet(
        action: action,
        items: data.catalog,
        availableMoney: data.profile.money,
      ),
    );

    if (!mounted || result == null || result.quantities.isEmpty) return;

    final itemsById = data.itemById;
    final selected = <BagItem, int>{};
    for (final entry in result.quantities.entries) {
      final item = itemsById[entry.key];
      if (item != null && entry.value > 0) selected[item] = entry.value;
    }
    if (selected.isEmpty) return;

    final quantities = {
      for (final entry in selected.entries) entry.key.id: entry.value,
    };
    final totalUnits = selected.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    final typeCount = selected.length;

    try {
      if (action == _BagAction.buy) {
        var totalCost = 0;
        for (final entry in selected.entries) {
          final cost = entry.key.cost;
          if (cost == null || cost <= 0) {
            await _reload(
              message: context.uiText(
                '${entry.key.name} non si può acquistare.',
                '${entry.key.name} cannot be purchased.',
              ),
            );
            return;
          }
          totalCost += cost * entry.value;
        }

        if (data.profile.money < totalCost) {
          await _reload(
            message: context.uiText(
              'Pokédollari insufficienti: servono ₽ $totalCost.',
              'Not enough Pokédollars: ₽ $totalCost are required.',
            ),
          );
          return;
        }

        final updatedProfile = data.profile.copyWith(
          money: data.profile.money - totalCost,
        );
        await _profileRepository.saveProfile(updatedProfile);
        try {
          await _bagRepository.addItems(
            profileId: data.profile.id,
            quantities: quantities,
          );
        } catch (_) {
          await _profileRepository.saveProfile(data.profile);
          rethrow;
        }

        if (!mounted) return;
        await _reload(
          message: context.uiText(
            '$totalUnits oggetti di $typeCount tipi acquistati per ₽ $totalCost.',
            '$totalUnits items across $typeCount types purchased for ₽ $totalCost.',
          ),
        );
        return;
      }

      await _bagRepository.addItems(
        profileId: data.profile.id,
        quantities: quantities,
      );
      if (!mounted) return;
      await _reload(
        message: context.uiText(
          '$totalUnits oggetti di $typeCount tipi aggiunti allo zaino.',
          '$totalUnits items across $typeCount types added to the Bag.',
        ),
      );
    } catch (error) {
      if (!mounted) return;
      await _reload(
        message: context.userFacingError(
          error,
          action: UserFacingErrorAction.save,
        ),
      );
    }
  }

  Future<void> _openSellCart(_BagData data) async {
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

    final ownedById = {
      for (final entry in data.ownedItems) entry.item.id: entry,
    };
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
    if (!mounted) return;
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
      if (!mounted) return;
      await _reload(
        message: context.userFacingError(
          error,
          action: UserFacingErrorAction.save,
        ),
      );
      return;
    }

    if (!mounted) return;
    await _reload(
      message: context.uiText(
        '$totalUnits oggetti di $typeCount tipi venduti per ₽ $totalValue.',
        '$totalUnits items across $typeCount types sold for ₽ $totalValue.',
      ),
    );
  }

  Future<void> _discardBagItem(_BagData data, _OwnedBagItem entry) async {
    var quantity = 1;
    final selectedQuantity = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            context.uiText(
              'Scarta ${entry.item.name}',
              'Discard ${entry.item.name}',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.uiText(
                  'L’oggetto verrà rimosso realmente dallo Zaino.',
                  'The item will be permanently removed from the Bag.',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: context.uiText('Diminuisci', 'Decrease'),
                    onPressed: quantity > 1
                        ? () => setDialogState(() => quantity -= 1)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  SizedBox(
                    width: 72,
                    child: Text(
                      '$quantity / ${entry.quantity}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: context.uiText('Aumenta', 'Increase'),
                    onPressed: quantity < entry.quantity
                        ? () => setDialogState(() => quantity += 1)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              if (entry.quantity > 1)
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () =>
                        setDialogState(() => quantity = entry.quantity),
                    child: Text(context.uiText('SCARTA TUTTI', 'DISCARD ALL')),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.uiText('ANNULLA', 'CANCEL')),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(quantity),
              icon: const Icon(Icons.delete_outline),
              label: Text(context.uiText('SCARTA', 'DISCARD')),
            ),
          ],
        ),
      ),
    );

    if (!mounted || selectedQuantity == null) return;

    final removed = await _bagRepository.consumeItem(
      profileId: data.profile.id,
      itemId: entry.item.id,
      quantity: selectedQuantity,
    );
    if (!mounted) return;
    await _reload(
      message: removed
          ? context.uiText(
              '$selectedQuantity × ${entry.item.name} scartati.',
              '$selectedQuantity × ${entry.item.name} discarded.',
            )
          : context.uiText(
              'Non è stato possibile scartare ${entry.item.name}.',
              '${entry.item.name} could not be discarded.',
            ),
    );
  }
}
