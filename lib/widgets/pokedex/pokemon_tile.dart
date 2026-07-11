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
    this.previewFormName,
  });

  final Pokemon pokemon;
  final PokedexEntry entry;
  final String? previewFormName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final number = '#${pokemon.id.toString().padLeft(3, '0')}';
    final colorScheme = Theme.of(context).colorScheme;
    final previewEntry = entry.viewForForm(
      previewFormName,
      speciesName: pokemon.name,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
              decoration: BoxDecoration(
                color: previewEntry.caught
                    ? Colors.white
                    : previewEntry.seen
                        ? const Color(0xFFF6F6F6)
                        : const Color(0xFFE4E1DC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: previewEntry.caught
                      ? colorScheme.primary
                      : previewEntry.seen
                          ? colorScheme.outlineVariant
                          : colorScheme.outline.withValues(alpha: 0.45),
                  width: previewEntry.caught ? 2 : 1,
                ),
                boxShadow: previewEntry.caught
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.14),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.86),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        number,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                  ),
                  if (previewEntry.caught || previewEntry.seen)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Icon(
                        previewEntry.caught
                            ? Icons.catching_pokemon
                            : Icons.visibility,
                        size: 18,
                        color: previewEntry.caught
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  Positioned(
                    bottom: 4,
                    child: Container(
                      width: 54,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(
                          alpha: previewEntry.seen ? 0.10 : 0.18,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  PokemonAssetImage(
                    pokemon: pokemon,
                    entry: previewEntry,
                    formName: previewFormName,
                    useLargeArtwork: true,
                    size: 96,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            previewEntry.seen ? pokemon.name : number,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: previewEntry.caught
                      ? FontWeight.w900
                      : FontWeight.w700,
                  color: previewEntry.seen
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
