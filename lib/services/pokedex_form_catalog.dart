import '../models/pokedex_entry.dart';
import '../models/pokemon.dart';

class PokedexFormOption {
  const PokedexFormOption({
    required this.key,
    required this.name,
    required this.formName,
    required this.pokemon,
    required this.aliases,
    required this.isBase,
  });

  final String key;
  final String name;
  final String? formName;
  final Pokemon pokemon;
  final Set<String> aliases;
  final bool isBase;

  PokedexFormEntry statusFor(PokedexEntry entry) {
    return entry.formForAliases(aliases, fallbackName: name);
  }
}

class PokedexFormCatalog {
  const PokedexFormCatalog._();

  static List<PokedexFormOption> optionsFor(Pokemon pokemon) {
    final byKey = <String, PokedexFormOption>{
      PokedexEntry.baseFormKey: PokedexFormOption(
        key: PokedexEntry.baseFormKey,
        name: 'Base',
        formName: null,
        pokemon: pokemon,
        aliases: const {PokedexEntry.baseFormKey},
        isBase: true,
      ),
    };

    for (final definition in pokemon.formDefinitions) {
      if (definition.gender != null || _isTemporary(pokemon, definition)) {
        continue;
      }

      final formName = definition.displayName.trim().isEmpty
          ? definition.key.trim()
          : definition.displayName.trim();
      final canonicalKey = Pokemon.formReferenceKey(formName, pokemon.name);
      if (canonicalKey.isEmpty || canonicalKey == PokedexEntry.baseFormKey) {
        continue;
      }

      final aliases = <String>{
        canonicalKey,
        PokedexEntry.normalizeFormKey(definition.key),
        PokedexEntry.normalizeFormKey(definition.displayName),
        PokedexEntry.normalizeFormKey(formName),
      }..removeWhere((value) => value.isEmpty);

      byKey.putIfAbsent(
        canonicalKey,
        () => PokedexFormOption(
          key: canonicalKey,
          name: _shortLabel(pokemon, formName),
          formName: formName,
          pokemon: definition.pokemon.copyWith(
            id: pokemon.id,
            name: pokemon.name,
            formDefinitions: pokemon.formDefinitions,
          ),
          aliases: Set<String>.unmodifiable(aliases),
          isBase: false,
        ),
      );
    }

    final options = byKey.values.toList(growable: false)
      ..sort((a, b) {
        if (a.isBase != b.isBase) return a.isBase ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return options;
  }

  static PokedexFormOption preferredFor(
    Pokemon pokemon,
    PokedexEntry entry,
  ) {
    final options = optionsFor(pokemon);
    var preferred = options.first;
    var preferredScore = -1;

    for (final option in options) {
      final status = option.statusFor(entry);
      final score = status.caught
          ? 2
          : status.seen
              ? 1
              : 0;

      if (score > preferredScore ||
          (score == preferredScore && option.isBase && !preferred.isBase)) {
        preferred = option;
        preferredScore = score;
      }
    }

    return preferred;
  }

  static bool _isTemporary(
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

  static String _shortLabel(Pokemon pokemon, String formName) {
    var label = formName.trim();
    final species = pokemon.name.trim();
    if (species.isNotEmpty) {
      label = label
          .replaceAll(
            RegExp(RegExp.escape(species), caseSensitive: false),
            ' ',
          )
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }

    return label.isEmpty ? formName : label;
  }
}
