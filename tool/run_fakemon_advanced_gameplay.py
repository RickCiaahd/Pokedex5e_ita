from pathlib import Path

script_path = Path('tool/apply_fakemon_advanced_gameplay.py')
source = script_path.read_text(encoding='utf-8')
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
