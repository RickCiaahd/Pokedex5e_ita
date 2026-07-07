import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/evolution_data.dart';
import '../../models/pokemon.dart';
import '../../models/team_slot.dart';
import '../../models/trainer_manual_content.dart';
import '../../models/trainer_manual_options.dart';
import '../../models/trainer_progression.dart';
import '../../models/user_profile.dart';
import '../../repositories/evolution_repository.dart';
import '../../repositories/pokemon_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/team_repository.dart';
import '../../repositories/trainer_manual_repository.dart';

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
  final TrainerManualRepository _trainerManualRepository =
      TrainerManualRepository();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _moneyController = TextEditingController();
  final TextEditingController _raceController = TextEditingController();

  UserProfile? _profile;
  List<Pokemon> _starterCandidates = [];
  List<TrainerOrigin> _trainerOrigins = [];
  List<TrainerPath> _trainerPaths = [];
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
  String _originAbilityBonusSource = '';
  List<String> _skillProficiencies = [];
  List<String> _savingThrowProficiencies = [];
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
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.removeListener(_refreshSheetPreview);
    _moneyController.removeListener(_refreshSheetPreview);
    _raceController.removeListener(_refreshSheetPreview);
    _nameController.dispose();
    _moneyController.dispose();
    _raceController.dispose();
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
      final trainerOrigins = await _trainerManualRepository.getOrigins();
      final trainerPaths = await _trainerManualRepository.getTrainerPaths();
      final starterCandidates = _starterPokemonCandidates(
        pokemon,
        evolutionData,
      );

      if (!mounted) return;

      _nameController.text = profile.name;
      _moneyController.text = profile.money.toString();
      _raceController.text = profile.trainerRace;

      setState(() {
        _profile = profile;
        _starterCandidates = starterCandidates;
        _trainerOrigins = trainerOrigins;
        _trainerPaths = trainerPaths;
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
        _originAbilityBonusSource = profile.originAbilityBonusSource;
        _skillProficiencies = [...profile.skillProficiencies];
        _savingThrowProficiencies = [...profile.savingThrowProficiencies];
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
      final isFirstStage = evolution == null || evolution.currentStage <= 1;

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

    final previousRace = _raceController.text.trim();
    final nextBonusSource = _originAbilityBonuses(race).isNotEmpty ? race : '';

    if (previousRace == race &&
        _originAbilityBonusSource == nextBonusSource) {
      return;
    }

    _raceController.text = race;
    setState(() {
      _abilityScores = _abilityScoresWithOriginBonusChange(
        previousRace: _originAbilityBonusSource,
        nextRace: nextBonusSource,
      );
      _originAbilityBonusSource = nextBonusSource;
    });
  }

  Map<String, int> _abilityScoresWithOriginBonusChange({
    required String previousRace,
    required String nextRace,
  }) {
    final previousBonuses = _originAbilityBonuses(previousRace);
    final nextBonuses = _originAbilityBonuses(nextRace);

    return {
      for (final entry in UserProfile.defaultAbilityScores.entries)
        entry.key: ((_abilityScores[entry.key] ?? entry.value) -
                (previousBonuses[entry.key] ?? 0) +
                (nextBonuses[entry.key] ?? 0))
            .clamp(1, 30)
            .toInt(),
    };
  }

  TrainerOrigin? _originByName(String name) {
    for (final origin in _trainerOrigins) {
      if (origin.name == name) {
        return origin;
      }
    }

    return null;
  }

  Map<String, int> _originAbilityBonuses(String name) {
    return _originByName(name)?.abilityBonuses ?? const <String, int>{};
  }

  Map<String, String> get _originDescriptions {
    return {
      for (final origin in _trainerOrigins) origin.name: origin.description,
    };
  }

  Map<String, String> get _trainerPathDescriptions {
    return {
      for (final path in _trainerPaths)
        path.name: path.featureForLevel(2)?.description ?? '',
    };
  }

  void _changeStarter(Pokemon pokemon) {
    setState(() => _starterPokemon = pokemon.name);
  }

  void _toggleSkillProficiency(String skill) {
    setState(() {
      if (_skillProficiencies.contains(skill)) {
        _skillProficiencies.remove(skill);
      } else {
        _skillProficiencies = [..._skillProficiencies, skill];
      }
    });
  }

  void _toggleSavingThrowProficiency(String ability) {
    if (TrainerManualOptions.fixedSavingThrowProficiencies.contains(ability)) {
      return;
    }

    setState(() {
      if (_savingThrowProficiencies.contains(ability)) {
        _savingThrowProficiencies.remove(ability);
      } else {
        _savingThrowProficiencies = [..._savingThrowProficiencies, ability];
      }
    });
  }

  void _changeSpecializationSlot(int slotIndex, String specialization) {
    final next = [..._specializations];
    while (next.length <= slotIndex) {
      next.add('');
    }

    next[slotIndex] = specialization;
    while (next.isNotEmpty && next.last.isEmpty) {
      next.removeLast();
    }

    setState(() => _specializations = next);
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
        originAbilityBonusSource: _originAbilityBonusSource,
        starterPokemon: _starterPokemon.trim(),
        startingPack: _startingPack,
        skillProficiencies: [..._skillProficiencies],
        savingThrowProficiencies: [..._savingThrowProficiencies],
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

  Future<void> _openRacePicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => _StringPickerSheet(
        title: 'Origine',
        options: [for (final origin in _trainerOrigins) origin.name],
        selected: _raceController.text.trim(),
        descriptions: _originDescriptions,
      ),
    );

    _changeRace(selected);
  }

  Future<void> _openStartingPackPicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => _StringPickerSheet(
        title: 'Pack iniziale',
        options: TrainerManualOptions.startingPacks,
        selected: _startingPack,
      ),
    );

    _changeStartingPack(selected);
  }

  Future<void> _openTrainerPathPicker() async {
    if (_trainerLevel < 2) return;

    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => _StringPickerSheet(
        title: 'Trainer Path',
        options: [for (final path in _trainerPaths) path.name],
        selected: _trainerPath,
        descriptions: _trainerPathDescriptions,
      ),
    );

    _changeTrainerPath(selected);
  }

  Future<void> _openSpecializationPicker(int slotIndex) async {
    final current = slotIndex < _specializations.length
        ? _specializations[slotIndex]
        : '';
    final options = TrainerManualOptions.specializations.where((option) {
      return option == current || !_specializations.contains(option);
    }).toList();
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _StringPickerSheet(
        title: 'Specializzazione',
        options: options,
        selected: current,
        descriptions: TrainerManualOptions.specializationNotes,
      ),
    );

    if (selected != null) {
      _changeSpecializationSlot(slotIndex, selected);
    }
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
              _InteractiveTrainerSheet(
                nameController: _nameController,
                moneyController: _moneyController,
                race: _raceController.text.trim(),
                raceDescription:
                    _originByName(_raceController.text.trim())?.description ??
                        '',
                selectedStarter: _selectedStarter,
                startingPack: _startingPack,
                trainerLevel: _trainerLevel,
                trainerPath: _trainerPath,
                trainerPaths: _trainerPaths,
                abilityScores: _abilityScores,
                armorClass: _armorClass,
                maxHp: _maxHp,
                currentHp: _currentHp,
                speed: _speed,
                skillProficiencies: _skillProficiencies,
                savingThrowProficiencies: _savingThrowProficiencies,
                specializations: _specializations,
                canAddStarterToTeam: _selectedStarter != null &&
                    !_starterAlreadyInTeam &&
                    _hasEmptyTeamSlot,
                starterAlreadyInTeam: _starterAlreadyInTeam,
                isSaving: _isSaving,
                errorMessage: _errorMessage,
                onDecreaseLevel: () => _changeLevel(-1),
                onIncreaseLevel: () => _changeLevel(1),
                onRaceTap: _openRacePicker,
                onStarterTap: _openStarterPicker,
                onAddStarterToTeam: _addStarterToTeam,
                onStartingPackTap: _openStartingPackPicker,
                onTrainerPathTap: _openTrainerPathPicker,
                onSkillToggle: _toggleSkillProficiency,
                onSavingThrowToggle: _toggleSavingThrowProficiency,
                onSpecializationTap: _openSpecializationPicker,
                onAbilityScoreChanged: _changeAbilityScore,
                onArmorClassChanged: _changeArmorClass,
                onMaxHpChanged: _changeMaxHp,
                onCurrentHpChanged: _changeCurrentHp,
                onSpeedChanged: _changeSpeed,
                onSave: _saveProfile,
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

class _InteractiveTrainerSheet extends StatelessWidget {
  const _InteractiveTrainerSheet({
    required this.nameController,
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
    required this.skillProficiencies,
    required this.savingThrowProficiencies,
    required this.specializations,
    required this.canAddStarterToTeam,
    required this.starterAlreadyInTeam,
    required this.isSaving,
    required this.errorMessage,
    required this.onDecreaseLevel,
    required this.onIncreaseLevel,
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
    required this.onSave,
  });

  final TextEditingController nameController;
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
  final List<String> skillProficiencies;
  final List<String> savingThrowProficiencies;
  final List<String> specializations;
  final bool canAddStarterToTeam;
  final bool starterAlreadyInTeam;
  final bool isSaving;
  final String? errorMessage;
  final VoidCallback onDecreaseLevel;
  final VoidCallback onIncreaseLevel;
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
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final pokeslots = TrainerProgression.pokeslotsForLevel(trainerLevel);
    final maxSr = TrainerProgression.maxControlledSrForLevel(trainerLevel);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 980;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: _TrainerSheetMainColumn(
                      nameController: nameController,
                      moneyController: moneyController,
                      race: race,
                      raceDescription: raceDescription,
                      selectedStarter: selectedStarter,
                      startingPack: startingPack,
                      trainerLevel: trainerLevel,
                      abilityScores: abilityScores,
                      armorClass: armorClass,
                      maxHp: maxHp,
                      currentHp: currentHp,
                      speed: speed,
                      pokeslots: pokeslots,
                      maxSr: maxSr,
                      skillProficiencies: skillProficiencies,
                      savingThrowProficiencies: savingThrowProficiencies,
                      canAddStarterToTeam: canAddStarterToTeam,
                      starterAlreadyInTeam: starterAlreadyInTeam,
                      errorMessage: errorMessage,
                      isSaving: isSaving,
                      onDecreaseLevel: onDecreaseLevel,
                      onIncreaseLevel: onIncreaseLevel,
                      onRaceTap: onRaceTap,
                      onStarterTap: onStarterTap,
                      onAddStarterToTeam: onAddStarterToTeam,
                      onStartingPackTap: onStartingPackTap,
                      onSkillToggle: onSkillToggle,
                      onSavingThrowToggle: onSavingThrowToggle,
                      onAbilityScoreChanged: onAbilityScoreChanged,
                      onArmorClassChanged: onArmorClassChanged,
                      onMaxHpChanged: onMaxHpChanged,
                      onCurrentHpChanged: onCurrentHpChanged,
                      onSpeedChanged: onSpeedChanged,
                      onSave: onSave,
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 300,
                    child: _TrainerProgressionColumn(
                      trainerLevel: trainerLevel,
                      trainerPath: trainerPath,
                      trainerPaths: trainerPaths,
                      specializations: specializations,
                      onTrainerPathTap: onTrainerPathTap,
                      onSpecializationTap: onSpecializationTap,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TrainerSheetMainColumn(
                    nameController: nameController,
                    moneyController: moneyController,
                    race: race,
                    raceDescription: raceDescription,
                    selectedStarter: selectedStarter,
                    startingPack: startingPack,
                    trainerLevel: trainerLevel,
                    abilityScores: abilityScores,
                    armorClass: armorClass,
                    maxHp: maxHp,
                    currentHp: currentHp,
                    speed: speed,
                    pokeslots: pokeslots,
                    maxSr: maxSr,
                    skillProficiencies: skillProficiencies,
                    savingThrowProficiencies: savingThrowProficiencies,
                    canAddStarterToTeam: canAddStarterToTeam,
                    starterAlreadyInTeam: starterAlreadyInTeam,
                    errorMessage: errorMessage,
                    isSaving: isSaving,
                    onDecreaseLevel: onDecreaseLevel,
                    onIncreaseLevel: onIncreaseLevel,
                    onRaceTap: onRaceTap,
                    onStarterTap: onStarterTap,
                    onAddStarterToTeam: onAddStarterToTeam,
                    onStartingPackTap: onStartingPackTap,
                    onSkillToggle: onSkillToggle,
                    onSavingThrowToggle: onSavingThrowToggle,
                    onAbilityScoreChanged: onAbilityScoreChanged,
                    onArmorClassChanged: onArmorClassChanged,
                    onMaxHpChanged: onMaxHpChanged,
                    onCurrentHpChanged: onCurrentHpChanged,
                    onSpeedChanged: onSpeedChanged,
                    onSave: onSave,
                  ),
                  const SizedBox(height: 16),
                  _TrainerProgressionColumn(
                    trainerLevel: trainerLevel,
                    trainerPath: trainerPath,
                    trainerPaths: trainerPaths,
                    specializations: specializations,
                    onTrainerPathTap: onTrainerPathTap,
                    onSpecializationTap: onSpecializationTap,
                  ),
                ],
              ),
      ),
    );
  }
}

