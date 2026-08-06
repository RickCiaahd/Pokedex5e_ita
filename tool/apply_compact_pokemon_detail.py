from __future__ import annotations

from pathlib import Path

TARGET = Path("lib/screens/pokemon/pokemon_detail_screen_legacy.dart")


def replace_between(text: str, start: str, end: str, replacement: str) -> str:
    start_index = text.index(start)
    end_index = text.index(end, start_index)
    return text[:start_index] + replacement.rstrip() + "\n\n" + text[end_index:]


def replace_build_method(text: str, class_name: str, replacement: str) -> str:
    class_marker = f"class {class_name} "
    class_index = text.index(class_marker)
    method_marker = "  @override\n  Widget build(BuildContext context) {"
    method_index = text.index(method_marker, class_index)
    brace_index = text.index("{", method_index)
    depth = 0
    method_end = None
    for index in range(brace_index, len(text)):
        char = text[index]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                method_end = index + 1
                break
    if method_end is None:
        raise RuntimeError(f"Could not find build method end for {class_name}")
    return text[:method_index] + replacement.rstrip() + text[method_end:]


text = TARGET.read_text(encoding="utf-8")

header_build = r'''  @override
  Widget build(BuildContext context) {
    final number = '#${pokemon.id.toString().padLeft(3, '0')}';
    final nextThreshold = LevelProgression.nextThresholdForLevel(level);
    final currentThreshold = LevelProgression.thresholdForLevel(level);
    final range = nextThreshold - currentThreshold;
    final expProgress = range <= 0
        ? 1.0
        : ((experience - currentThreshold) / range).clamp(0.0, 1.0).toDouble();
    final hpProgress = maxHp <= 0
        ? 0.0
        : (currentHp / maxHp).clamp(0.0, 1.0).toDouble();
    final compact = MediaQuery.sizeOf(context).width < 520;

    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 6 : 8, 6, compact ? 6 : 8, 4),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PokemonCenterButton(
                onTap: isPartyMode ? onPokemonCenter : null,
                compact: compact,
              ),
              SizedBox(width: compact ? 4 : 6),
              Card(
                margin: EdgeInsets.zero,
                child: SizedBox(
                  width: compact ? 108 : 132,
                  height: compact ? 136 : 142,
                  child: Padding(
                    padding: EdgeInsets.all(compact ? 4 : 6),
                    child: Column(
                      children: [
                        Expanded(
                          child: PokemonAssetImage(
                            pokemon: imagePokemon,
                            formName: slot?.effectiveFormName,
                            gender: slot?.gender,
                            isShiny: slot?.isShiny,
                            useLargeArtwork: true,
                            size: compact ? 96 : 112,
                          ),
                        ),
                        Text(
                          '$number ${pokemon.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: compact ? 6 : 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (compact)
                      SizedBox(
                        height: 34,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                pokemon.name.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                            ),
                            if (pokemon.types.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (final type in pokemon.types.take(2))
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 1,
                                      ),
                                      child: PokemonTypeBadge(
                                        type: type,
                                        height: 15,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      )
                    else ...[
                      Text(
                        pokemon.name.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final type in pokemon.types)
                            PokemonTypeBadge(type: type, height: 20),
                        ],
                      ),
                    ],
                    SizedBox(height: compact ? 4 : 6),
                    _LoyaltyRow(
                      loyalty: loyalty,
                      onDecrease: loyalty <= -3 ? null : onDecreaseLoyalty,
                      onIncrease: loyalty >= 3 ? null : onIncreaseLoyalty,
                    ),
                    SizedBox(height: compact ? 4 : 6),
                    if (compact)
                      Row(
                        children: [
                          Expanded(
                            child: _MetricBox(
                              label: context.uiText('Liv.', 'Lv.'),
                              value: '$level',
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _MetricBox(
                              label: context.uiText('CA:', 'AC:'),
                              value: '$armorClass',
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            flex: 2,
                            child: InkWell(
                              onTap: isPartyMode ? onEditExperience : null,
                              borderRadius: BorderRadius.circular(8),
                              child: _ProgressPanel(
                                label: 'EXP: $experience/$nextThreshold',
                                value: expProgress,
                                compact: true,
                              ),
                            ),
                          ),
                        ],
                      )
                    else ...[
                      Row(
                        children: [
                          Expanded(
                            child: _MetricBox(
                              label: context.uiText('Liv.', 'Lv.'),
                              value: '$level',
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _MetricBox(
                              label: context.uiText('CA:', 'AC:'),
                              value: '$armorClass',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: isPartyMode ? onEditExperience : null,
                        borderRadius: BorderRadius.circular(8),
                        child: _ProgressPanel(
                          label: 'EXP: $experience/$nextThreshold',
                          value: expProgress,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 5 : 6),
          _FightStatsGrid(
            attributes: attributes,
            modifierBuilder: modifierBuilder,
          ),
          const SizedBox(height: 4),
          _SavingThrowsRow(
            attributes: attributes,
            savingThrows: savingThrows,
            modifierBuilder: modifierBuilder,
            proficiency: proficiency,
            loyaltyBonus: savingThrowLoyaltyBonus,
          ),
          SizedBox(height: compact ? 5 : 6),
          Row(
            children: [
              Expanded(
                child: _StatusPanelButton(
                  statuses: statusEffects,
                  onTap: isPartyMode ? onAddStatusEffect : null,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: InkWell(
                  onTap: isPartyMode ? onEditHeldItem : null,
                  borderRadius: BorderRadius.circular(8),
                  child: _PanelButton(
                    label: context.uiText(
                      'STRUMENTO: $heldItemLabel',
                      'ITEM: $heldItemLabel',
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 6 : 8),
          Row(
            children: [
              _FightIconButton(icon: Icons.remove, onPressed: onDecreaseHp),
              SizedBox(width: compact ? 6 : 8),
              Expanded(
                child: InkWell(
                  onTap: isPartyMode ? onEditHp : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: compact ? 4 : 6),
                    child: Row(
                      children: [
                        Text(
                          context.uiText(
                            'PF: $currentHp/$maxHp',
                            'HP: $currentHp/$maxHp',
                          ),
                          style: (compact
                                  ? Theme.of(context).textTheme.titleMedium
                                  : Theme.of(context).textTheme.titleLarge)
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        SizedBox(width: compact ? 8 : 12),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: hpProgress,
                              minHeight: compact ? 12 : 16,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _hpProgressColor(hpProgress),
                              ),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (compact && isPartyMode && evolutionLabel != null) ...[
                const SizedBox(width: 6),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton.outlined(
                    tooltip: evolutionLabel,
                    onPressed: onEvolve,
                    icon: const Icon(Icons.trending_up),
                  ),
                ),
              ],
              SizedBox(width: compact ? 6 : 8),
              _FightIconButton(icon: Icons.add, onPressed: onIncreaseHp),
            ],
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            _InlineDetailMessage(message: message!),
          ],
          if (!compact && isPartyMode && evolutionLabel != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onEvolve,
                child: Text(evolutionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }'''

