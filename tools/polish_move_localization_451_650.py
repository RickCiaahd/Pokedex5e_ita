import json
import re
from pathlib import Path

START = 451
END = 650
SOURCE_PATH = Path('assets/data_webapp/moves.json')
OVERLAY_PATHS = [
    Path('assets/data/move_localization_it_451_500.json'),
    Path('assets/data/move_localization_it_501_550.json'),
    Path('assets/data/move_localization_it_551_600.json'),
    Path('assets/data/move_localization_it_601_650.json'),
]

TYPE_NAMES = {
    'normal': 'Normale',
    'fire': 'Fuoco',
    'water': 'Acqua',
    'electric': 'Elettro',
    'grass': 'Erba',
    'ice': 'Ghiaccio',
    'fighting': 'Lotta',
    'poison': 'Veleno',
    'ground': 'Terra',
    'flying': 'Volante',
    'psychic': 'Psico',
    'bug': 'Coleottero',
    'rock': 'Roccia',
    'ghost': 'Spettro',
    'dragon': 'Drago',
    'dark': 'Buio',
    'steel': 'Acciaio',
    'fairy': 'Folletto',
}

DAMAGE_TERMS = {
    'normale': 'Normale',
    'fuoco': 'Fuoco',
    'acqua': 'Acqua',
    'elettrico': 'Elettro',
    'elettrici': 'Elettro',
    'elettriche': 'Elettro',
    'erba': 'Erba',
    'ghiaccio': 'Ghiaccio',
    'lotta': 'Lotta',
    'combattimento': 'Lotta',
    'veleno': 'Veleno',
    'terra': 'Terra',
    'volante': 'Volante',
    'volanti': 'Volante',
    'psichico': 'Psico',
    'psichici': 'Psico',
    'psichica': 'Psico',
    'insetto': 'Coleottero',
    'coleottero': 'Coleottero',
    'roccia': 'Roccia',
    'fantasma': 'Spettro',
    'spettro': 'Spettro',
    'drago': 'Drago',
    'oscuro': 'Buio',
    'oscuri': 'Buio',
    'buio': 'Buio',
    'acciaio': 'Acciaio',
    'fata': 'Folletto',
    'folletto': 'Folletto',
}

