from pathlib import Path


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding="utf-8")
    if old not in text:
        raise RuntimeError(f"Expected block not found in {path}: {old[:120]!r}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")


path = Path("lib/widgets/pokemon/pokemon_asset_image.dart")

replace_once(
    path,
    """      if (choice == null || _isBaseSpriteLabel(choice.name)) continue;
      choicesByName.putIfAbsent(choice.name, () => choice);
    }

    for (final choice in await _variantMapFormChoices(pokemon)) {
      choicesByName.putIfAbsent(choice.name, () => choice);
    }

    final choices = choicesByName.values.toList(growable: false)
      ..sort(_compareFormChoices);
    return choices;
""",
    """      if (choice == null ||
          _isBaseSpriteLabel(choice.name) ||
          _isGenderOnlyLabel(choice.name)) {
        continue;
      }
      choicesByName.putIfAbsent(choice.name, () => choice);
    }

    for (final choice in await _variantMapFormChoices(pokemon)) {
      if (_isGenderOnlyLabel(choice.name)) continue;
      choicesByName.putIfAbsent(choice.name, () => choice);
    }

    if (choicesByName.isEmpty) return const [];

    final choices = choicesByName.values.toList(growable: false)
      ..sort(_compareFormChoices);
    return [
      const PokemonFormChoice(name: 'Base', assetPath: ''),
      ...choices,
    ];
""",
)

replace_once(
    path,
    """  static List<String> imageCandidatePrefixes({
    required Pokemon pokemon,
    required bool useLargeArtwork,
    String? formName,
    String? gender,
  }) {
    final folder = useLargeArtwork ? 'pokemons' : 'sprites';
    final alternateFolder = useLargeArtwork ? 'sprites' : 'pokemons';
    final id = pokemon.id.toString();
    final paddedId = id.padLeft(3, '0');
    final prefixes = <String>[];

    void add(String value) {
      if (!prefixes.contains(value)) prefixes.add(value);
    }

    for (final slug in _webCandidateSlugs(pokemon)) {
      add('$_webPokemonRoot/$slug/');
      add('$_webPokemonRoot/$slug-');
      add('$_webPokemonRoot/${slug}_');
      for (final transform in _transformFolders) {
        add('$_webTransformRoot/$transform/$slug/');
        add('$_webTransformRoot/$transform/$slug-');
        add('$_webTransformRoot/$transform/${slug}_');
      }
    }

    for (final formSlug in _formSlugs(pokemon, formName, gender)) {
      for (final slug in _webCandidateSlugs(pokemon)) {
        add('$_webPokemonRoot/$slug-$formSlug/');
        add('$_webPokemonRoot/${slug}_$formSlug/');
        add('$_webPokemonRoot/$slug/$formSlug/');
      }
    }

    add('assets/textures/$folder/$id');
    add('assets/textures/$folder/$paddedId');
    add('assets/textures/$alternateFolder/$id');
    add('assets/textures/$alternateFolder/$paddedId');

    return prefixes;
  }
""",
    """  static List<String> imageCandidatePrefixes({
    required Pokemon pokemon,
    required bool useLargeArtwork,
    String? formName,
    String? gender,
  }) {
    final folder = useLargeArtwork ? 'pokemons' : 'sprites';
    final alternateFolder = useLargeArtwork ? 'sprites' : 'pokemons';
    final id = pokemon.id.toString();
    final paddedId = id.padLeft(3, '0');
    final prefixes = <String>[];
    final candidateSlugs = _webCandidateSlugs(pokemon);
    final formSlugs = _formSlugs(pokemon, formName, gender);

    void add(String value) {
      if (!prefixes.contains(value)) prefixes.add(value);
    }

    for (final formSlug in formSlugs) {
      for (final slug in candidateSlugs) {
        add('$_webPokemonRoot/$slug-$formSlug/');
        add('$_webPokemonRoot/${slug}_$formSlug/');
        add('$_webPokemonRoot/$slug/$formSlug/');
        for (final transform in _transformFolders) {
          add('$_webTransformRoot/$transform/$slug-$formSlug/');
          add('$_webTransformRoot/$transform/${slug}_$formSlug/');
          add('$_webTransformRoot/$transform/$slug/$formSlug/');
        }
      }
    }

    for (final slug in candidateSlugs) {
      add('$_webPokemonRoot/$slug/');
      for (final transform in _transformFolders) {
        add('$_webTransformRoot/$transform/$slug/');
      }
    }

    if (formSlugs.isEmpty) {
      for (final slug in candidateSlugs) {
        add('$_webPokemonRoot/$slug-');
        add('$_webPokemonRoot/${slug}_');
        for (final transform in _transformFolders) {
          add('$_webTransformRoot/$transform/$slug-');
          add('$_webTransformRoot/$transform/${slug}_');
        }
      }
    }

    add('assets/textures/$folder/$id');
    add('assets/textures/$folder/$paddedId');
    add('assets/textures/$alternateFolder/$id');
    add('assets/textures/$alternateFolder/$paddedId');

    return prefixes;
  }
""",
)

