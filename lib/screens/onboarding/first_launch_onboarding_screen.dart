import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/pokemon.dart';
import '../../models/pokemon_type_localization.dart';
import '../../models/team_slot.dart';
import '../../models/trainer_manual_content.dart';
import '../../models/trainer_manual_options.dart';
import '../../models/user_profile.dart';
import '../../repositories/evolution_repository.dart';
import '../../repositories/pokedex_repositry.dart';
import '../../repositories/pokemon_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/team_repository.dart';
import '../../repositories/trainer_manual_repository.dart';
import '../../services/app_launch_service.dart';
import '../../widgets/pokemon/pokemon_asset_image.dart';

class FirstLaunchOnboardingScreen extends StatefulWidget {
  const FirstLaunchOnboardingScreen({super.key, required this.onCompleted});

  final VoidCallback onCompleted;

  @override
  State<FirstLaunchOnboardingScreen> createState() =>
      _FirstLaunchOnboardingScreenState();
}

class _FirstLaunchOnboardingScreenState
    extends State<FirstLaunchOnboardingScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final PokemonRepository _pokemonRepository = PokemonRepository();
  final EvolutionRepository _evolutionRepository = EvolutionRepository();
  final TeamRepository _teamRepository = TeamRepository();
  final PokedexRepository _pokedexRepository = PokedexRepository();
  final TrainerManualRepository _trainerManualRepository =
      TrainerManualRepository();
  final AppLaunchService _appLaunchService = AppLaunchService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  int _step = 0;
  int _age = 16;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String _background = _backgroundOptions.first.name;
  TrainerOrigin? _origin;
  Pokemon? _starter;
  List<TrainerOrigin> _origins = const [];
  List<Pokemon> _starterCandidates = const [];
  String _starterQuery = '';

  static const int _totalSteps = 10;

  static const List<_BackgroundOption> _backgroundOptions = [
    _BackgroundOption(
      name: 'Ricercatore',
      description:
          'Osservi, cataloghi e studi ogni scoperta prima di trarre conclusioni.',
      icon: Icons.science_outlined,
    ),
    _BackgroundOption(
      name: 'Esploratore',
      description:
          'Ti senti a casa sulle strade meno battute e negli ambienti selvaggi.',
      icon: Icons.explore_outlined,
    ),
    _BackgroundOption(
      name: 'Allevatore',
      description:
          'Conosci le necessità delle creature e costruisci legami pazienti.',
      icon: Icons.pets_outlined,
    ),
    _BackgroundOption(
      name: 'Combattente',
      description:
          'Affronti le difficoltà con disciplina, coraggio e spirito competitivo.',
      icon: Icons.sports_martial_arts_outlined,
    ),
    _BackgroundOption(
      name: 'Artista',
      description:
          'Esprimi te stesso attraverso spettacolo, creatività e sensibilità.',
      icon: Icons.palette_outlined,
    ),
    _BackgroundOption(
      name: 'Studioso',
      description:
          'Hai dedicato anni a libri, tradizioni e conoscenze specialistiche.',
      icon: Icons.menu_book_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onStarterSearchChanged);
    _loadOptions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController
      ..removeListener(_onStarterSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onStarterSearchChanged() {
    if (!mounted) return;
    setState(() => _starterQuery = _searchController.text.trim());
  }

  Future<void> _loadOptions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _trainerManualRepository.getOrigins(),
        _pokemonRepository.getAllPokemon(),
        _evolutionRepository.getEvolutionData(),
      ]);
      final origins = results[0] as List<TrainerOrigin>;
      final pokemon = results[1] as List<Pokemon>;
      final evolutionData = results[2] as Map<String, dynamic>;
      final candidates = pokemon.where((entry) {
        final evolution = evolutionData[entry.name];
        final currentStage = evolution?.currentStage as int?;
        final isFirstStage = currentStage == null || currentStage <= 1;
        return entry.sr <= 0.5 && isFirstStage;
      }).toList()
        ..sort((a, b) => a.id.compareTo(b.id));

      if (!mounted) return;
      setState(() {
        _origins = origins;
        _origin = origins.isEmpty ? null : origins.first;
        _starterCandidates = candidates;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  List<Pokemon> get _filteredStarters {
    final query = _starterQuery.toLowerCase();
    if (query.isEmpty) return _starterCandidates;

    return _starterCandidates.where((pokemon) {
      final nameMatches = pokemon.name.toLowerCase().contains(query);
      final typeMatches = pokemon.types.any((type) {
        final italian = PokemonTypeLocalization.italianLabel(type).toLowerCase();
        final english = PokemonTypeLocalization.englishValue(type).toLowerCase();
        return italian.contains(query) || english.contains(query);
      });
      return nameMatches || typeMatches;
    }).toList(growable: false);
  }

  _BackgroundOption get _selectedBackground => _backgroundOptions.firstWhere(
        (option) => option.name == _background,
        orElse: () => _backgroundOptions.first,
      );

  bool get _canContinue {
    switch (_step) {
      case 2:
        return _nameController.text.trim().isNotEmpty;
      case 4:
        return _origin != null;
      case 5:
        return _background.trim().isNotEmpty;
      case 6:
        return _starter != null;
      case 8:
        return !_isSaving && _errorMessage != null;
      default:
        return true;
    }
  }

  String get _buttonLabel {
    switch (_step) {
      case 0:
        return 'INIZIA LA TUA AVVENTURA';
      case 7:
        return 'CONFERMA';
      case 8:
        return _errorMessage == null ? 'CREAZIONE IN CORSO...' : 'RIPROVA';
      case 9:
        return 'INIZIA!';
      default:
        return 'AVANTI';
    }
  }

  Future<void> _next() async {
    if (!_canContinue || _isSaving) return;

    if (_step < 7) {
      setState(() {
        _step += 1;
        _errorMessage = null;
      });
      return;
    }

    if (_step == 7 || _step == 8) {
      setState(() {
        _step = 8;
        _errorMessage = null;
      });
      await _completeOnboarding();
      return;
    }

    if (_step == 9) {
      widget.onCompleted();
    }
  }

  void _back() {
    if (_step <= 0 || _step >= 8 || _isSaving) return;
    setState(() {
      _step -= 1;
      _errorMessage = null;
    });
  }

  Map<String, int> _abilityScoresWithOrigin(TrainerOrigin? origin) {
    final scores = {...UserProfile.defaultAbilityScores};
    if (origin == null) return scores;
    for (final entry in origin.abilityBonuses.entries) {
      scores[entry.key] = (scores[entry.key] ?? 10) + entry.value;
    }
    return scores;
  }

  String _originBonuses(TrainerOrigin origin) {
    if (origin.abilityBonuses.isEmpty) return 'Nessun bonus automatico';
    return origin.abilityBonuses.entries
        .map((entry) => '${entry.key.toUpperCase()} +${entry.value}')
        .join(', ');
  }

  Future<void> _completeOnboarding() async {
    final starter = _starter;
    final origin = _origin;
    if (starter == null || origin == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final now = DateTime.now();
      final profile = UserProfile(
        id: now.microsecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        createdAt: now,
        updatedAt: now,
        trainerAge: _age,
        trainerLevel: 1,
        money: 1000,
        abilityScores: _abilityScoresWithOrigin(origin),
        armorClass: 10,
        maxHp: 8,
        currentHp: 8,
        speed: 30,
        trainerRace: origin.name,
        originAbilityBonusSource: origin.name,
        background: _background,
        starterPokemon: starter.name,
        startingPack: TrainerManualOptions.startingPacks.first,
        skillProficiencies: <String>{
          ...TrainerManualOptions.fixedSkillProficiencies,
          ...origin.skillProficiencies,
        }.toList(),
        savingThrowProficiencies: <String>{
          ...TrainerManualOptions.fixedSavingThrowProficiencies,
          ...origin.savingThrowProficiencies,
        }.toList(),
      );

      await _profileRepository.saveProfile(profile);
      await _profileRepository.setActiveProfile(profile.id);
      await _teamRepository.updateSlot(
        profileId: profile.id,
        updatedSlot: TeamSlot(
          slotIndex: 0,
          pokemonId: starter.id,
          currentHp: starter.hitPoints,
          selectedMoves: starter.moves.startingMoves.take(4).toList(),
          abilities: starter.abilities.take(2).toList(),
          loyalty: 1,
        ),
      );
      await _pokedexRepository.updateMarkMode(
        profileId: profile.id,
        pokemonId: starter.id,
        speciesName: starter.name,
        seen: true,
        caught: true,
      );
      await _appLaunchService.markOnboardingCompleted();

      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _step = 9;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _OnboardingPalette.page,
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    if (_errorMessage != null && _origins.isEmpty) {
      return Scaffold(
        backgroundColor: _OnboardingPalette.page,
        body: SafeArea(
          child: _OnboardingError(
            message: _errorMessage!,
            onRetry: _loadOptions,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _OnboardingPalette.page,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              child: Column(
                children: [
                  _ProgressHeader(
                    step: _step,
                    totalSteps: _totalSteps,
                    canGoBack: _step > 0 && _step < 8,
                    onBack: _back,
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: _buildStage(),
                    ),
                  ),
                  if (_errorMessage != null && _step >= 8) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Non è stato possibile creare il profilo. Riprova.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (_step != 8 || !_isSaving)
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed: _canContinue && !_isSaving ? _next : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: _OnboardingPalette.orange,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              _OnboardingPalette.orange.withValues(alpha: .35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .2,
                          ),
                        ),
                        child: Text(_buttonLabel),
                      ),
                    )
                  else
                    const SizedBox(height: 54),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStage() {
    if (_step == 0) {
      return const _WelcomeStage(key: ValueKey('welcome'));
    }

    final dialogue = _buildDialogue();
    final compactCardFactor = switch (_step) {
      6 => .46,
      7 => .42,
      8 || 9 => .54,
      _ => .55,
    };

    return _ProfessorScene(
      key: ValueKey('scene-$_step'),
      compactCardTopFactor: compactCardFactor,
      child: dialogue,
    );
  }

  Widget _buildDialogue() {
    switch (_step) {
      case 1:
        return const _DialogueCard(
          speaker: 'Professore',
          title: 'Benvenuto nel tuo nuovo viaggio.',
          body:
              'Qui potrai creare il tuo Allenatore, scegliere il primo compagno e prepararti alle avventure da tavolo.',
          content: _InfoBanner(
            icon: Icons.auto_stories_outlined,
            text: 'Le tue scelte potranno essere modificate in seguito dal profilo.',
          ),
        );
      case 2:
        return _DialogueCard(
          speaker: 'Professore',
          title: 'Prima di iniziare, dimmi…',
          body: 'Come ti chiami?',
          content: TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nome Allenatore',
              hintText: 'Inserisci il tuo nome',
              prefixIcon: Icon(Icons.person_outline),
            ),
            onChanged: (_) => setState(() {}),
          ),
        );
      case 3:
        return _DialogueCard(
          speaker: 'Professore',
          title: 'Bene! E quanti anni hai?',
          body: 'Puoi sempre modificare questa informazione in seguito.',
          content: _AgeSelector(
            age: _age,
            onDecrease: _age > 6 ? () => setState(() => _age--) : null,
            onIncrease: _age < 99 ? () => setState(() => _age++) : null,
          ),
        );
      case 4:
        final origin = _origin;
        return _DialogueCard(
          speaker: 'Professore',
          title: 'Ogni Allenatore porta con sé una storia.',
          body: 'Da dove provieni?',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<TrainerOrigin>(
                initialValue: origin,
                isExpanded: true,
                items: [
                  for (final item in _origins)
                    DropdownMenuItem(value: item, child: Text(item.name)),
                ],
                onChanged: (value) => setState(() => _origin = value),
                decoration: const InputDecoration(
                  labelText: 'Origine',
                  prefixIcon: Icon(Icons.public),
                ),
              ),
              if (origin != null) ...[
                const SizedBox(height: 16),
                _DetailLine(
                  label: 'Bonus caratteristiche',
                  value: _originBonuses(origin),
                ),
                _DetailLine(
                  label: 'Competenze',
                  value: origin.skillProficiencies.isEmpty
                      ? 'Nessuna competenza aggiuntiva'
                      : origin.skillProficiencies.join(', '),
                ),
                const SizedBox(height: 8),
                Text(
                  origin.description,
                  style: const TextStyle(height: 1.35),
                ),
              ],
            ],
          ),
        );
      case 5:
        final selected = _selectedBackground;
        return _DialogueCard(
          speaker: 'Professore',
          title: 'Quale strada ti ha portato fin qui?',
          body: 'Scegli il background che descrive meglio il tuo Allenatore.',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _background,
                isExpanded: true,
                items: [
                  for (final option in _backgroundOptions)
                    DropdownMenuItem(
                      value: option.name,
                      child: Row(
                        children: [
                          Icon(option.icon, size: 20),
                          const SizedBox(width: 10),
                          Text(option.name),
                        ],
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _background = value);
                },
                decoration: const InputDecoration(labelText: 'Background'),
              ),
              const SizedBox(height: 16),
              _InfoBanner(icon: selected.icon, text: selected.description),
            ],
          ),
        );
      case 6:
        return _DialogueCard(
          speaker: 'Professore',
          title: 'Infine, scegli il tuo primo compagno.',
          body:
              'Puoi scegliere qualunque Pokémon non evoluto con SR 1/2 o inferiore.',
          content: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Cerca per nome o tipo in italiano',
                  hintText: 'Esempio: Bulbasaur, Erba, Fuoco…',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              _StarterGrid(
                pokemon: _filteredStarters,
                selectedId: _starter?.id,
                onSelected: (pokemon) => setState(() => _starter = pokemon),
              ),
            ],
          ),
        );
      case 7:
        return _DialogueCard(
          speaker: 'Professore',
          title: 'Ecco il tuo profilo.',
          body: 'Controlla le scelte e preparati a iniziare.',
          content: Column(
            children: [
              _SummaryRow(
                icon: Icons.person_outline,
                label: 'Nome',
                value: _nameController.text.trim(),
              ),
              _SummaryRow(
                icon: Icons.cake_outlined,
                label: 'Età',
                value: '$_age',
              ),
              _SummaryRow(
                icon: Icons.public,
                label: 'Origine',
                value: _origin?.name ?? '—',
              ),
              _SummaryRow(
                icon: Icons.menu_book_outlined,
                label: 'Background',
                value: _background,
              ),
              _SummaryRow(
                icon: Icons.catching_pokemon,
                label: 'Starter',
                value: _starter?.name ?? '—',
              ),
            ],
          ),
        );
      case 8:
        return _DialogueCard(
          speaker: 'Professore',
          title: 'Sto creando il tuo profilo.',
          body: _errorMessage == null
              ? 'Un momento… sto preparando il tuo Allenatore e il primo Pokémon.'
              : 'Qualcosa non ha funzionato. Puoi riprovare senza perdere le tue scelte.',
          content: _SavingView(hasError: _errorMessage != null),
        );
      default:
        return const _DialogueCard(
          speaker: 'Professore',
          title: 'Tutto pronto!',
          body:
              'La tua avventura sta per iniziare. Ci vediamo nel mondo dei Pokémon!',
          content: _InfoBanner(
            icon: Icons.celebration_outlined,
            text: 'Il profilo e il tuo starter sono stati creati correttamente.',
          ),
        );
    }
  }
}

