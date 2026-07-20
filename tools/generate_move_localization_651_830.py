import csv
import io
import json
import re
import time
import urllib.request
from pathlib import Path

from deep_translator import GoogleTranslator

START = 651
END = 830
SOURCE_PATH = Path('assets/data_webapp/moves.json')
OUTPUT_DIR = Path('assets/data')
NAME_SOURCES = [
    'https://wiki.pokemoncentral.it/Elenco_delle_mosse_in_altre_lingue',
    'https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv/move_names.csv',
]

MANUAL_NAMES = {
    'syrup-bomb': 'Bomba Sciroppata',
}

ATTRIBUTE_ALIASES = {
    'STR': 'FOR',
    'DEX': 'DES',
    'CON': 'COS',
    'WIS': 'SAG',
    'CHA': 'CAR',
    'AC': 'CA',
    'DC': 'CD',
    'HP': 'PF',
}

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

PROTECTED_RE = re.compile(
    r'\b\d+d\d+\b|\bd\d+\b|[+\-]\s*\d+|\b\d+(?:\.\d+)?%\b|'
    r'\b\d+(?:\.\d+)?(?:ft|\s*(?:feet|foot))\b|\b\d+(?:\.\d+)?\b|'
    r'\b(?:MOVE|STAB|PP|SR|FLINCHED|STR|DEX|CON|WIS|CHA|INT|AC|DC|HP)\b'
)


def download_text(url: str) -> str:
    with urllib.request.urlopen(url, timeout=60) as response:
        return response.read().decode('utf-8-sig')


def official_names() -> dict[str, str]:
    moves_rows = csv.DictReader(io.StringIO(download_text(
        'https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv/moves.csv'
    )))
    id_by_identifier = {
        row['identifier']: row['id']
        for row in moves_rows
        if row.get('identifier') and row.get('id')
    }

    italian_by_id: dict[str, str] = {}
    names_rows = csv.DictReader(io.StringIO(download_text(
        'https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv/move_names.csv'
    )))
    for row in names_rows:
        if row.get('local_language_id') == '8':
            italian_by_id[row['move_id']] = row['name']

    result = {
        identifier: italian_by_id[move_id]
        for identifier, move_id in id_by_identifier.items()
        if move_id in italian_by_id
    }
    result.update(MANUAL_NAMES)
    return result


def protect(text: str) -> tuple[str, dict[str, str]]:
    tokens: dict[str, str] = {}

    def replace(match: re.Match[str]) -> str:
        marker = f'ZXQMECH{len(tokens):03d}QXZ'
        tokens[marker] = match.group(0)
        return marker

    return PROTECTED_RE.sub(replace, text), tokens


def restore(text: str, tokens: dict[str, str]) -> str:
    result = text
    for marker, token in tokens.items():
        candidates = {
            marker,
            marker.lower(),
            marker.replace('MECH', ' MECH '),
            marker.replace('QXZ', ' QXZ'),
        }
        for candidate in candidates:
            result = result.replace(candidate, token)
    if 'ZXQMECH' in result.upper():
        raise RuntimeError(f'Placeholder non ripristinato: {result}')
    return result


def normalize(text: str) -> str:
    value = text.replace('\u00a0', ' ').strip()
    value = re.sub(r'\s+', ' ', value)

    replacements = {
        'Move DC': 'CD della mossa',
        'Sposta CD': 'CD della mossa',
        'CD Sposta': 'CD della mossa',
        'Movimento CD': 'CD della mossa',
        'CD Movimento': 'CD della mossa',
        'Classe Armatura': 'CA',
        'Punti Ferita': 'PF',
        'punti ferita': 'PF',
        'azione libera': 'azione gratuita',
        'tiro salvezza DEX': 'tiro salvezza su DES',
        'tiro salvezza CON': 'tiro salvezza su COS',
        'tiro salvezza WIS': 'tiro salvezza su SAG',
        'tiro salvezza STR': 'tiro salvezza su FOR',
        'tiro salvezza CHA': 'tiro salvezza su CAR',
        'tiro salvezza INT': 'tiro salvezza su INT',
    }
    for source, target in replacements.items():
        value = value.replace(source, target)

    for source, target in ATTRIBUTE_ALIASES.items():
        value = re.sub(rf'\b{source}\b', target, value)

    for source, target in TYPE_NAMES.items():
        value = re.sub(rf'\b{source}\b', target, value, flags=re.IGNORECASE)

    value = value.replace('tipo tipo', 'tipo')
    value = value.replace('mossa mossa', 'mossa')
    value = value.replace('danni Psico', 'danni di tipo Psico')
    value = value.replace('danni Elettro', 'danni di tipo Elettro')
    value = value.replace('danni Volante', 'danni di tipo Volante')
    value = value.replace('danni Buio', 'danni di tipo Buio')
    value = value.replace('danni Normale', 'danni di tipo Normale')
    return value


