from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    source = file.read_text(encoding='utf-8')
    count = source.count(old)
    if count != 1:
        raise SystemExit(f'{path}: expected one match, found {count}')
    file.write_text(source.replace(old, new, 1), encoding='utf-8')


replace_once(
    'lib/repositories/pokemon_repository.dart',
    """  Future<List<Pokemon>> _filterSealed(
    List<Pokemon> pokemon, {
    required bool includeSealed,
  }) async {
    if (includeSealed) return List<Pokemon>.from(pokemon);
    final customDefinitions = await CustomPokemonRepository().getAll();
    final visible = await CustomPokemonDiscoveryService().visibleDefinitions(
      customDefinitions,
    );
    final visibleIds = visible
        .map((definition) => definition.pokemonId)
        .toSet();
    return pokemon
        .where(
          (entry) =>
              entry.id < CustomPokemonDefinition.firstCustomPokemonId ||
              visibleIds.contains(entry.id),
        )
        .toList(growable: false);
  }
""",
    """  Future<List<Pokemon>> _filterSealed(
    List<Pokemon> pokemon, {
    required bool includeSealed,
  }) async {
    if (includeSealed) return List<Pokemon>.from(pokemon);
    final customDefinitions = await CustomPokemonRepository().getAll();
    final sealedDefinitions = customDefinitions
        .where((definition) => definition.advanced.sealedForPlayer)
        .toList(growable: false);
    if (sealedDefinitions.isEmpty) return List<Pokemon>.from(pokemon);

    final visible = await CustomPokemonDiscoveryService().visibleDefinitions(
      sealedDefinitions,
    );
    final visibleIds = visible
        .map((definition) => definition.pokemonId)
        .toSet();
    final hiddenIds = sealedDefinitions
        .map((definition) => definition.pokemonId)
        .where((pokemonId) => !visibleIds.contains(pokemonId))
        .toSet();
    return pokemon
        .where((entry) => !hiddenIds.contains(entry.id))
        .toList(growable: false);
  }
""",
)

marker = Path('docs/fakemon-test-diagnostic.md')
if marker.exists():
    marker.unlink()
