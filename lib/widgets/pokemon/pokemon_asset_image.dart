export 'pokemon_asset_image_legacy.dart' hide PokemonAssetImage;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/pokedex_entry.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_evolution_alias_registry.dart';
import '../../services/custom_pokemon_runtime_registry.dart';
import 'pokemon_asset_image_legacy.dart' as legacy;
import 'pokemon_gender_asset_paths.dart';

/// Resolves temporary evolution aliases, user-provided Fakemon images and
/// sex-specific bundled textures before delegating to the complete legacy
/// asset resolver.
class PokemonAssetImage extends StatelessWidget {
  const PokemonAssetImage({
    super.key,
    required this.pokemon,
    this.size = 72,
    this.fit = BoxFit.contain,
    this.useLargeArtwork = false,
    this.entry,
    this.formName,
    this.gender,
    this.isShiny,
    this.fallback,
  });

  final Pokemon pokemon;
  final double size;
  final BoxFit fit;
  final bool useLargeArtwork;
  final PokedexEntry? entry;
  final String? formName;
  final String? gender;
  final bool? isShiny;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final alias = PokemonEvolutionAliasRegistry.aliasFor(pokemon.id);
    final effectivePokemon = alias?.basePokemon ?? pokemon;
    final effectiveFormName = formName ?? alias?.formName;
    final customBytes = CustomPokemonRuntimeRegistry.imageBytesFor(
      effectivePokemon.id,
    );

    if (customBytes != null) {
      Widget image = Image.memory(
        customBytes,
        width: size,
        height: size,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) =>
            fallback ?? Icon(Icons.catching_pokemon, size: size * 0.48),
      );
      final seen = entry?.seen ?? true;
      final caught = entry?.caught ?? true;
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

      return SizedBox(
        key: ValueKey<String>('custom-${effectivePokemon.id}-$size'),
        width: size,
        height: size,
        child: Center(child: image),
      );
    }

    final legacyImage = legacy.PokemonAssetImage(
      key: ValueKey<String>(
        '${effectivePokemon.id}|${effectiveFormName ?? 'base'}|${gender ?? 'none'}|${isShiny ?? false}|$useLargeArtwork',
      ),
      pokemon: effectivePokemon,
      size: size,
      fit: fit,
      useLargeArtwork: useLargeArtwork,
      entry: entry,
      formName: effectiveFormName,
      gender: gender,
      isShiny: isShiny,
      fallback: fallback,
    );

    final genderCandidates = PokemonGenderAssetPaths.candidates(
      pokemon: effectivePokemon,
      useLargeArtwork: useLargeArtwork,
      formName: effectiveFormName,
      gender: gender,
      isShiny: isShiny ?? false,
    );
    if (genderCandidates.isEmpty) return legacyImage;

    return _GenderAwareBundledImage(
      key: ValueKey<String>(
        'gender-${effectivePokemon.id}-${effectiveFormName ?? 'base'}-${gender ?? 'none'}-${isShiny ?? false}-$useLargeArtwork',
      ),
      candidates: genderCandidates,
      fallback: legacyImage,
      entry: entry,
      size: size,
      fit: fit,
      visualScale: useLargeArtwork ? 1.08 : 1.12,
    );
  }
}

class _GenderAwareBundledImage extends StatefulWidget {
  const _GenderAwareBundledImage({
    super.key,
    required this.candidates,
    required this.fallback,
    required this.entry,
    required this.size,
    required this.fit,
    required this.visualScale,
  });

  final List<String> candidates;
  final Widget fallback;
  final PokedexEntry? entry;
  final double size;
  final BoxFit fit;
  final double visualScale;

  @override
  State<_GenderAwareBundledImage> createState() =>
      _GenderAwareBundledImageState();
}

class _GenderAwareBundledImageState extends State<_GenderAwareBundledImage> {
  static Future<Set<String>>? _assetPathsFuture;
  late final Future<String?> _resolvedAssetPath;

  @override
  void initState() {
    super.initState();
    _resolvedAssetPath = _firstExisting(widget.candidates);
  }

  static Future<Set<String>> _assetPaths() {
    return _assetPathsFuture ??= AssetManifest.loadFromAssetBundle(rootBundle)
        .then((manifest) => manifest.listAssets().toSet());
  }

  static Future<String?> _firstExisting(List<String> candidates) async {
    final assets = await _assetPaths();
    for (final candidate in candidates) {
      if (assets.contains(candidate)) return candidate;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _resolvedAssetPath,
      builder: (context, snapshot) {
        final assetPath = snapshot.data;
        if (assetPath == null) return widget.fallback;

        Widget image = Image.asset(
          assetPath,
          width: widget.size,
          height: widget.size,
          fit: widget.fit,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, _, _) => widget.fallback,
        );

        final seen = widget.entry?.seen ?? true;
        final caught = widget.entry?.caught ?? true;
        if (!seen) {
          image = ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Colors.black,
              BlendMode.srcATop,
            ),
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

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Center(
            child: Transform.scale(scale: widget.visualScale, child: image),
          ),
        );
      },
    );
  }
}
