import 'package:flutter/material.dart';

import '../../models/pokemon.dart';
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
  String _background = _backgrounds.first;
  TrainerOrigin? _origin;
  Pokemon? _starter;
  List<TrainerOrigin> _origins = const [];
  List<Pokemon> _starterCandidates = const [];
  String _starterQuery = '';

  static const _backgrounds = <String>[
    'Ricercatore',
    'Esploratore',
    'Allevatore',
    'Combattente',
    'Artista',
    'Studioso',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _starterQuery = _searchController.text.trim());
    });
    _loadOptions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
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
      return pokemon.name.toLowerCase().contains(query) ||
          pokemon.types.any((type) => type.toLowerCase().contains(query));
    }).toList(growable: false);
  }

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
      default:
        return true;
    }
  }

  Future<void> _next() async {
    if (!_canContinue || _isSaving) return;
    if (_step < 7) {
      setState(() => _step += 1);
      return;
    }
    await _completeOnboarding();
  }

  void _back() {
    if (_step <= 0 || _isSaving) return;
    setState(() => _step -= 1);
  }

  Map<String, int> _abilityScoresWithOrigin(TrainerOrigin? origin) {
    final scores = {...UserProfile.defaultAbilityScores};
    if (origin == null) return scores;
    for (final entry in origin.abilityBonuses.entries) {
      scores[entry.key] = (scores[entry.key] ?? 10) + entry.value;
    }
    return scores;
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
      widget.onCompleted();
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
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null && _origins.isEmpty
                ? _OnboardingError(message: _errorMessage!, onRetry: _loadOptions)
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 980),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                if (_step > 0)
                                  IconButton(
                                    onPressed: _back,
                                    icon: const Icon(Icons.arrow_back),
                                  )
                                else
                                  const SizedBox(width: 48),
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: (_step + 1) / 8,
                                    minHeight: 8,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                const SizedBox(width: 48),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: _ProfessorScene(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  child: _buildStep(theme),
                                ),
                              ),
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                _errorMessage!,
                                style: TextStyle(color: theme.colorScheme.error),
                              ),
                            ],
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _canContinue && !_isSaving ? _next : null,
                                child: Text(
                                  _isSaving
                                      ? 'CREAZIONE IN CORSO...'
                                      : _step == 7
                                          ? 'INIZIA L’AVVENTURA'
                                          : 'AVANTI',
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

  Widget _buildStep(ThemeData theme) {
    switch (_step) {
      case 0:
        return _DialogueCard(
          key: const ValueKey('welcome'),
          speaker: 'Professore',
          title: 'Benvenuto, Allenatore.',
          body:
              'Questa applicazione ti accompagnerà nella creazione del personaggio, nella gestione della squadra e durante le tue avventure da tavolo.',
          trailing: const Icon(Icons.explore_outlined, size: 56),
        );
      case 1:
        return _DialogueCard(
          key: const ValueKey('intro'),
          speaker: 'Professore',
          title: 'Un mondo di compagni e avventure.',
          body:
              'Ogni Pokémon ha statistiche, mosse, abilità e una propria storia. Qui potrai consultarli e gestirli con regole ispirate alla quinta edizione.',
          trailing: const Icon(Icons.auto_stories_outlined, size: 56),
        );
      case 2:
        return _DialogueCard(
          key: const ValueKey('name'),
          speaker: 'Professore',
          title: 'Prima di iniziare, dimmi…',
          body: 'Come ti chiami?',
          content: TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nome Allenatore'),
            onChanged: (_) => setState(() {}),
          ),
        );
      case 3:
        return _DialogueCard(
          key: const ValueKey('age'),
          speaker: 'Professore',
          title: 'Bene! E quanti anni hai?',
          body: 'Puoi sempre modificare questa informazione in seguito.',
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _age > 6 ? () => setState(() => _age--) : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Text(
                  '$_age',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: _age < 99 ? () => setState(() => _age++) : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        );
      case 4:
        return _DialogueCard(
          key: const ValueKey('origin'),
          speaker: 'Professore',
          title: 'Ogni Allenatore porta con sé una storia.',
          body: 'Da dove provieni?',
          content: DropdownButtonFormField<TrainerOrigin>(
            initialValue: _origin,
            isExpanded: true,
            items: [
              for (final origin in _origins)
                DropdownMenuItem(value: origin, child: Text(origin.name)),
            ],
            onChanged: (value) => setState(() => _origin = value),
            decoration: const InputDecoration(labelText: 'Origine'),
          ),
          footer: _origin == null
              ? null
              : Text(
                  _origin!.description,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
        );
      case 5:
        return _DialogueCard(
          key: const ValueKey('background'),
          speaker: 'Professore',
          title: 'Quale strada ti ha portato fin qui?',
          body: 'Scegli il background che descrive meglio il tuo Allenatore.',
          content: DropdownButtonFormField<String>(
            initialValue: _background,
            items: [
              for (final background in _backgrounds)
                DropdownMenuItem(value: background, child: Text(background)),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _background = value);
            },
            decoration: const InputDecoration(labelText: 'Background'),
          ),
        );
      case 6:
        return _DialogueCard(
          key: const ValueKey('starter'),
          speaker: 'Professore',
          title: 'Infine, scegli il tuo primo compagno.',
          body:
              'Puoi scegliere qualunque Pokémon non evoluto con SR 1/2 o inferiore.',
          content: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Cerca per nome o tipo',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 250,
                child: GridView.builder(
                  itemCount: _filteredStarters.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    childAspectRatio: .9,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final pokemon = _filteredStarters[index];
                    final selected = _starter?.id == pokemon.id;
                    return InkWell(
                      onTap: () => setState(() => _starter = pokemon),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: selected
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            width: selected ? 2 : 1,
                            color: selected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: PokemonAssetImage(
                                pokemon: pokemon,
                                useLargeArtwork: true,
                                size: 96,
                              ),
                            ),
                            Text(
                              pokemon.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              pokemon.types.join(' / '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      default:
        return _DialogueCard(
          key: const ValueKey('summary'),
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
    }
  }
}

class _ProfessorScene extends StatelessWidget {
  const _ProfessorScene({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.primaryContainer.withValues(alpha: .7),
                colors.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: compact
                ? Column(
                    children: [
                      const Expanded(child: _ProfessorPlaceholder()),
                      const SizedBox(height: 12),
                      Flexible(flex: 2, child: child),
                    ],
                  )
                : Row(
                    children: [
                      const Expanded(child: _ProfessorPlaceholder()),
                      const SizedBox(width: 18),
                      Expanded(flex: 2, child: child),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _ProfessorPlaceholder extends StatelessWidget {
  const _ProfessorPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320, maxHeight: 420),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: .78),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: const Center(
          child: Icon(Icons.person_outline, size: 150),
        ),
      ),
    );
  }
}

class _DialogueCard extends StatelessWidget {
  const _DialogueCard({
    super.key,
    required this.speaker,
    required this.title,
    required this.body,
    this.content,
    this.footer,
    this.trailing,
  });

  final String speaker;
  final String title;
  final String body;
  final Widget? content;
  final Widget? footer;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: const [
          BoxShadow(blurRadius: 18, spreadRadius: -10, offset: Offset(0, 10)),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              speaker,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                trailing?,
              ],
            ),
            const SizedBox(height: 8),
            Text(body),
            if (content != null) ...[
              const SizedBox(height: 18),
              content!,
            ],
            if (footer != null) ...[
              const SizedBox(height: 14),
              Divider(color: theme.colorScheme.outlineVariant),
              const SizedBox(height: 8),
              footer!,
            ],
          ],
        ),
      ),
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
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
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
            FilledButton(onPressed: onRetry, child: const Text('RIPROVA')),
          ],
        ),
      ),
    );
  }
}
