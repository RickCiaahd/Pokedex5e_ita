from pathlib import Path
import re


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f'{label}: expected 1 exact match, found {count}')
    return text.replace(old, new, 1)


def regex_once(text: str, pattern: str, replacement: str, label: str) -> str:
    updated, count = re.subn(pattern, replacement, text, count=1, flags=re.S)
    if count != 1:
        raise RuntimeError(f'{label}: expected 1 regex match, found {count}')
    return updated


battle_path = Path('lib/screens/battle/battle_screen.dart')
text = battle_path.read_text(encoding='utf-8')

text = replace_once(
    text,
    "  final List<BattleInitiativeEntry> _initiativeEntries = [];\n",
    "",
    'remove initiative entries state',
)
text = replace_once(
    text,
    "  int _turnIndex = 0;\n",
    "",
    'remove initiative turn index state',
)

text = replace_once(
    text,
    """    GuidedTourStepData(
      targetKey: _initiativeKey,
      icon: Icons.format_list_numbered,
      title: context.uiText('Iniziativa e turni', 'Initiative and turns'),
      description: context.uiText(
        'Aggiungi partecipanti, modifica l’ordine e usa il comando del turno successivo. Quando il giro termina, il round avanza automaticamente.',
        'Add participants, change the order and use the next-turn command. When the cycle ends, the round advances automatically.',
      ),
      fallbackScrollFraction: .16,
    ),
""",
    """    GuidedTourStepData(
      targetKey: _initiativeKey,
      icon: Icons.timelapse_outlined,
      title: context.uiText('Round personale', 'Personal round'),
      description: context.uiText(
        'Quando il Master comunica che torna il tuo turno, usa il pulsante per avanzare il round personale. Non devi gestire l’ordine completo dell’iniziativa.',
        'When the GM says your turn has come back, use the button to advance your personal round. You do not need to manage the full initiative order.',
      ),
      fallbackScrollFraction: .16,
    ),
""",
    'update round tour step',
)

text = replace_once(
    text,
    """    GuidedTourStepData(
      targetKey: _environmentKey,
      icon: Icons.public_outlined,
      title: context.uiText('Meteo e terreno', 'Weather and terrain'),
      description: context.uiText(
        'L’ambiente applica regole e modificatori a velocità, CA, tipi e danni. Puoi impostarlo manualmente o generare il meteo con il d100.',
        'The environment applies rules and modifiers to speed, AC, types and damage. Set it manually or roll weather with a d100.',
      ),
      fallbackScrollFraction: .30,
    ),
""",
    """    GuidedTourStepData(
      targetKey: _environmentKey,
      icon: Icons.public_outlined,
      title: context.uiText('Meteo e terreno', 'Weather and terrain'),
      description: context.uiText(
        'Registra il meteo e il terreno comunicati dal Master. Il Battle Companion applica al Pokémon i modificatori conosciuti, senza generare la scena al posto del Master.',
        'Record the weather and terrain communicated by the GM. The Battle Companion applies known modifiers to the Pokémon without generating the scene for the GM.',
      ),
      fallbackScrollFraction: .30,
    ),
""",
    'update environment tour step',
)

for old, label in [
    ("    _initiativeEntries.clear();\n", 'remove initiative clear'),
    ("    _turnIndex = 0;\n", 'remove turn index reset'),
    ("      _initiativeEntries.addAll(session.initiativeEntries);\n", 'remove initiative restore'),
]:
    text = replace_once(text, old, '', label)

text = replace_once(
    text,
    """      _turnIndex = _initiativeEntries.isEmpty
          ? 0
          : session.turnIndex.clamp(0, _initiativeEntries.length - 1).toInt();
""",
    "",
    'remove restored turn index',
)

text = replace_once(
    text,
    """    final activeSlot = _activeSlotFor(data);
    if (activeSlot != null) {
      _activeSlotIndex = activeSlot.slotIndex;
      final pokemon = _pokemonForSlot(data, activeSlot);
      if (pokemon != null) _ensureInitiative(data, activeSlot, pokemon);
    }
""",
    """    final activeSlot = _activeSlotFor(data);
    if (activeSlot != null) _activeSlotIndex = activeSlot.slotIndex;
""",
    'remove initiative setup for active pokemon',
)

text = replace_once(
    text,
    "        turnIndex: _turnIndex,\n",
    "        turnIndex: 0,\n",
    'save zero turn index',
)
text = replace_once(
    text,
    "        initiativeEntries: List<BattleInitiativeEntry>.from(_initiativeEntries),\n",
    "        initiativeEntries: const [],\n",
    'save empty initiative entries',
)

text = regex_once(
    text,
    r"\n  void _ensureInitiative\(.*?\n  Future<void> _editEnvironment",
    "\n  Future<void> _editEnvironment",
    'remove initiative helper methods',
)

text = regex_once(
    text,
    r"\n  void _rollEnvironmentWeather\(.*?\n  Future<void> _endBattle",
    """
  void _nextPlayerRound(_BattleData data) {
    setState(() {
      _statusMoment = BattleStatusMoment.turnStart;
      _round += 1;
      _environment = _environment.advanceRound();
      _message = context.uiText(
        'Round $_round iniziato.',
        'Round $_round started.',
      );
    });
    _scheduleSessionSave(data);
  }

  Future<void> _endBattle""",
    'replace master-style trackers with personal round action',
)

