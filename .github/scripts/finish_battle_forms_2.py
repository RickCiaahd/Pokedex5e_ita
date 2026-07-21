from pathlib import Path

path = Path('lib/screens/battle/battle_screen.dart')
text = path.read_text(encoding='utf-8')

start = text.index('class _ActivePokemonCard extends StatelessWidget {')
end = text.index('class _ArmorClassBadge extends StatelessWidget {', start)
segment = text[start:end]


def replace_segment(old: str, new: str) -> None:
    global segment
    count = segment.count(old)
    if count != 1:
        raise SystemExit(
            f'Active card: expected one match, found {count}: {old[:120]!r}'
        )
    segment = segment.replace(old, new, 1)


replace_segment(
    "    required this.currentHp,\n"
    "    required this.maxHp,\n"
    "    required this.nonVolatileStatus,",
    "    required this.currentHp,\n"
    "    required this.maxHp,\n"
    "    required this.temporaryHp,\n"
    "    required this.temporaryHpRule,\n"
    "    required this.temporaryHpEnabled,\n"
    "    required this.nonVolatileStatus,",
)

replace_segment(
    "    required this.onUseHeldBerry,\n"
    "    required this.onOpenBag,\n"
    "    required this.onChangeForm,",
    "    required this.onUseHeldBerry,\n"
    "    required this.onOpenBag,\n"
    "    required this.onToggleTemporaryHp,\n"
    "    required this.onChangeForm,",
)

replace_segment(
    "  final Pokemon pokemon;\n"
    "  final TeamSlot slot;",
    "  final Pokemon pokemon;\n"
    "  final Pokemon imagePokemon;\n"
    "  final TeamSlot slot;",
)

replace_segment(
    "  final int currentHp;\n"
    "  final int maxHp;\n"
    "  final String? nonVolatileStatus;",
    "  final int currentHp;\n"
    "  final int maxHp;\n"
    "  final int temporaryHp;\n"
    "  final BattleTemporaryHpRule? temporaryHpRule;\n"
    "  final bool temporaryHpEnabled;\n"
    "  final String? nonVolatileStatus;",
)

replace_segment(
    "  final VoidCallback? onUseHeldBerry;\n"
    "  final VoidCallback onOpenBag;\n"
    "  final VoidCallback? onChangeForm;",
    "  final VoidCallback? onUseHeldBerry;\n"
    "  final VoidCallback onOpenBag;\n"
    "  final ValueChanged<bool>? onToggleTemporaryHp;\n"
    "  final VoidCallback? onChangeForm;",
)

replace_segment(
    "                PokemonAssetImage(\n"
    "                  pokemon: pokemon,\n"
    "                  useLargeArtwork: true,",
    "                PokemonAssetImage(\n"
    "                  pokemon: imagePokemon,\n"
    "                  useLargeArtwork: true,",
)

replace_segment(
    "                      'HP $currentHp/$maxHp',",
    "                      temporaryHp > 0\n"
    "                          ? 'HP $currentHp/$maxHp  +$temporaryHp TEMP'\n"
    "                          : 'HP $currentHp/$maxHp',",
)

replace_segment(
    "            const SizedBox(height: 10),\n"
    "            _StatusPanel(\n"
    "              nonVolatileStatus: nonVolatileStatus,",
    "            if (temporaryHpRule != null) ...[\n"
    "              const SizedBox(height: 10),\n"
    "              _TemporaryHpPanel(\n"
    "                rule: temporaryHpRule!,\n"
    "                currentHp: temporaryHp,\n"
    "                enabled: temporaryHpEnabled,\n"
    "                onChanged: onToggleTemporaryHp,\n"
    "              ),\n"
    "            ],\n"
    "            const SizedBox(height: 10),\n"
    "            _StatusPanel(\n"
    "              nonVolatileStatus: nonVolatileStatus,",
)

panel = """class _TemporaryHpPanel extends StatelessWidget {
  const _TemporaryHpPanel({
    required this.rule,
    required this.currentHp,
    required this.enabled,
    required this.onChanged,
  });

  final BattleTemporaryHpRule rule;
  final int currentHp;
  final bool enabled;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.shield_moon_outlined),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${rule.label}: $currentHp PF temporanei',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    rule.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Switch(value: enabled, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

"""

text = text[:start] + segment + panel + text[end:]
path.write_text(text, encoding='utf-8')
