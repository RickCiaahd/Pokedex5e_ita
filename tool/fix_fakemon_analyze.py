from pathlib import Path

# Correzioni mirate emerse dalla prima analisi statica del formato v2.

def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    source = file.read_text(encoding='utf-8')
    count = source.count(old)
    if count != 1:
        raise SystemExit(f'{path}: expected one match, found {count}')
    file.write_text(source.replace(old, new, 1), encoding='utf-8')


replace_once(
    'lib/repositories/evolution_repository.dart',
    """    for (final entry in base.entries) {
      grouped.putIfAbsent(_referenceKey(entry.key), () => <EvolutionOption>[])
        ..addAll(entry.value.options);
    }
""",
    """    for (final entry in base.entries) {
      final options = grouped.putIfAbsent(
        _referenceKey(entry.key),
        () => <EvolutionOption>[],
      );
      options.addAll(entry.value.options);
    }
""",
)
replace_once(
    'lib/repositories/evolution_repository.dart',
    """    if (sourceKey.isEmpty || targetKey.isEmpty || sourceKey == targetKey)
      return;
""",
    """    if (sourceKey.isEmpty || targetKey.isEmpty || sourceKey == targetKey) {
      return;
    }
""",
)

replace_once(
    'lib/screens/pokemon/custom_pokemon_advanced_editor_screen.dart',
    'final pokemon = await showSearch<Pokemon>(\n',
    'final pokemon = await showSearch<Pokemon?>(\n',
)
replace_once(
    'lib/screens/pokemon/custom_pokemon_advanced_editor_screen.dart',
    'class _PokemonSearchDelegate extends SearchDelegate<Pokemon> {\n',
    'class _PokemonSearchDelegate extends SearchDelegate<Pokemon?> {\n',
)
replace_once(
    'lib/screens/pokemon/custom_pokemon_advanced_editor_screen.dart',
    """    final types = <String>[
      if (_primaryType != null) _primaryType!,
      if (_secondaryType != null && _secondaryType != _primaryType)
        _secondaryType!,
    ];
""",
    """    final types = <String>[];
    final primaryType = _primaryType;
    if (primaryType != null) {
      types.add(primaryType);
    }
    final secondaryType = _secondaryType;
    if (secondaryType != null && secondaryType != primaryType) {
      types.add(secondaryType);
    }
""",
)
