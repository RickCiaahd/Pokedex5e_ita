from pathlib import Path


PATH = Path('lib/screens/battle/battle_screen.dart')


def replace_once(old: str, new: str) -> None:
    text = PATH.read_text(encoding='utf-8')
    count = text.count(old)
    if count != 1:
        raise SystemExit(
            f'battle_screen.dart: expected one match, found {count}: {old[:120]!r}'
        )
    PATH.write_text(text.replace(old, new, 1), encoding='utf-8')


replace_once(
    "import '../../services/battle_form_change_service.dart';\n"
    "import '../../services/battle_quick_item_service.dart';",
    "import '../../services/battle_form_change_service.dart';\n"
    "import '../../services/battle_quick_item_service.dart';\n"
    "import '../../services/battle_temporary_hp_service.dart';",
)

replace_once(
    "  final Map<int, String> _battleFormBySlot = {};\n"
    "  final List<BattleInitiativeEntry> _initiativeEntries = [];",
    "  final Map<int, String> _battleFormBySlot = {};\n"
    "  final Map<int, int> _temporaryHpBySlot = {};\n"
    "  final Map<int, bool> _temporaryHpEnabledBySlot = {};\n"
    "  final Set<int> _temporaryHpInitializedSlots = {};\n"
    "  final List<BattleInitiativeEntry> _initiativeEntries = [];",
)

replace_once(
    "    _volatileStatusesBySlot.clear();\n"
    "    _battleFormBySlot.clear();\n"
    "    _initiativeEntries.clear();",
    "    _volatileStatusesBySlot.clear();\n"
    "    _battleFormBySlot.clear();\n"
    "    _temporaryHpBySlot.clear();\n"
    "    _temporaryHpEnabledBySlot.clear();\n"
    "    _temporaryHpInitializedSlots.clear();\n"
    "    _initiativeEntries.clear();",
)

replace_once(
    "        if (battleFormName != null && battleFormName.trim().isNotEmpty) {\n"
    "          _battleFormBySlot[matchingSlot.slotIndex] = battleFormName;\n"
    "        }\n"
    "      }",
    "        if (battleFormName != null && battleFormName.trim().isNotEmpty) {\n"
    "          _battleFormBySlot[matchingSlot.slotIndex] = battleFormName;\n"
    "        }\n"
    "        _temporaryHpBySlot[matchingSlot.slotIndex] = state.temporaryHp;\n"
    "        _temporaryHpEnabledBySlot[matchingSlot.slotIndex] =\n"
    "            state.temporaryHpEnabled;\n"
    "        if (state.temporaryHpInitialized) {\n"
    "          _temporaryHpInitializedSlots.add(matchingSlot.slotIndex);\n"
    "        }\n"
    "      }",
)

replace_once(
    "    final activeSlot = _activeSlotFor(data);",
    "    for (final slot in data.occupiedSlots) {\n"
    "      if (_temporaryHpInitializedSlots.contains(slot.slotIndex)) continue;\n"
    "      final pokemonId = slot.pokemonId;\n"
    "      if (pokemonId == null) continue;\n"
    "      final basePokemon = data.pokemonById[pokemonId];\n"
    "      if (basePokemon == null) continue;\n"
    "      final rule = BattleTemporaryHpService.ruleFor(basePokemon, slot);\n"
    "      _temporaryHpInitializedSlots.add(slot.slotIndex);\n"
    "      if (rule == null) continue;\n"
    "      _temporaryHpEnabledBySlot[slot.slotIndex] = true;\n"
    "      _temporaryHpBySlot[slot.slotIndex] =\n"
    "          rule.maximumForLevel(_levelForSlot(slot));\n"
    "      if (basePokemon.name == 'Mimikyu') {\n"
    "        _battleFormBySlot[slot.slotIndex] = 'Base';\n"
    "      }\n"
    "    }\n\n"
    "    final activeSlot = _activeSlotFor(data);",
)

