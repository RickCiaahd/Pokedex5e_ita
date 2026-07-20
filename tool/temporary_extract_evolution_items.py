import json
from pathlib import Path

source_path = Path('assets/data_webapp/items.json')
output_path = Path('docs/translation/temporary-evolution-items-source.json')

document = json.loads(source_path.read_text(encoding='utf-8'))
items = list(document.get('items', []))
selected = []
for index, item in enumerate(items, start=1):
    if item.get('type') == 'evolution':
        selected.append({
            'catalogIndex': index,
            'id': item.get('id'),
            'name': item.get('name'),
            'type': item.get('type'),
            'cost': item.get('cost'),
            'description': item.get('description'),
            'media': item.get('media'),
            '_ingameEffect': item.get('_ingameEffect'),
        })

output = {
    'source': str(source_path),
    'catalogCount': len(items),
    'evolutionCount': len(selected),
    'items': selected,
}
output_path.write_text(json.dumps(output, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(f'Extracted {len(selected)} evolution items')
