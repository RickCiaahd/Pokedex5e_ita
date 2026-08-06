import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../localization/ui_text.dart';
import '../../models/pokemon.dart';
import '../../models/trainer_manual_content.dart';
import '../../models/trainer_manual_options.dart';
import '../../models/trainer_progression.dart';
import '../../models/trainer_ui_localization.dart';
import '../../models/user_profile.dart';
import '../../widgets/profile/trainer_profile_image_picker.dart';

class TrainerSheetMobile extends StatefulWidget {
  const TrainerSheetMobile({
    super.key,
    required this.nameController,
    required this.profileImageBase64,
    required this.moneyController,
    required this.race,
    required this.raceDescription,
    required this.selectedStarter,
    required this.startingPack,
    required this.trainerLevel,
    required this.trainerPath,
    required this.trainerPaths,
    required this.abilityScores,
    required this.armorClass,
    required this.maxHp,
    required this.currentHp,
    required this.speed,
    required this.pokeslots,
    required this.maxSr,
    required this.skillProficiencies,
    required this.savingThrowProficiencies,
    required this.specializations,
    required this.canAddStarterToTeam,
    required this.starterAlreadyInTeam,
    required this.isSaving,
    required this.errorMessage,
    required this.onDecreaseLevel,
    required this.onIncreaseLevel,
    required this.onProfileImageChanged,
    required this.onRaceTap,
    required this.onStarterTap,
    required this.onAddStarterToTeam,
    required this.onStartingPackTap,
    required this.onTrainerPathTap,
    required this.onSkillToggle,
    required this.onSavingThrowToggle,
    required this.onSpecializationTap,
    required this.onAbilityScoreChanged,
    required this.onArmorClassChanged,
    required this.onMaxHpChanged,
    required this.onCurrentHpChanged,
    required this.onSpeedChanged,
    required this.advancementFooter,
  });

  final TextEditingController nameController;
  final String profileImageBase64;
  final TextEditingController moneyController;
  final String race;
  final String raceDescription;
  final Pokemon? selectedStarter;
  final String startingPack;
  final int trainerLevel;
  final String trainerPath;
  final List<TrainerPath> trainerPaths;
  final Map<String, int> abilityScores;
  final int armorClass;
  final int maxHp;
  final int currentHp;
  final int speed;
  final int pokeslots;
  final int maxSr;
  final List<String> skillProficiencies;
  final List<String> savingThrowProficiencies;
  final List<String> specializations;
  final bool canAddStarterToTeam;
  final bool starterAlreadyInTeam;
  final bool isSaving;
  final String? errorMessage;
  final VoidCallback onDecreaseLevel;
  final VoidCallback onIncreaseLevel;
  final ValueChanged<String> onProfileImageChanged;
  final VoidCallback onRaceTap;
  final VoidCallback onStarterTap;
  final VoidCallback onAddStarterToTeam;
  final VoidCallback onStartingPackTap;
  final VoidCallback onTrainerPathTap;
  final ValueChanged<String> onSkillToggle;
  final ValueChanged<String> onSavingThrowToggle;
  final void Function(int slotIndex) onSpecializationTap;
  final void Function(String ability, int delta) onAbilityScoreChanged;
  final ValueChanged<int> onArmorClassChanged;
  final ValueChanged<int> onMaxHpChanged;
  final ValueChanged<int> onCurrentHpChanged;
  final ValueChanged<int> onSpeedChanged;
  final Widget advancementFooter;

  @override
  State<TrainerSheetMobile> createState() => _TrainerSheetMobileState();
}