class _OnboardingPalette {
  const _OnboardingPalette._();

  static const page = Color(0xFFF7F3ED);
  static const card = Color(0xFFFFFCF9);
  static const peach = Color(0xFFFFE4D8);
  static const peachSoft = Color(0xFFFFF2EC);
  static const rust = Color(0xFF974A28);
  static const orange = Color(0xFFFF6B17);
  static const text = Color(0xFF241C19);
  static const border = Color(0xFFD8C7BF);
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.step,
    required this.totalSteps,
    required this.canGoBack,
    required this.onBack,
  });

  final int step;
  final int totalSteps;
  final bool canGoBack;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final value = math.min(1.0, (step + 1) / totalSteps);
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: canGoBack
              ? IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back, size: 28),
                  color: _OnboardingPalette.text,
                  tooltip: 'Indietro',
                )
              : null,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 9,
              backgroundColor: const Color(0xFFFFD8CD),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(_OnboardingPalette.rust),
            ),
          ),
        ),
        const SizedBox(width: 50),
      ],
    );
  }
}

class _OnboardingAssets {
  const _OnboardingAssets._();

  static const welcomeBackground =
      'assets/textures/trainers/onboarding_welcome_background.webp';
  static const laboratoryBackground =
      'assets/textures/trainers/onboarding_lab_background.webp';
  static const professor =
      'assets/textures/trainers/onboarding_professor.png';
}

