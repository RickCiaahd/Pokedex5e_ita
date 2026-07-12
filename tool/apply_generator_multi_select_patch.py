from pathlib import Path

path = Path('lib/screens/tools/pokemon_generator_screen.dart')
text = path.read_text(encoding='utf-8')


def replace_once(old: str, new: str, label: str) -> None:
    global text
    if old not in text:
        raise SystemExit(f'Could not locate {label}.')
    text = text.replace(old, new, 1)


replace_once(
    "import '../../models/move_data.dart';\nimport '../../models/pokemon.dart';\n",
    "import '../../models/move_data.dart';\nimport '../../models/pc_pokemon.dart';\nimport '../../models/pokemon.dart';\nimport '../../models/pokemon_type_localization.dart';\n",
    'model imports',
)
replace_once(
    "import '../../widgets/navigation/home_leading_button.dart';\nimport '../../widgets/pokemon/pokemon_asset_image.dart';\n",
    "import '../../widgets/navigation/home_leading_button.dart';\nimport '../../widgets/pokemon/pokemon_asset_image.dart';\nimport '../../widgets/tools/generated_pokemon_batch_card.dart';\nimport '../../widgets/tools/pokemon_generator_candidate_selector.dart';\n",
    'widget imports',
)
replace_once(
    "  GeneratedPokemon? _generated;\n  Map<String, MoveData?> _generatedMoves = const {};\n",
    "  GeneratedPokemon? _generated;\n  List<GeneratedPokemon> _generatedBatch = const [];\n  Map<String, MoveData?> _generatedMoves = const {};\n  final Set<int> _selectedPokemonIds = <int>{};\n",
    'generator state',
)
replace_once(
    "        setState(() {\n          _generated = null;\n          _generatedMoves = const {};\n",
    "        setState(() {\n          _generated = null;\n          _generatedBatch = const [];\n          _generatedMoves = const {};\n",
    'empty generation state',
)
replace_once(
    "      setState(() {\n        _generated = generated;\n        _generatedMoves = moves;\n      });\n",
    "      setState(() {\n        _generated = generated;\n        _generatedBatch = const [];\n        _generatedMoves = moves;\n      });\n",
    'single generation result',
)

methods_anchor = """  void _resetFilters() {
"""
methods = """  void _updateFilters(VoidCallback update) {
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
        title: Text('Generare $count Pokémon?'),
        content: const Text(
          'La generazione e l’anteprima di un gruppo molto grande possono '
          'richiedere qualche secondo. Nessun Pokémon verrà ancora salvato.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continua'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<Map<String, MoveData?>> _loadGeneratedMoves(
    Iterable<GeneratedPokemon> generated,
  ) {
    final references = <String>{
      for (final pokemon in generated) ...pokemon.selectedMoves,
    };
    return _moveRepository.getMoves(references);
  }

  Future<void> _generateSelected() async {
    if (_isGenerating) return;
    final selected = _candidates
        .where((pokemon) => _selectedPokemonIds.contains(pokemon.id))
        .toList(growable: false);
    if (selected.isEmpty) {
      setState(() {
        _errorMessage = 'Seleziona almeno un Pokémon dall’elenco compatibile.';
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
        if (generated.length != selected.length) {
          _statusMessage =
              'Generati ${generated.length} Pokémon su ${selected.length} selezionati.';
        }
      });
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
          _errorMessage =
              '${current.basePokemon.name} non corrisponde più ai filtri attuali.';
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
        for (var itemIndex = 0;
            itemIndex < _generatedBatch.length;
            itemIndex++)
          if (itemIndex != index) _generatedBatch[itemIndex],
      ];
    });
  }

"""
replace_once(methods_anchor, methods + methods_anchor, 'multi-select methods anchor')

replace_once(
    """      _includeForms = true;
      _shinyChance = 0.01;
      _statusMessage = null;
      _errorMessage = null;
""",
    """      _includeForms = true;
      _shinyChance = 0.01;
      _selectedPokemonIds.clear();
      _generated = null;
      _generatedBatch = const [];
      _generatedMoves = const {};
      _statusMessage = null;
      _errorMessage = null;
""",
    'reset state',
)

replace_once(
    """  Future<void> _openGeneratedDetails() async {
    final generated = _generated;
    if (generated == null) return;

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
""",
    """  Future<void> _openGeneratedDetails() async {
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
""",
    'detail helper',
)

