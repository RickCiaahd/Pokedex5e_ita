import 'package:flutter/material.dart';

import '../../localization/ui_text.dart';

class PokemonBattleAttributesCard extends StatelessWidget {
  const PokemonBattleAttributesCard({super.key, required this.attributes});

  final Map<String, int> attributes;

  static const List<(String, String, String)> _attributeLabels = [
    ('STR', 'Forza', 'Strength'),
    ('DEX', 'Destrezza', 'Dexterity'),
    ('CON', 'Costituzione', 'Constitution'),
    ('INT', 'Intelligenza', 'Intelligence'),
    ('WIS', 'Saggezza', 'Wisdom'),
    ('CHA', 'Carisma', 'Charisma'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined, size: 20, color: colors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    context.uiText('CARATTERISTICHE', 'ABILITY SCORES'),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            LayoutBuilder(
              builder: (context, constraints) {
                if (!constraints.hasBoundedWidth || constraints.maxWidth <= 0) {
                  return const SizedBox.shrink();
                }

                final textScale = MediaQuery.textScalerOf(context).scale(1);
                final columns = constraints.maxWidth < 320 || textScale > 1.3
                    ? 3
                    : 6;
                const spacing = 4.0;
                final itemWidth =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final (key, italianLabel, englishLabel)
                        in _attributeLabels)
                      SizedBox(
                        width: itemWidth,
                        child: _CompactAttributeTile(
                          abbreviation: key,
                          label: context.uiText(italianLabel, englishLabel),
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

class _CompactAttributeTile extends StatelessWidget {
  const _CompactAttributeTile({
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

    return Semantics(
      container: true,
      label: '$label: $score, $modifierLabel',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                abbreviation,
                maxLines: 1,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$score',
                  maxLines: 1,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                modifierLabel,
                maxLines: 1,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
