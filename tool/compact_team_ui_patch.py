from pathlib import Path

path = Path('lib/screens/team/team_selection_screen.dart')
text = path.read_text(encoding='utf-8')


def replace_once(old: str, new: str, label: str) -> None:
    global text
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{label}: attesa 1 occorrenza, trovate {count}')
    text = text.replace(old, new, 1)


replace_once(
    "import '../../models/pokemon.dart';\n",
    "import '../../models/level_progression.dart';\nimport '../../models/pokemon.dart';\n",
    'import LevelProgression',
)
replace_once(
    "import '../../services/pokemon_transfer_service.dart';\n",
    "import '../../services/pokemon_transfer_service.dart';\nimport '../../services/trainer_path_passive_service.dart';\n",
    'import TrainerPathPassiveService',
)

replace_once(
    """  String _displayNameForSlot(TeamSlot slot) {
    final nickname = slot.nickname?.trim() ?? '';
    if (nickname.isNotEmpty) return nickname;
    return _pokemonById(slot.pokemonId)?.name ?? 'Pokémon';
  }
""",
    """  String _displayNameForSlot(TeamSlot slot) {
    final nickname = slot.nickname?.trim() ?? '';
    if (nickname.isNotEmpty) return nickname;
    return _pokemonById(slot.pokemonId)?.name ?? 'Pokémon';
  }

  int _maxHpForSlot(TeamSlot slot) {
    final profile = _profile;
    final basePokemon = _pokemonById(slot.pokemonId);
    if (profile == null || basePokemon == null) return 0;

    final pokemon = basePokemon.resolveVariant(
      formName: slot.effectiveFormName,
      gender: slot.gender,
    );
    return TrainerPathPassiveService.maxHp(
      profile: profile,
      pokemon: pokemon,
      slot: slot,
      level: LevelProgression.levelFromExperience(slot.experience),
    );
  }
""",
    'max HP helper',
)

old_build_slots = """  Widget _buildTeamSlots(List<TeamSlot> visibleTeam) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final usesTwoColumns = constraints.maxWidth >= 840;
        final cardWidth = usesTwoColumns
            ? (constraints.maxWidth - spacing) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: 0,
          children: [
            for (final slot in visibleTeam)
              DragTarget<int>(
                key: ValueKey('team-slot-drop-${slot.slotIndex}'),
                onWillAcceptWithDetails: (details) =>
                    !_isBusy && details.data != slot.slotIndex,
                onAcceptWithDetails: (details) {
                  _reorderTeamSlot(details.data, slot.slotIndex);
                },
                builder: (context, candidateData, rejectedData) {
                  final isDropTarget = candidateData.isNotEmpty;
                  final card = SizedBox(
                    width: cardWidth,
                    child: _TeamSlotCard(
                      slot: slot,
                      pokemon: _pokemonById(slot.pokemonId),
                      isDropTarget: isDropTarget,
                      onOpen: () => _openPokemonDetail(slot),
                      onChange: () => _openPokemonPicker(slot),
                      onExport: slot.isPokemon
                          ? () => _exportPokemon(slot)
                          : null,
                      onShare: slot.isPokemon
                          ? () => _sharePokemon(slot)
                          : null,
                      onImport: slot.isEgg
                          ? null
                          : () => _importPokemonInto(slot),
                      onRemove: slot.isPokemon
                          ? () => _setPokemonInSlot(slot.slotIndex, null)
                          : null,
                    ),
                  );

                  if (!slot.isPokemon || _isBusy) return card;

                  final feedbackWidth = cardWidth > 440 ? 440.0 : cardWidth;
                  return LongPressDraggable<int>(
                    data: slot.slotIndex,
                    hapticFeedbackOnStart: true,
                    onDragUpdate: _autoScrollDuringDrag,
                    feedback: Material(
                      color: Colors.transparent,
                      elevation: 8,
                      borderRadius: BorderRadius.circular(14),
                      child: IgnorePointer(
                        child: SizedBox(
                          width: feedbackWidth,
                          child: _TeamSlotCard(
                            slot: slot,
                            pokemon: _pokemonById(slot.pokemonId),
                            onOpen: () {},
                            onChange: () {},
                            onExport: null,
                            onShare: null,
                            onImport: null,
                            onRemove: null,
                          ),
                        ),
                      ),
                    ),
                    childWhenDragging: Opacity(opacity: 0.3, child: card),
                    child: card,
                  );
                },
              ),
          ],
        );
      },
    );
  }
"""

