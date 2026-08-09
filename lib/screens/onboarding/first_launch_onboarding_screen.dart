import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../localization/ui_text.dart';
import '../../localization/user_facing_error.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_type_localization.dart';
import '../../models/team_slot.dart';
import '../../models/trainer_manual_content.dart';
import '../../models/trainer_manual_options.dart';
import '../../models/trainer_starting_equipment.dart';
import '../../models/trainer_origin_name_localization.dart';
import '../../models/trainer_ui_localization.dart';
import '../../models/user_profile.dart';
import '../../repositories/evolution_repository.dart';
import '../../repositories/pokemon_repository.dart';
import '../../repositories/trainer_manual_repository.dart';
import '../../services/profile_creation_service.dart';
import '../../widgets/pokemon/pokemon_asset_image.dart';
import '../../widgets/profile/trainer_profile_image_picker.dart';

class FirstLaunchOnboardingScreen extends StatefulWidget {
  const FirstLaunchOnboardingScreen({
    super.key,
    required this.onCompleted,
    this.onCancel,
    this.markOnboardingCompleted = true,
  });

  final VoidCallback onCompleted;
  final VoidCallback? onCancel;
  final bool markOnboardingCompleted;

  @override
  State<FirstLaunchOnboardingScreen> createState() =>
      _FirstLaunchOnboardingScreenState();
}

