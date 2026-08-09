export 'pokemon_asset_image_legacy.dart'
    hide PokemonAssetImage, PokemonAssetPaths, PokemonTypeBadge;
export 'pokemon_type_badge.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../localization/game_catalog_locale.dart';
import '../../models/item_driven_pokemon_form.dart';
import '../../models/pokedex_entry.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_evolution_alias_registry.dart';
import '../../models/pokemon_gender_appearance.dart';
import '../../services/custom_pokemon_runtime_registry.dart';
import 'pokemon_asset_image_legacy.dart' as legacy;
import 'pokemon_gender_asset_paths.dart';
import 'pokemon_minior_asset_paths.dart';

/// Public asset resolver used by the screens.
///
/// It delegates normal image lookup to the legacy resolver, but removes
/// male/female-only entries from the list of real Pokémon forms. Gender
/// variants remain available through the Sesso field and may still resolve
/// different rules data when the species actually has mechanical differences.
class PokemonAssetPaths {
  const PokemonAssetPaths._();

  static Future<List<legacy.PokemonFormChoice>> formChoices(
    Pokemon pokemon,
  ) async {
    if (ItemDrivenPokemonForm.usesHeldItemForm(pokemon.id)) return const [];

    final rawChoices = await legacy.PokemonAssetPaths.formChoices(pokemon);
    if (rawChoices.isEmpty) return const [];

    final genderDefinitionKeys = <String>{};
    for (final definition in pokemon.formDefinitions) {
      if (Pokemon.normalizeGenderValue(definition.gender) == null) continue;
      genderDefinitionKeys.add(
        Pokemon.formReferenceKey(definition.key, pokemon.name),
      );
      genderDefinitionKeys.add(
        Pokemon.formReferenceKey(definition.displayName, pokemon.name),
      );
    }

    legacy.PokemonFormChoice? baseChoice;
    final realChoicesByKey = <String, legacy.PokemonFormChoice>{};
    for (final choice in rawChoices) {
      if (_isShinyAppearanceChoice(pokemon: pokemon, value: choice.name)) {
        continue;
      }
      if (!PokedexEntry.isTrackableForm(
        choice.name,
        speciesName: pokemon.name,
      )) {
        continue;
      }
      final key = PokedexEntry.formKey(choice.name, speciesName: pokemon.name);
      if (key == 'base') {
        baseChoice ??= choice;
        continue;
      }
      if (_isGenderOnlyChoice(
        pokemon: pokemon,
        value: choice.name,
        genderDefinitionKeys: genderDefinitionKeys,
      )) {
        continue;
      }
      realChoicesByKey.putIfAbsent(key, () => choice);
    }

    // A species whose only alternatives are male/female or temporary battle
    // states must not display a Forma section containing only Base.
    if (realChoicesByKey.isEmpty) return const [];

    return <legacy.PokemonFormChoice>[
      baseChoice ?? const legacy.PokemonFormChoice(name: 'Base', assetPath: ''),
      ...realChoicesByKey.values,
    ];
  }

  static bool _isShinyAppearanceChoice({
    required Pokemon pokemon,
    required String value,
  }) {
    final key = Pokemon.formReferenceKey(value, pokemon.name);
    return key.split('-').contains('shiny');
  }

  static bool _isGenderOnlyChoice({
    required Pokemon pokemon,
    required String value,
    required Set<String> genderDefinitionKeys,
  }) {
    final key = Pokemon.formReferenceKey(value, pokemon.name);
    if (genderDefinitionKeys.contains(key)) return true;
    if (Pokemon.normalizeGenderValue(key) != null) return true;

    const ignoredTokens = {
      'appearance',
      'artwork',
      'base',
      'default',
      'main',
      'normal',
      'shiny',
      'sprite',
      'variant',
      'version',
    };
    final reduced = key
        .split('-')
        .where((token) => token.isNotEmpty && !ignoredTokens.contains(token))
        .join('-');

    if (Pokemon.normalizeGenderValue(reduced) != null) return true;
    return reduced == 'genderless' ||
        reduced == 'senza-sesso' ||
        reduced == 'sesso-sconosciuto';
  }

  static List<String> imageCandidates({
    required Pokemon pokemon,
    required bool useLargeArtwork,
    String? formName,
    String? gender,
    bool isShiny = false,
  }) {
    return <String>{
      ..._explicitFormAssetCandidates(
        pokemon: pokemon,
        useLargeArtwork: useLargeArtwork,
        formName: formName,
        isShiny: isShiny,
      ),
      ..._itemDrivenAssetCandidates(
        pokemon: pokemon,
        useLargeArtwork: useLargeArtwork,
        formName: formName,
        isShiny: isShiny,
      ),
      ...legacy.PokemonAssetPaths.imageCandidates(
        pokemon: pokemon,
        useLargeArtwork: useLargeArtwork,
        formName: formName,
        gender: gender,
        isShiny: isShiny,
      ),
    }.toList(growable: false);
  }

