from pathlib import Path


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding='utf-8')
    if old not in text:
        raise RuntimeError(f'Expected block not found in {path}: {old[:160]!r}')
    path.write_text(text.replace(old, new, 1), encoding='utf-8')


asset_path = Path('lib/widgets/pokemon/pokemon_asset_image.dart')
replace_once(
    asset_path,
    '''    for (final assetPath in assetIndex.sortedPaths) {
''',
    '''    for (final definition in pokemon.formDefinitions) {
      if (definition.gender != null) continue;
      addChoice(
        PokemonFormChoice(name: definition.displayName, assetPath: ''),
      );
    }

    for (final assetPath in assetIndex.sortedPaths) {
''',
)

battle_path = Path('lib/screens/battle/battle_screen.dart')
replace_once(
    battle_path,
    '''  Pokemon? _pokemonForSlot(_BattleData data, TeamSlot slot) {
    final pokemonId = slot.pokemonId;
    if (pokemonId == null) return null;
    return data.pokemonById[pokemonId];
  }
''',
    '''  Pokemon? _pokemonForSlot(_BattleData data, TeamSlot slot) {
    final pokemonId = slot.pokemonId;
    if (pokemonId == null) return null;
    return data.pokemonById[pokemonId]?.resolveVariant(
      formName: slot.formName,
      gender: slot.gender,
    );
  }
''',
)

detail_path = Path('lib/screens/pokemon/pokemon_detail_screen.dart')
replace_once(
    detail_path,
    '''  late Pokemon _pokemon;
  late List<TeamSlot> _team;
''',
    '''  late Pokemon _basePokemon;
  late Pokemon _pokemon;
  late List<TeamSlot> _team;
''',
)
replace_once(
    detail_path,
    '''    _pokemon = widget.pokemon;
    _team = [...widget.team];
    _teamSlot = widget.teamSlot;
''',
    '''    _basePokemon = widget.pokemon;
    _team = [...widget.team];
    _teamSlot = widget.teamSlot;
    _pokemon = _basePokemon.resolveVariant(
      formName: _teamSlot?.formName,
      gender: _teamSlot?.gender,
    );
''',
)
replace_once(
    detail_path,
    '''  void _saveTeamSlot(TeamSlot updatedSlot) {
    setState(() {
      _teamSlot = updatedSlot;
      _replaceTeamSlot(updatedSlot);
    });
    widget.onTeamSlotChanged?.call(updatedSlot);
    _refreshEvolutionChoices();
  }
''',
    '''  void _saveTeamSlot(TeamSlot updatedSlot) {
    setState(() {
      _teamSlot = updatedSlot;
      _pokemon = _basePokemon.resolveVariant(
        formName: updatedSlot.formName,
        gender: updatedSlot.gender,
      );
      _replaceTeamSlot(updatedSlot);
    });
    widget.onTeamSlotChanged?.call(updatedSlot);
    _refreshEvolutionChoices();
  }
''',
)
replace_once(
    detail_path,
    '''        builder: (_) => PokemonEditScreen(
          pokemon: _pokemon,
          slot: slot,
          availableMoves: _learnedMovesFor(_pokemon, _level),
''',
    '''        builder: (_) => PokemonEditScreen(
          pokemon: _basePokemon,
          slot: slot,
          availableMoves: _learnedMovesFor(_pokemon, _level),
''',
)
replace_once(
    detail_path,
    '''    setState(() {
      _pokemon = evolvedPokemon;
      _teamSlot = updatedSlot;
''',
    '''    setState(() {
      _basePokemon = evolvedPokemon;
      _pokemon = evolvedPokemon;
      _teamSlot = updatedSlot;
''',
)
replace_once(
    detail_path,
    '''    setState(() {
      _pokemon = pokemon;
      _teamSlot = slot;
''',
    '''    setState(() {
      _basePokemon = pokemon;
      _pokemon = pokemon.resolveVariant(
        formName: slot.formName,
        gender: slot.gender,
      );
      _teamSlot = slot;
''',
)

