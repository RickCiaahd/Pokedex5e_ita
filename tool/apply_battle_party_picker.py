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


path = Path('lib/screens/battle/battle_screen.dart')
text = path.read_text(encoding='utf-8')

text = replace_once(
    text,
    """                                    transformationForSlot: (slot) =>
                                        _transformationBySlot[slot.slotIndex],
                                    onSelected: (slotIndex) {
""",
    """                                    transformationForSlot: (slot) =>
                                        _transformationBySlot[slot.slotIndex],
                                    levelForSlot: _levelForSlot,
                                    maxHpForSlot: (slot) {
                                      final slotPokemon = _pokemonForSlot(
                                        data,
                                        slot,
                                      );
                                      return slotPokemon == null
                                          ? 0
                                          : _maxHpFor(slotPokemon, slot);
                                    },
                                    onSelected: (slotIndex) {
""",
    'wire party picker statistics',
)

replacement = r'''class _PartyBar extends StatelessWidget {
  const _PartyBar({
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

  String _displayName(TeamSlot slot, Pokemon pokemon) {
    final nickname = slot.nickname?.trim();
    return nickname == null || nickname.isEmpty ? pokemon.name : nickname;
  }

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
    final pokemon = pokemonForSlot(activeSlot);
    if (pokemon == null) return const SizedBox.shrink();

    final activeInfo = Row(
      children: [
        PokemonTransformationImage(
          pokemon: imagePokemonForSlot(activeSlot) ?? pokemon,
          size: 48,
          formName: formNameForSlot(activeSlot),
          gender: activeSlot.gender,
          isShiny: activeSlot.isShiny,
          transformation: transformationForSlot(activeSlot),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.uiText('POKÉMON ATTIVO', 'ACTIVE POKÉMON'),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                _displayName(activeSlot, pokemon),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                context.uiText(
                  '${slots.length} Pokémon in squadra',
                  '${slots.length} Pokémon in the team',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );

    final changeButton = FilledButton.icon(
      onPressed: () => _openPicker(context),
      icon: const Icon(Icons.swap_horiz),
      label: Text(context.uiText('CAMBIA POKÉMON', 'SWITCH POKÉMON')),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 520) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  activeInfo,
                  const SizedBox(height: 8),
                  SizedBox(width: double.infinity, child: changeButton),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: activeInfo),
                const SizedBox(width: 12),
                changeButton,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PartyPickerSheet extends StatelessWidget {
  const _PartyPickerSheet({
    required this.slots,
    required this.activeSlot,
    required this.pokemonForSlot,
    required this.imagePokemonForSlot,
    required this.formNameForSlot,
    required this.transformationForSlot,
    required this.levelForSlot,
    required this.maxHpForSlot,
  });

  final List<TeamSlot> slots;
  final TeamSlot activeSlot;
  final Pokemon? Function(TeamSlot slot) pokemonForSlot;
  final Pokemon? Function(TeamSlot slot) imagePokemonForSlot;
  final String? Function(TeamSlot slot) formNameForSlot;
  final BattleTransformationState? Function(TeamSlot slot)
  transformationForSlot;
  final int Function(TeamSlot slot) levelForSlot;
  final int Function(TeamSlot slot) maxHpForSlot;

  String _displayName(TeamSlot slot, Pokemon pokemon) {
    final nickname = slot.nickname?.trim();
    return nickname == null || nickname.isEmpty ? pokemon.name : nickname;
  }

  String _statusLabel(BuildContext context, TeamSlot slot) {
    if (slot.statusEffects.isEmpty) {
      return context.uiText('Nessuno status', 'No conditions');
    }
    return slot.statusEffects.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final sheetHeight = min(MediaQuery.sizeOf(context).height * 0.78, 640.0);

    return SafeArea(
      child: SizedBox(
        height: sheetHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.uiText(
                      'SCEGLI IL POKÉMON',
                      'CHOOSE A POKÉMON',
                    ),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.uiText(
                      'Il cambio volontario usa l’azione del turno. Se il Pokémon attivo è esausto, la sostituzione è gratuita.',
                      'A voluntary switch uses the turn action. If the active Pokémon is fainted, replacing it is free.',
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
                itemCount: slots.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final slot = slots[index];
                  final pokemon = pokemonForSlot(slot);
                  if (pokemon == null) return const SizedBox.shrink();

                  final isActive = slot.slotIndex == activeSlot.slotIndex;
                  final maxHp = maxHpForSlot(slot);
                  final currentHp = maxHp <= 0
                      ? slot.currentHp
                      : slot.currentHp.clamp(0, maxHp).toInt();
                  final isFainted = currentHp <= 0;
                  final types = pokemon.types.isEmpty
                      ? context.uiText('Senza tipo', 'Typeless')
                      : pokemon.types.join(' · ');
                  final status = _statusLabel(context, slot);

                  return Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      enabled: !isActive && !isFainted,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      leading: PokemonTransformationImage(
                        pokemon: imagePokemonForSlot(slot) ?? pokemon,
                        size: 54,
                        formName: formNameForSlot(slot),
                        gender: slot.gender,
                        isShiny: slot.isShiny,
                        transformation: transformationForSlot(slot),
                      ),
                      title: Text(
                        _displayName(slot, pokemon),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text(
                        'LV ${levelForSlot(slot)} · PF $currentHp/$maxHp\n$types · $status',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: isActive
                          ? Chip(
                              label: Text(
                                context.uiText('ATTIVO', 'ACTIVE'),
                              ),
                              visualDensity: VisualDensity.compact,
                            )
                          : isFainted
                          ? Chip(
                              label: Text(
                                context.uiText('ESAUSTO', 'FAINTED'),
                              ),
                              visualDensity: VisualDensity.compact,
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: isActive || isFainted
                          ? null
                          : () => Navigator.of(context).pop(slot.slotIndex),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

'''

text = regex_once(
    text,
    r"class _PartyBar extends StatelessWidget \{.*?\n(?=class _BattleFormPickerSheet)",
    replacement,
    'replace horizontal party bar with popup selector',
)

path.write_text(text, encoding='utf-8')
print('Battle party picker applied successfully.')