text = replace_build_method(text, "_Header", header_build)

pokemon_center = r'''class _PokemonCenterButton extends StatelessWidget {
  const _PokemonCenterButton({
    required this.onTap,
    this.compact = false,
  });

  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: compact ? 44 : 46,
        height: compact ? 136 : 142,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 32,
              child: Center(
                child: Icon(Icons.local_hospital, color: colorScheme.primary),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      uiTextForLanguage(
                        'POKÉMON CENTER',
                        """POKÉMON CENTER""",
                      ),
                      maxLines: 1,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 9.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}'''
text = replace_between(
    text,
    "class _PokemonCenterButton extends StatelessWidget {",
    "class _PokemonCenterDialog extends StatelessWidget {",
    pokemon_center,
)

progress_panel = r'''class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({
    required this.label,
    required this.value,
    this.compact = false,
  });

  final String label;
  final double value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: compact
          ? textScaleAwareValue(context, normal: 36, enlarged: 50)
          : textScaleAwareValue(context, normal: 46, enlarged: 62),
      padding: EdgeInsets.fromLTRB(8, compact ? 2 : 4, 8, compact ? 4 : 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.primary, width: 1.5),
      ),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: compact ? 11 : null,
                ),
              ),
            ),
          ),
          LinearProgressIndicator(
            value: value,
            minHeight: compact ? 4 : 6,
          ),
        ],
      ),
    );
  }
}'''
text = replace_between(
    text,
    "class _ProgressPanel extends StatelessWidget {",
    "class _PanelButton extends StatelessWidget {",
    progress_panel,
)

