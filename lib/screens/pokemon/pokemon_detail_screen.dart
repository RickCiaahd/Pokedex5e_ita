import 'package:flutter/material.dart';

import '../../models/pokemon.dart';
import '../../models/pokemon_evolution_alias_registry.dart';
import '../../models/team_slot.dart';
import '../../services/evolution_form_alias_service.dart';
import 'pokemon_detail_screen_legacy.dart' as legacy;

/// Compatibility shell around the full detail screen.
///
/// Evolution data can reference a concrete form (for example
/// `alolan-raichu`) even though owned Pokémon are persisted as a Pokédex
/// species id plus [TeamSlot.formName]. The full detail screen resolves an
/// evolution by display name, so this shell exposes temporary catalog aliases
/// and translates them back to the canonical species/form pair before
/// anything is persisted.
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
    if (alias == null) {
      final previous = _slot;
      final visualIdentityChanged =
          previous?.pokemonId != updatedSlot.pokemonId ||
          previous?.formName != updatedSlot.formName ||
          previous?.gender != updatedSlot.gender ||
          previous?.isShiny != updatedSlot.isShiny;

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
        '$_detailGeneration|${_slot?.pokemonId}|${_slot?.formName ?? 'base'}|${_slot?.gender ?? 'none'}|${_slot?.isShiny ?? false}',
      ),
      pokemon: _basePokemon,
      teamSlot: _slot,
      allPokemon: _aliasCatalog.pokemon,
      team: _team,
      onTeamSlotChanged: _handleSlotChanged,
    );
  }
}
