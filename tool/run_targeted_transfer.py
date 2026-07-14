from pathlib import Path

script_path = Path('tool/apply_targeted_transfer.py')
source = script_path.read_text(encoding='utf-8')
old = '''    """    await _setPokemonInSlot(slot.slotIndex, selectedPokemonId);
  }$methods

  @override
""",
'''
new = '''    """    await _setPokemonInSlot(slot.slotIndex, selectedPokemonId);
  }""" + methods + """

  @override
""",
'''
count = source.count(old)
if count != 1:
    raise SystemExit(f'Expected one methods insertion block, found {count}')
source = source.replace(old, new)
exec(compile(source, str(script_path), 'exec'))
