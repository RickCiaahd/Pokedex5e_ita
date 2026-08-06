from pathlib import Path
import re


def read(path: str) -> str:
    return Path(path).read_text(encoding='utf-8')


def write(path: str, text: str) -> None:
    Path(path).write_text(text, encoding='utf-8')


def replace_once(text: str, old: str, new: str, path: str) -> str:
    if old not in text:
        raise RuntimeError(f'Missing block in {path}: {old[:160]!r}')
    return text.replace(old, new, 1)


# Use the two catalog items that already existed instead of creating duplicates.
path = 'lib/models/trainer_starting_equipment.dart'
text = read(path)
text = replace_once(
    text,
    """    'trainer-license': 1,
    'trainer-pokedex': 1,
""",
    """    'trainers-license': 1,
    'pokedex': 1,
""",
    path,
)

for legacy_id in ('trainer-license', 'trainer-pokedex'):
    pattern = rf"\n      BagItem\(\n        id: '{legacy_id}',.*?\n      \),"
    text, count = re.subn(pattern, '', text, count=1, flags=re.S)
    if count != 1:
        raise RuntimeError(f'Expected one generated item block for {legacy_id}, got {count}')
write(path, text)


# Migrate inventories produced by the previous debug APK to the canonical IDs.
path = 'lib/repositories/bag_inventory_repository.dart'
text = read(path)
text = replace_once(
    text,
    """  Future<List<BagInventoryEntry>> getInventory(String profileId) async {
    final box = await _box();

    return box.values
""",
    """  Future<List<BagInventoryEntry>> getInventory(String profileId) async {
    final box = await _box();
    await _migrateLegacyStartingItemIds(box, profileId);

    return box.values
""",
    path,
)
insert_before = """  Future<void> addItem({
"""
migration = """  Future<void> _migrateLegacyStartingItemIds(
    Box box,
    String profileId,
  ) async {
    const aliases = {
      'trainer-license': 'trainers-license',
      'trainer-pokedex': 'pokedex',
    };
    var changed = false;

    for (final alias in aliases.entries) {
      final legacyKey = BagInventoryEntry.keyFor(profileId, alias.key);
      final legacyJson = box.get(legacyKey);
      if (legacyJson == null) continue;

      final legacy = BagInventoryEntry.fromJson(
        Map<String, dynamic>.from(legacyJson),
      );
      final canonicalKey = BagInventoryEntry.keyFor(profileId, alias.value);
      final canonicalJson = box.get(canonicalKey);
      final canonical = canonicalJson == null
          ? BagInventoryEntry(
              profileId: profileId,
              itemId: alias.value,
              quantity: 0,
            )
          : BagInventoryEntry.fromJson(
              Map<String, dynamic>.from(canonicalJson),
            );

      await box.put(
        canonicalKey,
        canonical
            .copyWith(quantity: canonical.quantity + legacy.quantity)
            .toJson(),
      );
      await box.delete(legacyKey);
      changed = true;
    }

    if (changed) await box.flush();
  }

"""
text = replace_once(text, insert_before, migration + insert_before, path)
write(path, text)


# Add a normal discard action for every concrete item in the Bag.
path = 'lib/screens/bag/bag_screen.dart'
text = read(path)
anchor = """  Future<void> _useBagItem(_BagData data, _OwnedBagItem entry) async {
"""
discard_method = """  Future<void> _discardBagItem(
    _BagData data,
    _OwnedBagItem entry,
  ) async {
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
                    onPressed: () => setDialogState(
                      () => quantity = entry.quantity,
                    ),
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

"""
text = replace_once(text, anchor, discard_method + anchor, path)

text = replace_once(
    text,
    """              onUseItem: (entry) => _useBagItem(data, entry),
              onEquipItem: (entry) => _useHeldItem(data, entry),
""",
    """              onUseItem: (entry) => _useBagItem(data, entry),
              onEquipItem: (entry) => _useHeldItem(data, entry),
              onDiscardItem: (entry) => _discardBagItem(data, entry),
""",
    path,
)

