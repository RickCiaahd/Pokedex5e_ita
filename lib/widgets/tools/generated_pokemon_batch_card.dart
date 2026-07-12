import 'package:flutter/material.dart';

import '../../models/generated_pokemon.dart';
import '../../models/move_data.dart';
import '../pokemon/pokemon_asset_image.dart';

class GeneratedPokemonBatchCard extends StatelessWidget {
  const GeneratedPokemonBatchCard({
    super.key,
    required this.generated,
    required this.moves,
    required this.isSaving,
    required this.onRegenerate,
    required this.onOpenDetails,
    required this.onRemove,
    required this.onAddAll,
  });

  final List<GeneratedPokemon> generated;
  final Map<String, MoveData?> moves;
  final bool isSaving;
  final ValueChanged<int> onRegenerate;
  final ValueChanged<int> onOpenDetails;
  final ValueChanged<int> onRemove;
  final VoidCallback onAddAll;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.playlist_add_check_circle_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'GRUPPO GENERATO — ${generated.length}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Ogni esemplare ha forma, sesso, natura, abilità, mosse, PF e stato shiny indipendenti.',
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < generated.length; index++) ...[
              _GeneratedBatchTile(
                generated: generated[index],
                moves: moves,
                onRegenerate: () => onRegenerate(index),
                onOpenDetails: () => onOpenDetails(index),
                onRemove: () => onRemove(index),
              ),
              if (index != generated.length - 1) const Divider(height: 1),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: isSaving || generated.isEmpty ? null : onAddAll,
              icon: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_circle_outline),
              label: Text(
                isSaving
                    ? 'SALVATAGGIO...'
                    : 'AGGIUNGI TUTTI A SQUADRA / PC',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Vengono riempiti prima i Pokéslot sbloccati e liberi; tutti gli altri Pokémon vanno nel PC.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _GeneratedBatchTile extends StatelessWidget {
  const _GeneratedBatchTile({
    required this.generated,
    required this.moves,
    required this.onRegenerate,
    required this.onOpenDetails,
    required this.onRemove,
  });

  final GeneratedPokemon generated;
  final Map<String, MoveData?> moves;
  final VoidCallback onRegenerate;
  final VoidCallback onOpenDetails;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final pokemon = generated.pokemon;
    final genderLabel = switch (generated.gender) {
      'Male' => 'Maschio',
      'Female' => 'Femmina',
      'Genderless' => 'Senza sesso',
      _ => 'Non specificato',
    };

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      leading: PokemonAssetImage(
        pokemon: generated.basePokemon,
        formName: generated.formName,
        gender: generated.gender,
        isShiny: generated.isShiny,
        size: 58,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              generated.basePokemon.name,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          if (generated.isShiny)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.auto_awesome, size: 18),
            ),
        ],
      ),
      subtitle: Text(
        '${generated.formLabel} · Livello ${generated.level} · $genderLabel · SR ${_formatSr(pokemon.sr)}',
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 6,
            runSpacing: 5,
            children: [
              for (final type in pokemon.types)
                PokemonTypeBadge(type: type, height: 19),
              Chip(label: Text('PF ${generated.maxHp}')),
              Chip(label: Text(generated.nature)),
              if (generated.ability != null)
                Chip(label: Text(generated.ability!)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Mosse',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: generated.selectedMoves.isEmpty
              ? const Text('Nessuna mossa naturale disponibile.')
              : Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: [
                    for (final reference in generated.selectedMoves)
                      Chip(label: Text(moves[reference]?.name ?? reference)),
                  ],
                ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.end,
          children: [
            TextButton.icon(
              onPressed: onRegenerate,
              icon: const Icon(Icons.casino_outlined),
              label: const Text('Rigenera'),
            ),
            TextButton.icon(
              onPressed: onOpenDetails,
              icon: const Icon(Icons.description_outlined),
              label: const Text('Scheda'),
            ),
            TextButton.icon(
              onPressed: onRemove,
              icon: const Icon(Icons.close),
              label: const Text('Rimuovi'),
            ),
          ],
        ),
      ],
    );
  }

  static String _formatSr(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}
