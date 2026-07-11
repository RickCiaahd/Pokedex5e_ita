from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise SystemExit(f"Expected block not found: {label}")
    return text.replace(old, new, 1)


detail_path = Path("lib/screens/pokemon/pokemon_detail_screen.dart")
detail = detail_path.read_text(encoding="utf-8")

detail = replace_once(
    detail,
    """  Pokemon? _pokemonByName(String name) {
    final targetKey = _referenceKey(name);

    for (final pokemon in widget.allPokemon) {
      if (pokemon.name == name || _referenceKey(pokemon.name) == targetKey) {
        return pokemon;
      }
    }

    return null;
  }

""",
    "",
    "_pokemonByName",
)

current_evolution = """  EvolutionData? _evolutionForCurrentPokemon() {
    return _evolutionForPokemon(_pokemon, _evolutions);
  }

"""
detail = replace_once(
    detail,
    current_evolution,
    current_evolution
    + """  EvolutionTarget? _evolutionTargetFor(EvolutionEligibility choice) {
    final slot = _teamSlot;
    if (slot == null) return null;

    return _evolutionService.resolveTarget(
      option: choice.option,
      currentPokemon: _pokemon,
      slot: slot,
      catalog: widget.allPokemon,
    );
  }

""",
    "evolution target helper",
)

detail = replace_once(
    detail,
    """    return _evolutionChoices
        .where(
          (choice) =>
              choice.isAvailable &&
              _pokemonByName(choice.option.toName) != null,
        )
        .toList(growable: false);
""",
    """    return _evolutionChoices
        .where(
          (choice) =>
              choice.isAvailable && _evolutionTargetFor(choice) != null,
        )
        .toList(growable: false);
""",
    "available evolution choices",
)

detail = replace_once(
    detail,
    """      builder: (_) => EvolutionSelectorSheet(
        currentPokemon: _pokemon,
        choices: choices,
        pokemonByName: _pokemonByName,
      ),
""",
    """      builder: (_) => EvolutionSelectorSheet(
        currentPokemon: _pokemon,
        choices: choices,
        targetForChoice: _evolutionTargetFor,
      ),
""",
    "evolution selector",
)

detail = replace_once(
    detail,
    """    final evolvedPokemon = _pokemonByName(selected.option.toName);
    if (evolvedPokemon == null) {
      _showMessage(
        '${selected.option.toName} non è presente nel catalogo attuale.',
      );
      return null;
    }

""",
    """    final target = _evolutionService.resolveTarget(
      option: selected.option,
      currentPokemon: _pokemon,
      slot: slot,
      catalog: widget.allPokemon,
    );
    if (target == null) {
      _showMessage(
        '${selected.option.toName} non è presente nel catalogo attuale.',
      );
      return null;
    }
    final evolvedBasePokemon = target.basePokemon;
    final evolvedPokemon = target.pokemon;

""",
    "evolution target lookup",
)

detail = replace_once(
    detail,
    """    final updatedSlot = slot.copyWith(
      pokemonId: evolvedPokemon.id,
      currentHp: wasFullHp
""",
    """    final updatedSlot = slot.copyWith(
      pokemonId: evolvedBasePokemon.id,
      formName: target.formName,
      currentHp: wasFullHp
""",
    "evolved slot",
)

detail = replace_once(
    detail,
    """    setState(() {
      _basePokemon = evolvedPokemon;
      _pokemon = evolvedPokemon;
      _teamSlot = updatedSlot;
      _replaceTeamSlot(updatedSlot);
      _isLoading = true;
      _message = '$oldName si è evoluto in ${selected.option.toName}!';
    });
""",
    """    setState(() {
      _basePokemon = evolvedBasePokemon;
      _pokemon = evolvedPokemon;
      _teamSlot = updatedSlot;
      _replaceTeamSlot(updatedSlot);
      _isLoading = true;
      _message = '$oldName si è evoluto in ${target.displayName}!';
    });
""",
    "evolution state",
)

detail_path.write_text(detail, encoding="utf-8")

assets_path = Path("lib/widgets/pokemon/pokemon_asset_image.dart")
assets = assets_path.read_text(encoding="utf-8")
assets = replace_once(
    assets,
    """    for (final assetPath in assetIndex.sortedPaths) {
      if (!assetPath.endsWith('.png')) continue;
      if (!prefixes.any(
""",
    """    for (final assetPath in assetIndex.sortedPaths) {
      if (!assetPath.endsWith('.png')) continue;
      if (assetPath.contains('/pokemon_transforms/')) continue;
      if (!prefixes.any(
""",
    "permanent form asset loop",
)
assets_path.write_text(assets, encoding="utf-8")
