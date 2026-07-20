from pathlib import Path

TEST_PATH = Path('test/item_localization_integrity_test.dart')
CHANGELOG_PATH = Path('CHANGELOG.md')

text = TEST_PATH.read_text(encoding='utf-8')

names = """  'sun-stone': 'Pietrasolare',
  'moon-stone': 'Pietralunare',
  'fire-stone': 'Pietrafocaia',
  'thunder-stone': 'Pietratuono',
  'water-stone': 'Pietraidrica',
  'leaf-stone': 'Pietrafoglia',
  'shiny-stone': 'Pietrabrillo',
  'dusk-stone': 'Neropietra',
  'dawn-stone': 'Pietralbore',
  'ice-stone': 'Pietragelo',
  'oval-stone': 'Pietraovale',
  'alola-stone': 'Alola Stone',
  'kings-rock': 'Roccia di re',
  'razor-claw': 'Affilartigli',
  'razor-fang': 'Affilodente',
  'metal-coat': 'Metalcoperta',
  'deep-sea-scale': 'Squamabissi',
  'deep-sea-tooth': 'Dente Abissi',
  'dragon-scale': 'Squama Drago',
  'up-grade': 'Upgrade',
  'protector': 'Copertura',
  'electirizer': 'Elettritore',
  'magmarizer': 'Magmatore',
  'dubious-disc': 'Dubbiodisco',
  'reaper-cloth': 'Terrorpanno',
  'prism-scale': 'Squama Bella',
  'whipped-dream': 'Dolcespuma',
  'sachet': 'Bustina Aromi',
  'sweet': 'Bonbon',
  'cracked-pot': 'Teiera rotta',
  'chipped-pot': 'Teiera crepata',
  'unremarkable-teacup': 'Tazza dozzinale',
  'masterpiece-teacup': 'Tazza eccezionale',
  'galarica-wreath': 'Corona Galarnoce',
  'black-augurite': 'Augite nera',
  'peat-block': 'Blocco di torba',
  'auspicious-armor': 'Armatura fausta',
  'malicious-armor': 'Armatura infausta',
  'gimmighoul-coin': 'Moneta di Gimmighoul',
"""
anchor = "  'roseli-berry': 'Baccarcadè',\n"
if "'sun-stone': 'Pietrasolare'" not in text:
    if anchor not in text:
        raise SystemExit('Anchor per i nomi non trovato')
    text = text.replace(anchor, anchor + names, 1)

text = text.replace(
    "test('i blocchi completati coprono Poké Ball, medicine e bacche', () async {",
    "test('i blocchi completati coprono Poké Ball, medicine, bacche e oggetti evolutivi', () async {",
    1,
)
text = text.replace(
    "            'berry',\n          }.contains(item['type']),",
    "            'berry',\n            'evolution',\n          }.contains(item['type']),",
    1,
)
text = text.replace(
    "const {'pokeball', 'medicine', 'berry'},",
    "const {'pokeball', 'medicine', 'berry', 'evolution'},",
    1,
)
text = text.replace('expect(declaredCount, 115);', 'expect(declaredCount, 154);', 1)
text = text.replace('expect(localizedItems.length, 115);', 'expect(localizedItems.length, 154);', 1)
text = text.replace('expect(entries.length, 115);', 'expect(entries.length, 154);', 1)

spot_anchor = "    expect(entries['roseli-berry']?.name, 'Baccarcadè');\n"
spot_checks = """    expect(entries['sun-stone']?.name, 'Pietrasolare');
    expect(entries['alola-stone']?.name, 'Alola Stone');
    expect(entries['kings-rock']?.name, 'Roccia di re');
    expect(entries['metal-coat']?.name, 'Metalcoperta');
    expect(entries['sweet']?.name, 'Bonbon');
    expect(entries['unremarkable-teacup']?.name, 'Tazza dozzinale');
    expect(entries['gimmighoul-coin']?.name, 'Moneta di Gimmighoul');
"""
if "entries['sun-stone']" not in text:
    if spot_anchor not in text:
        raise SystemExit('Anchor per gli spot check non trovato')
    text = text.replace(spot_anchor, spot_anchor + spot_checks, 1)

repo_anchor = "    expect(byId['roseli-berry']?.technicalName, 'Roseli Berry');\n"
repo_checks = """    expect(byId['sun-stone']?.name, 'Pietrasolare');
    expect(byId['sun-stone']?.technicalName, 'Sun Stone');
    expect(byId['alola-stone']?.name, 'Alola Stone');
    expect(byId['alola-stone']?.technicalName, 'Alola Stone');
    expect(byId['gimmighoul-coin']?.name, 'Moneta di Gimmighoul');
    expect(byId['gimmighoul-coin']?.technicalName, 'Gimmighoul Coin');
"""
if "byId['sun-stone']" not in text:
    if repo_anchor not in text:
        raise SystemExit('Anchor per il repository non trovato')
    text = text.replace(repo_anchor, repo_anchor + repo_checks, 1)

TEST_PATH.write_text(text, encoding='utf-8')

changelog = CHANGELOG_PATH.read_text(encoding='utf-8')
old = '- localizzati con nomi italiani verificati e descrizioni 5e tradotte i 24 tipi di Poké Ball, i 63 oggetti di tipo medicina e le 28 bacche, conservando ID, costi, asset e nomi tecnici;'
new = '- localizzati con nomi italiani verificati e descrizioni 5e tradotte i 24 tipi di Poké Ball, i 63 oggetti di tipo medicina, le 28 bacche e i 39 oggetti evolutivi, conservando ID, costi, asset e nomi tecnici;'
if old not in changelog and new not in changelog:
    raise SystemExit('Voce del changelog non trovata')
changelog = changelog.replace(old, new, 1)
CHANGELOG_PATH.write_text(changelog, encoding='utf-8')