replace_once(
    "        battleFormName: _battleFormBySlot[slot.slotIndex],\n"
    "      );",
    "        battleFormName: _battleFormBySlot[slot.slotIndex],\n"
    "        temporaryHp: _temporaryHpBySlot[slot.slotIndex] ?? 0,\n"
    "        temporaryHpEnabled:\n"
    "            _temporaryHpEnabledBySlot[slot.slotIndex] ?? false,\n"
    "        temporaryHpInitialized: _temporaryHpInitializedSlots.contains(\n"
    "          slot.slotIndex,\n"
    "        ),\n"
    "      );",
)

replace_once(
    "  Pokemon? _pokemonForSlot(_BattleData data, TeamSlot slot) {\n"
    "    final pokemonId = slot.pokemonId;\n"
    "    if (pokemonId == null) return null;\n"
    "    return data.pokemonById[pokemonId]?.resolveVariant(\n"
    "      formName: _effectiveFormName(slot),\n"
    "      gender: slot.gender,\n"
    "    );\n"
    "  }",
    "  Pokemon? _pokemonForSlot(_BattleData data, TeamSlot slot) {\n"
    "    final pokemonId = slot.pokemonId;\n"
    "    if (pokemonId == null) return null;\n"
    "    final basePokemon = data.pokemonById[pokemonId];\n"
    "    if (basePokemon == null) return null;\n"
    "    final formName = _effectiveFormName(slot);\n"
    "    if (basePokemon.name == 'Palafin' &&\n"
    "        BattleFormChangeService.canonicalFormKey(basePokemon, formName) ==\n"
    "            'hero') {\n"
    "      return basePokemon;\n"
    "    }\n"
    "    return basePokemon.resolveVariant(\n"
    "      formName: formName,\n"
    "      gender: slot.gender,\n"
    "    );\n"
    "  }",
)

replace_once(
    "  Future<void> _openBattleFormPicker(_BattleData data, TeamSlot slot) async {",
    "  List<PokemonFormChoice> _normalizedBattleFormChoices(\n"
    "    Pokemon pokemon,\n"
    "    TeamSlot slot,\n"
    "    List<PokemonFormChoice> choices,\n"
    "  ) {\n"
    "    final byKey = <String, PokemonFormChoice>{};\n"
    "    for (final choice in choices) {\n"
    "      if (!BattleFormChangeService.isAllowedChoice(\n"
    "        pokemon: pokemon,\n"
    "        slot: slot,\n"
    "        formName: choice.name,\n"
    "      )) {\n"
    "        continue;\n"
    "      }\n"
    "      final key = BattleFormChangeService.canonicalFormKey(\n"
    "        pokemon,\n"
    "        choice.name,\n"
    "      );\n"
    "      byKey.putIfAbsent(\n"
    "        key,\n"
    "        () => PokemonFormChoice(\n"
    "          name: BattleFormChangeService.normalizedChoiceName(\n"
    "            pokemon,\n"
    "            choice.name,\n"
    "          ),\n"
    "          assetPath: choice.assetPath,\n"
    "        ),\n"
    "      );\n"
    "    }\n"
    "    final result = byKey.values.toList(growable: false)\n"
    "      ..sort(\n"
    "        (a, b) => BattleFormChangeService.formSortWeight(\n"
    "          pokemon,\n"
    "          a.name,\n"
    "        ).compareTo(\n"
    "          BattleFormChangeService.formSortWeight(pokemon, b.name),\n"
    "        ),\n"
    "      );\n"
    "    return result;\n"
    "  }\n\n"
    "  Future<void> _openBattleFormPicker(_BattleData data, TeamSlot slot) async {",
)

replace_once(
    "    final allChoices = await PokemonAssetPaths.formChoices(basePokemon);\n"
    "    final choices = allChoices\n"
    "        .where(\n"
    "          (choice) => BattleFormChangeService.isAllowedChoice(\n"
    "            pokemon: basePokemon,\n"
    "            slot: slot,\n"
    "            formName: choice.name,\n"
    "          ),\n"
    "        )\n"
    "        .toList(growable: false);",
    "    final allChoices = await PokemonAssetPaths.formChoices(basePokemon);\n"
    "    final choices = _normalizedBattleFormChoices(\n"
    "      basePokemon,\n"
    "      slot,\n"
    "      allChoices,\n"
    "    );",
)

