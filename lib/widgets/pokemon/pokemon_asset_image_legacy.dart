import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/pokedex_entry.dart';
import '../../localization/game_catalog_locale.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_form_preferences.dart';

class PokemonFormChoice {
  const PokemonFormChoice({required this.name, required this.assetPath});

  final String name;
  final String assetPath;
}

class PokemonAssetImage extends StatelessWidget {
  const PokemonAssetImage({
    super.key,
    required this.pokemon,
    this.size = 72,
    this.fit = BoxFit.contain,
    this.useLargeArtwork = false,
    this.entry,
    this.formName,
    this.gender,
    this.isShiny,
    this.fallback,
  });

  final Pokemon pokemon;
  final double size;
  final BoxFit fit;
  final bool useLargeArtwork;
  final PokedexEntry? entry;
  final String? formName;
  final String? gender;
  final bool? isShiny;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final entry = this.entry;
    final seen = entry?.seen ?? true;
    final caught = entry?.caught ?? true;
    final effectiveFormName =
        formName ?? PokemonFormPreferences.formFor(pokemon.id);
    final effectiveGender =
        gender ?? PokemonFormPreferences.genderFor(pokemon.id);
    final effectiveShiny =
        isShiny ?? PokemonFormPreferences.shinyFor(pokemon.id);
    final visualScale = useLargeArtwork ? 1.08 : 1.12;

    Widget image = _AssetFallbackImage(
      assetPaths: PokemonAssetPaths.imageCandidates(
        pokemon: pokemon,
        useLargeArtwork: useLargeArtwork,
        formName: effectiveFormName,
        gender: effectiveGender,
        isShiny: effectiveShiny,
      ),
      assetPrefixes: PokemonAssetPaths.imageCandidatePrefixes(
        pokemon: pokemon,
        useLargeArtwork: useLargeArtwork,
        formName: effectiveFormName,
        gender: effectiveGender,
      ),
      width: size,
      height: size,
      fit: fit,
      fallback:
          fallback ??
          Icon(
            seen ? Icons.catching_pokemon : Icons.question_mark,
            size: size * 0.48,
            color: seen
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );

    if (!seen) {
      image = ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcATop),
        child: image,
      );
    } else if (!caught) {
      image = Opacity(
        opacity: 0.56,
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.2126,
            0.7152,
            0.0722,
            0,
            52,
            0.2126,
            0.7152,
            0.0722,
            0,
            52,
            0.2126,
            0.7152,
            0.0722,
            0,
            52,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: image,
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Transform.scale(scale: visualScale, child: image),
      ),
    );
  }
}

class PokemonTypeBadge extends StatelessWidget {
  const PokemonTypeBadge({
    super.key,
    required this.type,
    this.height = 24,
    this.fallbackTextStyle,
  });

  final String type;
  final double height;
  final TextStyle? fallbackTextStyle;

  @override
  Widget build(BuildContext context) {
    return _AssetFallbackImage(
      assetPaths: PokemonAssetPaths.typeCandidates(type),
      height: height,
      fit: BoxFit.contain,
      fallback: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            PokemonAssetPaths.localizedTypeLabel(type).toUpperCase(),
            style:
                fallbackTextStyle ??
                Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
      ),
    );
  }
}

class PokemonAssetPaths {
  const PokemonAssetPaths._();

  static const _webPokemonRoot = 'assets/textures/textures_webapp/pokemon';
  static const _webTransformRoot =
      'assets/textures/textures_webapp/pokemon_transforms';
  static const _transformFolders = ['mega', 'dynamax', 'gigamax', 'terastal'];