replace_once(
    path,
    """.where((name) => name.isNotEmpty && !_isBaseSpriteLabel(name))
""",
    """.where(
            (name) =>
                name.isNotEmpty &&
                !_isBaseSpriteLabel(name) &&
                !_isGenderOnlyLabel(name),
          )
""",
)

replace_once(
    path,
    """  static String _cleanVariantLabel(Pokemon pokemon, String value) {
    var label = value.trim();
    final pokemonName = pokemon.name.trim();
    if (label.toLowerCase().startsWith(pokemonName.toLowerCase())) {
      label = label.substring(pokemonName.length).trim();
    }
    label = label.replaceFirst(RegExp(r'^[-_:(\s]+'), '').trim();
    label = label.replaceFirst(RegExp(r'[)]+$'), '').trim();
    return label.isEmpty ? 'Base' : _cleanFormLabel(label);
  }
""",
    """  static String _cleanVariantLabel(Pokemon pokemon, String value) {
    var label = value.trim();
    final pokemonName = pokemon.name.trim();
    if (pokemonName.isNotEmpty) {
      label = label.replaceAll(
        RegExp(RegExp.escape(pokemonName), caseSensitive: false),
        ' ',
      );
    }
    label = label.replaceFirst(RegExp(r'^[-_:(\s]+'), '').trim();
    label = label.replaceFirst(RegExp(r'[)]+$'), '').trim();
    return label.isEmpty ? 'Base' : _cleanFormLabel(label);
  }
""",
)

replace_once(
    path,
    """    final form = formName?.trim();
    if (form == null || form.isEmpty) return const {};

    final aliases = _nameAliases(rawName);
""",
    """    final form = formName?.trim();
    if (form == null ||
        form.isEmpty ||
        _isBaseSpriteLabel(form) ||
        _isGenderOnlyLabel(form)) {
      return const {};
    }

    final aliases = _nameAliases(rawName);
""",
)