class _TrainerSheetMainColumn extends StatelessWidget {
  const _TrainerSheetMainColumn({
    required this.nameController,
    required this.moneyController,
    required this.race,
    required this.raceDescription,
    required this.selectedStarter,
    required this.startingPack,
    required this.trainerLevel,
    required this.abilityScores,
    required this.armorClass,
    required this.maxHp,
    required this.currentHp,
    required this.speed,
    required this.pokeslots,
    required this.maxSr,
    required this.skillProficiencies,
    required this.savingThrowProficiencies,
    required this.canAddStarterToTeam,
    required this.starterAlreadyInTeam,
    required this.errorMessage,
    required this.isSaving,
    required this.onDecreaseLevel,
    required this.onIncreaseLevel,
    required this.onRaceTap,
    required this.onStarterTap,
    required this.onAddStarterToTeam,
    required this.onStartingPackTap,
    required this.onSkillToggle,
    required this.onSavingThrowToggle,
    required this.onAbilityScoreChanged,
    required this.onArmorClassChanged,
    required this.onMaxHpChanged,
    required this.onCurrentHpChanged,
    required this.onSpeedChanged,
    required this.onSave,
  });

  final TextEditingController nameController;
  final TextEditingController moneyController;
  final String race;
  final String raceDescription;
  final Pokemon? selectedStarter;
  final String startingPack;
  final int trainerLevel;
  final Map<String, int> abilityScores;
  final int armorClass;
  final int maxHp;
  final int currentHp;
  final int speed;
  final int pokeslots;
  final int maxSr;
  final List<String> skillProficiencies;
  final List<String> savingThrowProficiencies;
  final bool canAddStarterToTeam;
  final bool starterAlreadyInTeam;
  final String? errorMessage;
  final bool isSaving;
  final VoidCallback onDecreaseLevel;
  final VoidCallback onIncreaseLevel;
  final VoidCallback onRaceTap;
  final VoidCallback onStarterTap;
  final VoidCallback onAddStarterToTeam;
  final VoidCallback onStartingPackTap;
  final ValueChanged<String> onSkillToggle;
  final ValueChanged<String> onSavingThrowToggle;
  final void Function(String ability, int delta) onAbilityScoreChanged;
  final ValueChanged<int> onArmorClassChanged;
  final ValueChanged<int> onMaxHpChanged;
  final ValueChanged<int> onCurrentHpChanged;
  final ValueChanged<int> onSpeedChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final selectedSkills = [
      ...TrainerManualOptions.fixedSkillProficiencies,
      ...skillProficiencies,
    ];
    final nextPokeslotLevel = TrainerProgression.nextPokeslotLevel(
      trainerLevel,
    );
    final nextControlLevel = TrainerProgression.nextControlUpgradeLevel(
      trainerLevel,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SheetSectionTitle(
          title: 'TRAINER',
          trailing: 'LEVEL $trainerLevel',
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SheetTextBox(
              label: 'Nome',
              controller: nameController,
              width: 260,
            ),
            _SheetCounterBox(
              label: 'Livello',
              value: trainerLevel.toString(),
              subtitle: 'Pokéslot $pokeslots | SR max $maxSr',
              onDecrease: trainerLevel <= TrainerProgression.minLevel
                  ? null
                  : onDecreaseLevel,
              onIncrease: trainerLevel >= TrainerProgression.maxLevel
                  ? null
                  : onIncreaseLevel,
            ),
            _SheetTextBox(
              label: 'Pokédollars',
              controller: moneyController,
              width: 150,
              prefixText: '₽ ',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            _SheetInfoBox(
              label: 'Prof',
              value: _signed(_trainerProficiencyBonus(trainerLevel)),
              width: 92,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _SheetChoiceBox(
          label: 'Origine',
          value: race.isEmpty ? 'Scegli' : race,
          detail: race.isEmpty
              ? 'Tocca per scegliere dal manuale'
              : raceDescription,
          detailMaxLines: null,
          onTap: onRaceTap,
        ),
        const SizedBox(height: 16),
        _SheetSectionTitle(title: 'CARATTERISTICHE'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in UserProfile.defaultAbilityScores.entries)
              _AbilityScoreTile(
                label: entry.key,
                score: abilityScores[entry.key] ?? entry.value,
                onDecrease: () => onAbilityScoreChanged(entry.key, -1),
                onIncrease: () => onAbilityScoreChanged(entry.key, 1),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _AbilityChecksPanel(
          abilityScores: abilityScores,
          trainerLevel: trainerLevel,
          skillProficiencies: skillProficiencies,
          onToggle: onSkillToggle,
        ),
        const SizedBox(height: 16),
        _SavingThrowsPanel(
          abilityScores: abilityScores,
          trainerLevel: trainerLevel,
          savingThrowProficiencies: savingThrowProficiencies,
          onToggle: onSavingThrowToggle,
        ),
        const SizedBox(height: 16),
        _StarterSheetBox(
          pokemon: selectedStarter,
          alreadyInTeam: starterAlreadyInTeam,
          canAddToTeam: canAddStarterToTeam,
          onPick: onStarterTap,
          onAddToTeam: onAddStarterToTeam,
        ),
        const SizedBox(height: 16),
        _SheetSectionTitle(title: 'COMBATTIMENTO'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SheetCounterBox(
              label: 'CA',
              value: armorClass.toString(),
              onDecrease: () => onArmorClassChanged(-1),
              onIncrease: () => onArmorClassChanged(1),
            ),
            _SheetCounterBox(
              label: 'PF attuali',
              value: currentHp.toString(),
              subtitle: 'Max $maxHp',
              onDecrease: () => onCurrentHpChanged(-1),
              onIncrease: () => onCurrentHpChanged(1),
            ),
            _SheetCounterBox(
              label: 'PF max',
              value: maxHp.toString(),
              onDecrease: () => onMaxHpChanged(-1),
              onIncrease: () => onMaxHpChanged(1),
            ),
            _SheetCounterBox(
              label: 'Velocita',
              value: '$speed ft',
              onDecrease: () => onSpeedChanged(-5),
              onIncrease: () => onSpeedChanged(5),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 720;
            final packAndUpgrades = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SheetChoiceBox(
                  label: 'Pack iniziale',
                  value: startingPack.isEmpty ? 'Scegli' : startingPack,
                  detail: 'Equipaggiamento rapido. Lo zaino lo separiamo dopo.',
                  onTap: onStartingPackTap,
                ),
                const SizedBox(height: 8),
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
            );

            if (!twoColumns) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  packAndUpgrades,
                  const SizedBox(height: 8),
                  _SelectedProficienciesBox(
                    abilityScores: abilityScores,
                    trainerLevel: trainerLevel,
                    selectedSkills: selectedSkills,
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: packAndUpgrades),
                const SizedBox(width: 8),
                Expanded(
                  child: _SelectedProficienciesBox(
                    abilityScores: abilityScores,
                    trainerLevel: trainerLevel,
                    selectedSkills: selectedSkills,
                  ),
                ),
              ],
            );
          },
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
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
    );
  }
}

int _abilityCheckTotal({
  required Map<String, int> abilityScores,
  required int trainerLevel,
  required String ability,
  required bool isProficient,
}) {
  final score =
      abilityScores[ability] ?? UserProfile.defaultAbilityScores[ability] ?? 10;
  final proficiency = isProficient ? _trainerProficiencyBonus(trainerLevel) : 0;

  return _abilityModifier(score) + proficiency;
}

class _AbilityChecksPanel extends StatelessWidget {
  const _AbilityChecksPanel({
    required this.abilityScores,
    required this.trainerLevel,
    required this.skillProficiencies,
    required this.onToggle,
  });

