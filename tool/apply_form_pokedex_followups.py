from pathlib import Path


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding='utf-8')
    count = text.count(old)
    if count != 1:
        raise SystemExit(
            f'{path}: expected exactly one match, found {count}: {old[:120]!r}'
        )
    path.write_text(text.replace(old, new, 1), encoding='utf-8')


capture = Path('lib/screens/capture/capture_pokemon_screen.dart')
replace_once(
    capture,
    "    await _pokedexRepository.updateMarkMode(\n"
    "      profileId: profile.id,\n"
    "      pokemonId: pokemon.id,\n"
    "      seen: true,\n"
    "      caught: true,\n"
    "    );\n",
    "    await _pokedexRepository.updateMarkMode(\n"
    "      profileId: profile.id,\n"
    "      pokemonId: pokemon.id,\n"
    "      formName: result.formName,\n"
    "      speciesName: pokemon.name,\n"
    "      seen: true,\n"
    "      caught: true,\n"
    "    );\n",
)

model = Path('lib/models/pokedex_entry.dart')
replace_once(
    model,
    "    final key = formKey(formName, speciesName: speciesName);\n"
    "    return forms[key] ??\n"
    "        PokedexFormEntry.empty(\n"
    "          key: key,\n"
    "          formName: displayNameFor(formName, speciesName: speciesName),\n"
    "        );\n",
    "    final key = formKey(formName, speciesName: speciesName);\n"
    "    final direct = forms[key];\n"
    "    if (direct != null) return direct;\n"
    "\n"
    "    for (final entry in forms.values) {\n"
    "      if (formKey(entry.formName, speciesName: speciesName) == key) {\n"
    "        return entry;\n"
    "      }\n"
    "    }\n"
    "\n"
    "    return PokedexFormEntry.empty(\n"
    "      key: key,\n"
    "      formName: displayNameFor(formName, speciesName: speciesName),\n"
    "    );\n",
)

replace_once(
    model,
    "    final nextForms = Map<String, PokedexFormEntry>.of(forms);\n"
    "\n"
    "    if (!normalizedSeen && !normalizedCaught) {\n",
    "    final nextForms = Map<String, PokedexFormEntry>.of(forms);\n"
    "    nextForms.removeWhere((existingKey, entry) {\n"
    "      if (existingKey == key) return false;\n"
    "      return formKey(entry.formName, speciesName: speciesName) == key;\n"
    "    });\n"
    "\n"
    "    if (!normalizedSeen && !normalizedCaught) {\n",
)
