from pathlib import Path

path = Path('CHANGELOG.md')
text = path.read_text(encoding='utf-8')
old = '- localizzati con nomi italiani verificati e descrizioni 5e tradotte i 24 tipi di Poké Ball, i 63 oggetti di tipo medicina e le 28 bacche, conservando ID, costi, asset e nomi tecnici;'
new = '- localizzati con nomi italiani verificati e descrizioni 5e tradotte i 24 tipi di Poké Ball, i 63 oggetti di tipo medicina, le 28 bacche e i 39 oggetti evolutivi, conservando ID, costi, asset e nomi tecnici;'
if old not in text and new not in text:
    raise SystemExit('Voce del changelog non trovata')
path.write_text(text.replace(old, new, 1), encoding='utf-8')