stats_grid = r'''class _FightStatsGrid extends StatelessWidget {
  const _FightStatsGrid({
    required this.attributes,
    required this.modifierBuilder,
  });

  final Map<String, int> attributes;
  final int Function(int score) modifierBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final singleRow =
            compact && accessibleTextScaleRatio(context) <= 1.3;
        final columns = singleRow || !compact ? 6 : 3;
        final aspectRatio = singleRow
            ? 0.98
            : compact
            ? textScaleAwareValue(context, normal: 1.85, enlarged: 1.1)
            : textScaleAwareValue(context, normal: 1.18, enlarged: 0.82);

        return GridView.count(
          crossAxisCount: columns,
          childAspectRatio: aspectRatio,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final entry in attributes.entries)
              _FightStatBox(
                label: TrainerUiLocalization.abilityAbbreviation(entry.key),
                score: entry.value,
                modifier: modifierBuilder(entry.value),
                dense: singleRow,
              ),
          ],
        );
      },
    );
  }
}

class _FightStatBox extends StatelessWidget {
  const _FightStatBox({
    required this.label,
    required this.score,
    required this.modifier,
    required this.dense,
  });

  final String label;
  final int score;
  final int modifier;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 2 : 4,
        vertical: dense ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$label $score',
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: (dense
                    ? Theme.of(context).textTheme.labelSmall
                    : Theme.of(context).textTheme.bodyMedium)
                ?.copyWith(color: muted, fontWeight: FontWeight.w800),
          ),
          Text(
            _signed(modifier),
            style: (dense
                    ? Theme.of(context).textTheme.titleLarge
                    : Theme.of(context).textTheme.headlineSmall)
                ?.copyWith(fontWeight: FontWeight.w900, height: 1),
          ),
        ],
      ),
    );
  }
}'''
text = replace_between(
    text,
    "class _FightStatsGrid extends StatelessWidget {",
    "class _SavingThrowsRow extends StatelessWidget {",
    stats_grid,
)

