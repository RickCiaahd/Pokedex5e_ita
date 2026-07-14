from pathlib import Path


battle_path = Path('lib/screens/battle/battle_screen.dart')
text = battle_path.read_text(encoding='utf-8')

replacements = [
    (
        """          final attributes = _attributeScores(pokemon, activeSlot);\n\n          return RefreshIndicator(""",
        """          final attributes = _attributeScores(pokemon, activeSlot);\n          final baseArmorClass = BattleEnvironmentService.baseArmorClass(\n            pokemon,\n            activeSlot,\n          );\n          final effectiveArmorClass =\n              baseArmorClass +\n              BattleEnvironmentService.armorClassBonus(\n                pokemon: pokemon,\n                slot: activeSlot,\n                environment: _environment,\n              );\n\n          return RefreshIndicator(""",
    ),
    (
        """                  level: _levelForSlot(activeSlot),\n                  currentHp: _currentHpFor(activeSlot, pokemon),""",
        """                  level: _levelForSlot(activeSlot),\n                  baseArmorClass: baseArmorClass,\n                  effectiveArmorClass: effectiveArmorClass,\n                  currentHp: _currentHpFor(activeSlot, pokemon),""",
    ),
    (
        """    required this.level,\n    required this.currentHp,""",
        """    required this.level,\n    required this.baseArmorClass,\n    required this.effectiveArmorClass,\n    required this.currentHp,""",
    ),
    (
        """  final int level;\n  final int currentHp;""",
        """  final int level;\n  final int baseArmorClass;\n  final int effectiveArmorClass;\n  final int currentHp;""",
    ),
    (
        """                      Text(\n                        displayName.toUpperCase(),\n                        maxLines: 1,\n                        overflow: TextOverflow.ellipsis,\n                        style: Theme.of(context).textTheme.titleLarge?.copyWith(\n                          fontWeight: FontWeight.w900,\n                        ),\n                      ),""",
        """                      Row(\n                        children: [\n                          Expanded(\n                            child: Text(\n                              displayName.toUpperCase(),\n                              maxLines: 1,\n                              overflow: TextOverflow.ellipsis,\n                              style: Theme.of(context)\n                                  .textTheme\n                                  .titleLarge\n                                  ?.copyWith(fontWeight: FontWeight.w900),\n                            ),\n                          ),\n                          const SizedBox(width: 8),\n                          _ArmorClassBadge(\n                            baseArmorClass: baseArmorClass,\n                            effectiveArmorClass: effectiveArmorClass,\n                          ),\n                        ],\n                      ),""",
    ),
]

for old, new in replacements:
    occurrences = text.count(old)
    if occurrences != 1:
        raise SystemExit(
            f'Expected one occurrence, found {occurrences}: {old[:80]!r}'
        )
    text = text.replace(old, new)

marker = "\nclass _StatusPanel extends StatelessWidget {"
badge = r'''

class _ArmorClassBadge extends StatelessWidget {
  const _ArmorClassBadge({
    required this.baseArmorClass,
    required this.effectiveArmorClass,
  });

  final int baseArmorClass;
  final int effectiveArmorClass;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bonus = effectiveArmorClass - baseArmorClass;
    final hasBonus = bonus != 0;
    final signedBonus = bonus > 0 ? '+$bonus' : bonus.toString();

    return Tooltip(
      message: hasBonus
          ? 'Classe Armatura: $baseArmorClass $signedBonus'
          : 'Classe Armatura',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: hasBonus
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: hasBonus ? colorScheme.primary : colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            hasBonus
                ? 'CA $effectiveArmorClass ($signedBonus)'
                : 'CA $effectiveArmorClass',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
'''

if text.count(marker) != 1:
    raise SystemExit('Status panel marker not found exactly once')
text = text.replace(marker, badge + marker)
battle_path.write_text(text, encoding='utf-8')

changelog = Path('CHANGELOG.md')
content = changelog.read_text(encoding='utf-8')
old = """- lo sprite personalizzato dell’uovo viene ora usato nella Squadra, nel riepilogo del PC e nelle schede di incubazione.\n\n### In programma"""
new = """- lo sprite personalizzato dell’uovo viene ora usato nella Squadra, nel riepilogo del PC e nelle schede di incubazione;\n- la Classe Armatura effettiva del Pokémon è ora visibile accanto al nome nel Battle Companion, con l’eventuale bonus ambientale evidenziato.\n\n### In programma"""
if content.count(old) != 1:
    raise SystemExit(f'Changelog marker count: {content.count(old)}')
changelog.write_text(content.replace(old, new), encoding='utf-8')