replace_once(
    path,
    """  static List<String> _formSlugs(Pokemon pokemon, String? formName, String? gender) {
    final result = <String>[];

    void add(String value) {
      final slug = _webSlug(value);
      if (slug.isNotEmpty && !result.contains(slug)) result.add(slug);
    }

    for (final slug in _genderSlugs(gender)) {
      add(slug);
    }

    final form = formName?.trim();
    if (form != null && form.isNotEmpty) {
      final pokemonName = pokemon.name.trim();
      var shortForm = form;
      if (shortForm.toLowerCase().startsWith(pokemonName.toLowerCase())) {
        shortForm = shortForm.substring(pokemonName.length).trim();
      }
      shortForm = _cleanFormLabel(shortForm);

      add(form);
      if (shortForm.isNotEmpty) add(shortForm);
      add('$pokemonName $form');
      if (shortForm.isNotEmpty) add('$pokemonName $shortForm');

      for (final alias in _genderSlugs(form)) {
        add(alias);
      }
    }

    return result;
  }
""",
    """  static List<String> _formSlugs(
    Pokemon pokemon,
    String? formName,
    String? gender,
  ) {
    final result = <String>[];

    void add(String value) {
      final slug = _webSlug(value);
      if (slug.isNotEmpty && !result.contains(slug)) result.add(slug);
    }

    final form = formName?.trim();
    if (form != null &&
        form.isNotEmpty &&
        !_isBaseSpriteLabel(form) &&
        !_isGenderOnlyLabel(form)) {
      final cleanedForm = _cleanFormLabel(form);
      final shortForm = _removePokemonName(cleanedForm, pokemon.name);
      final strippedForm = _stripGenericFormWords(shortForm);

      add(cleanedForm);
      add(shortForm);
      add(strippedForm);

      for (final alias in _regionalAliases(shortForm)) {
        add(alias);
      }
      for (final alias in _regionalAliases(strippedForm)) {
        add(alias);
      }
    }

    for (final slug in _genderSlugs(gender)) {
      add(slug);
    }

    return result;
  }
""",
)

replace_once(
    path,
    """  static int _formSortWeight(String label) {
    final value = label.toLowerCase().trim();
    if (value == 'male' || value == 'm' || value == 'maschio') return 0;
    if (value == 'female' || value == 'f' || value == 'femmina') return 1;
    if (value == 'amped') return 0;
    return 10;
  }
""",
    """  static int _formSortWeight(String label) {
    final value = label.toLowerCase().trim();
    if (value == 'amped') return 0;
    return 10;
  }
""",
)

replace_once(
    path,
    """  static bool _isBaseSpriteLabel(String label) {
    switch (label.toLowerCase().trim()) {
      case 'main':
      case 'sprite':
      case 'main shiny':
      case 'sprite shiny':
      case 'shiny':
      case 'base':
      case 'default':
        return true;
      default:
        return false;
    }
  }
""",
    """  static bool _isGenderOnlyLabel(String label) {
    switch (label.toLowerCase().trim()) {
      case 'male':
      case 'm':
      case 'maschio':
      case 'female':
      case 'f':
      case 'femmina':
        return true;
      default:
        return false;
    }
  }

  static String _removePokemonName(String value, String pokemonName) {
    final cleanName = pokemonName.trim();
    if (cleanName.isEmpty) return _cleanFormLabel(value);

    return _cleanFormLabel(
      value.replaceAll(
        RegExp(RegExp.escape(cleanName), caseSensitive: false),
        ' ',
      ),
    );
  }

  static String _stripGenericFormWords(String value) {
    return _cleanFormLabel(
      value.replaceAll(
        RegExp(r'\b(form|forme|style|mode)\b', caseSensitive: false),
        ' ',
      ),
    );
  }

  static List<String> _regionalAliases(String value) {
    final lower = value.toLowerCase();
    final aliases = <String>[];

    void add(String alias) {
      if (alias.isNotEmpty && !aliases.contains(alias)) aliases.add(alias);
    }

    if (lower.contains('alolan')) {
      add(lower.replaceAll('alolan', 'alola'));
      add('alola');
      add('alolan');
    }
    if (lower.contains('galarian')) {
      add(lower.replaceAll('galarian', 'galar'));
      add('galar');
      add('galarian');
    }
    if (lower.contains('hisuian')) {
      add(lower.replaceAll('hisuian', 'hisui'));
      add('hisui');
      add('hisuian');
    }
    if (lower.contains('paldean')) {
      add(lower.replaceAll('paldean', 'paldea'));
      add('paldea');
      add('paldean');
    }

    return aliases;
  }

  static bool _isBaseSpriteLabel(String label) {
    switch (label.toLowerCase().trim()) {
      case 'main':
      case 'sprite':
      case 'main shiny':
      case 'sprite shiny':
      case 'shiny':
      case 'base':
      case 'default':
      case 'forma base':
        return true;
      default:
        return false;
    }
  }
""",
)

print("Patched Pokemon asset and form resolver.")