batch_save_anchor = """  TeamSlot? _firstFreeUnlockedSlot(UserProfile profile) {
"""
batch_save_methods = """  List<String> _resolvedMoveReferences(GeneratedPokemon generated) {
    return [
      for (final reference in generated.selectedMoves)
        _generatedMoves[reference]?.id ?? reference,
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
          .where(
            (slot) => slot.slotIndex < unlocked && slot.pokemonId == null,
          )
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
              notes:
                  'Generato dagli Strumenti al livello ${generated.level}.',
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
        await _pcRepository.savePokemon(
          profile.id,
          [...pcAdditions, ...existingPc],
        );
      }

      final refreshedTeam = await _teamRepository.getTeam(profile.id);
      if (!mounted) return;
      setState(() {
        _team = refreshedTeam
          ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
        _generatedBatch = const [];
        _selectedPokemonIds.clear();
        _statusMessage =
            '${generatedBatch.length} Pokémon aggiunti: $teamCount in squadra, '
            '${pcAdditions.length} nel PC.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

"""
replace_once(
    batch_save_anchor,
    batch_save_methods + batch_save_anchor,
    'batch save anchor',
)

old_callbacks = """                onQueryChanged: (value) => setState(() => _query = value),
                onTypeChanged: (value) =>
                    setState(() => _selectedType = value ?? ''),
                onSrChanged: (value) => setState(() => _srRange = value),
                onGenerationChanged: (value) =>
                    setState(() => _generationRange = value),
                onLevelChanged: (value) => setState(() => _level = value),
                onIncludeFormsChanged: (value) =>
                    setState(() => _includeForms = value),
                onShinyChanceChanged: (value) =>
                    setState(() => _shinyChance = value),
                onReset: _resetFilters,
              ),
"""
new_callbacks = """                onQueryChanged: (value) =>
                    _updateFilters(() => _query = value),
                onTypeChanged: (value) =>
                    _updateFilters(() => _selectedType = value ?? ''),
                onSrChanged: (value) =>
                    _updateFilters(() => _srRange = value),
                onGenerationChanged: (value) =>
                    _updateFilters(() => _generationRange = value),
                onLevelChanged: (value) =>
                    _updateFilters(() => _level = value),
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
"""
replace_once(old_callbacks, new_callbacks, 'filter callbacks')

old_button = """              const SizedBox(height: 14),
              FilledButton.icon(
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
                      ? 'GENERAZIONE...'
                      : 'GENERA TRA ${candidates.length} POKÉMON',
                ),
              ),
"""
new_button = """              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final selectedCount = candidates
                      .where(
                        (pokemon) =>
                            _selectedPokemonIds.contains(pokemon.id),
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
                          ? 'GENERAZIONE...'
                          : 'GENERA 1 CASUALE TRA ${candidates.length}',
                    ),
                  );
                  final selectedButton = FilledButton.tonalIcon(
                    onPressed: selectedCount == 0 || _isGenerating
                        ? null
                        : _generateSelected,
                    icon: const Icon(Icons.playlist_add_check),
                    label: Text(
                      selectedCount == 0
                          ? 'GENERA I SELEZIONATI'
                          : 'GENERA $selectedCount SELEZIONATI',
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
"""
replace_once(old_button, new_button, 'generation buttons')

batch_widget_anchor = """              if (_generated != null) ...[
                const SizedBox(height: 18),
                _GeneratedPokemonCard(
                  generated: _generated!,
                  moves: _generatedMoves,
                  isSaving: _isSaving,
                  onGenerateAgain: _generate,
                  onOpenDetails: _openGeneratedDetails,
                  onAddToCollection: _addGeneratedToCollection,
                ),
              ],
"""
batch_widget = batch_widget_anchor + """              if (_generatedBatch.isNotEmpty) ...[
                const SizedBox(height: 18),
                GeneratedPokemonBatchCard(
                  generated: _generatedBatch,
                  moves: _generatedMoves,
                  isSaving: _isSaving,
                  onRegenerate: _regenerateBatchItem,
                  onOpenDetails: (index) =>
                      _openGeneratedDetailsFor(_generatedBatch[index]),
                  onRemove: _removeBatchItem,
                  onAddAll: _addGeneratedBatchToCollection,
                ),
              ],
"""
replace_once(batch_widget_anchor, batch_widget, 'batch preview widget')

replace_once(
    """                    for (final type in types)
                      DropdownMenuItem(value: type, child: Text(type)),
""",
    """                    for (final type in types)
                      DropdownMenuItem(
                        value: type,
                        child: Text(
                          PokemonTypeLocalization.italianLabel(type),
                        ),
                      ),
""",
    'localized type dropdown',
)

path.write_text(text, encoding='utf-8')
