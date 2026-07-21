from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    text = file.read_text(encoding='utf-8')
    count = text.count(old)
    if count != 1:
        raise SystemExit(
            f'{path}: expected one match, found {count}: {old[:100]!r}'
        )
    file.write_text(text.replace(old, new, 1), encoding='utf-8')


detail = 'lib/screens/pokemon/pokemon_detail_screen_legacy.dart'

replace_once(
    detail,
    "                          _TraitsView(\n                            pokemon: pokemon,",
    "                          _TraitsView(\n"
    "                            pokemon: pokemon,\n"
    "                            basePokemon: _basePokemon,",
)

replace_once(
    detail,
    "  const _Header({\n    required this.pokemon,\n    required this.slot,",
    "  const _Header({\n"
    "    required this.pokemon,\n"
    "    required this.imagePokemon,\n"
    "    required this.slot,",
)

replace_once(
    detail,
    "  final Pokemon pokemon;\n  final TeamSlot? slot;\n  final int level;",
    "  final Pokemon pokemon;\n"
    "  final Pokemon imagePokemon;\n"
    "  final TeamSlot? slot;\n"
    "  final int level;",
)

replace_once(
    detail,
    "                            pokemon: pokemon,\n                            formName: slot?.formName,",
    "                            pokemon: imagePokemon,\n"
    "                            formName: slot?.formName,",
)

replace_once(
    detail,
    "  Widget build(BuildContext context) {\n    final feats = slot?.feats ?? const <String>[];",
    "  Widget build(BuildContext context) {\n"
    "    String? lookup(Map<String, String> values, String reference) {\n"
    "      final direct = values[reference];\n"
    "      if (direct != null) return direct;\n"
    "      final key = _itemReferenceKey(reference);\n"
    "      for (final entry in values.entries) {\n"
    "        if (_itemReferenceKey(entry.key) == key) return entry.value;\n"
    "      }\n"
    "      return null;\n"
    "    }\n\n"
    "    final feats = slot?.feats ?? const <String>[];",
)

replace_once(
    detail,
    "            title: abilityDisplayNames[ability] ?? ability,\n"
    "            child: Text(\n"
    "              abilityDescriptions[ability] ?? 'Descrizione non disponibile.',\n"
    "            ),",
    "            title: lookup(abilityDisplayNames, ability) ?? ability,\n"
    "            child: Text(\n"
    "              lookup(abilityDescriptions, ability) ??\n"
    "                  'Descrizione non disponibile.',\n"
    "            ),",
)

replace_once(
    detail,
    "  const _TraitsView({\n    required this.pokemon,\n    required this.slot,",
    "  const _TraitsView({\n"
    "    required this.pokemon,\n"
    "    required this.basePokemon,\n"
    "    required this.slot,",
)

replace_once(
    detail,
    "  final Pokemon pokemon;\n  final TeamSlot? slot;\n  final Map<String, int> attributes;",
    "  final Pokemon pokemon;\n"
    "  final Pokemon basePokemon;\n"
    "  final TeamSlot? slot;\n"
    "  final Map<String, int> attributes;",
)

replace_once(
    detail,
    "              _InfoRow(label: 'Forma', value: slot?.formName ?? '-'),",
    "              _InfoRow(\n"
    "                label: 'Forma',\n"
    "                value: slot == null\n"
    "                    ? '-'\n"
    "                    : BattleFormChangeService.supports(basePokemon)\n"
    "                    ? BattleFormChangeService.formLabel(\n"
    "                        basePokemon,\n"
    "                        slot?.formName,\n"
    "                      )\n"
    "                    : slot?.formName ?? '-',\n"
    "              ),",
)
