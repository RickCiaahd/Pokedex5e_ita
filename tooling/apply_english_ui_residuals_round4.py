from __future__ import annotations

import json
import os
import re
from pathlib import Path

TRANSLATIONS = Path('tooling/english_ui_round4_translations.json')
MARKER = Path('tooling/.english_ui_round4_applied')


def ui_import_for(path: Path) -> str:
    rel = os.path.relpath(Path('lib/localization/ui_text.dart'), path.parent)
    return rel.replace(os.sep, '/')


def ensure_import(path: Path, import_path: str | None = None) -> None:
    text = path.read_text(encoding='utf-8')
    target = import_path or ui_import_for(path)
    line = f"import '{target}';"
    if line in text:
        return
    lines = text.splitlines(keepends=True)
    last_import = -1
    for i, current in enumerate(lines):
        if current.startswith('import '):
            last_import = i
        elif last_import >= 0 and current.strip():
            break
    lines.insert(last_import + 1 if last_import >= 0 else 0, line + '\n')
    path.write_text(''.join(lines), encoding='utf-8')


def skip_line_comment(text: str, index: int) -> int:
    end = text.find('\n', index + 2)
    return len(text) if end < 0 else end + 1


def skip_block_comment(text: str, index: int) -> int:
    end = text.find('*/', index + 2)
    return len(text) if end < 0 else end + 2


def scan_interpolation(text: str, index: int) -> int:
    depth = 1
    while index < len(text):
        if text.startswith('//', index):
            index = skip_line_comment(text, index)
            continue
        if text.startswith('/*', index):
            index = skip_block_comment(text, index)
            continue
        if text[index] in ("'", '"'):
            index = scan_string_end(text, index)
            continue
        if text[index] == '{':
            depth += 1
        elif text[index] == '}':
            depth -= 1
            if depth == 0:
                return index + 1
        index += 1
    return len(text)


def scan_string_end(text: str, start: int) -> int:
    quote = text[start]
    delimiter = quote * 3 if text.startswith(quote * 3, start) else quote
    index = start + len(delimiter)
    while index < len(text):
        if text.startswith(delimiter, index):
            return index + len(delimiter)
        if text[index] == '\\':
            index += 2
            continue
        if text.startswith('${', index):
            index = scan_interpolation(text, index + 2)
            continue
        index += 1
    return len(text)


def string_literals(text: str):
    index = 0
    while index < len(text):
        if text.startswith('//', index):
            index = skip_line_comment(text, index)
            continue
        if text.startswith('/*', index):
            index = skip_block_comment(text, index)
            continue
        if text[index] not in ("'", '"'):
            index += 1
            continue
        start = index
        delimiter = text[index] * 3 if text.startswith(text[index] * 3, index) else text[index]
        end = scan_string_end(text, start)
        raw = text[start + len(delimiter):end - len(delimiter)]
        yield start, end, raw
        index = end


def english_literal(value: str) -> str:
    if '"""' not in value:
        return f'"""{value}"""'
    escaped = value.replace('\\', '\\\\').replace("'", "\\'")
    return f"'{escaped}'"


def localize_file(path: Path, translations: dict[str, str]) -> None:
    ensure_import(path)
    text = path.read_text(encoding='utf-8')
    replacements: list[tuple[int, int, str]] = []
    found: set[str] = set()
    for start, end, raw in string_literals(text):
        english = translations.get(raw)
        if english is None:
            continue
        original = text[start:end]
        replacements.append((start, end, f'uiTextForLanguage({original}, {english_literal(english)})'))
        found.add(raw)
    for start, end, replacement in reversed(replacements):
        text = text[:start] + replacement + text[end:]
    missing = sorted(set(translations) - found)
    if missing:
        print(f'{path}: {len(missing)} configured values not found')
        for value in missing:
            print(f'  - {value}')
    path.write_text(text, encoding='utf-8')


def replace_once(path: Path, old: str, new: str, *, required: bool = True) -> None:
    text = path.read_text(encoding='utf-8')
    if old not in text:
        if required:
            raise RuntimeError(f'Missing fragment in {path}: {old[:160]!r}')
        return
    path.write_text(text.replace(old, new, 1), encoding='utf-8')


def remove_invalid_const_widgets(path: Path) -> None:
    text = path.read_text(encoding='utf-8')
    widgets = (
        'AlertDialog', 'AppBar', 'Card', 'Center', 'CheckboxListTile', 'Chip',
        'ChoiceChip', 'Column', 'Container', 'DecoratedBox', 'Dialog',
        'DropdownMenuItem', 'ElevatedButton', 'Expanded', 'FilledButton',
        'Flexible', 'IconButton', 'InputDecoration', 'ListTile', 'Padding',
        'RadioListTile', 'Row', 'Scaffold', 'SliverToBoxAdapter', 'SwitchListTile',
        'Tab', 'Text', 'TextButton', 'TextSpan', 'Tooltip', 'Wrap',
    )
    text = re.sub(r'\bconst (?=(?:' + '|'.join(widgets) + r')\s*\()', '', text)
    for prefix in ('actions:', 'children:', 'items:', 'tabs:', 'spans:'):
        text = text.replace(f'{prefix} const [', f'{prefix} [')
    path.write_text(text, encoding='utf-8')