moves_section = r'''class _MovesView extends StatelessWidget {
  const _MovesView({
    required this.selectedMoves,
    required this.moves,
    required this.moveStatsBuilder,
    required this.moveTypeBuilder,
  });

  final List<String> selectedMoves;
  final Map<String, MoveData?> moves;
  final String Function(MoveData move) moveStatsBuilder;
  final String Function(MoveData move) moveTypeBuilder;

  @override
  Widget build(BuildContext context) {
    final names = [...selectedMoves, 'Struggle'];
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      itemCount: names.length,
      itemBuilder: (context, index) {
        final reference = names[index];
        final move = moves[reference];
        return _CompactMoveTile(
          reference: reference,
          move: move,
          moveType: move == null ? null : moveTypeBuilder(move),
          stats: move == null ? null : moveStatsBuilder(move),
        );
      },
    );
  }
}

class _CompactMoveTile extends StatelessWidget {
  const _CompactMoveTile({
    required this.reference,
    required this.move,
    required this.moveType,
    required this.stats,
  });

  final String reference;
  final MoveData? move;
  final String? moveType;
  final String? stats;

  @override
  Widget build(BuildContext context) {
    final move = this.move;
    final name = move?.name ?? reference;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetails(context),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: textScaleAwareValue(
              context,
              normal: 66,
              enlarged: 92,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.radio_button_unchecked,
                      size: 17,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        name.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (move != null) ...[
                      PokemonTypeBadge(
                        type: moveType ?? move.type,
                        height: 19,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'PP ${move.pp}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right, size: 22),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  move == null
                      ? context.uiText(
                          'Dettagli mossa non disponibili.',
                          'Move details are unavailable.',
                        )
                      : (stats?.isNotEmpty == true ? stats! : move.moveTime),
                  maxLines: accessibleTextScaleRatio(context) > 1.3 ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDetails(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _MoveDetailsSheet(
        reference: reference,
        move: move,
        moveType: moveType,
        stats: stats,
      ),
    );
  }
}

class _MoveDetailsSheet extends StatelessWidget {
  const _MoveDetailsSheet({
    required this.reference,
    required this.move,
    required this.moveType,
    required this.stats,
  });

  final String reference;
  final MoveData? move;
  final String? moveType;
  final String? stats;

  @override
  Widget build(BuildContext context) {
    final move = this.move;
    final name = move?.name ?? reference;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      name.toUpperCase(),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  if (move != null)
                    Text(
                      'PP ${move.pp}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (move == null)
                Text(
                  context.uiText(
                    'Dettagli mossa non disponibili.',
                    'Move details are unavailable.',
                  ),
                )
              else ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    PokemonTypeBadge(
                      type: moveType ?? move.type,
                      height: 26,
                    ),
                    Chip(label: Text(move.moveTime)),
                  ],
                ),
                if (stats?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Text(
                    stats!,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                if (move.description.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 6),
                  Text(move.description),
                ],
              ],
              const SizedBox(height: 18),
              FilledButton.tonal(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.uiText('CHIUDI', 'CLOSE')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoveCard extends StatelessWidget {
  const _MoveCard({
    required this.reference,
    required this.move,
    required this.moveType,
    required this.stats,
  });

  final String reference;
  final MoveData? move;
  final String? moveType;
  final String? stats;

  @override
  Widget build(BuildContext context) {
    final move = this.move;
    final name = move?.name ?? reference;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.radio_button_unchecked, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name.toUpperCase(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (move != null) Text('PP ${move.pp}'),
              ],
            ),
            const SizedBox(height: 8),
            if (move == null)
              Text(
                context.uiText(
                  'Dettagli mossa non disponibili.',
                  'Move details are unavailable.',
                ),
              )
            else ...[
              if (stats != null && stats!.isNotEmpty) Text(stats!),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  PokemonTypeBadge(type: moveType ?? move.type, height: 24),
                  Chip(label: Text(move.moveTime)),
                ],
              ),
              if (move.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(move.description),
              ],
            ],
          ],
        ),
      ),
    );
  }
}'''
text = replace_between(
    text,
    "class _MovesView extends StatelessWidget {",
    "class _FeaturesView extends StatelessWidget {",
    moves_section,
)

party_switcher = r'''class _PartySwitcher extends StatelessWidget {
  const _PartySwitcher({
    required this.team,
    required this.currentSlotIndex,
    required this.pokemonById,
    required this.onSelect,
  });

  final List<TeamSlot> team;
  final int currentSlotIndex;
  final Pokemon? Function(int? pokemonId) pokemonById;
  final ValueChanged<TeamSlot> onSelect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sortedTeam = [...team]
      ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));

    return SafeArea(
      top: false,
      child: Container(
        height: textScaleAwareValue(
          context,
          normal: 60,
          enlarged: 98,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: Row(
          children: [
            for (final slot in sortedTeam)
              Expanded(
                child: _PartySlotButton(
                  slot: slot,
                  pokemon: pokemonById(slot.pokemonId),
                  isActive: slot.slotIndex == currentSlotIndex,
                  onTap: slot.pokemonId == null ? null : () => onSelect(slot),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PartySlotButton extends StatelessWidget {
  const _PartySlotButton({
    required this.slot,
    required this.pokemon,
    required this.isActive,
    required this.onTap,
  });

  final TeamSlot slot;
  final Pokemon? pokemon;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pokemon = this.pokemon;

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? colorScheme.primary : colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            pokemon == null
                ? Icon(Icons.radio_button_unchecked, color: colorScheme.outline)
                : PokemonAssetImage(
                    pokemon: pokemon,
                    formName: slot.effectiveFormName,
                    gender: slot.gender,
                    isShiny: slot.isShiny,
                    size: 28,
                  ),
            Text(
              pokemon == null
                  ? '${slot.slotIndex + 1}'
                  : '#${pokemon.id.toString().padLeft(3, '0')}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}'''
text = replace_between(
    text,
    "class _PartySwitcher extends StatelessWidget {",
    "class _ExperienceDialog extends StatefulWidget {",
    party_switcher,
)

TARGET.write_text(text, encoding="utf-8")
print(f"Updated {TARGET}")