  final Map<String, int> abilityScores;
  final int trainerLevel;
  final List<String> skillProficiencies;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final selected = {
      ...TrainerManualOptions.fixedSkillProficiencies,
      ...skillProficiencies,
    };

    return _SheetPanel(
      title: 'ABILITIES',
      child: Wrap(
        spacing: 10,
        runSpacing: 4,
        children: [
          for (final skill in TrainerManualOptions.skills)
            _CheckValueRow(
              title: '${skill.name} (${skill.ability})',
              value: _signed(
                _abilityCheckTotal(
                  abilityScores: abilityScores,
                  trainerLevel: trainerLevel,
                  ability: skill.ability,
                  isProficient: selected.contains(skill.name),
                ),
              ),
              isSelected: selected.contains(skill.name),
              isLocked: TrainerManualOptions.fixedSkillProficiencies.contains(
                skill.name,
              ),
              width: 220,
              onChanged: () => onToggle(skill.name),
            ),
        ],
      ),
    );
  }
}

class _SavingThrowsPanel extends StatelessWidget {
  const _SavingThrowsPanel({
    required this.abilityScores,
    required this.trainerLevel,
    required this.savingThrowProficiencies,
    required this.onToggle,
  });

  final Map<String, int> abilityScores;
  final int trainerLevel;
  final List<String> savingThrowProficiencies;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final selected = {
      ...TrainerManualOptions.fixedSavingThrowProficiencies,
      ...savingThrowProficiencies,
    };