edit_path = Path('lib/screens/pokemon/pokemon_edit_screen.dart')
replace_once(
    edit_path,
    '''  bool _isLoadingChoices = true;

  @override
''',
    '''  bool _isLoadingChoices = true;

  Pokemon get _formPokemon => widget.pokemon.resolveVariant(
        formName: _formName,
        gender: _gender,
      );

  @override
''',
)
replace_once(
    edit_path,
    '''    var formName = _formName;
    if (formChoices.length <= 1) {
      formName = null;
    } else if (formName == null ||
        !formChoices.any((choice) => choice.name == formName)) {
      formName = formChoices.first.name;
    }
''',
    '''    var formName = _formName;
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
''',
)
replace_once(
    edit_path,
    '    for (final tmNumber in widget.pokemon.moves.tmMoves) {\n',
    '    for (final tmNumber in _formPokemon.moves.tmMoves) {\n',
)
replace_once(
    edit_path,
    '    final fallback = widget.pokemon.abilities;\n',
    '    final fallback = _formPokemon.abilities;\n',
)
replace_once(
    edit_path,
    '''      ...widget.pokemon.abilities,
      if (widget.pokemon.hiddenAbility != null) widget.pokemon.hiddenAbility!,
''',
    '''      ..._formPokemon.abilities,
      if (_formPokemon.hiddenAbility != null) _formPokemon.hiddenAbility!,
''',
)
replace_once(
    edit_path,
    '''    final names = <String>[...widget.pokemon.moves.startingMoves];
    final entries = widget.pokemon.moves.levelMoves.entries
''',
    '''    final names = <String>[..._formPokemon.moves.startingMoves];
    final entries = _formPokemon.moves.levelMoves.entries
''',
)
replace_once(
    edit_path,
    '''  Future<void> _pickForm() async {
''',
    '''  Future<void> _reloadVariantDependentChoices() async {
    final tmMap = await _tmRepository.getTmMap();
    final tmMoveNames = await _tmMoveNamesFromRepository(tmMap);
    final moveData = await _moveRepository.getMoves(
      _allMoveChoices(tmMoveNames),
    );
    if (!mounted) return;

    setState(() {
      _tmMoveNames = tmMoveNames;
      _moveData = moveData;
    });
  }

  Future<void> _setGender(String? value) async {
    setState(() => _gender = value);
    await _reloadVariantDependentChoices();
  }

  Future<void> _pickForm() async {
''',
)
replace_once(
    edit_path,
    '''    if (!mounted || result == null) return;

    setState(() => _formName = result);
  }
''',
    '''    if (!mounted || result == null) return;

    setState(() => _formName = result);
    await _reloadVariantDependentChoices();
  }
''',
)
replace_once(
    edit_path,
    '''                        onChanged: (value) => setState(() => _gender = value),
''',
    '''                        onChanged: (value) {
                          _setGender(value);
                        },
''',
)

capture_path = Path('lib/screens/capture/capture_pokemon_screen.dart')
replace_once(
    capture_path,
    '''  bool _isShiny = false;

  @override
''',
    '''  bool _isShiny = false;

  Pokemon get _selectedPokemon => widget.pokemon.resolveVariant(
        formName: _formName,
        gender: _gender,
      );

  @override
''',
)
replace_once(
    capture_path,
    '''  void _submit(_CaptureRegistrationAction action) {
''',
    '''  void _setGender(String? value) {
    final oldPokemon = _selectedPokemon;
    final usedDefaultHp =
        _hpController.text.trim() == oldPokemon.hitPoints.toString();
    setState(() => _gender = value);
    if (usedDefaultHp) {
      _hpController.text = _selectedPokemon.hitPoints.toString();
    }
  }

  void _setForm(String? value) {
    final oldPokemon = _selectedPokemon;
    final usedDefaultHp =
        _hpController.text.trim() == oldPokemon.hitPoints.toString();
    setState(() => _formName = value);
    if (usedDefaultHp) {
      _hpController.text = _selectedPokemon.hitPoints.toString();
    }
  }

  void _submit(_CaptureRegistrationAction action) {
''',
)
replace_once(
    capture_path,
    '''        currentHp: (parsedHp ?? widget.pokemon.hitPoints).clamp(0, 9999).toInt(),
''',
    '''        currentHp: (parsedHp ?? _selectedPokemon.hitPoints)
            .clamp(0, 9999)
            .toInt(),
''',
)
replace_once(
    capture_path,
    '''    final formChoices = widget.formChoices;

    return SafeArea(
''',
    '''    final formChoices = widget.formChoices;
    final selectedPokemon = _selectedPokemon;

    return SafeArea(
''',
)
replace_once(
    capture_path,
    '''                          for (final type in widget.pokemon.types)
''',
    '''                          for (final type in selectedPokemon.types)
''',
)
replace_once(
    capture_path,
    '''                        : (value) => setState(() => _gender = value),
''',
    '''                        : _setGender,
''',
)
replace_once(
    capture_path,
    '''                onChanged: (value) => setState(() => _formName = value),
''',
    '''                onChanged: _setForm,
''',
)
replace_once(
    capture_path,
    '''    final teamSlot = _firstFreeTeamSlot;
    final nickname = result.nickname.trim().isEmpty ? null : result.nickname.trim();

    if (teamSlot != null) {
''',
    '''    final teamSlot = _firstFreeTeamSlot;
    final nickname = result.nickname.trim().isEmpty ? null : result.nickname.trim();
    final selectedPokemon = pokemon.resolveVariant(
      formName: result.formName,
      gender: result.gender,
    );
    final startingMoves = selectedPokemon.moves.startingMoves
        .take(4)
        .toList(growable: false);
    final naturalAbilities = selectedPokemon.abilities
        .take(2)
        .toList(growable: false);

    if (teamSlot != null) {
''',
)
replace_once(
    capture_path,
    '''          nature: result.nature,
        ),
''',
    '''          nature: result.nature,
          selectedMoves: startingMoves,
          abilities: naturalAbilities,
        ),
''',
)
replace_once(
    capture_path,
    '''        nature: result.nature,
      );
''',
    '''        nature: result.nature,
        selectedMoves: startingMoves,
        abilities: naturalAbilities,
      );
''',
)

