import json
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
for row in soup.select('table tr'):
    cells = row.find_all(['th', 'td'])
    values = [cell.get_text(' ', strip=True) for cell in cells]
    if len(values) >= 3 and values[1] and values[2]:
        lookup.setdefault(values[2], values[1])
rows = [
    {
        'id': item['id'],
        'sourceName': item['name'],
        'pokemonCentralItalianName': lookup.get(item['name']),
    }
    for item in held
]
Path('held-items-pokemoncentral.json').write_text(
    json.dumps({'count': len(rows), 'items': rows}, ensure_ascii=False, indent=2) + '\n',
    encoding='utf-8',
)
