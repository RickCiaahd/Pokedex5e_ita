from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    source = file.read_text(encoding="utf-8")
    count = source.count(old)
    if count != 1:
        raise SystemExit(f"{path}: expected one match, found {count}")
    file.write_text(source.replace(old, new, 1), encoding="utf-8")


replace_once(
    "lib/screens/pokemon/pokemon_detail_screen.dart",
    """  void _handleSlotChanged(TeamSlot updatedSlot) {
    final alias = _aliasCatalog.bySyntheticId[updatedSlot.pokemonId];
    if (alias == null) {
      final previousSlot = _slot;
      final visualIdentityChanged =
          previousSlot?.pokemonId != updatedSlot.pokemonId ||
          previousSlot?.formName != updatedSlot.formName ||
          previousSlot?.gender != updatedSlot.gender ||
          previousSlot?.isShiny != updatedSlot.isShiny;

      _slot = updatedSlot;
      _replaceTeamSlot(updatedSlot);

      if (visualIdentityChanged) {
        setState(() {
          _aliasCatalog = _buildAliasCatalog();
          _detailGeneration += 1;
        });
      }

      widget.onTeamSlotChanged?.call(updatedSlot);
      return;
    }

    final normalizedSlot = updatedSlot.copyWith(
      pokemonId: alias.basePokemon.id,
      formName: alias.formName,
    );

    setState(() {
      _slot = normalizedSlot;
      _basePokemon = alias.basePokemon;
      _replaceTeamSlot(normalizedSlot);
      _aliasCatalog = _buildAliasCatalog();
      _detailGeneration += 1;
    });

    widget.onTeamSlotChanged?.call(normalizedSlot);
  }
""",
    """  void _handleSlotChanged(TeamSlot updatedSlot) {
    final alias = _aliasCatalog.bySyntheticId[updatedSlot.pokemonId];
    final normalizedSlot = alias == null
        ? updatedSlot
        : updatedSlot.copyWith(
            pokemonId: alias.basePokemon.id,
            formName: alias.formName,
          );
    final nextBasePokemon =
        alias?.basePokemon ??
        _catalogPokemonById(normalizedSlot.pokemonId) ??
        _basePokemon;
    final previousSlot = _slot;
    final visualIdentityChanged =
        _basePokemon.id != nextBasePokemon.id ||
        previousSlot?.pokemonId != normalizedSlot.pokemonId ||
        previousSlot?.formName != normalizedSlot.formName ||
        previousSlot?.gender != normalizedSlot.gender ||
        previousSlot?.isShiny != normalizedSlot.isShiny;

    if (visualIdentityChanged) {
      setState(() {
        _slot = normalizedSlot;
        _basePokemon = nextBasePokemon;
        _replaceTeamSlot(normalizedSlot);
        _aliasCatalog = _buildAliasCatalog();
        _detailGeneration += 1;
      });
    } else {
      _slot = normalizedSlot;
      _replaceTeamSlot(normalizedSlot);
    }

    widget.onTeamSlotChanged?.call(normalizedSlot);
  }
""",
)

replace_once(
    "lib/screens/pokemon/pokemon_detail_screen.dart",
    """  void _replaceTeamSlot(TeamSlot updatedSlot) {
    final index = _team.indexWhere(
      (slot) => slot.slotIndex == updatedSlot.slotIndex,
    );
    if (index == -1) {
      _team = [..._team, updatedSlot];
      return;
    }
    _team = [..._team]..[index] = updatedSlot;
  }

  EvolutionFormAliasCatalog _buildAliasCatalog() {
""",
    """  void _replaceTeamSlot(TeamSlot updatedSlot) {
    final index = _team.indexWhere(
      (slot) => slot.slotIndex == updatedSlot.slotIndex,
    );
    if (index == -1) {
      _team = [..._team, updatedSlot];
      return;
    }
    _team = [..._team]..[index] = updatedSlot;
  }

  Pokemon? _catalogPokemonById(int? pokemonId) {
    if (pokemonId == null) return null;
    if (_basePokemon.id == pokemonId) return _basePokemon;
    for (final pokemon in widget.allPokemon) {
      if (pokemon.id == pokemonId) return pokemon;
    }
    return null;
  }

  EvolutionFormAliasCatalog _buildAliasCatalog() {
""",
)

