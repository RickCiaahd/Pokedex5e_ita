from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise SystemExit(f'Pattern non trovato: {label}')
    return text.replace(old, new, 1)


battle_path = Path('lib/screens/battle/battle_screen.dart')
battle = battle_path.read_text(encoding='utf-8')
battle = replace_once(
    battle,
    """  void _nextRound(_BattleData data) {\n    setState(() {\n      _statusMoment = BattleStatusMoment.turnStart;\n      _round += 1;\n      _turnIndex = 0;\n      _message = 'Round $_round iniziato.';\n    });\n    _scheduleSessionSave(data);\n  }\n\n""",
    '',
    'metodo _nextRound Battle Companion',
)
battle = replace_once(
    battle,
    """                  trainerInitiativeBonus: _trainerInitiativeBonus(data.profile),\n                  onNextRound: () => _nextRound(data),\n                  onEnd: () => _endBattle(data),\n""",
    """                  trainerInitiativeBonus: _trainerInitiativeBonus(data.profile),\n                  onEnd: () => _endBattle(data),\n""",
    'callback onNextRound BattleHeader',
)
battle = replace_once(
    battle,
    """    required this.trainerInitiativeBonus,\n    required this.onNextRound,\n    required this.onEnd,\n""",
    """    required this.trainerInitiativeBonus,\n    required this.onEnd,\n""",
    'costruttore BattleHeader',
)
battle = replace_once(
    battle,
    """  final int trainerInitiativeBonus;\n  final VoidCallback onNextRound;\n  final VoidCallback onEnd;\n""",
    """  final int trainerInitiativeBonus;\n  final VoidCallback onEnd;\n""",
    'campi BattleHeader',
)
battle = replace_once(
    battle,
    """            Row(\n              children: [\n                Expanded(\n                  child: FilledButton.icon(\n                    onPressed: onNextRound,\n                    icon: const Icon(Icons.skip_next),\n                    label: const Text('NUOVO ROUND'),\n                  ),\n                ),\n                const SizedBox(width: 8),\n                Expanded(\n                  child: OutlinedButton.icon(\n                    onPressed: onEnd,\n                    icon: const Icon(Icons.stop_circle_outlined),\n                    label: const Text('TERMINA'),\n                  ),\n                ),\n              ],\n            ),\n""",
    """            OutlinedButton.icon(\n              onPressed: onEnd,\n              icon: const Icon(Icons.stop_circle_outlined),\n              label: const Text('TERMINA'),\n            ),\n""",
    'pulsante NUOVO ROUND Battle Companion',
)
battle_path.write_text(battle, encoding='utf-8')

npc_path = Path('lib/screens/battle/npc_battle_screen.dart')
npc = npc_path.read_text(encoding='utf-8')
npc = replace_once(
    npc,
    """  Future<void> _nextRound() async {\n    setState(() => _statusMoment = BattleStatusMoment.turnStart);\n    await _commit(_session.copyWith(round: _session.round + 1, turnIndex: 0));\n  }\n\n""",
    '',
    'metodo _nextRound Fight del Master',
)
npc = replace_once(
    npc,
    """            activePokemonCount: activeCount,\n            onNextRound: _nextRound,\n            onEnd: _endFight,\n""",
    """            activePokemonCount: activeCount,\n            onEnd: _endFight,\n""",
    'callback onNextRound FightHeader',
)
npc = replace_once(
    npc,
    """          const SizedBox(height: 12),\n          FilledButton.icon(\n            onPressed: _isWorking ? null : _nextTurn,\n            icon: const Icon(Icons.skip_next),\n            label: const Text('PROSSIMO TURNO'),\n          ),\n""",
    '',
    'secondo pulsante PROSSIMO TURNO',
)
npc = replace_once(
    npc,
    """    required this.activePokemonCount,\n    required this.onNextRound,\n    required this.onEnd,\n""",
    """    required this.activePokemonCount,\n    required this.onEnd,\n""",
    'costruttore FightHeader',
)
npc = replace_once(
    npc,
    """  final int activePokemonCount;\n  final VoidCallback onNextRound;\n  final VoidCallback onEnd;\n""",
    """  final int activePokemonCount;\n  final VoidCallback onEnd;\n""",
    'campi FightHeader',
)
npc = replace_once(
    npc,
    """                IconButton(\n                  onPressed: onNextRound,\n                  tooltip: 'Round successivo',\n                  icon: Icon(\n                    Icons.add_circle_outline,\n                    color: colors.onPrimaryContainer,\n                  ),\n                ),\n""",
    '',
    'icona Round successivo',
)
npc_path.write_text(npc, encoding='utf-8')

changelog_path = Path('CHANGELOG.md')
changelog = changelog_path.read_text(encoding='utf-8')
needle = '- editor delle probabilità delle raccolte corretto per consentire la digitazione di percentuali a più cifre senza perdere il focus.\n'
replacement = needle + '- controllo del combattimento semplificato: resta un solo pulsante `PROSSIMO TURNO`, che avanza automaticamente il round al termine dell’iniziativa.\n'
if replacement not in changelog:
    changelog = replace_once(changelog, needle, replacement, 'voce changelog')
changelog_path.write_text(changelog, encoding='utf-8')

Path('test/battle_round_controls_test.dart').write_text("""import 'dart:io';\n\nimport 'package:flutter_test/flutter_test.dart';\n\nvoid main() {\n  test('ogni fight espone un solo controllo Prossimo turno', () {\n    for (final path in [\n      'lib/screens/battle/battle_screen.dart',\n      'lib/screens/battle/npc_battle_screen.dart',\n    ]) {\n      final source = File(path).readAsStringSync();\n      expect('PROSSIMO TURNO'.allMatches(source).length, 1, reason: path);\n      expect(source, isNot(contains('NUOVO ROUND')), reason: path);\n      expect(source, isNot(contains('onNextRound')), reason: path);\n      expect(source, isNot(contains('_nextRound(')), reason: path);\n    }\n  });\n}\n""", encoding='utf-8')
