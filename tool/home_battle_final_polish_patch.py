from pathlib import Path
import re


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise RuntimeError(f"Pattern non trovato: {label}")
    return text.replace(old, new, 1)


def sub_once(text: str, pattern: str, repl: str, label: str) -> str:
    updated, count = re.subn(pattern, repl, text, count=1, flags=re.S)
    if count != 1:
        raise RuntimeError(f"Pattern regex non trovato o ambiguo ({count}): {label}")
    return updated


home_path = Path('lib/screens/home/home_screen.dart')
home = home_path.read_text(encoding='utf-8')

home = replace_once(
    home,
    """                      _ProgressOverview(\n                        total: total,\n                        seen: seen,\n                        caught: caught,\n                      ),""",
    """                      _ProgressOverview(\n                        key: _pokedexKey,\n                        total: total,\n                        seen: seen,\n                        caught: caught,\n                        onTap: () async {\n                          await Navigator.of(context).push(\n                            MaterialPageRoute(\n                              builder: (_) => const PokedexScreen(),\n                            ),\n                          );\n                          await _loadDashboard();\n                        },\n                      ),""",
    'progress overview invocation',
)

home = sub_once(
    home,
    r"\n                      const SizedBox\(height: 20\),\n                      _HomeSectionTitle\(\n                        icon: Icons\.menu_book_outlined,.*?\n                      \),\n                      const SizedBox\(height: 24\),\n                      _HomeSectionTitle\(\n                        key: _masterSectionKey,",
    """
                      const SizedBox(height: 24),
                      _HomeSectionTitle(
                        key: _masterSectionKey,""",
    'remove redundant consultation section',
)

home = sub_once(
    home,
    r"class _ProgressOverview extends StatelessWidget \{.*?\n\}\n\nclass _ProgressStat",
    """class _ProgressOverview extends StatelessWidget {
  const _ProgressOverview({
    super.key,
    required this.total,
    required this.seen,
    required this.caught,
    required this.onTap,
  });

  final int total;
  final int seen;
  final int caught;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final semanticLabel =
        '${l10n.pokedexProgressTitle}. '
        '${l10n.seenLabel} $seen/$total. '
        '${l10n.caughtLabel} $caught/$total. '
        '${l10n.homeOpenPokedexTitle}';

    return Semantics(
      button: true,
      onTap: onTap,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.pokedexProgressTitle,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: total == 0 ? 0 : caught / total,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ProgressStat(
                          label: l10n.seenLabel,
                          value: '$seen/$total',
                        ),
                      ),
                      Expanded(
                        child: _ProgressStat(
                          label: l10n.caughtLabel,
                          value: '$caught/$total',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressStat""",
    'interactive progress overview class',
)

home_path.write_text(home, encoding='utf-8')

battle_path = Path('lib/screens/battle/battle_screen.dart')
battle = battle_path.read_text(encoding='utf-8')

battle = sub_once(
    battle,
    r"                            KeyedSubtree\(\n                              key: _battleHeaderKey,.*?\n                            const SizedBox\(height: 12\),\n                            KeyedSubtree\(\n                              key: _activePokemonKey,",
    """                            KeyedSubtree(
                              key: _battleHeaderKey,
                              child: _PartyBar(
                                headerKey: _initiativeKey,
                                round: _round,
                                trainerInitiativeBonus:
                                    _trainerInitiativeBonus(data.profile),
                                onNextRound: () => _nextPlayerRound(data),
                                onEnd: () => _endBattle(data),
                                slots: data.occupiedSlots,
                                activeSlot: activeSlot,
                                pokemonForSlot: (slot) =>
                                    _pokemonForSlot(data, slot),
                                imagePokemonForSlot: (slot) =>
                                    data.pokemonById[slot.pokemonId],
                                formNameForSlot: _effectiveFormName,
                                transformationForSlot: (slot) =>
                                    _transformationBySlot[slot.slotIndex],
                                levelForSlot: _levelForSlot,
                                maxHpForSlot: (slot) {
                                  final slotPokemon = _pokemonForSlot(data, slot);
                                  return slotPokemon == null
                                      ? 0
                                      : _maxHpFor(slotPokemon, slot);
                                },
                                onSelected: (slotIndex) {
                                  if (slotIndex != activeSlot.slotIndex &&
                                      BattleTransformationService.isDynamaxLike(
                                        _transformationBySlot[
                                            activeSlot.slotIndex],
                                      )) {
                                    setState(() {
                                      _message = context.uiText(
                                        'Un Pokémon Dynamax/Gigamax non può essere richiamato o sostituito.',
                                        'A Dynamax/Gigamax Pokémon cannot be recalled or switched.',
                                      );
                                    });
                                    return;
                                  }
                                  setState(() {
                                    _activeSlotIndex = slotIndex;
                                    _statusMoment = BattleStatusMoment.turnStart;
                                    _message = null;
                                  });
                                  _scheduleSessionSave(data);
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            KeyedSubtree(
                              key: _activePokemonKey,""",
    'combine battle header and switch control',
)

