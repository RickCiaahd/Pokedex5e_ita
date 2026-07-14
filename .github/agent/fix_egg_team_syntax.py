from pathlib import Path

path = Path('lib/screens/breeding/breeding_screen.dart')
text = path.read_text(encoding='utf-8')
old = """                                    : 'L’uovo occuperà lo slot squadra ${freeSlot.slotIndex + 1}.'
                          )
                          value: _useDayCare,"""
new = """                                    : 'L’uovo occuperà lo slot squadra ${freeSlot.slotIndex + 1}.'
                          ),
                          value: _useDayCare,"""
if text.count(old) != 1:
    raise RuntimeError(f'Chiusura Text Pensione non trovata: {text.count(old)}')
path.write_text(text.replace(old, new, 1), encoding='utf-8')
