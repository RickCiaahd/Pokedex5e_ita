from pathlib import Path
import re

repo = Path('.')
move_repository = repo / 'lib/repositories/move_repository.dart'
editor = repo / 'lib/screens/pokemon/pokemon_edit_screen.dart'
changelog = repo / 'CHANGELOG.md'
test_file = repo / 'test/full_move_catalog_test.dart'


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{label}: expected one match, found {count}')
    return text.replace(old, new, 1)


repository_source = move_repository.read_text(encoding='utf-8')
repository_source = replace_once(
    repository_source,
    "  Future<List<MoveData>> getAllWebMoves() async {\n",
    "  /// Returns the complete move catalog exposed by the app.\n"
    "  ///\n"
    "  /// Keeping this entry point independent from the backing asset makes it\n"
    "  /// possible to merge additional move sources later without changing the UI.\n"
    "  Future<List<MoveData>> getAllMoves() => getAllWebMoves();\n\n"
    "  Future<List<MoveData>> getAllWebMoves() async {\n",
    'move repository entry point',
)
move_repository.write_text(repository_source, encoding='utf-8')

source = editor.read_text(encoding='utf-8')
source = replace_once(
    source,
    "  List<String> _tmMoveNames = const [];\n  Map<String, String> _abilityDescriptions = {};\n",
    "  List<String> _tmMoveNames = const [];\n"
    "  List<String> _catalogMoveNames = const [];\n"
    "  Map<String, String> _abilityDescriptions = {};\n",
    'catalog move field',
)

load_method = '''  Future<void> _loadChoices() async {
    final abilityDescriptionsFuture = _abilityRepository
        .getAbilityDescriptions();
    final abilityChoicesFuture = _abilityRepository.getWebAbilities();
    final deprecatedAbilitiesFuture = _abilityRepository
        .getDeprecatedAbilityNames();
    final featDescriptionsFuture = _featRepository.getFeatDescriptions();
    final formChoicesFuture = PokemonAssetPaths.formChoices(widget.pokemon);
    final tmMapFuture = _tmRepository.getTmMap();
    final catalogMovesFuture = _moveRepository.getAllMoves();

    final abilityDescriptions = await abilityDescriptionsFuture;
    final abilityChoices = await abilityChoicesFuture;
    final deprecatedAbilities = await deprecatedAbilitiesFuture;
    final featDescriptions = await featDescriptionsFuture;
    final formChoices = await formChoicesFuture;
    final tmMap = await tmMapFuture;
    final catalogMoves = await catalogMovesFuture;
    final tmMoveNames = await _tmMoveNamesFromRepository(tmMap);
    final contextualMoveData = await _moveRepository.getMoves(
      _learnsetMoveChoices(tmMoveNames),
    );
    final moveData = <String, MoveData?>{...contextualMoveData};
    for (final move in catalogMoves) {
      moveData[move.id] = move;
      moveData[move.name] = move;
    }
    final catalogMoveNames = _unique(
      catalogMoves.map((move) => move.name),
    )..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    if (!mounted) return;

    var formName = _formName;
    if (formChoices.length <= 1) {
      formName = null;
    } else {
      final currentKey = Pokemon.formReferenceKey(
        formName ?? '',
        widget.pokemon.name,
      );
      PokemonFormChoice? matchingChoice;
      for (final choice in formChoices) {
        if (Pokemon.formReferenceKey(choice.name, widget.pokemon.name) ==
            currentKey) {
          matchingChoice = choice;
          break;
        }
      }
      formName = matchingChoice?.name ?? formChoices.first.name;
    }

    setState(() {
      _abilityDescriptions = abilityDescriptions;
      _abilityChoices = abilityChoices;
      _deprecatedAbilityNames = deprecatedAbilities;
      _featDescriptions = featDescriptions;
      _moveData = moveData;
      _tmMoveNames = tmMoveNames;
      _catalogMoveNames = catalogMoveNames;
      _formChoices = formChoices;
      _formName = formName;
      _isLoadingChoices = false;
    });
  }

'''
source, count = re.subn(
    r"  Future<void> _loadChoices\(\) async \{.*?\n  Future<List<String>> _tmMoveNamesFromRepository",
    load_method + "  Future<List<String>> _tmMoveNamesFromRepository",
    source,
    count=1,
    flags=re.S,
)
if count != 1:
    raise SystemExit(f'load choices replacement: {count}')

old_choices = '''  List<String> _allMoveChoices([List<String>? tmMoves]) {
    return _unique([
      ..._movesUpToLevel(20),
      ...(tmMoves ?? _tmMoveNames),
      ...widget.availableMoves,
      ..._selectedMoves,
    ])..sort();
  }
'''
new_choices = '''  List<String> _learnsetMoveChoices([List<String>? tmMoves]) {
    return _unique([
      ..._movesUpToLevel(20),
      ...(tmMoves ?? _tmMoveNames),
      ..._formPokemon.moves.eggMoves,
      ...widget.availableMoves,
      ..._selectedMoves,
    ])..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }
'''
source = replace_once(source, old_choices, new_choices, 'learnset choices')

