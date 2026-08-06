from pathlib import Path

path = Path('lib/screens/pokemon/pokemon_detail_screen_legacy.dart')
text = path.read_text(encoding='utf-8')


def replace_once(old: str, new: str, label: str) -> None:
    global text
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f'{label}: attesa 1 occorrenza, trovate {count}')
    text = text.replace(old, new, 1)


replace_once(
    """                    _LoyaltyRow(
                      loyalty: loyalty,
""",
    """                    _LoyaltyRow(
                      loyalty: loyalty,
                      compact: compact,
""",
    'passaggio compact alla lealta',
)

replace_once(
    """                    if (compact)
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
""",
    """                    if (compact) ...[
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
                        ],
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: isPartyMode ? onEditExperience : null,
                        borderRadius: BorderRadius.circular(8),
                        child: _ProgressPanel(
                          label: 'EXP: $experience/$nextThreshold',
                          value: expProgress,
                          compact: true,
                        ),
                      ),
                    ] else ...[
""",
    'metriche compatte su tre livelli',
)

replace_once(
    """              if (compact && isPartyMode && evolutionLabel != null) ...[
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
""",
    """""",
    'rimozione icona evoluzione dai PF',
)

replace_once(
    """          if (message != null) ...[
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
""",
    """          if (isPartyMode && evolutionLabel != null) ...[
            SizedBox(height: compact ? 6 : 8),
            SizedBox(
              width: double.infinity,
              height: compact ? 42 : null,
              child: FilledButton(
                onPressed: onEvolve,
                child: Text(evolutionLabel!),
              ),
            ),
          ],
          if (message != null) ...[
            const SizedBox(height: 8),
            _InlineDetailMessage(message: message!),
          ],
""",
    'ripristino pulsante evoluzione esteso',
)

replace_once(
    """class _LoyaltyRow extends StatelessWidget {
  const _LoyaltyRow({
    required this.loyalty,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int loyalty;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FightIconButton(icon: Icons.remove, onPressed: onDecrease),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  context.uiText('LEALTÀ', 'LOYALTY'),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                Text(
                  _signed(loyalty),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        _FightIconButton(icon: Icons.add, onPressed: onIncrease),
      ],
    );
  }
}
""",
    """class _LoyaltyRow extends StatelessWidget {
  const _LoyaltyRow({
    required this.loyalty,
    required this.onDecrease,
    required this.onIncrease,
    this.compact = false,
  });

  final int loyalty;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final buttonSize = compact ? 40.0 : 48.0;
    final spacing = compact ? 4.0 : 6.0;

    return Row(
      children: [
        _FightIconButton(
          icon: Icons.remove,
          onPressed: onDecrease,
          size: buttonSize,
          iconSize: compact ? 22 : 26,
        ),
        SizedBox(width: spacing),
        Expanded(
          child: Container(
            constraints: BoxConstraints(minHeight: buttonSize),
            padding: EdgeInsets.symmetric(
              horizontal: 4,
              vertical: compact ? 2 : 6,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  context.uiText('LEALTÀ', 'LOYALTY'),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1,
                    fontSize: compact ? 10 : null,
                  ),
                ),
                Text(
                  _signed(loyalty),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1,
                    fontSize: compact ? 16 : null,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: spacing),
        _FightIconButton(
          icon: Icons.add,
          onPressed: onIncrease,
          size: buttonSize,
          iconSize: compact ? 22 : 26,
        ),
      ],
    );
  }
}
""",
    'lealta compatta',
)

replace_once(
    """              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: compact ? 11 : null,
                ),
              ),
""",
    """              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: compact ? 11 : null,
                  ),
                ),
              ),
""",
    'valore esperienza adattivo',
)

replace_once(
    """class _FightIconButton extends StatelessWidget {
  const _FightIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton.filled(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(icon, size: 26),
      ),
    );
  }
}
""",
    """class _FightIconButton extends StatelessWidget {
  const _FightIconButton({
    required this.icon,
    required this.onPressed,
    this.size = 48,
    this.iconSize = 26,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: IconButton.filled(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(icon, size: iconSize),
      ),
    );
  }
}
""",
    'dimensioni configurabili pulsanti lotta',
)

path.write_text(text, encoding='utf-8')
print('Aggiornamento header compatto applicato con successo.')
