from pathlib import Path

path = Path('.github/agent/apply_eggs_in_team.py')
text = path.read_text(encoding='utf-8')
label = "    'egg list explanation',\n)"
label_index = text.find(label)
if label_index < 0:
    raise RuntimeError('Etichetta della spiegazione uova non trovata nello script')
start = text.rfind('text = replace_once(', 0, label_index)
end = text.find('\ntext = replace_once(', label_index + len(label))
if start < 0 or end < 0:
    raise RuntimeError('Limiti del blocco spiegazione uova non trovati')
replacement = '''text = text.replace(
    'Ogni uovo occupa un Pokéslot secondo il manuale. Il limite resta sotto il controllo del tavolo.',
    'Un uovo trasportato occupa davvero un Pokéslot. Un uovo affidato alla Pensione resta fuori dalla squadra e alla schiusa il Pokémon viene inviato al PC.',
    1,
)
'''
text = text[:start] + replacement + text[end + 1:]
path.write_text(text, encoding='utf-8')
