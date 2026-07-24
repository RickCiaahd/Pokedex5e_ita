import 'package:flutter/material.dart';

class PokemonBattleAttributesCard extends StatelessWidget {
  const PokemonBattleAttributesCard({
    super.key,
    required this.attributes,
  });

  final Map<String, int> attributes;

  static const List<(String, String)> _attributeLabels = [
    ('STR', 'Forza'),
    ('DEX', 'Destrezza'),
    ('CON', 'Costituzione'),
    ('INT', 'Intelligenza'),
    ('WIS', 'Saggezza'),
    ('CHA', 'Carisma'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'CARATTERISTICHE',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Valori effettivi e modificatori da usare per prove, tiri salvezza e iniziativa del Pokémon.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                if (!constraints.hasBoundedWidth ||
                    constraints.maxWidth <= 0) {
                  return const SizedBox.shrink();
                }

                final availableWidth = constraints.maxWidth;
                final columns = availableWidth >= 620
                    ? 6
                    : availableWidth >= 360
                        ? 3
                        : availableWidth >= 180
                            ? 2
                            : 1;
                const spacing = 8.0;
                final occupiedBySpacing = spacing * (columns - 1);
                final itemWidth =
                    (availableWidth - occupiedBySpacing) / columns;

                if (itemWidth <= 0) {
                  return const SizedBox.shrink();
                }

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final (key, label) in _attributeLabels)
                      SizedBox(
                        width: itemWidth,
                        child: _AttributeTile(
                          abbreviation: key,
                          label: label,
                          score: attributes[key] ?? 0,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AttributeTile extends StatelessWidget {
  const _AttributeTile({
    required this.abbreviation,
    required this.label,
    required this.score,
  });

  final String abbreviation;
  final String label;
  final int score;

  int get modifier => ((score - 10) / 2).floor();

  String get modifierLabel => modifier >= 0 ? '+$modifier' : '$modifier';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          children: [
            Text(
              abbreviation,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 6),
            Text(
              '$score',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                modifierLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