  static Future<List<PokemonFormChoice>> formChoices(Pokemon pokemon) async {
    final assetIndex = await _AssetLookup.assetIndex();
    final choicesByKey = <String, PokemonFormChoice>{};
    final prefixes = imageCandidatePrefixes(
      pokemon: pokemon,
      useLargeArtwork: false,
    );

    void addChoice(PokemonFormChoice choice) {
      final canonicalName = _canonicalFormLabel(pokemon, choice.name);
      if (canonicalName.isEmpty ||
          _isBaseSpriteLabel(canonicalName) ||
          _isGenderOnlyLabel(canonicalName) ||
          _isDefaultFormChoice(pokemon, canonicalName)) {
        return;
      }

      final key = _formIdentityKey(pokemon, canonicalName);
      if (key.isEmpty) return;

      final normalizedChoice = PokemonFormChoice(
        name: canonicalName,
        assetPath: choice.assetPath,
      );
      final current = choicesByKey[key];
      if (current == null ||
          (current.assetPath.isEmpty &&
              normalizedChoice.assetPath.isNotEmpty)) {
        choicesByKey[key] = normalizedChoice;
      }
    }

    for (final definition in pokemon.formDefinitions) {
      if (definition.gender != null) continue;
      addChoice(PokemonFormChoice(name: definition.displayName, assetPath: ''));
    }

    for (final assetPath in assetIndex.sortedPaths) {
      if (!_isSupportedImagePath(assetPath)) continue;
      if (!prefixes.any(
        (prefix) => _AssetLookup.matchesPrefix(assetPath, prefix),
      )) {
        continue;
      }

      final choice =
          _webFormChoiceFromAssetPath(pokemon, assetPath) ??
          _formChoiceFromAssetPath(pokemon, assetPath);
      if (choice != null) addChoice(choice);
    }

    for (final choice in await _variantMapFormChoices(pokemon)) {
      addChoice(choice);
    }

    if (choicesByKey.isEmpty) return const [];

    final choices = choicesByKey.values.toList(growable: false)
      ..sort(_compareFormChoices);
    return [const PokemonFormChoice(name: 'Base', assetPath: ''), ...choices];
  }

  static List<String> imageCandidates({
    required Pokemon pokemon,
    required bool useLargeArtwork,
    String? formName,
    String? gender,
    bool isShiny = false,
  }) {
    final canonicalFormName = formName == null
        ? null
        : _canonicalFormLabel(pokemon, formName);
    final hasSpecificForm =
        canonicalFormName != null &&
        canonicalFormName.isNotEmpty &&
        !_isBaseSpriteLabel(canonicalFormName) &&
        !_isGenderOnlyLabel(canonicalFormName);
    final hasSpecificGender = _genderSlugs(gender).isNotEmpty;
    final candidates = <String>[];

    void addAll(Iterable<String> values) {
      for (final value in values) {
        if (!candidates.contains(value)) candidates.add(value);
      }
    }

    if (hasSpecificForm || hasSpecificGender) {
      addAll(
        _webImageCandidates(
          pokemon: pokemon,
          useLargeArtwork: useLargeArtwork,
          formName: hasSpecificForm ? canonicalFormName : null,
          gender: gender,
          isShiny: isShiny,
          includeBaseFolders: false,
        ),
      );
      addAll(
        _legacyImageCandidates(
          pokemon: pokemon,
          useLargeArtwork: useLargeArtwork,
          formName: hasSpecificForm ? canonicalFormName : null,
          gender: gender,
          isShiny: isShiny,
          includeBaseAliases: false,
        ),
      );
    }

    addAll(
      _webImageCandidates(
        pokemon: pokemon,
        useLargeArtwork: useLargeArtwork,
        isShiny: isShiny,
      ),
    );
    addAll(
      _legacyImageCandidates(
        pokemon: pokemon,
        useLargeArtwork: useLargeArtwork,
        isShiny: isShiny,
      ),
    );

    return _preferModernImageFormats(candidates);
  }

  static List<String> _preferModernImageFormats(Iterable<String> candidates) {
    final resolved = <String>[];
    for (final candidate in candidates) {
      final isConvertible =
          candidate.endsWith('.png') &&
          (candidate.startsWith(_webPokemonRoot) ||
              candidate.startsWith(_webTransformRoot));
      if (isConvertible) {
        final webp = '${candidate.substring(0, candidate.length - 4)}.webp';
        if (!resolved.contains(webp)) resolved.add(webp);
      }
      if (!resolved.contains(candidate)) resolved.add(candidate);
    }
    return resolved;
  }