text = replace_once(
    text,
    """            'Round, iniziativa, PP, PF temporanei, forme di battaglia, trasformazioni attive e status volatili verranno rimossi. Gli utilizzi di Mega/Z/Dynamax/Tera resteranno consumati fino al prossimo riposo lungo.',
            'Rounds, initiative, PP, temporary HP, battle forms, active transformations and volatile conditions will be cleared. Mega/Z/Dynamax/Tera uses remain spent until the next long rest.',
""",
    """            'Round personale, PP, PF temporanei, forme di battaglia, trasformazioni attive e status volatili verranno rimossi. Gli utilizzi di Mega/Z/Dynamax/Tera resteranno consumati fino al prossimo riposo lungo.',
            'Personal round, PP, temporary HP, battle forms, active transformations and volatile conditions will be cleared. Mega/Z/Dynamax/Tera uses remain spent until the next long rest.',
""",
    'update end battle explanation',
)
text = replace_once(
    text,
    "    _initiativeEntries.clear();\n",
    "",
    'remove initiative clear on end battle',
)

text = replace_once(
    text,
    """  int _rollTrainerInitiative(UserProfile profile) {
    return _random.nextInt(20) + 1 + _trainerInitiativeBonus(profile);
  }

""",
    "",
    'remove trainer initiative roller',
)

text = replace_once(
    text,
    """                                  _BattleHeader(
                                    round: _round,
                                    profile: data.profile,
                                    trainerInitiativeBonus:
                                        _trainerInitiativeBonus(data.profile),
                                    onEnd: () => _endBattle(data),
                                  ),
""",
    """                                  KeyedSubtree(
                                    key: _initiativeKey,
                                    child: _BattleHeader(
                                      round: _round,
                                      profile: data.profile,
                                      trainerInitiativeBonus:
                                          _trainerInitiativeBonus(data.profile),
                                      onNextRound: () =>
                                          _nextPlayerRound(data),
                                      onEnd: () => _endBattle(data),
                                    ),
                                  ),
""",
    'wire personal round tracker',
)

text = regex_once(
    text,
    r"\n                            const SizedBox\(height: 12\),\n                            KeyedSubtree\(\n                              key: _initiativeKey,.*?\n                            \),(?=\n                            const SizedBox\(height: 12\),\n                            KeyedSubtree\(\n                              key: _environmentKey)",
    "",
    'remove full initiative tracker from layout',
)

text = replace_once(
    text,
    """                                onEdit: () => _editEnvironment(data),
                                onRollWeather: () =>
                                    _rollEnvironmentWeather(data),
                                onApplyWeatherDamage:
                                    BattleEnvironmentService.startTurnWeatherDamage(
                                          pokemon: pokemon,
                                          slot: activeSlot,
                                          environment: _environment,
                                        ) ==
                                        null
                                    ? null
                                    : () => _applyEnvironmentWeatherDamage(
                                        data,
                                        activeSlot,
                                      ),
""",
    """                                onEdit: () => _editEnvironment(data),
""",
    'simplify environment card wiring',
)

text = regex_once(
    text,
    r"class _InitiativeEntryInput \{.*?\n\}\n\n(?=class _StatusPickerResult)",
    "",
    'remove initiative dialog data class',
)

new_header = r'''class _BattleHeader extends StatelessWidget {
  const _BattleHeader({
    required this.round,
    required this.profile,
    required this.trainerInitiativeBonus,
    required this.onNextRound,
    required this.onEnd,
  });

  final int round;
  final UserProfile profile;
  final int trainerInitiativeBonus;
  final VoidCallback onNextRound;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'ROUND $round',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        Text(
          context.uiText(
            '${profile.name} · INIZ. ${trainerInitiativeBonus >= 0 ? '+' : ''}$trainerInitiativeBonus',
            '${profile.name} · INIT. ${trainerInitiativeBonus >= 0 ? '+' : ''}$trainerInitiativeBonus',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    final nextButton = FilledButton.icon(
      onPressed: onNextRound,
      icon: const Icon(Icons.navigate_next),
      label: Text(
        context.uiText('PROSSIMO MIO TURNO', 'NEXT MY TURN'),
        maxLines: 1,
      ),
    );

    final endButton = IconButton(
      tooltip: context.uiText('Termina battaglia', 'End battle'),
      onPressed: onEnd,
      icon: const Icon(Icons.stop_circle_outlined),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 460) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: info),
                      endButton,
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(width: double.infinity, child: nextButton),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: info),
                nextButton,
                const SizedBox(width: 4),
                endButton,
              ],
            );
          },
        ),
      ),
    );
  }
}

'''

text = regex_once(
    text,
    r"class _BattleHeader extends StatelessWidget \{.*?\n\}\n\n(?=class _PartyBar)",
    new_header,
    'replace battle header with personal round tracker',
)

text = regex_once(
    text,
    r"class _InitiativeTracker extends StatelessWidget \{.*?\n(?=class _BattleFormPickerSheet)",
    "",
    'remove full initiative widgets',
)

battle_path.write_text(text, encoding='utf-8')


print('Battle Companion round tracker applied successfully.')
