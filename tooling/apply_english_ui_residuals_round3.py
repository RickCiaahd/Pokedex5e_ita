from __future__ import annotations

import json
import re
from pathlib import Path

TRANSLATIONS_PATH = Path('tooling/english_ui_round3_translations.json')
MARKER_PATH = Path('tooling/.english_ui_round3_applied')


def ensure_import(path: Path, import_line: str) -> None:
    text = path.read_text(encoding='utf-8')
    if import_line in text:
        return
    lines = text.splitlines(keepends=True)
    last_import = -1
    for index, line in enumerate(lines):
        if line.startswith('import '):
            last_import = index
        elif last_import >= 0 and line.strip():
            break
    insertion = last_import + 1 if last_import >= 0 else 0
    lines.insert(insertion, import_line + '\n')
    path.write_text(''.join(lines), encoding='utf-8')


def skip_line_comment(text: str, index: int) -> int:
    end = text.find('\n', index + 2)
    return len(text) if end == -1 else end + 1


def skip_block_comment(text: str, index: int) -> int:
    end = text.find('*/', index + 2)
    return len(text) if end == -1 else end + 2


def skip_interpolation(text: str, index: int) -> int:
    depth = 1
    while index < len(text):
        if text.startswith('//', index):
            index = skip_line_comment(text, index)
            continue
        if text.startswith('/*', index):
            index = skip_block_comment(text, index)
            continue
        if text[index] in ("'", '"'):
            index = scan_string_end(text, index)
            continue
        if text[index] == '{':
            depth += 1
        elif text[index] == '}':
            depth -= 1
            if depth == 0:
                return index + 1
        index += 1
    return len(text)


def scan_string_end(text: str, start: int) -> int:
    quote = text[start]
    delimiter = quote * 3 if text.startswith(quote * 3, start) else quote
    index = start + len(delimiter)
    while index < len(text):
        if text.startswith(delimiter, index):
            return index + len(delimiter)
        if text[index] == '\\':
            index += 2
            continue
        if text.startswith('${', index):
            index = skip_interpolation(text, index + 2)
            continue
        index += 1
    return len(text)


def string_literals(text: str):
    index = 0
    while index < len(text):
        if text.startswith('//', index):
            index = skip_line_comment(text, index)
            continue
        if text.startswith('/*', index):
            index = skip_block_comment(text, index)
            continue
        if text[index] not in ("'", '"'):
            index += 1
            continue
        start = index
        delimiter = text[index] * 3 if text.startswith(text[index] * 3, index) else text[index]
        end = scan_string_end(text, start)
        if end <= start + len(delimiter):
            break
        raw = text[start + len(delimiter): end - len(delimiter)]
        yield start, end, raw
        index = end


def english_literal(value: str) -> str:
    if '"""' in value:
        raise ValueError('Unsupported triple quote in English translation')
    return f'"""{value}"""'


def localize_file(path: Path, translations: dict[str, str]) -> None:
    text = path.read_text(encoding='utf-8')
    replacements: list[tuple[int, int, str]] = []
    found: set[str] = set()
    for start, end, raw in string_literals(text):
        english = translations.get(raw)
        if english is None:
            continue
        original = text[start:end]
        replacements.append(
            (start, end, f'uiTextForLanguage({original}, {english_literal(english)})')
        )
        found.add(raw)
    for start, end, replacement in reversed(replacements):
        text = text[:start] + replacement + text[end:]
    missing = sorted(set(translations) - found)
    if missing:
        print(f'{path}: {len(missing)} configured strings were not found')
        for value in missing:
            print(f'  - {value}')
    path.write_text(text, encoding='utf-8')


def remove_invalid_const_widgets(path: Path) -> None:
    text = path.read_text(encoding='utf-8')
    widget_names = (
        'AlertDialog', 'AppBar', 'Card', 'Center', 'Chip', 'ChoiceChip',
        'Column', 'Container', 'DecoratedBox', 'DropdownMenuItem', 'Expanded',
        'FilledButton', 'Flexible', 'InputDecoration', 'ListTile',
        'OutlinedButton', 'Padding', 'Row', 'Scaffold', 'SwitchListTile',
        'Text', 'TextButton', 'Tooltip', 'Wrap',
    )
    pattern = r'\bconst (?=(?:' + '|'.join(widget_names) + r')\s*\()'
    text = re.sub(pattern, '', text)
    for prefix in ('actions:', 'children:', 'items:', 'tabs:'):
        text = text.replace(f'{prefix} const [', f'{prefix} [')
    path.write_text(text, encoding='utf-8')


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding='utf-8')
    if old not in text:
        raise RuntimeError(f'Missing fragment in {path}: {old[:120]!r}')
    path.write_text(text.replace(old, new, 1), encoding='utf-8')


