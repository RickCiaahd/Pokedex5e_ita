from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "build"
REPORT = BUILD / "remaining-ui-localization-report.md"
MODIFIED = BUILD / "remaining-ui-modified-files.txt"


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding="utf-8")
    if old not in text:
        raise RuntimeError(f"Missing expected fragment in {path}: {old!r}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")


def main() -> None:
    encounter = ROOT / "lib/screens/tools/encounter_generator_screen.dart"
    replace_once(
        encounter,
        "childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),",
        "childrenPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),",
    )

    generator = ROOT / "lib/screens/tools/npc_trainer_generator_screen.dart"
    replace_once(
        generator,
        "import '../../models/trainer_manual_options.dart';\n",
        "import '../../models/trainer_manual_options.dart';\n"
        "import '../../models/trainer_ui_localization.dart';\n",
    )
    replace_once(
        generator,
        "  String get _specializationSummary {\n",
        "  List<String> get _localizedSpecializations {\n"
        "    final values = [..._specializations];\n"
        "    values.sort(\n"
        "      (a, b) => TrainerUiLocalization.specializationName(\n"
        "        a,\n"
        "      ).compareTo(TrainerUiLocalization.specializationName(b)),\n"
        "    );\n"
        "    return values;\n"
        "  }\n\n"
        "  String get _specializationSummary {\n",
    )
    replace_once(
        generator,
        "                          for (final specialization in _specializations)\n"
        "                            DropdownMenuItem(\n"
        "                              value: specialization,\n"
        "                              child: Text(specialization),\n"
        "                            ),",
        "                          for (final specialization in\n"
        "                              _localizedSpecializations)\n"
        "                            DropdownMenuItem(\n"
        "                              value: specialization,\n"
        "                              child: Text(\n"
        "                                TrainerUiLocalization.specializationName(\n"
        "                                  specialization,\n"
        "                                ),\n"
        "                              ),\n"
        "                            ),",
    )

    result = ROOT / "lib/screens/tools/npc_trainer_result_screen.dart"
    replace_once(
        result,
        "import '../../models/trainer_manual_content.dart';\n",
        "import '../../models/trainer_manual_content.dart';\n"
        "import '../../models/trainer_ui_localization.dart';\n",
    )
    replace_once(
        result,
        "  String _summaryText() {\n    final buffer = StringBuffer()",
        "  String _summaryText() {\n"
        "    final specializationLabels = _trainer.specializations\n"
        "        .map(TrainerUiLocalization.specializationName)\n"
        "        .join(', ');\n"
        "    final buffer = StringBuffer()",
    )
    replace_once(
        result,
        "          'Specializzazioni: ${_trainer.specializations.join(', ')}',\n"
        "          'Specializations: ${_trainer.specializations.join(', ')}',",
        "          'Specializzazioni: $specializationLabels',\n"
        "          'Specializations: $specializationLabels',",
    )
    replace_once(
        result,
        "  Widget build(BuildContext context) {\n"
        "    final colors = Theme.of(context).colorScheme;\n"
        "    return Card(\n"
        "      color: colors.primaryContainer,",
        "  Widget build(BuildContext context) {\n"
        "    final colors = Theme.of(context).colorScheme;\n"
        "    final specializationLabels = trainer.specializations\n"
        "        .map(TrainerUiLocalization.specializationName)\n"
        "        .join(' · ');\n"
        "    return Card(\n"
        "      color: colors.primaryContainer,",
    )
    replace_once(
        result,
        "                'Specializzazioni: ${trainer.specializations.join(' · ')}',\n"
        "                'Specializations: ${trainer.specializations.join(' · ')}',",
        "                'Specializzazioni: $specializationLabels',\n"
        "                'Specializations: $specializationLabels',",
    )

    library = ROOT / "lib/screens/tools/npc_trainer_library_screen.dart"
    replace_once(
        library,
        "import '../../models/trainer_manual_options.dart';\n",
        "import '../../models/trainer_manual_options.dart';\n"
        "import '../../models/trainer_ui_localization.dart';\n",
    )
    replace_once(
        library,
        "  Widget build(BuildContext context) {\n"
        "    return Card(\n"
        "      clipBehavior: Clip.antiAlias,",
        "  Widget build(BuildContext context) {\n"
        "    final specializationLabels = trainer.specializations\n"
        "        .map(TrainerUiLocalization.specializationName)\n"
        "        .join(', ');\n"
        "    return Card(\n"
        "      clipBehavior: Clip.antiAlias,",
    )
    replace_once(
        library,
        "'${context.usesItalianUi ? trainer.rank.label : trainer.rank.englishLabel} · Lv. ${trainer.trainerLevel} · ${trainer.specializations.join(', ')}',",
        "'${context.usesItalianUi ? trainer.rank.label : trainer.rank.englishLabel} · Lv. ${trainer.trainerLevel} · $specializationLabels',",
    )

    test = ROOT / "test/npc_specialization_ui_localization_test.dart"
    test.write_text(
        """import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/localization/game_catalog_locale.dart';
import 'package:pokedex_5e_ita/models/trainer_ui_localization.dart';

void main() {
  tearDown(() => GameCatalogLocale.setLanguageCode('it'));

  test('NPC specialization labels follow the selected language', () {
    GameCatalogLocale.setLanguageCode('it');
    expect(
      TrainerUiLocalization.specializationName('Bird Keeper'),
      'Avicoltore',
    );
    expect(
      TrainerUiLocalization.specializationName('Alchemist'),
      'Alchimista',
    );

    GameCatalogLocale.setLanguageCode('en');
    expect(
      TrainerUiLocalization.specializationName('Bird Keeper'),
      'Bird Keeper',
    );
  });

  test('NPC screens render specializations through the localization helper', () {
    for (final path in <String>[
      'lib/screens/tools/npc_trainer_generator_screen.dart',
      'lib/screens/tools/npc_trainer_result_screen.dart',
      'lib/screens/tools/npc_trainer_library_screen.dart',
    ]) {
      expect(
        File(path).readAsStringSync(),
        contains('TrainerUiLocalization.specializationName'),
        reason: path,
      );
    }
  });

  test('advanced encounter filters leave room for the floating label', () {
    final source = File(
      'lib/screens/tools/encounter_generator_screen.dart',
    ).readAsStringSync();
    expect(
      source,
      contains('childrenPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16)'),
    );
  });
}
""",
        encoding="utf-8",
    )

    BUILD.mkdir(parents=True, exist_ok=True)
    MODIFIED.write_text("", encoding="utf-8")
    REPORT.write_text(
        "# Correzione UI PNG e filtri incontri\n\n"
        "- aggiunto spazio superiore al primo campo dei filtri avanzati;\n"
        "- specializzazioni PNG localizzate nel selettore, nel risultato, "
        "nel riepilogo copiato e nella libreria;\n"
        "- mantenuti i valori canonici inglesi nei dati salvati.\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
