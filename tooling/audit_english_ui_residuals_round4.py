from __future__ import annotations

import json
import re
from pathlib import Path

ROOTS = [Path('lib/screens'), Path('lib/widgets')]
EXCLUDED_PATHS = {
    'lib/widgets/pokemon/pokemon_asset_image.dart',
    'lib/widgets/pokemon/pokemon_asset_image_legacy.dart',
    'lib/widgets/pokemon/pokemon_minior_asset_paths.dart',
}
ALLOWED_EXACT = {
    'Pokémon', 'Poké Ball', 'Pokémon Breeder', '${data.profile.name} + Pokémon',
    'Acrobazia', 'Addestrare Animali', 'Arcano', 'Atletica', 'Inganno', 'Storia',
    'Intuizione', 'Intimidire', 'Investigazione', 'Medicina', 'Natura',
    'Percezione', 'Intrattenere', 'Persuasione', 'Religione',
    'Rapidità di Mano', 'Furtività', 'Sopravvivenza',
}
WORDS = {
    'abilità','aggiungi','allenatore','allenatori','allevamento','ambiente','annulla',
    'apri','avanza','bacca','cattura','catturato','chiudi','combattimento',
    'competenze','competenza','conferma','crea','danno','descrizione','difficoltà',
    'elimina','errore','figlio','forma','forme','generatore','genitore','gruppo',
    'incubazione','indietro','iniziativa','lealtà','livello','mossa','mosse',
    'natura','nessun','nessuna','oggetto','origine','pensione','peso','profilo',
    'prova','riprova','risultato','salva','scheda','schiusa','seleziona','sesso',
    'squadra','strumento','strumenti','tentativo','tira','turno','uovo','uova','usa',
    'velocità','zaino','qualsiasi','maschio','femmina','senza','personalità',
    'rilancia','comune','gestione','percorso','opzione','disponibile','disponibili',
    'ripristinato','completamente','collegamento','personalizzata','permanente',
    'momentanea','segreto','scoperta','importato','esportato','scegli','cerca',
    'altre','contenuto','giocatore','catalogo','attivi','contemporaneamente',
    'prossimo','nessuno','rimuovi','modifica','nome','nascosta',
}
SKIP_PARTS = ('assets/', '.json', '.png', '.jpg', '.jpeg', '.webp', '.svg', '.dart', 'package:', 'http://', 'https://')
CALLS = ('uiText', 'uiTextForLanguage')


def skip_comment(text: str, index: int) -> int:
    if text.startswith('//', index):
        end = text.find('\n', index + 2)
        return len(text) if end < 0 else end + 1
    end = text.find('*/', index + 2)
    return len(text) if end < 0 else end + 2


def skip_interpolation(text: str, index: int) -> int:
    depth = 1
    while index < len(text):
        if text.startswith('//', index) or text.startswith('/*', index):
            index = skip_comment(text, index)
            continue
        if text[index] in ("'", '"'):
            index = string_end(text, index)
            continue
        if text[index] == '{':
            depth += 1
        elif text[index] == '}':
            depth -= 1
            if depth == 0:
                return index + 1
        index += 1
    return len(text)


def string_end(text: str, start: int) -> int:
    quote = text[start]
    delim = quote * 3 if text.startswith(quote * 3, start) else quote
    index = start + len(delim)
    while index < len(text):
        if text.startswith(delim, index):
            return index + len(delim)
        if text[index] == '\\':
            index += 2
            continue
        if text.startswith('${', index):
            index = skip_interpolation(text, index + 2)
            continue
        index += 1
    return len(text)


def strings(text: str):
    index = 0
    while index < len(text):
        if text.startswith('//', index) or text.startswith('/*', index):
            index = skip_comment(text, index)
            continue
        if text[index] not in ("'", '"'):
            index += 1
            continue
        start = index
        delim = text[index] * 3 if text.startswith(text[index] * 3, index) else text[index]
        end = string_end(text, start)
        yield start, end, text[start + len(delim):end - len(delim)]
        index = end


def call_spans(text: str):
    spans = []
    pattern = re.compile(r'\b(?:' + '|'.join(CALLS) + r')\s*\(')
    for match in pattern.finditer(text):
        open_at = text.find('(', match.start())
        depth = 0
        i = open_at
        while i < len(text):
            if text.startswith('//', i) or text.startswith('/*', i):
                i = skip_comment(text, i)
                continue
            if text[i] in ("'", '"'):
                i = string_end(text, i)
                continue
            if text[i] == '(':
                depth += 1
            elif text[i] == ')':
                depth -= 1
                if depth == 0:
                    spans.append((match.start(), i + 1))
                    break
            i += 1
    return spans


def looks_italian(value: str) -> bool:
    value = value.strip()
    if value in ALLOWED_EXACT or len(value) < 2:
        return False
    if any(part in value for part in SKIP_PARTS):
        return False
    if not re.search(r'[A-Za-zÀ-ÿ]', value):
        return False
    if re.search(r'[àèéìòù]', value, re.I):
        return True
    lower = value.lower()
    return any(re.search(rf'\b{re.escape(word)}\b', lower) for word in WORDS)


def main() -> None:
    rows = []
    for root in ROOTS:
        for path in root.rglob('*.dart'):
            name = path.as_posix()
            if name in EXCLUDED_PATHS:
                continue
            text = path.read_text(encoding='utf-8')
            spans = call_spans(text)
            lines = text.splitlines()
            for start, _end, value in strings(text):
                if any(a <= start < b for a, b in spans):
                    continue
                if not looks_italian(value):
                    continue
                line = text.count('\n', 0, start) + 1
                rows.append({
                    'path': name,
                    'line': line,
                    'value': value.replace('\n', ' '),
                    'source': lines[line - 1].strip(),
                })
    out = Path('diagnostics')
    out.mkdir(exist_ok=True)
    report = {'candidate_count': len(rows), 'candidates': rows}
    (out / 'english-ui-residuals-round4.json').write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8',
    )
    md = [
        '# Audit residui italiani UI inglese — round 4',
        '',
        f'Candidati visibili non localizzati: **{len(rows)}**.',
        '',
    ]
    md += [
        f"- `{row['path']}:{row['line']}` — `{row['value'].replace('|', '\\|')}`"
        for row in rows
    ]
    (out / 'english-ui-residuals-round4.md').write_text(
        '\n'.join(md) + '\n',
        encoding='utf-8',
    )
    print(json.dumps(report, ensure_ascii=False, indent=2))
    if rows:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
