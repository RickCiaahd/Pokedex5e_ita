export 'pokemon_asset_image_legacy.dart' hide PokemonAssetImage;

import 'package:flutter/material.dart';

import '../../models/pokedex_entry.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_evolution_alias_registry.dart';
import '../../services/custom_pokemon_runtime_registry.dart';
import 'pokemon_asset_image_legacy.dart' as legacy;

/// Resolves temporary evolution aliases and user-provided Fakemon images before
/// delegating to the complete bundled-asset resolver.
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

    return legacy.PokemonAssetImage(
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
  }
}
