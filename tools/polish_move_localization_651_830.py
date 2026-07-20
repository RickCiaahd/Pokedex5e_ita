import json
import re
from copy import deepcopy
from pathlib import Path

SOURCE_PATH = Path('assets/data_webapp/moves.json')
OVERLAY_PATHS = [
    Path('assets/data/move_localization_it_651_700.json'),
    Path('assets/data/move_localization_it_701_750.json'),
    Path('assets/data/move_localization_it_751_800.json'),
    Path('assets/data/move_localization_it_801_830.json'),
]
SPECIAL_PATH = Path('tools/move_localization_651_830_special.json')
DIAGNOSTIC_PATH = Path('docs/translation/move-651-830-polish-diagnostic.txt')

DAMAGE_TYPES = {
    'normal': 'Normale', 'normale': 'Normale',
    'fire': 'Fuoco', 'fuoco': 'Fuoco',
    'water': 'Acqua', 'acqua': 'Acqua',
    'electric': 'Elettro', 'elettrico': 'Elettro', 'elettrici': 'Elettro',
    'grass': 'Erba', 'erba': 'Erba',
    'ice': 'Ghiaccio', 'ghiaccio': 'Ghiaccio',
    'fighting': 'Lotta', 'lotta': 'Lotta', 'combattimento': 'Lotta',
    'poison': 'Veleno', 'veleno': 'Veleno',
    'ground': 'Terra', 'terra': 'Terra', 'suolo': 'Terra',
    'flying': 'Volante', 'volante': 'Volante', 'volanti': 'Volante',
    'psychic': 'Psico', 'psichico': 'Psico', 'psichici': 'Psico',
    'bug': 'Coleottero', 'insetto': 'Coleottero', 'insetti': 'Coleottero',
    'coleottero': 'Coleottero', 'rock': 'Roccia', 'roccia': 'Roccia',
    'ghost': 'Spettro', 'fantasma': 'Spettro', 'spettro': 'Spettro',
    'dragon': 'Drago', 'drago': 'Drago',
    'dark': 'Buio', 'oscuro': 'Buio', 'oscuri': 'Buio', 'buio': 'Buio',
    'steel': 'Acciaio', 'acciaio': 'Acciaio',
    'fairy': 'Folletto', 'fata': 'Folletto', 'folletto': 'Folletto',
}

TOKEN_RE = re.compile(
    r'\b\d+d\d+\b|\bd\d+\b|[+\-]\s*\d+|\b\d+[sx]\b|'
    r'\b\d+(?:ft|\s*(?:feet|foot|piedi|piede))?\b|'
    r'\b(?:hitpoints?|hit points?|Hit Points?|punti ferita|Punti ferita)\b|'
    r'\b(?:HP|PF|STR|FOR|DEX|DES|CON|COS|WIS|SAG|CHA|CAR|INT|AC|CA|STAB|DC|CD|MOVE|PP|SR|FLINCHED)\b|'
    r'\b(?:flinch|flinches|flinched)\b'
)


def flatten(value) -> str:
    if isinstance(value, list):
        return ' '.join(flatten(item) for item in value)
    if isinstance(value, dict):
        return ' '.join(flatten(item) for item in value.values())
    return '' if value is None else str(value)


def canonical_token(value: str) -> str:
    token = value.upper().replace(' ', '')
    token = re.sub(r'(FT|FEET|FOOT|PIEDI|PIEDE)$', '', token)
    token = re.sub(r'(?<=\d)[SX]$', '', token)
    if token in {'HITPOINT', 'HITPOINTS', 'PUNTIFERITA'}:
        return 'HP'
    aliases = {
        'PF': 'HP', 'FOR': 'STR', 'DES': 'DEX', 'COS': 'CON',
        'SAG': 'WIS', 'CAR': 'CHA', 'CA': 'AC', 'CD': 'DC',
        'FLINCH': 'FLINCHED', 'FLINCHES': 'FLINCHED',
    }
    return aliases.get(token, token)


def token_counts(value: str) -> dict[str, int]:
    counts: dict[str, int] = {}
    for match in TOKEN_RE.finditer(value):
        token = canonical_token(match.group(0))
        counts[token] = counts.get(token, 0) + 1
    return counts


