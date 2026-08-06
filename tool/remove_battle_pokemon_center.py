from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f'{label}: expected 1 exact match, found {count}')
    return text.replace(old, new, 1)


def remove_dart_method(text: str, signature: str, label: str) -> str:
    start = text.find(signature)
    if start < 0:
        raise RuntimeError(f'{label}: signature not found')
    if text.find(signature, start + 1) >= 0:
        raise RuntimeError(f'{label}: signature is not unique')

    opening_brace = text.find('{', start)
    if opening_brace < 0:
        raise RuntimeError(f'{label}: opening brace not found')

    depth = 0
    index = opening_brace
    while index < len(text):
        char = text[index]
        if char == '{':
            depth += 1
        elif char == '}':
            depth -= 1
            if depth == 0:
                end = index + 1
                while end < len(text) and text[end] == '\n':
                    end += 1
                prefix_start = start
                if prefix_start > 0 and text[prefix_start - 1] == '\n':
                    prefix_start -= 1
                return text[:prefix_start] + '\n\n' + text[end:]
        index += 1

    raise RuntimeError(f'{label}: matching closing brace not found')


path = Path('lib/screens/battle/battle_screen.dart')
text = path.read_text(encoding='utf-8')

text = remove_dart_method(
    text,
    '  Future<void> _healFull(_BattleData data, TeamSlot slot) async {',
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