source = replace_once(
    source,
    '''        builder: (_) => _MovePickerScreen(
          currentLevelMoves: widget.availableMoves,
          level20Moves: _movesUpToLevel(20),
          tmMoves: _tmMoveNames,
          allMoves: _allMoveChoices(),
          blockedMoves: blocked,
          moveData: _moveData,
        ),
''',
    '''        builder: (_) => _MovePickerScreen(
          currentLevelMoves: widget.availableMoves,
          learnsetMoves: _learnsetMoveChoices(),
          catalogMoves: _catalogMoveNames,
          blockedMoves: blocked,
          moveData: _moveData,
        ),
''',
    'move picker arguments',
)

reload_method = '''  Future<void> _reloadVariantDependentChoices() async {
    final tmMap = await _tmRepository.getTmMap();
    final tmMoveNames = await _tmMoveNamesFromRepository(tmMap);
    final contextualMoveData = await _moveRepository.getMoves(
      _learnsetMoveChoices(tmMoveNames),
    );
    if (!mounted) return;

    setState(() {
      _tmMoveNames = tmMoveNames;
      _moveData = {..._moveData, ...contextualMoveData};
    });
  }

'''
source, count = re.subn(
    r"  Future<void> _reloadVariantDependentChoices\(\) async \{.*?\n  Future<void> _setGender",
    reload_method + "  Future<void> _setGender",
    source,
    count=1,
    flags=re.S,
)
if count != 1:
    raise SystemExit(f'reload choices replacement: {count}')

