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
    '- i trasferimenti di singoli Pokemon, squadre, incontri e Allenatori PNG includono automaticamente le definizioni complete dei Fakemon usati e le installano o rimappano durante l importazione;\n',
    'changelog portable transfer entry',
)