    return _SheetPanel(
      title: 'SAVING THROWS',
      child: Wrap(
        spacing: 10,
        runSpacing: 4,
        children: [
          for (final ability in TrainerManualOptions.savingThrows)
            _CheckValueRow(
              title: ability,
              value: _signed(
                _abilityCheckTotal(
                  abilityScores: abilityScores,
                  trainerLevel: trainerLevel,
                  ability: ability,
                  isProficient: selected.contains(ability),
                ),
              ),
              isSelected: selected.contains(ability),
              isLocked: TrainerManualOptions.fixedSavingThrowProficiencies
                  .contains(ability),
              width: 150,
              onChanged: () => onToggle(ability),
            ),
        ],
      ),
    );
  }
}

class _SelectedProficienciesBox extends StatelessWidget {
  const _SelectedProficienciesBox({
    required this.abilityScores,
    required this.trainerLevel,
    required this.selectedSkills,
  });

  final Map<String, int> abilityScores;
  final int trainerLevel;
  final List<String> selectedSkills;

  @override
  Widget build(BuildContext context) {
    final selected = [
      for (final skill in TrainerManualOptions.skills)
        if (selectedSkills.contains(skill.name)) skill,
    ];

    return _SheetBoxFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Competenze selezionate',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          if (selected.isEmpty)
            const Text('Spunta le competenze nella sezione Abilities.')
          else
            for (final skill in selected) ...[
              _SelectedSkillDescription(
                skill: skill,
                total: _abilityCheckTotal(
                  abilityScores: abilityScores,
                  trainerLevel: trainerLevel,
                  ability: skill.ability,
                  isProficient: true,
                ),
              ),
              if (skill != selected.last) const Divider(height: 14),
            ],
        ],
      ),
    );
  }
}

