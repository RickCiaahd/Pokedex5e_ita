from __future__ import annotations

import json
import re
from collections import Counter
from pathlib import Path

ROOTS = [Path('lib/screens'), Path('lib/widgets')]
EXTRA_FILES = [
    Path('lib/models/trainer_ui_localization.dart'),
    Path('lib/services/battle_status_rules.dart'),
]

STRING_RE = re.compile(r"(?P<quote>['\"])(?P<value>(?:\\.|(?!\1).)*?)(?P=quote)")
ITALIAN_WORDS = {
    'abilità', 'allenatore', 'annulla', 'apri', 'avanti', 'catturato',
    'chiudi', 'combattimento', 'competenze', 'conferma', 'crea', 'danno',
    'descrizione', 'errore', 'fight', 'forma', 'generatore', 'indietro',
    'iniziativa', 'livello', 'mossa', 'mosse', 'natura', 'nessun', 'nessuna',
    'oggetto', 'origine', 'peso', 'pokémon', 'profilo', 'riprova', 'round',
    'salva', 'scheda', 'seleziona', 'squadra', 'strumenti', 'turno', 'visto',
    'velocità', 'zaino', 'altezza', 'master', 'sessione', 'libreria',
}
UI_HINTS = (
    'Text(', 'title:', 'subtitle:', 'label', 'tooltip', 'description:',
    'message:', 'hintText:', 'labelText:', 'SnackBar', 'Dialog', 'AppBar',
    'GuidedTourStepData', 'Semantics', 'actionLabel:', 'placeholder',
)
SKIP_PARTS = (
    'assets/', '.json', '.png', '.jpg', '.webp', '.svg', '.dart',
    'package:', 'http://', 'https://', 'lib/', 'test/', 'key:',
)


def dart_files() -> list[Path]:
    files: list[Path] = []
    for root in ROOTS:
        if root.exists():
            files.extend(root.rglob('*.dart'))
    files.extend(path for path in EXTRA_FILES if path.exists())
    return sorted(set(files))


def is_candidate(value: str, line: str) -> bool:
    text = value.strip()
    if len(text) < 2 or not re.search(r'[A-Za-zÀ-ÿ]', text):
        return False
    if any(part in text for part in SKIP_PARTS):
        return False
    if re.fullmatch(r'[A-Za-z0-9_.:/-]+', text) and ' ' not in text:
        return False
    lowered = text.lower()
    italian = any(word in lowered for word in ITALIAN_WORDS) or bool(
        re.search(r'[àèéìòùÀÈÉÌÒÙ]', text)
    )
    hinted = any(hint in line for hint in UI_HINTS)
    return italian or hinted


def main() -> None:
    rows: list[dict[str, object]] = []
    per_file: Counter[str] = Counter()

    for path in dart_files():
        lines = path.read_text(encoding='utf-8').splitlines()
        for number, line in enumerate(lines, start=1):
            if line.lstrip().startswith('//'):
                continue
            for match in STRING_RE.finditer(line):
                value = bytes(match.group('value'), 'utf-8').decode(
                    'unicode_escape', errors='replace'
                )
                if not is_candidate(value, line):
                    continue
                row = {
                    'path': path.as_posix(),
                    'line': number,
                    'value': value,
                    'source': line.strip(),
                }
                rows.append(row)
                per_file[path.as_posix()] += 1

    report = {
        'candidate_count': len(rows),
        'file_count': len(per_file),
        'files': [
            {'path': path, 'count': count}
            for path, count in per_file.most_common()
        ],
        'candidates': rows,
    }
    output = Path('build/ui-localization-audit')
    output.mkdir(parents=True, exist_ok=True)
    (output / 'audit.json').write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8',
    )

    markdown = [
        '# Audit stringhe UI',
        '',
        f"Candidati: **{len(rows)}** in **{len(per_file)}** file.",
        '',
        '## File con più candidati',
        '',
    ]
    for path, count in per_file.most_common():
        markdown.append(f'- `{path}`: {count}')
    markdown.extend(['', '## Stringhe candidate', ''])
    for row in rows:
        value = str(row['value']).replace('|', '\\|').replace('\n', ' ')
        markdown.append(
            f"- `{row['path']}:{row['line']}` — `{value}`"
        )
    (output / 'audit.md').write_text('\n'.join(markdown) + '\n', encoding='utf-8')

    print(json.dumps({'candidates': len(rows), 'files': len(per_file)}))


if __name__ == '__main__':
    main()
