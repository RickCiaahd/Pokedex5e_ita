from pathlib import Path

path = Path('assets/data/item_localization_it_berry_088_115.json')
text = path.read_text(encoding='utf-8')
text = text.replace(
    'Può essere consumata come reazione quando i tuoi HP scendono sotto la metà.',
    'Può essere consumata come reazione quando i tuoi punti ferita scendono sotto la metà.',
)
path.write_text(text, encoding='utf-8')