def polish_text(text: str, source: str = '') -> str:
    value = re.sub(r'\s+', ' ', text.replace('\u00a0', ' ')).strip()
    value = re.sub(r'\b(\d+)\s*(?:ft|foot|feet)\b', r'\1 piedi', value, flags=re.IGNORECASE)

    replacements = {
        'Movimento CD': 'CD della mossa',
        'movimento CD': 'CD della mossa',
        'MOVE CD': 'CD della mossa',
        'Move DC': 'CD della mossa',
        'il tuo CD della mossa': 'la tua CD della mossa',
        'contro CD della mossa': 'contro la tua CD della mossa',
        'Potere di Movimento': 'caratteristica della mossa',
        'potere di movimento': 'caratteristica della mossa',
        'movimento del bersaglio fallisce': 'mossa del bersaglio fallisce',
        'usando il suo movimento': 'usando la mossa',
        "nel raggio d'azione": 'a gittata',
        'nel raggio d’azione': 'a gittata',
        'a portata di tiro': 'a gittata',
        'tiro di attacco': 'tiro per colpire',
        'tiro d’attacco': 'tiro per colpire',
        'azione libera': 'azione gratuita',
        'punteggi di abilità': 'punteggi di caratteristica',
        'modifiche alle statistiche': 'modifiche alle caratteristiche',
        'modifica alle statistiche': 'modifica alle caratteristiche',
        'addestratore': 'Allenatore',
        'trainer': 'Allenatore',
        'Trainer': 'Allenatore',
        'Tiro Salvezza': 'tiro salvezza',
        'salvataggi DES': 'tiri salvezza su DES',
        'salvataggio DES': 'tiro salvezza su DES',
        'salvataggio COS': 'tiro salvezza su COS',
        'salvataggio SAG': 'tiro salvezza su SAG',
        'salvataggio FOR': 'tiro salvezza su FOR',
        'salvataggio CAR': 'tiro salvezza su CAR',
        'in caso di colpo': 'se colpisci',
        'In caso di colpo': 'Se colpisci',
        'in caso di fallimento': 'se lo fallisce',
        'In caso di fallimento': 'Se lo fallisce',
        'in caso di successo': 'se lo supera',
        'In caso di successo': 'Se lo supera',
        'effettuare un salvataggio': 'effettuare un tiro salvezza',
        'superare un salvataggio': 'superare un tiro salvezza',
        'viene paralizzato': 'diventa paralizzato',
        'viene paralizzata': 'diventa paralizzata',
        'rimane paralizzato': 'diventa paralizzato',
        'rimane paralizzata': 'diventa paralizzata',
        'viene avvelenato': 'diventa avvelenato',
        'viene avvelenata': 'diventa avvelenata',
        'rimane accecata': 'diventa accecata',
        'rimanere accecata': 'diventare accecata',
        'la metà di questi danni': 'la metà dei danni',
        'la metà di quel danno': 'la metà dei danni',
        'danno completo': 'danni completi',
        'con uno svantaggio': 'con svantaggio',
        'ha uno svantaggio': 'ha svantaggio',
        'hanno uno svantaggio': 'hanno svantaggio',
        'ha un vantaggio': 'ha vantaggio',
        'hanno un vantaggio': 'hanno vantaggio',
        'è impilabile': 'è cumulabile',
        'può essere impilata': 'può essere cumulata',
        'fino ad un massimo': 'fino a un massimo',
        'round 5': '5 round',
        'turni 1d4': '1d4 turni',
        'proiettili 4': '4 proiettili',
        'proiettili 5': '5 proiettili',
        'proiettili 6': '6 proiettili',
        'uno d4': 'un d4',
        'uno 3 o 4': '3 o 4',
    }
    for old, new in replacements.items():
        value = value.replace(old, new)

    for attribute in ('DES', 'COS', 'SAG', 'FOR', 'CAR', 'INT'):
        value = re.sub(
            rf'\b(?:un|una)?\s*{attribute}\s+(?:tiro salvezza|salvataggio)\b',
            f'un tiro salvezza su {attribute}',
            value,
            flags=re.IGNORECASE,
        )
        value = re.sub(
            rf'\btiro salvezza (?:di|del|della) {attribute}\b',
            f'tiro salvezza su {attribute}',
            value,
            flags=re.IGNORECASE,
        )

    type_words = '|'.join(sorted(map(re.escape, DAMAGE_TYPES), key=len, reverse=True))
    value = re.sub(
        rf'\bdann(?:o|i)\s+(?:da|di|del|al|a|di tipo)?\s*({type_words})\b',
        lambda match: f'danni di tipo {DAMAGE_TYPES[match.group(1).lower()]}',
        value,
        flags=re.IGNORECASE,
    )

    value = value.replace('Effettua un tiro per colpire a distanza', 'Effettua un attacco a distanza')
    value = value.replace('Effettua un tiro per colpire in mischia', 'Effettua un attacco in mischia')
    value = value.replace('Effettua un attacco a distanza su ', 'Effettua un attacco a distanza contro ')
    value = value.replace('Effettua un attacco in mischia su ', 'Effettua un attacco in mischia contro ')
    value = value.replace('il tuo CA', 'la tua CA')
    value = value.replace('al tuo CA', 'alla tua CA')
    value = value.replace('bonus CA', 'bonus alla CA')
    value = value.replace('da +1 a CA', '+1 alla CA')
    value = value.replace('tiro di dado per i danni', 'dado di danno')
    value = value.replace('I dadi di danno lanciati', 'I dadi di danno')
    value = value.replace('lancio dei dadi curativi', 'dado di cura')
    value = value.replace('lancio del dado per la guarigione', 'dado di cura')
    value = value.replace('lancio del dado curativo', 'dado di cura')
    value = value.replace('tiro di dado curativo', 'dado di cura')
    value = value.replace('cambia in', 'diventa')
    value = value.replace('cambiano in', 'diventano')

    if re.search(r'\bflinch(?:es|ed)?\b', source, flags=re.IGNORECASE) and 'FLINCHED' not in value:
        for pattern in (
            r'il bersaglio sussulta', r'il bersaglio tentenna',
            r'il bersaglio esita', r'far sussultare il bersaglio',
            r'diventa esitante', r'rimane esitante', r'sussulta',
        ):
            if re.search(pattern, value, flags=re.IGNORECASE):
                value = re.sub(pattern, 'il bersaglio diventa FLINCHED', value, count=1, flags=re.IGNORECASE)
                break
        if 'FLINCHED' not in value:
            value += ' Il bersaglio diventa FLINCHED.'

    value = re.sub(r'\s+([,.;:])', r'\1', value).replace('..', '.')
    return value


