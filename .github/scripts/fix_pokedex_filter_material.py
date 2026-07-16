from pathlib import Path

path = Path('lib/screens/pokedex/pokedex_screen.dart')
source = path.read_text(encoding='utf-8')
old = """    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
"""
new = """    return Material(
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
"""
count = source.count(old)
if count != 1:
    raise SystemExit(f'Expected one filter panel match, found {count}')
path.write_text(source.replace(old, new, 1), encoding='utf-8')