replace_once(
    "  Future<void> _changeHp(_BattleData data, TeamSlot slot, int delta) async {\n"
    "    final pokemon = _pokemonForSlot(data, slot);\n"
    "    if (pokemon == null) return;\n\n"
    "    final maxHp = _maxHpFor(pokemon, slot);\n"
    "    final updatedHp = (_currentHpFor(slot, pokemon) + delta)\n"
    "        .clamp(0, maxHp)\n"
    "        .toInt();\n\n"
    "    await _teamRepository.updateSlot(\n"
    "      profileId: data.profile.id,\n"
    "      updatedSlot: slot.copyWith(currentHp: updatedHp),\n"
    "    );\n"
    "    await _reload();\n"
    "  }",
    "  BattleTemporaryHpRule? _temporaryHpRule(\n"
    "    _BattleData data,\n"
    "    TeamSlot slot,\n"
    "  ) {\n"
    "    final pokemonId = slot.pokemonId;\n"
    "    if (pokemonId == null) return null;\n"
    "    final basePokemon = data.pokemonById[pokemonId];\n"
    "    if (basePokemon == null) return null;\n"
    "    return BattleTemporaryHpService.ruleFor(basePokemon, slot);\n"
    "  }\n\n"
    "  Future<void> _toggleTemporaryHpRule(\n"
    "    _BattleData data,\n"
    "    TeamSlot slot,\n"
    "    bool enabled,\n"
    "  ) async {\n"
    "    final rule = _temporaryHpRule(data, slot);\n"
    "    if (rule == null) return;\n"
    "    final basePokemon = data.pokemonById[slot.pokemonId!]!;\n"
    "    setState(() {\n"
    "      _temporaryHpInitializedSlots.add(slot.slotIndex);\n"
    "      _temporaryHpEnabledBySlot[slot.slotIndex] = enabled;\n"
    "      _temporaryHpBySlot[slot.slotIndex] = enabled\n"
    "          ? rule.maximumForLevel(_levelForSlot(slot))\n"
    "          : 0;\n"
    "      if (basePokemon.name == 'Mimikyu') {\n"
    "        _battleFormBySlot[slot.slotIndex] = enabled\n"
    "            ? 'Base'\n"
    "            : rule.brokenFormName ?? 'Busted';\n"
    "      }\n"
    "      _message = enabled\n"
    "          ? '${rule.label} attivato: ${_temporaryHpBySlot[slot.slotIndex]} PF temporanei.'\n"
    "          : '${rule.label} disattivato.';\n"
    "    });\n"
    "    await _saveSession(data);\n"
    "  }\n\n"
    "  Future<void> _changeHp(_BattleData data, TeamSlot slot, int delta) async {\n"
    "    final pokemon = _pokemonForSlot(data, slot);\n"
    "    if (pokemon == null) return;\n\n"
    "    final maxHp = _maxHpFor(pokemon, slot);\n"
    "    var hpDelta = delta;\n"
    "    var absorbed = 0;\n"
    "    final rule = _temporaryHpRule(data, slot);\n"
    "    if (delta < 0 &&\n"
    "        rule != null &&\n"
    "        (_temporaryHpEnabledBySlot[slot.slotIndex] ?? false)) {\n"
    "      final currentTemporaryHp = _temporaryHpBySlot[slot.slotIndex] ?? 0;\n"
    "      absorbed = min(currentTemporaryHp, -delta);\n"
    "      if (absorbed > 0) {\n"
    "        final remainingTemporaryHp = currentTemporaryHp - absorbed;\n"
    "        _temporaryHpBySlot[slot.slotIndex] = remainingTemporaryHp;\n"
    "        hpDelta += absorbed;\n"
    "        if (remainingTemporaryHp == 0) {\n"
    "          _temporaryHpEnabledBySlot[slot.slotIndex] = false;\n"
    "          final basePokemon = data.pokemonById[slot.pokemonId!];\n"
    "          if (basePokemon?.name == 'Mimikyu') {\n"
    "            _battleFormBySlot[slot.slotIndex] =\n"
    "                rule.brokenFormName ?? 'Busted';\n"
    "          }\n"
    "        }\n"
    "      }\n"
    "    }\n\n"
    "    final updatedHp = (_currentHpFor(slot, pokemon) + hpDelta)\n"
    "        .clamp(0, maxHp)\n"
    "        .toInt();\n"
    "    await _teamRepository.updateSlot(\n"
    "      profileId: data.profile.id,\n"
    "      updatedSlot: slot.copyWith(currentHp: updatedHp),\n"
    "    );\n"
    "    await _saveSession(data);\n"
    "    final message = absorbed == 0\n"
    "        ? null\n"
    "        : (_temporaryHpBySlot[slot.slotIndex] ?? 0) > 0\n"
    "        ? '$absorbed danni assorbiti dai PF temporanei.'\n"
    "        : '$absorbed danni assorbiti: ${rule?.label ?? 'la protezione'} si spezza.';\n"
    "    await _reload(message: message);\n"
    "  }",
)

