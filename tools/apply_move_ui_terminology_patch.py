from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file_path = Path(path)
    text = file_path.read_text(encoding='utf-8')
    if old not in text:
        raise SystemExit(f'Pattern non trovato in {path}: {old!r}')
    file_path.write_text(text.replace(old, new, 1), encoding='utf-8')


replace_once(
    'lib/models/move_data.dart',
    ".map((power) => _localizeAbilityAbbreviation(power.toUpperCase()))",
    ".map((power) => power.toUpperCase())",
)

replace_once(
    'lib/screens/battle/battle_screen.dart',
    "if (move.save != null) parts.add('DC ${8 + proficiency + moveModifier}');",
    "if (move.save != null) parts.add('CD ${8 + proficiency + moveModifier}');",
)
