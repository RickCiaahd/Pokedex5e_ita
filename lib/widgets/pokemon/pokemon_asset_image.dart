import 'package:flutter/material.dart';

import '../../models/pokedex_entry.dart';
import '../../models/pokemon.dart';

class PokemonAssetImage extends StatelessWidget {
  const PokemonAssetImage({
    super.key,
    required this.pokemon,
    this.size = 72,
    this.fit = BoxFit.contain,
    this.useLargeArtwork = false,
    this.entry,
    this.fallback,
  });

  final Pokemon pokemon;
  final double size;
  final BoxFit fit;
  final bool useLargeArtwork;
  final PokedexEntry? entry;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final entry = this.entry;
    final seen = entry?.seen ?? true;
    final caught = entry?.caught ?? true;

    Widget image = _AssetFallbackImage(
      assetPaths: PokemonAssetPaths.imageCandidates(
        pokemon: pokemon,
        useLargeArtwork: useLargeArtwork,
      ),
      width: size,
      height: size,
      fit: fit,
      fallback:
          fallback ??
          Icon(
            seen ? Icons.catching_pokemon : Icons.question_mark,
            size: size * 0.48,
            color: seen
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );

    if (!seen) {
      image = ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcATop),
        child: image,
      );
    } else if (!caught) {
      image = Opacity(
        opacity: 0.56,
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.2126,
            0.7152,
            0.0722,
            0,
            52,
            0.2126,
            0.7152,
            0.0722,
            0,
            52,
            0.2126,
            0.7152,
            0.0722,
            0,
            52,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: image,
        ),
      );
    }

    return SizedBox(width: size, height: size, child: image);
  }
}

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
    return _AssetFallbackImage(
      assetPaths: PokemonAssetPaths.typeCandidates(type),
      height: height,
      fit: BoxFit.contain,
      fallback: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            PokemonAssetPaths.localizedTypeLabel(type).toUpperCase(),
            style:
                fallbackTextStyle ??
                Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
      ),
    );
  }
}

class PokemonAssetPaths {
  const PokemonAssetPaths._();

  static List<String> imageCandidates({
    required Pokemon pokemon,
    required bool useLargeArtwork,
  }) {
    final folder = useLargeArtwork ? 'pokemons' : 'sprites';
    final alternateFolder = useLargeArtwork ? 'sprites' : 'pokemons';
    final id = pokemon.id.toString();
    final paddedId = id.padLeft(3, '0');
    final rawName = pokemon.name.trim();
    final assetName = _assetName(rawName);
    final compactName = _compactAssetName(rawName);

    final fileNames = <String>{
      '$id$rawName.png',
      '$paddedId$rawName.png',
      '$id$assetName.png',
      '$paddedId$assetName.png',
      '$id$compactName.png',
      '$paddedId$compactName.png',
      '$paddedId.png',
      '$id.png',
      '$rawName.png',
      '$assetName.png',
      '$compactName.png',
      assetName.toLowerCase() + '.png',
      compactName.toLowerCase() + '.png',
    };

    return <String>[
      for (final fileName in fileNames) 'assets/textures/$folder/$fileName',
      for (final fileName in fileNames)
        'assets/textures/$alternateFolder/$fileName',
    ];
  }

  static List<String> typeCandidates(String type) {
    final english = _assetName(type);
    final italian = localizedTypeLabel(type);
    final italianAsset = _assetName(italian);
    final values = <String>{
      english,
      english.toLowerCase(),
      english.toUpperCase(),
      italianAsset,
      italianAsset.toLowerCase(),
      italianAsset.toUpperCase(),
    };

    return [
      for (final value in values) 'assets/textures/type_names/$value.png',
    ];
  }

  static String localizedTypeLabel(String type) {
    switch (type.trim().toLowerCase()) {
      case 'bug':
        return 'Coleottero';
      case 'dark':
        return 'Buio';
      case 'dragon':
        return 'Drago';
      case 'electric':
        return 'Elettro';
      case 'fairy':
        return 'Folletto';
      case 'fighting':
        return 'Lotta';
      case 'fire':
        return 'Fuoco';
      case 'flying':
        return 'Volante';
      case 'ghost':
        return 'Spettro';
      case 'grass':
        return 'Erba';
      case 'ground':
        return 'Terra';
      case 'ice':
        return 'Ghiaccio';
      case 'normal':
        return 'Normale';
      case 'poison':
        return 'Veleno';
      case 'psychic':
        return 'Psico';
      case 'rock':
        return 'Roccia';
      case 'steel':
        return 'Acciaio';
      case 'water':
        return 'Acqua';
      default:
        return type;
    }
  }

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

  static String _compactAssetName(String value) {
    return value
        .trim()
        .replaceAll(':', '')
        .replaceAll('.', '')
        .replaceAll("'", '')
        .replaceAll('’', '')
        .replaceAll(' ', '')
        .replaceAll('-', '');
  }
}

class _AssetFallbackImage extends StatefulWidget {
  const _AssetFallbackImage({
    required this.assetPaths,
    required this.fallback,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  final List<String> assetPaths;
  final Widget fallback;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  State<_AssetFallbackImage> createState() => _AssetFallbackImageState();
}

class _AssetFallbackImageState extends State<_AssetFallbackImage> {
  int _index = 0;

  @override
  void didUpdateWidget(covariant _AssetFallbackImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPaths.join('|') != widget.assetPaths.join('|')) {
      _index = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_index >= widget.assetPaths.length) {
      return widget.fallback;
    }

    return Image.asset(
      widget.assetPaths[_index],
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _index += 1;
          });
        });
        return widget.fallback;
      },
    );
  }
}
