import 'package:flutter/material.dart';

import 'pokemon_type_badge.dart';

/// Mantiene i badge dei tipi sulla stessa riga anche negli spazi compatti.
class PokemonTypeBadgeRow extends StatelessWidget {
  const PokemonTypeBadgeRow({
    super.key,
    required this.types,
    this.height = 17,
    this.spacing = 6,
  });

  final List<String> types;
  final double height;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (types.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        for (var index = 0; index < types.length; index++) ...[
          if (index > 0) SizedBox(width: spacing),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: PokemonTypeBadge(
                key: ValueKey<String>('pokemon-type-badge-$index'),
                type: types[index],
                height: height,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
