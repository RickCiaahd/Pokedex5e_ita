import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/evolution_data.dart';
import '../../models/pokemon.dart';
import '../../models/team_slot.dart';
import '../../models/trainer_manual_options.dart';
import '../../models/trainer_progression.dart';
import '../../models/user_profile.dart';
import '../../repositories/evolution_repository.dart';
import '../../repositories/pokemon_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/team_repository.dart';

class TrainerSheetScreen extends StatefulWidget {
  const TrainerSheetScreen({super.key});

  @override
  State<TrainerSheetScreen> createState() => _TrainerSheetScreenState();
}

class _TrainerSheetScreenState extends State<TrainerSheetScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final PokemonRepository _pokemonRepository = PokemonRepository();
  final EvolutionRepository _evolutionRepository = EvolutionRepository();
  final TeamRepository _teamRepository = TeamRepository();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _moneyController = TextEditingController();
  final TextEditingController _raceController = TextEditingController();
  final TextEditingController _backgroundController = TextEditingController();

  UserProfile? _profile;
  List<Pokemon> _starterCandidates = [];
  List<TeamSlot> _team = [];
  int _trainerLevel = TrainerProgression.minLevel;
  Map<String, int> _abilityScores = {...UserProfile.defaultAbilityScores};
  int _armorClass = 10;
  int _maxHp = 8;
  int _currentHp = 8;
  int _speed = 30;
  String _startingPack = '';
  String _trainerPath = '';
  String _starterPokemon = '';
  List<String> _skillProficiencies = [];
  List<String> _specializations = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_refreshSheetPreview);
    _moneyController.addListener(_refreshSheetPreview);
    _raceController.addListener(_refreshSheetPreview);
    _backgroundController.addListener(_refreshSheetPreview);
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.removeListener(_refreshSheetPreview);
    _moneyController.removeListener(_refreshSheetPreview);
    _raceController.removeListener(_refreshSheetPreview);
    _backgroundController.removeListener(_refreshSheetPreview);
    _nameController.dispose();
    _moneyController.dispose();
    _raceController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  void _refreshSheetPreview() {
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
      final pokemon = await _pokemonRepository.getAllPokemon();
      final evolutionData = await _evolutionRepository.getEvolutionData();
      final team = await _teamRepository.getTeam(profile.id);
      final starterCandidates = _starterPokemonCandidates(
        pokemon,
        evolutionData,
      );

      if (!mounted) return;

      _nameController.text = profile.name;
      _moneyController.text = profile.money.toString();
      _raceController.text = profile.trainerRace;
      _backgroundController.text = profile.background;

      setState(() {
        _profile = profile;
        _starterCandidates = starterCandidates;
        _team = team..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
        _trainerLevel = TrainerProgression.clampLevel(profile.trainerLevel);
        _abilityScores = {...profile.abilityScores};
        _armorClass = profile.armorClass;
        _maxHp = profile.maxHp;
        _currentHp = profile.currentHp.clamp(0, profile.maxHp).toInt();
        _speed = profile.speed;
        _startingPack = profile.startingPack;
        _trainerPath = profile.trainerPath;
        _starterPokemon = profile.starterPokemon;
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

  List<Pokemon> _starterPokemonCandidates(
    List<Pokemon> pokemon,
    Map<String, EvolutionData> evolutionData,
  ) {
    final candidates = pokemon.where((pokemon) {
      final evolution = evolutionData[pokemon.name];
      final isFirstStage = evolution?.currentStage == null ||
          evolution!.currentStage <= 1;

      return pokemon.sr <= 0.5 && isFirstStage;
    }).toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    return candidates;
  }

  void _changeAbilityScore(String ability, int delta) {
    setState(() {
      final current = _abilityScores[ability] ?? 10;
      _abilityScores = {
        ..._abilityScores,
        ability: (current + delta).clamp(1, 30).toInt(),
      };
    });
  }

  void _changeArmorClass(int delta) {
    setState(() => _armorClass = (_armorClass + delta).clamp(1, 30).toInt());
  }

  void _changeMaxHp(int delta) {
    setState(() {
      _maxHp = (_maxHp + delta).clamp(1, 999).toInt();
      _currentHp = _currentHp.clamp(0, _maxHp).toInt();
    });
  }

  void _changeCurrentHp(int delta) {
    setState(() => _currentHp = (_currentHp + delta).clamp(0, _maxHp).toInt());
  }

  void _changeSpeed(int delta) {
    setState(() => _speed = (_speed + delta).clamp(0, 999).toInt());
  }

  void _changeStartingPack(String? pack) {
    setState(() => _startingPack = pack ?? '');
  }

  void _changeTrainerPath(String? path) {
    setState(() => _trainerPath = path ?? '');
  }

  void _changeRace(String? race) {
    if (race == null) return;

    _raceController.text = race;
    _refreshSheetPreview();
  }

  void _changeBackground(String? background) {
    if (background == null) return;

    _backgroundController.text = background;
    _refreshSheetPreview();
  }

  void _changeStarter(Pokemon pokemon) {
    setState(() => _starterPokemon = pokemon.name);
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
        abilityScores: _abilityScores,
        armorClass: _armorClass,
        maxHp: _maxHp,
        currentHp: _currentHp,
        speed: _speed,
        trainerRace: _raceController.text.trim(),
        background: _backgroundController.text.trim(),
        starterPokemon: _starterPokemon.trim(),
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

  Pokemon? get _selectedStarter {
    for (final pokemon in _starterCandidates) {
      if (pokemon.name == _starterPokemon) {
        return pokemon;
      }
    }

    return null;
  }

  bool get _starterAlreadyInTeam {
    final starter = _selectedStarter;
    if (starter == null) return false;

    return _team.any((slot) => slot.pokemonId == starter.id);
  }

  bool get _hasEmptyTeamSlot {
    return _team.any((slot) => slot.pokemonId == null);
  }

  Future<void> _openStarterPicker() async {
    final selected = await showModalBottomSheet<Pokemon>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _StarterPickerSheet(pokemon: _starterCandidates),
    );

    if (selected == null) return;
    _changeStarter(selected);
  }

  Future<void> _addStarterToTeam() async {
    final profile = _profile;
    final starter = _selectedStarter;
    if (profile == null || starter == null) return;

    final emptySlots = _team.where((slot) => slot.pokemonId == null).toList()
      ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
    if (emptySlots.isEmpty) return;

    await _profileRepository.saveProfile(
      profile.copyWith(starterPokemon: starter.name),
    );

    await _teamRepository.setPokemonInSlot(
      profileId: profile.id,
      slotIndex: emptySlots.first.slotIndex,
      pokemonId: starter.id,
    );

    await _loadProfile();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${starter.name} aggiunto alla squadra.')),
    );
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
              _TrainerSheetBoard(
                sheet: _TrainerSheetSummary(
                  name: _nameController.text.trim(),
                  race: _raceController.text.trim(),
                  background: _backgroundController.text.trim(),
                  starterPokemon: _starterPokemon.trim(),
                  trainerLevel: _trainerLevel,
                  money: int.tryParse(_moneyController.text.trim()) ?? 0,
                  abilityScores: _abilityScores,
                  armorClass: _armorClass,
                  maxHp: _maxHp,
                  currentHp: _currentHp,
                  speed: _speed,
                  skillProficiencies: _skillProficiencies,
                  specializations: _specializations,
                  trainerPath: _trainerPath,
                ),
                checklist: _TrainerCompletionChecklist(
                  race: _raceController.text.trim(),
                  background: _backgroundController.text.trim(),
                  starterPokemon: _starterPokemon.trim(),
                  startingPack: _startingPack,
                  trainerLevel: _trainerLevel,
                  trainerPath: _trainerPath,
                  skillProficiencies: _skillProficiencies,
                  specializations: _specializations,
                ),
                creation: _TrainerCreationForm(
                  raceController: _raceController,
                  backgroundController: _backgroundController,
                  selectedStarter: _selectedStarter,
                  startingPack: _startingPack,
                  trainerLevel: _trainerLevel,
                  trainerPath: _trainerPath,
                  skillProficiencies: _skillProficiencies,
                  specializations: _specializations,
                  canAddStarterToTeam: _selectedStarter != null &&
                      !_starterAlreadyInTeam &&
                      _hasEmptyTeamSlot,
                  starterAlreadyInTeam: _starterAlreadyInTeam,
                  onRaceChanged: _changeRace,
                  onBackgroundChanged: _changeBackground,
                  onStarterTap: _openStarterPicker,
                  onAddStarterToTeam: _addStarterToTeam,
                  onStartingPackChanged: _changeStartingPack,
                  onTrainerPathChanged: _changeTrainerPath,
                  onSkillToggle: _toggleSkill,
                  onSpecializationToggle: _toggleSpecialization,
                ),
                edit: _TrainerEditForm(
                  nameController: _nameController,
                  moneyController: _moneyController,
                  trainerLevel: _trainerLevel,
                  abilityScores: _abilityScores,
                  armorClass: _armorClass,
                  maxHp: _maxHp,
                  currentHp: _currentHp,
                  speed: _speed,
                  isSaving: _isSaving,
                  errorMessage: _errorMessage,
                  onDecreaseLevel: () => _changeLevel(-1),
                  onIncreaseLevel: () => _changeLevel(1),
                  onAbilityScoreChanged: _changeAbilityScore,
                  onArmorClassChanged: _changeArmorClass,
                  onMaxHpChanged: _changeMaxHp,
                  onCurrentHpChanged: _changeCurrentHp,
                  onSpeedChanged: _changeSpeed,
                  onSave: _saveProfile,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

int _abilityModifier(int score) {
  return ((score - 10) / 2).floor();
}

int _trainerProficiencyBonus(int level) {
  return 2 + ((TrainerProgression.clampLevel(level) - 1) ~/ 4);
}

String _signed(int value) {
  return value >= 0 ? '+$value' : '$value';
}

class _TrainerSheetBoard extends StatelessWidget {
  const _TrainerSheetBoard({
    required this.sheet,
    required this.checklist,
    required this.creation,
    required this.edit,
  });

  final Widget sheet;
  final Widget checklist;
  final Widget creation;
  final Widget edit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: Column(
                  children: [
                    sheet,
                    const SizedBox(height: 16),
                    edit,
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    checklist,
                    const SizedBox(height: 16),
                    creation,
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            sheet,
            const SizedBox(height: 16),
            checklist,
            const SizedBox(height: 16),
            creation,
            const SizedBox(height: 16),
            edit,
          ],
        );
      },
    );
  }
}

class _TrainerSheetSummary extends StatelessWidget {
  const _TrainerSheetSummary({
    required this.name,
    required this.race,
    required this.background,
    required this.starterPokemon,
    required this.trainerLevel,
    required this.money,
    required this.abilityScores,
    required this.armorClass,
    required this.maxHp,
    required this.currentHp,
    required this.speed,
    required this.skillProficiencies,
    required this.specializations,
    required this.trainerPath,
  });

  final String name;
  final String race;
  final String background;
  final String starterPokemon;
  final int trainerLevel;
  final int money;
  final Map<String, int> abilityScores;
  final int armorClass;
  final int maxHp;
  final int currentHp;
  final int speed;
  final List<String> skillProficiencies;
  final List<String> specializations;
  final String trainerPath;

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
    final currentFeatures = [
      for (final entry in TrainerManualOptions.trainerLevelFeatures.entries)
        if (entry.key <= trainerLevel)
          for (final feature in entry.value) 'Lv. ${entry.key}: $feature',
    ];
    final selectedSkills = [
      ...TrainerManualOptions.fixedSkillProficiencies,
      ...skillProficiencies,
    ];
    final selectedPath = TrainerManualOptions.trainerPaths.contains(trainerPath)
        ? trainerPath
        : '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name.isEmpty ? 'Scheda Allenatore' : name,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              [
                if (race.isNotEmpty) race,
                'Pokémon Trainer',
                if (background.isNotEmpty) background,
              ].join(' | '),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _TrainerStat(label: 'Livello', value: '$trainerLevel'),
                ),
                Expanded(
                  child: _TrainerStat(
                    label: 'Competenza',
                    value: _signed(_trainerProficiencyBonus(trainerLevel)),
                  ),
                ),
                Expanded(child: _TrainerStat(label: 'Soldi', value: '₽ $money')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _TrainerStat(label: 'CA', value: '$armorClass')),
                Expanded(
                  child: _TrainerStat(label: 'PF', value: '$currentHp/$maxHp'),
                ),
                Expanded(
                  child: _TrainerStat(label: 'Velocità', value: '$speed ft'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in UserProfile.defaultAbilityScores.entries)
                  _AbilityScoreTile(
                    label: entry.key,
                    score: abilityScores[entry.key] ?? entry.value,
                  ),
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
            if (starterPokemon.isNotEmpty) ...[
              const SizedBox(height: 16),
              _ManualBulletCard(
                title: 'Starter',
                bullets: [starterPokemon],
              ),
            ],
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
            const SizedBox(height: 16),
            _DescriptionListCard(
              title: 'Competenze attive',
              entries: {
                for (final skill in selectedSkills)
                  skill: TrainerManualOptions.skillNotes[skill] ?? '',
              },
            ),
            if (specializations.isNotEmpty) ...[
              const SizedBox(height: 16),
              _DescriptionListCard(
                title: 'Specializzazioni',
                entries: {
                  for (final specialization in specializations)
                    specialization:
                        TrainerManualOptions.specializationNotes[specialization] ??
                        '',
                },
              ),
            ],
            if (selectedPath.isNotEmpty) ...[
              const SizedBox(height: 16),
              _DescriptionListCard(
                title: 'Trainer Path',
                entries: {
                  selectedPath:
                      TrainerManualOptions.trainerPathNotes[selectedPath] ?? '',
                },
              ),
            ],
            const SizedBox(height: 16),
            _ManualBulletCard(
              title: 'Feature sbloccate',
              bullets: currentFeatures,
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainerCompletionChecklist extends StatelessWidget {
  const _TrainerCompletionChecklist({
    required this.race,
    required this.background,
    required this.starterPokemon,
    required this.startingPack,
    required this.trainerLevel,
    required this.trainerPath,
    required this.skillProficiencies,
    required this.specializations,
  });

  final String race;
  final String background;
  final String starterPokemon;
  final String startingPack;
  final int trainerLevel;
  final String trainerPath;
  final List<String> skillProficiencies;
  final List<String> specializations;

  @override
  Widget build(BuildContext context) {
    final items = [
      _ChecklistItem('Razza', race.isNotEmpty),
      _ChecklistItem('Background', background.isNotEmpty),
      _ChecklistItem('Starter Pokémon', starterPokemon.isNotEmpty),
      _ChecklistItem('Pack iniziale', startingPack.isNotEmpty),
      _ChecklistItem('2 competenze scelte', skillProficiencies.length == 2),
      _ChecklistItem('Specializzazione', specializations.isNotEmpty),
      _ChecklistItem(
        trainerLevel >= 2 ? 'Trainer Path' : 'Trainer Path dal livello 2',
        trainerLevel < 2 || trainerPath.isNotEmpty,
      ),
    ];
    final completed = items.where((item) => item.isComplete).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compilazione guidata',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('$completed/${items.length} passaggi completati'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in items)
                  Chip(
                    avatar: Icon(
                      item.isComplete
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 18,
                    ),
                    label: Text(item.label),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistItem {
  const _ChecklistItem(this.label, this.isComplete);

  final String label;
  final bool isComplete;
}

class _AbilityScoreTile extends StatelessWidget {
  const _AbilityScoreTile({required this.label, required this.score});

  final String label;
  final int score;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        width: 78,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              Text(
                '$score',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(_signed(_abilityModifier(score))),
            ],
          ),
        ),
      ),
    );
  }
}

class _DescriptionListCard extends StatelessWidget {
  const _DescriptionListCard({required this.title, required this.entries});

  final String title;
  final Map<String, String> entries;

  @override
  Widget build(BuildContext context) {
    return _ManualBulletCard(
      title: title,
      bullets: [
        for (final entry in entries.entries)
          entry.value.isEmpty ? entry.key : '${entry.key}: ${entry.value}',
      ],
    );
  }
}

class _StarterSelector extends StatelessWidget {
  const _StarterSelector({
    required this.pokemon,
    required this.alreadyInTeam,
    required this.canAddToTeam,
    required this.onPick,
    required this.onAddToTeam,
  });

  final Pokemon? pokemon;
  final bool alreadyInTeam;
  final bool canAddToTeam;
  final VoidCallback onPick;
  final VoidCallback onAddToTeam;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedPokemon = pokemon;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Starter Pokémon',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onPick,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.catching_pokemon),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        selectedPokemon == null
                            ? 'Scegli uno starter valido'
                            : selectedPokemon.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const Icon(Icons.expand_more),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Lista filtrata: primo stadio e SR 1/2 o inferiore.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            if (selectedPokemon != null) ...[
              const SizedBox(height: 10),
              if (alreadyInTeam)
                const Text('Starter gia presente in squadra.')
              else
                FilledButton.icon(
                  onPressed: canAddToTeam ? onAddToTeam : null,
                  icon: const Icon(Icons.group_add_outlined),
                  label: const Text('Aggiungi alla squadra'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SmallInfoChip extends StatelessWidget {
  const _SmallInfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w800,
          ),
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
    required this.selectedStarter,
    required this.startingPack,
    required this.trainerLevel,
    required this.trainerPath,
    required this.skillProficiencies,
    required this.specializations,
    required this.canAddStarterToTeam,
    required this.starterAlreadyInTeam,
    required this.onRaceChanged,
    required this.onBackgroundChanged,
    required this.onStarterTap,
    required this.onAddStarterToTeam,
    required this.onStartingPackChanged,
    required this.onTrainerPathChanged,
    required this.onSkillToggle,
    required this.onSpecializationToggle,
  });

  final TextEditingController raceController;
  final TextEditingController backgroundController;
  final Pokemon? selectedStarter;
  final String startingPack;
  final int trainerLevel;
  final String trainerPath;
  final List<String> skillProficiencies;
  final List<String> specializations;
  final bool canAddStarterToTeam;
  final bool starterAlreadyInTeam;
  final ValueChanged<String?> onRaceChanged;
  final ValueChanged<String?> onBackgroundChanged;
  final VoidCallback onStarterTap;
  final VoidCallback onAddStarterToTeam;
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
    final selectedRace = TrainerManualOptions.trainerRaces.contains(
      raceController.text.trim(),
    )
        ? raceController.text.trim()
        : null;
    final selectedBackground = TrainerManualOptions.backgroundOptions.contains(
      backgroundController.text.trim(),
    )
        ? backgroundController.text.trim()
        : null;

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
            DropdownButtonFormField<String>(
              initialValue: selectedRace,
              decoration: const InputDecoration(
                labelText: 'Razza / origine',
                helperText: 'Origini regionali Pokémon 5e o razza approvata dal DM.',
              ),
              items: [
                for (final race in TrainerManualOptions.trainerRaces)
                  DropdownMenuItem(value: race, child: Text(race)),
              ],
              onChanged: onRaceChanged,
            ),
            if (selectedRace != null) ...[
              const SizedBox(height: 8),
              Text(TrainerManualOptions.trainerRaceNotes[selectedRace] ?? ''),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedBackground,
              decoration: const InputDecoration(labelText: 'Background'),
              items: [
                for (final background in TrainerManualOptions.backgroundOptions)
                  DropdownMenuItem(value: background, child: Text(background)),
              ],
              onChanged: onBackgroundChanged,
            ),
            if (selectedBackground != null) ...[
              const SizedBox(height: 8),
              Text(
                TrainerManualOptions.backgroundNotes[selectedBackground] ?? '',
              ),
            ],
            const SizedBox(height: 12),
            _StarterSelector(
              pokemon: selectedStarter,
              alreadyInTeam: starterAlreadyInTeam,
              canAddToTeam: canAddStarterToTeam,
              onPick: onStarterTap,
              onAddToTeam: onAddStarterToTeam,
            ),
            if (selectedStarter != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final type in selectedStarter!.types)
                    _SmallInfoChip(label: type.toUpperCase()),
                  _SmallInfoChip(label: 'SR ${selectedStarter!.sr}'),
                  _SmallInfoChip(label: 'HP ${selectedStarter!.hitPoints}'),
                  _SmallInfoChip(label: 'CA ${selectedStarter!.armorClass}'),
                ],
              ),
            ],
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
    required this.abilityScores,
    required this.armorClass,
    required this.maxHp,
    required this.currentHp,
    required this.speed,
    required this.isSaving,
    required this.errorMessage,
    required this.onDecreaseLevel,
    required this.onIncreaseLevel,
    required this.onAbilityScoreChanged,
    required this.onArmorClassChanged,
    required this.onMaxHpChanged,
    required this.onCurrentHpChanged,
    required this.onSpeedChanged,
    required this.onSave,
  });

  final TextEditingController nameController;
  final TextEditingController moneyController;
  final int trainerLevel;
  final Map<String, int> abilityScores;
  final int armorClass;
  final int maxHp;
  final int currentHp;
  final int speed;
  final bool isSaving;
  final String? errorMessage;
  final VoidCallback onDecreaseLevel;
  final VoidCallback onIncreaseLevel;
  final void Function(String ability, int delta) onAbilityScoreChanged;
  final ValueChanged<int> onArmorClassChanged;
  final ValueChanged<int> onMaxHpChanged;
  final ValueChanged<int> onCurrentHpChanged;
  final ValueChanged<int> onSpeedChanged;
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
            const SizedBox(height: 20),
            Text(
              'Statistiche D&D',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _NumberStepper(
                  label: 'CA',
                  value: armorClass,
                  onDecrease: () => onArmorClassChanged(-1),
                  onIncrease: () => onArmorClassChanged(1),
                ),
                _NumberStepper(
                  label: 'PF attuali',
                  value: currentHp,
                  onDecrease: () => onCurrentHpChanged(-1),
                  onIncrease: () => onCurrentHpChanged(1),
                ),
                _NumberStepper(
                  label: 'PF max',
                  value: maxHp,
                  onDecrease: () => onMaxHpChanged(-1),
                  onIncrease: () => onMaxHpChanged(1),
                ),
                _NumberStepper(
                  label: 'Velocità',
                  value: speed,
                  onDecrease: () => onSpeedChanged(-5),
                  onIncrease: () => onSpeedChanged(5),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Caratteristiche',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final ability in UserProfile.defaultAbilityScores.keys)
                  _AbilityScoreEditor(
                    label: ability,
                    score: abilityScores[ability] ?? 10,
                    onDecrease: () => onAbilityScoreChanged(ability, -1),
                    onIncrease: () => onAbilityScoreChanged(ability, 1),
                  ),
              ],
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

class _NumberStepper extends StatelessWidget {
  const _NumberStepper({
    required this.label,
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String label;
  final int value;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        width: 124,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onDecrease,
                    icon: const Icon(Icons.remove),
                  ),
                  Text(
                    '$value',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onIncrease,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AbilityScoreEditor extends StatelessWidget {
  const _AbilityScoreEditor({
    required this.label,
    required this.score,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String label;
  final int score;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        width: 108,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              Text('Mod. ${_signed(_abilityModifier(score))}'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onDecrease,
                    icon: const Icon(Icons.remove),
                  ),
                  Text(
                    '$score',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onIncrease,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StarterPickerSheet extends StatefulWidget {
  const _StarterPickerSheet({required this.pokemon});

  final List<Pokemon> pokemon;

  @override
  State<_StarterPickerSheet> createState() => _StarterPickerSheetState();
}

class _StarterPickerSheetState extends State<_StarterPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredPokemon = widget.pokemon.where((pokemon) {
      final query = _query.toLowerCase().trim();

      return query.isEmpty ||
          pokemon.name.toLowerCase().contains(query) ||
          pokemon.id.toString().contains(query) ||
          pokemon.types.any((type) => type.toLowerCase().contains(query));
    }).toList();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.82,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scegli starter',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('Mostro solo Pokémon primo stadio con SR 1/2 o meno.'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Cerca per nome, numero o tipo...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() => _query = value);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                itemCount: filteredPokemon.length,
                itemBuilder: (context, index) {
                  final pokemon = filteredPokemon[index];
                  final number = '#${pokemon.id.toString().padLeft(3, '0')}';

                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      leading: const Icon(Icons.catching_pokemon),
                      title: Text(
                        pokemon.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '$number | ${pokemon.types.join(' / ')} | SR ${pokemon.sr} | HP ${pokemon.hitPoints} | CA ${pokemon.armorClass}',
                      ),
                      trailing: const Icon(Icons.check_circle_outline),
                      onTap: () {
                        Navigator.of(context).pop(pokemon);
                      },
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