battle = replace_once(
    battle,
    """                            const SizedBox(height: 12),\n                            PokemonBattleAttributesCard(attributes: attributes),\n""",
    "",
    'remove old attributes position',
)

battle = replace_once(
    battle,
    """                            const SizedBox(height: 12),\n                            KeyedSubtree(\n                              key: _movesKey,""",
    """                            const SizedBox(height: 12),\n                            PokemonBattleAttributesCard(attributes: attributes),\n                            const SizedBox(height: 12),\n                            KeyedSubtree(\n                              key: _movesKey,""",
    'move attributes before moves',
)

battle = sub_once(
    battle,
    r"class _BattleHeader extends StatelessWidget \{.*?\n\}\n\nclass _PartyPickerSheet",
    """class _BattleHeader extends StatelessWidget {
  const _BattleHeader({
    super.key,
    required this.round,
    required this.trainerInitiativeBonus,
    required this.onNextRound,
    required this.onEnd,
  });

  final int round;
  final int trainerInitiativeBonus;
  final VoidCallback onNextRound;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final initiative =
        '${trainerInitiativeBonus >= 0 ? '+' : ''}$trainerInitiativeBonus';
    final info = Text(
      context.uiText(
        'ROUND $round · INIZ. $initiative',
        'ROUND $round · INIT. $initiative',
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
    );

    final endButton = IconButton(
      tooltip: context.uiText('Termina battaglia', 'End battle'),
      visualDensity: VisualDensity.compact,
      onPressed: onEnd,
      icon: const Icon(Icons.stop_circle_outlined),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final veryCompact = constraints.maxWidth < 390;
        final nextButton = Tooltip(
          message: context.uiText('Prossimo mio turno', 'Next my turn'),
          child: FilledButton.icon(
            onPressed: onNextRound,
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            icon: const Icon(Icons.navigate_next, size: 18),
            label: Text(
              veryCompact
                  ? context.uiText('TURNO', 'TURN')
                  : context.uiText('PROSSIMO TURNO', 'NEXT TURN'),
              maxLines: 1,
            ),
          ),
        );

        return Row(
          children: [
            Expanded(child: info),
            const SizedBox(width: 6),
            nextButton,
            endButton,
          ],
        );
      },
    );
  }
}

class _PartyBar extends StatelessWidget {
  const _PartyBar({
    required this.headerKey,
    required this.round,
    required this.trainerInitiativeBonus,
    required this.onNextRound,
    required this.onEnd,
    required this.slots,
    required this.activeSlot,
    required this.pokemonForSlot,
    required this.imagePokemonForSlot,
    required this.formNameForSlot,
    required this.transformationForSlot,
    required this.levelForSlot,
    required this.maxHpForSlot,
    required this.onSelected,
  });

  final Key headerKey;
  final int round;
  final int trainerInitiativeBonus;
  final VoidCallback onNextRound;
  final VoidCallback onEnd;
  final List<TeamSlot> slots;
  final TeamSlot activeSlot;
  final Pokemon? Function(TeamSlot slot) pokemonForSlot;
  final Pokemon? Function(TeamSlot slot) imagePokemonForSlot;
  final String? Function(TeamSlot slot) formNameForSlot;
  final BattleTransformationState? Function(TeamSlot slot)
  transformationForSlot;
  final int Function(TeamSlot slot) levelForSlot;
  final int Function(TeamSlot slot) maxHpForSlot;
  final ValueChanged<int> onSelected;

  Future<void> _openPicker(BuildContext context) async {
    final selectedSlot = await showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _PartyPickerSheet(
        slots: slots,
        activeSlot: activeSlot,
        pokemonForSlot: pokemonForSlot,
        imagePokemonForSlot: imagePokemonForSlot,
        formNameForSlot: formNameForSlot,
        transformationForSlot: transformationForSlot,
        levelForSlot: levelForSlot,
        maxHpForSlot: maxHpForSlot,
      ),
    );
    if (!context.mounted || selectedSlot == null) return;
    onSelected(selectedSlot);
  }

  @override
  Widget build(BuildContext context) {
    final changeButton = OutlinedButton.icon(
      onPressed: () => _openPicker(context),
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      icon: const Icon(Icons.swap_horiz, size: 18),
      label: Text(context.uiText('CAMBIA POKÉMON', 'SWITCH POKÉMON')),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final header = _BattleHeader(
              key: headerKey,
              round: round,
              trainerInitiativeBonus: trainerInitiativeBonus,
              onNextRound: onNextRound,
              onEnd: onEnd,
            );

            if (constraints.maxWidth < 600) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  const SizedBox(height: 6),
                  SizedBox(width: double.infinity, child: changeButton),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: header),
                const SizedBox(width: 10),
                changeButton,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PartyPickerSheet""",
    'compact battle command bar classes',
)

battle_path.write_text(battle, encoding='utf-8')
