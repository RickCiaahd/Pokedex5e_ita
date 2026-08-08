export 'pokemon_form_localization_legacy.dart' show PokemonFormLocalizedText;

import '../models/pokemon.dart';
import 'game_catalog_locale.dart';
import 'pokemon_form_display_name.dart';
import 'pokemon_form_display_name_extras.dart';
import 'pokemon_form_localization_legacy.dart' as legacy;

/// Compatibility facade that keeps regional form metadata in the historical
/// implementation while centralizing every visible form name in one complete
/// Italian label catalog.
class PokemonFormLocalization {
  const PokemonFormLocalization._();

  static String formLabel(Pokemon pokemon, String? formName) {
    final extra = PokemonFormDisplayNameExtras.label(pokemon, formName);
    if (extra != null) return extra;

    final label = PokemonFormDisplayName.label(pokemon, formName);
    if (!GameCatalogLocale.isItalian) return label;

    // Keep the compact labels already used by the Pokédex for generic base
    // and regional forms. Species with a real named base form (Oricorio,
    // Shaymin, Hoopa, etc.) are resolved before reaching these fallbacks.
    return switch (label) {
      'Forma base' => 'Base',
      'Forma di Alola' => 'Alola',
      'Forma di Galar' => 'Galar',
      'Forma di Hisui' => 'Hisui',
      'Forma di Paldea' => 'Paldea',
      _ => label,
    };
  }

  static String evolutionName(String value) =>
      legacy.PokemonFormLocalization.evolutionName(value);

  static legacy.PokemonFormLocalizedText? textFor(Pokemon pokemon) =>
      legacy.PokemonFormLocalization.textFor(pokemon);

  static legacy.PokemonFormLocalizedText? italianTextForAssetSlug(
    String rawSlug, {
    required String speciesName,
  }) => legacy.PokemonFormLocalization.italianTextForAssetSlug(
    rawSlug,
    speciesName: speciesName,
  );

  static bool hasSpecificItalianTextForAssetSlug(String rawSlug) =>
      legacy.PokemonFormLocalization.hasSpecificItalianTextForAssetSlug(rawSlug);

  static bool isRegionalAssetSlug(String rawSlug) =>
      legacy.PokemonFormLocalization.isRegionalAssetSlug(rawSlug);

  static String? regionForAssetSlug(String rawSlug) =>
      legacy.PokemonFormLocalization.regionForAssetSlug(rawSlug);
}