replace_once(
    "    _volatileStatusesBySlot.remove(slot.slotIndex);\n"
    "    await _teamRepository.updateSlot(",
    "    _volatileStatusesBySlot.remove(slot.slotIndex);\n"
    "    final rule = _temporaryHpRule(data, slot);\n"
    "    if (rule != null) {\n"
    "      _temporaryHpInitializedSlots.add(slot.slotIndex);\n"
    "      _temporaryHpEnabledBySlot[slot.slotIndex] = true;\n"
    "      _temporaryHpBySlot[slot.slotIndex] =\n"
    "          rule.maximumForLevel(_levelForSlot(slot));\n"
    "      final basePokemon = data.pokemonById[slot.pokemonId!];\n"
    "      if (basePokemon?.name == 'Mimikyu') {\n"
    "        _battleFormBySlot[slot.slotIndex] = 'Base';\n"
    "      }\n"
    "    }\n"
    "    await _teamRepository.updateSlot(",
)

replace_once(
    "          'Round, iniziativa, PP temporanei e status volatili verranno rimossi. HP, status persistenti e oggetti consumati resteranno salvati.',",
    "          'Round, iniziativa, PP, PF temporanei, forme di battaglia e status volatili verranno rimossi. HP, status persistenti e oggetti consumati resteranno salvati.',",
)

replace_once(
    "    _volatileStatusesBySlot.clear();\n"
    "    _battleFormBySlot.clear();\n"
    "    _initiativeEntries.clear();",
    "    _volatileStatusesBySlot.clear();\n"
    "    _battleFormBySlot.clear();\n"
    "    _temporaryHpBySlot.clear();\n"
    "    _temporaryHpEnabledBySlot.clear();\n"
    "    _temporaryHpInitializedSlots.clear();\n"
    "    _initiativeEntries.clear();",
)

replace_once(
    "  Map<String, int> _attributeScores(Pokemon pokemon, TeamSlot slot) {\n"
    "    return TrainerPathPassiveService.effectiveAttributeScores(\n"
    "      profile: _activeProfile,\n"
    "      pokemon: pokemon,\n"
    "      slot: slot,\n"
    "    );\n"
    "  }",
    "  Map<String, int> _attributeScores(\n"
    "    Pokemon pokemon,\n"
    "    TeamSlot slot, {\n"
    "    Pokemon? basePokemon,\n"
    "    String? formName,\n"
    "  }) {\n"
    "    final scores = TrainerPathPassiveService.effectiveAttributeScores(\n"
    "      profile: _activeProfile,\n"
    "      pokemon: pokemon,\n"
    "      slot: slot,\n"
    "    );\n"
    "    final sourcePokemon = basePokemon ?? pokemon;\n"
    "    return BattleFormChangeService.applyAttributeScoreModifiers(\n"
    "      sourcePokemon,\n"
    "      formName,\n"
    "      scores,\n"
    "    );\n"
    "  }",
)