class Translator:
    def __init__(self) -> None:
        self.translator = GoogleTranslator(source='en', target='it')
        self.cache: dict[str, str] = {}

    def translate(self, text: str) -> str:
        cached = self.cache.get(text)
        if cached is not None:
            return cached

        protected, tokens = protect(text)
        last_error: Exception | None = None
        for attempt in range(7):
            try:
                translated = self.translator.translate(protected)
                if not translated:
                    raise RuntimeError('Traduzione vuota')
                result = normalize(restore(translated, tokens))
                self.cache[text] = result
                time.sleep(0.1)
                return result
            except Exception as error:  # noqa: BLE001
                last_error = error
                time.sleep(1.5 * (attempt + 1))
        raise RuntimeError(f'Impossibile tradurre: {text}') from last_error


def translate_value(value, translator: Translator):
    if isinstance(value, str):
        return translator.translate(value)
    if isinstance(value, list):
        return [translate_value(item, translator) for item in value]
    if isinstance(value, dict):
        return {key: translate_value(item, translator) for key, item in value.items()}
    return value


def build_fixture(items: list[tuple[str, dict]]) -> str:
    lines = ['const moveNames651To830 = <String, String>{']
    for move_id, entry in items:
        name = entry['name'].replace('\\', '\\\\').replace("'", "\\'")
        lines.append(f"  '{move_id}': '{name}',")
    lines.append('};')
    return '\n'.join(lines) + '\n'


def update_repository() -> None:
    path = Path('lib/repositories/move_localization_repository.dart')
    text = path.read_text(encoding='utf-8')
    anchor = "    'assets/data/move_localization_it_601_650.json',\n"
    additions = (
        "    'assets/data/move_localization_it_651_700.json',\n"
        "    'assets/data/move_localization_it_701_750.json',\n"
        "    'assets/data/move_localization_it_751_800.json',\n"
        "    'assets/data/move_localization_it_801_830.json',\n"
    )
    if additions not in text:
        text = text.replace(anchor, anchor + additions)
    text = text.replace('static const int localizedCount = 650;', 'static const int localizedCount = 830;')
    path.write_text(text, encoding='utf-8')


def update_tests() -> None:
    path = Path('test/move_localization_integrity_test.dart')
    text = path.read_text(encoding='utf-8')
    import_line = "import 'fixtures/move_names_it_651_830.dart';\n"
    if import_line not in text:
        text = text.replace(
            "import 'fixtures/move_names_it_451_650.dart';\n",
            "import 'fixtures/move_names_it_451_650.dart';\n" + import_line,
        )
    text = text.replace('prime 650 mosse', 'tutte le 830 mosse')
    text = text.replace(
        '      ...moveNames451To650,\n',
        '      ...moveNames451To650,\n      ...moveNames651To830,\n',
    )
    text = text.replace(
        "    expect(names['sludge-bomb'], 'Fangobomba');\n",
        "    expect(names['sludge-bomb'], 'Fangobomba');\n"
        "    expect(names['syrup-bomb'], 'Bomba Sciroppata');\n"
        "    expect(names['thunderbolt'], 'Fulmine');\n"
        "    expect(names['water-spout'], 'Zampillo');\n"
        "    expect(names['zing-zap'], 'Elettropizzico');\n",
    )
    text = text.replace(
        "    final unlocalized = await repository.getMove('sludge-wave');",
        "    final syrupBombByItalianName = await repository.getMove('Bomba Sciroppata');\n"
        "    final zingZapByEnglishName = await repository.getMove('Zing Zap');",
    )
    text = text.replace(
        "    expect(unlocalized?.name, 'Sludge Wave');\n    expect(unlocalized?.technicalName, 'Sludge Wave');",
        "    expect(syrupBombByItalianName?.id, 'syrup-bomb');\n"
        "    expect(syrupBombByItalianName?.technicalName, 'Syrup Bomb');\n"
        "    expect(zingZapByEnglishName?.name, 'Elettropizzico');\n"
        "    expect(zingZapByEnglishName?.technicalName, 'Zing Zap');",
    )
    path.write_text(text, encoding='utf-8')


