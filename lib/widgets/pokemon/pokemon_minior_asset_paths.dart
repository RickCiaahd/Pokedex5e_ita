import '../../models/pokemon.dart';

/// Resolves Minior's seven aesthetic Core colours from the single bundled
/// `minior-core` directory. All colours share the same rules and statistics.
class PokemonMiniorAssetPaths {
  const PokemonMiniorAssetPaths._();

  static const String _folder =
      'assets/textures/textures_webapp/pokemon/minior-core';
  static const Set<String> _colors = {
    'red',
    'orange',
    'yellow',
    'green',
    'blue',
    'indigo',
    'violet',
  };

  static List<String> candidates({
    required Pokemon pokemon,
    required bool useLargeArtwork,
    String? formName,
    bool isShiny = false,
  }) {
    if (pokemon.name != 'Minior') return const [];

    final raw = Pokemon.formReferenceKey(formName ?? '', pokemon.name);
    final color = _coreColor(raw);
    if (color == null) return const [];

    final primary = useLargeArtwork ? 'main' : 'sprite';
    final secondary = useLargeArtwork ? 'sprite' : 'main';
    final result = <String>[];

    void add(String value) {
      if (!result.contains(value)) result.add(value);
    }

    if (isShiny) {
      add('$_folder/$primary-$color-shiny.png');
      add('$_folder/$secondary-$color-shiny.png');
      add('$_folder/$primary-shiny.png');
      add('$_folder/$secondary-shiny.png');
    }

    add('$_folder/$primary-$color.png');
    add('$_folder/$secondary-$color.png');
    add('$_folder/$primary.png');
    add('$_folder/$secondary.png');
    return result;
  }

  static String? _coreColor(String raw) {
    if (raw == 'core' || raw == 'core-form') return 'red';
    if (!raw.startsWith('core-')) return null;

    final color = raw.substring('core-'.length);
    return _colors.contains(color) ? color : null;
  }
}
