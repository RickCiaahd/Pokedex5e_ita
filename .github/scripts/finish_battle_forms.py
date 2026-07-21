from pathlib import Path

path = Path('lib/screens/battle/battle_screen.dart')


def replace_once(old: str, new: str) -> None:
    text = path.read_text(encoding='utf-8')
    count = text.count(old)
    if count != 1:
        raise SystemExit(
            f'Expected exactly one match, found {count}: {old[:140]!r}'
        )
    path.write_text(text.replace(old, new, 1), encoding='utf-8')


replace_once(
    "import '../../services/battle_temporary_hp_service.dart';\n"
    "import '../../services/battle_temporary_hp_service.dart';",
    "import '../../services/battle_temporary_hp_service.dart';",
)

replace_once(
    "                              pokemon,\n"
    "                              activeSlot,\n"
    "                              effectiveFormName,\n"
    "                            ),",
    "                              pokemon,\n"
    "                              activeSlot,\n"
    "                              basePokemon,\n"
    "                              effectiveFormName,\n"
    "                            ),",
)

replace_once(
    "                        pokemon: pokemonForSlot(slot),\n"
    "                        formName: formNameForSlot(slot),",
    "                        pokemon: pokemonForSlot(slot),\n"
    "                        imagePokemon: imagePokemonForSlot(slot),\n"
    "                        formName: formNameForSlot(slot),",
)

replace_once(
    "                PokemonAssetImage(\n"
    "                  pokemon: pokemon,\n"
    "                  size: 40,",
    "                PokemonAssetImage(\n"
    "                  pokemon: imagePokemon ?? pokemon,\n"
    "                  size: 40,",
)

replace_once(
    "  const _ActivePokemonCard({\n"
    "    required this.pokemon,\n"
    "    required this.slot,",
    "  const _ActivePokemonCard({\n"
    "    required this.pokemon,\n"
    "    required this.imagePokemon,\n"
    "    required this.slot,",
)

replace_once(
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

replace_once(
    "    required this.onUseHeldBerry,\n"
    "    required this.onOpenBag,\n"
    "    required this.onChangeForm,",
    "    required this.onUseHeldBerry,\n"
    "    required this.onOpenBag,\n"
    "    required this.onToggleTemporaryHp,\n"
    "    required this.onChangeForm,",
)

replace_once(
    "  final Pokemon pokemon;\n"
    "  final TeamSlot slot;",
    "  final Pokemon pokemon;\n"
    "  final Pokemon imagePokemon;\n"
    "  final TeamSlot slot;",
)

replace_once(
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

replace_once(
    "  final VoidCallback? onUseHeldBerry;\n"
    "  final VoidCallback onOpenBag;\n"
    "  final VoidCallback? onChangeForm;",
    "  final VoidCallback? onUseHeldBerry;\n"
    "  final VoidCallback onOpenBag;\n"
    "  final ValueChanged<bool>? onToggleTemporaryHp;\n"
    "  final VoidCallback? onChangeForm;",
)

replace_once(
    "                PokemonAssetImage(\n"
    "                  pokemon: pokemon,\n"
    "                  useLargeArtwork: true,",
    "                PokemonAssetImage(\n"
    "                  pokemon: imagePokemon,\n"
    "                  useLargeArtwork: true,",
)

replace_once(
    "                      'HP $currentHp/$maxHp',",
    "                      temporaryHp > 0\n"
    "                          ? 'HP $currentHp/$maxHp  +$temporaryHp TEMP'\n"
    "                          : 'HP $currentHp/$maxHp',",
)

replace_once(
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

replace_once(
    "class _ArmorClassBadge extends StatelessWidget {",
    "class _TemporaryHpPanel extends StatelessWidget {\n"
    "  const _TemporaryHpPanel({\n"
    "    required this.rule,\n"
    "    required this.currentHp,\n"
    "    required this.enabled,\n"
    "    required this.onChanged,\n"
    "  });\n\n"
    "  final BattleTemporaryHpRule rule;\n"
    "  final int currentHp;\n"
    "  final bool enabled;\n"
    "  final ValueChanged<bool>? onChanged;\n\n"
    "  @override\n"
    "  Widget build(BuildContext context) {\n"
    "    return DecoratedBox(\n"
    "      decoration: BoxDecoration(\n"
    "        color: Theme.of(context).colorScheme.secondaryContainer,\n"
    "        borderRadius: BorderRadius.circular(10),\n"
    "      ),\n"
    "      child: Padding(\n"
    "        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),\n"
    "        child: Row(\n"
    "          children: [\n"
    "            const Icon(Icons.shield_moon_outlined),\n"
    "            const SizedBox(width: 8),\n"
    "            Expanded(\n"
    "              child: Column(\n"
    "                crossAxisAlignment: CrossAxisAlignment.start,\n"
    "                children: [\n"
    "                  Text(\n"
    "                    '${rule.label}: $currentHp PF temporanei',\n"
    "                    style: const TextStyle(fontWeight: FontWeight.w800),\n"
    "                  ),\n"
    "                  Text(\n"
    "                    rule.description,\n"
    "                    style: Theme.of(context).textTheme.bodySmall,\n"
    "                  ),\n"
    "                ],\n"
    "              ),\n"
    "            ),\n"
    "            Switch(value: enabled, onChanged: onChanged),\n"
    "          ],\n"
    "        ),\n"
    "      ),\n"
    "    );\n"
    "  }\n"
    "}\n\n"
    "class _ArmorClassBadge extends StatelessWidget {",
)