bag_path = Path('lib/screens/bag/bag_screen.dart')
bag_text = bag_path.read_text(encoding='utf-8')
old_loop = '''      final pokemon = data.pokemonById[pokemonId];
      if (pokemon == null) continue;
'''
new_loop = '''      final basePokemon = data.pokemonById[pokemonId];
      if (basePokemon == null) continue;
      final pokemon = basePokemon.resolveVariant(
        formName: slot.formName,
        gender: slot.gender,
      );
'''
count = bag_text.count(old_loop)
if count < 2:
    raise RuntimeError(f'Expected at least two bag Pokemon loops, found {count}')
bag_text = bag_text.replace(old_loop, new_loop)
old_tm_loop = '''      final pokemon = pokemonById[pokemonId];
      if (pokemon == null) continue;
'''
new_tm_loop = '''      final basePokemon = pokemonById[pokemonId];
      if (basePokemon == null) continue;
      final pokemon = basePokemon.resolveVariant(
        formName: slot.formName,
        gender: slot.gender,
      );
'''
if old_tm_loop not in bag_text:
    raise RuntimeError('Expected TM Pokemon loop in bag screen')
bag_path.write_text(
    bag_text.replace(old_tm_loop, new_tm_loop, 1),
    encoding='utf-8',
)

test_content = r'''import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/repositories/pokemon_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Alolan Rattata applies mechanical variant data', () async {
    final pokemon = await PokemonRepository().getAllPokemon();
    final rattata = pokemon.firstWhere((entry) => entry.id == 19);
    final alolan = rattata.resolveVariant(formName: 'Alolan Rattata');

    expect(alolan.types, containsAll(<String>['Dark', 'Normal']));
    expect(alolan.abilities, contains('Gluttony'));
    expect(alolan.moves.startingMoves, contains('Quick Attack'));
  });

  test('Dusk Mane Necrozma deep-merges stats and types', () async {
    final pokemon = await PokemonRepository().getAllPokemon();
    final necrozma = pokemon.firstWhere((entry) => entry.id == 800);
    final duskMane = necrozma.resolveVariant(formName: 'Dusk Mane Necrozma');

    expect(duskMane.armorClass, 19);
    expect(duskMane.types, <String>['Psychic', 'Steel']);
    expect(duskMane.attributes.strength, 22);
    expect(duskMane.attributes.wisdom, 20);
  });

  test('web gender variants are selected from the saved gender', () async {
    final pokemon = await PokemonRepository().getAllPokemon();
    final indeedee = pokemon.firstWhere((entry) => entry.id == 876);
    final male = indeedee.resolveVariant(gender: 'male');
    final female = indeedee.resolveVariant(gender: 'female');

    expect(male.assetSlug, contains('indeedee-m'));
    expect(female.assetSlug, contains('indeedee-f'));
  });
}
'''
Path('test/pokemon_form_mechanics_test.dart').write_text(
    test_content,
    encoding='utf-8',
)

print('Applied mechanical Pokemon form support.')
