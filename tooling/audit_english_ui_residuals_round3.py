from __future__ import annotations

import json
import re
from pathlib import Path

ROOTS = [Path('lib/screens'), Path('lib/widgets')]
EXTRA_FILES = [
    Path('lib/services/pokemon_habitat_service.dart'),
    Path('lib/models/breeding_candidate.dart'),
    Path('lib/models/breeding_egg.dart'),
]

ITALIAN_WORDS = {
    'abilità', 'aggiungi', 'allenatore', 'allevamento', 'ambiente', 'annulla',
    'apri', 'avanza', 'cattura', 'catturato', 'chiudi', 'combattimento',
    'competenze', 'conferma', 'crea', 'danno', 'descrizione', 'difficoltà',
    'elimina', 'errore', 'figlio', 'forma', 'generatore', 'genitore', 'gruppo',
    'incubazione', 'indietro', 'iniziativa', 'lealtà', 'livello', 'mossa',
    'mosse', 'natura', 'nessun', 'nessuna', 'oggetto', 'origine', 'pensione',
    'peso', 'pokémon', 'profilo', 'prova', 'riprova', 'risultato', 'salva',
    'scheda', 'schiusa', 'seleziona', 'sesso', 'squadra', 'strumenti',
    'tentativo', 'tira', 'turno', 'uovo', 'uova', 'usa', 'velocità', 'zaino',
    'qualsiasi', 'prateria', 'foresta', 'grotta', 'montagna', 'deserto',
    'palude', 'costa', 'fiumi', 'mare', 'città', 'neve', 'ghiaccio',
}

SKIP_FRAGMENTS = (
    'assets/', '.json', '.png', '.jpg', '.jpeg', '.webp', '.svg', '.dart',
    'package:', 'http://', 'https://', 'lib/', 'test/', 'key:',
)

CALL_NAMES = ('uiText', 'uiTextForLanguage')


def dart_files() -> list[Path]:
    files: list[Path] = []
    for root in ROOTS:
        if root.exists():
            files.extend(root.rglob('*.dart'))
    files.extend(path for path in EXTRA_FILES if path.exists())
    return sorted(set(files))


def _skip_string(text: str, index: int) -> int:
    quote = text[index]
    triple = text.startswith(quote * 3, index)
    delimiter = quote * 3 if triple else quote
    index += len(delimiter)
    while index < len(text):
        if text.startswith(delimiter, index):
            return index + len(delimiter)
        if text[index] == '\\':
            index += 2
        else:
            index += 1
    return len(text)


def _skip_comment(text: str, index: int) -> int:
    if text.startswith('//', index):
        end = text.find('\n', index + 2)
        return len(text) if end == -1 else end + 1
    if text.startswith('/*', index):
        end = text.find('*/', index + 2)
        return len(text) if end == -1 else end + 2
    return index


def call_spans(text: str) -> list[tuple[int, int]]:
    spans: list[tuple[int, int]] = []
    pattern = re.compile(r'\b(?:' + '|'.join(CALL_NAMES) + r')\s*\(')
    for match in pattern.finditer(text):
        open_paren = text.find('(', match.start())
        depth = 0
        index = open_paren
        while index < len(text):
            if text.startswith('//', index) or text.startswith('/*', index):
                index = _skip_comment(text, index)
                continue
            if text[index] in ('\'', '"'):
                index = _skip_string(text, index)
                continue
            if text[index] == '(':
                depth += 1
            elif text[index] == ')':
                depth -= 1
                if depth == 0:
                    spans.append((match.start(), index + 1))
                    break
            index += 1
    return spans


def string_literals(text: str):
    index = 0
    while index < len(text):
        if text.startswith('//', index) or text.startswith('/*', index):
            index = _skip_comment(text, index)
            continue
        if text[index] not in ('\'', '"'):
            index += 1
            continue
        start = index
        quote = text[index]
        triple = text.startswith(quote * 3, index)
        delimiter = quote * 3 if triple else quote
        index += len(delimiter)
        value_start = index
        while index < len(text):
            if text.startswith(delimiter, index):
                yield start, index + len(delimiter), text[value_start:index]
                index += len(delimiter)
                break
            if text[index] == '\\':
                index += 2
            else:
                index += 1
        else:
            break


def is_inside(position: int, spans: list[tuple[int, int]]) -> bool:
    return any(start <= position < end for start, end in spans)


def looks_italian(value: str) -> bool:
    text = value.strip()
    if len(text) < 2 or not re.search(r'[A-Za-zÀ-ÿ]', text):
        return False
    if any(fragment in text for fragment in SKIP_FRAGMENTS):
        return False
    lowered = text.lower()
    if re.search(r'[àèéìòùÀÈÉÌÒÙ]', text):
        return True
    return any(re.search(rf'\b{re.escape(word)}\b', lowered) for word in ITALIAN_WORDS)


def line_number(text: str, position: int) -> int:
    return text.count('\n', 0, position) + 1


def main() -> None:
    rows: list[dict[str, object]] = []
    for path in dart_files():
        text = path.read_text(encoding='utf-8')
        spans = call_spans(text)
        lines = text.splitlines()
        for start, _end, raw_value in string_literals(text):
            if is_inside(start, spans) or not looks_italian(raw_value):
                continue
            line = line_number(text, start)
            source = lines[line - 1].strip() if line <= len(lines) else ''
            rows.append({
                'path': path.as_posix(),
                'line': line,
                'value': raw_value.replace('\n', ' '),
                'source': source,
            })

    report = {
        'candidate_count': len(rows),
        'candidates': rows,
    }
    output = Path('diagnostics')
    output.mkdir(parents=True, exist_ok=True)
    (output / 'english-ui-residuals-round3.json').write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8',
    )
    markdown = [
        '# Audit residui italiani nella UI inglese — round 3',
        '',
        f'Candidati non racchiusi in `uiText`: **{len(rows)}**.',
        '',
    ]
    for row in rows:
        value = str(row['value']).replace('|', '\\|')
        markdown.append(f"- `{row['path']}:{row['line']}` — `{value}`")
    (output / 'english-ui-residuals-round3.md').write_text(
        '\n'.join(markdown) + '\n',
        encoding='utf-8',
    )
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
