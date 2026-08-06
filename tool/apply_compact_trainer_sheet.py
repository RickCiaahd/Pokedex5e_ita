from pathlib import Path
import re


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f'{label}: expected 1 match, found {count}')
    return text.replace(old, new, 1)


def regex_once(text: str, pattern: str, replacement: str, label: str) -> str:
    updated, count = re.subn(pattern, lambda _: replacement, text, count=1, flags=re.S)
    if count != 1:
        raise RuntimeError(f'{label}: expected 1 match, found {count}')
    return updated


path = Path('lib/screens/trainer/trainer_sheet_screen.dart')
text = path.read_text(encoding='utf-8')

text = replace_once(
    text,
    "import '../../widgets/profile/trainer_profile_image_picker.dart';\n",
    "import '../../widgets/profile/trainer_profile_image_picker.dart';\nimport 'trainer_sheet_mobile.dart';\n",
    'mobile layout import',
)

text = replace_once(
    text,
    """        actions: [
          GuidedTourInfoAction(
""",
    """        actions: [
          IconButton(
            tooltip: context.uiText('Salva scheda', 'Save sheet'),
            onPressed: _isLoading || _profile == null || _isSaving
                ? null
                : _saveProfile,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
          ),
          GuidedTourInfoAction(
""",
    'app bar save button',
)

text = replace_once(
    text,
    """        builder: (context, _) {
          final selectedOriginName = _raceController.text.trim();
""",
    """        builder: (context, _) {
          final isCompactLayout = MediaQuery.sizeOf(context).width < 760;
          final selectedOriginName = _raceController.text.trim();
""",
    'compact layout flag',
)

text = replace_once(
    text,
    """                          errorMessage: _errorMessage,
                          onDecreaseLevel: () => _changeLevel(-1),
""",
    """                          errorMessage: _errorMessage,
                          mobileAdvancementFooter: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              KeyedSubtree(
                                key: _automationKey,
                                child: TrainerPathAutomationPanel(
                                  trainerPath: _trainerPath,
                                  resources: _trainerPathResourceDefinitions,
                                  resourceValues: _trainerPathResources,
                                  choices: _trainerPathChoiceDefinitions,
                                  choiceValues: _trainerPathChoices,
                                  onResourceChanged: _changeTrainerPathResource,
                                  onChoiceChanged: _changeTrainerPathChoice,
                                  onShortRest: () => _restoreTrainerPathResources(
                                    TrainerPathResourceReset.shortRest,
                                  ),
                                  onLongRest: () => _applyLongRest(),
                                ),
                              ),
                              if (_transformationUses.isNotEmpty ||
                                  _transformedPokemonKeys.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _TransformationRestCard(
                                  usedKinds: _transformationUses,
                                  pokemonCount: _transformedPokemonKeys.length,
                                  onLongRest: () => _applyLongRest(),
                                ),
                              ],
                            ],
                          ),
                          onDecreaseLevel: () => _changeLevel(-1),
""",
    'mobile advancement footer argument',
)

