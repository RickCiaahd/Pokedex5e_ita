import '../models/pokemon.dart';
import '../models/pokemon_evolution_alias_registry.dart';
import '../models/team_slot.dart';

class EvolutionFormAliasCatalog {
  const EvolutionFormAliasCatalog({
    required this.pokemon,
    required this.bySyntheticId,
  });

  final List<Pokemon> pokemon;
  final Map<int, PokemonEvolutionAlias> bySyntheticId;
}

/// Adapts form-specific evolution targets to the catalog contract used by the
/// existing detail screen.
///
/// Synthetic ids are negative and exist only while the evolution UI is open.
/// They are translated back to a canonical Pokédex id plus `formName` before a
/// [TeamSlot] is saved.
class EvolutionFormAliasService {
  const EvolutionFormAliasService();

  static const _regionalForms = {
    'alolan',
    'galarian',
    'hisuian',
    'paldean',
  };

  EvolutionFormAliasCatalog build({
    required Pokemon currentBasePokemon,
    required TeamSlot? slot,
    required List<Pokemon> catalog,
  }) {
    final bySyntheticId = <int, PokemonEvolutionAlias>{};
    final preferredRegionalAliases = <Pokemon>[];
    final explicitAliases = <Pokemon>[];
    final currentRegionalKey = _currentRegionalFormKey(
      currentBasePokemon: currentBasePokemon,
      slot: slot,
    );

    for (final basePokemon in catalog) {
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
        bySyntheticId[syntheticId] = PokemonEvolutionAlias(
          basePokemon: basePokemon,
          formName: formName,
        );

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

    return EvolutionFormAliasCatalog(
      pokemon: [
        ...preferredRegionalAliases,
        ...explicitAliases,
        ...catalog,
      ],
      bySyntheticId: Map<int, PokemonEvolutionAlias>.unmodifiable(
        bySyntheticId,
      ),
    );
  }

  String? _currentRegionalFormKey({
    required Pokemon currentBasePokemon,
    required TeamSlot? slot,
  }) {
    if (slot == null) return null;
    final key = Pokemon.formReferenceKey(
      slot.formName ?? '',
      currentBasePokemon.name,
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
}
