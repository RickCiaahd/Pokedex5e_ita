from pathlib import Path

path = Path('tool/apply_bag_sell_cart.py')
text = path.read_text(encoding='utf-8')
old = "sell_sheet = '''class _SellItemPickerSheet"
new = "sell_sheet = r'''class _SellItemPickerSheet"
if old not in text:
    raise RuntimeError('Blocco sell_sheet non trovato')
path.write_text(text.replace(old, new, 1), encoding='utf-8')
