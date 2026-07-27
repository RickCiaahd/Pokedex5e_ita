from __future__ import annotations

import json
import re
from pathlib import Path

from audit_english_ui_residuals_round4 import ROOTS, call_spans, strings

EXCLUDED_PATHS = {
    'lib/widgets/pokemon/pokemon_asset_image.dart',
    'lib/widgets/pokemon/pokemon_asset_image_legacy.dart',
    'lib/widgets/pokemon/pokemon_minior_asset_paths.dart',
    'lib/widgets/pokemon/pokemon_gender_asset_paths.dart',
}

ALLOWED_EXACT = {
    'Pokémon',
    'Poké Ball',
    'Pokémon Breeder',
    'Pokémon Center',
    'POKÉMON CENTER',
    '${data.profile.name} + Pokémon',
    'Acrobazia',
    'Addestrare Animali',
    'Arcano',
    'Atletica',
    'Inganno',
    'Storia',
    'Intuizione',
    'Intimidire',
    'Investigazione',
    'Medicina',
    'Natura',
    'Percezione',
    'Intrattenere',
    'Persuasione',
    'Religione',
    'Rapidità di Mano',
    'Furtività',
    'Sopravvivenza',
}

PATH_ALLOWED = {
    'lib/screens/onboarding/first_launch_onboarding_screen.dart': {
        'Origine 5e approvata dal DM',
    },
    'lib/screens/trainer/trainer_sheet_screen.dart': {
        'Origine 5e approvata dal DM',
    },
    'lib/screens/tools/encounter_generator_screen.dart': {
        'Qualsiasi',
    },
}

WORDS = {
    'abilità', 'aggiungi', 'aggiorna', 'allenatore', 'allenatori',
    'allevamento', 'ambiente', 'annulla', 'apri', 'attivi', 'attivo',
    'avanza', 'azzera', 'bacca', 'catalogo', 'cattura', 'catturato',
    'cerca', 'chiudi', 'combattimento', 'completamente', 'competenze',
    'competenza', 'condividi', 'conferma', 'contenuto', 'crea', 'danno',
    'descrizione', 'dettagli', 'difficoltà', 'disponibile', 'disponibili',
    'elimina', 'errore', 'esporta', 'esportato', 'esportazione', 'femmina',
    'figlio', 'forma', 'forme', 'generatore', 'genitore', 'gestione',
    'gruppo', 'importa', 'importato', 'importazione', 'incubazione',
    'indietro', 'iniziativa', 'lealtà', 'livello', 'maschio', 'modifica',
    'momentanea', 'mossa', 'mosse', 'nascosta', 'natura', 'nessun',
    'nessuna', 'nessuno', 'nome', 'nuovo', 'oggetto', 'opzione', 'origine',
    'percorso', 'permanente', 'personalità', 'pensione', 'peso', 'profilo',
    'prossimo', 'prova', 'riepilogo', 'rilancia', 'rimuovi', 'riprova',
    'ripristinato', 'risorse', 'risultato', 'salva', 'scheda', 'schiusa',
    'scelta', 'scelte', 'scegli', 'segreto', 'seleziona', 'sesso',
    'sostituire', 'squadra', 'strumento', 'strumenti', 'tentativo',
    'termina', 'tira', 'turno', 'uovo', 'uova', 'usa', 'velocità', 'zaino',
    'qualsiasi', 'altre', 'azioni', 'comune', 'collegamento',
    'personalizzata', 'scoperta', 'contemporaneamente', 'disponibilità',
}

SKIP_PARTS = (
    'assets/', '.json', '.png', '.jpg', '.jpeg', '.webp', '.svg', '.dart',
    'package:', 'http://', 'https://',
)


def looks_italian(value: str, path: str) -> bool:
    stripped = value.strip()
    if stripped in ALLOWED_EXACT or stripped in PATH_ALLOWED.get(path, set()):
        return False
    if len(stripped) < 2 or not re.search(r'[A-Za-zÀ-ÿ]', stripped):
        return False
    if any(part in stripped for part in SKIP_PARTS):
        return False
    if 'uiText(' in stripped or 'uiTextForLanguage(' in stripped:
        return False

    without_brand = re.sub(r'Pok(?:é|e)(?:mon|dex|slot|ball)?', '', stripped, flags=re.I)
    if re.search(r'[àèéìòù]', without_brand, flags=re.I):
        return True

    lowered = stripped.lower()
    return any(re.search(rf'\b{re.escape(word)}\b', lowered) for word in WORDS)


def main() -> None:
    rows: list[dict[str, object]] = []
    for root in ROOTS:
        for path in root.rglob('*.dart'):
            path_string = path.as_posix()
            if path_string in EXCLUDED_PATHS:
                continue
            text = path.read_text(encoding='utf-8')
            spans = call_spans(text)
            lines = text.splitlines()
            for start, _end, value in strings(text):
                if any(span_start <= start < span_end for span_start, span_end in spans):
                    continue
                if not looks_italian(value, path_string):
                    continue
                line = text.count('\n', 0, start) + 1
                rows.append({
                    'path': path_string,
                    'line': line,
                    'value': value.replace('\n', ' '),
                    'source': lines[line - 1].strip(),
                })

    output = Path('diagnostics')
    output.mkdir(exist_ok=True)
    report = {'candidate_count': len(rows), 'candidates': rows}
    (output / 'english-ui-residuals-round5.json').write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8',
    )
    markdown = [
        '# Audit residui italiani UI inglese — round 5',
        '',
        f'Candidati visibili non localizzati: **{len(rows)}**.',
        '',
    ]
    for row in rows:
        value = str(row['value']).replace('|', '\\|')
        markdown.append(f"- `{row['path']}:{row['line']}` — `{value}`")
    (output / 'english-ui-residuals-round5.md').write_text(
        '\n'.join(markdown) + '\n',
        encoding='utf-8',
    )
    print(json.dumps(report, ensure_ascii=False, indent=2))
    if rows:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