def polish_value(value, source_value=None):
    if isinstance(value, str):
        return polish_text(value, source_value if isinstance(source_value, str) else '')
    if isinstance(value, list):
        source_list = source_value if isinstance(source_value, list) else []
        return [
            polish_value(item, source_list[index] if index < len(source_list) else None)
            for index, item in enumerate(value)
        ]
    if isinstance(value, dict):
        source_dict = source_value if isinstance(source_value, dict) else {}
        result = {
            key: polish_value(item, source_dict.get(key))
            for key, item in value.items()
        }
        if 'type' in source_dict:
            result['type'] = source_dict['type']
        return result
    return value


def patch_test(text: str) -> str:
    text = text.replace('coprono le tutte le 830 mosse', 'coprono tutte le 830 mosse')
    text = text.replace('le tutte le 830 mosse usano', 'tutte le 830 mosse usano')
    text = text.replace(
        r'(?:hit points?|Hit Points?|punti ferita|Punti ferita)',
        r'(?:hitpoints?|hit points?|Hit Points?|punti ferita|Punti ferita)',
    )
    return text


def main() -> None:
    source_moves = json.loads(SOURCE_PATH.read_text(encoding='utf-8'))['moves']
    source_by_id = {move['id']: move for move in source_moves}
    special = json.loads(SPECIAL_PATH.read_text(encoding='utf-8'))
    revised_documents = []
    errors = []

    for path in OVERLAY_PATHS:
        document = json.loads(path.read_text(encoding='utf-8'))
        revised = deepcopy(document)
        for move_id, entry in revised['items'].items():
            source = source_by_id[move_id]
            entry['description'] = polish_value(entry['description'], source.get('description', []))
            if move_id in special:
                entry['description'] = deepcopy(special[move_id])
            if entry.get('higherLevels') is not None:
                entry['higherLevels'] = polish_text(entry['higherLevels'], source.get('higherLevels') or '')

            source_text = flatten(source.get('description', [])) + ' ' + (source.get('higherLevels') or '')
            localized_text = flatten(entry['description']) + ' ' + (entry.get('higherLevels') or '')
            source_tokens = token_counts(source_text)
            localized_tokens = token_counts(localized_text)
            if source_tokens != localized_tokens:
                errors.append(
                    f'{move_id}:\n  source={source_tokens}\n  it={localized_tokens}\n'
                    f'  sourceText={source_text}\n  itText={localized_text}'
                )
        revised_documents.append((path, revised))

    if errors:
        DIAGNOSTIC_PATH.write_text(
            'Token meccanici non conservati:\n\n' + '\n\n'.join(errors) + '\n',
            encoding='utf-8',
        )
        raise SystemExit(1)

    for path, document in revised_documents:
        path.write_text(json.dumps(document, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

    test_path = Path('test/move_localization_integrity_test.dart')
    test_path.write_text(patch_test(test_path.read_text(encoding='utf-8')), encoding='utf-8')
    DIAGNOSTIC_PATH.unlink(missing_ok=True)
    Path('docs/translation/move-651-830-test-diagnostic.txt').unlink(missing_ok=True)


if __name__ == '__main__':
    main()
