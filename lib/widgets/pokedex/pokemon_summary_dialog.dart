import 'package:flutter/material.dart';

import '../../models/pokedex_entry.dart';
import '../../models/pokemon.dart';
import '../../screens/pokemon/pokemon_detail_screen.dart';
import '../../models/pokemon_flavor.dart';
import '../pokemon/pokemon_asset_image.dart';

class PokemonSummaryDialog extends StatelessWidget {
  const PokemonSummaryDialog({
    super.key,
    required this.pokemon,
    this.flavor,
    required this.entry,
    required this.onToggleSeen,
    required this.onToggleCaught,
  });

  final Pokemon pokemon;
  final PokemonFlavor? flavor;
  final PokedexEntry entry;
  final VoidCallback onToggleSeen;
  final VoidCallback onToggleCaught;

  @override
  Widget build(BuildContext context) {
    final number = '#${pokemon.id.toString().padLeft(3, '0')}';

    return AlertDialog(
      title: Text('${pokemon.name} $number'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: entry.caught
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: PokemonAssetImage(
                pokemon: pokemon,
                entry: entry,
                useLargeArtwork: true,
                size: 96,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (flavor != null) ...[
            Text(
              flavor!.genus,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Altezza: ${flavor!.heightMeters.toStringAsFixed(1)} m · '
              'Peso: ${flavor!.weightKg.toStringAsFixed(1)} kg',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(flavor!.flavor, textAlign: TextAlign.center),
            const SizedBox(height: 16),
          ],
          if (entry.seen) ...[
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final type in pokemon.types)
                  PokemonTypeBadge(type: type, height: 24),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Text('CA: ${pokemon.armorClass}')),
                Expanded(child: Text('PF: ${pokemon.hitPoints}')),
              ],
            ),
          ] else
            const Text('Pokémon non ancora visto.'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onToggleSeen,
          child: Text(entry.seen ? 'Non visto' : 'Visto'),
        ),
        TextButton(
          onPressed: onToggleCaught,
          child: Text(entry.caught ? 'Non catturato' : 'Catturato'),
        ),
        FilledButton(
          onPressed: entry.seen
              ? () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PokemonDetailScreen(pokemon: pokemon),
                    ),
                  );
                }
              : null,
          child: const Text('Scheda'),
        ),
      ],
    );
  }
}
