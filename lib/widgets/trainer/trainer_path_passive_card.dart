import 'package:flutter/material.dart';

import '../../services/trainer_path_passive_service.dart';

class TrainerPathPassiveCard extends StatelessWidget {
  const TrainerPathPassiveCard({
    super.key,
    required this.trainerPath,
    required this.notes,
  });

  final String trainerPath;
  final List<TrainerPathPassiveNote> notes;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;

    return Card(
      color: colors.secondaryContainer.withValues(alpha: 0.55),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: colors.onSecondaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'BONUS PASSIVI TRAINER PATH',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colors.onSecondaryContainer,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (trainerPath.isNotEmpty)
                  Chip(
                    label: Text(trainerPath),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            for (var index = 0; index < notes.length; index++) ...[
              Text(
                notes[index].title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(notes[index].detail),
              if (index != notes.length - 1) const Divider(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}
