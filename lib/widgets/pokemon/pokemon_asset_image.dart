import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/pokedex_entry.dart';
import '../../models/pokemon.dart';

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
    this.fallback,
  });

  final Pokemon pokemon;
  final double size;
  final BoxFit fit;
  final bool useLargeArtwork;
  final PokedexEntry? entry;
  final String? formName;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final entry = this.entry;
    final seen = entry?.seen ?? true;
    final caught = entry?.caught ?? true;
    final visualScale = useLargeArtwork ? 1.08 : 1.12;

    Widget image = _AssetFallbackImage(
      assetPaths: PokemonAssetPaths.imageCandidates(
        pokemon: pokemon,
        useLargeArtwork: useLargeArtwork,
        formName: formName,
      ),
      assetPrefixes: PokemonAssetPaths.imageCandidatePrefixes(
        pokemon: pokemon,
        useLargeArtwork: useLargeArtwork,
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

  static Future<List<PokemonFormChoice>> formChoices(Pokemon pokemon) async {
    final assetIndex = await _AssetLookup.assetIndex();
    final choicesByName = <String, PokemonFormChoice>{};
    final prefixes = imageCandidatePrefixes(
      pokemon: pokemon,
      useLargeArtwork: false,
    );

    for (final assetPath in assetIndex.sortedPaths) {
      if (!assetPath.endsWith('.png')) continue;
      if (!prefixes.any((prefix) => _AssetLookup.matchesPrefix(assetPath, prefix))) {
        continue;
      }

      final choice = _formChoiceFromAssetPath(pokemon, assetPath);
      if (choice == null) continue;
      choicesByName.putIfAbsent(choice.name, () => choice);
    }

    final choices = choicesByName.values.toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));

    return choices;
  }

  static List<String> imageCandidates({
    required Pokemon pokemon,
    required bool useLargeArtwork,
    String? formName,
  }) {
    final folder = useLargeArtwork ? 'pokemons' : 'sprites';
    final alternateFolder = useLargeArtwork ? 'sprites' : 'pokemons';
    final id = pokemon.id.toString();
    final paddedId = id.padLeft(3, '0');
    final rawName = pokemon.name.trim();
    final selectedFormAliases = _formAwareAliases(rawName, formName);
    final nameAliases = _nameAliases(rawName);
    final fileNames = <String>{
      for (final name in selectedFormAliases) ...[
        '$id$name.png',
        '$paddedId$name.png',
        '$name.png',
        '${name.toLowerCase()}.png',
      ],
      for (final name in nameAliases) ...[
        '$id$name.png',
        '$paddedId$name.png',
        '$name.png',
        '${name.toLowerCase()}.png',
      ],
      '$paddedId.png',
      '$id.png',
    };

    return <String>[
      for (final fileName in fileNames) 'assets/textures/$folder/$fileName',
      for (final fileName in fileNames)
        'assets/textures/$alternateFolder/$fileName',
    ];
  }

  static List<String> imageCandidatePrefixes({
    required Pokemon pokemon,
    required bool useLargeArtwork,
  }) {
    final folder = useLargeArtwork ? 'pokemons' : 'sprites';
    final alternateFolder = useLargeArtwork ? 'sprites' : 'pokemons';
    final id = pokemon.id.toString();
    final paddedId = id.padLeft(3, '0');
    final prefixes = <String>{
      'assets/textures/$folder/$id',
      'assets/textures/$folder/$paddedId',
      'assets/textures/$alternateFolder/$id',
      'assets/textures/$alternateFolder/$paddedId',
    };

    return prefixes.toList(growable: false);
  }

  static List<String> typeCandidates(String type) {
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
    switch (type.trim().toLowerCase()) {
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

    suffix = suffix
        .replaceFirst(RegExp(r'^[-_:\s]+'), '')
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final label = suffix.isEmpty ? 'Base' : suffix;
    return PokemonFormChoice(name: label, assetPath: assetPath);
  }

  static Set<String> _formAwareAliases(String rawName, String? formName) {
    final form = formName?.trim();
    if (form == null || form.isEmpty) return const {};

    final aliases = _nameAliases(rawName);
    return <String>{
      for (final alias in aliases) ...[
        '$alias $form',
        '$alias - $form',
        '${alias}_$form',
        _assetName('$alias $form'),
        _compactAssetName('$alias $form'),
      ],
    }..removeWhere((name) => name.isEmpty);
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

        if (assetPath == null) {
          return fallback;
        }

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
      if (assetIndex.pathSet.contains(candidate)) {
        return candidate;
      }
    }

    for (final prefix in assetPrefixes) {
      for (final assetPath in assetIndex.sortedPaths) {
        if (matchesPrefix(assetPath, prefix)) {
          return assetPath;
        }
      }
    }

    return null;
  }

  static bool matchesPrefix(String assetPath, String prefix) {
    if (!assetPath.endsWith('.png')) return false;
    if (!assetPath.startsWith(prefix)) return false;
    if (assetPath.length <= prefix.length) return false;

    final nextCode = assetPath.codeUnitAt(prefix.length);
    return nextCode < 48 || nextCode > 57;
  }

  static Future<_AssetIndex> assetIndex() => _assetIndex();

  static Future<_AssetIndex> _assetIndex() {
    return _assetIndexFuture ??= AssetManifest.loadFromAssetBundle(
      rootBundle,
    ).then((manifest) {
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
