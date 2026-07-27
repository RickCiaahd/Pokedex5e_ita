from __future__ import annotations

import json
from pathlib import Path

from apply_english_ui_residuals_round4 import (
    localize_file,
    remove_invalid_const_widgets,
    scan_string_end,
)

TRANSLATIONS = Path('tooling/english_ui_round5_translations.json')
MARKER = Path('tooling/.english_ui_round5_applied')


def _call_end(text: str, open_paren: int) -> int:
    depth = 0
    index = open_paren
    while index < len(text):
        if text.startswith('//', index):
            end = text.find('\n', index + 2)
            index = len(text) if end < 0 else end + 1
            continue
        if text.startswith('/*', index):
            end = text.find('*/', index + 2)
            index = len(text) if end < 0 else end + 2
            continue
        if text[index] in ("'", '"'):
            index = scan_string_end(text, index)
            continue
        if text[index] == '(':
            depth += 1
        elif text[index] == ')':
            depth -= 1
            if depth == 0:
                return index + 1
        index += 1
    raise RuntimeError('Unclosed Dart call')


def repair_team_import_dialog() -> None:
    path = Path('lib/screens/team/team_selection_screen.dart')
    text = path.read_text(encoding='utf-8')
    title = "title: Text(context.uiText('Importare squadra?', 'Import team?'))"
    title_at = text.find(title)
    if title_at < 0:
        raise RuntimeError('Import team dialog title not found')
    content_at = text.find('content: Text(', title_at)
    if content_at < 0:
        raise RuntimeError('Import team dialog content not found')
    open_paren = text.find('(', content_at)
    call_end = _call_end(text, open_paren)
    replacement = """content: Text(
            uiTextForLanguage(
              'Stai importando ${bundle.pokemon.length} Pokémon$source. '
              '${replaced > 0 ? 'I $replaced Pokémon attualmente in squadra verranno spostati nel PC. ' : ''}'
              'Le uova resteranno nei loro slot. '
              '${overflow > 0 ? '$overflow Pokémon importati finiranno nel PC perché non ci sono abbastanza Pokéslot disponibili.' : ''}',
              'You are importing ${bundle.pokemon.length} Pokémon$source. '
              '${replaced > 0 ? 'The $replaced Pokémon currently in the team will be moved to the PC. ' : ''}'
              'Eggs will remain in their slots. '
              '${overflow > 0 ? '$overflow imported Pokémon will be sent to the PC because there are not enough Poké Slots available.' : ''}',
            ),
          )"""
    text = text[:content_at] + replacement + text[call_end:]
    path.write_text(text, encoding='utf-8')


def main() -> None:
    if MARKER.exists():
        print('Round 5 already applied')
        return

    configured: dict[str, dict[str, str]] = json.loads(
        TRANSLATIONS.read_text(encoding='utf-8')
    )
    for raw_path, translations in configured.items():
        path = Path(raw_path)
        localize_file(path, translations)
        remove_invalid_const_widgets(path)

    repair_team_import_dialog()
    MARKER.write_text('applied\n', encoding='utf-8')
    print(f'Applied {sum(len(values) for values in configured.values())} round 5 translations')


if __name__ == '__main__':
    main()