class _SelectedSkillDescription extends StatelessWidget {
  const _SelectedSkillDescription({required this.skill, required this.total});

  final TrainerSkillDefinition skill;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${skill.name} (${skill.ability})',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              _signed(total),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SheetPanel extends StatelessWidget {
  const _SheetPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _CheckValueRow extends StatelessWidget {
  const _CheckValueRow({
    required this.title,
    required this.value,
    required this.isSelected,
    required this.isLocked,
    required this.width,
    required this.onChanged,
  });

  final String title;
  final String value;
  final bool isSelected;
  final bool isLocked;
  final double width;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: isLocked ? null : onChanged,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: isLocked ? null : (_) => onChanged(),
                visualDensity: VisualDensity.compact,
              ),
              SizedBox(
                width: 34,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer
                        .withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      value,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
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

class _TrainerProgressionColumn extends StatelessWidget {
  const _TrainerProgressionColumn({
    required this.trainerLevel,
    required this.trainerPath,
    required this.trainerPaths,
    required this.specializations,
    required this.onTrainerPathTap,
    required this.onSpecializationTap,
  });

  final int trainerLevel;
  final String trainerPath;
  final List<TrainerPath> trainerPaths;
  final List<String> specializations;
  final VoidCallback onTrainerPathTap;
  final void Function(int slotIndex) onSpecializationTap;

  @override
  Widget build(BuildContext context) {
    final slots = <Widget>[
      _ProgressionChoiceBox(
        title: 'Specialization',
        level: 1,
        value: _specializationAt(0).isEmpty
            ? 'Scegli specializzazione'
            : _specializationAt(0),
        detail: _specializationDetail(0),
        onTap: () => onSpecializationTap(0),
      ),
    ];

    if (trainerLevel >= 2) {
      slots.add(
        _ProgressionChoiceBox(
          title: 'Trainer Path',
          level: 2,
          value: trainerPath.isEmpty ? 'Scegli trainer path' : trainerPath,
          detail: trainerPath.isEmpty
              ? 'Tocca per scegliere dal pool dei path.'
              : _trainerPathFeatureFor(2)?.description ?? '',
          onTap: onTrainerPathTap,
        ),
      );
    }

    for (final level in [5, 9, 15]) {
      if (trainerLevel >= level) {
        final feature = _trainerPathFeatureFor(level);
        slots.add(
          _ProgressionChoiceBox(
            title: 'Trainer Path',
            level: level,
            value: feature?.title ??
                (trainerPath.isEmpty
                    ? 'Path non scelto'
                    : 'Feature non trovata'),
            detail: feature?.description ??
                'Scegli il path al livello 2 per vedere la feature automatica.',
          ),
        );
      }
    }

    if (trainerLevel >= 7) {
      slots.add(
        _ProgressionChoiceBox(
          title: 'Specialization',
          level: 7,
          value: _specializationAt(1).isEmpty
              ? 'Scegli specializzazione'
              : _specializationAt(1),
          detail: _specializationDetail(1),
          onTap: () => onSpecializationTap(1),
        ),
      );
    }

    if (trainerLevel >= 18) {
      slots.add(
        _ProgressionChoiceBox(
          title: 'Specialization',
          level: 18,
          value: _specializationAt(2).isEmpty
              ? 'Scegli specializzazione'
              : _specializationAt(2),
          detail: _specializationDetail(2),
          onTap: () => onSpecializationTap(2),
        ),
      );
    }

    slots.sort((a, b) {
      final first = a is _ProgressionChoiceBox ? a.level : 0;
      final second = b is _ProgressionChoiceBox ? b.level : 0;
      return first.compareTo(second);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SheetSectionTitle(
          title: 'AVANZAMENTO',
          trailing: 'LEVEL $trainerLevel',
        ),
        const SizedBox(height: 8),
        for (final slot in slots) ...[
          slot,
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  String _specializationAt(int index) {
    return index < specializations.length ? specializations[index] : '';
  }

  String _specializationDetail(int index) {
    final specialization = _specializationAt(index);
    if (specialization.isEmpty) {
      return 'Tocca il box e scegli dal pool disponibile.';
    }

    return TrainerManualOptions.specializationNotes[specialization] ?? '';
  }

  TrainerPathFeature? _trainerPathFeatureFor(int level) {
    for (final path in trainerPaths) {
      if (path.name == trainerPath) {
        return path.featureForLevel(level);
      }
    }

    return null;
  }
}

class _SheetSectionTitle extends StatelessWidget {
  const _SheetSectionTitle({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SheetTextBox extends StatelessWidget {
  const _SheetTextBox({
    required this.label,
    required this.controller,
    this.width = 220,
    this.prefixText,
    this.keyboardType,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController controller;
  final double width;
  final String? prefixText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return _SheetBoxFrame(
      width: width,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefixText,
          isDense: true,
          border: InputBorder.none,
        ),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SheetInfoBox extends StatelessWidget {
  const _SheetInfoBox({
    required this.label,
    required this.value,
    this.detail,
    this.width = 132,
  });

  final String label;
  final String value;
  final String? detail;
  final double width;

  @override
  Widget build(BuildContext context) {
    return _SheetBoxFrame(
      width: width,
      child: _SheetBoxText(label: label, value: value, detail: detail),
    );
  }
}

class _SheetChoiceBox extends StatelessWidget {
  const _SheetChoiceBox({
    required this.label,
    required this.value,
    required this.onTap,
    this.detail,
    this.detailMaxLines = 4,
    this.width,
  });

  final String label;
  final String value;
  final String? detail;
  final int? detailMaxLines;
  final VoidCallback onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return _SheetBoxFrame(
      width: width,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SheetBoxText(
                  label: label,
                  value: value,
                  detail: detail,
                  detailMaxLines: detailMaxLines,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Icon(Icons.expand_more, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetCounterBox extends StatelessWidget {
  const _SheetCounterBox({
    required this.label,
    required this.value,
    this.subtitle,
    this.onDecrease,
    this.onIncrease,
  });

  final String label;
  final String value;
  final String? subtitle;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    return _SheetBoxFrame(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Diminuisci $label',
                onPressed: onDecrease,
                icon: const Icon(Icons.remove, size: 18),
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Aumenta $label',
                onPressed: onIncrease,
                icon: const Icon(Icons.add, size: 18),
              ),
            ],
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

class _SheetBoxFrame extends StatelessWidget {
  const _SheetBoxFrame({
    required this.child,
    this.width,
  });

  final Widget child;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: child,
        ),
      ),
    );
  }
}

class _SheetBoxText extends StatelessWidget {
  const _SheetBoxText({
    required this.label,
    required this.value,
    this.detail,
    this.detailMaxLines = 4,
  });

  final String label;
  final String value;
  final String? detail;
  final int? detailMaxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 3),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        if (detail != null && detail!.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            detail!,
            maxLines: detailMaxLines,
            overflow: detailMaxLines == null
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _StarterSheetBox extends StatelessWidget {
  const _StarterSheetBox({
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
    final selectedPokemon = pokemon;

    return _SheetBoxFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: onPick,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 18),
                  child: Icon(Icons.catching_pokemon),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SheetBoxText(
                    label: 'Starter Pokémon',
                    value: selectedPokemon == null
                        ? 'Scegli starter'
                        : selectedPokemon.name,
                    detail: selectedPokemon == null
                        ? 'Solo primo stadio con SR 1/2 o inferiore.'
                        : '${selectedPokemon.types.join(' / ')} | SR ${selectedPokemon.sr} | HP ${selectedPokemon.hitPoints} | CA ${selectedPokemon.armorClass}',
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(Icons.expand_more, size: 18),
                ),
              ],
            ),
          ),
          if (selectedPokemon != null) ...[
            const SizedBox(height: 8),
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
    );
  }
}

class _ProgressionChoiceBox extends StatelessWidget {
  const _ProgressionChoiceBox({
    required this.title,
    required this.level,
    required this.value,
    required this.detail,
    this.onTap,
  });

  final String title;
  final int level;
  final String value;
  final String detail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            offset: Offset(3, 3),
          ),
        ],
        color: Theme.of(context).colorScheme.surface,
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    'LEVEL $level',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer
                      .withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AbilityScoreTile extends StatelessWidget {
  const _AbilityScoreTile({
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
        width: 96,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              Text(
                '$score',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text('Mod. ${_signed(_abilityModifier(score))}'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Diminuisci $label',
                    onPressed: onDecrease,
                    icon: const Icon(Icons.remove, size: 18),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Aumenta $label',
                    onPressed: onIncrease,
                    icon: const Icon(Icons.add, size: 18),
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

class _StringPickerSheet extends StatelessWidget {
  const _StringPickerSheet({
    required this.title,
    required this.options,
    required this.selected,
    this.descriptions = const {},
  });

  final String title;
  final List<String> options;
  final String selected;
  final Map<String, String> descriptions;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.78,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                itemCount: options.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final option = options[index];
                  final description = descriptions[option] ?? '';

                  return _PickerOptionTile(
                    title: option,
                    subtitle: description,
                    isSelected: option == selected,
                    onTap: () => Navigator.of(context).pop(option),
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

class _PickerOptionTile extends StatelessWidget {
  const _PickerOptionTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    this.isEnabled = true,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        enabled: isEnabled,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
        trailing: Icon(
          isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
        ),
        onTap: isEnabled ? onTap : null,
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
