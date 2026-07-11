from pathlib import Path

path = Path('lib/screens/pokedex/pokedex_screen.dart')
text = path.read_text(encoding='utf-8')


def replace_once(old: str, new: str) -> None:
    global text
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'Expected exactly one match, found {count}: {old[:120]!r}')
    text = text.replace(old, new, 1)


replace_once(
    "import '../../repositories/pokemon_repository.dart';\n",
    "import '../../repositories/pokedex_repositry.dart';\n"
    "import '../../repositories/pokemon_pc_repository.dart';\n"
    "import '../../repositories/pokemon_repository.dart';\n"
    "import '../../repositories/team_repository.dart';\n",
)

replace_once(
    "  final PokemonRepository _repository = PokemonRepository();\n"
    "  final ProfileStorageService _profileStorageService = ProfileStorageService();\n",
    "  final PokemonRepository _repository = PokemonRepository();\n"
    "  final PokedexRepository _pokedexRepository = PokedexRepository();\n"
    "  final PokemonPcRepository _pokemonPcRepository = PokemonPcRepository();\n"
    "  final TeamRepository _teamRepository = TeamRepository();\n"
    "  final ProfileStorageService _profileStorageService = ProfileStorageService();\n",
)

replace_once(
    "      final pokemon = await _repository.getAllPokemon();\n"
    "      final flavors = await _repository.getPokemonFlavors();\n"
    "      await _loadEntries();\n",
    "      final pokemon = await _repository.getAllPokemon();\n"
    "      final flavors = await _repository.getPokemonFlavors();\n"
    "      await _syncOwnedPokemon();\n"
    "      await _loadEntries();\n",
)

replace_once(
    "  void _applyFilters() {\n",
    "  Future<void> _syncOwnedPokemon() async {\n"
    "    final profile = await _profileStorageService.getDefaultProfile();\n"
    "    final team = await _teamRepository.getTeam(profile.id);\n"
    "    final pcPokemon = await _pokemonPcRepository.getPokemon(profile.id);\n"
    "\n"
    "    await _pokedexRepository.registerCaughtMany(\n"
    "      profileId: profile.id,\n"
    "      pokemon: [\n"
    "        for (final slot in team)\n"
    "          if (slot.pokemonId != null)\n"
    "            PokedexOwnedForm(\n"
    "              pokemonId: slot.pokemonId!,\n"
    "              formName: slot.formName,\n"
    "            ),\n"
    "        for (final item in pcPokemon)\n"
    "          PokedexOwnedForm(\n"
    "            pokemonId: item.pokemonId,\n"
    "            formName: item.formName,\n"
    "          ),\n"
    "      ],\n"
    "    );\n"
    "  }\n"
    "\n"
    "  void _applyFilters() {\n",
)

replace_once(
    "    _filteredPokemon = _allPokemon.where((pokemon) {\n"
    "      final matchesSearch = query.isEmpty ||\n"
    "          pokemon.name.toLowerCase().contains(query) ||\n"
    "          pokemon.id.toString().contains(query) ||\n"
    "          pokemon.types.any((type) => type.toLowerCase().contains(query));\n"
    "\n"
    "      final entry = _entryFor(pokemon);\n",
    "    _filteredPokemon = _allPokemon.where((pokemon) {\n"
    "      final entry = _entryFor(pokemon);\n"
    "      final previewPokemon = pokemon.resolveVariant(\n"
    "        formName: entry.preferredFormName,\n"
    "      );\n"
    "      final matchesSearch = query.isEmpty ||\n"
    "          pokemon.name.toLowerCase().contains(query) ||\n"
    "          pokemon.id.toString().contains(query) ||\n"
    "          previewPokemon.types.any(\n"
    "            (type) => type.toLowerCase().contains(query),\n"
    "          );\n"
    "\n",
)

replace_once(
    "      final localizedTypes = pokemon.types\n"
    "          .map(PokemonAssetPaths.localizedTypeLabel)\n"
    "          .toSet();\n",
    "      final localizedTypes = previewPokemon.types\n"
    "          .map(PokemonAssetPaths.localizedTypeLabel)\n"
    "          .toSet();\n",
)