def localize_breeding_service() -> None:
    path = Path('lib/services/breeding_service.dart')
    ensure_import(path, "import '../localization/ui_text.dart';")
    translations = {
        'Seleziona due Pokémon diversi.': 'Select two different Pokémon.',
        'Entrambi i Pokémon devono avere Lealtà almeno +2.': 'Both Pokémon must have at least Loyalty +2.',
        'I dati dei Gruppi Uova non sono disponibili per uno dei genitori.': 'Egg Group data is not available for one of the parents.',
        'I Pokémon del gruppo Undiscovered non possono riprodursi.': 'Pokémon in the Undiscovered group cannot breed.',
        'Due Ditto non possono produrre un uovo.': 'Two Ditto cannot produce an egg.',
        'Senza Ditto servono un Pokémon maschio e uno femmina.': 'Without Ditto, one male and one female Pokémon are required.',
        'I due Pokémon non condividono alcun Gruppo Uova.': 'The two Pokémon do not share an Egg Group.',
        'I genitori selezionati non sono compatibili.': 'The selected parents are not compatible.',
        'La specie risultante non è presente nel catalogo.': 'The resulting species is not in the catalog.',
        'Impossibile generare il contenuto dell’uovo.': 'The egg contents could not be generated.',
    }
    localize_file(path, translations)


def localize_habitats() -> None:
    service = Path('lib/services/pokemon_habitat_service.dart')
    text = service.read_text(encoding='utf-8')
    if 'static String englishLabel' not in text:
        anchor = '  static const List<String> habitats = [\n'
        labels = """  static const Map<String, String> _englishLabels = {
    'Qualsiasi': 'Any',
    'Prateria': 'Grassland',
    'Foresta': 'Forest',
    'Grotta': 'Cave',
    'Montagna': 'Mountain',
    'Deserto': 'Desert',
    'Palude': 'Swamp',
    'Costa e fiumi': 'Coasts and rivers',
    'Mare': 'Sea',
    'Città': 'City',
    'Neve e ghiaccio': 'Snow and ice',
  };

  static String englishLabel(String habitat) =>
      _englishLabels[habitat] ?? habitat;

"""
        if anchor not in text:
            raise RuntimeError('Habitat list anchor not found')
        service.write_text(text.replace(anchor, labels + anchor, 1), encoding='utf-8')

    screen = Path('lib/screens/tools/encounter_generator_screen.dart')
    replace_once(
        screen,
        'DropdownMenuItem(value: habitat, child: Text(habitat))',
        """DropdownMenuItem(
                  value: habitat,
                  child: Text(
                    context.usesItalianUi
                        ? habitat
                        : PokemonHabitatService.englishLabel(habitat),
                  ),
                )""",
    )


def localize_battle_companion() -> None:
    path = Path('lib/screens/battle/battle_screen.dart')
    replacements = (
        ("actionLabel: 'Ricarica',", "actionLabel: context.uiText('Ricarica', 'Reload'),"),
        (
            "'${profile.name} · INIZ. ${trainerInitiativeBonus >= 0 ? '+' : ''}$trainerInitiativeBonus',",
            """context.uiText(
                      '${profile.name} · INIZ. ${trainerInitiativeBonus >= 0 ? '+' : ''}$trainerInitiativeBonus',
                      '${profile.name} · INIT. ${trainerInitiativeBonus >= 0 ? '+' : ''}$trainerInitiativeBonus',
                    ),""",
        ),
        ("return 'Bacca';", "return uiTextForLanguage('Bacca', 'Berry');"),
        ("return 'Medicina';", "return uiTextForLanguage('Medicina', 'Medicine');"),
        ("return 'MT';", "return uiTextForLanguage('MT', 'TM');"),
        (
            "return BattleQuickItemService.isPokeball(item) ? 'LANCIA' : 'USA';",
            """return BattleQuickItemService.isPokeball(item)
      ? uiTextForLanguage('LANCIA', 'THROW')
      : uiTextForLanguage('USA', 'USE');""",
        ),
        (
            "label: Text(formLabel ?? 'Forma'),",
            "label: Text(formLabel ?? context.uiText('Forma', 'Form')),
",
        ),
    )
    for old, new in replacements:
        replace_once(path, old, new)


