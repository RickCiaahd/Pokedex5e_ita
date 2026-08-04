import 'package:flutter/material.dart';

import '../../models/pokemon.dart';
import '../../models/pokemon_evolution_alias_registry.dart';
import '../../models/team_slot.dart';
import '../../services/custom_pokemon_runtime_registry.dart';
import '../../services/evolution_form_alias_service.dart';
import 'pokemon_detail_screen_legacy.dart' as legacy;

/// Compatibility shell around the full detail screen.
///
/// Evolution data can reference a concrete form (for example
/// `alolan-raichu`) even though owned Pokémon are persisted as a Pokédex
/// species id plus its persisted or item-derived effective form. The full
/// detail screen resolves an evolution by display name, so this shell exposes
/// temporary catalog aliases and translates them back to the canonical
/// species/form pair before anything is persisted.
class PokemonDetailScreen extends StatefulWidget {
  const PokemonDetailScreen({
    super.key,
    required this.pokemon,
    this.teamSlot,
    this.allPokemon = const [],
    this.team = const [],
    this.onTeamSlotChanged,
  });

  final Pokemon pokemon;
  final TeamSlot? teamSlot;
  final List<Pokemon> allPokemon;
  final List<TeamSlot> team;
  final ValueChanged<TeamSlot>? onTeamSlotChanged;

  @override
  State<PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen> {
  final EvolutionFormAliasService _aliasService =
      const EvolutionFormAliasService();

  late Pokemon _basePokemon;
  late TeamSlot? _slot;
  late List<TeamSlot> _team;
  late EvolutionFormAliasCatalog _aliasCatalog;
  int _detailGeneration = 0;

  @override
  void initState() {
    super.initState();
    _basePokemon = widget.pokemon;
    _slot = widget.teamSlot;
    _team = [...widget.team];
    _aliasCatalog = _buildAliasCatalog();
  }

  @override
  void didUpdateWidget(covariant PokemonDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pokemon.id == widget.pokemon.id &&
        oldWidget.teamSlot == widget.teamSlot &&
        identical(oldWidget.allPokemon, widget.allPokemon) &&
        identical(oldWidget.team, widget.team)) {
      return;
    }

    _basePokemon = widget.pokemon;
    _slot = widget.teamSlot;
    _team = [...widget.team];
    _aliasCatalog = _buildAliasCatalog();
    _detailGeneration += 1;
  }

  void _handleSlotChanged(TeamSlot updatedSlot) {
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
        previousSlot?.effectiveFormName != normalizedSlot.effectiveFormName ||
        previousSlot?.heldItem != normalizedSlot.heldItem ||
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

  void _replaceTeamSlot(TeamSlot updatedSlot) {
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
    return CustomPokemonRuntimeRegistry.definitionFor(pokemonId)?.toPokemon();
  }

  EvolutionFormAliasCatalog _buildAliasCatalog() {
    final result = _aliasService.build(
      currentBasePokemon: _basePokemon,
      slot: _slot,
      catalog: widget.allPokemon,
    );
    PokemonEvolutionAliasRegistry.replace(result.bySyntheticId);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return legacy.PokemonDetailScreen(
      key: ValueKey<String>(
        '$_detailGeneration|${_slot?.pokemonId}|${_slot?.effectiveFormName ?? 'base'}|${_slot?.gender ?? 'none'}|${_slot?.isShiny ?? false}',
      ),
      pokemon: _basePokemon,
      teamSlot: _slot,
      allPokemon: _aliasCatalog.pokemon,
      team: _team,
      onTeamSlotChanged: _handleSlotChanged,
    );
  }
}
