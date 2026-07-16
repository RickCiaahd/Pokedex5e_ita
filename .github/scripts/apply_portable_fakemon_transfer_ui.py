from pathlib import Path


def replace_exact(path: Path, old: str, new: str, expected: int, label: str) -> None:
    source = path.read_text(encoding='utf-8')
    count = source.count(old)
    if count != expected:
        raise SystemExit(f'{label}: expected {expected} matches, found {count}')
    path.write_text(source.replace(old, new), encoding='utf-8')


def replace_once(path: Path, old: str, new: str, label: str) -> None:
    replace_exact(path, old, new, 1, label)


team = Path('lib/screens/team/team_selection_screen.dart')
replace_exact(
    team,
    '      final json = _transferService.encode(bundle);\n',
    '      final json = await _transferService.encodePortable(bundle);\n',
    4,
    'team portable encodes',
)
replace_once(
    team,
    "  int get _unlockedPokeslots {\n",
    "  Pokemon? _pokemonFromTransfer(\n"
    "    PokemonTransferBundle bundle,\n"
    "    int? pokemonId,\n"
    "  ) {\n"
    "    final catalogPokemon = _pokemonById(pokemonId);\n"
    "    if (catalogPokemon != null || pokemonId == null) {\n"
    "      return catalogPokemon;\n"
    "    }\n"
    "    for (final definition in bundle.customPokemon) {\n"
    "      if (definition.pokemonId == pokemonId) {\n"
    "        return definition.toPokemon();\n"
    "      }\n"
    "    }\n"
    "    return null;\n"
    "  }\n\n"
    "  int get _unlockedPokeslots {\n",
    'team transfer preview helper',
)
replace_once(
    team,
    '      final importedPokemon = _pokemonById(importedSlot.pokemonId);\n',
    '      final importedPokemon = _pokemonFromTransfer(\n'
    '        bundle,\n'
    '        importedSlot.pokemonId,\n'
    '      );\n',
    'single transfer preview',
)
replace_once(
    team,
    "          if (_pokemonById(slot.pokemonId) == null) slot.pokemonId!,\n",
    "          if (_pokemonFromTransfer(bundle, slot.pokemonId) == null)\n"
    "            slot.pokemonId!,\n",
    'team transfer preview validation',
)
replace_once(
    team,
    "       await _loadTeam();\n       _setStatus(\n         result.replacedPokemon > 0\n",
    "       await _loadTeam();\n"
    "       final customSpeciesDetail = result.customPokemonInstalled > 0\n"
    "           ? ' ${result.customPokemonInstalled} specie Fakemon installata.'\n"
    "           : result.customPokemonUpdated > 0\n"
    "           ? ' ${result.customPokemonUpdated} specie Fakemon aggiornata.'\n"
    "           : '';\n"
    "       _setStatus(\n"
    "         (result.replacedPokemon > 0\n",
    'single import status prefix',
)
replace_once(
    team,
    "             : '$importedName importato nello slot ${target.slotIndex + 1}.',\n       );\n",
    "             : '$importedName importato nello slot ${target.slotIndex + 1}.') +\n"
    "             customSpeciesDetail,\n"
    "       );\n",
    'single import status suffix',
)
replace_once(
    team,
    "       final pcDetail = result.movedToPc == 0\n           ? ''\n           : ' ${result.movedToPc} Pokémon sono stati salvati nel PC.';\n       _setStatus(\n         'Squadra importata: ${result.importedToTeam} Pokémon nei Pokéslot.$pcDetail',\n       );\n",
    "       final pcDetail = result.movedToPc == 0\n"
    "           ? ''\n"
    "           : ' ${result.movedToPc} Pokémon sono stati salvati nel PC.';\n"
    "       final customSpeciesDetail = result.customPokemonInstalled == 0 &&\n"
    "               result.customPokemonUpdated == 0\n"
    "           ? ''\n"
    "           : ' Fakemon: ${result.customPokemonInstalled} installati, '\n"
    "                 '${result.customPokemonUpdated} aggiornati.';\n"
    "       _setStatus(\n"
    "         'Squadra importata: ${result.importedToTeam} Pokémon nei Pokéslot.'\n"
    "         '$pcDetail$customSpeciesDetail',\n"
    "       );\n",
    'team import status',
)

encounters = Path('lib/screens/tools/encounter_library_screen.dart')
replace_exact(
    encounters,
    '      final json = _transferService.encode(bundle);\n',
    '      final json = await _transferService.encodePortable(bundle);\n',
    2,
    'encounter portable encodes',
)

trainers = Path('lib/screens/tools/npc_trainer_library_screen.dart')
replace_exact(
    trainers,
    '      final json = _transferService.encode(bundle);\n',
    '      final json = await _transferService.encodePortable(bundle);\n',
    2,
    'trainer portable encodes',
)

changelog = Path('CHANGELOG.md')
replace_once(
    changelog,
    '### Modificato\n\n',
    '### Modificato\n\n'
    '- i trasferimenti di singoli Pokémon, squadre, incontri e Allenatori PNG includono automaticamente le definizioni complete dei Fakemon usati e le installano o rimappano durante l’importazione;\n',
    'changelog portable transfer entry',
)
