from pathlib import Path


def replace_once(path: Path, old: str, new: str, label: str) -> None:
    source = path.read_text(encoding='utf-8')
    count = source.count(old)
    if count != 1:
        raise SystemExit(f'{label}: expected one match, found {count}')
    path.write_text(source.replace(old, new, 1), encoding='utf-8')


model = Path('lib/models/custom_pokemon_definition.dart')
replace_once(
    model,
    "  Pokemon toPokemon() {\n    return Pokemon(\n",
    "  Pokemon toPokemon() {\n"
    "    final referencedMoveKeys = <String>{\n"
    "      ...startingMoves.map(MoveData.referenceKey),\n"
    "      ...levelMoves.values\n"
    "          .expand((moves) => moves)\n"
    "          .map(MoveData.referenceKey),\n"
    "      ...eggMoves.map(MoveData.referenceKey),\n"
    "    };\n"
    "    final effectiveStartingMoves = <String>[...startingMoves];\n"
    "    for (final localMove in localMoves) {\n"
    "      final key = MoveData.referenceKey(localMove.name);\n"
    "      if (key.isNotEmpty && referencedMoveKeys.add(key)) {\n"
    "        effectiveStartingMoves.add(localMove.name);\n"
    "      }\n"
    "    }\n\n"
    "    return Pokemon(\n",
    'effective Fakemon starting moves',
)
replace_once(
    model,
    "        startingMoves: List<String>.unmodifiable(startingMoves),\n",
    "        startingMoves: List<String>.unmodifiable(effectiveStartingMoves),\n",
    'use effective starting moves',
)

editor = Path('lib/screens/pokemon/custom_pokemon_library_screen.dart')
replace_once(
    editor,
    "    if (definition == null) return;\n    setState(() => _localMoves = [..._localMoves, definition]);\n  }\n",
    "    if (definition == null) return;\n"
    "    setState(() {\n"
    "      _localMoves = [..._localMoves, definition];\n"
    "      final startingMoveNames = _csv(_startingMoves.text);\n"
    "      final newMoveKey = MoveData.referenceKey(definition.name);\n"
    "      final isAlreadyAssigned = startingMoveNames.any(\n"
    "        (move) => MoveData.referenceKey(move) == newMoveKey,\n"
    "      );\n"
    "      if (!isAlreadyAssigned) {\n"
    "        startingMoveNames.add(definition.name);\n"
    "        _startingMoves.text = startingMoveNames.join(', ');\n"
    "      }\n"
    "    });\n"
    "  }\n",
    'assign new exclusive move to starting moves',
)

changelog = Path('CHANGELOG.md')
replace_once(
    changelog,
    "### Modificato\n\n",
    "### Modificato\n\n"
    "- le mosse esclusive dei Fakemon vengono aggiunte al moveset iniziale quando create e le vecchie mosse esclusive non assegnate diventano comunque selezionabili nei dettagli della specie;\n",
    'changelog entry',
)

test = Path('test/custom_pokemon_definition_test.dart')
replace_once(
    test,
    "    test('il file portabile rileva una modifica al contenuto', () {\n",
    "    test('una mossa esclusiva non assegnata diventa una mossa iniziale', () {\n"
    "      final json = _definition().toJson();\n"
    "      json['startingMoves'] = <String>[];\n"
    "      final definition = CustomPokemonDefinition.fromJson(json);\n\n"
    "      expect(\n"
    "        definition.toPokemon().moves.startingMoves,\n"
    "        contains('Scarica Astrale'),\n"
    "      );\n"
    "    });\n\n"
    "    test('il file portabile rileva una modifica al contenuto', () {\n",
    'orphan local move test',
)
