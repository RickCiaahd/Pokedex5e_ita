export 'pokemon_asset_image_legacy.dart' hide PokemonAssetImage;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/pokedex_entry.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_evolution_alias_registry.dart';
import '../../models/pokemon_gender_appearance.dart';
import '../../services/custom_pokemon_runtime_registry.dart';
import 'pokemon_asset_image_legacy.dart' as legacy;
import 'pokemon_gender_asset_paths.dart';
import 'pokemon_minior_asset_paths.dart';

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
    final effectiveForm = formName ?? alias?.formName;
    final customBytes = CustomPokemonRuntimeRegistry.imageBytesFor(
      effectivePokemon.id,
    );

    if (customBytes != null) {
      final custom = Image.memory(
        customBytes,
        width: size,
        height: size,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) =>
            fallback ?? Icon(Icons.catching_pokemon, size: size * 0.48),
      );
      return SizedBox(
        key: ValueKey<String>('custom-${effectivePokemon.id}-$size'),
        width: size,
        height: size,
        child: Center(child: _entryState(context, custom, entry)),
      );
    }

    final legacyImage = legacy.PokemonAssetImage(
      key: ValueKey<String>(
        '${effectivePokemon.id}|${effectiveForm ?? 'base'}|${gender ?? 'none'}|${isShiny ?? false}|$useLargeArtwork',
      ),
      pokemon: effectivePokemon,
      size: size,
      fit: fit,
      useLargeArtwork: useLargeArtwork,
      entry: entry,
      formName: effectiveForm,
      gender: gender,
      isShiny: isShiny,
      fallback: fallback,
    );

    final assetGender = gender ??
        (PokemonGenderAppearance.hasVisibleDifference(effectivePokemon)
            ? 'male'
            : null);
    final candidates = <String>[
      ...PokemonMiniorAssetPaths.candidates(
        pokemon: effectivePokemon,
        useLargeArtwork: useLargeArtwork,
        formName: effectiveForm,
        isShiny: isShiny ?? false,
      ),
      ...PokemonGenderAssetPaths.candidates(
        pokemon: effectivePokemon,
        useLargeArtwork: useLargeArtwork,
        formName: effectiveForm,
        gender: assetGender,
        isShiny: isShiny ?? false,
      ),
    ];
    if (candidates.isEmpty) return legacyImage;

    return _PreferredAssetImage(
      key: ValueKey<String>(
        'preferred-${effectivePokemon.id}-${effectiveForm ?? 'base'}-${assetGender ?? 'none'}-${isShiny ?? false}-$useLargeArtwork',
      ),
      candidates: candidates,
      fallback: legacyImage,
      entry: entry,
      size: size,
      fit: fit,
      scale: useLargeArtwork ? 1.08 : 1.12,
    );
  }
}

class _PreferredAssetImage extends StatelessWidget {
  const _PreferredAssetImage({
    super.key,
    required this.candidates,
    required this.fallback,
    required this.entry,
    required this.size,
    required this.fit,
    required this.scale,
  });

  static Future<Set<String>>? _manifestPaths;

  final List<String> candidates;
  final Widget fallback;
  final PokedexEntry? entry;
  final double size;
  final BoxFit fit;
  final double scale;

  static Future<Set<String>> _paths() {
    return _manifestPaths ??= AssetManifest.loadFromAssetBundle(rootBundle)
        .then((manifest) => manifest.listAssets().toSet());
  }

  Future<String?> _resolve() async {
    final paths = await _paths();
    for (final candidate in candidates) {
      if (paths.contains(candidate)) return candidate;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _resolve(),
      builder: (context, snapshot) {
        final path = snapshot.data;
        if (path == null) return fallback;
        final image = Image.asset(
          path,
          width: size,
          height: size,
          fit: fit,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, _, _) => fallback,
        );
        return SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Transform.scale(
              scale: scale,
              child: _entryState(context, image, entry),
            ),
          ),
        );
      },
    );
  }
}

Widget _entryState(
  BuildContext context,
  Widget image,
  PokedexEntry? entry,
) {
  final seen = entry?.seen ?? true;
  final caught = entry?.caught ?? true;
  if (!seen) {
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcATop),
      child: image,
    );
  }
  if (!caught) {
    return Opacity(
      opacity: 0.56,
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 52,
          0.2126, 0.7152, 0.0722, 0, 52,
          0.2126, 0.7152, 0.0722, 0, 52,
          0, 0, 0, 1, 0,
        ]),
        child: image,
      ),
    );
  }
  return image;
}
