from pathlib import Path


def replace_once(path: Path, old: str, new: str, label: str) -> None:
    text = path.read_text(encoding='utf-8')
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{label}: expected one match, found {count}')
    path.write_text(text.replace(old, new, 1), encoding='utf-8')


pokedex = Path('lib/screens/pokedex/pokedex_screen.dart')
replace_once(
    pokedex,
    "import '../../models/pokedex_entry.dart';\n",
    "import '../../models/custom_pokemon_definition.dart';\n"
    "import '../../models/pokedex_entry.dart';\n",
    'pokedex model import',
)
replace_once(
    pokedex,
    "import '../../widgets/pokemon/pokemon_asset_image.dart';\n",
    "import '../../widgets/pokemon/pokemon_asset_image.dart';\n"
    "import '../pokemon/custom_pokemon_library_screen.dart';\n",
    'pokedex screen import',
)
replace_once(
    pokedex,
    "    'Altri': [1026, 9999],\n",
    "    'Altri': [1026, 9999],\n"
    "    'Fakemon': [CustomPokemonDefinition.firstCustomPokemonId, 2147483647],\n",
    'fakemon region',
)
replace_once(
    pokedex,
    "  Future<void> _loadEntries() async {\n",
    "  Future<void> _openCustomPokemonLibrary() async {\n"
    "    await Navigator.of(context).push<void>(\n"
    "      MaterialPageRoute(\n"
    "        builder: (_) => const CustomPokemonLibraryScreen(),\n"
    "      ),\n"
    "    );\n"
    "    if (!mounted) return;\n"
    "    PokemonRepository.clearCache();\n"
    "    setState(() {\n"
    "      _isLoading = true;\n"
    "      _errorMessage = null;\n"
    "    });\n"
    "    await _loadPokemon();\n"
    "  }\n\n"
    "  Future<void> _loadEntries() async {\n",
    'pokedex manager method',
)
replace_once(
    pokedex,
    "      appBar: AppBar(title: const Text('Pokédex')),\n",
    "      appBar: AppBar(\n"
    "        title: const Text('Pokédex'),\n"
    "        actions: [\n"
    "          IconButton(\n"
    "            tooltip: 'I miei Fakemon',\n"
    "            onPressed: _openCustomPokemonLibrary,\n"
    "            icon: const Icon(Icons.auto_awesome),\n"
    "          ),\n"
    "        ],\n"
    "      ),\n",
    'pokedex app bar',
)

editor = Path('lib/screens/pokemon/pokemon_edit_screen.dart')
replace_once(
    editor,
    "    final abilityDescriptionsFuture = _abilityRepository\n        .getAbilityDescriptions();\n",
    "    final abilityDescriptionsFuture = _abilityRepository\n"
    "        .getAbilityDescriptions(pokemonId: widget.pokemon.id);\n",
    'editor ability context',
)
replace_once(
    editor,
    "    final contextualMoveData = await _moveRepository.getMoves(\n      _learnsetMoveChoices(tmMoveNames),\n    );\n",
    "    final contextualMoveData = await _moveRepository.getMoves(\n"
    "      _learnsetMoveChoices(tmMoveNames),\n"
    "      pokemonId: widget.pokemon.id,\n"
    "    );\n",
    'editor initial move context',
)
replace_once(
    editor,
    "    final contextualMoveData = await _moveRepository.getMoves(\n      _learnsetMoveChoices(tmMoveNames),\n    );\n",
    "    final contextualMoveData = await _moveRepository.getMoves(\n"
    "      _learnsetMoveChoices(tmMoveNames),\n"
    "      pokemonId: widget.pokemon.id,\n"
    "    );\n",
    'editor reload move context',
)

pokemon_detail = Path('lib/screens/pokemon/pokemon_detail_screen_legacy.dart')
replace_once(
    pokemon_detail,
    "      _moveRepository.getMoves(moveNames),\n      _abilityRepository.getAbilityDescriptions(),\n",
    "      _moveRepository.getMoves(moveNames, pokemonId: _pokemon.id),\n"
    "      _abilityRepository.getAbilityDescriptions(pokemonId: _pokemon.id),\n",
    'detail local definitions',
)

battle = Path('lib/screens/battle/battle_screen.dart')
replace_once(
    battle,
    "import '../../services/battle_status_rules.dart';\n",
    "import '../../services/battle_status_rules.dart';\n"
    "import '../../services/custom_pokemon_runtime_registry.dart';\n",
    'battle registry import',
)
replace_once(
    battle,
    "    final moves = await _moveRepository.getMoves(moveReferences);\n\n",
    "    final moves = await _moveRepository.getMoves(moveReferences);\n"
    "    for (final slot in team) {\n"
    "      final pokemonId = slot.pokemonId;\n"
    "      if (pokemonId == null) continue;\n"
    "      final pokemon = pokemonById[pokemonId];\n"
    "      if (pokemon == null) continue;\n"
    "      for (final reference in _movesForSlot(slot, pokemon)) {\n"
    "        final localMove = CustomPokemonRuntimeRegistry.moveFor(\n"
    "          pokemonId,\n"
    "          reference,\n"
    "        );\n"
    "        if (localMove != null) moves[reference] = localMove;\n"
    "      }\n"
    "    }\n\n",
    'battle local moves',
)

library = Path('lib/screens/pokemon/custom_pokemon_library_screen.dart')
text = library.read_text(encoding='utf-8')
text = text.replace(
    "                            case 'export': onExport();\n"
    "                            case 'duplicate': onDuplicate();\n"
    "                            case 'delete': onDelete();\n",
    "                            case 'export':\n"
    "                              onExport();\n"
    "                              break;\n"
    "                            case 'duplicate':\n"
    "                              onDuplicate();\n"
    "                              break;\n"
    "                            case 'delete':\n"
    "                              onDelete();\n"
    "                              break;\n",
)
library.write_text(text, encoding='utf-8')

changelog = Path('CHANGELOG.md')
replace_once(
    changelog,
    "### Aggiunto\n\n",
    "### Aggiunto\n\n"
    "- catalogo globale dei Fakemon con scheda 5e, immagine caricata, mosse e abilità esclusive della specie, importazione, esportazione e condivisione portabile;\n",
    'changelog fakemon entry',
)
