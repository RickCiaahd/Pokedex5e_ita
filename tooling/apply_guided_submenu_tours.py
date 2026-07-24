from __future__ import annotations

import re
from pathlib import Path


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path}: blocco atteso {count} volte invece di 1: {old[:100]!r}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")


def replace_regex_once(path: Path, pattern: str, replacement: str) -> None:
    text = path.read_text(encoding="utf-8")
    updated, count = re.subn(pattern, replacement, text, count=1, flags=re.S)
    if count != 1:
        raise SystemExit(f"{path}: pattern non trovato una sola volta: {pattern[:120]!r}")
    path.write_text(updated, encoding="utf-8")


# ---------------------------------------------------------------------------
# Strumenti del Master
# ---------------------------------------------------------------------------
tools = Path("lib/screens/tools/tools_screen.dart")
replace_once(
    tools,
    "import '../../repositories/profile_repository.dart';\n",
    "import '../../repositories/profile_repository.dart';\n"
    "import '../../services/guided_tour_service.dart';\n",
)
replace_once(
    tools,
    "import '../../widgets/navigation/home_leading_button.dart';\n",
    "import '../../widgets/navigation/home_leading_button.dart';\n"
    "import '../../widgets/tour/guided_tour.dart';\n",
)
replace_once(
    tools,
    """  final MasterBattleSessionRepository _battleRepository =
      MasterBattleSessionRepository();

  String? _profileId;
""",
    """  final MasterBattleSessionRepository _battleRepository =
      MasterBattleSessionRepository();
  final GuidedTourController _tourController = GuidedTourController(
    tourId: GuidedTourIds.masterTools,
  );
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _introKey = GlobalKey();
  final GlobalKey _generatorsKey = GlobalKey();
  final GlobalKey _librariesKey = GlobalKey();

  String? _profileId;
""",
)
replace_once(
    tools,
    """  String? _error;

  @override
  void initState() {
""",
    """  String? _error;

  List<GuidedTourStepData> get _tourSteps => [
        GuidedTourStepData(
          targetKey: _introKey,
          icon: Icons.construction_outlined,
          title: 'Il centro di comando',
          description:
              'Questa schermata separa la preparazione della sessione dalle librerie e dal Fight del Master. Ogni blocco raccoglie strumenti con uno scopo preciso.',
        ),
        GuidedTourStepData(
          targetKey: _generatorsKey,
          icon: Icons.auto_awesome_outlined,
          title: 'Generatori',
          description:
              'Qui crei Pokémon, incontri e Allenatori PNG. I risultati possono essere usati subito oppure salvati per una sessione futura.',
          fallbackScrollFraction: .38,
        ),
        GuidedTourStepData(
          targetKey: _librariesKey,
          icon: Icons.inventory_2_outlined,
          title: 'Librerie e Fight',
          description:
              'Le librerie riaprono i contenuti salvati e permettono di portarli nel Fight del Master, che conserva PF, PP, status, iniziativa e round.',
          fallbackScrollFraction: 1,
        ),
      ];

  @override
  void initState() {
""",
)
replace_once(
    tools,
    """  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
""",
    """  void initState() {
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
""",
)
replace_once(
    tools,
    """        _hasActiveMasterFight = hasActiveFight;
        _isLoading = false;
      });
""",
    """        _hasActiveMasterFight = hasActiveFight;
        _isLoading = false;
      });
      _tourController.showAutomaticallyIfNeeded(ready: true);
""",
)
new_tools_build = r'''  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: const HomeLeadingButton(),
        title: const Text('Strumenti del Master'),
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Preparazione e gestione della sessione',
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
                                        'Generatori, raccolte, contenuti salvati e Fight del Master sono divisi per funzione.',
                                        style: TextStyle(
                                          color:
                                              colorScheme.onPrimaryContainer,
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
                          const _ToolSectionTitle(
                            icon: Icons.play_circle_outline,
                            title: 'SESSIONE IN CORSO',
                            subtitle:
                                'La sessione rimane salvata finché non viene sostituita.',
                          ),
                          Card(
                            color: colorScheme.secondaryContainer,
                            child: ListTile(
                              leading: Icon(
                                Icons.sports_mma_outlined,
                                color: colorScheme.onSecondaryContainer,
                              ),
                              title: const Text(
                                'Fight del Master in corso',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                              subtitle: const Text(
                                'Riprendi PF, PP, status, round e iniziativa salvati.',
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
                          title: 'GENERATORI',
                          subtitle: 'Crea nuovi contenuti da usare o salvare.',
                        ),
                        _ToolCardGrid(
                          children: [
                            _ToolCard(
                              icon: Icons.catching_pokemon,
                              title: 'Generatore Pokémon',
                              subtitle:
                                  'Estrai un Pokémon con forma, livello, natura, abilità, mosse, sesso e probabilità shiny.',
                              actionLabel: 'GENERA',
                              onTap: () =>
                                  _open(const PokemonGeneratorScreen()),
                            ),
                            _ToolCard(
                              icon: Icons.travel_explore,
                              title: 'Generatore incontri',
                              subtitle:
                                  'Composizione automatica, manuale e raccolte ponderate con stima della difficoltà.',
                              actionLabel: 'GENERA',
                              onTap: () =>
                                  _open(const EncounterGeneratorScreen()),
                            ),
                            _ToolCard(
                              icon: Icons.groups_2_outlined,
                              title: 'Generatore Allenatori PNG',
                              subtitle:
                                  'Crea identità, specializzazione, squadra, personalità, tattiche e ricompense.',
                              actionLabel: 'GENERA',
                              onTap: () =>
                                  _open(const NpcTrainerGeneratorScreen()),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        _ToolSectionTitle(
                          key: _librariesKey,
                          icon: Icons.inventory_2_outlined,
                          title: 'LIBRERIE',
                          subtitle:
                              'Riapri, modifica e usa i contenuti già preparati.',
                        ),
                        _ToolCardGrid(
                          children: [
                            _ToolCard(
                              icon: Icons.bookmarks_outlined,
                              title: 'Libreria incontri',
                              subtitle:
                                  'Incontri salvati, raccolte ponderate e avvio diretto nel Fight del Master.',
                              actionLabel: 'APRI',
                              onTap: () =>
                                  _open(const EncounterLibraryScreen()),
                            ),
                            _ToolCard(
                              icon: Icons.people_alt_outlined,
                              title: 'Libreria Allenatori PNG',
                              subtitle:
                                  'Allenatori salvati, selezione multipla e gestione delle loro squadre nel fight.',
                              actionLabel: 'APRI',
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
'''
replace_regex_once(
    tools,
    r"  @override\n  Widget build\(BuildContext context\) \{.*?\n  \}\n\}\n\nclass _ToolSectionTitle",
    new_tools_build + "}\n\nclass _ToolSectionTitle",
)
replace_once(
    tools,
    """class _ToolSectionTitle extends StatelessWidget {
  const _ToolSectionTitle({
    required this.icon,
""",
    """class _ToolSectionTitle extends StatelessWidget {
  const _ToolSectionTitle({
    super.key,
    required this.icon,
""",
)