replace_once(
    "lib/screens/pokemon/pokemon_detail_screen_legacy.dart",
    """                : PokemonAssetImage(pokemon: pokemon, size: 30),
""",
    """                : PokemonAssetImage(
                    pokemon: pokemon,
                    formName: slot.formName,
                    gender: slot.gender,
                    isShiny: slot.isShiny,
                    size: 30,
                  ),
""",
)

replace_once(
    "lib/repositories/evolution_repository.dart",
    """    for (final item in items) {
      if (item is! Map) continue;

      final option = EvolutionOption.fromWebJson(
        Map<String, dynamic>.from(item),
        displayNameBuilder: _displayNameFromKey,
      );
""",
    """    for (final item in items) {
      if (item is! Map) continue;
      final itemJson = Map<String, dynamic>.from(item);
      if (itemJson['nonCanon'] == true) continue;

      final option = EvolutionOption.fromWebJson(
        itemJson,
        displayNameBuilder: _displayNameFromKey,
      );
""",
)

replace_once(
    "lib/repositories/evolution_repository.dart",
    """    return value
        .split('-')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
""",
    """    final parts = value
        .split('-')
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    const regionalLabels = <String, String>{
      'alola': 'Alolan',
      'alolan': 'Alolan',
      'galar': 'Galarian',
      'galarian': 'Galarian',
      'hisui': 'Hisuian',
      'hisuian': 'Hisuian',
      'paldea': 'Paldean',
      'paldean': 'Paldean',
    };
    if (parts.length > 1) {
      final leadingRegion = regionalLabels[parts.first];
      if (leadingRegion != null) {
        return '$leadingRegion ${_titleCase(parts.skip(1))}';
      }
      final trailingRegion = regionalLabels[parts.last];
      if (trailingRegion != null) {
        return '$trailingRegion ${_titleCase(parts.take(parts.length - 1))}';
      }
    }

    return _titleCase(parts);
  }

  String _titleCase(Iterable<String> parts) {
    return parts
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
""",
)

Path("test/evolution_repository_regression_test.dart").write_text(
    """import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/repositories/evolution_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Eevee espone soltanto le evoluzioni canoniche', () async {
    final evolutions = await EvolutionRepository().getEvolutionData();
    final eevee = evolutions['eevee'] ?? evolutions['Eevee'];

    expect(eevee, isNotNull);
    final names = eevee!.options
        .map((option) => option.toName.toLowerCase())
        .toSet();
    expect(
      names,
      containsAll(<String>{
        'vaporeon',
        'jolteon',
        'flareon',
        'espeon',
        'umbreon',
        'leafeon',
        'glaceon',
        'sylveon',
      }),
    );
    expect(
      names.intersection(<String>{
        'droideon',
        'brawleon',
        'specteon',
        'toxeon',
        'minereon',
        'aereon',
        'pesteon',
        'terreon',
        'drakeon',
      }),
      isEmpty,
    );
  });

  test('le evoluzioni regionali di Hisui usano nomi risolvibili', () async {
    final evolutions = await EvolutionRepository().getEvolutionData();

    expect(
      evolutions['dartrix']!.options.map((option) => option.toName),
      contains('Hisuian Decidueye'),
    );
    expect(
      evolutions['quilava']!.options.map((option) => option.toName),
      contains('Hisuian Typhlosion'),
    );
    expect(
      evolutions['dewott']!.options.map((option) => option.toName),
      contains('Hisuian Samurott'),
    );
  });
}
""",
    encoding="utf-8",
)

replace_once(
    "CHANGELOG.md",
    """## [Non rilasciato]

Nessuna modifica successiva alla release 1.0.2.
""",
    """## [Non rilasciato]

### Corretto

- aggiornamento immediato della scheda dopo un’evoluzione;
- sincronizzazione della specie mostrata dopo la modifica di un altro membro della squadra;
- disponibilità delle evoluzioni regionali con regione in forma prefissa o suffissa, compresi gli starter di Hisui;
- sprite della barra squadra coerenti con forma, sesso e variante cromatica dell’esemplare;
- esclusione delle evoluzioni non canoniche di Eevee dal selettore.
""",
)
