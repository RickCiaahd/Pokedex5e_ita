import 'package:flutter/material.dart';

import '../../models/encounter_collection.dart';
import '../../models/generated_encounter.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_form_choice.dart';
import '../../models/pokemon_type_localization.dart';
import '../../models/user_profile.dart';
import '../../repositories/encounter_collection_repository.dart';
import '../../repositories/pokemon_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../services/encounter_generator_service.dart';
import '../../services/pokemon_generator_service.dart';
import '../../services/pokemon_habitat_service.dart';
import '../../widgets/navigation/home_leading_button.dart';
import '../../widgets/pokemon/pokemon_asset_image.dart';
import 'encounter_collection_editor_screen.dart';
import 'encounter_result_screen.dart';

class EncounterGeneratorScreen extends StatefulWidget {
  const EncounterGeneratorScreen({super.key});

  @override
  State<EncounterGeneratorScreen> createState() =>
      _EncounterGeneratorScreenState();
}

class _EncounterGeneratorScreenState extends State<EncounterGeneratorScreen> {
  final PokemonRepository _pokemonRepository = PokemonRepository();
  final ProfileRepository _profileRepository = ProfileRepository();
  final EncounterCollectionRepository _collectionRepository =
      EncounterCollectionRepository();
  final EncounterGeneratorService _encounterService =
      const EncounterGeneratorService();
  final PokemonGeneratorService _pokemonGeneratorService =
      const PokemonGeneratorService();
  final TextEditingController _manualSearchController = TextEditingController();

  List<Pokemon> _catalog = const [];
  List<String> _types = const [];
  List<EncounterCollection> _collections = const [];
  UserProfile? _profile;
  double _maximumSr = 20;

  bool _isLoading = true;
  bool _isGenerating = false;
  String? _error;

  int _trainerCount = 1;
  int _activePokemon = 1;
  int _averageLevel = 5;
  EncounterDifficulty _difficulty = EncounterDifficulty.medium;
  EncounterComposition _composition = EncounterComposition.mixed;
  String _habitat = 'Qualsiasi';
  String _selectedType = '';
  RangeValues _srRange = const RangeValues(0, 20);
  RangeValues _generationRange = const RangeValues(1, 9);
  int _generatedLevel = 0;
  bool _includeForms = true;
  bool _allowLegendary = false;
  int _minEnemies = 1;
  int _maxEnemies = 4;

  String _manualQuery = '';
  final Map<String, int> _manualQuantities = <String, int>{};

  int _collectionCount = 1;
  bool _collectionAllowDuplicates = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _manualSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final profile = await _profileRepository.getActiveProfile();
      final catalog = await _pokemonRepository.getAllPokemon();
      final collections = await _collectionRepository.getCollections(
        profile.id,
      );
      final maximumSr = _pokemonGeneratorService.maximumSr(catalog);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _catalog = catalog;
        _collections = collections;
        _types = _pokemonGeneratorService.availableTypes(catalog);
        _maximumSr = maximumSr;
        _srRange = RangeValues(0, maximumSr);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  EncounterPartyProfile get _party => EncounterPartyProfile(
    trainerCount: _trainerCount,
    activePokemon: _activePokemon,
    averageLevel: _averageLevel,
  );

  EncounterGeneratorFilters get _filters => EncounterGeneratorFilters(
    habitat: _habitat,
    type: _selectedType.isEmpty ? null : _selectedType,
    minSr: _srRange.start,
    maxSr: _srRange.end,
    minGeneration: _generationRange.start.round(),
    maxGeneration: _generationRange.end.round(),
    level: _generatedLevel,
    includeForms: _includeForms,
    allowLegendary: _allowLegendary,
  );

  List<Pokemon> get _filteredCandidates =>
      _encounterService.filterCandidates(_catalog, _filters);

  PokemonGeneratorFilters get _manualPokemonFilters => PokemonGeneratorFilters(
    type: _filters.type,
    minSr: _filters.minSr,
    maxSr: _filters.maxSr,
    minGeneration: _filters.minGeneration,
    maxGeneration: _filters.maxGeneration,
    level: _filters.level,
    includeForms: _filters.includeForms,
    shinyChance: 0.01,
  );

  List<_ManualEncounterCandidate> get _manualCandidates {
    final query = _manualQuery.trim().toLowerCase();
    final candidates = <_ManualEncounterCandidate>[];
    for (final basePokemon in _filteredCandidates) {
      final forms = _pokemonGeneratorService.eligibleFormNames(
        basePokemon,
        _manualPokemonFilters,
      );
      for (final formName in forms) {
        final resolved = basePokemon.resolveVariant(formName: formName);
        final candidate = _ManualEncounterCandidate(
          basePokemon: basePokemon,
          pokemon: resolved,
          formName: formName,
        );
        if (query.isNotEmpty && !candidate.matches(query)) continue;
        candidates.add(candidate);
      }
    }
    return candidates;
  }

