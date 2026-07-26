import 'package:flutter/material.dart';

import '../../localization/ui_text.dart';

import '../../models/generated_pokemon.dart';
import '../../models/move_data.dart';
import '../../models/pc_pokemon.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_type_localization.dart';
import '../../models/pokemon_nature.dart';
import '../../models/team_slot.dart';
import '../../models/trainer_progression.dart';
import '../../models/user_profile.dart';
import '../../repositories/move_repository.dart';
import '../../repositories/pokemon_pc_repository.dart';
import '../../repositories/pokemon_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/team_repository.dart';
import '../../services/pokemon_generator_service.dart';
import '../../widgets/navigation/home_leading_button.dart';
import '../../widgets/pokemon/pokemon_asset_image.dart';
import '../../widgets/tools/generated_pokemon_batch_card.dart';
import '../../widgets/tools/pokemon_generator_candidate_selector.dart';
import '../pokemon/pokemon_detail_screen.dart';

class PokemonGeneratorScreen extends StatefulWidget {
  const PokemonGeneratorScreen({super.key});

  @override
  State<PokemonGeneratorScreen> createState() => _PokemonGeneratorScreenState();
}

class _PokemonGeneratorScreenState extends State<PokemonGeneratorScreen> {
  final PokemonRepository _pokemonRepository = PokemonRepository();
  final ProfileRepository _profileRepository = ProfileRepository();
  final TeamRepository _teamRepository = TeamRepository();
  final PokemonPcRepository _pcRepository = PokemonPcRepository();
  final MoveRepository _moveRepository = MoveRepository();
  final PokemonGeneratorService _generatorService =
      const PokemonGeneratorService();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _singleResultKey = GlobalKey();
  final GlobalKey _batchResultKey = GlobalKey();

  List<Pokemon> _pokemon = const [];
  List<TeamSlot> _team = const [];
  List<String> _types = const [];
  UserProfile? _profile;
  GeneratedPokemon? _generated;
  List<GeneratedPokemon> _generatedBatch = const [];
  Map<String, MoveData?> _generatedMoves = const {};
  final Set<int> _selectedPokemonIds = <int>{};

  bool _isLoading = true;
  bool _isGenerating = false;
  bool _isSaving = false;
  String? _statusMessage;
  String? _errorMessage;

  String _query = '';
  String _selectedType = '';
  RangeValues _srRange = const RangeValues(0, 20);
  RangeValues _generationRange = const RangeValues(1, 9);
  double _maximumSr = 20;
  int _level = 0;
  bool _includeForms = true;
  double _shinyChance = 0.01;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _profileRepository.getActiveProfile();
      final pokemon = await _pokemonRepository.getAllPokemon();
      final team = await _teamRepository.getTeam(profile.id);
      final maximumSr = _generatorService.maximumSr(pokemon);

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _pokemon = pokemon;
        _team = team..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
        _types = _generatorService.availableTypes(pokemon);
        _maximumSr = maximumSr;
        _srRange = RangeValues(0, maximumSr);
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

  PokemonGeneratorFilters get _filters => PokemonGeneratorFilters(
    query: _query,
    type: _selectedType.isEmpty ? null : _selectedType,
    minSr: _srRange.start,
    maxSr: _srRange.end,
    minGeneration: _generationRange.start.round(),
    maxGeneration: _generationRange.end.round(),
    level: _level,
    includeForms: _includeForms,
    shinyChance: _shinyChance,
  );

  List<Pokemon> get _candidates =>
      _generatorService.filterPokemon(_pokemon, _filters);