class _FirstLaunchOnboardingScreenState
    extends State<FirstLaunchOnboardingScreen> {
  final PokemonRepository _pokemonRepository = PokemonRepository();
  final EvolutionRepository _evolutionRepository = EvolutionRepository();
  final TrainerManualRepository _trainerManualRepository =
      TrainerManualRepository();
  final ProfileCreationService _profileCreationService =
      ProfileCreationService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _backgroundController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  int _step = 0;
  int _age = 16;
  bool _ageInputIsValid = true;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String _startingPack = TrainerManualOptions.startingPacks.first;
  String _profileImageBase64 = '';
  TrainerOrigin? _origin;
  Pokemon? _starter;
  List<TrainerOrigin> _origins = const [];
  List<Pokemon> _starterCandidates = const [];
  String _starterQuery = '';

  static const int _totalSteps = 12;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onStarterSearchChanged);
    _loadOptions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _backgroundController.dispose();
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
      }).toList()..sort((a, b) => a.id.compareTo(b.id));

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
        _errorMessage = context.userFacingError(
          error,
          action: UserFacingErrorAction.load,
        );
        _isLoading = false;
      });
    }
  }

  List<Pokemon> get _filteredStarters {
    final query = _starterQuery.toLowerCase();
    if (query.isEmpty) return _starterCandidates;

    return _starterCandidates
        .where((pokemon) {
          final nameMatches = pokemon.name.toLowerCase().contains(query);
          final typeMatches = pokemon.types.any((type) {
            final italian = PokemonTypeLocalization.italianLabel(
              type,
            ).toLowerCase();
            final english = PokemonTypeLocalization.englishValue(
              type,
            ).toLowerCase();
            return italian.contains(query) || english.contains(query);
          });
          return nameMatches || typeMatches;
        })
        .toList(growable: false);
  }

  String _originDisplayName(TrainerOrigin origin, AppLocalizations l10n) {
    return trainerOriginDisplayName(
      origin.name,
      isItalian: Localizations.localeOf(context).languageCode == 'it',
      dmApprovedLabel: l10n.onboardingOriginDmApprovedName,
    );
  }

  String _originDescription(TrainerOrigin origin, AppLocalizations l10n) {
    final description = switch (origin.name) {
      'Alolan' => l10n.onboardingOriginAlolanDescription,
      'Hoennian' => l10n.onboardingOriginHoennianDescription,
      'Johtoan' => l10n.onboardingOriginJohtoanDescription,
      'Kalosian' => l10n.onboardingOriginKalosianDescription,
      'Kantoan' => l10n.onboardingOriginKantoanDescription,
      'Sinnoan' => l10n.onboardingOriginSinnoanDescription,
      'Unovan' => l10n.onboardingOriginUnovanDescription,
      'Galarian' => l10n.onboardingOriginGalarianDescription,
      'Origine 5e approvata dal DM' =>
        l10n.onboardingOriginDmApprovedDescription,
      _ => origin.description,
    };
    return TrainerUiLocalization.visibleText(description);
  }

  bool get _canContinue {
    switch (_step) {
      case 2:
        return _nameController.text.trim().isNotEmpty;
      case 4:
        return _ageInputIsValid;
      case 5:
        return _origin != null;
      case 7:
        return _startingPack.trim().isNotEmpty;
      case 8:
        return _starter != null;
      case 10:
        return !_isSaving && _errorMessage != null;
      default:
        return true;
    }
  }

  bool get _canCancelFlow {
    return widget.onCancel != null &&
        !_isSaving &&
        (_step < 10 || (_step == 10 && _errorMessage != null));
  }

  bool get _canPopRoute {
    return widget.onCancel == null ? !_isSaving : _canCancelFlow;
  }

  String get _buttonLabel {
    final l10n = AppLocalizations.of(context);
    switch (_step) {
      case 0:
        return l10n.onboardingStartAdventure;
      case 3:
        return _profileImageBase64.isEmpty
            ? context.uiText('Salta', 'Skip')
            : l10n.nextAction;
      case 9:
        return l10n.onboardingConfirm;
      case 10:
        return _errorMessage == null
            ? l10n.onboardingCreatingProfile
            : l10n.retryAction.toUpperCase();
      case 11:
        return l10n.onboardingBegin;
      default:
        return l10n.nextAction;
    }
  }

  Future<void> _next() async {
    if (!_canContinue || _isSaving) return;

    if (_step < 9) {
      setState(() {
        _step += 1;
        _errorMessage = null;
      });
      return;
    }

    if (_step == 9 || _step == 10) {
      setState(() {
        _step = 10;
        _errorMessage = null;
      });
      await _completeOnboarding();
      return;
    }

    if (_step == 11) {
      widget.onCompleted();
    }
  }

  void _back() {
    if (_step <= 0 || _step >= 10 || _isSaving) return;
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
    if (origin.abilityBonuses.isEmpty) {
      return AppLocalizations.of(context).onboardingNoAutomaticBonuses;
    }
    return origin.abilityBonuses.entries
        .map(
          (entry) =>
              '${TrainerUiLocalization.abilityAbbreviation(entry.key)} +${entry.value}',
        )
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
        profileImageBase64: _profileImageBase64,
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
        background: _backgroundController.text.trim(),
        starterPokemon: starter.name,
        startingPack: _startingPack,
        skillProficiencies: <String>{
          ...TrainerManualOptions.fixedSkillProficiencies,
          ...origin.skillProficiencies,
        }.toList(),
        savingThrowProficiencies: <String>{
          ...TrainerManualOptions.fixedSavingThrowProficiencies,
          ...origin.savingThrowProficiencies,
        }.toList(),
      );

      await _profileCreationService.createGuidedProfile(
        profile: profile,
        starterSlot: TeamSlot(
          slotIndex: 0,
          pokemonId: starter.id,
          currentHp: starter.hitPoints,
          selectedMoves: starter.moves.startingMoves.take(4).toList(),
          abilities: starter.abilities.take(2).toList(),
          loyalty: 1,
        ),
        starterPokemonId: starter.id,
        starterSpeciesName: starter.name,
        initialInventory: TrainerStartingEquipment.inventoryForPack(
          _startingPack,
        ),
        markOnboardingCompleted: widget.markOnboardingCompleted,
      );

      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _step = 11;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = context.userFacingError(
          error,
          action: UserFacingErrorAction.save,
        );
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    if (_isLoading) {
      return Scaffold(
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

    return PopScope(
      canPop: _canPopRoute,
      child: Scaffold(
        backgroundColor: _OnboardingPalette.page,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  keyboardVisible ? 8 : 12,
                  16,
                  keyboardVisible ? 8 : 18,
                ),
                child: Column(
                  children: [
                    _ProgressHeader(
                      step: _step,
                      totalSteps: _totalSteps,
                      canGoBack: _step > 0 && _step < 10,
                      onBack: _back,
                      onCancel: _canCancelFlow ? widget.onCancel : null,
                    ),
                    SizedBox(height: keyboardVisible ? 6 : 14),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: _buildStage(keyboardVisible: keyboardVisible),
                      ),
                    ),
                    if (_errorMessage != null && _step >= 10) ...[
                      const SizedBox(height: 10),
                      Text(
                        l10n.onboardingProfileCreationError,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    SizedBox(height: keyboardVisible ? 8 : 14),
                    if (_step != 10 || !_isSaving)
                      SizedBox(
                        width: double.infinity,
                        height: keyboardVisible ? 48 : 54,
                        child: FilledButton(
                          onPressed: _canContinue && !_isSaving ? _next : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: _OnboardingPalette.orange,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: _OnboardingPalette.orange
                                .withValues(alpha: .35),
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
                      SizedBox(height: keyboardVisible ? 48 : 54),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStage({required bool keyboardVisible}) {
    if (_step == 0) {
      return const _WelcomeStage(key: ValueKey('welcome'));
    }

    final dialogue = _buildDialogue();
    final compactCardFactor = switch (_step) {
      8 => .30,
      9 => .36,
      10 || 11 => .50,
      _ => .48,
    };

    return _ProfessorScene(
      key: ValueKey('scene-$_step'),
      compactCardTopFactor: compactCardFactor,
      keyboardVisible: keyboardVisible,
      child: dialogue,
    );
  }

  Widget _buildDialogue() {
    final l10n = AppLocalizations.of(context);
    switch (_step) {
      case 1:
        return _DialogueCard(
          speaker: l10n.onboardingProfessor,
          title: l10n.onboardingWelcomeTitle,
          body: l10n.onboardingWelcomeBody,
          content: _InfoBanner(
            icon: Icons.auto_stories_outlined,
            text: l10n.onboardingWelcomeNote,
          ),
        );
      case 2:
        return _DialogueCard(
          speaker: l10n.onboardingProfessor,
          title: l10n.onboardingNameTitle,
          body: l10n.onboardingNameBody,
          content: TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.onboardingTrainerNameLabel,
              hintText: l10n.onboardingTrainerNameHint,
              prefixIcon: const Icon(Icons.person_outline),
            ),
            onChanged: (_) => setState(() {}),
          ),
        );
      case 3:
        return _DialogueCard(
          speaker: l10n.onboardingProfessor,
          title: context.uiText('Scegli la tua immagine', 'Choose your image'),
          body: context.uiText(
            'Puoi aggiungere un’immagine dell’Allenatore oppure saltare questo passaggio.',
            'You can add a Trainer image or skip this step.',
          ),
          content: TrainerProfileImagePicker(
            imageBase64: _profileImageBase64,
            trainerName: _nameController.text,
            onChanged: (value) => setState(() => _profileImageBase64 = value),
          ),
        );
      case 4:
        return _DialogueCard(
          speaker: l10n.onboardingProfessor,
          title: l10n.onboardingAgeTitle,
          body: l10n.onboardingAgeBody,
          content: _AgeSelector(
            age: _age,
            isValid: _ageInputIsValid,
            onChanged: (value) {
              final parsed = int.tryParse(value.trim());
              setState(() {
                _ageInputIsValid =
                    parsed != null && parsed >= 6 && parsed <= 99;
                if (_ageInputIsValid) _age = parsed!;
              });
            },
          ),
        );
      case 5:
        final origin = _origin;
        return _DialogueCard(
          speaker: l10n.onboardingProfessor,
          title: l10n.onboardingOriginTitle,
          body: l10n.onboardingOriginBody,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<TrainerOrigin>(
                initialValue: origin,
                isExpanded: true,
                items: [
                  for (final item in _origins)
                    DropdownMenuItem(
                      value: item,
                      child: Text(_originDisplayName(item, l10n)),
                    ),
                ],
                onChanged: (value) => setState(() => _origin = value),
                decoration: InputDecoration(
                  labelText: l10n.onboardingOriginLabel,
                  prefixIcon: const Icon(Icons.public),
                ),
              ),
              if (origin != null) ...[
                const SizedBox(height: 16),
                _DetailLine(
                  label: l10n.onboardingOriginBonusLabel,
                  value: _originBonuses(origin),
                ),
                _DetailLine(
                  label: l10n.onboardingProficienciesLabel,
                  value: origin.skillProficiencies.isEmpty
                      ? l10n.onboardingNoAdditionalProficiencies
                      : origin.skillProficiencies.join(', '),
                ),
                const SizedBox(height: 8),
                Text(
                  _originDescription(origin, l10n),
                  style: const TextStyle(height: 1.35),
                ),
              ],
            ],
          ),
        );
      case 6:
        return _DialogueCard(
          speaker: l10n.onboardingProfessor,
          title: context.uiText('Racconta chi sei', 'Tell us who you are'),
          body: context.uiText(
            'Scrivi liberamente il background narrativo del tuo Allenatore. Non assegna bonus automatici e potrai modificarlo dalla scheda.',
            'Write your Trainer’s narrative background freely. It grants no automatic bonuses and can be edited from the sheet.',
          ),
          content: TextField(
            controller: _backgroundController,
            minLines: 4,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [LengthLimitingTextInputFormatter(4000)],
            decoration: InputDecoration(
              labelText: context.uiText(
                'Background narrativo',
                'Narrative background',
              ),
              hintText: context.uiText(
                'Da dove vieni? Perché hai iniziato il viaggio? Chi o cosa hai lasciato alle spalle?',
                'Where are you from? Why did you begin your journey? Who or what did you leave behind?',
              ),
              alignLabelWithHint: true,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 86),
                child: Icon(Icons.auto_stories_outlined),
              ),
            ),
          ),
        );
      case 7:
        return _DialogueCard(
          speaker: l10n.onboardingProfessor,
          title: context.uiText(
            'Scegli la dotazione iniziale',
            'Choose your starting pack',
          ),
          body: context.uiText(
            'La dotazione scelta verrà aperta e ogni oggetto sarà inserito concretamente nello Zaino.',
            'The selected pack will be unpacked and every item will be placed in the Bag.',
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _startingPack,
                isExpanded: true,
                items: [
                  for (final pack in TrainerManualOptions.startingPacks)
                    DropdownMenuItem(
                      value: pack,
                      child: Text(TrainerUiLocalization.startingPackName(pack)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _startingPack = value);
                },
                decoration: InputDecoration(
                  labelText: context.uiText('Dotazione', 'Starting pack'),
                  prefixIcon: const Icon(Icons.backpack_outlined),
                ),
              ),
              const SizedBox(height: 16),
              _InfoBanner(
                icon: Icons.inventory_2_outlined,
                text: TrainerUiLocalization.startingPackDescription(
                  _startingPack,
                ),
              ),
            ],
          ),
        );
      case 8:
        return _DialogueCard(
          speaker: l10n.onboardingProfessor,
          title: l10n.onboardingStarterTitle,
          body: l10n.onboardingStarterBody,
          compact: true,
          scrollable: false,
          expandContent: true,
          content: Column(
            children: [
              TextField(
                key: const ValueKey('onboarding-starter-search'),
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: l10n.onboardingStarterSearchLabel,
                  hintText: l10n.onboardingStarterSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _StarterGrid(
                  pokemon: _filteredStarters,
                  selectedId: _starter?.id,
                  onSelected: (pokemon) => setState(() => _starter = pokemon),
                ),
              ),
            ],
          ),
        );
      case 9:
        return _DialogueCard(
          speaker: l10n.onboardingProfessor,
          title: l10n.onboardingSummaryTitle,
          body: l10n.onboardingSummaryBody,
          content: Column(
            children: [
              TrainerProfileAvatar(
                imageBase64: _profileImageBase64,
                trainerName: _nameController.text,
                radius: 40,
              ),
              const SizedBox(height: 12),
              _SummaryRow(
                icon: Icons.person_outline,
                label: l10n.onboardingNameLabel,
                value: _nameController.text.trim(),
              ),
              _SummaryRow(
                icon: Icons.cake_outlined,
                label: l10n.onboardingAgeLabel,
                value: '$_age',
              ),
              _SummaryRow(
                icon: Icons.public,
                label: l10n.onboardingOriginLabel,
                value: _origin == null
                    ? '—'
                    : _originDisplayName(_origin!, l10n),
              ),
              _SummaryRow(
                icon: Icons.auto_stories_outlined,
                label: context.uiText(
                  'Background narrativo',
                  'Narrative background',
                ),
                value: _backgroundController.text.trim().isEmpty
                    ? context.uiText('Non compilato', 'Not provided')
                    : _backgroundController.text.trim(),
              ),
              _SummaryRow(
                icon: Icons.backpack_outlined,
                label: context.uiText('Dotazione', 'Starting pack'),
                value: TrainerUiLocalization.startingPackName(_startingPack),
              ),
              _SummaryRow(
                icon: Icons.catching_pokemon,
                label: l10n.onboardingStarterLabel,
                value: _starter?.name ?? '—',
              ),
            ],
          ),
        );
      case 10:
        return _DialogueCard(
          speaker: l10n.onboardingProfessor,
          title: l10n.onboardingSavingTitle,
          body: _errorMessage == null
              ? l10n.onboardingSavingBody
              : l10n.onboardingSavingErrorBody,
          content: _SavingView(hasError: _errorMessage != null),
        );
      default:
        return _DialogueCard(
          speaker: l10n.onboardingProfessor,
          title: l10n.onboardingDoneTitle,
          body: l10n.onboardingDoneBody,
          content: _InfoBanner(
            icon: Icons.celebration_outlined,
            text: l10n.onboardingDoneNote,
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
    this.onCancel,
  });

  final int step;
  final int totalSteps;
  final bool canGoBack;
  final VoidCallback onBack;
  final VoidCallback? onCancel;

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
                  tooltip: AppLocalizations.of(context).backAction,
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
              valueColor: const AlwaysStoppedAnimation<Color>(
                _OnboardingPalette.rust,
              ),
            ),
          ),
        ),
        SizedBox(
          width: 50,
          child: onCancel == null
              ? null
              : IconButton(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close, size: 28),
                  color: _OnboardingPalette.text,
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                ),
        ),
      ],
    );
  }
}