class _TrainerSheetMobileState extends State<TrainerSheetMobile> {
  int _sectionIndex = 0;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MobileSectionTabs(
              selectedIndex: _sectionIndex,
              onSelected: (value) => setState(() => _sectionIndex = value),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: switch (_sectionIndex) {
                1 => _MobileCompetencies(
                  key: const ValueKey('trainer-mobile-competencies'),
                  trainerLevel: widget.trainerLevel,
                  abilityScores: widget.abilityScores,
                  skillProficiencies: widget.skillProficiencies,
                  savingThrowProficiencies: widget.savingThrowProficiencies,
                  onAbilityScoreChanged: widget.onAbilityScoreChanged,
                  onSkillToggle: widget.onSkillToggle,
                  onSavingThrowToggle: widget.onSavingThrowToggle,
                ),
                2 => _MobileProgression(
                  key: const ValueKey('trainer-mobile-progression'),
                  trainerLevel: widget.trainerLevel,
                  trainerPath: widget.trainerPath,
                  trainerPaths: widget.trainerPaths,
                  specializations: widget.specializations,
                  onTrainerPathTap: widget.onTrainerPathTap,
                  onSpecializationTap: widget.onSpecializationTap,
                  footer: widget.advancementFooter,
                ),
                _ => _MobileOverview(
                  key: const ValueKey('trainer-mobile-overview'),
                  nameController: widget.nameController,
                  profileImageBase64: widget.profileImageBase64,
                  moneyController: widget.moneyController,
                  race: widget.race,
                  raceDescription: widget.raceDescription,
                  selectedStarter: widget.selectedStarter,
                  startingPack: widget.startingPack,
                  trainerLevel: widget.trainerLevel,
                  trainerPath: widget.trainerPath,
                  armorClass: widget.armorClass,
                  maxHp: widget.maxHp,
                  currentHp: widget.currentHp,
                  speed: widget.speed,
                  pokeslots: widget.pokeslots,
                  maxSr: widget.maxSr,
                  isSaving: widget.isSaving,
                  errorMessage: widget.errorMessage,
                  canAddStarterToTeam: widget.canAddStarterToTeam,
                  starterAlreadyInTeam: widget.starterAlreadyInTeam,
                  onDecreaseLevel: widget.onDecreaseLevel,
                  onIncreaseLevel: widget.onIncreaseLevel,
                  onProfileImageChanged: widget.onProfileImageChanged,
                  onRaceTap: widget.onRaceTap,
                  onStarterTap: widget.onStarterTap,
                  onAddStarterToTeam: widget.onAddStarterToTeam,
                  onStartingPackTap: widget.onStartingPackTap,
                  onArmorClassChanged: widget.onArmorClassChanged,
                  onMaxHpChanged: widget.onMaxHpChanged,
                  onCurrentHpChanged: widget.onCurrentHpChanged,
                  onSpeedChanged: widget.onSpeedChanged,
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileSectionTabs extends StatelessWidget {
  const _MobileSectionTabs({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final labels = [
      context.uiText('RIEPILOGO', 'SUMMARY'),
      context.uiText('COMPETENZE', 'SKILLS'),
      context.uiText('AVANZ.', 'PROGRESS'),
    ];
    final icons = [
      Icons.badge_outlined,
      Icons.fact_check_outlined,
      Icons.route,
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    vertical: 9,
                    horizontal: 3,
                  ),
                  decoration: BoxDecoration(
                    color: index == selectedIndex
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icons[index], size: 19),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          labels[index],
                          maxLines: 1,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MobileOverview extends StatelessWidget {
  const _MobileOverview({
    super.key,
    required this.nameController,
    required this.profileImageBase64,
    required this.moneyController,
    required this.race,
    required this.raceDescription,
    required this.selectedStarter,
    required this.startingPack,
    required this.trainerLevel,
    required this.trainerPath,
    required this.armorClass,
    required this.maxHp,
    required this.currentHp,
    required this.speed,
    required this.pokeslots,
    required this.maxSr,
    required this.isSaving,
    required this.errorMessage,
    required this.canAddStarterToTeam,
    required this.starterAlreadyInTeam,
    required this.onDecreaseLevel,
    required this.onIncreaseLevel,
    required this.onProfileImageChanged,
    required this.onRaceTap,
    required this.onStarterTap,
    required this.onAddStarterToTeam,
    required this.onStartingPackTap,
    required this.onArmorClassChanged,
    required this.onMaxHpChanged,
    required this.onCurrentHpChanged,
    required this.onSpeedChanged,
  });

  final TextEditingController nameController;
  final String profileImageBase64;
  final TextEditingController moneyController;
  final String race;
  final String raceDescription;
  final Pokemon? selectedStarter;
  final String startingPack;
  final int trainerLevel;
  final String trainerPath;
  final int armorClass;
  final int maxHp;
  final int currentHp;
  final int speed;
  final int pokeslots;
  final int maxSr;
  final bool isSaving;
  final String? errorMessage;
  final bool canAddStarterToTeam;
  final bool starterAlreadyInTeam;
  final VoidCallback onDecreaseLevel;
  final VoidCallback onIncreaseLevel;
  final ValueChanged<String> onProfileImageChanged;
  final VoidCallback onRaceTap;
  final VoidCallback onStarterTap;
  final VoidCallback onAddStarterToTeam;
  final VoidCallback onStartingPackTap;
  final ValueChanged<int> onArmorClassChanged;
  final ValueChanged<int> onMaxHpChanged;
  final ValueChanged<int> onCurrentHpChanged;
  final ValueChanged<int> onSpeedChanged;

  @override
  Widget build(BuildContext context) {
    final nextPokeslot = TrainerProgression.nextPokeslotLevel(trainerLevel);
    final nextControl = TrainerProgression.nextControlUpgradeLevel(
      trainerLevel,
    );
    final progressionNotes = <String>[
      if (nextPokeslot != null)
        context.uiText(
          'Nuovo Pokéslot al livello $nextPokeslot',
          'New Poké Slot at level $nextPokeslot',
        ),
      if (nextControl != null)
        context.uiText(
          'Nuovo limite SR al livello $nextControl',
          'New SR limit at level $nextControl',
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 108,
              child: TrainerProfileImagePicker(
                imageBase64: profileImageBase64,
                trainerName: nameController.text,
                compact: true,
                editButtonOnly: true,
                enabled: !isSaving,
                onChanged: onProfileImageChanged,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameController,
                    enabled: !isSaving,
                    decoration: InputDecoration(
                      labelText: context.uiText('Nome', 'Name'),
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _CompactChoiceLine(
                    label: context.uiText('LIVELLO', 'LEVEL'),
                    value: '$trainerLevel',
                    onTap: () => _showCounterSheet(
                      context: context,
                      title: context.uiText(
                        'Livello allenatore',
                        'Trainer level',
                      ),
                      initialValue: trainerLevel,
                      minValue: TrainerProgression.minLevel,
                      maxValue: TrainerProgression.maxLevel,
                      onDecrease: onDecreaseLevel,
                      onIncrease: onIncreaseLevel,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _InfoChip(
              label: 'COMP',
              value: _signed(_proficiency(trainerLevel)),
            ),
            _InfoChip(
              label: context.uiText('SLOT', 'SLOTS'),
              value: '$pokeslots',
            ),
            _InfoChip(label: 'SR', value: '$maxSr'),
            if (trainerPath.trim().isNotEmpty)
              _InfoChip(
                label: context.uiText('PERCORSO', 'PATH'),
                value: TrainerUiLocalization.trainerPathName(trainerPath),
              ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: moneyController,
          enabled: !isSaving,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: context.uiText('Pokédollars', 'Pokédollars'),
            prefixText: '₽ ',
            isDense: true,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        _CompactChoiceCard(
          icon: Icons.public_outlined,
          label: context.uiText('ORIGINE', 'ORIGIN'),
          value: race.isEmpty ? context.uiText('Scegli', 'Choose') : race,
          detail: race.isEmpty
              ? context.uiText(
                  'Tocca per scegliere dal manuale.',
                  'Tap to choose from the manual.',
                )
              : _compactOriginDetail(raceDescription),
          onTap: onRaceTap,
        ),
        const SizedBox(height: 12),
        _MobileSectionTitle(title: context.uiText('COMBATTIMENTO', 'COMBAT')),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _CompactStatTile(
                label: context.uiText('CA', 'AC'),
                value: '$armorClass',
                onTap: () => _showCounterSheet(
                  context: context,
                  title: context.uiText('Classe Armatura', 'Armor Class'),
                  initialValue: armorClass,
                  minValue: 1,
                  maxValue: 30,
                  onDecrease: () => onArmorClassChanged(-1),
                  onIncrease: () => onArmorClassChanged(1),
                ),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _CompactStatTile(
                label: context.uiText('PF', 'HP'),
                value: '$currentHp/$maxHp',
                onTap: () => _showHpSheet(
                  context: context,
                  currentHp: currentHp,
                  maxHp: maxHp,
                  onCurrentChanged: onCurrentHpChanged,
                  onMaxChanged: onMaxHpChanged,
                ),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _CompactStatTile(
                label: context.uiText('VELOCITÀ', 'SPEED'),
                value: context.uiText('$speed ft', '$speed ft'),
                onTap: () => _showCounterSheet(
                  context: context,
                  title: context.uiText('Velocità', 'Speed'),
                  initialValue: speed,
                  minValue: 0,
                  maxValue: 999,
                  step: 5,
                  onDecrease: () => onSpeedChanged(-5),
                  onIncrease: () => onSpeedChanged(5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _CompactChoiceCard(
          icon: Icons.catching_pokemon,
          label: context.uiText('STARTER', 'STARTER'),
          value: selectedStarter?.name ?? context.uiText('Scegli', 'Choose'),
          detail: selectedStarter == null
              ? context.uiText(
                  'Scegli il Pokémon iniziale.',
                  'Choose the starter Pokémon.',
                )
              : selectedStarter!.types.join(' · '),
          onTap: onStarterTap,
          actionLabel: canAddStarterToTeam
              ? context.uiText('AGGIUNGI', 'ADD')
              : starterAlreadyInTeam
              ? context.uiText('IN SQUADRA', 'IN TEAM')
              : null,
          onAction: canAddStarterToTeam ? onAddStarterToTeam : null,
        ),
        const SizedBox(height: 8),
        _CompactChoiceCard(
          icon: Icons.backpack_outlined,
          label: context.uiText('DOTAZIONE', 'STARTING PACK'),
          value: startingPack.isEmpty
              ? context.uiText('Scegli', 'Choose')
              : TrainerUiLocalization.startingPackName(startingPack),
          onTap: onStartingPackTap,
        ),
        if (progressionNotes.isNotEmpty) ...[
          const SizedBox(height: 10),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.trending_up, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      progressionNotes.join(' · '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (errorMessage != null) ...[
          const SizedBox(height: 10),
          Text(
            errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }

  String _compactOriginDetail(String description) {
    final normalized = description.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 150) return normalized;
    return '${normalized.substring(0, 147)}…';
  }
}

class _MobileCompetencies extends StatelessWidget {
  const _MobileCompetencies({
    super.key,
    required this.trainerLevel,
    required this.abilityScores,
    required this.skillProficiencies,
    required this.savingThrowProficiencies,
    required this.onAbilityScoreChanged,
    required this.onSkillToggle,
    required this.onSavingThrowToggle,
  });

  final int trainerLevel;
  final Map<String, int> abilityScores;
  final List<String> skillProficiencies;
  final List<String> savingThrowProficiencies;
  final void Function(String ability, int delta) onAbilityScoreChanged;
  final ValueChanged<String> onSkillToggle;
  final ValueChanged<String> onSavingThrowToggle;

  @override
  Widget build(BuildContext context) {
    final abilities = UserProfile.defaultAbilityScores.entries.toList();
    final selectedSkills = {
      ...TrainerManualOptions.fixedSkillProficiencies,
      ...skillProficiencies,
    };
    final selectedSavingThrows = {
      ...TrainerManualOptions.fixedSavingThrowProficiencies,
      ...savingThrowProficiencies,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MobileSectionTitle(
          title: context.uiText('CARATTERISTICHE', 'ABILITY SCORES'),
        ),
        const SizedBox(height: 8),
        for (var row = 0; row < 2; row++) ...[
          Row(
            children: [
              for (var column = 0; column < 3; column++) ...[
                if (column > 0) const SizedBox(width: 7),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final entry = abilities[(row * 3) + column];
                      final score = abilityScores[entry.key] ?? entry.value;
                      return _CompactAbilityTile(
                        label: TrainerUiLocalization.abilityAbbreviation(
                          entry.key,
                        ),
                        score: score,
                        modifier: _abilityModifier(score),
                        onTap: () => _showAbilitySheet(
                          context: context,
                          ability: entry.key,
                          score: score,
                          onChanged: onAbilityScoreChanged,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
          if (row == 0) const SizedBox(height: 7),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MobileSectionTitle(
                title: context.uiText(
                  'ABILITÀ COMPETENTI',
                  'SKILL PROFICIENCIES',
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _showSkillsSheet(
                context: context,
                trainerLevel: trainerLevel,
                abilityScores: abilityScores,
                skillProficiencies: skillProficiencies,
                onToggle: onSkillToggle,
              ),
              icon: const Icon(Icons.tune, size: 18),
              label: Text(context.uiText('GESTISCI', 'MANAGE')),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (selectedSkills.isEmpty)
          Text(
            context.uiText(
              'Nessuna competenza selezionata.',
              'No skill proficiency selected.',
            ),
          )
        else
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (final skill in TrainerManualOptions.skills)
                  if (selectedSkills.contains(skill.name))
                    ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      title: Text(
                        '${TrainerUiLocalization.skillName(skill.name)} (${TrainerUiLocalization.abilityAbbreviation(skill.ability)})',
                        maxLines: 2,
                      ),
                      trailing: Text(
                        _signed(
                          _checkTotal(
                            abilityScores: abilityScores,
                            trainerLevel: trainerLevel,
                            ability: skill.ability,
                            proficient: true,
                          ),
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MobileSectionTitle(
                title: context.uiText('TIRI SALVEZZA', 'SAVING THROWS'),
              ),
            ),
            TextButton.icon(
              onPressed: () => _showSavingThrowsSheet(
                context: context,
                trainerLevel: trainerLevel,
                abilityScores: abilityScores,
                savingThrowProficiencies: savingThrowProficiencies,
                onToggle: onSavingThrowToggle,
              ),
              icon: const Icon(Icons.tune, size: 18),
              label: Text(context.uiText('GESTISCI', 'MANAGE')),
            ),
          ],
        ),
        const SizedBox(height: 6),
        for (var row = 0; row < 2; row++) ...[
          Row(
            children: [
              for (var column = 0; column < 3; column++) ...[
                if (column > 0) const SizedBox(width: 7),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final ability =
                          TrainerManualOptions.savingThrows[(row * 3) + column];
                      final proficient = selectedSavingThrows.contains(ability);
                      return _SavingThrowTile(
                        label: TrainerUiLocalization.abilityAbbreviation(
                          ability,
                        ),
                        value: _signed(
                          _checkTotal(
                            abilityScores: abilityScores,
                            trainerLevel: trainerLevel,
                            ability: ability,
                            proficient: proficient,
                          ),
                        ),
                        proficient: proficient,
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
          if (row == 0) const SizedBox(height: 7),
        ],
      ],
    );
  }
}

class _MobileProgression extends StatelessWidget {
  const _MobileProgression({
    super.key,
    required this.trainerLevel,
    required this.trainerPath,
    required this.trainerPaths,
    required this.specializations,
    required this.onTrainerPathTap,
    required this.onSpecializationTap,
    required this.footer,
  });

  final int trainerLevel;
  final String trainerPath;
  final List<TrainerPath> trainerPaths;
  final List<String> specializations;
  final VoidCallback onTrainerPathTap;
  final void Function(int slotIndex) onSpecializationTap;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final entries = _entries(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MobileSectionTitle(
          title: context.uiText('AVANZAMENTO', 'PROGRESSION'),
          trailing: context.uiText('LV $trainerLevel', 'LV $trainerLevel'),
        ),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              for (var index = 0; index < entries.length; index++) ...[
                _ProgressionRow(entry: entries[index]),
                if (index < entries.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        footer,
      ],
    );
  }

  List<_ProgressionEntry> _entries(BuildContext context) {
    final result = <_ProgressionEntry>[
      _ProgressionEntry(
        level: 1,
        label: context.uiText('Specializzazione', 'Specialization'),
        value: _specializationAt(0).isEmpty
            ? context.uiText('Scegli specializzazione', 'Choose specialization')
            : TrainerUiLocalization.specializationName(_specializationAt(0)),
        detail: _specializationAt(0).isEmpty
            ? context.uiText(
                'Scegli una specializzazione sbloccata al livello 1.',
                'Choose a specialization unlocked at level 1.',
              )
            : TrainerManualOptions.specializationNote(_specializationAt(0)),
        onTap: () => onSpecializationTap(0),
        editable: true,
      ),
    ];

    if (trainerLevel >= 2) {
      final feature = _pathFeature(2);
      result.add(
        _ProgressionEntry(
          level: 2,
          label: context.uiText('Percorso Allenatore', 'Trainer Path'),
          value: trainerPath.isEmpty
              ? context.uiText('Scegli percorso', 'Choose path')
              : TrainerUiLocalization.trainerPathName(trainerPath),
          detail: trainerPath.isEmpty
              ? context.uiText(
                  'Scegli il Percorso Allenatore.',
                  'Choose the Trainer Path.',
                )
              : TrainerUiLocalization.visibleText(feature?.description ?? ''),
          onTap: onTrainerPathTap,
          editable: true,
        ),
      );
    }

    for (final level in [5, 9, 15]) {
      if (trainerLevel < level) continue;
      final feature = _pathFeature(level);
      result.add(
        _ProgressionEntry(
          level: level,
          label: context.uiText('Privilegio del percorso', 'Path feature'),
          value: feature == null
              ? context.uiText('Percorso non scelto', 'No path selected')
              : TrainerUiLocalization.featureName(feature.title),
          detail: feature == null
              ? context.uiText(
                  'Scegli il percorso al livello 2.',
                  'Choose the path at level 2.',
                )
              : TrainerUiLocalization.visibleText(feature.description),
        ),
      );
    }

    if (trainerLevel >= 7) {
      result.add(
        _ProgressionEntry(
          level: 7,
          label: context.uiText('Specializzazione', 'Specialization'),
          value: _specializationAt(1).isEmpty
              ? context.uiText(
                  'Scegli specializzazione',
                  'Choose specialization',
                )
              : TrainerUiLocalization.specializationName(_specializationAt(1)),
          detail: _specializationAt(1).isEmpty
              ? context.uiText(
                  'Scegli la specializzazione del livello 7.',
                  'Choose the level 7 specialization.',
                )
              : TrainerManualOptions.specializationNote(_specializationAt(1)),
          onTap: () => onSpecializationTap(1),
          editable: true,
        ),
      );
    }

    if (trainerLevel >= 18) {
      result.add(
        _ProgressionEntry(
          level: 18,
          label: context.uiText('Specializzazione', 'Specialization'),
          value: _specializationAt(2).isEmpty
              ? context.uiText(
                  'Scegli specializzazione',
                  'Choose specialization',
                )
              : TrainerUiLocalization.specializationName(_specializationAt(2)),
          detail: _specializationAt(2).isEmpty
              ? context.uiText(
                  'Scegli la specializzazione del livello 18.',
                  'Choose the level 18 specialization.',
                )
              : TrainerManualOptions.specializationNote(_specializationAt(2)),
          onTap: () => onSpecializationTap(2),
          editable: true,
        ),
      );
    }

    result.sort((a, b) => a.level.compareTo(b.level));
    return result;
  }

  String _specializationAt(int index) {
    return index < specializations.length ? specializations[index] : '';
  }

  TrainerPathFeature? _pathFeature(int level) {
    for (final path in trainerPaths) {
      if (path.name == trainerPath) return path.featureForLevel(level);
    }
    return null;
  }
}

class _ProgressionEntry {
  const _ProgressionEntry({
    required this.level,
    required this.label,
    required this.value,
    required this.detail,
    this.onTap,
    this.editable = false,
  });

  final int level;
  final String label;
  final String value;
  final String detail;
  final VoidCallback? onTap;
  final bool editable;
}

class _ProgressionRow extends StatelessWidget {
  const _ProgressionRow({required this.entry});

  final _ProgressionEntry entry;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: CircleAvatar(
        radius: 20,
        child: Text(
          'LV\n${entry.level}',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
      title: Text(
        entry.label.toUpperCase(),
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(
        entry.value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
      trailing: Icon(entry.editable ? Icons.edit_outlined : Icons.info_outline),
      onTap:
          entry.onTap ??
          () => _showTextSheet(context, entry.value, entry.detail),
    );
  }
}

class _CompactChoiceLine extends StatelessWidget {
  const _CompactChoiceLine({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const Spacer(),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(width: 4),
            const Icon(Icons.edit_outlined, size: 17),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text('$label $value'),
      labelStyle: const TextStyle(fontWeight: FontWeight.w800),
    );
  }
}

class _MobileSectionTitle extends StatelessWidget {
  const _MobileSectionTitle({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ),
        if (trailing != null)
          Text(trailing!, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _CompactChoiceCard extends StatelessWidget {
  const _CompactChoiceCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.detail,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? detail;
  final VoidCallback onTap;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (detail != null && detail!.trim().isNotEmpty)
                      Text(
                        detail!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              if (actionLabel != null)
                TextButton(onPressed: onAction, child: Text(actionLabel!))
              else
                const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactStatTile extends StatelessWidget {
  const _CompactStatTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactAbilityTile extends StatelessWidget {
  const _CompactAbilityTile({
    required this.label,
    required this.score,
    required this.modifier,
    required this.onTap,
  });

  final String label;
  final int score;
  final int modifier;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
              Text(
                '$score',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              Text(
                _signed(modifier),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavingThrowTile extends StatelessWidget {
  const _SavingThrowTile({
    required this.label,
    required this.value,
    required this.proficient,
  });

  final String label;
  final String value;
  final bool proficient;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: proficient
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (proficient) ...[
                  const Icon(Icons.check_circle, size: 14),
                  const SizedBox(width: 3),
                ],
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

int _abilityModifier(int score) => ((score - 10) / 2).floor();

int _proficiency(int level) {
  return 2 + ((TrainerProgression.clampLevel(level) - 1) ~/ 4);
}

int _checkTotal({
  required Map<String, int> abilityScores,
  required int trainerLevel,
  required String ability,
  required bool proficient,
}) {
  final score =
      abilityScores[ability] ?? UserProfile.defaultAbilityScores[ability] ?? 10;
  return _abilityModifier(score) +
      (proficient ? _proficiency(trainerLevel) : 0);
}

String _signed(int value) => value >= 0 ? '+$value' : '$value';

Future<void> _showTextSheet(
  BuildContext context,
  String title,
  String description,
) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(description),
        ],
      ),
    ),
  );
}

Future<void> _showCounterSheet({
  required BuildContext context,
  required String title,
  required int initialValue,
  required int minValue,
  required int maxValue,
  required VoidCallback onDecrease,
  required VoidCallback onIncrease,
  int step = 1,
}) {
  var value = initialValue;
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed: value <= minValue
                        ? null
                        : () {
                            onDecrease();
                            setSheetState(
                              () => value = (value - step).clamp(
                                minValue,
                                maxValue,
                              ),
                            );
                          },
                    icon: const Icon(Icons.remove),
                  ),
                  SizedBox(
                    width: 110,
                    child: Text(
                      '$value',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: value >= maxValue
                        ? null
                        : () {
                            onIncrease();
                            setSheetState(
                              () => value = (value + step).clamp(
                                minValue,
                                maxValue,
                              ),
                            );
                          },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}

Future<void> _showHpSheet({
  required BuildContext context,
  required int currentHp,
  required int maxHp,
  required ValueChanged<int> onCurrentChanged,
  required ValueChanged<int> onMaxChanged,
}) {
  var current = currentHp;
  var maximum = maxHp;
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) {
        Widget counter({
          required String label,
          required int value,
          required VoidCallback? decrease,
          required VoidCallback increase,
        }) {
          return Column(
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: decrease,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text(
                      '$value',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: increase,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.uiText('Punti Ferita', 'Hit Points'),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              counter(
                label: context.uiText('PF attuali', 'Current HP'),
                value: current,
                decrease: current <= 0
                    ? null
                    : () {
                        onCurrentChanged(-1);
                        setSheetState(() => current -= 1);
                      },
                increase: () {
                  if (current >= maximum) return;
                  onCurrentChanged(1);
                  setSheetState(() => current += 1);
                },
              ),
              const Divider(),
              counter(
                label: context.uiText('PF massimi', 'Maximum HP'),
                value: maximum,
                decrease: maximum <= 1
                    ? null
                    : () {
                        onMaxChanged(-1);
                        setSheetState(() {
                          maximum -= 1;
                          if (current > maximum) current = maximum;
                        });
                      },
                increase: () {
                  onMaxChanged(1);
                  setSheetState(() => maximum += 1);
                },
              ),
            ],
          ),
        );
      },
    ),
  );
}

Future<void> _showAbilitySheet({
  required BuildContext context,
  required String ability,
  required int score,
  required void Function(String ability, int delta) onChanged,
}) {
  var current = score;
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                TrainerUiLocalization.abilityAbbreviation(ability),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                context.uiText(
                  'Modificatore ${_signed(_abilityModifier(current))}',
                  'Modifier ${_signed(_abilityModifier(current))}',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed: current <= 1
                        ? null
                        : () {
                            onChanged(ability, -1);
                            setSheetState(() => current -= 1);
                          },
                    icon: const Icon(Icons.remove),
                  ),
                  SizedBox(
                    width: 110,
                    child: Text(
                      '$current',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: current >= 30
                        ? null
                        : () {
                            onChanged(ability, 1);
                            setSheetState(() => current += 1);
                          },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}

Future<void> _showSkillsSheet({
  required BuildContext context,
  required int trainerLevel,
  required Map<String, int> abilityScores,
  required List<String> skillProficiencies,
  required ValueChanged<String> onToggle,
}) {
  final selected = {
    ...TrainerManualOptions.fixedSkillProficiencies,
    ...skillProficiencies,
  };
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) {
        return SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.82,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  context.uiText('Gestisci abilità', 'Manage skills'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 18),
                  itemCount: TrainerManualOptions.skills.length,
                  itemBuilder: (context, index) {
                    final skill = TrainerManualOptions.skills[index];
                    final locked = TrainerManualOptions.fixedSkillProficiencies
                        .contains(skill.name);
                    final checked = selected.contains(skill.name);
                    final total = _checkTotal(
                      abilityScores: abilityScores,
                      trainerLevel: trainerLevel,
                      ability: skill.ability,
                      proficient: checked,
                    );
                    return CheckboxListTile(
                      dense: true,
                      value: checked,
                      onChanged: locked
                          ? null
                          : (_) {
                              onToggle(skill.name);
                              setSheetState(() {
                                if (checked) {
                                  selected.remove(skill.name);
                                } else {
                                  selected.add(skill.name);
                                }
                              });
                            },
                      title: Text(
                        '${TrainerUiLocalization.skillName(skill.name)} (${TrainerUiLocalization.abilityAbbreviation(skill.ability)})',
                      ),
                      secondary: Text(
                        _signed(total),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

Future<void> _showSavingThrowsSheet({
  required BuildContext context,
  required int trainerLevel,
  required Map<String, int> abilityScores,
  required List<String> savingThrowProficiencies,
  required ValueChanged<String> onToggle,
}) {
  final selected = {
    ...TrainerManualOptions.fixedSavingThrowProficiencies,
    ...savingThrowProficiencies,
  };
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.uiText(
                  'Gestisci tiri salvezza',
                  'Manage saving throws',
                ),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              for (final ability in TrainerManualOptions.savingThrows)
                Builder(
                  builder: (context) {
                    final locked = TrainerManualOptions
                        .fixedSavingThrowProficiencies
                        .contains(ability);
                    final checked = selected.contains(ability);
                    return CheckboxListTile(
                      dense: true,
                      value: checked,
                      onChanged: locked
                          ? null
                          : (_) {
                              onToggle(ability);
                              setSheetState(() {
                                if (checked) {
                                  selected.remove(ability);
                                } else {
                                  selected.add(ability);
                                }
                              });
                            },
                      title: Text(
                        TrainerUiLocalization.abilityAbbreviation(ability),
                      ),
                      secondary: Text(
                        _signed(
                          _checkTotal(
                            abilityScores: abilityScores,
                            trainerLevel: trainerLevel,
                            ability: ability,
                            proficient: checked,
                          ),
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    ),
  );
}