new_build_slots = """  Widget _buildTeamSlots(List<TeamSlot> visibleTeam) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final columns = constraints.maxWidth >= 1000
            ? 4
            : constraints.maxWidth >= 680
            ? 3
            : 2;
        final cardWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final slot in visibleTeam)
              DragTarget<int>(
                key: ValueKey('team-slot-drop-${slot.slotIndex}'),
                onWillAcceptWithDetails: (details) =>
                    !_isBusy && details.data != slot.slotIndex,
                onAcceptWithDetails: (details) {
                  _reorderTeamSlot(details.data, slot.slotIndex);
                },
                builder: (context, candidateData, rejectedData) {
                  final isDropTarget = candidateData.isNotEmpty;
                  final card = SizedBox(
                    width: cardWidth,
                    child: _TeamSlotCard(
                      slot: slot,
                      pokemon: _pokemonById(slot.pokemonId),
                      maxHp: _maxHpForSlot(slot),
                      isDropTarget: isDropTarget,
                      onOpen: () => _openPokemonDetail(slot),
                      onChange: () => _openPokemonPicker(slot),
                      onExport: slot.isPokemon
                          ? () => _exportPokemon(slot)
                          : null,
                      onShare: slot.isPokemon
                          ? () => _sharePokemon(slot)
                          : null,
                      onImport: slot.isEgg
                          ? null
                          : () => _importPokemonInto(slot),
                      onRemove: slot.isPokemon
                          ? () => _setPokemonInSlot(slot.slotIndex, null)
                          : null,
                    ),
                  );

                  if (!slot.isPokemon || _isBusy) return card;

                  return LongPressDraggable<int>(
                    data: slot.slotIndex,
                    hapticFeedbackOnStart: true,
                    onDragUpdate: _autoScrollDuringDrag,
                    feedback: Material(
                      color: Colors.transparent,
                      elevation: 8,
                      borderRadius: BorderRadius.circular(14),
                      child: IgnorePointer(
                        child: SizedBox(
                          width: cardWidth,
                          child: _TeamSlotCard(
                            slot: slot,
                            pokemon: _pokemonById(slot.pokemonId),
                            maxHp: _maxHpForSlot(slot),
                            onOpen: () {},
                            onChange: () {},
                            onExport: null,
                            onShare: null,
                            onImport: null,
                            onRemove: null,
                          ),
                        ),
                      ),
                    ),
                    childWhenDragging: Opacity(opacity: 0.3, child: card),
                    child: card,
                  );
                },
              ),
          ],
        );
      },
    );
  }
"""
replace_once(old_build_slots, new_build_slots, 'team grid')

replace_once(
    """    final profileName = _profile?.name ?? widget.nickname;
    final visibleTeam = _visibleTeam;
    final filledSlots = visibleTeam.where((slot) => !slot.isEmpty).length;
""",
    """    final visibleTeam = _visibleTeam;
""",
    'unused header locals',
)

replace_once(
    """              else ...[
                _TeamHeader(
                  profileName: profileName,
                  filledSlots: filledSlots,
                  totalSlots: visibleTeam.length,
                ),
                if (_statusMessage != null) ...[
                  const SizedBox(height: 12),
                  _TeamStatusBanner(
""",
    """              else ...[
                if (_statusMessage != null) ...[
                  _TeamStatusBanner(
""",
    'remove team header',
)

old_header = """class _TeamHeader extends StatelessWidget {
  const _TeamHeader({
    required this.profileName,
    required this.filledSlots,
    required this.totalSlots,
  });

  final String profileName;
  final int filledSlots;
  final int totalSlots;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: const Icon(
              Icons.catching_pokemon,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.uiText('Squadra di', 'Team of').toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.uiText(
                    '$filledSlots/$totalSlots Pokéslot occupati',
                    '$filledSlots/$totalSlots Poké Slots occupied',
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

"""
replace_once(old_header, '', 'team header class')

