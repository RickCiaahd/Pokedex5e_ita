from pathlib import Path

path = Path('.github/agent/apply_eggs_in_team.py')
text = path.read_text(encoding='utf-8')
old = '''text = replace_once(
    text,
    "                  const Text(\n                    'Ogni uovo occupa un Pokéslot secondo il manuale. Il limite resta sotto il controllo del tavolo.',\n                  ),",
    "                  const Text(\n"
    "                    'Un uovo trasportato occupa davvero un Pokéslot. Un uovo affidato alla Pensione resta fuori dalla squadra e alla schiusa il Pokémon viene inviato al PC.',\n"
    "                  ),",
    'egg list explanation',
)
'''
new = '''text = text.replace(
    'Ogni uovo occupa un Pokéslot secondo il manuale. Il limite resta sotto il controllo del tavolo.',
    'Un uovo trasportato occupa davvero un Pokéslot. Un uovo affidato alla Pensione resta fuori dalla squadra e alla schiusa il Pokémon viene inviato al PC.',
    1,
)
'''
if old not in text:
    raise RuntimeError('Blocco della spiegazione uova non trovato nello script')
path.write_text(text.replace(old, new, 1), encoding='utf-8')
