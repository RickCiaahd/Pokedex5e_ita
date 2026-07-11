import 'package:flutter/material.dart';

import '../../models/pokedex_entry.dart';
import '../../models/pokemon.dart';
import '../../services/pokedex_form_catalog.dart';
import '../pokemon/pokemon_asset_image.dart';

class PokemonTile extends StatelessWidget {
  const PokemonTile({
    super.key,
    required this.pokemon,
    required this.entry,
    required this.form,
    required this.onTap,
  });

  final Pokemon pokemon;
  final PokedexEntry entry;
  final PokedexFormOption form;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final number = '#${pokemon.id.toString().padLeft(3, '0')}';
    final colorScheme = Theme.of(context).colorScheme;
    final status = form.statusFor(entry);
    final visibilityEntry = PokedexEntry(
      pokemonId: pokemon.id,
      seen: status.seen,
      caught: status.caught,
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
                color: status.caught
                    ? Colors.white
                    : status.seen
                    ? const Color(0xFFF6F6F6)
                    : const Color(0xFFE4E1DC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: status.caught
                      ? colorScheme.primary
                      : status.seen
                      ? colorScheme.outlineVariant
                      : colorScheme.outline.withValues(alpha: 0.45),
                  width: status.caught ? 2 : 1,
                ),
                boxShadow: status.caught
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
                  if (status.caught || status.seen)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Icon(
                        status.caught
                            ? Icons.catching_pokemon
                            : Icons.visibility,
                        size: 18,
                        color: status.caught
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
                          alpha: status.seen ? 0.10 : 0.18,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  PokemonAssetImage(
                    pokemon: pokemon,
                    entry: visibilityEntry,
                    formName: form.formName,
                    useLargeArtwork: true,
                    size: 96,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            status.seen ? pokemon.name : number,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: status.caught ? FontWeight.w900 : FontWeight.w700,
              color: status.seen
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
