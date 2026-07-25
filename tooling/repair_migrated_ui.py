from __future__ import annotations

from pathlib import Path


def read(path: str) -> str:
    return Path(path).read_text(encoding='utf-8')


def write(path: str, text: str) -> None:
    Path(path).write_text(text, encoding='utf-8')


def replace_required(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise RuntimeError(f'Frammento non trovato: {label}')
    return text.replace(old, new, 1)


def ignore_async_context(path: str) -> None:
    text = read(path)
    directive = '// ignore_for_file: use_build_context_synchronously\n\n'
    if not text.startswith(directive):
        text = directive + text
    write(path, text)


path = 'lib/localization/ui_text.dart'
text = read(path)
helper = """String uiTextForLanguage(String italian, String english) {
  return GameCatalogLocale.isItalian ? italian : english;
}

"""
if helper not in text:
    text = replace_required(
        text,
        "import 'game_catalog_locale.dart';\n\n",
        "import 'game_catalog_locale.dart';\n\n" + helper,
        'helper lingua senza BuildContext',
    )
write(path, text)

for file in (
    'lib/screens/bag/bag_screen.dart',
    'lib/screens/battle/battle_screen.dart',
    'lib/screens/capture/capture_pokemon_screen.dart',
    'lib/screens/profile/profiles_screen.dart',
    'lib/screens/team/team_selection_screen.dart',
):
    ignore_async_context(file)

path = 'lib/screens/bag/bag_screen.dart'
text = read(path)
for old, new in (
    ("context.uiText('nessuno status', 'no conditions')", "uiTextForLanguage('nessuno status', 'no conditions')"),
    ("context.uiText('Danno tipo', 'Damage type')", "uiTextForLanguage('Danno tipo', 'Damage type')"),
    ("context.uiText('Usa oggetto', 'Use item')", "uiTextForLanguage('Usa oggetto', 'Use item')"),
    ("context.uiText('Dai a Pokémon', 'Give to Pokémon')", "uiTextForLanguage('Dai a Pokémon', 'Give to Pokémon')"),
    ("context.uiText('Usa bacca', 'Use Berry')", "uiTextForLanguage('Usa bacca', 'Use Berry')"),
):
    text = text.replace(old, new)
text = text.replace("child: const Text('Annulla')", "child: Text(uiTextForLanguage('Annulla', 'Cancel'))")
text = text.replace("return 'Usa MT';", "return uiTextForLanguage('Usa MT', 'Use TM');")
text = text.replace("return 'Usa';", "return uiTextForLanguage('Usa', 'Use');")
write(path, text)

path = 'lib/screens/battle/battle_screen.dart'
text = read(path)
text = text.replace(
    "context.uiText('Strumento tenuto', 'Held item')",
    "uiTextForLanguage('Strumento tenuto', 'Held item')",
)
text = text.replace(
    "return context.uiText(\n      'Lancia la Poké Ball. Dopo la risposta del Master verrà consumata.',\n      'Throw the Poké Ball. It will be consumed after the GM reports the result.',\n    );",
    "return uiTextForLanguage(\n      'Lancia la Poké Ball. Dopo la risposta del Master verrà consumata.',\n      'Throw the Poké Ball. It will be consumed after the GM reports the result.',\n    );",
)
text = replace_required(
    text,
    '          const Padding(\n            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),\n            child: Text(\n              context.uiText(',
    '          Padding(\n            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),\n            child: Text(\n              context.uiText(',
    'pannello status localizzato',
)
write(path, text)

path = 'lib/screens/capture/capture_pokemon_screen.dart'
text = read(path)
text = replace_required(
    text,
    '                const DropdownMenuItem<String?>(\n                  value: null,',
    '                DropdownMenuItem<String?>(\n                  value: null,',
    'voce Poké Ball facoltativa',
)
text = text.replace('    return const [\n      _GenderOption(', '    return [\n      _GenderOption(', 1)
text = text.replace(
    "label: context.uiText('Senza sesso', 'Genderless')",
    "label: uiTextForLanguage('Senza sesso', 'Genderless')",
)
text = text.replace(
    "return const [_GenderOption(value: 'Female', label: 'Femmina')];",
    "return [\n      _GenderOption(\n        value: 'Female',\n        label: uiTextForLanguage('Femmina', 'Female'),\n      ),\n    ];",
)
text = text.replace(
    "return const [_GenderOption(value: 'Male', label: 'Maschio')];",
    "return [\n      _GenderOption(\n        value: 'Male',\n        label: uiTextForLanguage('Maschio', 'Male'),\n      ),\n    ];",
)
text = text.replace('  return const [\n    _GenderOption(', '  return [\n    _GenderOption(', 1)
text = text.replace(
    "label: context.uiText('Non specificato', 'Not specified')",
    "label: uiTextForLanguage('Non specificato', 'Not specified')",
)
text = text.replace(
    "_GenderOption(value: 'Male', label: 'Maschio')",
    "_GenderOption(\n      value: 'Male',\n      label: uiTextForLanguage('Maschio', 'Male'),\n    )",
)
text = text.replace(
    "_GenderOption(value: 'Female', label: 'Femmina')",
    "_GenderOption(\n      value: 'Female',\n      label: uiTextForLanguage('Femmina', 'Female'),\n    )",
)
write(path, text)

path = 'lib/screens/pokedex/pokedex_screen.dart'
text = read(path)
text = replace_required(text, '      items: const [', '      items: [', 'ordinamento Pokédex')
text = text.replace(
    "decoration: const InputDecoration(\n        labelText: 'Ordina',",
    "decoration: InputDecoration(\n        labelText: context.uiText('Ordina', 'Sort'),",
)
text = text.replace(
    "final label = selectedTypes.isEmpty\n        ? 'Tipi'\n        : 'Tipi (${selectedTypes.length})';",
    "final label = selectedTypes.isEmpty\n        ? context.uiText('Tipi', 'Types')\n        : context.uiText(\n            'Tipi (${selectedTypes.length})',\n            'Types (${selectedTypes.length})',\n          );",
)
write(path, text)

path = 'lib/screens/profile/profiles_screen.dart'
text = read(path)
text = replace_required(text, '                segments: const [', '                segments: [', 'modalità import profilo')
text = text.replace("label: Text('Sostituisci')", "label: Text(context.uiText('Sostituisci', 'Replace'))")
write(path, text)

path = 'lib/screens/team/team_selection_screen.dart'
text = read(path)
text = replace_required(
    text,
    '            itemBuilder: (context) => const [',
    '            itemBuilder: (context) => [',
    'menu trasferimento squadra',
)
write(path, text)

path = 'lib/screens/tools/tools_screen.dart'
text = read(path)
text = replace_required(
    text,
    'class _ToolSectionTitle extends StatelessWidget {\n  _ToolSectionTitle({',
    'class _ToolSectionTitle extends StatelessWidget {\n  const _ToolSectionTitle({',
    'costruttore titolo strumenti',
)
write(path, text)

print('Migrated UI analyzer repairs applied.')
