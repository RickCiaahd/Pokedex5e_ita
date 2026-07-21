import '../../models/pokemon.dart';

/// Builds bundled asset candidates for visible male/female differences.
///
/// Gender remains a property of the caught Pokémon and is not exposed as a
/// Pokédex form. Files live directly inside the already registered species (or
/// permanent-form) folder, so adding them does not require a pubspec update.
class PokemonGenderAssetPaths {
  const PokemonGenderAssetPaths._();

  static const String _root = 'assets/textures/textures_webapp/pokemon';

  static List<String> candidates({
    required Pokemon pokemon,
    required bool useLargeArtwork,
    String? formName,
    String? gender,
    bool isShiny = false,
  }) {
    final genderSlugs = _genderSlugs(gender);
    if (genderSlugs.isEmpty) return const [];

    final primary = useLargeArtwork ? 'main' : 'sprite';
    final secondary = useLargeArtwork ? 'sprite' : 'main';
    final folders = _folderCandidates(pokemon, formName);
    final paths = <String>[];

    void add(String value) {
      if (!paths.contains(value)) paths.add(value);
    }

    for (final folder in folders) {
      for (final genderSlug in genderSlugs) {
        if (isShiny) {
          for (final basename in [primary, secondary]) {
            add('$folder/$basename-shiny-$genderSlug.png');
            add('$folder/$basename-$genderSlug-shiny.png');
            add('$folder/${basename}_shiny_$genderSlug.png');
            add('$folder/${basename}_${genderSlug}_shiny.png');
          }
        }

        // When the shiny texture for the selected sex is missing, prefer the
        // normal texture with the correct silhouette over a generic shiny one.
        for (final basename in [primary, secondary]) {
          add('$folder/$basename-$genderSlug.png');
          add('$folder/${basename}_$genderSlug.png');
        }
      }
    }

    return paths;
  }

  static List<String> _folderCandidates(Pokemon pokemon, String? formName) {
    final folders = <String>[];
    final speciesSlugs = <String>{
      _slug(pokemon.name),
      if (pokemon.assetSlug?.trim().isNotEmpty == true)
        _slug(pokemon.assetSlug!),
    }..removeWhere((value) => value.isEmpty);

    final formKey = Pokemon.formReferenceKey(formName ?? '', pokemon.name);
    final formSlugs = _formSlugs(formKey);

    void addFolder(String value) {
      if (value.isNotEmpty && !folders.contains(value)) folders.add(value);
    }

    for (final formSlug in formSlugs) {
      for (final speciesSlug in speciesSlugs) {
        addFolder('$_root/$speciesSlug-$formSlug');
        addFolder('$_root/$formSlug-$speciesSlug');
        addFolder('$_root/$speciesSlug/$formSlug');
      }
    }

    for (final speciesSlug in speciesSlugs) {
      addFolder('$_root/$speciesSlug');
    }

    return folders;
  }

  static List<String> _formSlugs(String formKey) {
    if (formKey.isEmpty || formKey == 'base') return const [];

    final slug = _slug(formKey);
    final values = <String>[slug];

    void add(String value) {
      if (value.isNotEmpty && !values.contains(value)) values.add(value);
    }

    if (slug.contains('hisuian')) add(slug.replaceAll('hisuian', 'hisui'));
    if (slug.contains('hisui')) add(slug.replaceAll('hisui', 'hisuian'));
    if (slug.contains('galarian')) add(slug.replaceAll('galarian', 'galar'));
    if (slug.contains('galar')) add(slug.replaceAll('galar', 'galarian'));
    if (slug.contains('alolan')) add(slug.replaceAll('alolan', 'alola'));
    if (slug.contains('alola')) add(slug.replaceAll('alola', 'alolan'));
    if (slug.contains('paldean')) add(slug.replaceAll('paldean', 'paldea'));
    if (slug.contains('paldea')) add(slug.replaceAll('paldea', 'paldean'));

    return values;
  }

  static List<String> _genderSlugs(String? gender) {
    switch (gender?.trim().toLowerCase()) {
      case 'male':
      case 'm':
      case 'maschio':
        return const ['m', 'male'];
      case 'female':
      case 'f':
      case 'femmina':
        return const ['f', 'female'];
      default:
        return const [];
    }
  }

  static String _slug(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(' ♀', '-f')
        .replaceAll('♀', '-f')
        .replaceAll(' ♂', '-m')
        .replaceAll('♂', '-m')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
}
