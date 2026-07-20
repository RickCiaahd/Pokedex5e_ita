import json
import re
import urllib.request
from pathlib import Path

from bs4 import BeautifulSoup

source = json.loads(Path('assets/data_webapp/items.json').read_text(encoding='utf-8'))
held = [item for item in source['items'] if item.get('type') == 'held item']
request = urllib.request.Request(
    'https://wiki.pokemoncentral.it/Elenco_degli_strumenti_in_altre_lingue',
    headers={'User-Agent': 'Mozilla/5.0'},
)
html = urllib.request.urlopen(request, timeout=60).read()
soup = BeautifulSoup(html, 'html.parser')
lookup = {}
samples = []
for row in soup.select('table tr'):
    cells = row.find_all(['th', 'td'])
    values = [re.sub(r'\s+', ' ', cell.get_text(' ', strip=True)).strip() for cell in cells]
    if values and len(samples) < 80:
        samples.append(values)
    italian = next((value[9:].strip() for value in values if value.startswith('Italiano:')), None)
    english = next((value[8:].strip() for value in values if value.startswith('Inglese:')), None)
    if italian and english:
        lookup.setdefault(english, italian)
rows = [
    {
        'id': item['id'],
        'sourceName': item['name'],
        'pokemonCentralItalianName': lookup.get(item['name']),
    }
    for item in held
]
Path('held-items-pokemoncentral.json').write_text(
    json.dumps(
        {
            'count': len(rows),
            'lookupCount': len(lookup),
            'matched': sum(1 for row in rows if row['pokemonCentralItalianName']),
            'samples': samples,
            'items': rows,
        },
        ensure_ascii=False,
        indent=2,
    ) + '\n',
    encoding='utf-8',
)
