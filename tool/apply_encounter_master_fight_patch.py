from pathlib import Path


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"Expected one match in {path} but found {count}: {old[:80]!r}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")


result_path = Path("lib/screens/tools/encounter_result_screen.dart")
replace_once(
    result_path,
    "import '../../widgets/navigation/home_leading_button.dart';\n"
    "import '../../widgets/pokemon/pokemon_asset_image.dart';",
    "import '../../widgets/battle/wild_master_fight_launcher.dart';\n"
    "import '../../widgets/navigation/home_leading_button.dart';\n"
    "import '../../widgets/pokemon/pokemon_asset_image.dart';",
)
replace_once(
    result_path,
    "  Future<void> _openDetails(GeneratedPokemon generated) async {",
    "  Future<void> _startMasterFight() async {\n"
    "    final profileId = widget.profileId;\n"
    "    if (profileId == null ||\n"
    "        _encounter.members.isEmpty ||\n"
    "        _isWorking ||\n"
    "        _isSaving) {\n"
    "      return;\n"
    "    }\n\n"
    "    setState(() {\n"
    "      _isWorking = true;\n"
    "      _message = null;\n"
    "    });\n"
    "    try {\n"
    "      final launched = await launchWildMasterFight(\n"
    "        context: context,\n"
    "        profileId: profileId,\n"
    "        encounter: _encounter,\n"
    "        catalog: widget.catalog,\n"
    "      );\n"
    "      if (!mounted || !launched) return;\n"
    "      setState(() {\n"
    "        _message =\n"
    "            'Il fight selvatico è stato salvato e può essere ripreso dagli Strumenti del Master.';\n"
    "      });\n"
    "    } catch (error) {\n"
    "      if (!mounted) return;\n"
    "      setState(() {\n"
    "        _message = error\n"
    "            .toString()\n"
    "            .replaceFirst('FormatException: ', '')\n"
    "            .replaceFirst('Bad state: ', '');\n"
    "      });\n"
    "    } finally {\n"
    "      if (mounted) setState(() => _isWorking = false);\n"
    "    }\n"
    "  }\n\n"
    "  Future<void> _openDetails(GeneratedPokemon generated) async {",
)
replace_once(
    result_path,
    "          if (widget.profileId != null) ...[\n"
    "            OutlinedButton.icon(",
    "          if (widget.profileId != null) ...[\n"
    "            FilledButton.icon(\n"
    "              onPressed: _encounter.members.isEmpty || _isWorking || _isSaving\n"
    "                  ? null\n"
    "                  : _startMasterFight,\n"
    "              icon: const Icon(Icons.sports_mma_outlined),\n"
    "              label: const Text('AVVIA NEL FIGHT DEL MASTER'),\n"
    "            ),\n"
    "            const SizedBox(height: 8),\n"
    "            OutlinedButton.icon(",
)

library_path = Path("lib/screens/tools/encounter_library_screen.dart")
replace_once(
    library_path,
    "import '../../widgets/navigation/home_leading_button.dart';",
    "import '../../widgets/battle/wild_master_fight_launcher.dart';\n"
    "import '../../widgets/navigation/home_leading_button.dart';",
)
replace_once(
    library_path,
    "  Future<void> _duplicateEncounter(SavedEncounter saved) async {",
    "  Future<void> _startFight(SavedEncounter saved) async {\n"
    "    final profile = _profile;\n"
    "    if (profile == null || _isBusy) return;\n"
    "    setState(() => _isBusy = true);\n"
    "    try {\n"
    "      final encounter = _mapper.toGenerated(saved: saved, catalog: _catalog);\n"
    "      final launched = await launchWildMasterFight(\n"
    "        context: context,\n"
    "        profileId: profile.id,\n"
    "        encounter: encounter,\n"
    "        catalog: _catalog,\n"
    "      );\n"
    "      if (!mounted || !launched) return;\n"
    "      _setMessage(\n"
    "        'Il fight di ${saved.name} è stato salvato e può essere ripreso dagli Strumenti del Master.',\n"
    "      );\n"
    "    } catch (error) {\n"
    "      _setMessage(_friendlyError(error), isError: true);\n"
    "    } finally {\n"
    "      if (mounted) setState(() => _isBusy = false);\n"
    "    }\n"
    "  }\n\n"
    "  Future<void> _duplicateEncounter(SavedEncounter saved) async {",
)
replace_once(
    library_path,
    "                  onOpen: () => _openEncounter(saved),\n"
    "                  onDuplicate: () => _duplicateEncounter(saved),",
    "                  onOpen: () => _openEncounter(saved),\n"
    "                  onFight: () => _startFight(saved),\n"
    "                  onDuplicate: () => _duplicateEncounter(saved),",
)
replace_once(
    library_path,
    "    required this.onOpen,\n"
    "    required this.onDuplicate,",
    "    required this.onOpen,\n"
    "    required this.onFight,\n"
    "    required this.onDuplicate,",
)
replace_once(
    library_path,
    "  final VoidCallback onOpen;\n"
    "  final VoidCallback onDuplicate;",
    "  final VoidCallback onOpen;\n"
    "  final VoidCallback onFight;\n"
    "  final VoidCallback onDuplicate;",
)
replace_once(
    library_path,
    "              Row(\n"
    "                children: [\n"
    "                  Text(\n"
    "                    'Aggiornato ${_formatDate(saved.updatedAt)}',\n"
    "                    style: Theme.of(context).textTheme.bodySmall,\n"
    "                  ),\n"
    "                  const Spacer(),\n"
    "                  FilledButton.tonalIcon(\n"
    "                    onPressed: isBusy ? null : onOpen,\n"
    "                    icon: const Icon(Icons.open_in_new),\n"
    "                    label: const Text('APRI'),\n"
    "                  ),\n"
    "                ],\n"
    "              ),",
    "              Row(\n"
    "                children: [\n"
    "                  Expanded(\n"
    "                    child: Text(\n"
    "                      'Aggiornato ${_formatDate(saved.updatedAt)}',\n"
    "                      style: Theme.of(context).textTheme.bodySmall,\n"
    "                    ),\n"
    "                  ),\n"
    "                ],\n"
    "              ),\n"
    "              const SizedBox(height: 8),\n"
    "              Wrap(\n"
    "                alignment: WrapAlignment.end,\n"
    "                spacing: 8,\n"
    "                runSpacing: 8,\n"
    "                children: [\n"
    "                  OutlinedButton.icon(\n"
    "                    onPressed: isBusy ? null : onFight,\n"
    "                    icon: const Icon(Icons.sports_mma_outlined),\n"
    "                    label: const Text('FIGHT DEL MASTER'),\n"
    "                  ),\n"
    "                  FilledButton.tonalIcon(\n"
    "                    onPressed: isBusy ? null : onOpen,\n"
    "                    icon: const Icon(Icons.open_in_new),\n"
    "                    label: const Text('APRI'),\n"
    "                  ),\n"
    "                ],\n"
    "              ),",
)

changelog_path = Path("CHANGELOG.md")
replace_once(
    changelog_path,
    "- documentazione iniziale del progetto, delle piattaforme supportate e dei controlli locali.\n",
    "- documentazione iniziale del progetto, delle piattaforme supportate e dei controlli locali;\n"
    "- avvio diretto degli incontri generati o salvati nel Fight del Master, senza creare Allenatori PNG nella libreria.\n",
)
replace_once(
    changelog_path,
    "- collegamento diretto tra Generatore incontri e Fight del Master;\n",
    "",
)

Path("tool/apply_encounter_master_fight_patch.py").unlink()
Path(".github/workflows/apply-encounter-master-fight.yml").unlink()
