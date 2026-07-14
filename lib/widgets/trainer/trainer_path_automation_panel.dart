import 'package:flutter/material.dart';

import '../../services/trainer_path_automation_service.dart';

class TrainerPathAutomationPanel extends StatelessWidget {
  const TrainerPathAutomationPanel({
    super.key,
    required this.trainerPath,
    required this.resources,
    required this.resourceValues,
    required this.choices,
    required this.choiceValues,
    required this.onResourceChanged,
    required this.onChoiceChanged,
    required this.onShortRest,
    required this.onLongRest,
  });

  final String trainerPath;
  final List<TrainerPathResourceDefinition> resources;
  final Map<String, int> resourceValues;
  final List<TrainerPathChoiceDefinition> choices;
  final Map<String, String> choiceValues;
  final void Function(String resourceId, int value) onResourceChanged;
  final void Function(String choiceId, String value) onChoiceChanged;
  final VoidCallback onShortRest;
  final VoidCallback onLongRest;

  @override
  Widget build(BuildContext context) {
    if (trainerPath.trim().isEmpty) return const SizedBox.shrink();

    final missingChoices = TrainerPathAutomationService.missingChoices(
      current: choiceValues,
      definitions: choices,
    );
    final colors = Theme.of(context).colorScheme;

    return Card(
      color: colors.secondaryContainer.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome, color: colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GESTIONE TRAINER PATH',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        trainerPath,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Le risorse massime vengono calcolate dal livello e dalle caratteristiche. Le quantità rimaste e le scelte vengono salvate nella scheda.',
            ),
            if (choices.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'SCELTE DEI PRIVILEGI',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              for (final choice in choices) ...[
                _PathChoiceField(
                  definition: choice,
                  selectedValue: choiceValues[choice.id],
                  onChanged: (value) => onChoiceChanged(choice.id, value),
                ),
                const SizedBox(height: 10),
              ],
              if (missingChoices.isNotEmpty)
                Text(
                  'Completa ${missingChoices.length == 1 ? 'la scelta richiesta' : 'le ${missingChoices.length} scelte richieste'} prima di considerare il path configurato.',
                  style: TextStyle(
                    color: colors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
            if (resources.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'RISORSE DISPONIBILI',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              for (final resource in resources) ...[
                _PathResourceRow(
                  definition: resource,
                  current: (resourceValues[resource.id] ?? resource.maxUses)
                      .clamp(0, resource.maxUses)
                      .toInt(),
                  onChanged: (value) => onResourceChanged(resource.id, value),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: onShortRest,
                    icon: const Icon(Icons.bedtime_outlined),
                    label: const Text('RIPOSO BREVE'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: onLongRest,
                    icon: const Icon(Icons.hotel_outlined),
                    label: const Text('RIPOSO LUNGO'),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 14),
              const Text(
                'A questo livello il path non ha ancora risorse numeriche da consumare.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PathChoiceField extends StatelessWidget {
  const _PathChoiceField({
    required this.definition,
    required this.selectedValue,
    required this.onChanged,
  });

  final TrainerPathChoiceDefinition definition;
  final String? selectedValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = definition.options;
    final selected = options.contains(selectedValue) ? selectedValue : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('${definition.id}-${selected ?? 'none'}'),
          initialValue: selected,
          isExpanded: true,
          decoration: InputDecoration(
            labelText:
                'Lv ${definition.featureLevel} · ${definition.featureTitle}',
            helperText: definition.description,
            helperMaxLines: 3,
            border: const OutlineInputBorder(),
          ),
          hint: Text(
            options.isEmpty ? 'Nessuna opzione disponibile' : definition.label,
          ),
          items: [
            for (final option in options)
              DropdownMenuItem(value: option, child: Text(option)),
          ],
          onChanged: options.isEmpty
              ? null
              : (value) {
                  if (value != null) onChanged(value);
                },
        ),
      ],
    );
  }
}

class _PathResourceRow extends StatelessWidget {
  const _PathResourceRow({
    required this.definition,
    required this.current,
    required this.onChanged,
  });

  final TrainerPathResourceDefinition definition;
  final int current;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    definition.label,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Lv ${definition.featureLevel} · ${definition.featureTitle} · ${definition.resetLabel}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Consuma',
              onPressed: current <= 0 ? null : () => onChanged(current - 1),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            SizedBox(
              width: 74,
              child: Text(
                '$current/${definition.maxUses} ${definition.unitLabel}',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            IconButton(
              tooltip: 'Recupera',
              onPressed: current >= definition.maxUses
                  ? null
                  : () => onChanged(current + 1),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ),
    );
  }
}