start = text.index('class _TeamSlotCard extends StatelessWidget {')
end = text.index('enum _TeamTransferAction', start)
old_card_block = text[start:end]
new_card_block = r'''class _TeamSlotCard extends StatelessWidget {
  const _TeamSlotCard({
    required this.slot,
    required this.pokemon,
    required this.maxHp,
    required this.onOpen,
    required this.onChange,
    required this.onExport,
    required this.onShare,
    required this.onImport,
    required this.onRemove,
    this.isDropTarget = false,
  });

  final TeamSlot slot;
  final Pokemon? pokemon;
  final int maxHp;
  final VoidCallback onOpen;
  final VoidCallback onChange;
  final VoidCallback? onExport;
  final VoidCallback? onShare;
  final VoidCallback? onImport;
  final VoidCallback? onRemove;
  final bool isDropTarget;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final basePokemon = pokemon;
    final resolvedPokemon = basePokemon?.resolveVariant(
      formName: slot.effectiveFormName,
      gender: slot.gender,
    );
    final nickname = slot.nickname?.trim() ?? '';
    final title = slot.isEgg
        ? context.uiText('Uovo', 'Egg')
        : nickname.isEmpty
        ? resolvedPokemon?.name ?? context.uiText('Slot vuoto', 'Empty slot')
        : nickname;
    final level = resolvedPokemon == null
        ? null
        : LevelProgression.levelFromExperience(slot.experience);
    final currentHp = maxHp <= 0 ? 0 : slot.currentHp.clamp(0, maxHp).toInt();
    final hpProgress = maxHp <= 0
        ? 0.0
        : (currentHp / maxHp).clamp(0.0, 1.0).toDouble();
    final hasHeldItem = slot.heldItem?.trim().isNotEmpty == true;
    final hasStatus = slot.statusEffects.isNotEmpty;
    final enlargedText = MediaQuery.textScalerOf(context).scale(1) > 1.25;
    final cardHeight = enlargedText ? 244.0 : 194.0;

    return Semantics(
      button: true,
      label: slot.isEgg
          ? context.uiText(
              'Pokéslot ${slot.slotIndex + 1}, uovo in incubazione',
              'Poké Slot ${slot.slotIndex + 1}, incubating egg',
            )
          : resolvedPokemon == null
          ? context.uiText(
              'Pokéslot ${slot.slotIndex + 1}, vuoto',
              'Poké Slot ${slot.slotIndex + 1}, empty',
            )
          : '$title, ${context.uiText('livello', 'level')} $level',
      child: Card(
        margin: EdgeInsets.zero,
        color: isDropTarget ? colorScheme.primaryContainer : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: isDropTarget
              ? BorderSide(color: colorScheme.primary, width: 2)
              : BorderSide(color: colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: SizedBox(
            height: cardHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 7, 6, 8),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(
                            context.uiText(
                              'SLOT ${slot.slotIndex + 1}',
                              'SLOT ${slot.slotIndex + 1}',
                            ),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const Spacer(),
                          if (slot.isEgg)
                            Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: colorScheme.onSurfaceVariant,
                            )
                          else
                            _TeamSlotMenu(
                              pokemon: resolvedPokemon,
                              onChange: onChange,
                              onExport: onExport,
                              onShare: onShare,
                              onImport: onImport,
                              onRemove: onRemove,
                            ),
                        ],
                      ),
                      Expanded(
                        child: Center(
                          child: _SlotAvatar(
                            slot: slot,
                            pokemon: resolvedPokemon,
                          ),
                        ),
                      ),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (slot.isEgg)
                        Text(
                          context.uiText(
                            'Tocca per gestire',
                            'Tap to manage',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        )
                      else if (resolvedPokemon == null)
                        Text(
                          context.uiText(
                            'Tocca per scegliere',
                            'Tap to choose',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${context.uiText('Liv.', 'Lv.')} $level',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            if (resolvedPokemon.types.isNotEmpty) ...[
                              const SizedBox(width: 5),
                              Flexible(
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 3,
                                  runSpacing: 2,
                                  children: [
                                    for (final type in resolvedPokemon.types.take(2))
                                      PokemonTypeBadge(type: type, height: 15),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    context.uiText(
                                      'PF $currentHp/$maxHp',
                                      'HP $currentHp/$maxHp',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.labelSmall
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 2),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: hpProgress,
                                      minHeight: 6,
                                      backgroundColor:
                                          colorScheme.surfaceContainerHighest,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (hasStatus) ...[
                              const SizedBox(width: 5),
                              Tooltip(
                                message: context.uiText(
                                  'Status attivi: ${slot.statusEffects.length}',
                                  'Active conditions: ${slot.statusEffects.length}',
                                ),
                                child: Icon(
                                  Icons.warning_amber_rounded,
                                  size: 18,
                                  color: colorScheme.error,
                                ),
                              ),
                            ],
                            if (hasHeldItem) ...[
                              const SizedBox(width: 4),
                              Tooltip(
                                message: context.uiText(
                                  'Strumento tenuto',
                                  'Held item',
                                ),
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  size: 17,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                  if (resolvedPokemon == null && !slot.isEgg)
                    Positioned.fill(
                      top: 24,
                      bottom: 45,
                      child: IgnorePointer(
                        child: Center(
                          child: Icon(
                            Icons.add_circle_outline,
                            size: 42,
                            color: colorScheme.primary.withValues(alpha: 0.72),
                          ),
                        ),
                      ),
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

class _TeamSlotMenu extends StatelessWidget {
  const _TeamSlotMenu({
    required this.pokemon,
    required this.onChange,
    required this.onExport,
    required this.onShare,
    required this.onImport,
    required this.onRemove,
  });

  final Pokemon? pokemon;
  final VoidCallback onChange;
  final VoidCallback? onExport;
  final VoidCallback? onShare;
  final VoidCallback? onImport;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 30,
      child: PopupMenuButton<_SlotAction>(
        padding: EdgeInsets.zero,
        iconSize: 19,
        tooltip: context.uiText('Altre azioni', 'More actions'),
        onSelected: (action) {
          switch (action) {
            case _SlotAction.change:
              onChange();
              break;
            case _SlotAction.export:
              onExport?.call();
              break;
            case _SlotAction.share:
              onShare?.call();
              break;
            case _SlotAction.import:
              onImport?.call();
              break;
            case _SlotAction.remove:
              onRemove?.call();
              break;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _SlotAction.change,
            child: Text(
              pokemon == null
                  ? context.uiText('Scegli Pokémon', 'Choose Pokémon')
                  : context.uiText('Cambia Pokémon', 'Change Pokémon'),
            ),
          ),
          if (pokemon != null)
            PopupMenuItem(
              value: _SlotAction.export,
              child: Text(
                context.uiText('Esporta Pokémon', 'Export Pokémon'),
              ),
            ),
          if (pokemon != null)
            PopupMenuItem(
              value: _SlotAction.share,
              child: Text(
                context.uiText('Condividi Pokémon', 'Share Pokémon'),
              ),
            ),
          if (onImport != null)
            PopupMenuItem(
              value: _SlotAction.import,
              child: Text(
                context.uiText('Importa Pokémon qui', 'Import Pokémon here'),
              ),
            ),
          if (pokemon != null)
            PopupMenuItem(
              value: _SlotAction.remove,
              child: Text(
                context.uiText('Rimuovi dallo slot', 'Remove from slot'),
              ),
            ),
        ],
      ),
    );
  }
}

'''
text = text[:start] + new_card_block + text[end:]

