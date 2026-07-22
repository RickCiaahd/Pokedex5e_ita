from pathlib import Path

path = Path('lib/screens/pokemon/custom_pokemon_advanced_editor_screen.dart')
source = path.read_text(encoding='utf-8')
old = '''          subtitle: Text(
            item.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
'''
new = '''          subtitle: Text(
            item.displayDescription,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
'''
if source.count(old) != 1:
    raise SystemExit('Descrizione oggetto nel selettore Fakemon non trovata.')
path.write_text(source.replace(old, new, 1), encoding='utf-8')