  void _setError(String message) {
    setState(() => _error = message);
  }

  Future<void> _openResult(GeneratedEncounter encounter) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            EncounterResultScreen(encounter: encounter, catalog: _catalog),
      ),
    );
  }

  Future<void> _generateAutomatic() async {
    if (_isGenerating) return;
    setState(() {
      _isGenerating = true;
      _error = null;
    });
    try {
      final encounter = _encounterService.generateAutomatic(
        catalog: _catalog,
        party: _party,
        filters: _filters,
        difficulty: _difficulty,
        composition: _composition,
        minEnemies: _minEnemies,
        maxEnemies: _maxEnemies,
      );
      if (encounter == null) {
        _setError(
          'Nessun incontro può essere generato con questi filtri. Amplia ambiente, SR, generazioni o livello.',
        );
        return;
      }
      if (!mounted) return;
      await _openResult(encounter);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _generateManual() async {
    if (_manualQuantities.isEmpty) {
      _setError('Aggiungi almeno un avversario alla composizione manuale.');
      return;
    }
    if (_isGenerating) return;
    setState(() {
      _isGenerating = true;
      _error = null;
    });
    try {
      final candidatesByKey = {
        for (final candidate in _manualCandidates) candidate.key: candidate,
      };
      final selections = <EncounterManualSelection>[
        for (final entry in _manualQuantities.entries)
          if (candidatesByKey[entry.key] case final candidate?)
            EncounterManualSelection(
              pokemonId: candidate.basePokemon.id,
              formName: candidate.formName,
              quantity: entry.value,
            ),
      ];
      final encounter = _encounterService.generateManual(
        catalog: _catalog,
        selections: selections,
        party: _party,
        filters: _filters,
        targetDifficulty: _difficulty,
      );
      if (encounter == null) {
        _setError(
          'Non è stato possibile generare la composizione selezionata.',
        );
        return;
      }
      if (!mounted) return;
      await _openResult(encounter);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _generateCollection(EncounterCollection collection) async {
    if (!collection.isReady) {
      _setError(
        'La raccolta “${collection.name}” non è valida: il totale deve essere 100%.',
      );
      return;
    }
    if (_isGenerating) return;
    setState(() {
      _isGenerating = true;
      _error = null;
    });
    try {
      final encounter = _encounterService.generateFromCollection(
        catalog: _catalog,
        collection: collection,
        count: _collectionCount,
        allowDuplicates: _collectionAllowDuplicates,
        party: _party,
        filters: _filters,
        targetDifficulty: _difficulty,
      );
      if (encounter == null) {
        _setError('Non è stato possibile generare dalla raccolta selezionata.');
        return;
      }
      if (!mounted) return;
      await _openResult(encounter);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _editCollection([EncounterCollection? collection]) async {
    final profile = _profile;
    if (profile == null) return;
    final result = await Navigator.of(context).push<EncounterCollection>(
      MaterialPageRoute(
        builder: (_) => EncounterCollectionEditorScreen(
          profileId: profile.id,
          catalog: _catalog,
          collection: collection,
        ),
      ),
    );
    if (result != null) await _reloadCollections();
  }

  Future<void> _reloadCollections() async {
    final profile = _profile;
    if (profile == null) return;
    final collections = await _collectionRepository.getCollections(profile.id);
    if (!mounted) return;
    setState(() => _collections = collections);
  }

  Future<void> _duplicateCollection(EncounterCollection collection) async {
    final profile = _profile;
    if (profile == null) return;
    final copy = collection.copyWith(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: '${collection.name} (copia)',
      updatedAt: DateTime.now(),
    );
    await _collectionRepository.saveCollection(
      profileId: profile.id,
      collection: copy,
    );
    await _reloadCollections();
  }

  Future<void> _deleteCollection(EncounterCollection collection) async {
    final profile = _profile;
    if (profile == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare la raccolta?'),
        content: Text(
          '“${collection.name}” verrà rimossa definitivamente dal profilo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _collectionRepository.deleteCollection(
      profileId: profile.id,
      collectionId: collection.id,
    );
    await _reloadCollections();
  }

  void _changeManualQuantity(String choiceKey, int delta) {
    setState(() {
      final next = (_manualQuantities[choiceKey] ?? 0) + delta;
      if (next <= 0) {
        _manualQuantities.remove(choiceKey);
      } else {
        _manualQuantities[choiceKey] = next.clamp(1, 12).toInt();
      }
      _error = null;
    });
  }

  Pokemon? _pokemonById(int id) {
    for (final pokemon in _catalog) {
      if (pokemon.id == id) return pokemon;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tabForeground =
        Theme.of(context).appBarTheme.foregroundColor ?? colors.onPrimary;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: const HomeLeadingButton(),
          title: const Text('Generatore incontri'),
          bottom: TabBar(
            isScrollable: true,
            labelColor: tabForeground,
            unselectedLabelColor: tabForeground.withValues(alpha: 0.72),
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(color: tabForeground, width: 3),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
            tabs: const [
              Tab(icon: Icon(Icons.auto_awesome), text: 'AUTOMATICO'),
              Tab(icon: Icon(Icons.tune), text: 'MANUALE'),
              Tab(icon: Icon(Icons.library_books_outlined), text: 'RACCOLTE'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildAutomaticTab(),
                  _buildManualTab(),
                  _buildCollectionsTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildAutomaticTab() {
    final candidateCount = _filteredCandidates.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _IntroCard(
          title: 'Composizione automatica',
          text:
              'Imposta il gruppo, la difficoltà e l’ambiente. L’app costruisce un incontro temporaneo e ne mostra il costo stimato.',
        ),
        const SizedBox(height: 12),
        _buildPartyCard(),
        const SizedBox(height: 12),
        _buildFilterCard(),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'COMPOSIZIONE',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<EncounterDifficulty>(
                  initialValue: _difficulty,
                  decoration: const InputDecoration(
                    labelText: 'Difficoltà obiettivo',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final value in EncounterDifficulty.values)
                      DropdownMenuItem(value: value, child: Text(value.label)),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _difficulty = value);
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<EncounterComposition>(
                  initialValue: _composition,
                  decoration: const InputDecoration(
                    labelText: 'Tipo di incontro',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final value in EncounterComposition.values)
                      DropdownMenuItem(value: value, child: Text(value.label)),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _composition = value);
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _IntDropdown(
                        label: 'Min. avversari',
                        value: _minEnemies,
                        values: List.generate(12, (index) => index + 1),
                        onChanged: (value) => setState(() {
                          _minEnemies = value;
                          if (_maxEnemies < value) _maxEnemies = value;
                        }),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _IntDropdown(
                        label: 'Max. avversari',
                        value: _maxEnemies,
                        values: List.generate(12, (index) => index + 1),
                        onChanged: (value) => setState(() {
                          _maxEnemies = value;
                          if (_minEnemies > value) _minEnemies = value;
                        }),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          _MessageCard(message: _error!, isError: true),
        ],
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: candidateCount == 0 || _isGenerating
              ? null
              : _generateAutomatic,
          icon: _isGenerating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome),
          label: Text(
            _isGenerating
                ? 'GENERAZIONE...'
                : 'GENERA INCONTRO TRA $candidateCount CANDIDATI',
          ),
        ),
      ],
    );
  }

  Widget _buildManualTab() {
    final candidates = _manualCandidates;
    final visible = candidates.take(100).toList(growable: false);
    final visibleKeys = candidates.map((candidate) => candidate.key).toSet();
    final selectedTotal = _manualQuantities.entries
        .where((entry) => visibleKeys.contains(entry.key))
        .fold<int>(0, (sum, entry) => sum + entry.value);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _IntroCard(
          title: 'Composizione manuale',
          text:
              'Scegli specie e quantità. L’app genera ogni esemplare e calcola la difficoltà rispetto al gruppo.',
        ),
        const SizedBox(height: 12),
        _buildPartyCard(),
        const SizedBox(height: 12),
        _buildFilterCard(),
        const SizedBox(height: 12),
        TextField(
          controller: _manualSearchController,
          decoration: const InputDecoration(
            labelText: 'Cerca tra i candidati',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() => _manualQuery = value),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                'POKÉMON COMPATIBILI — ${candidates.length}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            Text(
              '$selectedTotal avversari',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (visible.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Nessun Pokémon corrisponde ai filtri.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          for (final candidate in visible) ...[
            _ManualCandidateCard(
              candidate: candidate,
              quantity: _manualQuantities[candidate.key] ?? 0,
              onDecrease: () => _changeManualQuantity(candidate.key, -1),
              onIncrease: () => _changeManualQuantity(candidate.key, 1),
            ),
            const SizedBox(height: 6),
          ],
        if (candidates.length > visible.length)
          Text(
            'Mostrati i primi ${visible.length} risultati. Usa la ricerca o restringi i filtri.',
            textAlign: TextAlign.center,
          ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          _MessageCard(message: _error!, isError: true),
        ],
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: selectedTotal == 0 || _isGenerating
              ? null
              : _generateManual,
          icon: const Icon(Icons.playlist_add_check),
          label: Text('GENERA $selectedTotal AVVERSARI'),
        ),
      ],
    );
  }

  Widget _buildCollectionsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _IntroCard(
          title: 'Raccolte ponderate',
          text:
              'Crea tabelle riutilizzabili come “Percorso 24”. Ogni estrazione rispetta le percentuali assegnate alle specie.',
        ),
        const SizedBox(height: 12),
        _buildPartyCard(compact: true),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'ESTRAZIONE',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                _IntDropdown(
                  label: 'Numero di apparizioni',
                  value: _collectionCount,
                  values: List.generate(12, (index) => index + 1),
                  onChanged: (value) =>
                      setState(() => _collectionCount = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Consenti duplicati'),
                  subtitle: const Text(
                    'Ogni apparizione effettua una nuova estrazione indipendente.',
                  ),
                  value: _collectionAllowDuplicates,
                  onChanged: (value) =>
                      setState(() => _collectionAllowDuplicates = value),
                ),
                DropdownButtonFormField<int>(
                  initialValue: _generatedLevel,
                  decoration: const InputDecoration(
                    labelText: 'Livello generato',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: 0, child: Text('Automatico')),
                    for (var level = 1; level <= 20; level++)
                      DropdownMenuItem(
                        value: level,
                        child: Text('Livello $level'),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _generatedLevel = value);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: () => _editCollection(),
          icon: const Icon(Icons.add),
          label: const Text('NUOVA RACCOLTA'),
        ),
        const SizedBox(height: 12),
        if (_collections.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Non hai ancora creato raccolte. Aggiungi specie e percentuali fino a raggiungere il 100%.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          for (final collection in _collections) ...[
            _CollectionCard(
              collection: collection,
              pokemonById: _pokemonById,
              isGenerating: _isGenerating,
              onGenerate: () => _generateCollection(collection),
              onEdit: () => _editCollection(collection),
              onDuplicate: () => _duplicateCollection(collection),
              onDelete: () => _deleteCollection(collection),
            ),
            const SizedBox(height: 10),
          ],
        if (_error != null) _MessageCard(message: _error!, isError: true),
      ],
    );
  }

  Widget _buildPartyCard({bool compact = false}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'GRUPPO DI GIOCO',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _IntDropdown(
                    label: 'Allenatori',
                    value: _trainerCount,
                    values: List.generate(8, (index) => index + 1),
                    onChanged: (value) => setState(() => _trainerCount = value),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _IntDropdown(
                    label: 'Pokémon attivi',
                    value: _activePokemon,
                    values: List.generate(12, (index) => index + 1),
                    onChanged: (value) =>
                        setState(() => _activePokemon = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _IntDropdown(
              label: 'Livello medio dei Pokémon alleati',
              value: _averageLevel,
              values: List.generate(20, (index) => index + 1),
              onChanged: (value) => setState(() => _averageLevel = value),
            ),
            if (!compact) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<EncounterDifficulty>(
                initialValue: _difficulty,
                decoration: const InputDecoration(
                  labelText: 'Difficoltà obiettivo',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final value in EncounterDifficulty.values)
                    DropdownMenuItem(value: value, child: Text(value.label)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _difficulty = value);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterCard() {
    return Card(
      child: ExpansionTile(
        initiallyExpanded: true,
        title: const Text(
          'FILTRI AVANZATI',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _habitat,
            decoration: const InputDecoration(
              labelText: 'Ambiente',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final habitat in PokemonHabitatService.habitats)
                DropdownMenuItem(value: habitat, child: Text(habitat)),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _habitat = value);
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Tipo',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: '', child: Text('Tutti i tipi')),
              for (final type in _types)
                DropdownMenuItem(
                  value: type,
                  child: Text(PokemonTypeLocalization.italianLabel(type)),
                ),
            ],
            onChanged: (value) => setState(() => _selectedType = value ?? ''),
          ),
          const SizedBox(height: 12),
          Text(
            'SR ${_format(_srRange.start)} – ${_format(_srRange.end)}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          RangeSlider(
            values: _srRange,
            min: 0,
            max: _maximumSr,
            divisions: (_maximumSr * 2).round().clamp(1, 200).toInt(),
            labels: RangeLabels(_format(_srRange.start), _format(_srRange.end)),
            onChanged: (value) => setState(() => _srRange = value),
          ),
          Text(
            'Generazioni ${_generationRange.start.round()} – ${_generationRange.end.round()}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          RangeSlider(
            values: _generationRange,
            min: 1,
            max: 9,
            divisions: 8,
            labels: RangeLabels(
              '${_generationRange.start.round()}',
              '${_generationRange.end.round()}',
            ),
            onChanged: (value) => setState(() => _generationRange = value),
          ),
          DropdownButtonFormField<int>(
            initialValue: _generatedLevel,
            decoration: const InputDecoration(
              labelText: 'Livello degli avversari',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(
                value: 0,
                child: Text('Automatico: minimo selvatico'),
              ),
              for (var level = 1; level <= 20; level++)
                DropdownMenuItem(value: level, child: Text('Livello $level')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _generatedLevel = value);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Forme permanenti'),
            value: _includeForms,
            onChanged: (value) => setState(() => _includeForms = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Leggendari e misteriosi'),
            subtitle: const Text('Disattivati per impostazione predefinita.'),
            value: _allowLegendary,
            onChanged: (value) => setState(() => _allowLegendary = value),
          ),
        ],
      ),
    );
  }

  String _format(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(text, style: TextStyle(color: colors.onPrimaryContainer)),
          ],
        ),
      ),
    );
  }
}

class _IntDropdown extends StatelessWidget {
  const _IntDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final int value;
  final List<int> values;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final item in values)
          DropdownMenuItem(value: item, child: Text('$item')),
      ],
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }
}

class _ManualEncounterCandidate {
  const _ManualEncounterCandidate({
    required this.basePokemon,
    required this.pokemon,
    required this.formName,
  });

  final Pokemon basePokemon;
  final Pokemon pokemon;
  final String? formName;

  String get key => pokemonFormChoiceKey(
    pokemonId: basePokemon.id,
    speciesName: basePokemon.name,
    formName: formName,
  );

  String get displayName => pokemonFormDisplayName(basePokemon.name, formName);

  bool matches(String query) {
    return displayName.toLowerCase().contains(query) ||
        basePokemon.id.toString().contains(query) ||
        pokemon.types.any(
          (type) =>
              type.toLowerCase().contains(query) ||
              PokemonTypeLocalization.italianLabel(
                type,
              ).toLowerCase().contains(query),
        );
  }
}

class _ManualCandidateCard extends StatelessWidget {
  const _ManualCandidateCard({
    required this.candidate,
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final _ManualEncounterCandidate candidate;
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    final pokemon = candidate.pokemon;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          children: [
            PokemonAssetImage(
              pokemon: candidate.basePokemon,
              formName: candidate.formName,
              size: 54,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    '${pokemonFormSubtitle(candidate.formName)} · '
                    'SR ${pokemon.sr} · min. Lv ${pokemon.minLevelFound}',
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: quantity == 0 ? null : onDecrease,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text(
              '$quantity',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            IconButton(
              onPressed: quantity >= 12 ? null : onIncrease,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({
    required this.collection,
    required this.pokemonById,
    required this.isGenerating,
    required this.onGenerate,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  final EncounterCollection collection;
  final Pokemon? Function(int) pokemonById;
  final bool isGenerating;
  final VoidCallback onGenerate;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    collection.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'duplicate':
                        onDuplicate();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Modifica')),
                    PopupMenuItem(value: 'duplicate', child: Text('Duplica')),
                    PopupMenuItem(value: 'delete', child: Text('Elimina')),
                  ],
                ),
              ],
            ),
            if (collection.notes.isNotEmpty) Text(collection.notes),
            const SizedBox(height: 8),
            for (final entry in collection.entries) ...[
              Builder(
                builder: (context) {
                  final pokemon = pokemonById(entry.pokemonId);
                  return Row(
                    children: [
                      if (pokemon != null)
                        PokemonAssetImage(
                          pokemon: pokemon,
                          formName: entry.formName,
                          size: 38,
                        ),
                      if (pokemon != null) const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pokemon == null
                              ? '#${entry.pokemonId}'
                              : pokemonFormDisplayName(
                                  pokemon.name,
                                  entry.formName,
                                ),
                        ),
                      ),
                      Text(
                        '${entry.weight}%',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 3),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Totale ${collection.totalWeight}%',
                  style: TextStyle(
                    color: collection.isReady
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: !collection.isReady || isGenerating
                      ? null
                      : onGenerate,
                  icon: const Icon(Icons.casino_outlined),
                  label: const Text('GENERA'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: isError ? colors.errorContainer : colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          style: TextStyle(
            color: isError
                ? colors.onErrorContainer
                : colors.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}
