# Applies the last cleanup before merging the NPC Master fight.
from pathlib import Path


def replace_once(source: str, old: str, new: str, label: str) -> str:
    count = source.count(old)
    if count == 0:
        return source
    if count != 1:
        raise RuntimeError(f'{label}: expected at most one match, found {count}')
    return source.replace(old, new, 1)


model = Path('lib/models/master_battle_session.dart')
source = model.read_text(encoding='utf-8')
source = replace_once(
    source,
    '    while (active.length > safeLimit) active.remove(active.last);\n',
    '    while (active.length > safeLimit) {\n      active.remove(active.last);\n    }\n',
    'active set normalization',
)
model.write_text(source, encoding='utf-8')

battle = Path('lib/screens/battle/npc_battle_screen.dart')
source = battle.read_text(encoding='utf-8')
source = replace_once(
    source,
    '    final pokemon = generated.pokemon;\n',
    '',
    'unused generated pokemon',
)
source = replace_once(
    source,
    '''    final damage = move?.damageForLevel(level)?.label;
    final details = [
      if (move != null) move!.type,
      if (damage != null) damage,
      if (move != null && move!.range != '-') move!.range,
      if (move != null && move!.save != null) 'TS ${move!.save}',
    ].join(' · ');
''',
    '''    final damage = move?.damageForLevel(level)?.label;
    final details = <String?>[
      move?.type,
      damage,
      move?.range == '-' ? null : move?.range,
      move?.save == null ? null : 'TS ${move!.save}',
    ].whereType<String>().join(' · ');
''',
    'move details',
)
source = replace_once(
    source,
    '  late Set<String> _volatile = {...widget.volatile};\n',
    '  late final Set<String> _volatile = {...widget.volatile};\n',
    'volatile status set',
)
source = replace_once(
    source,
    '''            items: const [
              DropdownMenuItem<String?>(value: null, child: Text('Nessuno')),
              for (final status in _nonVolatileStatuses)
                DropdownMenuItem<String?>(value: status, child: Text(status)),
            ],
''',
    '''            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Nessuno'),
              ),
              for (final status in _nonVolatileStatuses)
                DropdownMenuItem<String?>(value: status, child: Text(status)),
            ],
''',
    'status dropdown items',
)
battle.write_text(source, encoding='utf-8')

library = Path('lib/screens/tools/npc_trainer_library_screen.dart')
source = library.read_text(encoding='utf-8')
source = replace_once(
    source,
    "import '../../models/master_battle_session.dart';\n",
    '',
    'unused master battle import',
)
source = replace_once(
    source,
    '''      if (replace != true) return;
    }

    final activeCounts = await showDialog<Map<String, int>>(
''',
    '''      if (replace != true) return;
      if (!mounted) return;
    }

    final activeCounts = await showDialog<Map<String, int>>(
''',
    'mounted guard',
)
library.write_text(source, encoding='utf-8')

for relative in [
    'tool/npc-master-analyze.txt',
    'tool/npc-master-tests.txt',
    'tool/npc-master-full-tests.txt',
]:
    path = Path(relative)
    if path.exists():
        path.unlink()