picker_code = r'''class _MovePickerScreen extends StatefulWidget {
  const _MovePickerScreen({
    required this.currentLevelMoves,
    required this.learnsetMoves,
    required this.catalogMoves,
    required this.blockedMoves,
    required this.moveData,
  });

  final List<String> currentLevelMoves;
  final List<String> learnsetMoves;
  final List<String> catalogMoves;
  final Set<String> blockedMoves;
  final Map<String, MoveData?> moveData;

  @override
  State<_MovePickerScreen> createState() => _MovePickerScreenState();
}

class _MovePickerScreenState extends State<_MovePickerScreen> {
  String _source = 'current';
  String _search = '';
  String? _selectedType;
  String _category = 'all';

  Set<String> get _blockedMoveKeys => widget.blockedMoves
      .map(MoveData.referenceKey)
      .where((key) => key.isNotEmpty)
      .toSet();

  List<String> get _sourceMoves {
    return switch (_source) {
      'learnset' => widget.learnsetMoves,
      'catalog' => widget.catalogMoves,
      _ => widget.currentLevelMoves,
    };
  }

  List<String> get _availableTypes {
    final types = <String>{};
    for (final move in _sourceMoves) {
      final type = widget.moveData[move]?.type.trim();
      if (type != null && type.isNotEmpty) types.add(type);
    }
    return types.toList(growable: false)
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  String _categoryFor(MoveData? move) {
    if (move?.isAttack == true) return 'attack';
    if ((move?.save ?? '').trim().isNotEmpty) return 'save';
    return 'other';
  }

  String get _sourceLabel {
    return switch (_source) {
      'learnset' => 'Learnset completo',
      'catalog' => 'Catalogo completo',
      _ => 'Disponibile ora',
    };
  }

  String _categoryLabel(String value) {
    return switch (value) {
      'attack' => 'Attacchi',
      'save' => 'Tiri salvezza',
      'other' => 'Altre mosse',
      _ => 'Tutte le categorie',
    };
  }

  List<String> get _activeMoves {
    final search = _search.trim().toLowerCase();
    final selectedType = _selectedType?.toLowerCase();
    final blocked = _blockedMoveKeys;
    final seen = <String>{};

    final moves = _sourceMoves.where((move) {
      final key = MoveData.referenceKey(move);
      if (key.isEmpty || blocked.contains(key) || !seen.add(key)) return false;

      final data = widget.moveData[move];
      if (selectedType != null &&
          (data?.type.toLowerCase() ?? '') != selectedType) {
        return false;
      }
      if (_category != 'all' && _categoryFor(data) != _category) {
        return false;
      }
      if (search.isEmpty) return true;

      return move.toLowerCase().contains(search) ||
          (data?.name.toLowerCase().contains(search) ?? false) ||
          (data?.description.toLowerCase().contains(search) ?? false) ||
          (data?.type.toLowerCase().contains(search) ?? false) ||
          (data?.moveTime.toLowerCase().contains(search) ?? false);
    }).toList(growable: false);

    return moves
      ..sort((a, b) {
        final aLabel = widget.moveData[a]?.name ?? a;
        final bLabel = widget.moveData[b]?.name ?? b;
        return aLabel.toLowerCase().compareTo(bLabel.toLowerCase());
      });
  }

  void _setSource(String value) {
    setState(() {
      _source = value;
      final currentType = _selectedType;
      if (currentType != null && !_availableTypes.contains(currentType)) {
        _selectedType = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final moves = _activeMoves;
    final availableTypes = _availableTypes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SCEGLI MOSSA'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Row(
          children: [
            SizedBox(
              width: 84,
              child: ListView(
                padding: const EdgeInsets.only(top: 12),
                children: [
                  _FilterButton(
                    label: 'ORA',
                    selected: _source == 'current',
                    onTap: () => _setSource('current'),
                  ),
                  _FilterButton(
                    label: 'LEARN.',
                    selected: _source == 'learnset',
                    onTap: () => _setSource('learnset'),
                  ),
                  _FilterButton(
                    label: 'TUTTE',
                    selected: _source == 'catalog',
                    onTap: () => _setSource('catalog'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          textAlign: TextAlign.center,
                          textInputAction: TextInputAction.search,
                          decoration: const InputDecoration(
                            labelText: 'Cerca per nome, tipo o descrizione',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) => setState(() => _search = value),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            SizedBox(
                              width: 210,
                              child: DropdownButtonFormField<String?>(
                                initialValue: _selectedType,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Tipo',
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('Tutti i tipi'),
                                  ),
                                  for (final type in availableTypes)
                                    DropdownMenuItem<String?>(
                                      value: type,
                                      child: Text(type),
                                    ),
                                ],
                                onChanged: (value) =>
                                    setState(() => _selectedType = value),
                              ),
                            ),
                            SizedBox(
                              width: 210,
                              child: DropdownButtonFormField<String>(
                                initialValue: _category,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Categoria',
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  for (final value in const [
                                    'all',
                                    'attack',
                                    'save',
                                    'other',
                                  ])
                                    DropdownMenuItem(
                                      value: value,
                                      child: Text(_categoryLabel(value)),
                                    ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _category = value);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        if (_source == 'catalog') ...[
                          const SizedBox(height: 8),
                          Card(
                            color: Theme.of(
                              context,
                            ).colorScheme.secondaryContainer,
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.info_outline, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Scelta manuale: la compatibilità con la specie non viene verificata.',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '$_sourceLabel · ${moves.length} mosse',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: moves.isEmpty
                        ? const Center(child: Text('Nessuna mossa disponibile.'))
                        : ListView.builder(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                            itemCount: moves.length,
                            itemBuilder: (context, index) {
                              final move = moves[index];
                              final data = widget.moveData[move];
                              final details = <String>[
                                _sourceLabel,
                                if (data != null &&
                                    data.moveTime.trim().isNotEmpty &&
                                    data.moveTime != '-')
                                  data.moveTime,
                                if (data != null &&
                                    data.description.trim().isNotEmpty)
                                  data.description.trim(),
                              ];
                              return _PickerTile(
                                label: data?.name ?? move,
                                type: data?.type,
                                subtitle: details.join('\n'),
                                onTap: () => Navigator.of(context).pop(move),
                              );
                            },
                          ),
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

'''
source, count = re.subn(
    r"class _MovePickerScreen extends StatefulWidget \{.*?\nclass _ChoicePickerScreen extends StatefulWidget \{",
    picker_code + "class _ChoicePickerScreen extends StatefulWidget {",
    source,
    count=1,
    flags=re.S,
)
if count != 1:
    raise SystemExit(f'move picker replacement: {count}')

editor.write_text(source, encoding='utf-8')

changelog_source = changelog.read_text(encoding='utf-8')
changelog_source = replace_once(
    changelog_source,
    "### Modificato\n\n",
    "### Modificato\n\n"
    "- nell'editor Pokémon il selettore mosse distingue disponibilità attuale, learnset completo e catalogo globale, con ricerca e filtri;\n",
    'changelog entry',
)
changelog.write_text(changelog_source, encoding='utf-8')

test_file.write_text(
    '''import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/move_data.dart';
import 'package:pokedex_5e_ita/repositories/move_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('il catalogo completo delle mosse contiene Surf', () async {
    final moves = await MoveRepository().getAllMoves();

    expect(
      moves.any((move) => MoveData.referenceKey(move.name) == 'surf'),
      isTrue,
    );
  });

  test('l editor separa learnset e scelta manuale globale', () {
    final source = File(
      'lib/screens/pokemon/pokemon_edit_screen.dart',
    ).readAsStringSync();

    expect(source, contains("label: 'TUTTE'"));
    expect(source, contains('Scelta manuale: la compatibilità'));
    expect(source, contains('_formPokemon.moves.eggMoves'));
    expect(source, contains('ListView.builder'));
  });
}
''',
    encoding='utf-8',
)
