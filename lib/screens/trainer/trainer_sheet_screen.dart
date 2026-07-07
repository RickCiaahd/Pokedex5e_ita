import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/trainer_manual_options.dart';
import '../../models/trainer_progression.dart';
import '../../models/user_profile.dart';
import '../../repositories/profile_repository.dart';

class TrainerSheetScreen extends StatefulWidget {
  const TrainerSheetScreen({super.key});

  @override
  State<TrainerSheetScreen> createState() => _TrainerSheetScreenState();
}

class _TrainerSheetScreenState extends State<TrainerSheetScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _moneyController = TextEditingController();
  final TextEditingController _raceController = TextEditingController();
  final TextEditingController _backgroundController = TextEditingController();
  final TextEditingController _starterController = TextEditingController();

  UserProfile? _profile;
  int _trainerLevel = TrainerProgression.minLevel;
  String _startingPack = '';
  String _trainerPath = '';
  List<String> _skillProficiencies = [];
  List<String> _specializations = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _moneyController.addListener(_refreshMoneySummary);
    _loadProfile();
  }

  @override
  void dispose() {
    _moneyController.removeListener(_refreshMoneySummary);
    _nameController.dispose();
    _moneyController.dispose();
    _raceController.dispose();
    _backgroundController.dispose();
    _starterController.dispose();
    super.dispose();
  }

  void _refreshMoneySummary() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _profileRepository.getActiveProfile();

      if (!mounted) return;

      _nameController.text = profile.name;
      _moneyController.text = profile.money.toString();
      _raceController.text = profile.trainerRace;
      _backgroundController.text = profile.background;
      _starterController.text = profile.starterPokemon;

      setState(() {
        _profile = profile;
        _trainerLevel = TrainerProgression.clampLevel(profile.trainerLevel);
        _startingPack = profile.startingPack;
        _trainerPath = profile.trainerPath;
        _skillProficiencies = [...profile.skillProficiencies];
        _specializations = [...profile.specializations];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _changeLevel(int delta) {
    setState(() {
      _trainerLevel = TrainerProgression.clampLevel(_trainerLevel + delta);
    });
  }

  void _changeStartingPack(String? pack) {
    setState(() => _startingPack = pack ?? '');
  }

  void _changeTrainerPath(String? path) {
    setState(() => _trainerPath = path ?? '');
  }

  void _toggleSkill(String skill) {
    setState(() {
      if (_skillProficiencies.contains(skill)) {
        _skillProficiencies.remove(skill);
      } else if (_skillProficiencies.length < 2) {
        _skillProficiencies = [..._skillProficiencies, skill];
      }
    });
  }

  void _toggleSpecialization(String specialization) {
    setState(() {
      if (_specializations.contains(specialization)) {
        _specializations.remove(specialization);
      } else {
        _specializations = [..._specializations, specialization];
      }
    });
  }

  Future<void> _saveProfile() async {
    final profile = _profile;
    if (profile == null) return;

    final name = _nameController.text.trim();
    final money = int.tryParse(_moneyController.text.trim());

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Inserisci un nome allenatore.');
      return;
    }

    if (money == null || money < 0) {
      setState(() => _errorMessage = 'Inserisci una quantita di soldi valida.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final updated = profile.copyWith(
        name: name,
        trainerLevel: _trainerLevel,
        money: money,
        trainerRace: _raceController.text.trim(),
        background: _backgroundController.text.trim(),
        starterPokemon: _starterController.text.trim(),
        startingPack: _startingPack,
        skillProficiencies: [..._skillProficiencies],
        specializations: [..._specializations],
        trainerPath: _trainerPath,
      );

      await _profileRepository.saveProfile(updated);

      if (!mounted) return;

      setState(() {
        _profile = updated;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scheda allenatore aggiornata.')),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scheda Allenatore')),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null && _profile == null)
              _TrainerSheetErrorState(
                message: _errorMessage!,
                onRetry: _loadProfile,
              )
            else ...[
              _TrainerSummary(
                trainerLevel: _trainerLevel,
                money: int.tryParse(_moneyController.text.trim()) ?? 0,
              ),
              const SizedBox(height: 20),
              _TrainerCreationForm(
                raceController: _raceController,
                backgroundController: _backgroundController,
                starterController: _starterController,
                startingPack: _startingPack,
                trainerLevel: _trainerLevel,
                trainerPath: _trainerPath,
                skillProficiencies: _skillProficiencies,
                specializations: _specializations,
                onStartingPackChanged: _changeStartingPack,
                onTrainerPathChanged: _changeTrainerPath,
                onSkillToggle: _toggleSkill,
                onSpecializationToggle: _toggleSpecialization,
              ),
              const SizedBox(height: 20),
              _TrainerEditForm(
                nameController: _nameController,
                moneyController: _moneyController,
                trainerLevel: _trainerLevel,
                isSaving: _isSaving,
                errorMessage: _errorMessage,
                onDecreaseLevel: () => _changeLevel(-1),
                onIncreaseLevel: () => _changeLevel(1),
                onSave: _saveProfile,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrainerSummary extends StatelessWidget {
  const _TrainerSummary({required this.trainerLevel, required this.money});

  final int trainerLevel;
  final int money;

  @override
  Widget build(BuildContext context) {
    final pokeslots = TrainerProgression.pokeslotsForLevel(trainerLevel);
    final maxSr = TrainerProgression.maxControlledSrForLevel(trainerLevel);
    final nextPokeslotLevel = TrainerProgression.nextPokeslotLevel(
      trainerLevel,
    );
    final nextControlLevel = TrainerProgression.nextControlUpgradeLevel(
      trainerLevel,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progressione campagna',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _TrainerStat(label: 'Livello', value: '$trainerLevel'),
                ),
                Expanded(child: _TrainerStat(label: 'Soldi', value: '₽ $money')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _TrainerStat(label: 'Pokéslot', value: '$pokeslots'),
                ),
                Expanded(child: _TrainerStat(label: 'SR max', value: '$maxSr')),
              ],
            ),
            const SizedBox(height: 16),
            _ManualBulletCard(
              title: 'Prossimi upgrade',
              bullets: [
                nextPokeslotLevel == null
                    ? 'Pokéslot: massimo gia raggiunto.'
                    : 'Nuovo Pokéslot al livello $nextPokeslotLevel.',
                nextControlLevel == null
                    ? 'Controllo SR: massimo gia raggiunto.'
                    : 'Nuovo limite SR al livello $nextControlLevel.',
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainerStat extends StatelessWidget {
  const _TrainerStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _TrainerCreationForm extends StatelessWidget {
  const _TrainerCreationForm({
    required this.raceController,
    required this.backgroundController,
    required this.starterController,
    required this.startingPack,
    required this.trainerLevel,
    required this.trainerPath,
    required this.skillProficiencies,
    required this.specializations,
    required this.onStartingPackChanged,
    required this.onTrainerPathChanged,
    required this.onSkillToggle,
    required this.onSpecializationToggle,
  });

  final TextEditingController raceController;
  final TextEditingController backgroundController;
  final TextEditingController starterController;
  final String startingPack;
  final int trainerLevel;
  final String trainerPath;
  final List<String> skillProficiencies;
  final List<String> specializations;
  final ValueChanged<String?> onStartingPackChanged;
  final ValueChanged<String?> onTrainerPathChanged;
  final ValueChanged<String> onSkillToggle;
  final ValueChanged<String> onSpecializationToggle;

  @override
  Widget build(BuildContext context) {
    final pathEnabled = trainerLevel >= 2;
    final selectedPack = TrainerManualOptions.startingPacks.contains(startingPack)
        ? startingPack
        : null;
    final selectedPath =
        TrainerManualOptions.trainerPaths.contains(trainerPath) ? trainerPath : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Creazione Trainer',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Dal manuale: razza 5e, classe Pokémon Trainer, Animal Handling, '
              'due competenze a scelta, starter, pack iniziale e specializzazione.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: raceController,
              decoration: const InputDecoration(
                labelText: 'Razza',
                helperText: 'Qualsiasi razza 5e approvata dal DM.',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: backgroundController,
              decoration: const InputDecoration(labelText: 'Background'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: starterController,
              decoration: const InputDecoration(
                labelText: 'Starter Pokémon',
                helperText: 'Unevolved, SR 1/2 o inferiore; natura e abilita a scelta.',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedPack,
              decoration: const InputDecoration(labelText: 'Pack iniziale'),
              items: [
                for (final pack in TrainerManualOptions.startingPacks)
                  DropdownMenuItem(value: pack, child: Text(pack)),
              ],
              onChanged: onStartingPackChanged,
            ),
            const SizedBox(height: 16),
            _ManualBulletCard(
              title: 'Equipaggiamento iniziale',
              bullets: const [
                '5 Pokéball',
                '1 potion',
                'Trainer License',
                'Pokédex',
                '₽ 1000 + ₽ 100 x 4d4',
              ],
            ),
            const SizedBox(height: 16),
            _ChoiceChipSection(
              title: 'Competenze',
              subtitle: 'Animal Handling e Charisma save sono fissi. Scegli due competenze.',
              options: TrainerManualOptions.skillChoices,
              selected: skillProficiencies,
              maxSelections: 2,
              onToggle: onSkillToggle,
            ),
            const SizedBox(height: 16),
            _ChoiceChipSection(
              title: 'Specializzazioni',
              subtitle: 'Scegline una al livello 1; il manuale consente '
                  'ulteriori scelte piu avanti.',
              options: TrainerManualOptions.specializations,
              selected: specializations,
              onToggle: onSpecializationToggle,
              descriptions: TrainerManualOptions.specializationNotes,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedPath,
              decoration: InputDecoration(
                labelText: 'Trainer Path',
                helperText: pathEnabled
                    ? 'Scelta disponibile dal livello 2.'
                    : 'Disponibile quando il trainer arriva al livello 2.',
              ),
              items: [
                for (final path in TrainerManualOptions.trainerPaths)
                  DropdownMenuItem(value: path, child: Text(path)),
              ],
              onChanged: pathEnabled ? onTrainerPathChanged : null,
            ),
            if (selectedPath != null) ...[
              const SizedBox(height: 8),
              Text(TrainerManualOptions.trainerPathNotes[selectedPath] ?? ''),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChoiceChipSection extends StatelessWidget {
  const _ChoiceChipSection({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selected,
    required this.onToggle,
    this.maxSelections,
    this.descriptions = const {},
  });

  final String title;
  final String subtitle;
  final List<String> options;
  final List<String> selected;
  final ValueChanged<String> onToggle;
  final int? maxSelections;
  final Map<String, String> descriptions;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        Text(subtitle),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              Tooltip(
                message: descriptions[option] ?? option,
                child: FilterChip(
                  label: Text(option),
                  selected: selected.contains(option),
                  onSelected: (_) => onToggle(option),
                ),
              ),
          ],
        ),
        if (maxSelections != null) ...[
          const SizedBox(height: 8),
          Text(
            '${selected.length}/$maxSelections selezionate',
            style: TextStyle(
              color: selected.length > maxSelections!
                  ? colorScheme.error
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _ManualBulletCard extends StatelessWidget {
  const _ManualBulletCard({required this.title, required this.bullets});

  final String title;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (final bullet in bullets)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $bullet'),
              ),
          ],
        ),
      ),
    );
  }
}

class _TrainerEditForm extends StatelessWidget {
  const _TrainerEditForm({
    required this.nameController,
    required this.moneyController,
    required this.trainerLevel,
    required this.isSaving,
    required this.errorMessage,
    required this.onDecreaseLevel,
    required this.onIncreaseLevel,
    required this.onSave,
  });

  final TextEditingController nameController;
  final TextEditingController moneyController;
  final int trainerLevel;
  final bool isSaving;
  final String? errorMessage;
  final VoidCallback onDecreaseLevel;
  final VoidCallback onIncreaseLevel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final pokeslots = TrainerProgression.pokeslotsForLevel(trainerLevel);
    final maxSr = TrainerProgression.maxControlledSrForLevel(trainerLevel);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dati allenatore',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nome allenatore'),
            ),
            const SizedBox(height: 20),
            Text(
              'Livello allenatore',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  tooltip: 'Diminuisci livello',
                  onPressed: trainerLevel <= TrainerProgression.minLevel
                      ? null
                      : onDecreaseLevel,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Lv. $trainerLevel',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text('Pokéslot $pokeslots | SR max $maxSr'),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Aumenta livello',
                  onPressed: trainerLevel >= TrainerProgression.maxLevel
                      ? null
                      : onIncreaseLevel,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: moneyController,
              decoration: const InputDecoration(
                labelText: 'Soldi',
                prefixText: '₽ ',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isSaving ? null : onSave,
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(isSaving ? 'Salvataggio...' : 'Salva scheda'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainerSheetErrorState extends StatelessWidget {
  const _TrainerSheetErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 16),
          Text('Errore: $message', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Riprova')),
        ],
      ),
    );
  }
}
