import 'pokemon.dart';

class PokemonEvolutionAlias {
  const PokemonEvolutionAlias({
    required this.basePokemon,
    required this.formName,
  });

  final Pokemon basePokemon;
  final String formName;
}

/// Maps temporary negative ids used only inside the evolution UI back to the
/// canonical Pokédex species and form.
///
/// These aliases are never serialized. Owned Pokémon continue to be stored as
/// a normal Pokédex id plus `formName`.
class PokemonEvolutionAliasRegistry {
  const PokemonEvolutionAliasRegistry._();

  static Map<int, PokemonEvolutionAlias> _aliases = const {};

  static void replace(Map<int, PokemonEvolutionAlias> aliases) {
    _aliases = Map<int, PokemonEvolutionAlias>.unmodifiable(aliases);
  }

  static PokemonEvolutionAlias? aliasFor(int pokemonId) {
    return _aliases[pokemonId];
  }
}