old_after_sheet = """                        const SizedBox(height: 16),
                        KeyedSubtree(
                          key: _automationKey,
                          child: TrainerPathAutomationPanel(
                            trainerPath: _trainerPath,
                            resources: _trainerPathResourceDefinitions,
                            resourceValues: _trainerPathResources,
                            choices: _trainerPathChoiceDefinitions,
                            choiceValues: _trainerPathChoices,
                            onResourceChanged: _changeTrainerPathResource,
                            onChoiceChanged: _changeTrainerPathChoice,
                            onShortRest: () => _restoreTrainerPathResources(
                              TrainerPathResourceReset.shortRest,
                            ),
                            onLongRest: () => _applyLongRest(),
                          ),
                        ),
                        if (_transformationUses.isNotEmpty ||
                            _transformedPokemonKeys.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _TransformationRestCard(
                            usedKinds: _transformationUses,
                            pokemonCount: _transformedPokemonKeys.length,
                            onLongRest: () => _applyLongRest(),
                          ),
                        ],
"""
new_after_sheet = """                        if (!isCompactLayout) ...[
                          const SizedBox(height: 16),
                          KeyedSubtree(
                            key: _automationKey,
                            child: TrainerPathAutomationPanel(
                              trainerPath: _trainerPath,
                              resources: _trainerPathResourceDefinitions,
                              resourceValues: _trainerPathResources,
                              choices: _trainerPathChoiceDefinitions,
                              choiceValues: _trainerPathChoices,
                              onResourceChanged: _changeTrainerPathResource,
                              onChoiceChanged: _changeTrainerPathChoice,
                              onShortRest: () => _restoreTrainerPathResources(
                                TrainerPathResourceReset.shortRest,
                              ),
                              onLongRest: () => _applyLongRest(),
                            ),
                          ),
                          if (_transformationUses.isNotEmpty ||
                              _transformedPokemonKeys.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _TransformationRestCard(
                              usedKinds: _transformationUses,
                              pokemonCount: _transformedPokemonKeys.length,
                              onLongRest: () => _applyLongRest(),
                            ),
                          ],
                        ],
"""
text = replace_once(text, old_after_sheet, new_after_sheet, 'desktop-only footer')

text = replace_once(
    text,
    """    required this.errorMessage,
    required this.onDecreaseLevel,
""",
    """    required this.errorMessage,
    required this.mobileAdvancementFooter,
    required this.onDecreaseLevel,
""",
    'interactive sheet constructor footer',
)

text = replace_once(
    text,
    """  final String? errorMessage;
  final VoidCallback onDecreaseLevel;
""",
    """  final String? errorMessage;
  final Widget mobileAdvancementFooter;
  final VoidCallback onDecreaseLevel;
""",
    'interactive sheet footer field',
)

mobile_return = """    if (width < 760) {
      return TrainerSheetMobile(
        nameController: nameController,
        profileImageBase64: profileImageBase64,
        moneyController: moneyController,
        race: race,
        raceDescription: raceDescription,
        selectedStarter: selectedStarter,
        startingPack: startingPack,
        trainerLevel: trainerLevel,
        trainerPath: trainerPath,
        trainerPaths: trainerPaths,
        abilityScores: abilityScores,
        armorClass: armorClass,
        maxHp: maxHp,
        currentHp: currentHp,
        speed: speed,
        pokeslots: pokeslots,
        maxSr: maxSr,
        skillProficiencies: skillProficiencies,
        savingThrowProficiencies: savingThrowProficiencies,
        specializations: specializations,
        canAddStarterToTeam: canAddStarterToTeam,
        starterAlreadyInTeam: starterAlreadyInTeam,
        isSaving: isSaving,
        errorMessage: errorMessage,
        onDecreaseLevel: onDecreaseLevel,
        onIncreaseLevel: onIncreaseLevel,
        onProfileImageChanged: onProfileImageChanged,
        onRaceTap: onRaceTap,
        onStarterTap: onStarterTap,
        onAddStarterToTeam: onAddStarterToTeam,
        onStartingPackTap: onStartingPackTap,
        onTrainerPathTap: onTrainerPathTap,
        onSkillToggle: onSkillToggle,
        onSavingThrowToggle: onSavingThrowToggle,
        onSpecializationTap: onSpecializationTap,
        onAbilityScoreChanged: onAbilityScoreChanged,
        onArmorClassChanged: onArmorClassChanged,
        onMaxHpChanged: onMaxHpChanged,
        onCurrentHpChanged: onCurrentHpChanged,
        onSpeedChanged: onSpeedChanged,
        advancementFooter: mobileAdvancementFooter,
      );
    }

"""
text = replace_once(
    text,
    """    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 980;

    return DecoratedBox(
""",
    """    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 980;

""" + mobile_return + """    return DecoratedBox(
""",
    'mobile sheet branch',
)

path.write_text(text, encoding='utf-8')
print('Compact trainer sheet patch applied.')
