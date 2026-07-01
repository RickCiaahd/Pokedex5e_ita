import 'package:flutter/material.dart';

import '../../models/pokedex_entry.dart';
import '../../models/pokemon.dart';

class PokemonTile extends StatelessWidget {
  const PokemonTile({
    super.key,
    required this.pokemon,
    required this.entry,
    required this.onTap,
  });

  final Pokemon pokemon;
  final PokedexEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final number = '#${pokemon.id.toString().padLeft(3, '0')}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: entry.seen ? 1 : 0.45,
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: entry.caught
                      ? Colors.green.shade200
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: entry.caught
                        ? Colors.green
                        : Colors.grey.shade500,
                    width: entry.caught ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    entry.seen
                        ? Icons.catching_pokemon
                        : Icons.question_mark,
                    size: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              entry.seen ? pokemon.name : number,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}