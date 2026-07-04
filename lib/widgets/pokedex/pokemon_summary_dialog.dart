import 'package:flutter/material.dart';

import '../../models/pokedex_entry.dart';
import '../../models/pokemon.dart';
import '../../screens/pokemon/pokemon_detail_screen.dart';
import '../../models/pokemon_flavor.dart';

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
          CircleAvatar(
            radius: 44,
            child: Icon(
              entry.seen ? Icons.catching_pokemon : Icons.question_mark,
              size: 40,
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
            Text(pokemon.types.join(' • ')),
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
