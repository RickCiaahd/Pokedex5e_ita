import 'package:flutter/material.dart';

import '../../localization/game_catalog_locale.dart';
import 'pokemon_asset_image_legacy.dart' as legacy;

/// Etichetta grafica del tipo Pokémon nella lingua attiva.
///
/// Le immagini italiane restano nella cartella storica `type_names`, mentre le
/// corrispondenti immagini inglesi vengono cercate in `type_names/en`.
class PokemonTypeBadge extends StatelessWidget {
  const PokemonTypeBadge({
    super.key,
    required this.type,
    this.height = 24,
    this.fallbackTextStyle,
  });

  final String type;
  final double height;
  final TextStyle? fallbackTextStyle;

  @override
  Widget build(BuildContext context) {
    final localizedLabel = legacy.PokemonAssetPaths.localizedTypeLabel(type);
    final assetName = _assetName(localizedLabel).toLowerCase();
    final root = GameCatalogLocale.isItalian
        ? 'assets/textures/type_names'
        : 'assets/textures/type_names/en';
    final assetPath = '$root/$assetName.png';
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          localizedLabel.toUpperCase(),
          style:
              fallbackTextStyle ??
              Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w900,
              ),
        ),
      ),
    );

    if (!_assetBackedTypes.contains(type.trim().toLowerCase())) {
      return fallback;
    }

    return Image.asset(
      assetPath,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => fallback,
    );
  }

  static const Set<String> _assetBackedTypes = {
    'bug',
    'coleottero',
    'dark',
    'buio',
    'dragon',
    'drago',
    'electric',
    'elettro',
    'fairy',
    'folletto',
    'fighting',
    'lotta',
    'fire',
    'fuoco',
    'flying',
    'volante',
    'ghost',
    'spettro',
    'grass',
    'erba',
    'ground',
    'terra',
    'ice',
    'ghiaccio',
    'normal',
    'normale',
    'poison',
    'veleno',
    'psychic',
    'psico',
    'rock',
    'roccia',
    'steel',
    'acciaio',
    'water',
    'acqua',
  };

  static String _assetName(String value) {
    return value
        .trim()
        .replaceAll(':', '')
        .replaceAll('.', '')
        .replaceAll("'", '')
        .replaceAll('’', '')
        .replaceAll(' ', '_')
        .replaceAll('-', '_');
  }
}
