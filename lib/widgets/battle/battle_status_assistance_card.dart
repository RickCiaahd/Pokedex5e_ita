import 'package:flutter/material.dart';

import '../../services/battle_status_rules.dart';
import '../../localization/ui_text.dart';

class BattleStatusAssistanceCard extends StatelessWidget {
  const BattleStatusAssistanceCard({
    super.key,
    required this.pokemonName,
    required this.nonVolatileStatus,
    required this.volatileStatuses,
    required this.selectedMoment,
    required this.onMomentChanged,
  });

  final String pokemonName;
  final String? nonVolatileStatus;
  final Set<String> volatileStatuses;
  final BattleStatusMoment selectedMoment;
  final ValueChanged<BattleStatusMoment> onMomentChanged;

  @override
  Widget build(BuildContext context) {
    if (!BattleStatusRules.hasSupportedStatus(
      nonVolatileStatus: nonVolatileStatus,
      volatileStatuses: volatileStatuses,
    )) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).colorScheme;
    final passive = BattleStatusRules.passiveReminders(
      nonVolatileStatus: nonVolatileStatus,
      volatileStatuses: volatileStatuses,
    );
    final contextual = BattleStatusRules.remindersForMoment(
      nonVolatileStatus: nonVolatileStatus,
      volatileStatuses: volatileStatuses,
      moment: selectedMoment,
    );
    final statuses = <String>[
      ?nonVolatileStatus,
      ...(volatileStatuses.toList()..sort()),
    ];

    return Card(
      color: colors.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.fact_check_outlined,
                  color: colors.onTertiaryContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        uiTextForLanguage(
                          'ASSISTENZA STATUS',
                          'STATUS ASSISTANCE',
                        ),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: colors.onTertiaryContainer,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$pokemonName · ${statuses.join(', ')}',
                        style: TextStyle(color: colors.onTertiaryContainer),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final moment in BattleStatusMoment.values) ...[
                    ChoiceChip(
                      label: Text(moment.label),
                      selected: selectedMoment == moment,
                      onSelected: (_) => onMomentChanged(moment),
                    ),
                    if (moment != BattleStatusMoment.values.last)
                      const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            _ReminderSection(
              title: uiTextForLanguage(
                'EFFETTI SEMPRE ATTIVI',
                """ALWAYS-ACTIVE EFFECTS""",
              ),
              reminders: passive,
              emptyMessage: uiTextForLanguage(
                'Nessun effetto passivo da ricordare.',
                """No passive effects to remember.""",
              ),
            ),
            const SizedBox(height: 12),
            Text(
              selectedMoment.label,
              style: TextStyle(
                color: colors.onTertiaryContainer,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              selectedMoment.description,
              style: TextStyle(color: colors.onTertiaryContainer),
            ),
            const SizedBox(height: 8),
            _ReminderSection(
              reminders: contextual,
              emptyMessage: uiTextForLanguage(
                'Nessun tiro o danno richiesto in questa fase.',
                """No roll or damage is required at this stage.""",
              ),
            ),
            const SizedBox(height: 10),
            Text(
              uiTextForLanguage(
                'Le durate e il periodo di protezione dopo la guarigione restano manuali: il pannello non tira dadi e non rimuove automaticamente gli status.',
                """Durations and the protection period after healing remain manual: the panel does not roll dice or remove statuses automatically.""",
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onTertiaryContainer,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderSection extends StatelessWidget {
  const _ReminderSection({
    required this.reminders,
    required this.emptyMessage,
    this.title,
  });

  final String? title;
  final List<BattleStatusReminder> reminders;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: TextStyle(
              color: colors.onTertiaryContainer,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
        ],
        if (reminders.isEmpty)
          Text(
            emptyMessage,
            style: TextStyle(color: colors.onTertiaryContainer),
          )
        else
          for (final reminder in reminders) ...[
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${reminder.status.toUpperCase()} · ${reminder.title}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(reminder.instruction),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
      ],
    );
  }
}