def repair_pokemon_edit() -> None:
    path = Path('lib/screens/pokemon/pokemon_edit_screen.dart')
    ensure_import(path, '../../localization/game_catalog_locale.dart')
    text = path.read_text(encoding='utf-8')
    if 'Map<String, String> get _localizedSkillLabels' not in text:
        anchor = "  final AbilityRepository _abilityRepository = AbilityRepository();\n"
        getter = """  Map<String, String> get _localizedSkillLabels =>
      GameCatalogLocale.isItalian
          ? _skillLabels
          : {for (final skill in _skills) skill: skill};

"""
        if anchor not in text:
            raise RuntimeError('Pokemon edit repository anchor not found')
        text = text.replace(anchor, getter + anchor, 1)
    text = text.replace('labels: _skillLabels,', 'labels: _localizedSkillLabels,')
    text = text.replace(
        "labelText: 'Natura',",
        "labelText: uiTextForLanguage('Natura', 'Nature'),",
        1,
    )
    path.write_text(text, encoding='utf-8')


def repair_team_import_composites() -> None:
    path = Path('lib/screens/team/team_selection_screen.dart')
    text = path.read_text(encoding='utf-8')
    text = text.replace(
        "'Il catalogo non contiene i Pokémon: ${unknownIds.join(', ')}.',",
        "uiTextForLanguage(\n            'Il catalogo non contiene i Pokémon: ${unknownIds.join(', ')}.',\n            'The catalog does not contain these Pokémon: ${unknownIds.join(', ')}.',\n          ),",
        1,
    )
    path.write_text(text, encoding='utf-8')


def repair_legacy_status_catalog() -> None:
    path = Path('lib/screens/pokemon/pokemon_detail_screen_legacy.dart')
    text = path.read_text(encoding='utf-8')
    text = text.replace('const _statusEffectInfos = [', 'final _statusEffectInfos = [', 1)
    path.write_text(text, encoding='utf-8')


def write_test() -> None:
    Path('test/english_ui_residuals_round4_test.dart').write_text(
        """import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/localization/game_catalog_locale.dart';
import 'package:pokedex_5e_ita/localization/ui_text.dart';

void main() {
  tearDown(() => GameCatalogLocale.setLanguageCode('it'));

  test('round 4 strings follow the selected language', () {
    GameCatalogLocale.setLanguageCode('en');
    expect(uiTextForLanguage('Annulla', 'Cancel'), 'Cancel');
    expect(uiTextForLanguage('Scheda', 'Sheet'), 'Sheet');
    GameCatalogLocale.setLanguageCode('it');
    expect(uiTextForLanguage('Annulla', 'Cancel'), 'Annulla');
  });

  test('general English audit covers the remaining visible areas', () {
    final files = <String, List<String>>{
      'lib/screens/battle/npc_battle_screen.dart': [
        'NPC Trainer',
        'SHARED INITIATIVE',
        'NEXT TURN',
      ],
      'lib/screens/pokemon/custom_pokemon_library_screen.dart': [
        'OPEN ADVANCED EDITOR',
        'SAVE FAKEMON',
      ],
      'lib/screens/pokemon/custom_pokemon_advanced_editor_screen.dart': [
        'SAVE ADVANCED DATA',
        'CUSTOM FORM',
      ],
      'lib/screens/pokemon/pokemon_edit_screen.dart': [
        'Choose ability',
        'Proficiencies',
        'CHOOSE MOVE',
      ],
      'lib/screens/team/team_selection_screen.dart': [
        'Choose Pokémon',
        'Retry',
      ],
      'lib/widgets/trainer/trainer_path_automation_panel.dart': [
        'TRAINER PATH MANAGEMENT',
      ],
    };
    for (final entry in files.entries) {
      final source = File(entry.key).readAsStringSync();
      for (final expected in entry.value) {
        expect(source, contains(expected), reason: '${entry.key}: $expected');
      }
    }
  });
}
""",
        encoding='utf-8',
    )


def main() -> None:
    if MARKER.exists():
        print('Round 4 already applied')
        return
    configured: dict[str, dict[str, str]] = json.loads(TRANSLATIONS.read_text(encoding='utf-8'))
    for raw_path, translations in configured.items():
        path = Path(raw_path)
        localize_file(path, translations)

    repair_pokemon_edit()
    repair_team_import_composites()
    repair_legacy_status_catalog()
    write_test()

    for raw_path in configured:
        remove_invalid_const_widgets(Path(raw_path))

    MARKER.write_text('applied\n', encoding='utf-8')
    print(f'Applied {sum(len(v) for v in configured.values())} round 4 translations')


if __name__ == '__main__':
    main()
