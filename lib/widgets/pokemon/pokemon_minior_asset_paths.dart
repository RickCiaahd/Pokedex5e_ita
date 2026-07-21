import '../../models/pokemon.dart';

/// Resolves Minior's Meteor Form and seven aesthetic Core colours.
///
/// The Meteor Form always uses its dedicated folder, so it can never fall back
/// to a Core image. All Core colours share the same rules and statistics.
class PokemonMiniorAssetPaths {
  const PokemonMiniorAssetPaths._();

  static const String _meteorFolder =
      'assets/textures/textures_webapp/pokemon/minior-meteor-form';
  static const String _coreFolder =
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
    final primary = useLargeArtwork ? 'main' : 'sprite';
    final secondary = useLargeArtwork ? 'sprite' : 'main';

    if (_isMeteor(raw)) {
      return _standardFolderCandidates(
        folder: _meteorFolder,
        primary: primary,
        secondary: secondary,
        isShiny: isShiny,
      );
    }

    final color = _coreColor(raw);
    if (color == null) return const [];

    final result = <String>[];

    void add(String value) {
      if (!result.contains(value)) result.add(value);
    }

    if (isShiny) {
      add('$_coreFolder/$primary-$color-shiny.png');
      add('$_coreFolder/$secondary-$color-shiny.png');
      add('$_coreFolder/$primary-shiny.png');
      add('$_coreFolder/$secondary-shiny.png');
    }

    add('$_coreFolder/$primary-$color.png');
    add('$_coreFolder/$secondary-$color.png');
    add('$_coreFolder/$primary.png');
    add('$_coreFolder/$secondary.png');
    return result;
  }

  static List<String> _standardFolderCandidates({
    required String folder,
    required String primary,
    required String secondary,
    required bool isShiny,
  }) {
    return <String>[
      if (isShiny) '$folder/$primary-shiny.png',
      if (isShiny) '$folder/$secondary-shiny.png',
      '$folder/$primary.png',
      '$folder/$secondary.png',
    ];
  }

  static bool _isMeteor(String raw) {
    return raw == 'base' || raw == 'meteor' || raw == 'meteor-form';
  }

  static String? _coreColor(String raw) {
    if (raw == 'core' || raw == 'core-form') return 'red';
    if (!raw.startsWith('core-')) return null;

    final color = raw.substring('core-'.length);
    return _colors.contains(color) ? color : null;
  }
}
