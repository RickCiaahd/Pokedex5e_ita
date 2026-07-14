from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f'{label}: attesa 1 occorrenza, trovate {count}')
    return text.replace(old, new, 1)


path = Path('lib/screens/battle/battle_screen.dart')
text = path.read_text(encoding='utf-8')

text = replace_once(
    text,
    "import '../../widgets/battle/battle_status_assistance_card.dart';\n",
    "import '../../widgets/battle/battle_status_assistance_card.dart';\n"
    "import '../../widgets/battle/pokemon_battle_attributes_card.dart';\n",
    'import scheda caratteristiche',
)

text = replace_once(
    text,
    "          final passiveNotes = TrainerPathPassiveService.passiveNotes(\n"
    "            profile: data.profile,\n"
    "            pokemon: pokemon,\n"
    "            slot: activeSlot,\n"
    "          );\n\n"
    "          return RefreshIndicator(",
    "          final passiveNotes = TrainerPathPassiveService.passiveNotes(\n"
    "            profile: data.profile,\n"
    "            pokemon: pokemon,\n"
    "            slot: activeSlot,\n"
    "          );\n"
    "          final attributes = _attributeScores(pokemon, activeSlot);\n\n"
    "          return RefreshIndicator(",
    'calcolo caratteristiche effettive',
)

text = replace_once(
    text,
    "                BattleStatusAssistanceCard(\n"
    "                  key: ValueKey('player-status-${activeSlot.slotIndex}'),\n"
    "                  pokemonName: _displayName(activeSlot, pokemon),\n"
    "                  nonVolatileStatus: _nonVolatileStatusFor(activeSlot),\n"
    "                  volatileStatuses: _volatileStatusesFor(activeSlot),\n"
    "                  selectedMoment: _statusMoment,\n"
    "                  onMomentChanged: (moment) {\n"
    "                    setState(() => _statusMoment = moment);\n"
    "                  },\n"
    "                ),\n"
    "                const SizedBox(height: 12),\n"
    "                Text(\n"
    "                  'MOSSE DA COMBATTIMENTO',",
    "                BattleStatusAssistanceCard(\n"
    "                  key: ValueKey('player-status-${activeSlot.slotIndex}'),\n"
    "                  pokemonName: _displayName(activeSlot, pokemon),\n"
    "                  nonVolatileStatus: _nonVolatileStatusFor(activeSlot),\n"
    "                  volatileStatuses: _volatileStatusesFor(activeSlot),\n"
    "                  selectedMoment: _statusMoment,\n"
    "                  onMomentChanged: (moment) {\n"
    "                    setState(() => _statusMoment = moment);\n"
    "                  },\n"
    "                ),\n"
    "                const SizedBox(height: 12),\n"
    "                PokemonBattleAttributesCard(attributes: attributes),\n"
    "                const SizedBox(height: 12),\n"
    "                Text(\n"
    "                  'MOSSE DA COMBATTIMENTO',",
    'scheda sopra le mosse',
)

path.write_text(text, encoding='utf-8')
