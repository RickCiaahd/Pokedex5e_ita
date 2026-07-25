import 'package:flutter/material.dart';

import '../../models/pokemon.dart';
import '../../localization/ui_text.dart';
import '../../repositories/master_battle_session_repository.dart';
import '../../repositories/pokemon_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../services/guided_tour_service.dart';
import '../../widgets/layout/responsive_content.dart';
import '../../widgets/navigation/home_leading_button.dart';
import '../../widgets/tour/guided_tour.dart';
import '../battle/npc_battle_screen.dart';
import 'encounter_generator_screen.dart';
import 'encounter_library_screen.dart';
import 'npc_trainer_generator_screen.dart';
import 'npc_trainer_library_screen.dart';
import 'pokemon_generator_screen.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final PokemonRepository _pokemonRepository = PokemonRepository();
  final MasterBattleSessionRepository _battleRepository =
      MasterBattleSessionRepository();
  final GuidedTourController _tourController = GuidedTourController(
    tourId: GuidedTourIds.masterTools,
  );
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _introKey = GlobalKey();
  final GlobalKey _generatorsKey = GlobalKey();
  final GlobalKey _librariesKey = GlobalKey();

  String? _profileId;
  List<Pokemon> _catalog = const [];
  bool _hasActiveMasterFight = false;
  bool _isLoading = true;
  String? _error;

  List<GuidedTourStepData> get _tourSteps => [
    GuidedTourStepData(
      targetKey: _introKey,
      icon: Icons.construction_outlined,
      title: context.uiText('Il centro di comando', 'The command center'),
      description: context.uiText(
        'Questa schermata separa la preparazione della sessione dalle librerie e dal Fight del Master. Ogni blocco raccoglie strumenti con uno scopo preciso.',
        'This screen separates session preparation from libraries and the GM Fight. Each section groups tools with a specific purpose.',
      ),
    ),
    GuidedTourStepData(
      targetKey: _generatorsKey,
      icon: Icons.auto_awesome_outlined,
      title: context.uiText('Generatori', 'Generators'),
      description: context.uiText(
        'Qui crei Pokémon, incontri e Allenatori PNG. I risultati possono essere usati subito oppure salvati per una sessione futura.',
        'Create Pokémon, encounters and NPC Trainers. Results can be used immediately or saved for a future session.',
      ),
      fallbackScrollFraction: .38,
    ),
    GuidedTourStepData(
      targetKey: _librariesKey,
      icon: Icons.inventory_2_outlined,
      title: context.uiText('Librerie e Fight', 'Libraries and Fight'),
      description: context.uiText(
        'Le librerie riaprono i contenuti salvati e permettono di portarli nel Fight del Master, che conserva PF, PP, status, iniziativa e round.',
        'Libraries reopen saved content and send it to the GM Fight, which preserves HP, PP, conditions, initiative and rounds.',
      ),
      fallbackScrollFraction: 1,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tourController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final profile = await _profileRepository.getActiveProfile();
      final catalog = await _pokemonRepository.getAllPokemon();
      final hasActiveFight = await _battleRepository.hasSession(profile.id);
      if (!mounted) return;
      setState(() {
        _profileId = profile.id;
        _catalog = catalog;
        _hasActiveMasterFight = hasActiveFight;
        _isLoading = false;
      });
      _tourController.showAutomaticallyIfNeeded(ready: true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _resumeMasterFight() async {
    final profileId = _profileId;
    if (profileId == null) return;
    final session = await _battleRepository.getSession(profileId);
    if (!mounted) return;
    if (session == null) {
      await _load();
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NpcBattleScreen(
          profileId: profileId,
          catalog: _catalog,
          initialSession: session,
        ),
      ),
    );
    if (!mounted) return;
    await _load();
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: const HomeLeadingButton(),
        title: Text(context.uiText('Strumenti del Master', 'GM Tools')),
        actions: [
          GuidedTourInfoAction(
            controller: _tourController,
            enabled: !_isLoading && _error == null,
          ),
          const HomeAppBarAction(),
        ],
      ),
      body: AnimatedBuilder(
        animation: _tourController,
        builder: (context, _) {
          return Stack(
            children: [
              Positioned.fill(
                child: ResponsiveContent(
                  maxWidth: 1180,
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      controller: _scrollController,
                      padding: EdgeInsets.fromLTRB(
                        16,
                        12,
                        16,
                        _tourController.isVisible ? 330 : 32,
                      ),
                      children: [
                        Card(
                          key: _introKey,
                          color: colorScheme.primaryContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.construction,
                                  size: 38,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.uiText(
                                          'Preparazione e gestione della sessione',
                                          'Session preparation and management',
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              color: colorScheme
                                                  .onPrimaryContainer,
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        context.uiText(
                                          'Generatori, raccolte, contenuti salvati e Fight del Master sono divisi per funzione.',
                                          'Generators, collections, saved content and the GM Fight are organized by purpose.',
                                        ),
                                        style: TextStyle(
                                          color: colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_isLoading) ...[
                          const SizedBox(height: 12),
                          const LinearProgressIndicator(),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Card(
                            color: colorScheme.errorContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (_hasActiveMasterFight) ...[
                          const SizedBox(height: 18),
                          _ToolSectionTitle(
                            icon: Icons.play_circle_outline,
                            title: context.uiText(
                              'SESSIONE IN CORSO',
                              'ONGOING SESSION',
                            ),
                            subtitle: context.uiText(
                              'La sessione rimane salvata finché non viene sostituita.',
                              'The session remains saved until it is replaced.',
                            ),
                          ),
                          Card(
                            color: colorScheme.secondaryContainer,
                            child: ListTile(
                              leading: Icon(
                                Icons.sports_mma_outlined,
                                color: colorScheme.onSecondaryContainer,
                              ),
                              title: Text(
                                context.uiText(
                                  'Fight del Master in corso',
                                  'GM Fight in progress',
                                ),
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                              subtitle: Text(
                                context.uiText(
                                  'Riprendi PF, PP, status, round e iniziativa salvati.',
                                  'Resume saved HP, PP, conditions, rounds and initiative.',
                                ),
                              ),
                              trailing: const Icon(Icons.play_arrow),
                              onTap: _isLoading ? null : _resumeMasterFight,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        _ToolSectionTitle(
                          key: _generatorsKey,
                          icon: Icons.auto_awesome_outlined,
                          title: context.uiText('GENERATORI', 'GENERATORS'),
                          subtitle: context.uiText(
                            'Crea nuovi contenuti da usare o salvare.',
                            'Create new content to use or save.',
                          ),
                        ),
                        _ToolCardGrid(
                          children: [
                            _ToolCard(
                              icon: Icons.catching_pokemon,
                              title: context.uiText(
                                'Generatore Pokémon',
                                'Pokémon Generator',
                              ),
                              subtitle: context.uiText(
                                'Estrai un Pokémon con forma, livello, natura, abilità, mosse, sesso e probabilità shiny.',
                                'Generate a Pokémon with form, level, nature, ability, moves, gender and shiny chance.',
                              ),
                              actionLabel: context.uiText('GENERA', 'GENERATE'),
                              onTap: () =>
                                  _open(const PokemonGeneratorScreen()),
                            ),
                            _ToolCard(
                              icon: Icons.travel_explore,
                              title: context.uiText(
                                'Generatore incontri',
                                'Encounter Generator',
                              ),
                              subtitle: context.uiText(
                                'Composizione automatica, manuale e raccolte ponderate con stima della difficoltà.',
                                'Automatic or manual composition and weighted collections with difficulty estimates.',
                              ),
                              actionLabel: context.uiText('GENERA', 'GENERATE'),
                              onTap: () =>
                                  _open(const EncounterGeneratorScreen()),
                            ),
                            _ToolCard(
                              icon: Icons.groups_2_outlined,
                              title: context.uiText(
                                'Generatore Allenatori PNG',
                                'NPC Trainer Generator',
                              ),
                              subtitle: context.uiText(
                                'Crea identità, specializzazione, squadra, personalità, tattiche e ricompense.',
                                'Create identity, specialization, team, personality, tactics and rewards.',
                              ),
                              actionLabel: context.uiText('GENERA', 'GENERATE'),
                              onTap: () =>
                                  _open(const NpcTrainerGeneratorScreen()),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        _ToolSectionTitle(
                          key: _librariesKey,
                          icon: Icons.inventory_2_outlined,
                          title: context.uiText('LIBRERIE', 'LIBRARIES'),
                          subtitle: context.uiText(
                            'Riapri, modifica e usa i contenuti già preparati.',
                            'Reopen, edit and use prepared content.',
                          ),
                        ),
                        _ToolCardGrid(
                          children: [
                            _ToolCard(
                              icon: Icons.bookmarks_outlined,
                              title: context.uiText(
                                'Libreria incontri',
                                'Encounter Library',
                              ),
                              subtitle: context.uiText(
                                'Incontri salvati, raccolte ponderate e avvio diretto nel Fight del Master.',
                                'Saved encounters, weighted collections and direct launch into the GM Fight.',
                              ),
                              actionLabel: context.uiText('APRI', 'OPEN'),
                              onTap: () =>
                                  _open(const EncounterLibraryScreen()),
                            ),
                            _ToolCard(
                              icon: Icons.people_alt_outlined,
                              title: context.uiText(
                                'Libreria Allenatori PNG',
                                'NPC Trainer Library',
                              ),
                              subtitle: context.uiText(
                                'Allenatori salvati, selezione multipla e gestione delle loro squadre nel fight.',
                                'Saved Trainers, multiple selection and team management in the fight.',
                              ),
                              actionLabel: context.uiText('APRI', 'OPEN'),
                              onTap: () =>
                                  _open(const NpcTrainerLibraryScreen()),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              GuidedTourLayer(
                controller: _tourController,
                steps: _tourSteps,
                scrollController: _scrollController,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ToolSectionTitle extends StatelessWidget {
  const _ToolSectionTitle({
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
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

class _ToolCardGrid extends StatelessWidget {
  const _ToolCardGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final twoColumns = constraints.maxWidth >= 760;
        final cardWidth = twoColumns
            ? (constraints.maxWidth - spacing) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: 4,
          children: [
            for (final child in children)
              SizedBox(width: cardWidth, child: child),
          ],
        );
      },
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(compact ? 13 : 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: compact ? 23 : 27,
                    backgroundColor: enabled
                        ? colorScheme.secondaryContainer
                        : colorScheme.surfaceContainerHighest,
                    child: Icon(
                      icon,
                      color: enabled
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(width: compact ? 10 : 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(subtitle),
                      ],
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 12),
                    Text(
                      actionLabel,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: enabled
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                  if (enabled) const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