class _WelcomeStage extends StatelessWidget {
  const _WelcomeStage({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _OnboardingAssetImage(
            path: _OnboardingAssets.welcomeBackground,
            fit: BoxFit.cover,
            fallback: _WelcomeBackgroundPlaceholder(),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x08FFFFFF),
                  Color(0x24FFFFFF),
                  Color(0x66FFF8ED),
                ],
                stops: [0, .48, 1],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .82),
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.catching_pokemon,
                    size: 72,
                    color: _OnboardingPalette.rust,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'TRAINER ATLAS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _OnboardingPalette.text,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(color: Color(0x44FFFFFF), blurRadius: 12),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Il tuo compagno per le avventure da tavolo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _OnboardingPalette.rust,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingAssetImage extends StatelessWidget {
  const _OnboardingAssetImage({
    required this.path,
    required this.fallback,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  });

  final String path;
  final Widget fallback;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      fit: fit,
      alignment: alignment,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}

class _WelcomeBackgroundPlaceholder extends StatelessWidget {
  const _WelcomeBackgroundPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEAF7FB), Color(0xFFFFF4DE)],
        ),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(top: 18),
          child: _MissingAssetLabel(
            title: 'SFONDO COPERTINA',
            fileName: 'onboarding_welcome_background.webp',
          ),
        ),
      ),
    );
  }
}