  Future<void> _generate() async {
    if (_isGenerating || _pokemon.isEmpty) return;
    setState(() {
      _isGenerating = true;
      _statusMessage = null;
      _errorMessage = null;
    });

    try {
      final generated = _generatorService.generate(
        pokemon: _pokemon,
        filters: _filters,
      );
      if (generated == null) {
        if (!mounted) return;
        setState(() {
          _generated = null;
          _generatedBatch = const [];
          _generatedMoves = const {};
          _errorMessage = context.uiText(
            'Nessun Pokémon corrisponde ai filtri selezionati. Prova ad ampliare SR, generazioni o livello.',
            'No Pokémon match the selected filters. Try widening the SR, generation or level ranges.',
          );
        });
        return;
      }

      final moves = await _moveRepository.getMovesByPokemon({
        generated.basePokemon.id: generated.selectedMoves,
      });
      if (!mounted) return;
      setState(() {
        _generated = generated;
        _generatedBatch = const [];
        _generatedMoves = moves;
        _statusMessage = context.uiText(
          '${generated.basePokemon.name} generato. Anteprima pronta qui sotto.',
          '${generated.basePokemon.name} generated. The preview is ready below.',
        );
      });
      _scrollToResult(_singleResultKey);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _updateFilters(VoidCallback update) {
    setState(() {
      update();
      final visibleIds = _generatorService
          .filterPokemon(_pokemon, _filters)
          .map((pokemon) => pokemon.id)
          .toSet();
      _selectedPokemonIds.removeWhere((id) => !visibleIds.contains(id));
      _generated = null;
      _generatedBatch = const [];
      _generatedMoves = const {};
      _statusMessage = null;
      _errorMessage = null;
    });
  }

  void _toggleCandidate(int pokemonId) {
    setState(() {
      if (!_selectedPokemonIds.add(pokemonId)) {
        _selectedPokemonIds.remove(pokemonId);
      }
    });
  }

  void _selectAllCandidates() {
    setState(() {
      _selectedPokemonIds.addAll(_candidates.map((pokemon) => pokemon.id));
    });
  }

  void _clearCandidateSelection() {
    setState(_selectedPokemonIds.clear);
  }

  Future<bool> _confirmLargeSelection(int count) async {
    if (count <= 25) return true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          context.uiText(
            'Generare $count Pokémon?',
            'Generate $count Pokémon?',
          ),
        ),
        content: Text(
          context.uiText(
            'La generazione e l’anteprima di un gruppo molto grande possono richiedere qualche secondo. Nessun Pokémon verrà ancora salvato.',
            'Generating and previewing a very large group may take a few seconds. No Pokémon will be saved yet.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.uiText('Annulla', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.uiText('Continua', 'Continue')),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<Map<String, MoveData?>> _loadGeneratedMoves(
    Iterable<GeneratedPokemon> generated,
  ) {
    final referencesByPokemon = <int, Set<String>>{};
    for (final pokemon in generated) {
      referencesByPokemon
          .putIfAbsent(pokemon.basePokemon.id, () => <String>{})
          .addAll(pokemon.selectedMoves);
    }
    return _moveRepository.getMovesByPokemon(referencesByPokemon);
  }

  void _scrollToResult(GlobalKey resultKey) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final resultContext = resultKey.currentContext;
      if (resultContext == null) return;
      Scrollable.ensureVisible(
        resultContext,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        alignment: 0.04,
      );
    });
  }