old_avatar = r'''class _SlotAvatar extends StatelessWidget {
  const _SlotAvatar({required this.slot, required this.pokemon});

  final TeamSlot slot;
  final Pokemon? pokemon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pokemon = this.pokemon;

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: pokemon != null
            ? colorScheme.primaryContainer.withValues(alpha: 0.72)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: slot.isEgg
            ? const EggAssetImage(size: 38)
            : pokemon == null
            ? Text(
                '${slot.slotIndex + 1}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                ),
              )
            : PokemonAssetImage(
                pokemon: pokemon,
                formName: slot.effectiveFormName,
                gender: slot.gender,
                isShiny: slot.isShiny,
                size: 48,
              ),
      ),
    );
  }
}
'''

new_avatar = r'''class _SlotAvatar extends StatelessWidget {
  const _SlotAvatar({required this.slot, required this.pokemon});

  final TeamSlot slot;
  final Pokemon? pokemon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pokemon = this.pokemon;

    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: pokemon != null
            ? colorScheme.primaryContainer.withValues(alpha: 0.48)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: slot.isEgg
          ? const EggAssetImage(size: 54)
          : pokemon == null
          ? const SizedBox.shrink()
          : PokemonAssetImage(
              pokemon: pokemon,
              formName: slot.effectiveFormName,
              gender: slot.gender,
              isShiny: slot.isShiny,
              size: 70,
            ),
    );
  }
}
'''
replace_once(old_avatar, new_avatar, 'team slot avatar')

path.write_text(text, encoding='utf-8')
print('Patch GUI Squadra applicata con successo.')
