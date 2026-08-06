from pathlib import Path

path = Path('tool/apply_narrative_background_and_inventory_cart.py')
text = path.read_text(encoding='utf-8')

old = "inputFormatters: const [LengthLimitingTextInputFormatter(4000)],"
new = "inputFormatters: [LengthLimitingTextInputFormatter(4000)],"
count = text.count(old)
if count != 2:
    raise RuntimeError(f'Expected two const formatter occurrences, found {count}')

path.write_text(text.replace(old, new), encoding='utf-8')
