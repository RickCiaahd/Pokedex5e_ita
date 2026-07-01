import 'package:flutter/material.dart';

import '../../models/pokemon.dart';
import '../../screens/pokemon/pokemon_detail_screen.dart';

class PokemonSummaryDialog extends StatelessWidget {
  const PokemonSummaryDialog({
    super.key,
    required this.pokemon,
  });

  final Pokemon pokemon;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        '${pokemon.name} #${pokemon.id.toString().padLeft(3, '0')}',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 44,
            child: Text(
              pokemon.id.toString(),
              style: const TextStyle(fontSize: 22),
            ),
          ),
          const SizedBox(height: 16),
          Text(pokemon.types.join(' • ')),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Text('CA: ${pokemon.armorClass}')),
              Expanded(child: Text('PF: ${pokemon.hitPoints}')),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Chiudi'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PokemonDetailScreen(pokemon: pokemon),
              ),
            );
          },
          child: const Text('Scheda completa'),
        ),
      ],
    );
  }
}