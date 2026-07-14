from pathlib import Path

path = Path('.github/agent/apply_eggs_in_team.py')
text = path.read_text(encoding='utf-8')


def replace_block(label: str, replacement: str) -> None:
    global text
    marker = f"    '{label}',\n)"
    marker_index = text.find(marker)
    if marker_index < 0:
        raise RuntimeError(f'Etichetta non trovata nello script: {label}')
    start = text.rfind('text = replace_once(', 0, marker_index)
    end = text.find('\ntext = replace_once(', marker_index + len(marker))
    if start < 0 or end < 0:
        raise RuntimeError(f'Limiti del blocco non trovati: {label}')
    text = text[:start] + replacement + text[end + 1:]


replace_block(
    'egg list explanation',
    '''text = text.replace(
    'Ogni uovo occupa un Pokéslot secondo il manuale. Il limite resta sotto il controllo del tavolo.',
    'Un uovo trasportato occupa davvero un Pokéslot. Un uovo affidato alla Pensione resta fuori dalla squadra e alla schiusa il Pokémon viene inviato al PC.',
    1,
)
''',
)

replace_block(
    'team remove only pokemon',
    '''text = text.replace(
    "                  onRemove: slot.pokemonId == null\n                      ? null\n                      : () => _setPokemonInSlot(slot.slotIndex, null),",
    "                  onRemove: slot.isPokemon\n                      ? () => _setPokemonInSlot(slot.slotIndex, null)\n                      : null,",
    1,
)
''',
)

path.write_text(text, encoding='utf-8')
