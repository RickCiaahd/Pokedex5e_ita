from pathlib import Path

path = Path('tool/apply_narrative_background_and_inventory_cart.py')
text = path.read_text(encoding='utf-8')
old = "    updated, count = re.subn(pattern, replacement, text, count=1, flags=re.S)\n"
new = "    updated, count = re.subn(pattern, lambda _: replacement, text, count=1, flags=re.S)\n"
if old not in text:
    raise RuntimeError('Expected regex helper implementation not found')
path.write_text(text.replace(old, new, 1), encoding='utf-8')
