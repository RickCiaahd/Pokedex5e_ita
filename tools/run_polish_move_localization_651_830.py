import importlib.util
import re
from pathlib import Path

MODULE_PATH = Path('tools/polish_move_localization_651_830.py')
spec = importlib.util.spec_from_file_location('move_polish_651_830', MODULE_PATH)
if spec is None or spec.loader is None:
    raise RuntimeError('Impossibile caricare lo script di revisione.')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


def token_counts(value: str) -> dict[str, int]:
    normalized = re.sub(
        r'\b(?:MOVE|Move)\s+DC\b',
        'MOVE DC',
        value,
    )
    normalized = re.sub(
        r'\bCD della mossa\b',
        'MOVE DC',
        normalized,
        flags=re.IGNORECASE,
    )
    counts: dict[str, int] = {}
    for match in module.TOKEN_RE.finditer(normalized):
        token = module.canonical_token(match.group(0))
        counts[token] = counts.get(token, 0) + 1
    return counts


module.token_counts = token_counts
module.main()