  Future<void> _generateSelected() async {
    if (_isGenerating) return;
    final selected = _candidates
        .where((pokemon) => _selectedPokemonIds.contains(pokemon.id))
        .toList(growable: false);
    if (selected.isEmpty) {
      setState(() {
        _errorMessage = context.uiText(
          'Seleziona almeno un Pokémon dall’elenco compatibile.',
          'Select at least one Pokémon from the compatible list.',
        );
      });
      return;
    }
    if (!await _confirmLargeSelection(selected.length) || !mounted) return;

    setState(() {
      _isGenerating = true;
      _statusMessage = null;
      _errorMessage = null;
    });

    try {
      final generated = _generatorService.generateSelected(
        pokemon: selected,
        filters: _filters,
      );
      final moves = await _loadGeneratedMoves(generated);
      if (!mounted) return;
      setState(() {
        _generated = null;
        _generatedBatch = generated;
        _generatedMoves = moves;
        _statusMessage = generated.length == selected.length
            ? context.uiText(
                '${generated.length} Pokémon generati. Anteprima pronta qui sotto.',
                '${generated.length} Pokémon generated. The preview is ready below.',
              )
            : context.uiText(
                'Generati ${generated.length} Pokémon su ${selected.length} selezionati.',
                'Generated ${generated.length} of ${selected.length} selected Pokémon.',
              );
      });
      _scrollToResult(_batchResultKey);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _regenerateBatchItem(int index) async {
    if (_isGenerating || index < 0 || index >= _generatedBatch.length) return;
    final current = _generatedBatch[index];
    setState(() {
      _isGenerating = true;
      _statusMessage = null;
      _errorMessage = null;
    });

    try {
      final regenerated = _generatorService.generateForPokemon(
        pokemon: current.basePokemon,
        filters: _filters,
      );
      if (regenerated == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = context.uiText(
            '${current.basePokemon.name} non corrisponde più ai filtri attuali.',
            '${current.basePokemon.name} no longer matches the current filters.',
          );
        });
        return;
      }
      final updated = [..._generatedBatch]..[index] = regenerated;
      final moves = await _loadGeneratedMoves(updated);
      if (!mounted) return;
      setState(() {
        _generatedBatch = updated;
        _generatedMoves = moves;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _removeBatchItem(int index) {
    if (index < 0 || index >= _generatedBatch.length) return;
    setState(() {
      _generatedBatch = [
        for (var itemIndex = 0; itemIndex < _generatedBatch.length; itemIndex++)
          if (itemIndex != index) _generatedBatch[itemIndex],
      ];
    });
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _selectedType = '';
      _srRange = RangeValues(0, _maximumSr);
      _generationRange = const RangeValues(1, 9);
      _level = 0;
      _includeForms = true;
      _shinyChance = 0.01;
      _selectedPokemonIds.clear();
      _generated = null;
      _generatedBatch = const [];
      _generatedMoves = const {};
      _statusMessage = null;
      _errorMessage = null;
    });
  }

  Future<void> _openGeneratedDetails() async {
    final generated = _generated;
    if (generated == null) return;
    await _openGeneratedDetailsFor(generated);
  }

  Future<void> _openGeneratedDetailsFor(GeneratedPokemon generated) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PokemonDetailScreen(
          pokemon: generated.basePokemon,
          teamSlot: generated.toTeamSlot(slotIndex: 0),
          allPokemon: _pokemon,
          team: const [],
        ),
      ),
    );
  }

  Future<void> _addGeneratedToCollection() async {
    final generated = _generated;
    final profile = _profile;
    if (generated == null || profile == null || _isSaving) return;

    setState(() {
      _isSaving = true;
      _statusMessage = null;
      _errorMessage = null;
    });

    try {
      final moveReferences = [
        for (final reference in generated.selectedMoves)
          _generatedMoves[MoveRepository.contextualKey(
                    generated.basePokemon.id,
                    reference,
                  )]
                  ?.id ??
              reference,
      ];
      final freeSlot = _firstFreeUnlockedSlot(profile);
      String destination;

      if (freeSlot != null) {
        await _teamRepository.updateSlot(
          profileId: profile.id,
          updatedSlot: TeamSlot(
            slotIndex: freeSlot.slotIndex,
            pokemonId: generated.basePokemon.id,
            experience: generated.experience,
            currentHp: generated.maxHp,
            selectedMoves: moveReferences,
            isShiny: generated.isShiny,
            gender: generated.gender,
            formName: generated.formName,
            nature: generated.nature,
            abilities: generated.ability == null
                ? const []
                : [generated.ability!],
          ),
        );
        destination = uiTextForLanguage(
          'aggiunto allo slot squadra ${freeSlot.slotIndex + 1}',
          'added to team slot ${freeSlot.slotIndex + 1}',
        );
      } else {
        await _pcRepository.depositPokemon(
          profileId: profile.id,
          pokemonId: generated.basePokemon.id,
          experience: generated.experience,
          currentHp: generated.maxHp,
          selectedMoves: moveReferences,
          isShiny: generated.isShiny,
          gender: generated.gender,
          formName: generated.formName,
          nature: generated.nature,
          abilities: generated.ability == null
              ? const []
              : [generated.ability!],
          notes: uiTextForLanguage(
            'Generato dagli Strumenti al livello ${generated.level}.',
            'Generated by Tools at level ${generated.level}.',
          ),
        );
        destination = uiTextForLanguage('inviato al PC', 'sent to the PC');
      }

      final team = await _teamRepository.getTeam(profile.id);
      if (!mounted) return;
      setState(() {
        _team = team..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
        _statusMessage = '${generated.basePokemon.name} $destination.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  List<String> _resolvedMoveReferences(GeneratedPokemon generated) {
    return [
      for (final reference in generated.selectedMoves)
        _generatedMoves[MoveRepository.contextualKey(
                  generated.basePokemon.id,
                  reference,
                )]
                ?.id ??
            reference,
    ];
  }

  Future<void> _addGeneratedBatchToCollection() async {
    final profile = _profile;
    final generatedBatch = [..._generatedBatch];
    if (profile == null || generatedBatch.isEmpty || _isSaving) return;

    setState(() {
      _isSaving = true;
      _statusMessage = null;
      _errorMessage = null;
    });

    try {
      final currentTeam = await _teamRepository.getTeam(profile.id)
        ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
      final unlocked = TrainerProgression.pokeslotsForLevel(
        profile.trainerLevel,
      );
      final freeSlotIndexes = currentTeam
          .where((slot) => slot.slotIndex < unlocked && slot.pokemonId == null)
          .map((slot) => slot.slotIndex)
          .toList();
      final updatedTeam = [...currentTeam];
      final pcAdditions = <PcPokemon>[];
      var teamCount = 0;
      final idSeed = DateTime.now().microsecondsSinceEpoch;

      for (var index = 0; index < generatedBatch.length; index++) {
        final generated = generatedBatch[index];
        final moves = _resolvedMoveReferences(generated);
        if (freeSlotIndexes.isNotEmpty) {
          final slotIndex = freeSlotIndexes.removeAt(0);
          final replacement = TeamSlot(
            slotIndex: slotIndex,
            pokemonId: generated.basePokemon.id,
            experience: generated.experience,
            currentHp: generated.maxHp,
            selectedMoves: moves,
            isShiny: generated.isShiny,
            gender: generated.gender,
            formName: generated.formName,
            nature: generated.nature,
            abilities: generated.ability == null
                ? const []
                : [generated.ability!],
          );
          final teamIndex = updatedTeam.indexWhere(
            (slot) => slot.slotIndex == slotIndex,
          );
          if (teamIndex == -1) {
            updatedTeam.add(replacement);
          } else {
            updatedTeam[teamIndex] = replacement;
          }
          teamCount += 1;
        } else {
          pcAdditions.add(
            PcPokemon(
              id: '$idSeed-$index',
              pokemonId: generated.basePokemon.id,
              experience: generated.experience,
              currentHp: generated.maxHp,
              selectedMoves: moves,
              isShiny: generated.isShiny,
              gender: generated.gender,
              formName: generated.formName,
              nature: generated.nature,
              abilities: generated.ability == null
                  ? const []
                  : [generated.ability!],
              notes: uiTextForLanguage(
                'Generato dagli Strumenti al livello ${generated.level}.',
                'Generated by Tools at level ${generated.level}.',
              ),
            ),
          );
        }
      }

      if (teamCount > 0) {
        updatedTeam.sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
        await _teamRepository.saveTeam(profile.id, updatedTeam);
      }
      if (pcAdditions.isNotEmpty) {
        final existingPc = await _pcRepository.getPokemon(profile.id);
        await _pcRepository.savePokemon(profile.id, [
          ...pcAdditions,
          ...existingPc,
        ]);
      }

      final refreshedTeam = await _teamRepository.getTeam(profile.id);
      if (!mounted) return;
      setState(() {
        _team = refreshedTeam
          ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
        _generatedBatch = const [];
        _selectedPokemonIds.clear();
        _statusMessage = uiTextForLanguage(
          '${generatedBatch.length} Pokémon aggiunti: $teamCount in squadra, ${pcAdditions.length} nel PC.',
          '${generatedBatch.length} Pokémon added: $teamCount to the team, ${pcAdditions.length} to the PC.',
        );
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  TeamSlot? _firstFreeUnlockedSlot(UserProfile profile) {
    final unlocked = TrainerProgression.pokeslotsForLevel(profile.trainerLevel);
    final ordered = [..._team]
      ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
    for (final slot in ordered) {
      if (slot.slotIndex < unlocked && slot.pokemonId == null) return slot;
    }
    return null;
  }

  String _formatSr(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  String _shinyLabel(double chance) {
    if (chance <= 0) return 'Mai';
    if (chance >= 1) return 'Sempre';
    return '${(chance * 100).round()}%';
  }

  @override
  Widget build(BuildContext context) {
    final candidates = _isLoading ? const <Pokemon>[] : _candidates;

    return Scaffold(
      appBar: AppBar(
        leading: const HomeLeadingButton(),
        title: Text(context.uiText('Generatore Pokémon', 'Pokémon Generator')),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            32.0 + MediaQuery.viewPaddingOf(context).bottom,
          ),
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _GeneratorIntro(candidateCount: candidates.length),
              const SizedBox(height: 12),
              _GeneratorFiltersCard(
                searchController: _searchController,
                selectedType: _selectedType,
                types: _types,
                srRange: _srRange,
                maximumSr: _maximumSr,
                generationRange: _generationRange,
                level: _level,
                includeForms: _includeForms,
                shinyChance: _shinyChance,
                formatSr: _formatSr,
                shinyLabel: _shinyLabel,
                onQueryChanged: (value) => _updateFilters(() => _query = value),
                onTypeChanged: (value) =>
                    _updateFilters(() => _selectedType = value ?? ''),
                onSrChanged: (value) => _updateFilters(() => _srRange = value),
                onGenerationChanged: (value) =>
                    _updateFilters(() => _generationRange = value),
                onLevelChanged: (value) => _updateFilters(() => _level = value),
                onIncludeFormsChanged: (value) =>
                    _updateFilters(() => _includeForms = value),
                onShinyChanceChanged: (value) =>
                    _updateFilters(() => _shinyChance = value),
                onReset: _resetFilters,
              ),
              const SizedBox(height: 12),
              PokemonGeneratorCandidateSelector(
                candidates: candidates,
                selectedIds: _selectedPokemonIds,
                filters: _filters,
                generatorService: _generatorService,
                onToggle: _toggleCandidate,
                onSelectAll: _selectAllCandidates,
                onClearSelection: _clearCandidateSelection,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                _InlineMessage(message: _errorMessage!, isError: true),
              ],
              if (_statusMessage != null) ...[
                const SizedBox(height: 12),
                _InlineMessage(message: _statusMessage!),
              ],
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final selectedCount = candidates
                      .where(
                        (pokemon) => _selectedPokemonIds.contains(pokemon.id),
                      )
                      .length;
                  final randomButton = FilledButton.icon(
                    onPressed: candidates.isEmpty || _isGenerating
                        ? null
                        : _generate,
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.casino_outlined),
                    label: Text(
                      _isGenerating
                          ? context.uiText('GENERAZIONE...', 'GENERATING...')
                          : context.uiText(
                              'GENERA 1 CASUALE TRA ${candidates.length}',
                              'GENERATE 1 RANDOM FROM ${candidates.length}',
                            ),
                    ),
                  );
                  final selectedButton = FilledButton.tonalIcon(
                    onPressed: selectedCount == 0 || _isGenerating
                        ? null
                        : _generateSelected,
                    icon: const Icon(Icons.playlist_add_check),
                    label: Text(
                      selectedCount == 0
                          ? context.uiText(
                              'GENERA I SELEZIONATI',
                              'GENERATE SELECTED',
                            )
                          : context.uiText(
                              'GENERA $selectedCount SELEZIONATI',
                              'GENERATE $selectedCount SELECTED',
                            ),
                    ),
                  );
                  if (constraints.maxWidth < 650) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        randomButton,
                        const SizedBox(height: 8),
                        selectedButton,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: randomButton),
                      const SizedBox(width: 10),
                      Expanded(child: selectedButton),
                    ],
                  );
                },
              ),
              if (_generated != null) ...[
                const SizedBox(height: 18),
                KeyedSubtree(
                  key: _singleResultKey,
                  child: _GeneratedPokemonCard(
                    generated: _generated!,
                    moves: _generatedMoves,
                    isSaving: _isSaving,
                    onGenerateAgain: _generate,
                    onOpenDetails: _openGeneratedDetails,
                    onAddToCollection: _addGeneratedToCollection,
                  ),
                ),
              ],
              if (_generatedBatch.isNotEmpty) ...[
                const SizedBox(height: 18),
                KeyedSubtree(
                  key: _batchResultKey,
                  child: GeneratedPokemonBatchCard(
                    generated: _generatedBatch,
                    moves: _generatedMoves,
                    isSaving: _isSaving,
                    onRegenerate: _regenerateBatchItem,
                    onOpenDetails: (index) =>
                        _openGeneratedDetailsFor(_generatedBatch[index]),
                    onRemove: _removeBatchItem,
                    onAddAll: _addGeneratedBatchToCollection,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _GeneratorIntro extends StatelessWidget {
  const _GeneratorIntro({required this.candidateCount});

  final int candidateCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.catching_pokemon,
              size: 38,
              color: colors.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.uiText(
                      'Crea un Pokémon pronto da usare',
                      'Create a ready-to-use Pokémon',
                    ),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.uiText(
                      '$candidateCount candidati con i filtri attuali. Il risultato può restare temporaneo oppure essere aggiunto alla collezione.',
                      '$candidateCount candidates match the current filters. The result can remain temporary or be added to the collection.',
                    ),
                    style: TextStyle(color: colors.onPrimaryContainer),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GeneratorFiltersCard extends StatelessWidget {
  const _GeneratorFiltersCard({
    required this.searchController,
    required this.selectedType,
    required this.types,
    required this.srRange,
    required this.maximumSr,
    required this.generationRange,
    required this.level,
    required this.includeForms,
    required this.shinyChance,
    required this.formatSr,
    required this.shinyLabel,
    required this.onQueryChanged,
    required this.onTypeChanged,
    required this.onSrChanged,
    required this.onGenerationChanged,
    required this.onLevelChanged,
    required this.onIncludeFormsChanged,
    required this.onShinyChanceChanged,
    required this.onReset,
  });

  final TextEditingController searchController;
  final String selectedType;
  final List<String> types;
  final RangeValues srRange;
  final double maximumSr;
  final RangeValues generationRange;
  final int level;
  final bool includeForms;
  final double shinyChance;
  final String Function(double) formatSr;
  final String Function(double) shinyLabel;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<RangeValues> onSrChanged;
  final ValueChanged<RangeValues> onGenerationChanged;
  final ValueChanged<int> onLevelChanged;
  final ValueChanged<bool> onIncludeFormsChanged;
  final ValueChanged<double> onShinyChanceChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.uiText('FILTRI', 'FILTERS'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.restart_alt),
                  label: Text(context.uiText('Azzera', 'Reset')),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 680;
                final search = TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: context.uiText(
                      'Nome, numero o tipo',
                      'Name, number or type',
                    ),
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: onQueryChanged,
                );
                final type = DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: InputDecoration(
                    labelText: context.uiText('Tipo', 'Type'),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: '',
                      child: Text(context.uiText('Tutti i tipi', 'All types')),
                    ),
                    for (final type in types)
                      DropdownMenuItem(
                        value: type,
                        child: Text(
                          context.uiText(
                            PokemonTypeLocalization.italianLabel(type),
                            PokemonTypeLocalization.englishValue(type),
                          ),
                        ),
                      ),
                  ],
                  onChanged: onTypeChanged,
                );

                if (!wide) {
                  return Column(
                    children: [search, const SizedBox(height: 10), type],
                  );
                }
                return Row(
                  children: [
                    Expanded(flex: 2, child: search),
                    const SizedBox(width: 10),
                    Expanded(child: type),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            Text(
              'SR ${formatSr(srRange.start)} – ${formatSr(srRange.end)}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            RangeSlider(
              values: srRange,
              min: 0,
              max: maximumSr,
              divisions: (maximumSr * 2).round().clamp(1, 200).toInt(),
              labels: RangeLabels(
                formatSr(srRange.start),
                formatSr(srRange.end),
              ),
              onChanged: onSrChanged,
            ),
            Text(
              context.uiText(
                'Generazioni ${generationRange.start.round()} – ${generationRange.end.round()}',
                'Generations ${generationRange.start.round()} – ${generationRange.end.round()}',
              ),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            RangeSlider(
              values: generationRange,
              min: 1,
              max: 9,
              divisions: 8,
              labels: RangeLabels(
                generationRange.start.round().toString(),
                generationRange.end.round().toString(),
              ),
              onChanged: onGenerationChanged,
            ),
            Text(
              level == 0
                  ? context.uiText(
                      'Livello: automatico (minimo selvatico)',
                      'Level: automatic (minimum wild level)',
                    )
                  : context.uiText('Livello: $level', 'Level: $level'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Slider(
              value: level.toDouble(),
              min: 0,
              max: 20,
              divisions: 20,
              label: level == 0 ? 'Auto' : '$level',
              onChanged: (value) => onLevelChanged(value.round()),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final children = [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      context.uiText('Forme permanenti', 'Permanent forms'),
                    ),
                    subtitle: Text(
                      context.uiText(
                        'Esclude Mega, Gigamax e altre forme temporanee.',
                        'Excludes Mega, Gigantamax and other temporary forms.',
                      ),
                    ),
                    value: includeForms,
                    onChanged: onIncludeFormsChanged,
                  ),
                  DropdownButtonFormField<double>(
                    initialValue: shinyChance,
                    decoration: InputDecoration(
                      labelText: context.uiText(
                        'Probabilità shiny',
                        'Shiny chance',
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      for (final chance in const [0.0, 0.01, 0.05, 0.10, 1.0])
                        DropdownMenuItem(
                          value: chance,
                          child: Text(shinyLabel(chance)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) onShinyChanceChanged(value);
                    },
                  ),
                ];
                if (constraints.maxWidth < 680) {
                  return Column(
                    children: [
                      children.first,
                      const SizedBox(height: 10),
                      children.last,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: children.first),
                    const SizedBox(width: 12),
                    SizedBox(width: 220, child: children.last),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GeneratedPokemonCard extends StatelessWidget {
  const _GeneratedPokemonCard({
    required this.generated,
    required this.moves,
    required this.isSaving,
    required this.onGenerateAgain,
    required this.onOpenDetails,
    required this.onAddToCollection,
  });

  final GeneratedPokemon generated;
  final Map<String, MoveData?> moves;
  final bool isSaving;
  final VoidCallback onGenerateAgain;
  final VoidCallback onOpenDetails;
  final VoidCallback onAddToCollection;

  @override
  Widget build(BuildContext context) {
    final pokemon = generated.pokemon;
    final nature = PokemonNature.forName(generated.nature);
    final armorClass = pokemon.armorClass + (nature['AC'] ?? 0);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final artwork = DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: PokemonAssetImage(
                      pokemon: generated.basePokemon,
                      formName: generated.formName,
                      gender: generated.gender,
                      isShiny: generated.isShiny,
                      useLargeArtwork: true,
                      size: 170,
                    ),
                  ),
                );
                final summary = _GeneratedSummary(
                  generated: generated,
                  armorClass: armorClass,
                );
                if (constraints.maxWidth < 720) {
                  return Column(
                    children: [
                      Center(child: artwork),
                      const SizedBox(height: 14),
                      summary,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    artwork,
                    const SizedBox(width: 18),
                    Expanded(child: summary),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            Text(
              context.uiText('MOSSE GENERATE', 'GENERATED MOVES'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            if (generated.selectedMoves.isEmpty)
              Text(
                context.uiText(
                  'Nessuna mossa naturale disponibile a questo livello.',
                  'No natural moves are available at this level.',
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final reference in generated.selectedMoves)
                    _GeneratedMoveChip(
                      reference: reference,
                      move:
                          moves[MoveRepository.contextualKey(
                            generated.basePokemon.id,
                            reference,
                          )],
                    ),
                ],
              ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: onGenerateAgain,
                  icon: const Icon(Icons.casino_outlined),
                  label: Text(
                    context.uiText('GENERA ANCORA', 'GENERATE AGAIN'),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onOpenDetails,
                  icon: const Icon(Icons.description_outlined),
                  label: Text(context.uiText('SCHEDA COMPLETA', 'FULL SHEET')),
                ),
                FilledButton.icon(
                  onPressed: isSaving ? null : onAddToCollection,
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_circle_outline),
                  label: Text(
                    isSaving
                        ? context.uiText('SALVATAGGIO...', 'SAVING...')
                        : context.uiText(
                            'AGGIUNGI A SQUADRA / PC',
                            'ADD TO TEAM / PC',
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              context.uiText(
                'Aggiungendolo alla collezione verrà registrato come catturato nel Pokédex.',
                'Adding it to the collection will register it as caught in the Pokédex.',
              ),
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _GeneratedSummary extends StatelessWidget {
  const _GeneratedSummary({required this.generated, required this.armorClass});

  final GeneratedPokemon generated;
  final int armorClass;

  @override
  Widget build(BuildContext context) {
    final pokemon = generated.pokemon;
    final number = '#${generated.basePokemon.id.toString().padLeft(3, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                generated.basePokemon.name.toUpperCase(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (generated.isShiny)
              const Chip(
                avatar: Icon(Icons.auto_awesome, size: 18),
                label: Text('SHINY'),
              ),
          ],
        ),
        Text(
          context.uiText(
            '$number · ${generated.formLabel} · Livello ${generated.level}',
            '$number · ${generated.formLabel} · Level ${generated.level}',
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final type in pokemon.types)
              PokemonTypeBadge(type: type, height: 22),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoChip(label: 'SR', value: _formatNumber(pokemon.sr)),
            _InfoChip(label: context.uiText('CA', 'AC'), value: '$armorClass'),
            _InfoChip(
              label: context.uiText('PF', 'HP'),
              value: '${generated.maxHp}',
            ),
            _InfoChip(
              label: context.uiText('Sesso', 'Gender'),
              value: _genderLabel(generated.gender),
            ),
            _InfoChip(
              label: context.uiText('Natura', 'Nature'),
              value: generated.nature,
            ),
            _InfoChip(
              label: context.uiText('Abilità', 'Ability'),
              value: generated.ability ?? context.uiText('Nessuna', 'None'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoChip(
              label: context.uiText('FOR', 'STR'),
              value: '${pokemon.attributes.strength}',
            ),
            _InfoChip(
              label: context.uiText('DES', 'DEX'),
              value: '${pokemon.attributes.dexterity}',
            ),
            _InfoChip(
              label: context.uiText('COS', 'CON'),
              value: '${pokemon.attributes.constitution}',
            ),
            _InfoChip(
              label: 'INT',
              value: '${pokemon.attributes.intelligence}',
            ),
            _InfoChip(
              label: context.uiText('SAG', 'WIS'),
              value: '${pokemon.attributes.wisdom}',
            ),
            _InfoChip(
              label: context.uiText('CAR', 'CHA'),
              value: '${pokemon.attributes.charisma}',
            ),
          ],
        ),
      ],
    );
  }

  static String _formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  static String _genderLabel(String? gender) {
    switch (gender) {
      case 'Male':
        return 'Maschio';
      case 'Female':
        return 'Femmina';
      case 'Genderless':
        return 'Senza sesso';
      default:
        return 'Non specificato';
    }
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _GeneratedMoveChip extends StatelessWidget {
  const _GeneratedMoveChip({required this.reference, required this.move});

  final String reference;
  final MoveData? move;

  @override
  Widget build(BuildContext context) {
    final resolved = move;
    return Container(
      constraints: const BoxConstraints(minWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            resolved?.name ?? reference,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            resolved == null
                ? 'Dettagli non disponibili'
                : '${resolved.type} · PP ${resolved.pp}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = isError
        ? colors.errorContainer
        : colors.primaryContainer;
    final foreground = isError
        ? colors.onErrorContainer
        : colors.onPrimaryContainer;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: foreground,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: TextStyle(color: foreground)),
            ),
          ],
        ),
      ),
    );
  }
}
