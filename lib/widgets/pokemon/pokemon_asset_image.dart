export 'pokemon_asset_image_legacy.dart' hide PokemonAssetImage;

import 'package:flutter/material.dart';

import '../../models/pokedex_entry.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_evolution_alias_registry.dart';
import 'pokemon_asset_image_legacy.dart' as legacy;

/// Resolves temporary evolution aliases before delegating to the complete
/// asset resolver.
///
/// The compatibility layer is invisible to normal Pokémon: only negative ids
/// created for an evolution preview are translated to their canonical species
/// id and form.
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
