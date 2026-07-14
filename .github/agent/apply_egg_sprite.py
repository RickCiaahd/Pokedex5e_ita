from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f'{label}: attesa 1 occorrenza, trovate {count}')
    return text.replace(old, new, 1)


team = Path('lib/screens/team/team_selection_screen.dart')
text = team.read_text(encoding='utf-8')
text = replace_once(
    text,
    "import '../../widgets/pokemon/pokemon_asset_image.dart';",
    "import '../../widgets/pokemon/egg_asset_image.dart';\nimport '../../widgets/pokemon/pokemon_asset_image.dart';",
    'import squadra',
)
text = replace_once(
    text,
    '? const Icon(Icons.egg_alt_outlined, size: 34)',
    '? const EggAssetImage(size: 46)',
    'sprite squadra',
)
team.write_text(text, encoding='utf-8')


pc = Path('lib/screens/pc/pokemon_pc_screen.dart')
text = pc.read_text(encoding='utf-8')
text = replace_once(
    text,
    "import '../../widgets/pokemon/pokemon_asset_image.dart';",
    "import '../../widgets/pokemon/egg_asset_image.dart';\nimport '../../widgets/pokemon/pokemon_asset_image.dart';",
    'import PC',
)
text = replace_once(
    text,
    """                slot.isEgg
                    ? CircleAvatar(
                        radius: spriteSize / 2,
                        backgroundColor: colorScheme.tertiaryContainer,
                        child: const Icon(Icons.egg_alt_outlined),
                      )""",
    """                slot.isEgg
                    ? EggAssetImage(size: spriteSize)""",
    'sprite PC',
)
pc.write_text(text, encoding='utf-8')


breeding = Path('lib/screens/breeding/breeding_screen.dart')
text = breeding.read_text(encoding='utf-8')
text = replace_once(
    text,
    "import '../../widgets/pokemon/pokemon_asset_image.dart';",
    "import '../../widgets/pokemon/egg_asset_image.dart';",
    'import allevamento',
)
text = replace_once(
    text,
    """                if (pokemon != null)
                  PokemonAssetImage(
                    pokemon: pokemon!,
                    formName: egg.formName,
                    size: 64,
                  )
                else
                  const SizedBox(
                    width: 64,
                    height: 64,
                    child: Icon(Icons.egg_outlined, size: 48),
                  ),""",
    """                const EggAssetImage(size: 64),""",
    'sprite allevamento',
)
breeding.write_text(text, encoding='utf-8')


changelog = Path('CHANGELOG.md')
text = changelog.read_text(encoding='utf-8')
anchor = '- la schiusa considera soltanto i Pokéslot sbloccati: con tutti gli slot disponibili occupati il Pokémon viene depositato nel PC, e gli esemplari finiti in slot bloccati vengono recuperati automaticamente.'
addition = '- lo sprite personalizzato dell’uovo viene ora usato nella Squadra, nel riepilogo del PC e nelle schede di incubazione.'
if addition not in text:
    text = replace_once(text, anchor, f'{anchor}\n{addition}', 'changelog')
changelog.write_text(text, encoding='utf-8')