  static bool _isSupportedImagePath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.png') || lower.endsWith('.webp');
  }

  static List<String> imageCandidatePrefixes({
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
        add('$_webPokemonRoot/$formSlug-$slug/');
        add('$_webPokemonRoot/${formSlug}_$slug/');
        add('$_webPokemonRoot/$formSlug/$slug/');
        for (final transform in _transformFolders) {
          add('$_webTransformRoot/$transform/$slug-$formSlug/');
          add('$_webTransformRoot/$transform/${slug}_$formSlug/');
          add('$_webTransformRoot/$transform/$slug/$formSlug/');
          add('$_webTransformRoot/$transform/$formSlug-$slug/');
          add('$_webTransformRoot/$transform/${formSlug}_$slug/');
          add('$_webTransformRoot/$transform/$formSlug/$slug/');
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

  static List<String> _legacyImageCandidates({
    required Pokemon pokemon,
    required bool useLargeArtwork,
    String? formName,
    String? gender,
    bool isShiny = false,
    bool includeBaseAliases = true,
  }) {
    final folder = useLargeArtwork ? 'pokemons' : 'sprites';
    final alternateFolder = useLargeArtwork ? 'sprites' : 'pokemons';
    final id = pokemon.id.toString();
    final paddedId = id.padLeft(3, '0');
    final aliases = <String>{
      ..._formAwareAliases(pokemon.name, formName),
      ..._genderAwareAliases(pokemon.name, gender),
      if (includeBaseAliases) ..._nameAliases(pokemon.name),
    }..removeWhere((name) => name.isEmpty);
    final fileNames = <String>{};

    if (isShiny) {
      for (final name in aliases) {
        fileNames.addAll([
          '$id$name Shiny.png',
          '$paddedId$name Shiny.png',
          '$id${name}_shiny.png',
          '$paddedId${name}_shiny.png',
          '$name Shiny.png',
          '${name}_shiny.png',
          '${name.toLowerCase()}-shiny.png',
        ]);
      }
      if (includeBaseAliases) {
        fileNames.addAll([
          '$paddedId-shiny.png',
          '$id-shiny.png',
          '${paddedId}_shiny.png',
          '${id}_shiny.png',
        ]);
      }
    }

    for (final name in aliases) {
      fileNames.addAll([
        '$id$name.png',
        '$paddedId$name.png',
        '$name.png',
        '${name.toLowerCase()}.png',
      ]);
    }
    if (includeBaseAliases) {
      fileNames.addAll(['$paddedId.png', '$id.png']);
    }

    return <String>[
      for (final fileName in fileNames) 'assets/textures/$folder/$fileName',
      for (final fileName in fileNames)
        'assets/textures/$alternateFolder/$fileName',
    ];
  }

  static List<String> _webImageCandidates({
    required Pokemon pokemon,
    required bool useLargeArtwork,
    String? formName,
    String? gender,
    bool isShiny = false,
    bool includeBaseFolders = true,
  }) {
    final primary = useLargeArtwork ? 'main' : 'sprite';
    final secondary = useLargeArtwork ? 'sprite' : 'main';
    final folders = <String>[];

    void addFolder(String value) {
      if (!folders.contains(value)) folders.add(value);
    }

    final slugs = _webCandidateSlugs(pokemon);
    final formSlugs = _formSlugs(pokemon, formName, gender);

    for (final formSlug in formSlugs) {
      for (final slug in slugs) {
        addFolder('$_webPokemonRoot/$slug-$formSlug');
        addFolder('$_webPokemonRoot/${slug}_$formSlug');
        addFolder('$_webPokemonRoot/$slug/$formSlug');
        addFolder('$_webPokemonRoot/$formSlug-$slug');
        addFolder('$_webPokemonRoot/${formSlug}_$slug');
        addFolder('$_webPokemonRoot/$formSlug/$slug');
      }
    }

    if (includeBaseFolders) {
      for (final slug in slugs) {
        addFolder('$_webPokemonRoot/$slug');
      }
    }

    final paths = <String>[];
    for (final folder in folders) {
      if (isShiny) {
        paths.addAll([
          '$folder/$primary-shiny.png',
          '$folder/$secondary-shiny.png',
          '$folder/${primary}_shiny.png',
          '$folder/${secondary}_shiny.png',
          '$folder/shiny-$primary.png',
          '$folder/shiny-$secondary.png',
          '$folder/shiny.png',
        ]);
      }
      paths.addAll([
        '$folder/$primary.png',
        '$folder/$secondary.png',
        '$folder/main.png',
        '$folder/sprite.png',
        '$folder/${primary}_default.png',
        '$folder/${secondary}_default.png',
      ]);
    }

    for (final transform in _transformFolders) {
      for (final folder in folders) {
        final relative = folder.substring(_webPokemonRoot.length + 1);
        if (isShiny) {
          paths.addAll([
            '$_webTransformRoot/$transform/$relative/$primary-shiny.png',
            '$_webTransformRoot/$transform/$relative/$secondary-shiny.png',
          ]);
        }
        paths.addAll([
          '$_webTransformRoot/$transform/$relative/$primary.png',
          '$_webTransformRoot/$transform/$relative/$secondary.png',
          '$_webTransformRoot/$transform/$relative.png',
        ]);
      }
    }

    return paths.toList(growable: false);
  }

  static List<String> typeCandidates(String type) {
    if (!GameCatalogLocale.isItalian) return const [];
    final localized = localizedTypeLabel(type);
    final assetName = _assetName(localized);
    final lowercaseAssetName = assetName.toLowerCase();

    return [
      'assets/textures/type_names/$lowercaseAssetName.png',
      if (assetName != lowercaseAssetName)
        'assets/textures/type_names/$assetName.png',
    ];
  }

  static String localizedTypeLabel(String type) {
    final normalized = type.trim().toLowerCase();
    if (!GameCatalogLocale.isItalian) {
      switch (normalized) {
        case 'coleottero':
        case 'bug':
          return 'Bug';
        case 'buio':
        case 'dark':
          return 'Dark';
        case 'drago':
        case 'dragon':
          return 'Dragon';
        case 'elettro':
        case 'electric':
          return 'Electric';
        case 'folletto':
        case 'fairy':
          return 'Fairy';
        case 'lotta':
        case 'fighting':
          return 'Fighting';
        case 'fuoco':
        case 'fire':
          return 'Fire';
        case 'volante':
        case 'flying':
          return 'Flying';
        case 'spettro':
        case 'ghost':
          return 'Ghost';
        case 'erba':
        case 'grass':
          return 'Grass';
        case 'terra':
        case 'ground':
          return 'Ground';
        case 'ghiaccio':
        case 'ice':
          return 'Ice';
        case 'normale':
        case 'normal':
          return 'Normal';
        case 'veleno':
        case 'poison':
          return 'Poison';
        case 'psico':
        case 'psychic':
          return 'Psychic';
        case 'roccia':
        case 'rock':
          return 'Rock';
        case 'acciaio':
        case 'steel':
          return 'Steel';
        case 'acqua':
        case 'water':
          return 'Water';
        default:
          return type;
      }
    }

    switch (normalized) {
      case 'bug':
      case 'coleottero':
        return 'Coleottero';
      case 'dark':
      case 'buio':
        return 'Buio';
      case 'dragon':
      case 'drago':
        return 'Drago';
      case 'electric':
      case 'elettro':
        return 'Elettro';
      case 'fairy':
      case 'folletto':
        return 'Folletto';
      case 'fighting':
      case 'lotta':
        return 'Lotta';
      case 'fire':
      case 'fuoco':
        return 'Fuoco';
      case 'flying':
      case 'volante':
        return 'Volante';
      case 'ghost':
      case 'spettro':
        return 'Spettro';
      case 'grass':
      case 'erba':
        return 'Erba';
      case 'ground':
      case 'terra':
        return 'Terra';
      case 'ice':
      case 'ghiaccio':
        return 'Ghiaccio';
      case 'normal':
      case 'normale':
        return 'Normale';
      case 'poison':
      case 'veleno':
        return 'Veleno';
      case 'psychic':
      case 'psico':
        return 'Psico';
      case 'rock':
      case 'roccia':
        return 'Roccia';
      case 'steel':
      case 'acciaio':
        return 'Acciaio';
      case 'water':
      case 'acqua':
        return 'Acqua';
      default:
        return type;
    }
  }

  static PokemonFormChoice? _formChoiceFromAssetPath(
    Pokemon pokemon,
    String assetPath,
  ) {
    final fileName = assetPath.split('/').last;
    if (!fileName.endsWith('.png')) return null;

    final baseName = fileName.substring(0, fileName.length - 4);
    final id = pokemon.id.toString();
    final paddedId = id.padLeft(3, '0');
    String nameAndForm;

    if (baseName.startsWith(paddedId)) {
      nameAndForm = baseName.substring(paddedId.length).trim();
    } else if (baseName.startsWith(id)) {
      nameAndForm = baseName.substring(id.length).trim();
    } else {
      return null;
    }

    if (nameAndForm.isEmpty) return null;

    final aliases = _nameAliases(pokemon.name).toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    var suffix = nameAndForm;
    for (final alias in aliases) {
      if (suffix.toLowerCase().startsWith(alias.toLowerCase())) {
        suffix = suffix.substring(alias.length).trim();
        break;
      }
    }

    suffix = _cleanFormLabel(suffix);
    if (suffix.isEmpty || _isBaseSpriteLabel(suffix)) return null;
    return PokemonFormChoice(name: suffix, assetPath: assetPath);
  }

  static PokemonFormChoice? _webFormChoiceFromAssetPath(
    Pokemon pokemon,
    String assetPath,
  ) {
    if (!assetPath.startsWith('$_webPokemonRoot/') ||
        !assetPath.endsWith('.png')) {
      return null;
    }

    final relative = assetPath.substring(_webPokemonRoot.length + 1);
    final parts = relative.split('/');
    if (parts.isEmpty) return null;

    final folder = parts.first;
    final speciesSlug = _webBaseSlug(pokemon);
    var rawForm = '';

    for (final slug in _webCandidateSlugs(pokemon)) {
      if (folder == slug) {
        rawForm =
            _folderSuffixAfterSpecies(folder, speciesSlug) ??
            (parts.length > 2 ? parts[1] : _formFromFileName(parts.last));
        break;
      }
      if (folder.startsWith('$slug-')) {
        rawForm = folder.substring(slug.length + 1);
        break;
      }
      if (folder.startsWith('${slug}_')) {
        rawForm = folder.substring(slug.length + 1);
        break;
      }
    }

    rawForm = _cleanFormLabel(rawForm);
    if (rawForm.isEmpty || _isBaseSpriteLabel(rawForm)) return null;
    return PokemonFormChoice(name: rawForm, assetPath: assetPath);
  }

  static String _formFromFileName(String fileName) {
    return fileName
        .replaceFirst(RegExp(r'\.(?:png|webp)$'), '')
        .replaceFirst(
          RegExp(r'^(main|sprite)[-_\s]+', caseSensitive: false),
          '',
        )
        .replaceFirst(
          RegExp(r'[-_\s]+(main|sprite)$', caseSensitive: false),
          '',
        )
        .replaceFirst(RegExp(r'[-_\s]*shiny$', caseSensitive: false), '')
        .trim();
  }

  static Future<List<PokemonFormChoice>> _variantMapFormChoices(
    Pokemon pokemon,
  ) async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/variant_map.json',
      );
      final json = Map<String, dynamic>.from(jsonDecode(jsonString));
      final variants = List<dynamic>.from(json[pokemon.name] ?? const []);

      if (variants.length <= 1) return const [];

      return variants
          .map((value) => _cleanVariantLabel(pokemon, value.toString()))
          .where(
            (name) =>
                name.isNotEmpty &&
                !_isBaseSpriteLabel(name) &&
                !_isGenderOnlyLabel(name),
          )
          .map((name) => PokemonFormChoice(name: name, assetPath: ''))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  static String _cleanVariantLabel(Pokemon pokemon, String value) {
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

  static Set<String> _formAwareAliases(String rawName, String? formName) {
    final form = formName?.trim();
    if (form == null ||
        form.isEmpty ||
        _isBaseSpriteLabel(form) ||
        _isGenderOnlyLabel(form)) {
      return const {};
    }

    final speciesAliases = _nameAliases(rawName);
    final cleanedForm = _cleanFormLabel(form);
    final shortForm = _stripGenericFormWords(
      _removePokemonName(cleanedForm, rawName),
    );
    final formAliases = <String>{
      if (shortForm.isNotEmpty) shortForm,
      if (cleanedForm.isNotEmpty &&
          !cleanedForm.toLowerCase().contains(rawName.toLowerCase()))
        cleanedForm,
      for (final alias in _regionalAliases(shortForm)) _cleanFormLabel(alias),
    }..removeWhere((name) => name.isEmpty);

    final result = <String>{};
    if (cleanedForm.toLowerCase().contains(rawName.toLowerCase())) {
      result.addAll([
        cleanedForm,
        _assetName(cleanedForm),
        _compactAssetName(cleanedForm),
      ]);
    }

    for (final speciesAlias in speciesAliases) {
      for (final formAlias in formAliases) {
        result.addAll([
          '$formAlias $speciesAlias',
          '$speciesAlias $formAlias',
          '$formAlias - $speciesAlias',
          '$speciesAlias - $formAlias',
          '${formAlias}_$speciesAlias',
          '${speciesAlias}_$formAlias',
          _assetName('$formAlias $speciesAlias'),
          _assetName('$speciesAlias $formAlias'),
          _compactAssetName('$formAlias $speciesAlias'),
          _compactAssetName('$speciesAlias $formAlias'),
        ]);
      }
    }

    return result..removeWhere((name) => name.isEmpty);
  }

  static Set<String> _genderAwareAliases(String rawName, String? gender) {
    final labels = _genderLabels(gender);
    if (labels.isEmpty) return const {};

    final aliases = _nameAliases(rawName);
    return <String>{
      for (final alias in aliases)
        for (final label in labels) ...[
          '$label $alias',
          '$alias $label',
          '$label - $alias',
          '$alias - $label',
          '${label}_$alias',
          '${alias}_$label',
          _assetName('$label $alias'),
          _assetName('$alias $label'),
          _compactAssetName('$label $alias'),
          _compactAssetName('$alias $label'),
        ],
    }..removeWhere((name) => name.isEmpty);
  }

  static List<String> _formSlugs(
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
    if (form != null && form.isNotEmpty) {
      final canonicalForm = _canonicalFormLabel(pokemon, form);
      if (!_isBaseSpriteLabel(canonicalForm) &&
          !_isGenderOnlyLabel(canonicalForm)) {
        add(canonicalForm);
        final strippedForm = _stripGenericFormWords(canonicalForm);
        add(strippedForm);

        for (final alias in _regionalAliases(canonicalForm)) {
          add(alias);
        }
        for (final alias in _regionalAliases(strippedForm)) {
          add(alias);
        }
      }
    }

    for (final slug in _genderSlugs(gender)) {
      add(slug);
    }

    return result;
  }

  static List<String> _genderSlugs(String? gender) {
    final value = gender?.toLowerCase().trim();
    switch (value) {
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

  static List<String> _genderLabels(String? gender) {
    final value = gender?.toLowerCase().trim();
    switch (value) {
      case 'male':
      case 'm':
      case 'maschio':
        return const ['Male', 'M', 'Maschio'];
      case 'female':
      case 'f':
      case 'femmina':
        return const ['Female', 'F', 'Femmina'];
      default:
        return const [];
    }
  }

  static String _webAssetSlug(Pokemon pokemon) {
    final slug = pokemon.assetSlug?.trim();
    if (slug != null && slug.isNotEmpty) return slug;
    return _webSlug(pokemon.name);
  }

  static String _webBaseSlug(Pokemon pokemon) => _webSlug(pokemon.name);

  static List<String> _webCandidateSlugs(Pokemon pokemon) {
    final exactSlug = _webAssetSlug(pokemon);
    final baseSlug = _webBaseSlug(pokemon);
    final slugs = <String>[];

    void add(String value) {
      if (value.isNotEmpty && !slugs.contains(value)) slugs.add(value);
    }

    // Prefer the species folder for the default form. Variant-specific
    // folders are then resolved through the explicit form slug.
    add(baseSlug);
    add(exactSlug);

    final suffix = _folderSuffixAfterSpecies(exactSlug, baseSlug);
    if (suffix != null && suffix.isNotEmpty) {
      add('$baseSlug-$suffix');
    }

    return slugs;
  }

  static String? _folderSuffixAfterSpecies(String folder, String speciesSlug) {
    if (folder == speciesSlug) return null;
    if (folder.startsWith('$speciesSlug-')) {
      return folder.substring(speciesSlug.length + 1);
    }
    if (folder.startsWith('${speciesSlug}_')) {
      return folder.substring(speciesSlug.length + 1);
    }
    return null;
  }

  static int _compareFormChoices(PokemonFormChoice a, PokemonFormChoice b) {
    final weightA = _formSortWeight(a.name);
    final weightB = _formSortWeight(b.name);
    if (weightA != weightB) return weightA.compareTo(weightB);
    return a.name.compareTo(b.name);
  }

  static int _formSortWeight(String label) {
    final value = label.toLowerCase().trim();
    if (value == 'amped') return 0;
    return 10;
  }

  static String _webSlug(String value) {
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

  static String _assetName(String value) {
    return value
        .trim()
        .replaceAll(':', '')
        .replaceAll('.', '')
        .replaceAll("'", '')
        .replaceAll('’', '')
        .replaceAll(' ', '_')
        .replaceAll('-', '_');
  }

  static String _compactAssetName(String value) {
    return value
        .trim()
        .replaceAll(':', '')
        .replaceAll('.', '')
        .replaceAll("'", '')
        .replaceAll('’', '')
        .replaceAll(' ', '')
        .replaceAll('-', '');
  }

  static String _punctuationAsSpaceName(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'[:._-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _cleanFormLabel(String value) {
    final cleaned = value
        .replaceFirst(RegExp(r'^[-_:\s]+'), '')
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    switch (cleaned.toLowerCase()) {
      case 'm':
        return 'Male';
      case 'f':
        return 'Female';
      default:
        break;
    }

    if (cleaned.isEmpty) return '';
    return cleaned
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  static String _canonicalFormLabel(Pokemon pokemon, String value) {
    var label = _cleanFormLabel(value);
    if (label.isEmpty || _isBaseSpriteLabel(label)) return 'Base';
    if (_isGenderOnlyLabel(label)) return label;

    label = _stripGenericFormWords(_removePokemonName(label, pokemon.name));
    if (label.isEmpty) return 'Base';

    switch (label.toLowerCase()) {
      case 'regular':
      case 'kanto':
        return 'Base';
      case 'alola':
      case 'alolan':
        return 'Alolan';
      case 'galar':
      case 'galarian':
        return 'Galarian';
      case 'hisui':
      case 'hisuian':
        return 'Hisuian';
      case 'paldea':
      case 'paldean':
        return 'Paldean';
      default:
        return label;
    }
  }

  static String _formIdentityKey(Pokemon pokemon, String value) {
    final canonical = _canonicalFormLabel(pokemon, value);
    return _isBaseSpriteLabel(canonical) ? 'base' : _webSlug(canonical);
  }

  static bool _isGenderOnlyLabel(String label) {
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
    } else if (lower.contains('alola')) {
      add(lower.replaceAll('alola', 'alolan'));
    }
    if (lower.contains('alolan') || lower.contains('alola')) {
      add('alola');
      add('alolan');
    }

    if (lower.contains('galarian')) {
      add(lower.replaceAll('galarian', 'galar'));
    } else if (lower.contains('galar')) {
      add(lower.replaceAll('galar', 'galarian'));
    }
    if (lower.contains('galarian') || lower.contains('galar')) {
      add('galar');
      add('galarian');
    }

    if (lower.contains('hisuian')) {
      add(lower.replaceAll('hisuian', 'hisui'));
    } else if (lower.contains('hisui')) {
      add(lower.replaceAll('hisui', 'hisuian'));
    }
    if (lower.contains('hisuian') || lower.contains('hisui')) {
      add('hisui');
      add('hisuian');
    }

    if (lower.contains('paldean')) {
      add(lower.replaceAll('paldean', 'paldea'));
    } else if (lower.contains('paldea')) {
      add(lower.replaceAll('paldea', 'paldean'));
    }
    if (lower.contains('paldean') || lower.contains('paldea')) {
      add('paldea');
      add('paldean');
    }

    return aliases;
  }

  static bool _isDefaultFormChoice(Pokemon pokemon, String label) {
    final normalized = _webSlug(
      _stripGenericFormWords(_removePokemonName(label, pokemon.name)),
    );
    const defaultForms = <String, Set<String>>{
      'Deoxys': {'normal'},
      'Castform': {'normal'},
      'Cherrim': {'overcast'},
      'Darmanitan': {'standard'},
      'Meloetta': {'aria'},
      'Aegislash': {'blade'},
      'Wishiwashi': {'solo'},
      'Minior': {'meteor'},
      'Mimikyu': {'disguised'},
      'Eiscue': {'ice-face'},
      'Morpeko': {'full-belly'},
      'Palafin': {'zero'},
      'Zygarde': {'50'},
      'Ogerpon': {'teal-mask'},
      'Terapagos': {'normal'},
    };
    return defaultForms[pokemon.name]?.contains(normalized) ?? false;
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

  static Set<String> _nameAliases(String value) {
    final genderName = value
        .replaceAll(' ♀', '-f')
        .replaceAll('♀', '-f')
        .replaceAll(' ♂', '-m')
        .replaceAll('♂', '-m');
    final punctuationAsSpaceName = _punctuationAsSpaceName(value);

    return <String>{
      value.trim(),
      _assetName(value),
      _compactAssetName(value),
      punctuationAsSpaceName,
      _assetName(punctuationAsSpaceName),
      _compactAssetName(punctuationAsSpaceName),
      genderName.trim(),
      _assetName(genderName),
      _compactAssetName(genderName),
    }..removeWhere((name) => name.isEmpty);
  }
}

class _AssetFallbackImage extends StatelessWidget {
  const _AssetFallbackImage({
    required this.assetPaths,
    required this.fallback,
    this.assetPrefixes = const [],
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  final List<String> assetPaths;
  final List<String> assetPrefixes;
  final Widget fallback;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _AssetLookup.firstExisting(
        assetPaths,
        assetPrefixes: assetPrefixes,
      ),
      builder: (context, snapshot) {
        final assetPath = snapshot.data;
        if (assetPath == null) return fallback;

        return Image.asset(
          assetPath,
          width: width,
          height: height,
          fit: fit,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) => fallback,
        );
      },
    );
  }
}

class _AssetLookup {
  const _AssetLookup._();

  static Future<_AssetIndex>? _assetIndexFuture;

  static Future<String?> firstExisting(
    List<String> candidates, {
    List<String> assetPrefixes = const [],
  }) async {
    final assetIndex = await _assetIndex();

    for (final candidate in candidates) {
      if (assetIndex.pathSet.contains(candidate)) return candidate;
    }

    for (final prefix in assetPrefixes) {
      for (final assetPath in assetIndex.sortedPaths) {
        if (matchesPrefix(assetPath, prefix)) return assetPath;
      }
    }

    return null;
  }

  static bool matchesPrefix(String assetPath, String prefix) {
    if (!PokemonAssetPaths._isSupportedImagePath(assetPath)) return false;
    if (!assetPath.startsWith(prefix)) return false;
    if (assetPath.length <= prefix.length) return false;

    if (prefix.endsWith('/') || prefix.endsWith('-') || prefix.endsWith('_')) {
      return true;
    }

    final nextCode = assetPath.codeUnitAt(prefix.length);
    return nextCode < 48 || nextCode > 57;
  }

  static Future<_AssetIndex> assetIndex() => _assetIndex();

  static Future<_AssetIndex> _assetIndex() {
    return _assetIndexFuture ??= AssetManifest.loadFromAssetBundle(rootBundle)
        .then((manifest) {
          final sortedPaths = manifest.listAssets().toList()..sort();
          return _AssetIndex(
            pathSet: sortedPaths.toSet(),
            sortedPaths: sortedPaths,
          );
        });
  }
}

class _AssetIndex {
  const _AssetIndex({required this.pathSet, required this.sortedPaths});

  final Set<String> pathSet;
  final List<String> sortedPaths;
}