replace_once(
    "  int _bestMoveModifier(MoveData move, Pokemon pokemon, TeamSlot slot) {\n"
    "    final attributes = _attributeScores(pokemon, slot);",
    "  int _bestMoveModifier(\n"
    "    MoveData move,\n"
    "    Pokemon pokemon,\n"
    "    TeamSlot slot, {\n"
    "    required Pokemon basePokemon,\n"
    "    required String? formName,\n"
    "  }) {\n"
    "    final attributes = _attributeScores(\n"
    "      pokemon,\n"
    "      slot,\n"
    "      basePokemon: basePokemon,\n"
    "      formName: formName,\n"
    "    );",
)

replace_once(
    "    TeamSlot slot,\n    String? formName,\n  ) {\n"
    "    final level = _levelForSlot(slot);\n"
    "    final moveModifier = _bestMoveModifier(move, pokemon, slot);",
    "    TeamSlot slot,\n"
    "    Pokemon basePokemon,\n"
    "    String? formName,\n"
    "  ) {\n"
    "    final level = _levelForSlot(slot);\n"
    "    final moveModifier = _bestMoveModifier(\n"
    "      move,\n"
    "      pokemon,\n"
    "      slot,\n"
    "      basePokemon: basePokemon,\n"
    "      formName: formName,\n"
    "    );",
)

replace_once(
    "            final attributes = _attributeScores(pokemon, activeSlot);",
    "            final attributes = _attributeScores(\n"
    "              pokemon,\n"
    "              activeSlot,\n"
    "              basePokemon: basePokemon,\n"
    "              formName: effectiveFormName,\n"
    "            );\n"
    "            final temporaryHpRule = _temporaryHpRule(data, activeSlot);\n"
    "            final temporaryHp = _temporaryHpBySlot[activeSlot.slotIndex] ?? 0;\n"
    "            final temporaryHpEnabled =\n"
    "                _temporaryHpEnabledBySlot[activeSlot.slotIndex] ?? false;",
)

replace_once(
    "                    pokemonForSlot: (slot) => _pokemonForSlot(data, slot),\n"
    "                    formNameForSlot: _effectiveFormName,",
    "                    pokemonForSlot: (slot) => _pokemonForSlot(data, slot),\n"
    "                    imagePokemonForSlot: (slot) =>\n"
    "                        data.pokemonById[slot.pokemonId],\n"
    "                    formNameForSlot: _effectiveFormName,",
)

replace_once(
    "                  _ActivePokemonCard(\n"
    "                    pokemon: pokemon,",
    "                  _ActivePokemonCard(\n"
    "                    pokemon: pokemon,\n"
    "                    imagePokemon: basePokemon,",
)

replace_once(
    "                    maxHp: _maxHpFor(pokemon, activeSlot),\n"
    "                    nonVolatileStatus: _nonVolatileStatusFor(activeSlot),",
    "                    maxHp: _maxHpFor(pokemon, activeSlot),\n"
    "                    temporaryHp: temporaryHp,\n"
    "                    temporaryHpRule: temporaryHpRule,\n"
    "                    temporaryHpEnabled: temporaryHpEnabled,\n"
    "                    nonVolatileStatus: _nonVolatileStatusFor(activeSlot),",
)

replace_once(
    "                    onOpenBag: () => _openQuickBag(data, activeSlot),\n"
    "                    onChangeForm: canChangeForm",
    "                    onOpenBag: () => _openQuickBag(data, activeSlot),\n"
    "                    onToggleTemporaryHp: temporaryHpRule == null\n"
    "                        ? null\n"
    "                        : (enabled) => _toggleTemporaryHpRule(\n"
    "                            data,\n"
    "                            activeSlot,\n"
    "                            enabled,\n"
    "                          ),\n"
    "                    onChangeForm: canChangeForm",
)