class _ProfessorScene extends StatelessWidget {
  const _ProfessorScene({
    super.key,
    required this.child,
    required this.compactCardTopFactor,
  });

  final Widget child;
  final double compactCardTopFactor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final proposedCardTop = constraints.maxHeight * compactCardTopFactor;
        final maximumCardTop = math.max(160.0, constraints.maxHeight - 140);
        final cardTop = math.min(
          maximumCardTop,
          math.max(190.0, proposedCardTop),
        );
        final horizontalInset = constraints.maxWidth < 760 ? 14.0 : 34.0;

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const _OnboardingAssetImage(
                    path: _OnboardingAssets.laboratoryBackground,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    fallback: _LaboratoryBackgroundPlaceholder(),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x08FFFFFF),
                          Color(0x00FFFFFF),
                          Color(0x33FFF2EA),
                        ],
                        stops: [0, .55, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: constraints.maxWidth < 760 ? 28 : 88,
                    right: constraints.maxWidth < 760 ? 28 : 88,
                    top: 8,
                    height: cardTop + 78,
                    child: const _ProfessorPortrait(),
                  ),
                  Positioned(
                    left: horizontalInset,
                    right: horizontalInset,
                    top: cardTop,
                    bottom: 14,
                    child: child,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfessorPortrait extends StatelessWidget {
  const _ProfessorPortrait();

  @override
  Widget build(BuildContext context) {
    return const _OnboardingAssetImage(
      path: _OnboardingAssets.professor,
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
      fallback: _ProfessorAssetPlaceholder(),
    );
  }
}

class _LaboratoryBackgroundPlaceholder extends StatelessWidget {
  const _LaboratoryBackgroundPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF4EFEA), Color(0xFFFFF7F1)],
        ),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(top: 18),
          child: _MissingAssetLabel(
            title: 'SFONDO LABORATORIO',
            fileName: 'onboarding_lab_background.webp',
          ),
        ),
      ),
    );
  }
}

