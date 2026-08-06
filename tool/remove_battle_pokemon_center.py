from pathlib import Path
import re


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f'{label}: expected 1 exact match, found {count}')
    return text.replace(old, new, 1)


def regex_once(text: str, pattern: str, replacement: str, label: str) -> str:
    updated, count = re.subn(pattern, replacement, text, count=1, flags=re.S)
    if count != 1:
        raise RuntimeError(f'{label}: expected 1 regex match, found {count}')
    return updated


path = Path('lib/screens/battle/battle_screen.dart')
text = path.read_text(encoding='utf-8')

text = regex_once(
    text,
    r"\n  Future<void> _healFull\(_BattleData data, TeamSlot slot\) async \{.*?\n  \}\n\n(?=  Future<void> _openStatusPicker)",
    "\n",
    'remove Pokemon Center healing method',
)

text = replace_once(
    text,
    """                                    onEditHp: () => _editHp(data, activeSlot),
                                    onHeal: () => _healFull(data, activeSlot),
                                    onStatus: () =>
""",
    """                                    onEditHp: () => _editHp(data, activeSlot),
                                    onStatus: () =>
""",
    'remove Pokemon Center callback wiring',
)

text = replace_once(
    text,
    """    required this.onTransformations,
    required this.onEditHp,
    required this.onHeal,
    required this.onStatus,
""",
    """    required this.onTransformations,
    required this.onEditHp,
    required this.onStatus,
""",
    'remove Pokemon Center constructor parameter',
)

text = replace_once(
    text,
    """  final VoidCallback onTransformations;
  final VoidCallback onEditHp;
  final VoidCallback onHeal;
  final VoidCallback onStatus;
""",
    """  final VoidCallback onTransformations;
  final VoidCallback onEditHp;
  final VoidCallback onStatus;
""",
    'remove Pokemon Center field',
)

text = replace_once(
    text,
    """                FilledButton(
                  onPressed: onHeal,
                  child: Text(
                    context.uiText('POKÉMON CENTER', 'POKÉMON CENTER'),
                  ),
                ),
""",
    "",
    'remove Pokemon Center button',
)

path.write_text(text, encoding='utf-8')
print('Pokemon Center removed from Battle Companion.')
