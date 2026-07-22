from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    source = file.read_text(encoding='utf-8')
    count = source.count(old)
    if count != 1:
        raise SystemExit(f'{path}: expected one match, found {count}')
    file.write_text(source.replace(old, new, 1), encoding='utf-8')


# Secret evolution presentation.
path = 'lib/screens/pokemon/evolution_selector_sheet.dart'
replace_once(
    path,
    """        leading: targetPokemon == null
            ? const Icon(Icons.catching_pokemon)
            : PokemonAssetImage(pokemon: targetPokemon, size: 52),
        title: Text(
          choice.option.toName.toUpperCase(),
""",
    """        leading: choice.option.isSecret
            ? const Icon(Icons.lock_outline, size: 36)
            : targetPokemon == null
                ? const Icon(Icons.catching_pokemon)
                : PokemonAssetImage(
                    pokemon: targetPokemon,
                    formName: choice.option.targetFormName,
                    size: 52,
                  ),
        title: Text(
          choice.option.isSecret
              ? 'EVOLUZIONE SCONOSCIUTA'
              : choice.option.toName.toUpperCase(),
""",
)
replace_once(
    path,
    """              if (conditionLabels.isNotEmpty)
                Wrap(
""",
    """              if (choice.option.isSecret &&
                  choice.option.secretHint?.trim().isNotEmpty == true) ...[
                Text(
                  choice.option.secretHint!,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 6),
              ],
              if (conditionLabels.isNotEmpty)
                Wrap(
""",
)

# Detail screen can resolve sealed custom targets and reveal them after evolution.
path = 'lib/screens/pokemon/pokemon_detail_screen_legacy.dart'
replace_once(
    path,
    """import '../../services/battle_form_change_service.dart';
import '../../services/evolution_service.dart';
""",
    """import '../../services/battle_form_change_service.dart';
import '../../services/custom_pokemon_discovery_service.dart';
import '../../services/custom_pokemon_runtime_registry.dart';
import '../../services/evolution_service.dart';
""",
)
replace_once(
    path,
    """  final EvolutionService _evolutionService = const EvolutionService();
""",
    """  final EvolutionService _evolutionService = const EvolutionService();
  final CustomPokemonDiscoveryService _customDiscoveryService =
      CustomPokemonDiscoveryService();
""",
)
replace_once(
    path,
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
    """  Pokemon? _pokemonByName(String name) {
    final targetKey = _referenceKey(name);
    for (final pokemon in widget.allPokemon) {
      if (pokemon.name == name || _referenceKey(pokemon.name) == targetKey) {
        return pokemon;
      }
    }
    for (final definition in CustomPokemonRuntimeRegistry.definitions) {
      if (definition.name == name || _referenceKey(definition.name) == targetKey) {
        return definition.toPokemon();
      }
    }

    return null;
  }

  Pokemon? _pokemonForEvolutionOption(EvolutionOption option) {
    final targetId = option.targetPokemonId;
    if (targetId != null) {
      for (final pokemon in widget.allPokemon) {
        if (pokemon.id == targetId) return pokemon;
      }
      final custom = CustomPokemonRuntimeRegistry.definitionFor(targetId);
      if (custom != null) return custom.toPokemon();
    }
    final stable = CustomPokemonRuntimeRegistry.definitionByStableId(
      option.targetStableId,
    );
    return stable?.toPokemon() ?? _pokemonByName(option.toName);
  }
""",
)
replace_once(
    path,
    """    final evolvedPokemon = _pokemonByName(selected.option.toName);
""",
    """    final evolvedPokemon = _pokemonForEvolutionOption(selected.option);
""",
)
replace_once(
    path,
    """      selectedMoves: List<String>.from(slot.selectedMoves),
    );
""",
    """      selectedMoves: List<String>.from(slot.selectedMoves),
      formName: selected.option.targetFormName,
    );
""",
)
replace_once(
    path,
    """    widget.onTeamSlotChanged?.call(updatedSlot);
    await _loadData();

    return updatedSlot;
""",
    """    widget.onTeamSlotChanged?.call(updatedSlot);
    final revealed = await _customDiscoveryService.revealByPokemonId(
      evolvedPokemon.id,
    );
    if (revealed) {
      PokemonRepository.clearCache();
      _showMessage(
        '$oldName si è evoluto in ${selected.option.toName}! Nuova specie scoperta.',
      );
    }
    await _loadData();

    return updatedSlot;
""",
)
replace_once(
    path,
    """import '../../repositories/profile_repository.dart';
""",
    """import '../../repositories/profile_repository.dart';
import '../../repositories/pokemon_repository.dart';
""",
)

