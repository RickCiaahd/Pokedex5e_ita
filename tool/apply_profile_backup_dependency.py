from pathlib import Path

path = Path('pubspec.yaml')
text = path.read_text(encoding='utf-8')
needle = '  scrollable_positioned_list: ^0.3.8\n\n'
replacement = '  scrollable_positioned_list: ^0.3.8\n  file_picker: ^11.0.2\n\n'

if 'file_picker:' not in text:
    if needle not in text:
        raise SystemExit('Could not locate the dependency insertion point.')
    text = text.replace(needle, replacement, 1)
    path.write_text(text, encoding='utf-8')
