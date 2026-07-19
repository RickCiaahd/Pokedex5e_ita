from pathlib import Path

changelog_path = Path('CHANGELOG.md')
changelog = changelog_path.read_text(encoding='utf-8')
changelog_anchor = (
    '- tradotte in italiano le descrizioni delle 330 abilità, preservando nomi, '
    'ID, flag di deprecazione e valori meccanici originali;\n'
)
changelog_line = (
    '- assegnati i nomi italiani ufficiali a 308 abilità confrontate con Pokémon '
    'Central, mantenendo invariati nomi tecnici, ID e dati salvati; le 22 voci '
    'personalizzate o deprecate conservano il nome originale;\n'
)
if changelog_line not in changelog:
    if changelog_anchor not in changelog:
        raise SystemExit('Punto di inserimento del changelog non trovato.')
    changelog = changelog.replace(
        changelog_anchor,
        changelog_anchor + changelog_line,
        1,
    )
    changelog_path.write_text(changelog, encoding='utf-8')

glossary_path = Path('docs/translation/glossary-it.md')
glossary = glossary_path.read_text(encoding='utf-8')
section = '''
## Nomi delle abilità

- Le abilità presenti nei videogiochi usano il nome italiano riportato nella pagina **Abilità** di Pokémon Central Wiki: `https://wiki.pokemoncentral.it/Abilit%C3%A0`.
- Il nome inglese tecnico resta invariato nei JSON sorgente, nei salvataggi, nei trasferimenti e nei riferimenti interni.
- La localizzazione del nome viene applicata soltanto all'interfaccia.
- Le capacità personalizzate del sistema 5e, le vecchie mosse registrate come abilità e le voci tecniche di cambio forma conservano il nome originale quando non esiste una corrispondenza ufficiale.
- Le varianti tecniche della stessa abilità condividono il nome ufficiale verificato, per esempio `power-construct-*` → **Sciamefusione** ed `embody-aspect-*` → **Albergamemorie**.

'''
anchor = '## Stile delle descrizioni del Pokédex\n'
if section.strip() not in glossary:
    if anchor not in glossary:
        raise SystemExit('Punto di inserimento del glossario non trovato.')
    glossary = glossary.replace(anchor, section + anchor, 1)
    glossary_path.write_text(glossary, encoding='utf-8')