# ---------------------------------------------------------------------------
# Scheda Allenatore
# ---------------------------------------------------------------------------
trainer = Path("lib/screens/trainer/trainer_sheet_screen.dart")
replace_once(
    trainer,
    "import '../../services/trainer_path_automation_service.dart';\n",
    "import '../../services/guided_tour_service.dart';\n"
    "import '../../services/trainer_path_automation_service.dart';\n",
)
replace_once(
    trainer,
    "import '../../widgets/trainer/trainer_path_automation_panel.dart';\n",
    "import '../../widgets/tour/guided_tour.dart';\n"
    "import '../../widgets/trainer/trainer_path_automation_panel.dart';\n",
)
replace_once(
    trainer,
    """  final TextEditingController _raceController = TextEditingController();

  UserProfile? _profile;
""",
    """  final TextEditingController _raceController = TextEditingController();
  final GuidedTourController _tourController = GuidedTourController(
    tourId: GuidedTourIds.trainerSheet,
  );
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _sheetKey = GlobalKey();
  final GlobalKey _progressionKey = GlobalKey();
  final GlobalKey _automationKey = GlobalKey();

  UserProfile? _profile;
""",
)
replace_once(
    trainer,
    """  String? _errorMessage;

  @override
  void initState() {
""",
    """  String? _errorMessage;

  List<GuidedTourStepData> get _tourSteps => [
        GuidedTourStepData(
          targetKey: _sheetKey,
          icon: Icons.badge_outlined,
          title: 'La scheda interattiva',
          description:
              'Qui aggiorni nome, livello, denaro, origine, starter, caratteristiche, PF, CA, velocità, competenze e tiri salvezza. I riquadri modificabili reagiscono al tocco.',
        ),
        GuidedTourStepData(
          targetKey: _progressionKey,
          icon: Icons.route_outlined,
          title: 'Avanzamento e percorso',
          description:
              'La colonna Avanzamento mostra specializzazioni, Percorso Allenatore e privilegi sbloccati ai livelli corretti. Le scelte disponibili cambiano con il livello.',
          fallbackScrollFraction: .58,
        ),
        GuidedTourStepData(
          targetKey: _automationKey,
          icon: Icons.auto_awesome_outlined,
          title: 'Risorse del percorso',
          description:
              'Questo pannello gestisce risorse, scelte e recuperi del Trainer Path. Ricorda di salvare la scheda dopo aver modificato i dati principali.',
          fallbackScrollFraction: 1,
        ),
      ];

  @override
  void initState() {
""",
)
replace_once(
    trainer,
    """    _raceController.dispose();
    super.dispose();
""",
    """    _raceController.dispose();
    _tourController.dispose();
    _scrollController.dispose();
    super.dispose();
""",
)
replace_once(
    trainer,
    """        _reconcileTrainerPathAutomation();
        _isLoading = false;
      });
""",
    """        _reconcileTrainerPathAutomation();
        _isLoading = false;
      });
      _tourController.showAutomaticallyIfNeeded(ready: true);
""",
)
new_trainer_build = r'''  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const HomeLeadingButton(),
        title: const Text('Scheda Allenatore'),
        actions: [
          GuidedTourInfoAction(
            controller: _tourController,
            enabled: !_isLoading && _profile != null,
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
                child: RefreshIndicator(
                  onRefresh: _loadProfile,
                  child: ListView(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(
                      24,
                      24,
                      24,
                      _tourController.isVisible ? 340 : 24,
                    ),
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
                          key: _sheetKey,
                          progressionKey: _progressionKey,
                          nameController: _nameController,
                          moneyController: _moneyController,
                          race: _raceController.text.trim(),
                          raceDescription:
                              _originByName(_raceController.text.trim())
                                      ?.description ??
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
                          savingThrowProficiencies:
                              _savingThrowProficiencies,
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
                            onLongRest: () => _restoreTrainerPathResources(
                              TrainerPathResourceReset.longRest,
                            ),
                          ),
                        ),
                      ],
                    ],
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
'''
replace_regex_once(
    trainer,
    r"  @override\n  Widget build\(BuildContext context\) \{\n    return Scaffold\(.*?\n  \}\n\}\n\nint _abilityModifier",
    new_trainer_build + "}\n\nint _abilityModifier",
)
replace_once(
    trainer,
    """class _InteractiveTrainerSheet extends StatelessWidget {
  const _InteractiveTrainerSheet({
    required this.nameController,
""",
    """class _InteractiveTrainerSheet extends StatelessWidget {
  const _InteractiveTrainerSheet({
    super.key,
    required this.progressionKey,
    required this.nameController,
""",
)
replace_once(
    trainer,
    """  final TextEditingController nameController;
""",
    """  final GlobalKey progressionKey;
  final TextEditingController nameController;
""",
)
replace_once(
    trainer,
    """                    child: _TrainerProgressionColumn(
                      trainerLevel: trainerLevel,
""",
    """                    child: _TrainerProgressionColumn(
                      key: progressionKey,
                      trainerLevel: trainerLevel,
""",
)
replace_once(
    trainer,
    """                  _TrainerProgressionColumn(
                    trainerLevel: trainerLevel,
""",
    """                  _TrainerProgressionColumn(
                    key: progressionKey,
                    trainerLevel: trainerLevel,
""",
)
replace_once(
    trainer,
    """class _TrainerProgressionColumn extends StatelessWidget {
  const _TrainerProgressionColumn({
    required this.trainerLevel,
""",
    """class _TrainerProgressionColumn extends StatelessWidget {
  const _TrainerProgressionColumn({
    super.key,
    required this.trainerLevel,
""",
)


