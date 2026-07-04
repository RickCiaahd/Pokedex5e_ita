import 'package:flutter/material.dart';

import '../../models/pokedex_entry.dart';
import '../../models/pokemon.dart';
import '../pokemon/pokemon_asset_image.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: entry.caught
                    ? colorScheme.primaryContainer
                    : entry.seen
                    ? Colors.white
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: entry.caught
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  width: entry.caught ? 2 : 1,
                ),
              ),
              child: Center(
                child: PokemonAssetImage(
                  pokemon: pokemon,
                  entry: entry,
                  size: 74,
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            entry.seen ? pokemon.name : number,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: entry.caught ? FontWeight.w900 : FontWeight.w700,
              color: entry.seen
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