# Compatibility shell resolves hidden custom species by id after evolution.
path = 'lib/screens/pokemon/pokemon_detail_screen.dart'
replace_once(
    path,
    """import '../../services/evolution_form_alias_service.dart';
""",
    """import '../../services/custom_pokemon_runtime_registry.dart';
import '../../services/evolution_form_alias_service.dart';
""",
)
replace_once(
    path,
    """    for (final pokemon in widget.allPokemon) {
      if (pokemon.id == pokemonId) return pokemon;
    }
    return null;
""",
    """    for (final pokemon in widget.allPokemon) {
      if (pokemon.id == pokemonId) return pokemon;
    }
    return CustomPokemonRuntimeRegistry.definitionFor(pokemonId)?.toPokemon();
""",
)

# Capture and seen registration reveal sealed species for the active profile.
path = 'lib/screens/capture/capture_pokemon_screen.dart'
replace_once(
    path,
    """import '../../services/trainer_path_passive_service.dart';
""",
    """import '../../services/custom_pokemon_discovery_service.dart';
import '../../services/trainer_path_passive_service.dart';
""",
)
replace_once(
    path,
    """  final BagInventoryRepository _bagRepository = BagInventoryRepository();
""",
    """  final BagInventoryRepository _bagRepository = BagInventoryRepository();
  final CustomPokemonDiscoveryService _discoveryService =
      CustomPokemonDiscoveryService();
""",
)
replace_once(
    path,
    """      final destination = await _addPokemonToCollection(
        profile,
        pokemon,
        result,
      );
      await _loadData(clearMessages: false);
""",
    """      final destination = await _addPokemonToCollection(
        profile,
        pokemon,
        result,
      );
      final revealed = await _discoveryService.revealByPokemonId(pokemon.id);
      if (revealed) PokemonRepository.clearCache();
      await _loadData(clearMessages: false);
""",
)
replace_once(
    path,
    """        _successMessage =
            '${pokemon.name} registrato come catturato e $destination.';
""",
    """        _successMessage = revealed
            ? '${pokemon.name} scoperto, registrato come catturato e $destination.'
            : '${pokemon.name} registrato come catturato e $destination.';
""",
)
replace_once(
    path,
    """    await _pokedexRepository.updateMarkMode(
      profileId: profile.id,
      pokemonId: pokemon.id,
      seen: true,
      caught: false,
    );

    if (!mounted) return;
""",
    """    await _pokedexRepository.updateMarkMode(
      profileId: profile.id,
      pokemonId: pokemon.id,
      seen: true,
      caught: false,
    );
    final revealed = await _discoveryService.revealByPokemonId(pokemon.id);
    if (revealed) PokemonRepository.clearCache();

    if (!mounted) return;
""",
)

# Custom temporary forms remain available to the Battle Companion even though
# they are hidden from the persistent edit screen.
path = 'lib/screens/battle/battle_screen.dart'
replace_once(
    path,
    """    final allChoices = await PokemonAssetPaths.formChoices(basePokemon);
    final choices = _normalizedBattleFormChoices(basePokemon, slot, allChoices);
""",
    """    final allChoices = await PokemonAssetPaths.formChoices(basePokemon);
    final customDefinition = CustomPokemonRuntimeRegistry.definitionFor(
      basePokemon.id,
    );
    final customTemporaryChoices = [
      for (final form in customDefinition?.advanced.forms ?? const [])
        if (form.duration == CustomPokemonFormDuration.battle)
          PokemonFormChoice(name: form.name, assetPath: ''),
    ];
    final choices = _normalizedBattleFormChoices(
      basePokemon,
      slot,
      [...allChoices, ...customTemporaryChoices],
    );
""",
)
replace_once(
    path,
    """import '../../models/battle_environment.dart';
""",
    """import '../../models/battle_environment.dart';
import '../../models/custom_pokemon_advanced_data.dart';
""",
)
replace_once(
    path,
    """import '../../services/custom_pokemon_runtime_registry.dart';
""",
    """import '../../services/custom_pokemon_runtime_registry.dart';
""",
)
# The runtime registry import already exists in the current battle screen; the
# exact self-replacement above validates that assumption without changing it.
