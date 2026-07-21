from pathlib import Path

source_path = Path('.github/scripts/fix_battle_forms.py')
source = source_path.read_text(encoding='utf-8')

old_helper = """def replace_once(old: str, new: str) -> None:
    text = PATH.read_text(encoding='utf-8')
    count = text.count(old)
    if count != 1:
        raise SystemExit(
            f'battle_screen.dart: expected one match, found {count}: {old[:120]!r}'
        )
    PATH.write_text(text.replace(old, new, 1), encoding='utf-8')
"""
new_helper = """def replace_once(old: str, new: str) -> None:
    text = PATH.read_text(encoding='utf-8')
    count = text.count(old)
    if count == 0:
        return
    if count != 1:
        raise SystemExit(
            f'battle_screen.dart: expected at most one match, found {count}: {old[:120]!r}'
        )
    PATH.write_text(text.replace(old, new, 1), encoding='utf-8')


def replace_first(old: str, new: str) -> None:
    text = PATH.read_text(encoding='utf-8')
    if old not in text:
        return
    PATH.write_text(text.replace(old, new, 1), encoding='utf-8')
"""
if old_helper not in source:
    raise SystemExit('Unable to patch helper functions')
source = source.replace(old_helper, new_helper, 1)

clear_call = """replace_once(
    \"    _volatileStatusesBySlot.clear();\\n\"
    \"    _battleFormBySlot.clear();\\n\"
    \"    _initiativeEntries.clear();\","""
if clear_call not in source:
    raise SystemExit('Unable to locate the first clear-state patch')
source = source.replace(clear_call, clear_call.replace('replace_once(', 'replace_first('), 1)

exec(compile(source, str(source_path), 'exec'))