class _OnboardingAssets {
  const _OnboardingAssets._();

  static const welcomeBackground =
      'assets/textures/trainers/onboarding_welcome_background.webp';
  static const trainerAtlasLogo =
      'assets/textures/trainers/trainer_atlas_logo.png';
  static const laboratoryBackground =
      'assets/textures/trainers/onboarding_lab_background.webp';
  static const professor = 'assets/textures/trainers/onboarding_professor.png';
}

class _WelcomeStage extends StatelessWidget {
  const _WelcomeStage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
          DecoratedBox(
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
                Flexible(
                  child: Semantics(
                    image: true,
                    label: 'Trainer Atlas 5e',
                    child: Image.asset(
                      _OnboardingAssets.trainerAtlasLogo,
                      width: 360,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.onboardingTagline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEAF7FB), Color(0xFFFFF4DE)],
        ),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 18),
          child: _MissingAssetLabel(
            title: AppLocalizations.of(
              context,
            ).onboardingMissingCoverBackground,
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
    required this.keyboardVisible,
  });

  final Widget child;
  final double compactCardTopFactor;
  final bool keyboardVisible;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final keyboardCompact = compact && keyboardVisible;
        final proposedCardTop =
            constraints.maxHeight *
            (keyboardCompact ? .22 : compactCardTopFactor);
        final minimumCardTop = compact
            ? (keyboardCompact ? 72.0 : 170.0)
            : 210.0;
        final maximumCardTop = math.max(
          minimumCardTop,
          constraints.maxHeight - (keyboardCompact ? 220 : 140),
        );
        final cardTop = math.min(
          maximumCardTop,
          math.max(minimumCardTop, proposedCardTop),
        );
        final horizontalInset = compact ? 8.0 : 28.0;
        final professorInset = compact ? 4.0 : 72.0;
        final double professorOverlap;
        if (keyboardCompact) {
          professorOverlap = math.min(120.0, math.max(80.0, cardTop * .35));
        } else if (compact) {
          professorOverlap = math.min(220.0, math.max(132.0, cardTop * .48));
        } else {
          professorOverlap = math.min(260.0, math.max(170.0, cardTop * .42));
        }

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
                  DecoratedBox(
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
                    left: professorInset,
                    right: professorInset,
                    top: compact ? 0 : 8,
                    height: cardTop + professorOverlap,
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
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      fallback: _ProfessorAssetPlaceholder(),
    );
  }
}