text = replace_once(
    text,
    """    required this.onUseItem,
    required this.onEquipItem,
    required this.onRemoveHeldItem,
""",
    """    required this.onUseItem,
    required this.onEquipItem,
    required this.onDiscardItem,
    required this.onRemoveHeldItem,
""",
    path,
)
text = replace_once(
    text,
    """  final ValueChanged<_OwnedBagItem> onUseItem;
  final ValueChanged<_OwnedBagItem> onEquipItem;
  final ValueChanged<_EquippedHeldItem> onRemoveHeldItem;
""",
    """  final ValueChanged<_OwnedBagItem> onUseItem;
  final ValueChanged<_OwnedBagItem> onEquipItem;
  final ValueChanged<_OwnedBagItem> onDiscardItem;
  final ValueChanged<_EquippedHeldItem> onRemoveHeldItem;
""",
    path,
)
text = replace_once(
    text,
    """            onUseItem: onUseItem,
            onEquipItem: onEquipItem,
""",
    """            onUseItem: onUseItem,
            onEquipItem: onEquipItem,
            onDiscardItem: onDiscardItem,
""",
    path,
)

text = replace_once(
    text,
    """    required this.onUseItem,
    required this.onEquipItem,
  });

  final List<_OwnedBagItem> items;
  final ValueChanged<_OwnedBagItem> onUseItem;
  final ValueChanged<_OwnedBagItem> onEquipItem;
""",
    """    required this.onUseItem,
    required this.onEquipItem,
    required this.onDiscardItem,
  });

  final List<_OwnedBagItem> items;
  final ValueChanged<_OwnedBagItem> onUseItem;
  final ValueChanged<_OwnedBagItem> onEquipItem;
  final ValueChanged<_OwnedBagItem> onDiscardItem;
""",
    path,
)
text = replace_once(
    text,
    """                  onUse: () => onUseItem(entry),
                  onEquip: () => onEquipItem(entry),
""",
    """                  onUse: () => onUseItem(entry),
                  onEquip: () => onEquipItem(entry),
                  onDiscard: () => onDiscardItem(entry),
""",
    path,
)

text = replace_once(
    text,
    """class _BagItemCard extends StatefulWidget {
  const _BagItemCard({required this.entry, required this.onUse, this.onEquip});

  final _OwnedBagItem entry;
  final VoidCallback onUse;
  final VoidCallback? onEquip;
""",
    """class _BagItemCard extends StatefulWidget {
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
""",
    path,
)

old_actions = """          if (canUse) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: item.type == 'berry'
                  ? Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: widget.onUse,
                          icon: const Icon(Icons.medical_services_outlined),
                          label: Text(
                            uiTextForLanguage('Usa bacca', 'Use Berry'),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: widget.onEquip,
                          icon: const Icon(Icons.inventory_2_outlined),
                          label: Text(
                            uiTextForLanguage(
                              'Dai a Pokémon',
                              'Give to Pokémon',
                            ),
                          ),
                        ),
                      ],
                    )
                  : FilledButton.icon(
                      onPressed: widget.onUse,
                      icon: Icon(_useIconForItemType(item.type)),
                      label: Text(_useLabelForItemType(item.type)),
                    ),
            ),
          ],
"""
new_actions = """          const SizedBox(height: 12),
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
"""
text = replace_once(text, old_actions, new_actions, path)
write(path, text)


# Update the targeted static test.
path = 'test/trainer_manual_identity_fields_test.dart'
text = read(path)
text = text.replace("expect(inventory['trainer-license'], 1);", "expect(inventory['trainers-license'], 1);")
text = text.replace("expect(inventory['trainer-pokedex'], 1);", "expect(inventory['pokedex'], 1);")
text = text.replace(
    """    final customInventoryIds = <String>{
      ...TrainerStartingEquipment.baseInventory.keys,
      for (final pack in TrainerStartingEquipment.packInventory.values)
        ...pack.keys,
    }..removeAll({'poke-ball', 'potion'});
""",
    """    final customInventoryIds = <String>{
      for (final pack in TrainerStartingEquipment.packInventory.values)
        ...pack.keys,
    };
""",
)
text += """

test('starting inventory reuses the existing license and pokedex items', () {
  expect(TrainerStartingEquipment.baseInventory['trainers-license'], 1);
  expect(TrainerStartingEquipment.baseInventory['pokedex'], 1);
  expect(TrainerStartingEquipment.baseInventory, isNot(contains('trainer-license')));
  expect(TrainerStartingEquipment.baseInventory, isNot(contains('trainer-pokedex')));

  final generatedIds = TrainerStartingEquipment.catalogItems
      .map((item) => item.id)
      .toSet();
  expect(generatedIds, isNot(contains('trainers-license')));
  expect(generatedIds, isNot(contains('pokedex')));
});
"""
write(path, text)