replace_once(
    "                               activeSlot,\n"
    "                               effectiveFormName,\n"
    "                             ),",
    "                               activeSlot,\n"
    "                               basePokemon,\n"
    "                               effectiveFormName,\n"
    "                             ),",
)

replace_once(
    "    required this.pokemonForSlot,\n"
    "    required this.formNameForSlot,",
    "    required this.pokemonForSlot,\n"
    "    required this.imagePokemonForSlot,\n"
    "    required this.formNameForSlot,",
)

replace_once(
    "  final Pokemon? Function(TeamSlot slot) pokemonForSlot;\n"
    "  final String? Function(TeamSlot slot) formNameForSlot;",
    "  final Pokemon? Function(TeamSlot slot) pokemonForSlot;\n"
    "  final Pokemon? Function(TeamSlot slot) imagePokemonForSlot;\n"
    "  final String? Function(TeamSlot slot) formNameForSlot;",
)

replace_once(
    "                         pokemon: pokemonForSlot(slot),\n"
    "                         formName: formNameForSlot(slot),",
    "                         pokemon: pokemonForSlot(slot),\n"
    "                         imagePokemon: imagePokemonForSlot(slot),\n"
    "                         formName: formNameForSlot(slot),",
)

replace_once(
    "    required this.pokemon,\n    required this.formName,",
    "    required this.pokemon,\n"
    "    required this.imagePokemon,\n"
    "    required this.formName,",
)

replace_once(
    "  final Pokemon? pokemon;\n  final String? formName;",
    "  final Pokemon? pokemon;\n"
    "  final Pokemon? imagePokemon;\n"
    "  final String? formName;",
)

replace_once(
    "                PokemonAssetImage(\n"
    "                  pokemon: pokemon,",
    "                PokemonAssetImage(\n"
    "                  pokemon: imagePokemon ?? pokemon,",
)

replace_once(
    "    required this.pokemon,\n    required this.slot,\n    required this.formName,",
    "    required this.pokemon,\n"
    "    required this.imagePokemon,\n"
    "    required this.slot,\n"
    "    required this.formName,",
)

replace_once(
    "    required this.maxHp,\n    required this.nonVolatileStatus,",
    "    required this.maxHp,\n"
    "    required this.temporaryHp,\n"
    "    required this.temporaryHpRule,\n"
    "    required this.temporaryHpEnabled,\n"
    "    required this.nonVolatileStatus,",
)

replace_once(
    "    required this.onOpenBag,\n    required this.onChangeForm,",
    "    required this.onOpenBag,\n"
    "    required this.onToggleTemporaryHp,\n"
    "    required this.onChangeForm,",
)

replace_once(
    "  final Pokemon pokemon;\n  final TeamSlot slot;",
    "  final Pokemon pokemon;\n"
    "  final Pokemon imagePokemon;\n"
    "  final TeamSlot slot;",
)

replace_once(
    "  final int maxHp;\n  final String? nonVolatileStatus;",
    "  final int maxHp;\n"
    "  final int temporaryHp;\n"
    "  final BattleTemporaryHpRule? temporaryHpRule;\n"
    "  final bool temporaryHpEnabled;\n"
    "  final String? nonVolatileStatus;",
)

replace_once(
    "  final VoidCallback onOpenBag;\n  final VoidCallback? onChangeForm;",
    "  final VoidCallback onOpenBag;\n"
    "  final ValueChanged<bool>? onToggleTemporaryHp;\n"
    "  final VoidCallback? onChangeForm;",
)

replace_once(
    "                 PokemonAssetImage(\n                   pokemon: pokemon,\n                   useLargeArtwork: true,",
    "                 PokemonAssetImage(\n"
    "                   pokemon: imagePokemon,\n"
    "                   useLargeArtwork: true,",
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