replace_once(
    "  void _openPokemonDialog(Pokemon pokemon) {\n"
    "    showDialog(\n"
    "      context: context,\n"
    "      builder: (_) => PokemonSummaryDialog(\n"
    "        pokemon: pokemon,\n"
    "        flavor: _pokemonFlavors[pokemon.id],\n"
    "        entry: _entryFor(pokemon),\n"
    "        onToggleSeen: () => _toggleSeen(pokemon),\n"
    "        onToggleCaught: () => _toggleCaught(pokemon),\n"
    "      ),\n"
    "    );\n"
    "  }\n",
    "  Future<void> _openPokemonDialog(Pokemon pokemon) async {\n"
    "    await showDialog<void>(\n"
    "      context: context,\n"
    "      builder: (_) => PokemonSummaryDialog(\n"
    "        pokemon: pokemon,\n"
    "        flavor: _pokemonFlavors[pokemon.id],\n"
    "        entry: _entryFor(pokemon),\n"
    "        onEntryChanged: (entry) async {\n"
    "          if (!mounted) return;\n"
    "          setState(() {\n"
    "            _entries[pokemon.id] = entry;\n"
    "            _applyFilters();\n"
    "          });\n"
    "          await _saveEntries();\n"
    "        },\n"
    "      ),\n"
    "    );\n"
    "  }\n",
)

old_toggle_block = """  Future<void> _toggleSeen(Pokemon pokemon) async {
    final entry = _entryFor(pokemon);

    setState(() {
      _entries[pokemon.id] = entry.copyWith(
        seen: !entry.seen,
        caught: entry.seen ? false : entry.caught,
      );
    });

    await _saveEntries();

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _toggleCaught(Pokemon pokemon) async {
    final entry = _entryFor(pokemon);

    setState(() {
      _entries[pokemon.id] = entry.copyWith(seen: true, caught: !entry.caught);
    });

    await _saveEntries();

    if (!mounted) return;
    Navigator.of(context).pop();
  }

"""
replace_once(old_toggle_block, "")

replace_once(
    "        case MarkMode.seen:\n"
    "          _entries[pokemon.id] = entry.copyWith(seen: true);\n"
    "          break;\n"
    "        case MarkMode.unseen:\n"
    "          _entries[pokemon.id] = entry.copyWith(seen: false, caught: false);\n"
    "          break;\n"
    "        case MarkMode.caught:\n"
    "          _entries[pokemon.id] = entry.copyWith(seen: true, caught: true);\n"
    "          break;\n",
    "        case MarkMode.seen:\n"
    "          final base = entry.formFor(null, speciesName: pokemon.name);\n"
    "          _entries[pokemon.id] = entry.setFormState(\n"
    "            formName: null,\n"
    "            speciesName: pokemon.name,\n"
    "            seen: true,\n"
    "            caught: base.caught,\n"
    "          );\n"
    "          break;\n"
    "        case MarkMode.unseen:\n"
    "          _entries[pokemon.id] = entry.clearAllForms();\n"
    "          break;\n"
    "        case MarkMode.caught:\n"
    "          _entries[pokemon.id] = entry.setFormState(\n"
    "            formName: null,\n"
    "            speciesName: pokemon.name,\n"
    "            seen: true,\n"
    "            caught: true,\n"
    "          );\n"
    "          break;\n",
)

replace_once(
    "                        entryFor: _entryFor,\n"
    "                        onPokemonTap: _handlePokemonTap,\n",
    "                        entryFor: _entryFor,\n"
    "                        previewFormFor: (pokemon) =>\n"
    "                            _entryFor(pokemon).preferredFormName,\n"
    "                        onPokemonTap: _handlePokemonTap,\n",
)

replace_once(
    "    required this.entryFor,\n"
    "    required this.onPokemonTap,\n",
    "    required this.entryFor,\n"
    "    required this.previewFormFor,\n"
    "    required this.onPokemonTap,\n",
)

replace_once(
    "  final PokedexEntry Function(Pokemon pokemon) entryFor;\n"
    "  final ValueChanged<Pokemon> onPokemonTap;\n",
    "  final PokedexEntry Function(Pokemon pokemon) entryFor;\n"
    "  final String? Function(Pokemon pokemon) previewFormFor;\n"
    "  final ValueChanged<Pokemon> onPokemonTap;\n",
)

replace_once(
    "                entry: entryFor(currentPokemon),\n"
    "                onTap: () => onPokemonTap(currentPokemon),\n",
    "                entry: entryFor(currentPokemon),\n"
    "                previewFormName: previewFormFor(currentPokemon),\n"
    "                onTap: () => onPokemonTap(currentPokemon),\n",
)

path.write_text(text, encoding='utf-8')
