import '../models/evolution_data.dart';
import '../models/pokemon.dart';

/// Resolves evolution rules against the concrete catalogue identity of a
/// Pokémon form instead of relying only on its display name.
///
/// Web catalogue forms keep their source id in [Pokemon.assetSlug] (for
/// example `sneasel-hisui` or `gimmighoul-roaming`). Using that id keeps
/// evolution routing stable even when the visible form label is localized.
class EvolutionCatalogResolver {
  const EvolutionCatalogResolver();

  EvolutionData? evolutionFor({
    required Pokemon pokemon,
    required Map<String, EvolutionData> evolutions,
  }) {
    final assetSlug = pokemon.assetSlug?.trim() ?? '';
    if (assetSlug.isNotEmpty) {
      final byAsset =
          evolutions[assetSlug] ?? evolutions[_referenceKey(assetSlug)];
      if (byAsset != null) return byAsset;
    }

    return evolutions[pokemon.name] ??
        evolutions[_referenceKey(pokemon.name)];
  }

  Pokemon? targetPokemonFor({
    required EvolutionOption option,
    required List<Pokemon> catalog,
  }) {
    final targetId = option.targetPokemonId;
    if (targetId != null) {
      for (final pokemon in catalog) {
        if (pokemon.id == targetId) return pokemon;
      }
    }

    final targetKey = _referenceKey(option.toKey);
    if (targetKey.isNotEmpty) {
      for (final pokemon in catalog) {
        final assetKey = _referenceKey(pokemon.assetSlug ?? '');
        if (assetKey == targetKey) return pokemon;
      }
    }

    final displayKey = _referenceKey(option.toName);
    for (final pokemon in catalog) {
      if (_referenceKey(pokemon.name) == displayKey) return pokemon;
    }
    return null;
  }

  String _referenceKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('♀', '-f')
        .replaceAll('♂', '-m')
        .replaceAll(RegExp(r"[’']"), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}
