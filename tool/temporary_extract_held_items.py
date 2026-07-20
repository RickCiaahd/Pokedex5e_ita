import csv
import io
import json
import urllib.request
from pathlib import Path

SOURCE = Path('assets/data_webapp/items.json')
OUTPUT = Path('held-items-audit.json')
POKEAPI_ITEMS = 'https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv/items.csv'
POKEAPI_NAMES = 'https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv/item_names.csv'
ITALIAN_LANGUAGE_ID = '8'

source = json.loads(SOURCE.read_text(encoding='utf-8'))
held_items = [item for item in source['items'] if item.get('type') == 'held item']

with urllib.request.urlopen(POKEAPI_ITEMS) as response:
    item_rows = list(csv.DictReader(io.StringIO(response.read().decode('utf-8'))))
with urllib.request.urlopen(POKEAPI_NAMES) as response:
    name_rows = list(csv.DictReader(io.StringIO(response.read().decode('utf-8'))))

identifier_to_id = {row['identifier']: row['id'] for row in item_rows}
italian_by_id = {
    row['item_id']: row['name']
    for row in name_rows
    if row['local_language_id'] == ITALIAN_LANGUAGE_ID
}

rows = []
for item in held_items:
    item_id = item['id']
    pokeapi_id = identifier_to_id.get(item_id)
    rows.append({
        'id': item_id,
        'sourceName': item.get('name'),
        'cost': item.get('cost'),
        'description': item.get('description'),
        'ingameEffect': item.get('_ingameEffect'),
        'sprite': (item.get('media') or {}).get('sprite'),
        'pokeapiItemId': pokeapi_id,
        'pokeapiItalianName': italian_by_id.get(pokeapi_id) if pokeapi_id else None,
    })

OUTPUT.write_text(
    json.dumps(
        {
            'count': len(rows),
            'resolvedByPokeAPI': sum(1 for row in rows if row['pokeapiItalianName']),
            'unresolvedIds': [row['id'] for row in rows if not row['pokeapiItalianName']],
            'items': rows,
        },
        ensure_ascii=False,
        indent=2,
    ) + '\n',
    encoding='utf-8',
)
