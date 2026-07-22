from pathlib import Path

path = Path('lib/screens/pokemon/custom_pokemon_advanced_editor_screen.dart')
source = path.read_text(encoding='utf-8')
old = 'item.description,'
new = 'item.displayDescription,'
if source.count(old) != 1:
    raise SystemExit(
        f'Descrizione oggetto nel selettore Fakemon non univoca: {source.count(old)}.'
    )
path.write_text(source.replace(old, new, 1), encoding='utf-8')
