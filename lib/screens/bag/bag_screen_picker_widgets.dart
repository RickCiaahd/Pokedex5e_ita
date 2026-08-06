part of 'bag_screen.dart';

class _HeldItemPokemonPickerSheet extends StatelessWidget {
  const _HeldItemPokemonPickerSheet({
    required this.item,
    required this.candidates,
    required this.itemByReference,
  });

  final BagItem item;
  final List<_HeldItemCandidate> candidates;
  final BagItem? Function(String reference) itemByReference;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              context.uiText('Dai ${item.name}', 'Give ${item.name}'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              context.uiText(
                'Scegli il Pokémon a cui far tenere questo strumento. Se ha già uno strumento, quello vecchio torna nello zaino.',
                'Choose the Pokémon that will hold this item. If it already holds one, the previous item returns to the Bag.',
              ),
            ),
            const SizedBox(height: 12),
            for (final candidate in candidates)
              Card(
                child: ListTile(
                  leading: PokemonAssetImage(
                    pokemon: candidate.pokemon,
                    formName: candidate.slot.effectiveFormName,
                    gender: candidate.slot.gender,
                    isShiny: candidate.slot.isShiny,
                    size: 46,
                  ),
                  title: Text(
                    candidate.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(_heldItemCandidateSummary(candidate)),
                  trailing: Text(context.uiText('Scegli', 'Choose')),
                  onTap: () => Navigator.of(context).pop(candidate),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _heldItemCandidateSummary(_HeldItemCandidate candidate) {
    final heldItemReference = candidate.slot.heldItem;
    final heldItem = heldItemReference == null
        ? null
        : itemByReference(heldItemReference);

    return uiTextForLanguage(
      'Slot ${candidate.slot.slotIndex + 1} • Tiene: ${heldItem?.name ?? 'nessuno strumento'}',
      """Slot ${candidate.slot.slotIndex + 1} • Holding: ${heldItem?.name ?? 'no item'}""",
    );
  }
}

class _MedicinePokemonPickerSheet extends StatelessWidget {
  const _MedicinePokemonPickerSheet({
    required this.item,
    required this.candidates,
    required this.maxHpBuilder,
  });

  final BagItem item;
  final List<_MedicineCandidate> candidates;
  final int Function(Pokemon pokemon, TeamSlot slot) maxHpBuilder;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              context.uiText('Usa ${item.name}', 'Use ${item.name}'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              context.uiText(
                'Scegli il Pokémon della squadra.',
                'Choose a Pokémon from the team.',
              ),
            ),
            const SizedBox(height: 12),
            for (final candidate in candidates)
              Card(
                child: ListTile(
                  leading: PokemonAssetImage(
                    pokemon: candidate.pokemon,
                    formName: candidate.slot.effectiveFormName,
                    gender: candidate.slot.gender,
                    isShiny: candidate.slot.isShiny,
                    size: 46,
                  ),
                  title: Text(
                    candidate.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(_medicineCandidateSummary(candidate)),
                  trailing: Text(context.uiText('Scegli', 'Choose')),
                  onTap: () => Navigator.of(context).pop(candidate),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _medicineCandidateSummary(_MedicineCandidate candidate) {
    final maxHp = maxHpBuilder(candidate.pokemon, candidate.slot);
    final currentHp = candidate.slot.currentHp.clamp(0, maxHp).toInt();
    final statuses = candidate.slot.statusEffects;
    final statusText = statuses.isEmpty
        ? uiTextForLanguage('nessuno status', 'no conditions')
        : statuses.join(', ');

    return 'Slot ${candidate.slot.slotIndex + 1} • HP $currentHp/$maxHp • $statusText';
  }
}

class _TmPokemonPickerSheet extends StatelessWidget {
  const _TmPokemonPickerSheet({
    required this.item,
    required this.move,
    required this.candidates,
  });

  final BagItem item;
  final MoveData move;
  final List<_TmCandidate> candidates;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              context.uiText('Usa ${item.name}', 'Use ${item.name}'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              context.uiText(
                'Scegli un Pokémon compatibile con ${move.name}.',
                'Choose a Pokémon compatible with ${move.name}.',
              ),
            ),
            const SizedBox(height: 12),
            _MoveDetailsCard(
              move: move,
              title: context.uiText(
                context.uiText(
                  'Dettagli della nuova mossa',
                  'New move details',
                ),
                'New move details',
              ),
            ),
            const SizedBox(height: 12),
            for (final candidate in candidates)
              Card(
                child: ListTile(
                  leading: PokemonAssetImage(
                    pokemon: candidate.pokemon,
                    formName: candidate.slot.effectiveFormName,
                    gender: candidate.slot.gender,
                    isShiny: candidate.slot.isShiny,
                    size: 46,
                  ),
                  title: Text(
                    candidate.slot.nickname ?? candidate.pokemon.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    'Slot ${candidate.slot.slotIndex + 1} • ${candidate.pokemon.name}',
                  ),
                  trailing: Text(context.uiText('Scegli', 'Choose')),
                  onTap: () => Navigator.of(context).pop(candidate),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MoveReplaceSheet extends StatelessWidget {
  const _MoveReplaceSheet({
    required this.pokemonName,
    required this.newMove,
    required this.selectedMoves,
    required this.moveData,
  });

  final String pokemonName;
  final MoveData newMove;
  final List<String> selectedMoves;
  final Map<String, MoveData?> moveData;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.82,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              context.uiText(
                '$pokemonName sta imparando ${newMove.name}',
                '$pokemonName is learning ${newMove.name}',
              ),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              context.uiText(
                'Il moveset è pieno. Controlla la nuova mossa e scegli quale dimenticare.',
                'The moveset is full. Review the new move and choose one to forget.',
              ),
            ),
            const SizedBox(height: 12),
            _MoveDetailsCard(
              move: newMove,
              title: context.uiText('Nuova mossa', 'New move'),
            ),
            const SizedBox(height: 16),
            Text(
              context.uiText('Mosse da dimenticare', 'Moves to forget'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            for (final entry in selectedMoves.asMap().entries)
              _MoveReplacementTile(
                index: entry.key,
                reference: entry.value,
                move: moveData[entry.value],
              ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(uiTextForLanguage('Annulla', 'Cancel')),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoveReplacementTile extends StatelessWidget {
  const _MoveReplacementTile({
    required this.index,
    required this.reference,
    required this.move,
  });

  final int index;
  final String reference;
  final MoveData? move;

  @override
  Widget build(BuildContext context) {
    final move = this.move;

    return Card(
      child: ListTile(
        leading: move == null
            ? const Icon(Icons.radio_button_unchecked)
            : PokemonTypeBadge(type: move.type, height: 24),
        title: Text((move?.name ?? reference).toUpperCase()),
        subtitle: move == null ? null : _MoveCompactInfo(move: move),
        trailing: Text(context.uiText('Sostituisci', 'Replace')),
        onTap: () => Navigator.of(context).pop(index),
      ),
    );
  }
}

class _MoveCompactInfo extends StatelessWidget {
  const _MoveCompactInfo({required this.move});

  final MoveData move;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      'PP ${move.pp}',
      if (move.range.trim().isNotEmpty && move.range != '-')
        context.uiText('Raggio ${move.range}', 'Range ${move.range}'),
      if (move.damageByLevel.isNotEmpty)
        context.uiText(
          'Danni ${_damageSummary(move)}',
          'Damage ${_damageSummary(move)}',
        ),
      if (move.save != null)
        context.uiText('TS ${move.save}', 'Save ${move.save}'),
    ];

    return Text(
      parts.join(' • '),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _MoveDetailsCard extends StatelessWidget {
  const _MoveDetailsCard({
    required this.move,
    required this.title,
    this.initiallyExpanded = true,
  });

  final MoveData move;
  final String title;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = _moveDetailRows(context, move);

    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: PokemonTypeBadge(type: move.type, height: 26),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(move.name.toUpperCase()),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final detail in details)
                _MoveInfoChip(label: detail.$1, value: detail.$2),
            ],
          ),
          if (move.description.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(move.description.trim()),
            ),
          ],
        ],
      ),
    );
  }
}

class _MoveInfoChip extends StatelessWidget {
  const _MoveInfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          '$label: $value',
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ),
    );
  }
}

List<(String, String)> _moveDetailRows(BuildContext context, MoveData move) {
  return <(String, String)>[
    (
      context.uiText('Tipo', 'Type'),
      PokemonAssetPaths.localizedTypeLabel(move.type),
    ),
    ('PP', move.pp),
    if (move.moveTime.trim().isNotEmpty && move.moveTime != '-')
      (context.uiText('Tempo', 'Time'), move.moveTime),
    if (move.range.trim().isNotEmpty && move.range != '-')
      (context.uiText('Raggio', 'Range'), move.range),
    if (move.duration.trim().isNotEmpty && move.duration != '-')
      (context.uiText('Durata', 'Duration'), move.duration),
    if (move.movePowers.isNotEmpty) ('Power', move.movePowers.join('/')),
    if (move.damageByLevel.isNotEmpty)
      (context.uiText('Danni', 'Damage'), _damageSummary(move)),
    if (move.damageTypes.isNotEmpty)
      (
        uiTextForLanguage('Danno tipo', 'Damage type'),
        move.damageTypes.join('/'),
      ),
    if (move.damageModifier?.trim().isNotEmpty == true)
      ('Mod.', move.damageModifier!.trim()),
    if (move.save?.trim().isNotEmpty == true)
      (context.uiText('TS', 'Save'), move.save!.trim()),
    if (move.attackScope?.trim().isNotEmpty == true)
      (context.uiText('Bersaglio', 'Target'), move.attackScope!.trim()),
  ];
}

String _damageSummary(MoveData move) {
  final entries = move.damageByLevel.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));

  return entries
      .map((entry) => 'Lv.${entry.key} ${entry.value.label}')
      .join(' / ');
}

class _ItemCartResult {
  const _ItemCartResult({required this.quantities});

  final Map<String, int> quantities;
}
