from __future__ import annotations

import json
import re
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


def repair_custom_library_composites() -> None:
    path = Path('lib/screens/pokemon/custom_pokemon_library_screen.dart')
    text = path.read_text(encoding='utf-8')

    catalog_start = text.find("uiTextForLanguage('Catalogo importato:")
    if catalog_start < 0:
        raise RuntimeError('Localized catalog import prefix not found')
    catalog_call_end = _call_end(text, text.find('(', catalog_start))
    next_literal_start = catalog_call_end
    while next_literal_start < len(text) and text[next_literal_start].isspace():
        next_literal_start += 1
    if next_literal_start >= len(text) or text[next_literal_start] not in ("'", '"'):
        raise RuntimeError('Catalog import suffix literal not found')
    catalog_end = scan_string_end(text, next_literal_start)
    catalog_replacement = """uiTextForLanguage(
          'Catalogo importato: ${imported.installed} installati, '
          '${imported.updated} aggiornati, ${imported.remapped} rimappati.',
          'Catalog imported: ${imported.installed} installed, '
          '${imported.updated} updated, ${imported.remapped} remapped.',
        )"""
    text = text[:catalog_start] + catalog_replacement + text[catalog_end:]

    forms_start = text.find(
        "'${_advanced.evolvesFrom.length} pre-evoluzioni · '"
    )
    if forms_start < 0:
        raise RuntimeError('Advanced evolution summary start not found')
    forms_call_start = text.find(
        "uiTextForLanguage('${_advanced.forms.length} forme'", forms_start
    )
    if forms_call_start < 0:
        raise RuntimeError('Localized advanced forms suffix not found')
    forms_end = _call_end(text, text.find('(', forms_call_start))
    forms_replacement = """uiTextForLanguage(
                      '${_advanced.evolvesFrom.length} pre-evoluzioni · '
                      '${_advanced.evolvesTo.length} evoluzioni · '
                      '${_advanced.forms.length} forme',
                      '${_advanced.evolvesFrom.length} pre-evolutions · '
                      '${_advanced.evolvesTo.length} evolutions · '
                      '${_advanced.forms.length} forms',
                    )"""
    text = text[:forms_start] + forms_replacement + text[forms_end:]
    path.write_text(text, encoding='utf-8')


def repair_remaining_const_contexts() -> None:
    npc_path = Path('lib/screens/battle/npc_battle_screen.dart')
    npc = npc_path.read_text(encoding='utf-8')
    npc = npc.replace(
        'const DropdownMenuItem<String?>(',
        'DropdownMenuItem<String?>(',
    )
    npc_path.write_text(npc, encoding='utf-8')

    library_path = Path('lib/screens/pokemon/custom_pokemon_library_screen.dart')
    library = library_path.read_text(encoding='utf-8')
    # La migrazione introduce espressioni runtime in numerosi widget e collezioni.
    # Rimuoviamo temporaneamente tutti i const da questo singolo file: il passaggio
    # successivo con dart fix ripristina quelli realmente sicuri, evitando però di
    # ricreare contesti const attorno a uiTextForLanguage().
    library = library.replace('const ', '')
    library_path.write_text(library, encoding='utf-8')

    edit_path = Path('lib/screens/pokemon/pokemon_edit_screen.dart')
    edit = edit_path.read_text(encoding='utf-8')
    edit = edit.replace('const _PickerGroupLabel(', '_PickerGroupLabel(')
    edit_path.write_text(edit, encoding='utf-8')


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
    repair_custom_library_composites()
    repair_remaining_const_contexts()
    MARKER.write_text('applied\n', encoding='utf-8')
    print(f'Applied {sum(len(values) for values in configured.values())} round 5 translations')


if __name__ == '__main__':
    main()
