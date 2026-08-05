import '../models/pokemon.dart';
import 'game_catalog_locale.dart';

/// Visible labels for persisted/technical Pokémon forms.
///
/// Technical form names stay unchanged in saves and asset lookup. This class
/// only translates what the user sees.
class PokemonFormLocalization {
  const PokemonFormLocalization._();

  static String formLabel(Pokemon pokemon, String? formName) {
    final raw = formName?.trim() ?? '';
    final key = Pokemon.formReferenceKey(raw, pokemon.name);

    if (!GameCatalogLocale.isItalian) {
      if (key == 'base') return 'Base form';
      return raw.isEmpty ? 'Base form' : raw;
    }

    if (pokemon.id == 999) {
      if (key == 'base') return 'Scrigno';
      if (key == 'roaming') return 'Ambulante';
    }

    switch (key) {
      case 'base':
        return 'Forma base';
      case 'alolan':
        return 'Forma di Alola';
      case 'galarian':
        return 'Forma di Galar';
      case 'hisuian':
        return 'Forma di Hisui';
      case 'paldean':
        return 'Forma di Paldea';
      default:
        return raw.isEmpty ? 'Forma base' : raw;
    }
  }

  static String evolutionName(String value) {
    final trimmed = value.trim();
    if (!GameCatalogLocale.isItalian || trimmed.isEmpty) return trimmed;

    final regional = RegExp(
      r'^(Alolan|Galarian|Hisuian|Paldean)\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (regional != null) {
      final region = switch (regional.group(1)!.toLowerCase()) {
        'alolan' => 'Alola',
        'galarian' => 'Galar',
        'hisuian' => 'Hisui',
        'paldean' => 'Paldea',
        _ => regional.group(1)!,
      };
      return '${regional.group(2)} di $region';
    }

    final gendered = RegExp(r'^(.+)\s+([MF])$').firstMatch(trimmed);
    if (gendered != null) {
      return '${gendered.group(1)} ${gendered.group(2) == 'M' ? '♂' : '♀'}';
    }

    return trimmed;
  }
}
