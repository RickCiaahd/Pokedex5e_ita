from pathlib import Path

path = Path('test/item_localization_integrity_test.dart')
text = path.read_text(encoding='utf-8')

names = """  'cheri-berry': 'Baccaliegia',
  'chesto-berry': 'Baccastagna',
  'pecha-berry': 'Baccapesca',
  'rawst-berry': 'Baccafrago',
  'aspear-berry': 'Baccaperina',
  'leppa-berry': 'Baccamela',
  'oran-berry': 'Baccarancia',
  'persim-berry': 'Baccaki',
  'lum-berry': 'Baccaprugna',
  'sitrus-berry': 'Baccacedro',
  'occa-berry': 'Baccacao',
  'passho-berry': 'Baccapasflo',
  'wacan-berry': 'Baccaparmen',
  'rindo-berry': 'Baccarindo',
  'yache-berry': 'Baccamoya',
  'chople-berry': 'Baccarosmel',
  'kebia-berry': 'Baccakebia',
  'shuca-berry': 'Baccanaca',
  'coba-berry': 'Baccababa',
  'payapa-berry': 'Baccapayapa',
  'tanga-berry': 'Baccaitan',
  'charti-berry': 'Baccaciofo',
  'kasib-berry': 'Baccacitrus',
  'haban-berry': 'Baccahaban',
  'colbur-berry': 'Baccaxan',
  'babiri-berry': 'Baccababiri',
  'chilan-berry': 'Baccacinlan',
  'roseli-berry': 'Baccarcadè',
"""
anchor = "  'ability-patch': 'Cerotto abilità',\n"
if names.strip() not in text:
    if anchor not in text:
        raise SystemExit('Anchor nomi non trovato')
    text = text.replace(anchor, anchor + names, 1)

text = text.replace(
    "test('il primo blocco copre tutte le Poké Ball e le medicine', () async {",
    "test('i blocchi completati coprono Poké Ball, medicine e bacche', () async {",
    1,
)
text = text.replace(
    ".where((item) => const {'pokeball', 'medicine'}.contains(item['type']))",
    ".where(\n          (item) => const {\n            'pokeball',\n            'medicine',\n            'berry',\n          }.contains(item['type']),\n        )",
    1,
)
text = text.replace(
    "expect(const {'pokeball', 'medicine'}, contains(document['type']));",
    "expect(\n        const {'pokeball', 'medicine', 'berry'},\n        contains(document['type']),\n      );",
    1,
)
text = text.replace('expect(declaredCount, 87);', 'expect(declaredCount, 115);', 1)
text = text.replace('expect(localizedItems.length, 87);', 'expect(localizedItems.length, 115);', 1)
text = text.replace('expect(entries.length, 87);', 'expect(entries.length, 115);', 1)

spot_anchor = "    expect(entries['red-nectar']?.name, 'Nettare Rosso');\n"
spot_checks = """    expect(entries['cheri-berry']?.name, 'Baccaliegia');
    expect(entries['sitrus-berry']?.name, 'Baccacedro');
    expect(entries['passho-berry']?.name, 'Baccapasflo');
    expect(entries['chople-berry']?.name, 'Baccarosmel');
    expect(entries['roseli-berry']?.name, 'Baccarcadè');
"""
if spot_checks.strip() not in text:
    if spot_anchor not in text:
        raise SystemExit('Anchor spot check non trovato')
    text = text.replace(spot_anchor, spot_anchor + spot_checks, 1)

repo_anchor = "    expect(byId['potion']?.technicalName, 'Potion');\n"
repo_checks = """    expect(byId['cheri-berry']?.name, 'Baccaliegia');
    expect(byId['cheri-berry']?.technicalName, 'Cheri Berry');
    expect(byId['roseli-berry']?.name, 'Baccarcadè');
    expect(byId['roseli-berry']?.technicalName, 'Roseli Berry');
"""
if repo_checks.strip() not in text:
    if repo_anchor not in text:
        raise SystemExit('Anchor repository non trovato')
    text = text.replace(repo_anchor, repo_anchor + repo_checks, 1)

path.write_text(text, encoding='utf-8')
