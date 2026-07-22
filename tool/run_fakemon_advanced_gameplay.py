from pathlib import Path

script_path = Path('tool/apply_fakemon_advanced_gameplay.py')
source = script_path.read_text(encoding='utf-8')

old_function = '''def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    source = file.read_text(encoding='utf-8')
    count = source.count(old)
    if count != 1:
        raise SystemExit(f'{path}: expected one match, found {count}')
    file.write_text(source.replace(old, new, 1), encoding='utf-8')
'''
new_function = '''def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    source = file.read_text(encoding='utf-8')
    count = source.count(old)
    label = next((line.strip() for line in old.splitlines() if line.strip()), '<empty>')
    if count != 1:
        raise SystemExit(
            f'{path}: expected one match, found {count}; pattern starts with: {label}'
        )
    print(f'patching {path}: {label}')
    file.write_text(source.replace(old, new, 1), encoding='utf-8')
'''
if old_function not in source:
    raise SystemExit('gameplay replace_once function marker missing')
source = source.replace(old_function, new_function, 1)

old = '''replace_once(
    path,
    """import '../../services/custom_pokemon_runtime_registry.dart';
""",
    """import '../../services/custom_pokemon_runtime_registry.dart';
""",
)
# The runtime registry import already exists in the current battle screen; the
# exact self-replacement above validates that assumption without changing it.
'''
new = '''replace_once(
    path,
    """import '../../services/battle_form_change_service.dart';
""",
    """import '../../services/battle_form_change_service.dart';
import '../../services/custom_pokemon_runtime_registry.dart';
""",
)
'''
if old not in source:
    raise SystemExit('gameplay wrapper marker missing')
source = source.replace(old, new, 1)
exec(compile(source, str(script_path), 'exec'))
