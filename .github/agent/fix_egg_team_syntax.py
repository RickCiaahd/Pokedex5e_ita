from pathlib import Path

path = Path('lib/screens/breeding/breeding_screen.dart')
text = path.read_text(encoding='utf-8')
needle = "\n                          )\n                          value: _useDayCare,"
replacement = "\n                          ),\n                          value: _useDayCare,"
if needle in text:
    text = text.replace(needle, replacement, 1)
elif replacement not in text:
    raise RuntimeError('Chiusura Text Pensione non trovata')
path.write_text(text, encoding='utf-8')