class _LaboratoryBackgroundPlaceholder extends StatelessWidget {
  const _LaboratoryBackgroundPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF4EFEA), Color(0xFFFFF7F1)],
        ),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 18),
          child: _MissingAssetLabel(
            title: AppLocalizations.of(context).onboardingMissingLabBackground,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_add_alt_1_outlined,
              size: 72,
              color: _OnboardingPalette.rust,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).onboardingMissingProfessor,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _OnboardingPalette.rust,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
            const SizedBox(height: 8),
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
  const _MissingAssetLabel({required this.title, required this.fileName});

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
    this.compact = false,
    this.scrollable = true,
    this.expandContent = false,
  });

  final String speaker;
  final String title;
  final String body;
  final Widget? content;
  final bool compact;
  final bool scrollable;
  final bool expandContent;

  @override
  Widget build(BuildContext context) {
    final padding = compact ? 16.0 : 22.0;
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          speaker,
          style: TextStyle(
            color: _OnboardingPalette.rust,
            fontSize: compact ? 13 : 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: compact ? 5 : 8),
        Text(
          title,
          key: const ValueKey('onboarding-dialogue-title'),
          maxLines: compact ? 2 : null,
          overflow: compact ? TextOverflow.ellipsis : null,
          style: TextStyle(
            color: _OnboardingPalette.text,
            fontSize: compact ? 22 : 27,
            height: 1.08,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: compact ? 6 : 10),
        Text(
          body,
          maxLines: compact ? 2 : null,
          overflow: compact ? TextOverflow.ellipsis : null,
          style: TextStyle(
            color: _OnboardingPalette.text,
            fontSize: compact ? 14 : 16,
            height: compact ? 1.25 : 1.35,
          ),
        ),
        if (content != null) ...[
          SizedBox(height: compact ? 10 : 18),
          if (expandContent) Expanded(child: content!) else content!,
        ],
      ],
    );

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
      child: scrollable
          ? Scrollbar(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: column,
              ),
            )
          : Padding(padding: EdgeInsets.all(padding), child: column),
    );
  }
}

