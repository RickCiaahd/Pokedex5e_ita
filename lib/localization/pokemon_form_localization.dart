export 'pokemon_form_localization_legacy.dart' show PokemonFormLocalizedText;

import '../models/pokemon.dart';
import 'pokemon_form_display_name.dart';
import 'pokemon_form_localization_legacy.dart' as legacy;

/// Compatibility facade that keeps regional form metadata in the historical
/// implementation while centralizing every visible form name in one complete
/// Italian label catalog.
class PokemonFormLocalization {
  const PokemonFormLocalization._();

  static String formLabel(Pokemon pokemon, String? formName) =>
      PokemonFormDisplayName.label(pokemon, formName);

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
