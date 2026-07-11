import 'package:flutter/material.dart';

import '../../models/pokemon.dart';
import '../../models/team_slot.dart';
import 'pokemon_detail_screen_legacy.dart' as legacy;

/// Compatibility shell around the full detail screen.
///
/// Evolution data can reference a concrete form (for example
/// `alolan-raichu`) even though owned Pokémon are persisted as a Pokédex
/// species id plus [TeamSlot.formName]. The legacy detail screen resolves an
/// evolution by display name only, so this shell exposes temporary catalog
/// aliases and translates them back to the canonical species/form pair before
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
  static const _regionalForms = {
    'alolan',
    'galarian',
    'hisuian',
    'paldean',
  };

  late Pokemon _basePokemon;
  late TeamSlot? _slot;
  late List<TeamSlot> _team;
  late _EvolutionAliasCatalog _aliasCatalog;
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
      _slot = updatedSlot;
      _replaceTeamSlot(updatedSlot);
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

  _EvolutionAliasCatalog _buildAliasCatalog() {
    final bySyntheticId = <int, _EvolutionFormAlias>{};
    final preferredRegionalAliases = <Pokemon>[];
    final explicitAliases = <Pokemon>[];
    final currentRegionalKey = _currentRegionalFormKey();

    for (final basePokemon in widget.allPokemon) {
      for (var index = 0;
          index < basePokemon.formDefinitions.length;
          index += 1) {
        final definition = basePokemon.formDefinitions[index];
        if (definition.gender != null ||
            _isTemporaryTransformation(basePokemon, definition)) {
          continue;
        }

        final formName = definition.displayName.trim().isEmpty
            ? definition.key
            : definition.displayName;
        final formKey = Pokemon.formReferenceKey(
          formName,
          basePokemon.name,
        );
        if (formKey.isEmpty || formKey == 'base') continue;

        final syntheticId = _syntheticId(basePokemon.id, index);
        final alias = _EvolutionFormAlias(
          basePokemon: basePokemon,
          formName: formName,
        );
        bySyntheticId[syntheticId] = alias;

        final variant = definition.pokemon.copyWith(
          id: syntheticId,
          name: _explicitEvolutionName(basePokemon, definition),
          formDefinitions: basePokemon.formDefinitions,
        );
        explicitAliases.add(variant);

        if (currentRegionalKey != null && formKey == currentRegionalKey) {
          preferredRegionalAliases.add(
            variant.copyWith(name: basePokemon.name),
          );
        }
      }
    }

    return _EvolutionAliasCatalog(
      pokemon: [
        ...preferredRegionalAliases,
        ...explicitAliases,
        ...widget.allPokemon,
      ],
      bySyntheticId: bySyntheticId,
    );
  }

  String? _currentRegionalFormKey() {
    final slot = _slot;
    if (slot == null) return null;
    final key = Pokemon.formReferenceKey(
      slot.formName ?? '',
      _basePokemon.name,
    );
    return _regionalForms.contains(key) ? key : null;
  }

  bool _isTemporaryTransformation(
    Pokemon pokemon,
    PokemonFormDefinition definition,
  ) {
    final key = Pokemon.formReferenceKey(
      '${definition.key} ${definition.displayName}',
      pokemon.name,
    );
    final tokens = key.split('-').toSet();
    return tokens.contains('mega') ||
        tokens.contains('dynamax') ||
        tokens.contains('gigamax') ||
        tokens.contains('gigantamax') ||
        tokens.contains('gmax') ||
        tokens.contains('terastal') ||
        tokens.contains('tera');
  }

  String _explicitEvolutionName(
    Pokemon pokemon,
    PokemonFormDefinition definition,
  ) {
    final formName = definition.displayName.trim().isEmpty
        ? definition.key.trim()
        : definition.displayName.trim();
    if (formName.isEmpty) return pokemon.name;

    final formKey = _referenceKey(formName);
    final speciesKey = _referenceKey(pokemon.name);
    if (formKey == speciesKey ||
        formKey.startsWith('$speciesKey-') ||
        formKey.endsWith('-$speciesKey')) {
      return formName;
    }
    return '$formName ${pokemon.name}';
  }

  int _syntheticId(int pokemonId, int formIndex) {
    return -((pokemonId * 1000) + formIndex + 1);
  }

  String _referenceKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r"[’']"), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    return legacy.PokemonDetailScreen(
      key: ValueKey<int>(_detailGeneration),
      pokemon: _basePokemon,
      teamSlot: _slot,
      allPokemon: _aliasCatalog.pokemon,
      team: _team,
      onTeamSlotChanged: _handleSlotChanged,
    );
  }
}

class _EvolutionAliasCatalog {
  const _EvolutionAliasCatalog({
    required this.pokemon,
    required this.bySyntheticId,
  });

  final List<Pokemon> pokemon;
  final Map<int, _EvolutionFormAlias> bySyntheticId;
}

class _EvolutionFormAlias {
  const _EvolutionFormAlias({
    required this.basePokemon,
    required this.formName,
  });

  final Pokemon basePokemon;
  final String formName;
}