def localize_miscellaneous() -> None:
    egg_image = Path('lib/widgets/pokemon/egg_asset_image.dart')
    ensure_import(egg_image, "import '../../localization/ui_text.dart';")
    replace_once(
        egg_image,
        "static const String semanticLabel = 'Uovo Pokémon';",
        "static String get semanticLabel =>\n      uiTextForLanguage('Uovo Pokémon', 'Pokémon Egg');",
    )

    home_button = Path('lib/widgets/navigation/home_leading_button.dart')
    text = home_button.read_text(encoding='utf-8')
    if "tooltip: 'Indietro'" in text:
        ensure_import(home_button, "import '../../localization/ui_text.dart';")
        replace_once(
            home_button,
            "tooltip: 'Indietro'",
            "tooltip: context.uiText('Indietro', 'Back')",
        )


def write_focused_test() -> None:
    path = Path('test/english_ui_residuals_round3_test.dart')
    path.write_text(
        """import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/localization/game_catalog_locale.dart';
import 'package:pokedex_5e_ita/models/breeding_candidate.dart';
import 'package:pokedex_5e_ita/services/pokemon_habitat_service.dart';

void main() {
  tearDown(() => GameCatalogLocale.setLanguageCode('it'));

  test('breeding labels and habitats follow the selected language', () {
    const candidate = BreedingCandidate(
      key: 'test',
      pokemonId: 1,
      displayName: 'Test',
      location: 'PC',
      loyalty: 2,
      selectedMoves: [],
      abilities: [],
      gender: 'genderless',
    );

    GameCatalogLocale.setLanguageCode('en');
    expect(candidate.genderLabel, 'Genderless');
    expect(PokemonHabitatService.englishLabel('Qualsiasi'), 'Any');

    GameCatalogLocale.setLanguageCode('it');
    expect(candidate.genderLabel, 'Senza sesso');
  });

  test('third audit localizes the reported screens', () {
    final breeding = File(
      'lib/screens/breeding/breeding_screen.dart',
    ).readAsStringSync();
    expect(breeding, contains('Breeding and Eggs'));
    expect(breeding, contains('POKÉMON BREEDING'));
    expect(breeding, contains('NEW ATTEMPT'));
    expect(breeding, contains('INCUBATING EGGS'));

    final battle = File(
      'lib/screens/battle/battle_screen.dart',
    ).readAsStringSync();
    expect(battle, contains('INIT.'));
    expect(battle, contains("uiTextForLanguage('USA', 'USE')"));

    final encounter = File(
      'lib/screens/tools/encounter_generator_screen.dart',
    ).readAsStringSync();
    expect(encounter, contains('PokemonHabitatService.englishLabel(habitat)'));
  });
}
""",
        encoding='utf-8',
    )


def main() -> None:
    if MARKER_PATH.exists():
        print('Round 3 localization already applied.')
        return

    configured = json.loads(TRANSLATIONS_PATH.read_text(encoding='utf-8'))
    special = {'lib/widgets/pokemon/egg_asset_image.dart'}
    import_paths = {
        'lib/screens/breeding/breeding_screen.dart': "import '../../localization/ui_text.dart';",
        'lib/widgets/breeding/breeder_trait_dialogs.dart': "import '../../localization/ui_text.dart';",
        'lib/models/breeding_candidate.dart': "import '../localization/ui_text.dart';",
        'lib/models/breeding_egg.dart': "import '../localization/ui_text.dart';",
    }
    for raw_path, translations in configured.items():
        if raw_path in special:
            continue
        path = Path(raw_path)
        import_line = import_paths.get(raw_path)
        if import_line:
            ensure_import(path, import_line)
        localize_file(path, translations)

    localize_breeding_service()
    localize_habitats()
    localize_battle_companion()
    localize_miscellaneous()
    write_focused_test()

    for path in (
        Path('lib/screens/breeding/breeding_screen.dart'),
        Path('lib/widgets/breeding/breeder_trait_dialogs.dart'),
    ):
        remove_invalid_const_widgets(path)

    MARKER_PATH.write_text('applied\n', encoding='utf-8')
    print('Applied English UI residual fixes round 3.')


if __name__ == '__main__':
    main()
