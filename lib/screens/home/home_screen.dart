import 'package:flutter/material.dart';

import '../../models/pokedex_entry.dart';
import '../../models/pokemon.dart';
import '../../models/trainer_progression.dart';
import '../../models/user_profile.dart';
import '../../repositories/battle_session_repository.dart';
import '../../repositories/master_battle_session_repository.dart';
import '../../repositories/pokemon_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../services/home_tour_service.dart';
import '../../services/profile_storage_service.dart';
import '../../widgets/home/home_tour_overlay.dart';
import '../../widgets/layout/responsive_content.dart';
import '../bag/bag_screen.dart';
import '../battle/battle_screen.dart';
import '../battle/npc_battle_screen.dart';
import '../breeding/breeding_screen.dart';
import '../capture/capture_pokemon_screen.dart';
import '../pc/pokemon_pc_screen.dart';
import '../pokedex/pokedex_screen.dart';
import '../profile/profiles_screen.dart';
import '../team/team_selection_screen.dart';
import '../tools/tools_screen.dart';
import '../trainer/trainer_sheet_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final BattleSessionRepository _battleSessionRepository =
      BattleSessionRepository();
  final MasterBattleSessionRepository _masterBattleSessionRepository =
      MasterBattleSessionRepository();
  final PokemonRepository _pokemonRepository = PokemonRepository();
  final ProfileStorageService _profileStorageService = ProfileStorageService();
  final HomeTourService _homeTourService = HomeTourService();

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _homeBodyKey = GlobalKey();
  final GlobalKey _trainerHeaderKey = GlobalKey();
  final GlobalKey _trainerSectionKey = GlobalKey();
  final GlobalKey _pokedexKey = GlobalKey();
  final GlobalKey _masterSectionKey = GlobalKey();
  final GlobalKey _profilesKey = GlobalKey();

  UserProfile? _profile;
  List<Pokemon> _pokemon = [];
  Map<int, PokedexEntry> _entries = {};

  bool _isLoading = true;
  bool _hasActiveBattle = false;
  bool _hasActiveMasterFight = false;
  bool _hasCheckedAutomaticTour = false;
  bool _isTourVisible = false;
  int _tourStepIndex = 0;
  Rect? _tourTargetRect;
  String? _errorMessage;

  List<HomeTourStepData> get _tourSteps => [
        HomeTourStepData(
          targetKey: _trainerHeaderKey,
          icon: Icons.dashboard_outlined,
          title: 'La tua dashboard',
          description:
              'Qui trovi subito il profilo attivo, il livello, il denaro, i Pokéslot disponibili e il grado sfida massimo che puoi controllare.',
        ),
        HomeTourStepData(
          targetKey: _trainerSectionKey,
          icon: Icons.groups_outlined,
          title: 'Allenatore e squadra',
          description:
              'Da questa sezione gestisci la scheda dell’Allenatore, catturi Pokémon, organizzi squadra e PC, controlli lo Zaino e segui allevamento e uova.',
        ),
        HomeTourStepData(
          targetKey: _pokedexKey,
          icon: Icons.catching_pokemon,
          title: 'Il Pokédex',
          description:
              'Apri il Pokédex per consultare le creature, applicare filtri e registrare quali Pokémon hai visto o catturato.',
        ),
        HomeTourStepData(
          targetKey: _masterSectionKey,
          icon: Icons.construction_outlined,
          title: 'Strumenti del Master',
          description:
              'Quest’area raccoglie generatori, incontri, raccolte, Allenatori PNG e strumenti per preparare e gestire i combattimenti.',
        ),
        HomeTourStepData(
          targetKey: _profilesKey,
          icon: Icons.info_outline,
          title: 'Profili e aiuto',
          description:
              'In Profili puoi creare o cambiare Allenatore. Per rivedere questa spiegazione in qualsiasi momento usa il pulsante INFO in alto.',
        ),
      ];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _profileRepository.getActiveProfile();
      final pokemon = await _pokemonRepository.getAllPokemon();
      final entries = await _profileStorageService.loadPokedexEntries();
      final hasActiveBattle = await _battleSessionRepository.hasSession(
        profile.id,
      );
      final hasActiveMasterFight = await _masterBattleSessionRepository
          .hasSession(profile.id);

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _pokemon = pokemon;
        _entries = entries;
        _hasActiveBattle = hasActiveBattle;
        _hasActiveMasterFight = hasActiveMasterFight;
        _isLoading = false;
      });
      _scheduleAutomaticTour();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _scheduleAutomaticTour() {
    if (_hasCheckedAutomaticTour) return;
    _hasCheckedAutomaticTour = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        final shouldShowTour = await _homeTourService.shouldShowTour();
        if (!mounted || !shouldShowTour) return;
        await _startTour();
      } catch (error) {
        debugPrint('Impossibile verificare il tour della Home: $error');
      }
    });
  }

  Future<void> _startTour() async {
    if (_isLoading || _errorMessage != null || _profile == null) return;

    setState(() {
      _isTourVisible = true;
      _tourStepIndex = 0;
      _tourTargetRect = null;
    });
    await _revealCurrentTourStep();
  }

  Future<void> _revealCurrentTourStep() async {
    if (!_isTourVisible || _tourStepIndex >= _tourSteps.length) return;

    await Future<void>.delayed(Duration.zero);
    if (!mounted || !_isTourVisible) return;

    final targetContext = _tourSteps[_tourStepIndex].targetKey.currentContext;
    if (targetContext != null && targetContext.mounted) {
      await Scrollable.ensureVisible(
        targetContext,
        alignment: 0.12,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    }

    await Future<void>.delayed(const Duration(milliseconds: 380));
    if (!mounted || !_isTourVisible) return;
    _updateTourTargetRect();
  }

  void _updateTourTargetRect() {
    if (!_isTourVisible || _tourStepIndex >= _tourSteps.length) return;

    final bodyBox =
        _homeBodyKey.currentContext?.findRenderObject() as RenderBox?;
    final targetBox = _tourSteps[_tourStepIndex]
        .targetKey
        .currentContext
        ?.findRenderObject() as RenderBox?;

    if (bodyBox == null || targetBox == null || !targetBox.hasSize) {
      setState(() => _tourTargetRect = null);
      return;
    }

    final targetOrigin = bodyBox.globalToLocal(
      targetBox.localToGlobal(Offset.zero),
    );
    final rect = (targetOrigin & targetBox.size).inflate(8);
    setState(() => _tourTargetRect = rect);
  }

  Future<void> _nextTourStep() async {
    if (_tourStepIndex >= _tourSteps.length - 1) {
      await _finishTour();
      return;
    }

    setState(() {
      _tourStepIndex += 1;
      _tourTargetRect = null;
    });
    await _revealCurrentTourStep();
  }

  Future<void> _previousTourStep() async {
    if (_tourStepIndex <= 0) return;

    setState(() {
      _tourStepIndex -= 1;
      _tourTargetRect = null;
    });
    await _revealCurrentTourStep();
  }

  Future<void> _finishTour() async {
    if (mounted) {
      setState(() {
        _isTourVisible = false;
        _tourTargetRect = null;
      });
    }

    try {
      await _homeTourService.markTourCompleted();
    } catch (error) {
      debugPrint('Impossibile salvare il completamento del tour: $error');
    }
  }

  Future<void> _resumeMasterFight() async {
    final profile = _profile;
    if (profile == null) return;

    final session = await _masterBattleSessionRepository.getSession(profile.id);
    if (!mounted) return;
    if (session == null) {
      await _loadDashboard();
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NpcBattleScreen(
          profileId: profile.id,
          catalog: _pokemon,
          initialSession: session,
        ),
      ),
    );
    await _loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final total = _pokemon.length;
    final seen = _pokemon.where((pokemon) {
      return _entries[pokemon.id]?.seen ?? false;
    }).length;
    final caught = _pokemon.where((pokemon) {
      return _entries[pokemon.id]?.caught ?? false;
    }).length;
    final hasActiveSession = _hasActiveBattle || _hasActiveMasterFight;
    final wideAppBar = MediaQuery.sizeOf(context).width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokédex 5e ITA'),
        actions: [
          if (wideAppBar)
            TextButton.icon(
              onPressed: _isLoading || _isTourVisible
                  ? null
                  : () {
                      _startTour();
                    },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
              ),
              icon: const Icon(Icons.info_outline),
              label: const Text('INFO'),
            )
          else
            IconButton(
              onPressed: _isLoading || _isTourVisible
                  ? null
                  : () {
                      _startTour();
                    },
              tooltip: 'INFO · Rivedi il tour',
              icon: const Icon(Icons.info_outline),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        key: _homeBodyKey,
        children: [
          Positioned.fill(
            child: ResponsiveContent(
              maxWidth: 1040,
              child: RefreshIndicator(
                onRefresh: _loadDashboard,
                child: ListView(
                  controller: _scrollController,
                  padding: EdgeInsets.fromLTRB(
                    16,
                    18,
                    16,
                    _isTourVisible ? 340 : 32,
                  ),
                  children: [
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 120),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_errorMessage != null)
                      _ErrorState(
                        message: _errorMessage!,
                        onRetry: _loadDashboard,
                      )
                    else ...[
                      _TrainerHeader(
                        key: _trainerHeaderKey,
                        profile: profile,
                      ),
                      const SizedBox(height: 20),
                      _ProgressOverview(total: total, seen: seen, caught: caught),
                      if (hasActiveSession) ...[
                        const SizedBox(height: 24),
                        const _HomeSectionTitle(
                          icon: Icons.play_circle_outline,
                          title: 'SESSIONI IN CORSO',
                          subtitle: 'Riprendi subito da dove avevi lasciato.',
                        ),
                        if (_hasActiveBattle)
                          _HomeActionButton(
                            icon: Icons.flash_on,
                            title: 'Riprendi battaglia',
                            subtitle:
                                'Continua dal round, turno, PP e status salvati.',
                            emphasized: true,
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const BattleScreen(),
                                ),
                              );
                              await _loadDashboard();
                            },
                          ),
                        if (_hasActiveMasterFight)
                          _HomeActionButton(
                            icon: Icons.sports_mma_outlined,
                            title: 'Riprendi Fight del Master',
                            subtitle:
                                'Riapri la sessione del Master con PF, PP, status e iniziativa salvati.',
                            emphasized: true,
                            onTap: _resumeMasterFight,
                          ),
                      ],
                      const SizedBox(height: 24),
                      _HomeSectionTitle(
                        key: _trainerSectionKey,
                        icon: Icons.person_outline,
                        title: 'ALLENATORE E SQUADRA',
                        subtitle:
                            'Gestisci il personaggio e i Pokémon catturati.',
                      ),
                      if (!_hasActiveBattle)
                        _HomeActionButton(
                          icon: Icons.flash_on,
                          title: 'Battle Companion',
                          subtitle:
                              'Traccia round, PF, status e PP durante il combattimento.',
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const BattleScreen(),
                              ),
                            );
                            await _loadDashboard();
                          },
                        ),
                      _HomeActionButton(
                        icon: Icons.badge_outlined,
                        title: 'Scheda Allenatore',
                        subtitle:
                            'Aggiorna livello, soldi e progressione campagna.',
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const TrainerSheetScreen(),
                            ),
                          );
                          await _loadDashboard();
                        },
                      ),
                      _HomeActionButton(
                        icon: Icons.add_circle_outline,
                        title: 'Cattura Pokémon',
                        subtitle:
                            'Scegli il Pokémon: va in squadra se c’è posto, altrimenti nel PC.',
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CapturePokemonScreen(),
                            ),
                          );
                          await _loadDashboard();
                        },
                      ),
                      _HomeActionButton(
                        icon: Icons.groups,
                        title: 'Squadra',
                        subtitle:
                            'Scegli fino a 6 Pokémon per il profilo attivo.',
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TeamSelectionScreen(
                                nickname: profile?.name ?? 'Allenatore',
                              ),
                            ),
                          );
                          await _loadDashboard();
                        },
                      ),
                      _HomeActionButton(
                        icon: Icons.computer,
                        title: 'PC Pokémon',
                        subtitle:
                            'Gestisci i Pokémon catturati fuori squadra.',
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PokemonPcScreen(),
                            ),
                          );
                          await _loadDashboard();
                        },
                      ),
                      _HomeActionButton(
                        icon: Icons.egg_alt_outlined,
                        title: 'Allevamento e uova',
                        subtitle:
                            'Verifica i genitori, crea uova, avanza l’incubazione e fai schiudere i Pokémon.',
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const BreedingScreen(),
                            ),
                          );
                          await _loadDashboard();
                        },
                      ),
                      _HomeActionButton(
                        icon: Icons.backpack_outlined,
                        title: 'Zaino',
                        subtitle:
                            'Equipaggiamento, cure e oggetti da cattura.',
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const BagScreen(),
                            ),
                          );
                          await _loadDashboard();
                        },
                      ),
                      const SizedBox(height: 24),
                      const _HomeSectionTitle(
                        icon: Icons.menu_book_outlined,
                        title: 'CONSULTAZIONE',
                        subtitle: 'Cerca informazioni e aggiorna i progressi.',
                      ),
                      _HomeActionButton(
                        key: _pokedexKey,
                        icon: Icons.catching_pokemon,
                        title: 'Apri Pokédex',
                        subtitle: 'Consulta, filtra e marca i Pokémon.',
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PokedexScreen(),
                            ),
                          );
                          await _loadDashboard();
                        },
                      ),
                      const SizedBox(height: 24),
                      _HomeSectionTitle(
                        key: _masterSectionKey,
                        icon: Icons.construction,
                        title: 'STRUMENTI DEL MASTER',
                        subtitle:
                            'Genera contenuti, usa le librerie e prepara i fight.',
                      ),
                      _HomeActionButton(
                        icon: Icons.construction,
                        title: 'Apri Strumenti del Master',
                        subtitle:
                            'Generatori Pokémon, incontri, raccolte e Allenatori PNG.',
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ToolsScreen(),
                            ),
                          );
                          await _loadDashboard();
                        },
                      ),
                      const SizedBox(height: 24),
                      const _HomeSectionTitle(
                        icon: Icons.settings_outlined,
                        title: 'GESTIONE APPLICAZIONE',
                        subtitle: 'Gestisci i profili e i dati dell’app.',
                      ),
                      _HomeActionButton(
                        key: _profilesKey,
                        icon: Icons.person,
                        title: 'Profili',
                        subtitle:
                            'Crea, cambia o elimina profili allenatore.',
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ProfilesScreen(),
                            ),
                          );
                          await _loadDashboard();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (_isTourVisible && !_isLoading && _errorMessage == null)
            Positioned.fill(
              child: HomeTourOverlay(
                step: _tourSteps[_tourStepIndex],
                stepIndex: _tourStepIndex,
                totalSteps: _tourSteps.length,
                targetRect: _tourTargetRect,
                onBack: _tourStepIndex == 0
                    ? null
                    : () {
                        _previousTourStep();
                      },
                onNext: () {
                  _nextTourStep();
                },
                onSkip: () {
                  _finishTour();
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _TrainerHeader extends StatelessWidget {
  const _TrainerHeader({super.key, required this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final profileName = profile?.name ?? 'Allenatore';
    final trainerLevel = profile?.trainerLevel ?? 1;
    final money = profile?.money ?? 0;
    final pokeslots = TrainerProgression.pokeslotsForLevel(trainerLevel);
    final maxSr = TrainerProgression.maxControlledSrForLevel(trainerLevel);

    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.person,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 34,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ciao, $profileName',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _TrainerInfoChip(label: 'Lv. $trainerLevel'),
                  _TrainerInfoChip(label: '₽ $money'),
                  _TrainerInfoChip(label: 'Pokéslot $pokeslots'),
                  _TrainerInfoChip(label: 'SR max $maxSr'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrainerInfoChip extends StatelessWidget {
  const _TrainerInfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _ProgressOverview extends StatelessWidget {
  const _ProgressOverview({
    required this.total,
    required this.seen,
    required this.caught,
  });

  final int total;
  final int seen;
  final int caught;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progresso Pokédex',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: total == 0 ? 0 : caught / total,
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ProgressStat(label: 'Visti', value: '$seen/$total'),
                ),
                Expanded(
                  child: _ProgressStat(
                    label: 'Catturati',
                    value: '$caught/$total',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  const _ProgressStat({required this.label, required this.value});

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
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _HomeSectionTitle extends StatelessWidget {
  const _HomeSectionTitle({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeActionButton extends StatelessWidget {
  const _HomeActionButton({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.emphasized = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: emphasized ? colors.primaryContainer : null,
      child: ListTile(
        leading: Icon(
          icon,
          color: emphasized ? colors.onPrimaryContainer : colors.primary,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

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
