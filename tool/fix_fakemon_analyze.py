from pathlib import Path

path = Path('lib/repositories/pokemon_repository.dart')
source = path.read_text(encoding='utf-8')
old = "import '../models/custom_pokemon_definition.dart';\n"
if source.count(old) != 1:
    raise SystemExit('unused import marker missing')
path.write_text(source.replace(old, '', 1), encoding='utf-8')