  static List<String> imageCandidatePrefixes({
    required Pokemon pokemon,
    required bool useLargeArtwork,
    String? formName,
    String? gender,
  }) {
    return legacy.PokemonAssetPaths.imageCandidatePrefixes(
      pokemon: pokemon,
      useLargeArtwork: useLargeArtwork,
      formName: formName,
      gender: gender,
    );
  }

  static List<String> typeCandidates(String type) {
    final localized = localizedTypeLabel(type);
    final assetName = _typeAssetName(localized);
    final lowercaseAssetName = assetName.toLowerCase();
    final root = GameCatalogLocale.isItalian
        ? 'assets/textures/type_names'
        : 'assets/textures/type_names/en';

    return [
      '$root/$lowercaseAssetName.png',
      if (assetName != lowercaseAssetName) '$root/$assetName.png',
    ];
  }

  static String localizedTypeLabel(String type) {
    return legacy.PokemonAssetPaths.localizedTypeLabel(type);
  }

  static String _typeAssetName(String value) {
    return value
        .trim()
        .replaceAll(':', '')
        .replaceAll('.', '')
        .replaceAll("'", '')
        .replaceAll('’', '')
        .replaceAll(' ', '_')
        .replaceAll('-', '_');
  }
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
    final alias = PokemonEvolutionAliasRegistry.aliasFor(pokemon.id);
    final effectivePokemon = alias?.basePokemon ?? pokemon;
    final effectiveForm = formName ?? alias?.formName;
    final customBytes = CustomPokemonRuntimeRegistry.imageBytesFor(
      effectivePokemon.id,
      formName: effectiveForm,
      shiny: isShiny ?? false,
    );

    if (customBytes != null) {
      final custom = Image.memory(
        customBytes,
        width: size,
        height: size,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) =>
            fallback ?? Icon(Icons.catching_pokemon, size: size * 0.48),
      );
      return SizedBox(
        key: ValueKey<String>(
          'custom-${effectivePokemon.id}-${effectiveForm ?? 'base'}-${isShiny ?? false}-$size',
        ),
        width: size,
        height: size,
        child: Center(child: _entryState(context, custom, entry)),
      );
    }

    final legacyImage = legacy.PokemonAssetImage(
      key: ValueKey<String>(
        '${effectivePokemon.id}|${effectiveForm ?? 'base'}|${gender ?? 'none'}|${isShiny ?? false}|$useLargeArtwork',
      ),
      pokemon: effectivePokemon,
      size: size,
      fit: fit,
      useLargeArtwork: useLargeArtwork,
      entry: entry,
      formName: effectiveForm,
      gender: gender,
      isShiny: isShiny,
      fallback: fallback,
    );

    final assetGender =
        gender ??
        (PokemonGenderAppearance.hasVisibleDifference(effectivePokemon)
            ? 'male'
            : null);
    final candidates = <String>[
      ..._explicitFormAssetCandidates(
        pokemon: effectivePokemon,
        useLargeArtwork: useLargeArtwork,
        formName: effectiveForm,
        isShiny: isShiny ?? false,
      ),
      ..._itemDrivenAssetCandidates(
        pokemon: effectivePokemon,
        useLargeArtwork: useLargeArtwork,
        formName: effectiveForm,
        isShiny: isShiny ?? false,
      ),
      ..._regionalAssetCandidates(
        pokemon: effectivePokemon,
        formName: effectiveForm,
        useLargeArtwork: useLargeArtwork,
        isShiny: isShiny ?? false,
      ),
      ...PokemonMiniorAssetPaths.candidates(
        pokemon: effectivePokemon,
        useLargeArtwork: useLargeArtwork,
        formName: effectiveForm,
        isShiny: isShiny ?? false,
      ),
      ...PokemonGenderAssetPaths.candidates(
        pokemon: effectivePokemon,
        useLargeArtwork: useLargeArtwork,
        formName: effectiveForm,
        gender: assetGender,
        isShiny: isShiny ?? false,
      ),
    ];
    if (candidates.isEmpty) return legacyImage;

    return _PreferredAssetImage(
      key: ValueKey<String>(
        'preferred-${effectivePokemon.id}-${effectiveForm ?? 'base'}-${assetGender ?? 'none'}-${isShiny ?? false}-$useLargeArtwork',
      ),
      candidates: candidates,
      fallback: legacyImage,
      entry: entry,
      size: size,
      fit: fit,
      scale: useLargeArtwork ? 1.08 : 1.12,
    );
  }
}

List<String> _explicitFormAssetCandidates({
  required Pokemon pokemon,
  required bool useLargeArtwork,
  required String? formName,
  required bool isShiny,
}) {
  final formKey = Pokemon.formReferenceKey(formName ?? '', pokemon.name);
  if (formKey == 'base' || formKey.isEmpty) return const [];

  final speciesSlug = _assetSlug(pokemon.name);
  if (speciesSlug.isEmpty) return const [];

  final formSlugs = <String>{
    formKey,
    '$formKey-style',
    '$formKey-form',
    '$formKey-forme',
    '$formKey-mode',
  };
  final folders = <String>[];
  for (final formSlug in formSlugs) {
    folders.addAll([
      '$speciesSlug-$formSlug',
      '$formSlug-$speciesSlug',
      '$speciesSlug/$formSlug',
    ]);
  }

  final primary = useLargeArtwork ? 'main' : 'sprite';
  final secondary = useLargeArtwork ? 'sprite' : 'main';
  const root = 'assets/textures/textures_webapp/pokemon';
  final candidates = <String>[];
  for (final folder in folders) {
    if (isShiny) {
      candidates.addAll([
        '$root/$folder/$primary-shiny.png',
        '$root/$folder/$secondary-shiny.png',
        '$root/$folder/${primary}_shiny.png',
        '$root/$folder/${secondary}_shiny.png',
      ]);
    }
    candidates.addAll([
      '$root/$folder/$primary.png',
      '$root/$folder/$secondary.png',
      '$root/$folder/main.png',
      '$root/$folder/sprite.png',
    ]);
  }
  return candidates;
}

