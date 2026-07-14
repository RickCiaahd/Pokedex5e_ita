import 'package:flutter/material.dart';

import '../../models/pokemon.dart';
import '../../services/evolution_service.dart';
import '../../widgets/pokemon/pokemon_asset_image.dart';

class EvolutionSelectorSheet extends StatelessWidget {
  const EvolutionSelectorSheet({
    super.key,
    required this.currentPokemon,
    required this.choices,
    required this.pokemonByName,
  });

  final Pokemon currentPokemon;
  final List<EvolutionEligibility> choices;
  final Pokemon? Function(String name) pokemonByName;

  @override
  Widget build(BuildContext context) {
    final availableChoices = choices
        .where(
          (choice) =>
              choice.isAvailable && pokemonByName(choice.option.toName) != null,
        )
        .toList(growable: false);
    final isSingleEvolution = choices.length == 1;
    final title = isSingleEvolution ? 'Evoluzione' : 'Scegli evoluzione';
    final description = isSingleEvolution
        ? 'Controlla i requisiti per far evolvere ${currentPokemon.name}.'
        : '${currentPokemon.name} può evolversi in ${choices.length} forme.';

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.78,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(description),
            if (availableChoices.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Nessuna evoluzione soddisfa ancora tutte le condizioni gestibili.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            for (final choice in choices)
              _EvolutionChoiceTile(
                choice: choice,
                targetPokemon: pokemonByName(choice.option.toName),
                actionLabel: isSingleEvolution ? 'Evolvi' : 'Scegli',
              ),
          ],
        ),
      ),
    );
  }
}

class _EvolutionChoiceTile extends StatelessWidget {
  const _EvolutionChoiceTile({
    required this.choice,
    required this.targetPokemon,
    required this.actionLabel,
  });

  final EvolutionEligibility choice;
  final Pokemon? targetPokemon;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final targetPokemon = this.targetPokemon;
    final isAvailable = choice.isAvailable && targetPokemon != null;
    final conditionLabels = choice.conditionLabels;

    return Card(
      child: ListTile(
        enabled: isAvailable,
        leading: targetPokemon == null
            ? const Icon(Icons.catching_pokemon)
            : PokemonAssetImage(pokemon: targetPokemon, size: 52),
        title: Text(
          choice.option.toName.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (conditionLabels.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final label in conditionLabels)
                      _ConditionChip(
                        label: label,
                        satisfied: choice.isAvailable,
                      ),
                  ],
                ),
              if (targetPokemon == null) ...[
                const SizedBox(height: 6),
                Text(
                  'Pokémon non presente nel catalogo attuale.',
                  style: TextStyle(color: colorScheme.error),
                ),
              ] else if (choice.missingRequirements.isNotEmpty) ...[
                const SizedBox(height: 6),
                for (final missing in choice.missingRequirements)
                  Text(
                    '• $missing',
                    style: TextStyle(color: colorScheme.error),
                  ),
              ],
            ],
          ),
        ),
        trailing: isAvailable
            ? Text(
                actionLabel,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              )
            : Icon(Icons.lock_outline, color: colorScheme.outline),
        onTap: isAvailable ? () => Navigator.of(context).pop(choice) : null,
      ),
    );
  }
}

class _ConditionChip extends StatelessWidget {
  const _ConditionChip({required this.label, required this.satisfied});

  final String label;
  final bool satisfied;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = satisfied
        ? colorScheme.primaryContainer
        : colorScheme.errorContainer;
    final foreground = satisfied
        ? colorScheme.onPrimaryContainer
        : colorScheme.onErrorContainer;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