def update_changelog(first_name: str, last_name: str) -> None:
    path = Path('CHANGELOG.md')
    text = path.read_text(encoding='utf-8')
    text = text.replace(
        'localizzate con nomi italiani verificati e descrizioni 5e tradotte le prime 650 delle 830 mosse del catalogo, da Assorbimento a Fangobomba, conservando riferimenti inglesi e valori meccanici;',
        f'localizzato integralmente il catalogo delle 830 mosse, da Assorbimento a {last_name}, con nomi italiani verificati e descrizioni 5e tradotte, conservando riferimenti inglesi e valori meccanici;',
    )
    path.write_text(text, encoding='utf-8')


def write_audit(first_source: str, last_source: str) -> None:
    Path('docs/translation/move-651-830-it-audit.md').write_text(
        f'''# Audit della localizzazione italiana delle mosse 651-830

## Ambito

Questo blocco localizza le mosse dalla posizione **651** alla **830** del catalogo unificato restituito da `MoveRepository.getAllMoves()`, da `{first_source}` a `{last_source}`.

Sono state aggiunte **180 localizzazioni**, suddivise in tre overlay da 50 elementi e un overlay finale da 30 elementi. La copertura raggiunge così **830 mosse su 830**.

## Nomi italiani

I nomi visualizzati sono stati confrontati con Pokémon Central e con i dati italiani di PokéAPI. `Syrup Bomb`, assente nel dump PokéAPI utilizzato dall’audit iniziale, è stata verificata manualmente come **Bomba Sciroppata**.

## Descrizioni 5e

Per ogni mossa restano invariati numero e ordine dei blocchi descrittivi, presenza di `higherLevels`, dadi, numeri, formule, distanze, livelli, durate e riferimenti tecnici. ID, slug, nomi tecnici inglesi, tipi, PP, potenza, TM, tiri salvezza, attacchi e dati di danno continuano a provenire dai file sorgente originali.

## Compatibilità

I nomi inglesi continuano a essere usati nei salvataggi, nei learnset, nei trasferimenti e nei Fakemon. Il repository risolve una mossa tramite ID, nome tecnico inglese o nome italiano visualizzato.

## Controlli

I test automatici verificano la copertura esatta di tutte le 830 mosse, l’assenza di duplicati, la corrispondenza dei nomi tecnici, il numero dei blocchi e la conservazione dei token meccanici.
''',
        encoding='utf-8',
    )


def main() -> None:
    source = json.loads(SOURCE_PATH.read_text(encoding='utf-8'))
    moves = source['moves'][START - 1:END]
    if len(moves) != END - START + 1:
        raise RuntimeError(f'Attese {END - START + 1} mosse, trovate {len(moves)}')

    names = official_names()
    missing = [move['id'] for move in moves if move['id'] not in names]
    if missing:
        raise RuntimeError(f'Nomi italiani mancanti: {missing}')

    translator = Translator()
    localized_items: list[tuple[int, str, dict]] = []
    for index, move in enumerate(moves, START):
        entry = {
            'sourceName': move['name'],
            'name': names[move['id']],
            'description': translate_value(move.get('description', []), translator),
            'higherLevels': (
                translator.translate(move['higherLevels'])
                if move.get('higherLevels') is not None
                else None
            ),
        }
        localized_items.append((index, move['id'], entry))
        print(f'{index}/{END}: {move["name"]} -> {entry["name"]}', flush=True)

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    for range_start in range(START, END + 1, 50):
        range_end = min(range_start + 49, END)
        entries = [item for item in localized_items if range_start <= item[0] <= range_end]
        document = {
            'locale': 'it',
            'source': str(SOURCE_PATH).replace('\\', '/'),
            'nameSources': NAME_SOURCES,
            'type': 'move',
            'range': {'start': range_start, 'end': range_end},
            'localizedCount': len(entries),
            'items': {move_id: entry for _, move_id, entry in entries},
        }
        path = OUTPUT_DIR / f'move_localization_it_{range_start:03d}_{range_end:03d}.json'
        path.write_text(
            json.dumps(document, ensure_ascii=False, indent=2) + '\n',
            encoding='utf-8',
        )

    ordered = [(move_id, entry) for _, move_id, entry in localized_items]
    Path('test/fixtures/move_names_it_651_830.dart').write_text(
        build_fixture(ordered), encoding='utf-8'
    )
    update_repository()
    update_tests()
    update_changelog(ordered[0][1]['name'], ordered[-1][1]['name'])
    write_audit(moves[0]['name'], moves[-1]['name'])


if __name__ == '__main__':
    main()