List<String> _itemDrivenAssetCandidates({
  required Pokemon pokemon,
  required bool useLargeArtwork,
  required String? formName,
  required bool isShiny,
}) {
  if (!ItemDrivenPokemonForm.usesHeldItemForm(pokemon.id)) return const [];

  final formSlug = Pokemon.formReferenceKey(formName ?? '', pokemon.name);
  if (formSlug == 'base' || formSlug.isEmpty) return const [];

  final speciesSlug = _assetSlug(pokemon.name);
  if (speciesSlug.isEmpty) return const [];

  final imageKind = useLargeArtwork ? 'main' : 'sprite';
  final root = 'assets/textures/textures_webapp/pokemon/$speciesSlug';
  return <String>[
    if (isShiny) ...[
      '$root/$imageKind-$formSlug-shiny.webp',
      '$root/$imageKind-$formSlug-shiny.png',
    ],
    '$root/$imageKind-$formSlug.webp',
    '$root/$imageKind-$formSlug.png',
  ];
}

List<String> _regionalAssetCandidates({
  required Pokemon pokemon,
  required String? formName,
  required bool useLargeArtwork,
  required bool isShiny,
}) {
  final formKey = Pokemon.formReferenceKey(formName ?? '', pokemon.name);
  final regionalNames = switch (formKey) {
    'alolan' => const ('alolan', 'alola'),
    'galarian' => const ('galarian', 'galar'),
    'hisuian' => const ('hisuian', 'hisui'),
    'paldean' => const ('paldean', 'paldea'),
    _ => null,
  };
  if (regionalNames == null) return const [];

  final speciesSlug = _assetSlug(pokemon.name);
  if (speciesSlug.isEmpty) return const [];

  final adjective = regionalNames.$1;
  final region = regionalNames.$2;
  final folders = <String>[
    '$adjective-$speciesSlug',
    '$speciesSlug-$region',
    '$speciesSlug-$adjective',
  ];
  final primary = useLargeArtwork ? 'main' : 'sprite';
  final secondary = useLargeArtwork ? 'sprite' : 'main';
  const root = 'assets/textures/textures_webapp/pokemon';
  final candidates = <String>[];

  for (final folder in folders) {
    if (isShiny) {
      candidates.addAll([
        '$root/$folder/$primary-shiny.png',
        '$root/$folder/$secondary-shiny.png',
        '$root/$folder/${primary}_shiny.png',
        '$root/$folder/${secondary}_shiny.png',
      ]);
    }
    candidates.addAll([
      '$root/$folder/$primary.png',
      '$root/$folder/$secondary.png',
    ]);
  }

  return candidates;
}

String _assetSlug(String value) {
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

class _PreferredAssetImage extends StatelessWidget {
  const _PreferredAssetImage({
    super.key,
    required this.candidates,
    required this.fallback,
    required this.entry,
    required this.size,
    required this.fit,
    required this.scale,
  });

  static Future<Set<String>>? _manifestPaths;

  final List<String> candidates;
  final Widget fallback;
  final PokedexEntry? entry;
  final double size;
  final BoxFit fit;
  final double scale;

  static Future<Set<String>> _paths() {
    return _manifestPaths ??= AssetManifest.loadFromAssetBundle(
      rootBundle,
    ).then((manifest) => manifest.listAssets().toSet());
  }

  Future<String?> _resolve() async {
    final paths = await _paths();
    for (final candidate in candidates) {
      if (candidate.endsWith('.png')) {
        final webp = '${candidate.substring(0, candidate.length - 4)}.webp';
        if (paths.contains(webp)) return webp;
      }
      if (paths.contains(candidate)) return candidate;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _resolve(),
      builder: (context, snapshot) {
        final path = snapshot.data;
        if (path == null) return fallback;
        final image = Image.asset(
          path,
          width: size,
          height: size,
          fit: fit,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, _, _) => fallback,
        );
        return SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Transform.scale(
              scale: scale,
              child: _entryState(context, image, entry),
            ),
          ),
        );
      },
    );
  }
}

Widget _entryState(BuildContext context, Widget image, PokedexEntry? entry) {
  final seen = entry?.seen ?? true;
  final caught = entry?.caught ?? true;
  if (!seen) {
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcATop),
      child: image,
    );
  }
  if (!caught) {
    return Opacity(
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
  return image;
}
