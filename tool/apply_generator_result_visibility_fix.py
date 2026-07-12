from pathlib import Path

path = Path('lib/screens/tools/pokemon_generator_screen.dart')
text = path.read_text(encoding='utf-8')

replacements = [
    (
        "  final TextEditingController _searchController = TextEditingController();\n",
        "  final TextEditingController _searchController = TextEditingController();\n"
        "  final GlobalKey _singleResultKey = GlobalKey();\n"
        "  final GlobalKey _batchResultKey = GlobalKey();\n",
    ),
    (
        "      setState(() {\n"
        "        _generated = generated;\n"
        "        _generatedBatch = const [];\n"
        "        _generatedMoves = moves;\n"
        "      });\n",
        "      setState(() {\n"
        "        _generated = generated;\n"
        "        _generatedBatch = const [];\n"
        "        _generatedMoves = moves;\n"
        "        _statusMessage =\n"
        "            '${generated.basePokemon.name} generato. Anteprima pronta qui sotto.';\n"
        "      });\n"
        "      _scrollToResult(_singleResultKey);\n",
    ),
    (
        "  Future<Map<String, MoveData?>> _loadGeneratedMoves(\n"
        "    Iterable<GeneratedPokemon> generated,\n"
        "  ) {\n"
        "    final references = <String>{\n"
        "      for (final pokemon in generated) ...pokemon.selectedMoves,\n"
        "    };\n"
        "    return _moveRepository.getMoves(references);\n"
        "  }\n",
        "  Future<Map<String, MoveData?>> _loadGeneratedMoves(\n"
        "    Iterable<GeneratedPokemon> generated,\n"
        "  ) {\n"
        "    final references = <String>{\n"
        "      for (final pokemon in generated) ...pokemon.selectedMoves,\n"
        "    };\n"
        "    return _moveRepository.getMoves(references);\n"
        "  }\n\n"
        "  void _scrollToResult(GlobalKey resultKey) {\n"
        "    WidgetsBinding.instance.addPostFrameCallback((_) {\n"
        "      if (!mounted) return;\n"
        "      final resultContext = resultKey.currentContext;\n"
        "      if (resultContext == null) return;\n"
        "      Scrollable.ensureVisible(\n"
        "        resultContext,\n"
        "        duration: const Duration(milliseconds: 420),\n"
        "        curve: Curves.easeOutCubic,\n"
        "        alignment: 0.04,\n"
        "      );\n"
        "    });\n"
        "  }\n",
    ),
    (
        "      setState(() {\n"
        "        _generated = null;\n"
        "        _generatedBatch = generated;\n"
        "        _generatedMoves = moves;\n"
        "        if (generated.length != selected.length) {\n"
        "          _statusMessage =\n"
        "              'Generati ${generated.length} Pokémon su ${selected.length} selezionati.';\n"
        "        }\n"
        "      });\n",
        "      setState(() {\n"
        "        _generated = null;\n"
        "        _generatedBatch = generated;\n"
        "        _generatedMoves = moves;\n"
        "        _statusMessage = generated.length == selected.length\n"
        "            ? '${generated.length} Pokémon generati. Anteprima pronta qui sotto.'\n"
        "            : 'Generati ${generated.length} Pokémon su ${selected.length} selezionati.';\n"
        "      });\n"
        "      _scrollToResult(_batchResultKey);\n",
    ),
    (
        "                _GeneratedPokemonCard(\n"
        "                  generated: _generated!,\n"
        "                  moves: _generatedMoves,\n"
        "                  isSaving: _isSaving,\n"
        "                  onGenerateAgain: _generate,\n"
        "                  onOpenDetails: _openGeneratedDetails,\n"
        "                  onAddToCollection: _addGeneratedToCollection,\n"
        "                ),\n",
        "                KeyedSubtree(\n"
        "                  key: _singleResultKey,\n"
        "                  child: _GeneratedPokemonCard(\n"
        "                    generated: _generated!,\n"
        "                    moves: _generatedMoves,\n"
        "                    isSaving: _isSaving,\n"
        "                    onGenerateAgain: _generate,\n"
        "                    onOpenDetails: _openGeneratedDetails,\n"
        "                    onAddToCollection: _addGeneratedToCollection,\n"
        "                  ),\n"
        "                ),\n",
    ),
    (
        "                GeneratedPokemonBatchCard(\n"
        "                  generated: _generatedBatch,\n"
        "                  moves: _generatedMoves,\n"
        "                  isSaving: _isSaving,\n"
        "                  onRegenerate: _regenerateBatchItem,\n"
        "                  onOpenDetails: (index) =>\n"
        "                      _openGeneratedDetailsFor(_generatedBatch[index]),\n"
        "                  onRemove: _removeBatchItem,\n"
        "                  onAddAll: _addGeneratedBatchToCollection,\n"
        "                ),\n",
        "                KeyedSubtree(\n"
        "                  key: _batchResultKey,\n"
        "                  child: GeneratedPokemonBatchCard(\n"
        "                    generated: _generatedBatch,\n"
        "                    moves: _generatedMoves,\n"
        "                    isSaving: _isSaving,\n"
        "                    onRegenerate: _regenerateBatchItem,\n"
        "                    onOpenDetails: (index) =>\n"
        "                        _openGeneratedDetailsFor(_generatedBatch[index]),\n"
        "                    onRemove: _removeBatchItem,\n"
        "                    onAddAll: _addGeneratedBatchToCollection,\n"
        "                  ),\n"
        "                ),\n",
    ),
]

for old, new in replacements:
    if old not in text:
        raise SystemExit(f'Could not find expected snippet:\n{old[:200]}')
    text = text.replace(old, new, 1)

path.write_text(text, encoding='utf-8')