class _ProfessorAssetPlaceholder extends StatelessWidget {
  const _ProfessorAssetPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: 260,
        height: 330,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .64),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(120),
            bottom: Radius.circular(28),
          ),
          border: Border.all(color: const Color(0xFFBCA99F), width: 2),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add_alt_1_outlined,
              size: 72,
              color: _OnboardingPalette.rust,
            ),
            SizedBox(height: 12),
            Text(
              'PROFESSORE PNG\nTRASPARENTE',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _OnboardingPalette.rust,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'onboarding_professor.png',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingAssetLabel extends StatelessWidget {
  const _MissingAssetLabel({
    required this.title,
    required this.fileName,
  });

  final String title;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .90),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _OnboardingPalette.border),
      ),
      child: Text(
        '$title  ·  $fileName',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _OnboardingPalette.rust,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DialogueCard extends StatelessWidget {
  const _DialogueCard({
    required this.speaker,
    required this.title,
    required this.body,
    this.content,
  });

  final String speaker;
  final String title;
  final String body;
  final Widget? content;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _OnboardingPalette.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _OnboardingPalette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            spreadRadius: -8,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Scrollbar(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                speaker,
                style: const TextStyle(
                  color: _OnboardingPalette.rust,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: _OnboardingPalette.text,
                  fontSize: 27,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                body,
                style: const TextStyle(
                  color: _OnboardingPalette.text,
                  fontSize: 16,
                  height: 1.35,
                ),
              ),
              if (content != null) ...[
                const SizedBox(height: 18),
                content!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AgeSelector extends StatelessWidget {
  const _AgeSelector({
    required this.age,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int age;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        border: Border.all(color: _OnboardingPalette.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          IconButton(onPressed: onDecrease, icon: const Icon(Icons.remove)),
          Expanded(
            child: Text(
              '$age',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ),
          IconButton(onPressed: onIncrease, icon: const Icon(Icons.add)),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _OnboardingPalette.peachSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _OnboardingPalette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _OnboardingPalette.rust),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(height: 1.35, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            TextSpan(text: value),
          ],
        ),
        style: const TextStyle(height: 1.3),
      ),
    );
  }
}

class _StarterGrid extends StatelessWidget {
  const _StarterGrid({
    required this.pokemon,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Pokemon> pokemon;
  final int? selectedId;
  final ValueChanged<Pokemon> onSelected;

  @override
  Widget build(BuildContext context) {
    if (pokemon.isEmpty) {
      return const _InfoBanner(
        icon: Icons.search_off,
        text: 'Nessun Pokémon corrisponde alla ricerca.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 680 ? 4 : 2;
        return SizedBox(
          height: 330,
          child: GridView.builder(
            primary: false,
            padding: EdgeInsets.zero,
            itemCount: pokemon.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              childAspectRatio: .78,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final entry = pokemon[index];
              final selected = selectedId == entry.id;
              return InkWell(
                onTap: () => onSelected(entry),
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: selected
                        ? _OnboardingPalette.peach
                        : _OnboardingPalette.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected
                          ? _OnboardingPalette.orange
                          : _OnboardingPalette.border,
                      width: selected ? 2.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: PokemonAssetImage(
                          pokemon: entry,
                          useLargeArtwork: true,
                          size: 112,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.types
                            .map(PokemonTypeLocalization.italianLabel)
                            .join(' / '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _OnboardingPalette.peachSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: _OnboardingPalette.rust, size: 21),
          const SizedBox(width: 10),
          SizedBox(
            width: 92,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavingView extends StatelessWidget {
  const _SavingView({required this.hasError});

  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: hasError
            ? const Icon(
                Icons.error_outline,
                size: 72,
                color: Colors.redAccent,
              )
            : const SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  strokeWidth: 7,
                  color: _OnboardingPalette.orange,
                ),
              ),
      ),
    );
  }
}

class _BackgroundOption {
  const _BackgroundOption({
    required this.name,
    required this.description,
    required this.icon,
  });

  final String name;
  final String description;
  final IconData icon;
}

class _OnboardingError extends StatelessWidget {
  const _OnboardingError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('RIPROVA')),
          ],
        ),
      ),
    );
  }
}
