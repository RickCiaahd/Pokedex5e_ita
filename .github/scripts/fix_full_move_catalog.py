from pathlib import Path

path = Path('lib/screens/pokemon/pokemon_edit_screen.dart')
source = path.read_text(encoding='utf-8')

broken_join = "subtitle: details.join('\n'),"
fixed_join = "subtitle: details.join('\\n'),"
if broken_join not in source:
    raise SystemExit('broken subtitle join not found')
source = source.replace(broken_join, fixed_join, 1)

old_types = "return types.toList(growable: false)\n      ..sort"
new_types = "return types.toList()\n      ..sort"
if old_types not in source:
    raise SystemExit('fixed-length type list not found')
source = source.replace(old_types, new_types, 1)

marker = "final moves = _sourceMoves.where((move) {"
start = source.index(marker)
old_active = "}).toList(growable: false);"
active_index = source.index(old_active, start)
source = source[:active_index] + "}).toList();" + source[active_index + len(old_active):]

path.write_text(source, encoding='utf-8')