class _AgeSelector extends StatelessWidget {
  const _AgeSelector({
    required this.age,
    required this.isValid,
    required this.onChanged,
  });
  final int age;
  final bool isValid;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: '$age',
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(2),
      ],
      decoration: InputDecoration(
        labelText: context.uiText('Età dell’Allenatore', 'Trainer age'),
        helperText: context.uiText(
          'Scrivi un valore da 6 a 99.',
          'Enter a value from 6 to 99.',
        ),
        errorText: isValid
            ? null
            : context.uiText(
                'Inserisci un’età valida da 6 a 99.',
                'Enter a valid age from 6 to 99.',
              ),
        prefixIcon: const Icon(Icons.cake_outlined),
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
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
    final l10n = AppLocalizations.of(context);
    final isItalian = Localizations.localeOf(context).languageCode == 'it';
    if (pokemon.isEmpty) {
      return _InfoBanner(
        icon: Icons.search_off,
        text: l10n.onboardingNoStarterResults,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 680 ? 4 : 2;
        return GridView.builder(
          key: const ValueKey('onboarding-starter-grid'),
          primary: false,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.zero,
          itemCount: pokemon.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: 1,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            final entry = pokemon[index];
            final selected = selectedId == entry.id;
            return InkWell(
              onTap: () => onSelected(entry),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: selected
                      ? _OnboardingPalette.peach
                      : _OnboardingPalette.card,
                  borderRadius: BorderRadius.circular(14),
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
                        size: 82,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      entry.types
                          .map(
                            isItalian
                                ? PokemonTypeLocalization.italianLabel
                                : PokemonTypeLocalization.englishValue,
                          )
                          .join(' / '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            );
          },
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
            ? const Icon(Icons.error_outline, size: 72, color: Colors.redAccent)
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
            FilledButton(
              onPressed: onRetry,
              child: Text(
                AppLocalizations.of(context).retryAction.toUpperCase(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