MECHANICAL_RE = re.compile(
    r'\b\d+d\d+\b|\bd\d+\b|[+\-]\s*\d+|'
    r'\b\d+(?:ft|\s*(?:feet|foot|piedi|piede))?\b|'
    r'\b(?:HP|PF|STR|FOR|DEX|DES|CON|COS|WIS|SAG|CHA|CAR|INT|AC|CA|STAB|DC|CD|MOVE|PP|SR|FLINCHED|flinch(?:es|ed)?)\b'
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
    aliases = {
        'PF': 'HP', 'FOR': 'STR', 'DES': 'DEX', 'COS': 'CON',
        'SAG': 'WIS', 'CAR': 'CHA', 'CA': 'AC', 'CD': 'DC',
        'FLINCH': 'FLINCHED', 'FLINCHES': 'FLINCHED',
    }
    return aliases.get(token, token)


def token_counts(value: str) -> dict[str, int]:
    result: dict[str, int] = {}
    for match in MECHANICAL_RE.finditer(value):
        token = canonical_token(match.group(0))
        result[token] = result.get(token, 0) + 1
    return result


def translate_higher_levels(source: str | None) -> str | None:
    if source is None:
        return None

    patterns = [
        (
            r'The damage dice rolls? for this move changes? to (.+) at level 5, (.+) at level 10, and (.+) at level 17\.(.*)',
            lambda m: f'Il dado di danno di questa mossa diventa {m.group(1)} al livello 5, {m.group(2)} al livello 10 e {m.group(3)} al livello 17.' + (
                ' Questa modifica non si applica ai danni extra Xd6 quando vengono attivati.'
                if 'does NOT apply' in m.group(4) else ''
            ),
        ),
        (
            r'The damage dice changes to a? ?(.+) at level 5, a? ?(.+) at level 10, and a? ?(.+) at level 17\.',
            lambda m: f'Il dado di danno di questa mossa diventa {m.group(1)} al livello 5, {m.group(2)} al livello 10 e {m.group(3)} al livello 17.',
        ),
        (
            r'The dice used for this move changes to a? ?(.+) at level 5, a? ?(.+) at level 10, and a? ?(.+) at level 17\.',
            lambda m: f'Il dado usato da questa mossa diventa {m.group(1)} al livello 5, {m.group(2)} al livello 10 e {m.group(3)} al livello 17.',
        ),
        (
            r'The (?:healing dice roll for this move|dice roll for healing) changes to (.+) at level 5, (.+) at level 10, and (.+) at level 17\.',
            lambda m: f'Il dado di cura di questa mossa diventa {m.group(1)} al livello 5, {m.group(2)} al livello 10 e {m.group(3)} al livello 17.',
        ),
        (
            r'The dice roll for healing increases to (.+) at level 5, (.+) at level 10, and (.+) at level 17\.',
            lambda m: f'Il dado di cura di questa mossa diventa {m.group(1)} al livello 5, {m.group(2)} al livello 10 e {m.group(3)} al livello 17.',
        ),
        (
            r'The number of hit points affected changes to (.+) at level 5, (.+) at level 10, and (.+) at level 17\.',
            lambda m: f'Il numero di PF influenzati diventa {m.group(1)} al livello 5, {m.group(2)} al livello 10 e {m.group(3)} al livello 17.',
        ),
        (
            r'The dice roll for this move changes to (.+) at level 10\.',
            lambda m: f'Il dado di questa mossa diventa {m.group(1)} al livello 10.',
        ),
        (
            r'Add (\+\d+) to your AC at level 10 and above',
            lambda m: f'Al livello 10 e oltre, aggiungi {m.group(1)} alla tua CA.',
        ),
        (
            r'For damage when raging, the bonus changes to (.+) at level 5, (.+) at level 10, and (.+) at level 17\.',
            lambda m: f'Quando sei in preda all’ira, il bonus ai danni diventa {m.group(1)} al livello 5, {m.group(2)} al livello 10 e {m.group(3)} al livello 17.',
        ),
    ]
    for pattern, builder in patterns:
        match = re.fullmatch(pattern, source)
        if match:
            return builder(match)
    raise RuntimeError(f'higherLevels non gestito: {source}')


def canonical_table(move_id: str):
    if move_id == 'natural-gift':
        return {
            'type': 'table',
            'headers': ['Tipo', 'Bacca', 'Tipo', 'Bacca'],
            'rows': [
                ['Normale', 'Chilan', 'Volante', 'Lum, Coba'],
                ['Fuoco', 'Cherri, Occa', 'Psico', 'Sitrus, Payapa'],
                ['Acqua', 'Chesto, Passho', 'Coleottero', 'Tanga'],
                ['Elettro', 'Pecha, Waccan', 'Roccia', 'Charti'],
                ['Erba', 'Rawst, Rindo', 'Spettro', 'Kasib'],
                ['Ghiaccio', 'Aspear, Yache', 'Drago', 'Haban'],
                ['Lotta', 'Leppa, Chople', 'Buio', 'Colbur'],
                ['Veleno', 'Oran, Kebia', 'Acciaio', 'Babiri, Razz'],
                ['Terra', 'Persim, Shucca', 'Folletto', 'Roseli'],
            ],
        }
    if move_id == 'nature-power':
        return {
            'type': 'table',
            'headers': ['Terreno', 'Mossa'],
            'rows': [
                ['Città, strade ed edifici', 'Comete'],
                ['Zone sabbiose', 'Terremoto'],
                ['Vulcani e zone laviche', 'Fuocobomba'],
                ['Grotte e zone buie', 'Palla Ombra'],
                ['Terreni rocciosi e montagne', 'Frana'],
                ['Campi e pianure', 'Paralizzante'],
                ['Foreste ed erba alta', 'Foglielama'],
                ['Stagni e paludi', 'Bollaraggio'],
                ['In mare', 'Surf'],
                ['Sott’acqua', 'Idropompa'],
                ['Zone innevate', 'Bora'],
            ],
        }
    if move_id == 'order-up':
        return {
            'type': 'table',
            'headers': ['Forma', 'Effetto'],
            'rows': [
                ['Ad Arco (arancione)', 'L’attacco infligge danni extra pari al tuo modificatore di FOR.'],
                ['Adagiata (rosa)', 'Ottieni +3 alla CA fino all’inizio del tuo prossimo turno.'],
                ['Tesa (gialla)', 'Hai vantaggio ai tiri salvezza su DES fino all’inizio del tuo prossimo turno.'],
            ],
        }
    if move_id == 'raging-bull':
        return {
            'type': 'table',
            'headers': ['Razza', 'Tipo di danno'],
            'rows': [
                ['Non specificata', 'Normale'],
                ['Razza Combattiva', 'Lotta'],
                ['Razza Infuocata', 'Fuoco'],
                ['Razza Acquatica', 'Acqua'],
            ],
        }
    if move_id == 'secret-power':
        return {
            'type': 'table',
            'headers': ['d6', 'Effetto'],
            'rows': [
                ['1', 'Avvelenamento'],
                ['2', 'Scottatura'],
                ['3', 'Confusione'],
                ['4', 'Congelamento'],
                ['5', 'Paralisi'],
                ['6', 'Sonno'],
            ],
        }
    return None


def polish_text(text: str, source: str, move_id: str) -> str:
    value = text.replace('\u00a0', ' ').strip()
    value = re.sub(r'\s+', ' ', value)

    value = re.sub(r'\b(\d+)\s*(?:ft|foot|feet)\b', r'\1 piedi', value, flags=re.IGNORECASE)
    value = re.sub(r'\b(?:il|la|un|una|tuo|tua)?\s*Movimento CD\b', 'CD della mossa', value, flags=re.IGNORECASE)
    value = value.replace('Move DC', 'CD della mossa')
    value = value.replace('potere di movimento', 'caratteristica della mossa')
    value = value.replace('potere della mossa', 'caratteristica della mossa')

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

    replacements = {
        'danni senza tipo': 'danni senza tipo',
        'danno senza tipo': 'danni senza tipo',
        'in caso di colpo': 'se colpisci',
        'al colpo': 'se colpisci',
        'su un colpo': 'se colpisci',
        'subisce uno svantaggio': 'ha svantaggio',
        'subiscono uno svantaggio': 'hanno svantaggio',
        'hanno un vantaggio': 'hanno vantaggio',
        'ha un vantaggio': 'ha vantaggio',
        'a portata': 'a gittata',
        'nel raggio d’azione': 'a gittata',
        "nel raggio d'azione": 'a gittata',
        'lancia il suo attacco successivo': 'effettua il suo prossimo attacco',
        'lancia un attacco': 'effettua un attacco',
        'effettuare un salvataggio': 'effettuare un tiro salvezza',
        'superare un salvataggio': 'superare un tiro salvezza',
        'in caso di tiro salvezza fallito': 'se fallisce il tiro salvezza',
        'in caso di successo': 'se lo supera',
        'in caso di fallimento': 'se lo fallisce',
        'viene gravemente avvelenata': 'diventa gravemente avvelenata',
        'viene avvelenata': 'diventa avvelenata',
        'diventano avvelenati': 'diventano avvelenate',
        'danno completo': 'danni completi',
        'danni regolari': 'danni normali',
        'punteggi delle abilità': 'punteggi di caratteristica',
        'punteggi di abilità': 'punteggi di caratteristica',
        'abilità punteggi': 'punteggi di caratteristica',
        'azione libera': 'azione gratuita',
        'attacco di opportunità': 'attacco di opportunità',
        'trainer': 'Allenatore',
        'Trainer': 'Allenatore',
    }
    for old, new in replacements.items():
        value = value.replace(old, new)

    damage_words = '|'.join(sorted(map(re.escape, DAMAGE_TERMS), key=len, reverse=True))
    value = re.sub(
        rf'\bdann(?:o|i)\s+(?:da|di tipo)?\s*({damage_words})\b',
        lambda m: f'danni di tipo {DAMAGE_TERMS[m.group(1).lower()]}',
        value,
        flags=re.IGNORECASE,
    )
    value = re.sub(r'\bdanni? psichici\b', 'danni di tipo Psico', value, flags=re.IGNORECASE)
    value = re.sub(r'\bdanni? elettrici\b', 'danni di tipo Elettro', value, flags=re.IGNORECASE)
    value = re.sub(r'\bdanni? volanti\b', 'danni di tipo Volante', value, flags=re.IGNORECASE)
    value = re.sub(r'\bdanni? oscuri\b', 'danni di tipo Buio', value, flags=re.IGNORECASE)
    value = re.sub(r'\bdanni? normali\b', 'danni di tipo Normale', value, flags=re.IGNORECASE)

    value = value.replace('Effettua un tiro di attacco a distanza', 'Effettua un attacco a distanza')
    value = value.replace('Effettua un tiro per colpire a distanza', 'Effettua un attacco a distanza')
    value = value.replace('Effettua un tiro per colpire in mischia', 'Effettua un attacco in mischia')
    value = value.replace('Effettua un tiro di attacco in mischia', 'Effettua un attacco in mischia')
    value = value.replace('Effettua un attacco in mischia su ', 'Effettua un attacco in mischia contro ')
    value = value.replace('Effettua un attacco a distanza su ', 'Effettua un attacco a distanza contro ')

    if move_id == 'plasma-fists':
        value = value.replace('i tuoi primi', 'i tuoi pugni')
    if move_id == 'pound':
        value = value.replace('con un attacco con libbra', 'con un colpo poderoso')
    if move_id == 'play-rough':
        value = value.replace('Si finge una creatura con un attacco giocoso che diventa rapidamente troppo duro.', 'Attacchi una creatura fingendo di giocare, ma il colpo diventa rapidamente molto violento.')
    if move_id == 'poison-fang':
        value = value.replace('con veleno velenoso', 'con zanne intrise di veleno')
    if move_id == 'misty-explosion':
        value = value.replace('svenendo immediatamente', 'andando immediatamente KO')
    if move_id == 'moonlight':
        value = value.replace('crogiolandoti nella luce curativa', 'avvolgendoti in una luce curativa')
    if move_id == 'morning-sun':
        value = value.replace('crogiolandoti in una luce curativa', 'avvolgendoti in una luce curativa')

    source_has_flinch = re.search(r'\bflinch(?:es|ed)?\b', source, flags=re.IGNORECASE)
    if source_has_flinch and 'FLINCHED' not in value:
        patterns = [
            r'il bersaglio sussulta',
            r'il bersaglio tentenna',
            r'far sussultare il bersaglio',
            r'o sussultare',
            r'diventa esitante',
        ]
        for pattern in patterns:
            if re.search(pattern, value, flags=re.IGNORECASE):
                value = re.sub(pattern, 'il bersaglio diventa FLINCHED', value, count=1, flags=re.IGNORECASE)
                break
        if 'FLINCHED' not in value:
            value += ' Il bersaglio diventa FLINCHED.'

    value = re.sub(r'\s+([,.;:])', r'\1', value)
    value = value.replace('..', '.')
    return value


def build_fixture(items: list[tuple[str, dict]]) -> str:
    lines = ['const moveNames451To650 = <String, String>{']
    for move_id, entry in items:
        name = entry['name'].replace('\\', '\\\\').replace("'", "\\'")
        lines.append(f"  '{move_id}': '{name}',")
    lines.append('};')
    return '\n'.join(lines) + '\n'


def update_repository() -> None:
    path = Path('lib/repositories/move_localization_repository.dart')
    text = path.read_text(encoding='utf-8')
    anchor = "    'assets/data/move_localization_it_411_450.json',\n"
    additions = (
        "    'assets/data/move_localization_it_451_500.json',\n"
        "    'assets/data/move_localization_it_501_550.json',\n"
        "    'assets/data/move_localization_it_551_600.json',\n"
        "    'assets/data/move_localization_it_601_650.json',\n"
    )
    if additions not in text:
        text = text.replace(anchor, anchor + additions)
    text = text.replace('static const int localizedCount = 450;', 'static const int localizedCount = 650;')
    path.write_text(text, encoding='utf-8')


def update_tests() -> None:
    path = Path('test/move_localization_integrity_test.dart')
    text = path.read_text(encoding='utf-8')
    import_line = "import 'fixtures/move_names_it_451_650.dart';\n"
    if import_line not in text:
        text = text.replace(
            "import 'fixtures/move_names_it_251_450.dart';\n",
            "import 'fixtures/move_names_it_251_450.dart';\n" + import_line,
        )
    text = text.replace('prime 450 mosse', 'prime 650 mosse')
    text = text.replace(
        '      ...moveNames251To450,\n',
        '      ...moveNames251To450,\n      ...moveNames451To650,\n',
    )
    text = text.replace(
        "    expect(names['mist'], 'Nebbia');\n",
        "    expect(names['mist'], 'Nebbia');\n"
        "    expect(names['mist-ball'], 'Foschisfera');\n"
        "    expect(names['natures-madness'], 'Ira della Natura');\n"
        "    expect(names['raging-bull'], 'Scatenatoro');\n"
        "    expect(names['sludge-bomb'], 'Fangobomba');\n",
    )
    text = text.replace(
        "    final unlocalized = await repository.getMove('zing-zap');",
        "    final mistBallByItalianName = await repository.getMove('Foschisfera');\n"
        "    final sludgeBombByEnglishName = await repository.getMove('Sludge Bomb');\n"
        "    final unlocalized = await repository.getMove('sludge-wave');",
    )
    text = text.replace(
        "    expect(acupressure?.name, 'Acupressione');",
        "    expect(mistBallByItalianName?.id, 'mist-ball');\n"
        "    expect(mistBallByItalianName?.technicalName, 'Mist Ball');\n"
        "    expect(sludgeBombByEnglishName?.name, 'Fangobomba');\n"
        "    expect(sludgeBombByEnglishName?.technicalName, 'Sludge Bomb');\n\n"
        "    expect(acupressure?.name, 'Acupressione');",
    )
    text = text.replace("expect(unlocalized?.name, 'Zing Zap');", "expect(unlocalized?.name, 'Sludge Wave');")
    text = text.replace("expect(unlocalized?.technicalName, 'Zing Zap');", "expect(unlocalized?.technicalName, 'Sludge Wave');")
    path.write_text(text, encoding='utf-8')


def write_audit() -> None:
    Path('docs/translation/move-451-650-it-audit.md').write_text(
        '''# Audit della localizzazione italiana delle mosse 451-650

## Ambito

Questo blocco localizza le mosse dalla posizione **451** alla **650** del catalogo unificato restituito da `MoveRepository.getAllMoves()`, da `Mist Ball` a `Sludge Bomb`.

Sono state aggiunte **200 localizzazioni**, suddivise in quattro overlay da 50 elementi.

## Nomi italiani

I 200 nomi visualizzati sono stati verificati tramite il riferimento italiano delle mosse di Pokémon Central e confrontati con i dati italiani di PokéAPI. Tutte le voci del blocco hanno un equivalente ufficiale italiano.

| Nome tecnico | Nome visualizzato |
| --- | --- |
| Mist Ball | Foschisfera |
| Misty Terrain | Campo Nebbioso |
| Nature’s Madness | Ira della Natura |
| Photon Geyser | Geyser Fotonico |
| Psychic Noise | Psicorumore |
| Raging Bull | Scatenatoro |
| Revival Blessing | Preghiera Vitale |
| Sludge Bomb | Fangobomba |

## Descrizioni 5e

Per ogni mossa sono stati conservati numero e ordine dei blocchi, presenza di `higherLevels`, dadi, numeri, formule, distanze, livelli, durate e riferimenti tecnici. Le tabelle di Dononaturale, Naturforza, Alta Cucina, Scatenatoro e Forzasegreta sono state ricostruite con intestazioni e valori italiani controllati.

ID, slug, nome tecnico inglese, tipo, PP, potenza, TM, tiri salvezza, attacchi e dati di danno restano nei file sorgente originali.

## Compatibilità

Il nome inglese continua a essere usato nei salvataggi, nei learnset, nei trasferimenti e nei Fakemon. Il repository risolve ogni mossa tramite ID, nome tecnico inglese o nome italiano visualizzato.

## Controlli

I test automatici verificano la copertura esatta delle prime 650 mosse, l’assenza di duplicati, la corrispondenza dei nomi tecnici, il numero dei blocchi descrittivi e la conservazione dei token meccanici.
''',
        encoding='utf-8',
    )


def update_changelog() -> None:
    path = Path('CHANGELOG.md')
    text = path.read_text(encoding='utf-8')
    text = text.replace(
        'localizzate con nomi italiani verificati e descrizioni 5e tradotte le prime 450 delle 830 mosse del catalogo, da Assorbimento a Nebbia, conservando riferimenti inglesi e valori meccanici;',
        'localizzate con nomi italiani verificati e descrizioni 5e tradotte le prime 650 delle 830 mosse del catalogo, da Assorbimento a Fangobomba, conservando riferimenti inglesi e valori meccanici;',
    )
    path.write_text(text, encoding='utf-8')


def main() -> None:
    source_moves = json.loads(SOURCE_PATH.read_text(encoding='utf-8'))['moves']
    source_by_id = {move['id']: move for move in source_moves}
    ordered_items: list[tuple[str, dict]] = []
    errors: list[str] = []

    for path in OVERLAY_PATHS:
        document = json.loads(path.read_text(encoding='utf-8'))
        for move_id, entry in document['items'].items():
            source = source_by_id[move_id]
            polished_description = []
            source_blocks = source.get('description', [])
            for block_index, localized_block in enumerate(entry.get('description', [])):
                source_block = source_blocks[block_index]
                if isinstance(source_block, dict):
                    table = canonical_table(move_id)
                    if table is None:
                        raise RuntimeError(f'Tabella non gestita: {move_id}')
                    polished_description.append(table)
                else:
                    polished_description.append(polish_text(str(localized_block), str(source_block), move_id))
            entry['description'] = polished_description
            entry['higherLevels'] = translate_higher_levels(source.get('higherLevels'))

            source_text = flatten(source.get('description', [])) + ' ' + (source.get('higherLevels') or '')
            localized_text = flatten(entry['description']) + ' ' + (entry.get('higherLevels') or '')
            if token_counts(source_text) != token_counts(localized_text):
                errors.append(
                    f'{move_id}: {token_counts(source_text)} != {token_counts(localized_text)}'
                )
            ordered_items.append((move_id, entry))

        path.write_text(json.dumps(document, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

    if errors:
        raise RuntimeError('Token meccanici non conservati:\n' + '\n'.join(errors))
    if len(ordered_items) != 200:
        raise RuntimeError(f'Attese 200 mosse, trovate {len(ordered_items)}')

    Path('test/fixtures/move_names_it_451_650.dart').write_text(
        build_fixture(ordered_items), encoding='utf-8'
    )
    update_repository()
    update_tests()
    write_audit()
    update_changelog()


if __name__ == '__main__':
    main()
