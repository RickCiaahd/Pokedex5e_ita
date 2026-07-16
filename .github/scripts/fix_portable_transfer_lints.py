from pathlib import Path


def replace_once(path: Path, old: str, new: str, label: str) -> None:
    source = path.read_text(encoding='utf-8')
    count = source.count(old)
    if count != 1:
        raise SystemExit(f'{label}: expected one match, found {count}')
    path.write_text(source.replace(old, new, 1), encoding='utf-8')


team = Path('lib/screens/team/team_selection_screen.dart')
replace_once(
    team,
    "      final json = await _transferService.encodePortable(bundle);\n"
    "      final displayName = _displayNameForSlot(slot);\n"
    "      final outcome = await _shareService.shareTextFile(\n",
    "      final json = await _transferService.encodePortable(bundle);\n"
    "      if (!mounted) return;\n"
    "      final displayName = _displayNameForSlot(slot);\n"
    "      final outcome = await _shareService.shareTextFile(\n",
    'share pokemon mounted check',
)
replace_once(
    team,
    "      final json = await _transferService.encodePortable(bundle);\n"
    "      final outcome = await _shareService.shareTextFile(\n"
    "        context: context,\n"
    "        content: json,\n"
    "        fileName: _transferService.fileNameForTeam(bundle),\n",
    "      final json = await _transferService.encodePortable(bundle);\n"
    "      if (!mounted) return;\n"
    "      final outcome = await _shareService.shareTextFile(\n"
    "        context: context,\n"
    "        content: json,\n"
    "        fileName: _transferService.fileNameForTeam(bundle),\n",
    'share team mounted check',
)

encounter = Path('lib/screens/tools/encounter_library_screen.dart')
replace_once(
    encounter,
    "      final json = await _transferService.encodePortable(bundle);\n"
    "      final outcome = await _shareService.shareTextFile(\n",
    "      final json = await _transferService.encodePortable(bundle);\n"
    "      if (!mounted) return;\n"
    "      final outcome = await _shareService.shareTextFile(\n",
    'share encounter mounted check',
)

trainer = Path('lib/screens/tools/npc_trainer_library_screen.dart')
replace_once(
    trainer,
    "      final json = await _transferService.encodePortable(bundle);\n"
    "      final outcome = await _shareService.shareTextFile(\n",
    "      final json = await _transferService.encodePortable(bundle);\n"
    "      if (!mounted) return;\n"
    "      final outcome = await _shareService.shareTextFile(\n",
    'share trainer mounted check',
)

log = Path('portable_transfer_validation.txt')
if log.exists():
    log.unlink()