# ---------------------------------------------------------------------------
# Battle Companion
# ---------------------------------------------------------------------------
battle = Path("lib/screens/battle/battle_screen.dart")
replace_once(
    battle,
    "import '../../services/custom_pokemon_runtime_registry.dart';\n",
    "import '../../services/custom_pokemon_runtime_registry.dart';\n"
    "import '../../services/guided_tour_service.dart';\n",
)
replace_once(
    battle,
    "import '../../widgets/trainer/trainer_path_passive_card.dart';\n",
    "import '../../widgets/tour/guided_tour.dart';\n"
    "import '../../widgets/trainer/trainer_path_passive_card.dart';\n",
)
replace_once(
    battle,
    """  final BattleSessionRepository _battleSessionRepository =
      BattleSessionRepository();
  final Random _random = Random();

  late Future<_BattleData> _future;
""",
    """  final BattleSessionRepository _battleSessionRepository =
      BattleSessionRepository();
  final Random _random = Random();
  final GuidedTourController _tourController = GuidedTourController(
    tourId: GuidedTourIds.battle,
  );
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _battleHeaderKey = GlobalKey();
  final GlobalKey _initiativeKey = GlobalKey();
  final GlobalKey _environmentKey = GlobalKey();
  final GlobalKey _activePokemonKey = GlobalKey();
  final GlobalKey _movesKey = GlobalKey();

  late Future<_BattleData> _future;
""",
)
replace_once(
    battle,
    """  UserProfile? _activeProfile;

  @override
  void initState() {
""",
    """  UserProfile? _activeProfile;
  bool _isBattleReady = false;

  List<GuidedTourStepData> get _tourSteps => [
        GuidedTourStepData(
          targetKey: _battleHeaderKey,
          icon: Icons.groups_outlined,
          title: 'Squadra e round',
          description:
              'In alto controlli il round, termini la battaglia e scegli quale Pokémon della squadra è attivo. La sessione viene conservata finché non la chiudi.',
        ),
        GuidedTourStepData(
          targetKey: _initiativeKey,
          icon: Icons.format_list_numbered,
          title: 'Iniziativa e turni',
          description:
              'Aggiungi partecipanti, modifica l’ordine e usa il comando del turno successivo. Quando il giro termina, il round avanza automaticamente.',
          fallbackScrollFraction: .16,
        ),
        GuidedTourStepData(
          targetKey: _environmentKey,
          icon: Icons.public_outlined,
          title: 'Meteo e terreno',
          description:
              'L’ambiente applica regole e modificatori a velocità, CA, tipi e danni. Puoi impostarlo manualmente o generare il meteo con il d100.',
          fallbackScrollFraction: .30,
        ),
        GuidedTourStepData(
          targetKey: _activePokemonKey,
          icon: Icons.favorite_outline,
          title: 'Pokémon attivo',
          description:
              'Qui gestisci PF, PF temporanei, status, forma di battaglia, oggetto tenuto e Zaino rapido del Pokémon selezionato.',
          fallbackScrollFraction: .50,
        ),
        GuidedTourStepData(
          targetKey: _movesKey,
          icon: Icons.flash_on_outlined,
          title: 'Mosse e PP',
          description:
              'Le mosse mostrano tiro, CD, danni e PP rimanenti. Usa e ripristina i PP dai pulsanti; quando finiscono, il tracker segnala Struggle.',
          fallbackScrollFraction: 1,
        ),
      ];

  @override
  void initState() {
""",
)
replace_once(
    battle,
    """  void initState() {
    super.initState();
    _future = _loadBattleData();
  }

  Future<_BattleData> _loadBattleData() async {
""",
    """  void initState() {
    super.initState();
    _future = _loadBattleData();
  }

  @override
  void dispose() {
    _tourController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<_BattleData> _loadBattleData() async {
""",
)
replace_once(
    battle,
    """    await _restoreOrStartSession(data);
    return data;
""",
    """    await _restoreOrStartSession(data);
    if (mounted) {
      setState(() => _isBattleReady = data.occupiedSlots.isNotEmpty);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _tourController.showAutomaticallyIfNeeded(ready: _isBattleReady);
      });
    }
    return data;
""",
)
replace_once(
    battle,
    """    setState(() {
      _message = message;
      _future = _loadBattleData();
    });
""",
    """    setState(() {
      _message = message;
      _isBattleReady = false;
      _future = _loadBattleData();
    });
""",
)
new_battle_build = r'''  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const HomeLeadingButton(),
        title: const Text('Battle Companion'),
        actions: [
          GuidedTourInfoAction(
            controller: _tourController,
            enabled: _isBattleReady,
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
                  maxWidth: 1280,
                  child: FutureBuilder<_BattleData>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return _BattleEmptyState(
                          icon: Icons.error_outline,
                          title: 'Errore caricando il combattimento',
                          message: snapshot.error.toString(),
                          actionLabel: 'Riprova',
                          onAction: () => _reload(),
                        );
                      }

                      final data = snapshot.data;
                      if (data == null || data.occupiedSlots.isEmpty) {
                        return _BattleEmptyState(
                          icon: Icons.groups_outlined,
                          title: 'Nessun Pokémon in squadra',
                          message:
                              'Aggiungi almeno un Pokémon alla squadra prima di aprire il tracker.',
                          actionLabel: 'Ricarica',
                          onAction: () => _reload(),
                        );
                      }

                      final activeSlot = _activeSlotFor(data)!;
                      final basePokemon =
                          data.pokemonById[activeSlot.pokemonId!]!;
                      final effectiveFormName = _effectiveFormName(activeSlot);
                      final pokemon = _pokemonForSlot(data, activeSlot)!;
                      final canChangeForm =
                          BattleFormChangeService.supports(basePokemon);
                      final moveReferences = _movesForSlot(activeSlot, pokemon);
                      final noPpLeft = _hasNoPpLeft(
                        activeSlot,
                        moveReferences,
                        data.moves,
                      );
                      MoveData? moveForActive(String reference) =>
                          data.moves[MoveRepository.contextualKey(
                            activeSlot.pokemonId!,
                            reference,
                          )];
                      final heldItem = data.heldItemFor(activeSlot);
                      final passiveNotes =
                          TrainerPathPassiveService.passiveNotes(
                        profile: data.profile,
                        pokemon: pokemon,
                        slot: activeSlot,
                      );
                      final attributes = _attributeScores(
                        pokemon,
                        activeSlot,
                        basePokemon: basePokemon,
                        formName: effectiveFormName,
                      );
                      final temporaryHpRule =
                          _temporaryHpRule(data, activeSlot);
                      final temporaryHp =
                          _temporaryHpBySlot[activeSlot.slotIndex] ?? 0;
                      final temporaryHpEnabled =
                          _temporaryHpEnabledBySlot[activeSlot.slotIndex] ??
                              false;
                      final baseArmorClass =
                          BattleEnvironmentService.baseArmorClass(
                        pokemon,
                        activeSlot,
                      );
                      final formArmorClass = baseArmorClass +
                          BattleFormChangeService.armorClassBonus(
                            basePokemon,
                            effectiveFormName,
                          );
                      final effectiveArmorClass = formArmorClass +
                          BattleEnvironmentService.armorClassBonus(
                            pokemon: pokemon,
                            slot: activeSlot,
                            environment: _environment,
                          );

                      return RefreshIndicator(
                        onRefresh: () => _reload(),
                        child: ListView(
                          controller: _scrollController,
                          padding: EdgeInsets.fromLTRB(
                            12,
                            8,
                            12,
                            _tourController.isVisible ? 340 : 24,
                          ),
                          children: [
                            KeyedSubtree(
                              key: _battleHeaderKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _BattleHeader(
                                    round: _round,
                                    profile: data.profile,
                                    trainerInitiativeBonus:
                                        _trainerInitiativeBonus(data.profile),
                                    onEnd: () => _endBattle(data),
                                  ),
                                  const SizedBox(height: 12),
                                  _PartyBar(
                                    slots: data.occupiedSlots,
                                    activeSlot: activeSlot,
                                    pokemonForSlot: (slot) =>
                                        _pokemonForSlot(data, slot),
                                    imagePokemonForSlot: (slot) =>
                                        data.pokemonById[slot.pokemonId],
                                    formNameForSlot: _effectiveFormName,
                                    onSelected: (slotIndex) {
                                      setState(() {
                                        _activeSlotIndex = slotIndex;
                                        _statusMoment =
                                            BattleStatusMoment.turnStart;
                                        _message = null;
                                      });
                                      _scheduleSessionSave(data);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            KeyedSubtree(
                              key: _initiativeKey,
                              child: _InitiativeTracker(
                                round: _round,
                                entries: _initiativeEntries,
                                currentTurnIndex: _turnIndex,
                                trainerInitiativeBonus:
                                    _trainerInitiativeBonus(data.profile),
                                onRollTrainer: () =>
                                    _rerollTrainerInitiative(data),
                                onAddEntry: () => _addInitiativeEntry(data),
                                onRemoveEntry: (entry) =>
                                    _removeInitiativeEntry(data, entry),
                                onNextTurn: () => _nextTurn(data),
                              ),
                            ),
                            const SizedBox(height: 12),
                            KeyedSubtree(
                              key: _environmentKey,
                              child: BattleEnvironmentCard(
                                environment: _environment,
                                pokemon: pokemon,
                                slot: activeSlot,
                                level: _levelForSlot(activeSlot),
                                proficiency:
                                    _proficiency(_levelForSlot(activeSlot)),
                                baseSpeed:
                                    TrainerPathPassiveService.effectiveSpeed(
                                  profile: data.profile,
                                  pokemon: pokemon,
                                  slot: activeSlot,
                                ),
                                onEdit: () => _editEnvironment(data),
                                onRollWeather: () =>
                                    _rollEnvironmentWeather(data),
                                onApplyWeatherDamage:
                                    BattleEnvironmentService
                                                .startTurnWeatherDamage(
                                              pokemon: pokemon,
                                              slot: activeSlot,
                                              environment: _environment,
                                            ) ==
                                            null
                                        ? null
                                        : () => _applyEnvironmentWeatherDamage(
                                              data,
                                              activeSlot,
                                            ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            KeyedSubtree(
                              key: _activePokemonKey,
                              child: _ActivePokemonCard(
                                pokemon: pokemon,
                                imagePokemon: basePokemon,
                                slot: activeSlot,
                                formName: effectiveFormName,
                                formLabel: canChangeForm
                                    ? BattleFormChangeService.formLabel(
                                        basePokemon,
                                        effectiveFormName,
                                      )
                                    : null,
                                formNote: canChangeForm
                                    ? BattleFormChangeService.effectNote(
                                        basePokemon,
                                        effectiveFormName,
                                      )
                                    : null,
                                heldItem: heldItem,
                                displayName: _displayName(activeSlot, pokemon),
                                level: _levelForSlot(activeSlot),
                                baseArmorClass: formArmorClass,
                                effectiveArmorClass: effectiveArmorClass,
                                currentHp: _currentHpFor(activeSlot, pokemon),
                                maxHp: _maxHpFor(pokemon, activeSlot),
                                temporaryHp: temporaryHp,
                                temporaryHpRule: temporaryHpRule,
                                temporaryHpEnabled: temporaryHpEnabled,
                                nonVolatileStatus:
                                    _nonVolatileStatusFor(activeSlot),
                                volatileStatuses:
                                    _volatileStatusesFor(activeSlot),
                                message: _message,
                                onMinusFive: () =>
                                    _changeHp(data, activeSlot, -5),
                                onMinusOne: () =>
                                    _changeHp(data, activeSlot, -1),
                                onPlusOne: () =>
                                    _changeHp(data, activeSlot, 1),
                                onPlusFive: () =>
                                    _changeHp(data, activeSlot, 5),
                                onEditHp: () => _editHp(data, activeSlot),
                                onHeal: () => _healFull(data, activeSlot),
                                onStatus: () =>
                                    _openStatusPicker(data, activeSlot),
                                onUseHeldBerry: heldItem?.type == 'berry'
                                    ? () => _useHeldBerry(data, activeSlot)
                                    : null,
                                onOpenBag: () =>
                                    _openQuickBag(data, activeSlot),
                                onToggleTemporaryHp: temporaryHpRule == null
                                    ? null
                                    : (enabled) => _toggleTemporaryHpRule(
                                          data,
                                          activeSlot,
                                          enabled,
                                        ),
                                onChangeForm: canChangeForm
                                    ? () => _openBattleFormPicker(
                                          data,
                                          activeSlot,
                                        )
                                    : null,
                              ),
                            ),
                            if (passiveNotes.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              TrainerPathPassiveCard(
                                trainerPath: data.profile.trainerPath,
                                notes: passiveNotes,
                              ),
                            ],
                            const SizedBox(height: 12),
                            BattleStatusAssistanceCard(
                              key: ValueKey(
                                'player-status-${activeSlot.slotIndex}',
                              ),
                              pokemonName: _displayName(activeSlot, pokemon),
                              nonVolatileStatus:
                                  _nonVolatileStatusFor(activeSlot),
                              volatileStatuses:
                                  _volatileStatusesFor(activeSlot),
                              selectedMoment: _statusMoment,
                              onMomentChanged: (moment) {
                                setState(() => _statusMoment = moment);
                              },
                            ),
                            const SizedBox(height: 12),
                            PokemonBattleAttributesCard(attributes: attributes),
                            const SizedBox(height: 12),
                            KeyedSubtree(
                              key: _movesKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'MOSSE DA COMBATTIMENTO',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (noPpLeft) ...[
                                    _StruggleWarning(
                                      move: moveForActive('Struggle'),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  for (final reference in moveReferences)
                                    _MoveCard(
                                      reference: reference,
                                      move: moveForActive(reference),
                                      remainingPp: _remainingPp(
                                        activeSlot,
                                        reference,
                                        moveForActive(reference),
                                      ),
                                      maxPp:
                                          _maxPpFor(moveForActive(reference)),
                                      stats: moveForActive(reference) == null
                                          ? null
                                          : _moveStats(
                                              moveForActive(reference)!,
                                              pokemon,
                                              activeSlot,
                                              basePokemon,
                                              effectiveFormName,
                                            ),
                                      onUse: () => _changePp(
                                        data,
                                        activeSlot,
                                        reference,
                                        moveForActive(reference),
                                        -1,
                                      ),
                                      onRestore: () => _changePp(
                                        data,
                                        activeSlot,
                                        reference,
                                        moveForActive(reference),
                                        1,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
'''
replace_regex_once(
    battle,
    r"  @override\n  Widget build\(BuildContext context\) \{\n    return Scaffold\(.*?\n  \}\n\}\n\nclass _BattleData",
    new_battle_build + "}\n\nclass _BattleData",
)


# Remove the temporary patch machinery after a successful transformation.
Path("tooling/apply_guided_submenu_tours.py").unlink()
Path(".github/workflows/apply-guided-submenu-tours.yml").unlink()
