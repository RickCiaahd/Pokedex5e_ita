import csv
import io
import json
import re
import time
import urllib.request
from pathlib import Path

from deep_translator import GoogleTranslator

START = 451
END = 650
SOURCE_PATH = Path('assets/data_webapp/moves.json')
OUTPUT_DIR = Path('assets/data')
NAME_SOURCES = [
    'https://wiki.pokemoncentral.it/Elenco_delle_mosse_in_altre_lingue',
    'https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv/move_names.csv',
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

TABLE_TERMS = {
    'Type': 'Tipo',
    'Berry': 'Bacca',
    'Terrain': 'Terreno',
    'Move': 'Mossa',
    'Effect': 'Effetto',
    'Result': 'Risultato',
    'Cities, Roads, Buildings': 'Città, strade ed edifici',
    'Sandy areas': 'Zone sabbiose',
    'Volcanos, Lava areas': 'Vulcani e zone laviche',
    'Caves, Dark areas': 'Grotte e zone buie',
    'Rocky terrain, Mountains': 'Terreni rocciosi e montagne',
    'Fields, Plains': 'Campi e pianure',
    'Forests, Tall grasslands': 'Foreste ed erba alta',
    'Ponds, Swamps': 'Stagni e paludi',
    'At sea': 'In mare',
    'Underwater': 'Sott’acqua',
    'Snowy': 'Zone innevate',
    'Swift': 'Comete',
    'Earthquake': 'Terremoto',
    'Fire Blast': 'Fuocobomba',
    'Shadow Ball': 'Palla Ombra',
    'Rock Slide': 'Frana',
    'Stun Spore': 'Paralizzante',
    'Razor Leaf': 'Foglielama',
    'Bubble Beam': 'Bollaraggio',
    'Surf': 'Surf',
    'Hydro Pump': 'Idropompa',
    'Blizzard': 'Bora',
}

TOKEN_RE = re.compile(
    r'\b\d+d\d+\b|\bd\d+\b|[+\-]\s*\d+|\b\d+(?:\.\d+)?%\b|'
    r'\b\d+(?:ft|\s*(?:feet|foot))\b|\b\d+(?:\.\d+)?\b|'
    r'\b(?:MOVE|STAB|PP|SR|FLINCHED|STR|DEX|CON|WIS|CHA|INT|AC|DC|HP)\b'
)


def download_text(url: str) -> str:
    with urllib.request.urlopen(url, timeout=60) as response:
        return response.read().decode('utf-8-sig')


def official_move_names() -> dict[str, str]:
    moves_rows = csv.DictReader(io.StringIO(download_text(
        'https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv/moves.csv'
    )))
    id_by_identifier = {
        row['identifier']: row['id']
        for row in moves_rows
        if row.get('identifier') and row.get('id')
    }

    italian_by_move_id: dict[str, str] = {}
    name_rows = csv.DictReader(io.StringIO(download_text(
        'https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv/move_names.csv'
    )))
    for row in name_rows:
        if row.get('local_language_id') == '8':
            italian_by_move_id[row['move_id']] = row['name']

    return {
        identifier: italian_by_move_id[move_id]
        for identifier, move_id in id_by_identifier.items()
        if move_id in italian_by_move_id
    }


def protect_tokens(text: str) -> tuple[str, dict[str, str]]:
    replacements: dict[str, str] = {}

    def replace(match: re.Match[str]) -> str:
        placeholder = f'[[MECCANICA_{len(replacements):03d}]]'
        replacements[placeholder] = match.group(0)
        return placeholder

    return TOKEN_RE.sub(replace, text), replacements


def restore_tokens(text: str, replacements: dict[str, str]) -> str:
    result = text
    for placeholder, token in replacements.items():
        candidates = {
            placeholder,
            placeholder.replace('_', ' _ '),
            placeholder.replace('_', ' '),
        }
        for candidate in candidates:
            result = result.replace(candidate, token)
    return result


def normalize_translation(text: str) -> str:
    value = text.replace('\u00a0', ' ').strip()
    value = re.sub(r'\s+', ' ', value)
    value = value.replace('CD Sposta', 'CD della mossa')
    value = value.replace('Sposta CD', 'CD della mossa')
    value = value.replace('CD Movimento', 'CD della mossa')
    value = value.replace('Movimento CD', 'CD della mossa')
    value = value.replace('CD mossa', 'CD della mossa')
    value = value.replace('la tua mossa CD', 'la tua CD della mossa')
    value = value.replace('il tuo Move DC', 'la tua CD della mossa')
    value = value.replace('Move DC', 'CD della mossa')
    value = value.replace('Classe Armatura', 'CA')
    value = value.replace('Punti Ferita', 'punti ferita')
    value = value.replace('punti ferita', 'PF')
    value = value.replace('tiro salvezza DEX', 'tiro salvezza su DES')
    value = value.replace('tiro salvezza CON', 'tiro salvezza su COS')
    value = value.replace('tiro salvezza WIS', 'tiro salvezza su SAG')
    value = value.replace('tiro salvezza STR', 'tiro salvezza su FOR')
    value = value.replace('tiro salvezza CHA', 'tiro salvezza su CAR')
    for source, target in ATTRIBUTE_ALIASES.items():
        value = re.sub(rf'\b{source}\b', target, value)
    for source, target in TYPE_NAMES.items():
        value = re.sub(rf'\b{source}\b', target, value, flags=re.IGNORECASE)
    value = value.replace('tipo tipo', 'tipo')
    value = value.replace('mossa mossa', 'mossa')
    return value


class Translator:
    def __init__(self) -> None:
        self._translator = GoogleTranslator(source='en', target='it')
        self._cache: dict[str, str] = {}

    def translate(self, text: str) -> str:
        if text in TABLE_TERMS:
            return TABLE_TERMS[text]
        cached = self._cache.get(text)
        if cached is not None:
            return cached

        protected, replacements = protect_tokens(text)
        last_error: Exception | None = None
        for attempt in range(6):
            try:
                translated = self._translator.translate(protected)
                if not translated:
                    raise RuntimeError('Traduzione vuota')
                restored = restore_tokens(translated, replacements)
                if '[[MECCANICA_' in restored:
                    raise RuntimeError(f'Placeholder non ripristinato: {restored}')
                result = normalize_translation(restored)
                self._cache[text] = result
                time.sleep(0.08)
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
        result = dict(value)
        if value.get('type') == 'table':
            result['headers'] = [
                TABLE_TERMS.get(str(item), translator.translate(str(item)))
                for item in value.get('headers', [])
            ]
            result['rows'] = [
                [TABLE_TERMS.get(str(cell), translator.translate(str(cell))) for cell in row]
                for row in value.get('rows', [])
            ]
            return result
        return {key: translate_value(item, translator) for key, item in value.items()}
    return value


def main() -> None:
    source = json.loads(SOURCE_PATH.read_text(encoding='utf-8'))
    moves = source['moves'][START - 1:END]
    if len(moves) != END - START + 1:
        raise RuntimeError(f'Attese {END - START + 1} mosse, trovate {len(moves)}')

    names = official_move_names()
    missing_names = [move['id'] for move in moves if move['id'] not in names]
    if missing_names:
        raise RuntimeError(f'Nomi italiani mancanti: {missing_names}')

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


if __name__ == '__main__':
    main()
