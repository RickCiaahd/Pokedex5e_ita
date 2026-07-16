from pathlib import Path


def replace_once(path: Path, old: str, new: str, label: str) -> None:
    source = path.read_text(encoding='utf-8')
    count = source.count(old)
    if count != 1:
        raise SystemExit(f'{label}: expected one match, found {count}')
    path.write_text(source.replace(old, new, 1), encoding='utf-8')


backup = Path('lib/models/profile_backup.dart')
replace_once(
    backup,
    "    ids.addAll(pokedex.map((entry) => entry.pokemonId).where((id) => id > 0));\n",
    "    ids.addAll(\n"
    "      pokedex\n"
    "          .where(\n"
    "            (entry) => entry.seen || entry.caught || entry.forms.isNotEmpty,\n"
    "          )\n"
    "          .map((entry) => entry.pokemonId)\n"
    "          .where((id) => id > 0),\n"
    "    );\n",
    'meaningful pokedex references in backup',
)

references = Path('lib/services/custom_pokemon_reference_service.dart')
replace_once(
    references,
    "    if (backup.pokedex.any((entry) => entry.pokemonId == pokemonId)) {\n",
    "    if (backup.pokedex.any(\n"
    "      (entry) =>\n"
    "          entry.pokemonId == pokemonId &&\n"
    "          (entry.seen || entry.caught || entry.forms.isNotEmpty),\n"
    "    )) {\n",
    'meaningful pokedex deletion reference',
)

test = Path('test/fakemon_backup_safe_delete_test.dart')
replace_once(
    test,
    "import 'package:pokedex_5e_ita/models/profile_backup.dart';\n",
    "import 'package:pokedex_5e_ita/models/pokedex_entry.dart';\n"
    "import 'package:pokedex_5e_ita/models/profile_backup.dart';\n",
    'pokedex entry test import',
)
replace_once(
    test,
    "import 'package:pokedex_5e_ita/repositories/profile_repository.dart';\n",
    "import 'package:pokedex_5e_ita/repositories/pokedex_repositry.dart';\n"
    "import 'package:pokedex_5e_ita/repositories/profile_repository.dart';\n",
    'pokedex repository test import',
)
replace_once(
    test,
    "  test('il catalogo globale ha checksum e rileva le modifiche', () async {\n",
    "  test('una voce Pokédex vuota non blocca l’eliminazione', () async {\n"
    "    final definition = _definition(\n"
    "      stableId: 'fakemon-pokedex-vuoto',\n"
    "      pokemonId: CustomPokemonDefinition.firstCustomPokemonId,\n"
    "      name: 'Vuoto',\n"
    "    );\n"
    "    await customPokemonRepository.save(definition);\n"
    "    final profile = await profileRepository.createProfile('Archivio');\n"
    "    await PokedexRepository().saveEntry(\n"
    "      profileId: profile.id,\n"
    "      entry: PokedexEntry.empty(definition.pokemonId),\n"
    "    );\n\n"
    "    final backup = await backupService.createBackup(profile.id);\n"
    "    final report = await CustomPokemonReferenceService().findReferences(\n"
    "      definition.pokemonId,\n"
    "    );\n\n"
    "    expect(backup.customPokemon, isEmpty);\n"
    "    expect(report.isInUse, isFalse);\n"
    "  });\n\n"
    "  test('il catalogo globale ha checksum e rileva le modifiche', () async {\n",
    'empty pokedex regression test',
)
