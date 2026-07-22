from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    source = file.read_text(encoding='utf-8')
    count = source.count(old)
    if count != 1:
        raise SystemExit(f'{path}: expected one match, found {count}')
    file.write_text(source.replace(old, new, 1), encoding='utf-8')


# CustomPokemonDefinition v2 and advanced payload.
path = 'lib/models/custom_pokemon_definition.dart'
replace_once(
    path,
    "import 'move_data.dart';\n",
    "import 'custom_pokemon_advanced_data.dart';\nimport 'move_data.dart';\n",
)
replace_once(
    path,
    """    this.imageMimeType,
    this.imageBase64,
    this.localMoves = const [],
    this.localAbilities = const [],
  });

  static const int currentFormatVersion = 1;
""",
    """    this.imageMimeType,
    this.imageBase64,
    this.shinyImageMimeType,
    this.shinyImageBase64,
    this.localMoves = const [],
    this.localAbilities = const [],
    this.advanced = const CustomPokemonAdvancedData(),
  });

  static const int currentFormatVersion = 2;
""",
)
replace_once(
    path,
    """  final String? imageMimeType;
  final String? imageBase64;
  final List<CustomPokemonMoveDefinition> localMoves;
  final List<CustomPokemonAbilityDefinition> localAbilities;

  bool get hasImage => imageBase64 != null && imageBase64!.isNotEmpty;
""",
    """  final String? imageMimeType;
  final String? imageBase64;
  final String? shinyImageMimeType;
  final String? shinyImageBase64;
  final List<CustomPokemonMoveDefinition> localMoves;
  final List<CustomPokemonAbilityDefinition> localAbilities;
  final CustomPokemonAdvancedData advanced;

  bool get hasImage => imageBase64 != null && imageBase64!.isNotEmpty;
  bool get hasShinyImage =>
      shinyImageBase64 != null && shinyImageBase64!.isNotEmpty;
""",
)
replace_once(
    path,
    """  Uint8List? get imageBytes {
    final encoded = imageBase64;
    if (encoded == null || encoded.isEmpty) return null;
    try {
      return Uint8List.fromList(base64Decode(encoded));
    } on FormatException {
      return null;
    }
  }

  Pokemon toPokemon() {
""",
    """  Uint8List? get imageBytes => _decodeImage(imageBase64);
  Uint8List? get shinyImageBytes => _decodeImage(shinyImageBase64);

  Pokemon toPokemon() {
""",
)
replace_once(
    path,
    """    return Pokemon(
      id: pokemonId,
""",
    """    final basePokemon = Pokemon(
      id: pokemonId,
""",
)
replace_once(
    path,
    """      weight: weight,
    );
  }

  Map<String, MoveData> localMoveCatalog() {
""",
    """      weight: weight,
    );
    return basePokemon.copyWith(
      formDefinitions: [
        for (final form in advanced.forms) form.toPokemonForm(basePokemon),
      ],
    );
  }

  Map<String, MoveData> localMoveCatalog() {
""",
)
replace_once(
    path,
    """      imageMimeType: _nullableText(json['imageMimeType']),
      imageBase64: _nullableText(json['imageBase64']),
      localMoves: _mapList(
""",
    """      imageMimeType: _nullableText(json['imageMimeType']),
      imageBase64: _nullableText(json['imageBase64']),
      shinyImageMimeType: _nullableText(json['shinyImageMimeType']),
      shinyImageBase64: _nullableText(json['shinyImageBase64']),
      localMoves: _mapList(
""",
)
replace_once(
    path,
    """      localAbilities: _mapList(
        json['localAbilities'],
      ).map(CustomPokemonAbilityDefinition.fromJson).toList(growable: false),
    );
""",
    """      localAbilities: _mapList(
        json['localAbilities'],
      ).map(CustomPokemonAbilityDefinition.fromJson).toList(growable: false),
      advanced: json['advanced'] is Map
          ? CustomPokemonAdvancedData.fromJson(
              Map<String, dynamic>.from(json['advanced'] as Map),
            )
          : const CustomPokemonAdvancedData(),
    );
""",
)
replace_once(
    path,
    """      if (imageMimeType != null) 'imageMimeType': imageMimeType,
      if (imageBase64 != null) 'imageBase64': imageBase64,
      'localMoves': localMoves.map((move) => move.toJson()).toList(),
""",
    """      if (imageMimeType != null) 'imageMimeType': imageMimeType,
      if (imageBase64 != null) 'imageBase64': imageBase64,
      if (shinyImageMimeType != null)
        'shinyImageMimeType': shinyImageMimeType,
      if (shinyImageBase64 != null) 'shinyImageBase64': shinyImageBase64,
      if (!advanced.isEmpty) 'advanced': advanced.toJson(),
      'localMoves': localMoves.map((move) => move.toJson()).toList(),
""",
)
replace_once(
    path,
    """    if (bytes != null && bytes.length > maxImageBytes) {
      throw const FormatException(
        'L’immagine del Fakemon supera il limite di 5 MB.',
      );
    }

    final moveIds = <String>{};
""",
    """    if (bytes != null && bytes.length > maxImageBytes) {
      throw const FormatException(
        'L’immagine del Fakemon supera il limite di 5 MB.',
      );
    }
    final shinyBytes = shinyImageBytes;
    if ((shinyImageMimeType == null) != (shinyBytes == null)) {
      throw const FormatException('Immagine shiny Fakemon incompleta o non valida.');
    }
    if (shinyImageMimeType != null &&
        !supportedImageMimeTypes.contains(shinyImageMimeType)) {
      throw FormatException(
        'Formato immagine shiny non supportato: $shinyImageMimeType.',
      );
    }
    if (shinyBytes != null && shinyBytes.length > maxImageBytes) {
      throw const FormatException(
        'L’immagine shiny del Fakemon supera il limite di 5 MB.',
      );
    }
    advanced.validate(currentPokemonId: pokemonId);

    final moveIds = <String>{};
""",
)
replace_once(
    path,
    """String? _nullableText(dynamic value) {
""",
    """Uint8List? _decodeImage(String? encoded) {
  if (encoded == null || encoded.isEmpty) return null;
  try {
    return Uint8List.fromList(base64Decode(encoded));
  } on FormatException {
    return null;
  }
}

String? _nullableText(dynamic value) {
""",
)

# Preserve advanced payload in single-file imports and copies.
path = 'lib/services/custom_pokemon_transfer_service.dart'
replace_once(
    path,
    """      imageMimeType: source.imageMimeType,
      imageBase64: source.imageBase64,
      localMoves: List<CustomPokemonMoveDefinition>.from(source.localMoves),
""",
    """      imageMimeType: source.imageMimeType,
      imageBase64: source.imageBase64,
      shinyImageMimeType: source.shinyImageMimeType,
      shinyImageBase64: source.shinyImageBase64,
      advanced: source.advanced,
      localMoves: List<CustomPokemonMoveDefinition>.from(source.localMoves),
""",
)

# Discovery persistence box.
path = 'lib/database/hive_boxes.dart'
replace_once(
    path,
    """  static const customPokemon = 'custom_pokemon';
  static const settings = 'settings';
""",
    """  static const customPokemon = 'custom_pokemon';
  static const customPokemonDiscovery = 'custom_pokemon_discovery';
  static const settings = 'settings';
""",
)

# Runtime access to advanced forms, images and references.
path = 'lib/services/custom_pokemon_runtime_registry.dart'
replace_once(
    path,
    """import '../models/custom_pokemon_definition.dart';
import '../models/move_data.dart';
""",
    """import '../models/custom_pokemon_advanced_data.dart';
import '../models/custom_pokemon_definition.dart';
import '../models/move_data.dart';
import '../models/pokemon.dart';
""",
)
replace_once(
    path,
    """  static Uint8List? imageBytesFor(int pokemonId) {
    return _definitions[pokemonId]?.imageBytes;
  }
""",
    """  static Uint8List? imageBytesFor(
    int pokemonId, {
    String? formName,
    bool shiny = false,
  }) {
    final definition = _definitions[pokemonId];
    if (definition == null) return null;
    final key = Pokemon.formReferenceKey(formName ?? '', definition.name);
    if (key.isNotEmpty && key != 'base') {
      for (final form in definition.advanced.forms) {
        final formKey = Pokemon.formReferenceKey(form.name, definition.name);
        final idKey = Pokemon.formReferenceKey(form.id, definition.name);
        if (key == formKey || key == idKey) {
          return shiny
              ? form.shinyImageBytes ?? form.imageBytes
              : form.imageBytes;
        }
      }
    }
    return shiny
        ? definition.shinyImageBytes ?? definition.imageBytes
        : definition.imageBytes;
  }

  static CustomPokemonDefinition? definitionByStableId(String? stableId) {
    if (stableId == null || stableId.isEmpty) return null;
    for (final definition in _definitions.values) {
      if (definition.stableId == stableId) return definition;
    }
    return null;
  }

  static CustomPokemonDefinition? resolveReference(
    CustomPokemonReference reference,
  ) {
    final byId = reference.pokemonId == null
        ? null
        : _definitions[reference.pokemonId];
    return byId ?? definitionByStableId(reference.stableId);
  }

  static bool isTemporaryForm(int pokemonId, String? formName) {
    final definition = _definitions[pokemonId];
    if (definition == null) return false;
    final key = Pokemon.formReferenceKey(formName ?? '', definition.name);
    return definition.advanced.forms.any(
      (form) =>
          form.duration == CustomPokemonFormDuration.battle &&
          (Pokemon.formReferenceKey(form.name, definition.name) == key ||
              Pokemon.formReferenceKey(form.id, definition.name) == key),
    );
  }

  static bool hasTemporaryForms(int pokemonId) {
    return _definitions[pokemonId]?.advanced.forms.any(
          (form) => form.duration == CustomPokemonFormDuration.battle,
        ) ==
        true;
  }
""",
)

# Custom form artwork.
path = 'lib/widgets/pokemon/pokemon_asset_image.dart'
replace_once(
    path,
    """    final customBytes = CustomPokemonRuntimeRegistry.imageBytesFor(
      effectivePokemon.id,
    );
""",
    """    final customBytes = CustomPokemonRuntimeRegistry.imageBytesFor(
      effectivePokemon.id,
      formName: effectiveForm,
      shiny: isShiny ?? false,
    );
""",
)
replace_once(
    path,
    """        key: ValueKey<String>('custom-${effectivePokemon.id}-$size'),
""",
    """        key: ValueKey<String>(
          'custom-${effectivePokemon.id}-${effectiveForm ?? 'base'}-${isShiny ?? false}-$size',
        ),
""",
)

# Hide temporary custom forms from the persistent form editor.
path = 'lib/screens/pokemon/pokemon_edit_screen.dart'
replace_once(
    path,
    """import '../../services/battle_form_change_service.dart';
""",
    """import '../../services/battle_form_change_service.dart';
import '../../services/custom_pokemon_runtime_registry.dart';
""",
)
replace_once(
    path,
    """    final rawFormChoices = await formChoicesFuture;
    final formChoices = _normalizedFormChoices(rawFormChoices);
""",
    """    final rawFormChoices = await formChoicesFuture;
    final persistentFormChoices = rawFormChoices
        .where(
          (choice) => !CustomPokemonRuntimeRegistry.isTemporaryForm(
            widget.pokemon.id,
            choice.name,
          ),
        )
        .toList(growable: false);
    final formChoices = _normalizedFormChoices(persistentFormChoices);
""",
)

# Battle Companion supports custom temporary forms.
path = 'lib/services/battle_form_change_service.dart'
replace_once(
    path,
    """import '../models/team_slot.dart';
""",
    """import '../models/team_slot.dart';
import 'custom_pokemon_runtime_registry.dart';
""",
)
replace_once(
    path,
    """  static bool supports(Pokemon pokemon) {
    return _supportedSpecies.contains(pokemon.name);
  }
""",
    """  static bool supports(Pokemon pokemon) {
    return _supportedSpecies.contains(pokemon.name) ||
        CustomPokemonRuntimeRegistry.hasTemporaryForms(pokemon.id);
  }
""",
)

# Full vs visible catalog for sealed player content.
path = 'lib/repositories/pokemon_repository.dart'
replace_once(
    path,
    """import '../models/pokemon_flavor.dart';
import 'custom_pokemon_repository.dart';
""",
    """import '../models/pokemon_flavor.dart';
import '../services/custom_pokemon_discovery_service.dart';
import 'custom_pokemon_repository.dart';
""",
)
replace_once(
    path,
    """  Future<List<Pokemon>> getAllPokemon() async {
    final customRevision = CustomPokemonRepository.revision;
    if (_cachedAllPokemon != null && _cachedCustomRevision == customRevision) {
      return List<Pokemon>.from(_cachedAllPokemon!);
    }
""",
    """  Future<List<Pokemon>> getAllPokemon({bool includeSealed = false}) async {
    final customRevision = CustomPokemonRepository.revision;
    if (_cachedAllPokemon != null && _cachedCustomRevision == customRevision) {
      return _filterSealed(_cachedAllPokemon!, includeSealed: includeSealed);
    }
""",
)
replace_once(
    path,
    """    return List<Pokemon>.from(pokemonList);
  }

  static void clearCache() {
""",
    """    return _filterSealed(pokemonList, includeSealed: includeSealed);
  }

  Future<List<Pokemon>> _filterSealed(
    List<Pokemon> pokemon, {
    required bool includeSealed,
  }) async {
    if (includeSealed) return List<Pokemon>.from(pokemon);
    final customDefinitions = await CustomPokemonRepository().getAll();
    final visible = await CustomPokemonDiscoveryService().visibleDefinitions(
      customDefinitions,
    );
    final visibleIds = visible.map((definition) => definition.pokemonId).toSet();
    return pokemon
        .where(
          (entry) =>
              entry.id < CustomPokemonDefinition.firstCustomPokemonId ||
              visibleIds.contains(entry.id),
        )
        .toList(growable: false);
  }

  static void clearCache() {
""",
)
replace_once(
    path,
    """import '../models/pokemon.dart';
import '../models/pokemon_flavor.dart';
""",
    """import '../models/custom_pokemon_definition.dart';
import '../models/pokemon.dart';
import '../models/pokemon_flavor.dart';
""",
)

# Evolution metadata for custom targets and secrets.
path = 'lib/models/evolution_data.dart'
replace_once(
    path,
    """    required this.conditions,
    required this.effects,
  });
""",
    """    required this.conditions,
    required this.effects,
    this.targetPokemonId,
    this.targetStableId,
    this.targetFormName,
    this.isSecret = false,
    this.secretHint,
  });
""",
)
replace_once(
    path,
    """  final List<EvolutionRule> conditions;
  final List<EvolutionRule> effects;
""",
    """  final List<EvolutionRule> conditions;
  final List<EvolutionRule> effects;
  final int? targetPokemonId;
  final String? targetStableId;
  final String? targetFormName;
  final bool isSecret;
  final String? secretHint;
""",
)

# Merge custom evolution links into the standard repository.
path = 'lib/repositories/evolution_repository.dart'
replace_once(
    path,
    """import '../models/evolution_data.dart';
""",
    """import '../models/custom_pokemon_advanced_data.dart';
import '../models/evolution_data.dart';
import '../services/custom_pokemon_runtime_registry.dart';
""",
)
replace_once(
    path,
    """      _cache = await _getWebappEvolutionData();
      return _cache!;
    } catch (_) {
      _cache = await _getLegacyEvolutionData();
      return _cache!;
""",
    """      _cache = _withCustomEvolutions(await _getWebappEvolutionData());
      return _cache!;
    } catch (_) {
      _cache = _withCustomEvolutions(await _getLegacyEvolutionData());
      return _cache!;
""",
)
replace_once(
    path,
    """  Future<Map<String, EvolutionData>> _getLegacyEvolutionData() async {
""",
    """  Map<String, EvolutionData> _withCustomEvolutions(
    Map<String, EvolutionData> base,
  ) {
    final grouped = <String, List<EvolutionOption>>{};
    for (final entry in base.entries) {
      grouped.putIfAbsent(_referenceKey(entry.key), () => <EvolutionOption>[])
        ..addAll(entry.value.options);
    }

    for (final definition in CustomPokemonRuntimeRegistry.definitions) {
      for (final link in definition.advanced.evolvesFrom) {
        final source = _resolvedReference(link.pokemon);
        if (source.name.isEmpty) continue;
        _addCustomOption(
          grouped,
          sourceName: source.name,
          targetName: definition.name,
          targetPokemonId: definition.pokemonId,
          targetStableId: definition.stableId,
          targetFormName: null,
          secret: definition.advanced.sealedForPlayer,
          link: link,
        );
      }
      for (final link in definition.advanced.evolvesTo) {
        final target = _resolvedReference(link.pokemon);
        if (target.name.isEmpty) continue;
        _addCustomOption(
          grouped,
          sourceName: definition.name,
          targetName: target.name,
          targetPokemonId: target.pokemonId,
          targetStableId: target.stableId,
          targetFormName: link.pokemon.formName,
          secret: target.definition?.advanced.sealedForPlayer == true,
          link: link,
        );
      }
    }

    final result = <String, EvolutionData>{};
    for (final entry in grouped.entries) {
      if (entry.value.isEmpty) continue;
      final data = EvolutionData.fromOptions(entry.value);
      result[entry.key] = data;
      final display = _displayNameFromKey(entry.key);
      result[display] = data;
      for (final definition in CustomPokemonRuntimeRegistry.definitions) {
        if (_referenceKey(definition.name) == entry.key) {
          result[definition.name] = data;
        }
      }
    }
    return result;
  }

  void _addCustomOption(
    Map<String, List<EvolutionOption>> grouped, {
    required String sourceName,
    required String targetName,
    required int? targetPokemonId,
    required String? targetStableId,
    required String? targetFormName,
    required bool secret,
    required CustomPokemonEvolutionLink link,
  }) {
    final sourceKey = _referenceKey(sourceName);
    final targetKey = _referenceKey(targetName);
    if (sourceKey.isEmpty || targetKey.isEmpty || sourceKey == targetKey) return;
    final options = grouped.putIfAbsent(sourceKey, () => <EvolutionOption>[]);
    if (options.any((option) => option.id == link.id)) return;
    options.add(
      EvolutionOption(
        id: link.id,
        fromKey: sourceKey,
        toKey: targetKey,
        toName: targetName,
        conditions: link.conditions
            .map((condition) => condition.toEvolutionRule())
            .toList(growable: false),
        effects: [
          if (link.asiPoints > 0)
            EvolutionRule(type: 'asi', value: link.asiPoints),
        ],
        targetPokemonId: targetPokemonId,
        targetStableId: targetStableId,
        targetFormName: targetFormName,
        isSecret: secret,
        secretHint: link.hint,
      ),
    );
  }

  _ResolvedCustomReference _resolvedReference(
    CustomPokemonReference reference,
  ) {
    final definition = CustomPokemonRuntimeRegistry.resolveReference(reference);
    return _ResolvedCustomReference(
      name: definition?.name ?? reference.name,
      pokemonId: definition?.pokemonId ?? reference.pokemonId,
      stableId: definition?.stableId ?? reference.stableId,
      definition: definition,
    );
  }

  String _referenceKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('♀', '-f')
        .replaceAll('♂', '-m')
        .replaceAll(RegExp(r\"[’']\"), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  Future<Map<String, EvolutionData>> _getLegacyEvolutionData() async {
""",
)
replace_once(
    path,
    """}
""",
    """}

class _ResolvedCustomReference {
  const _ResolvedCustomReference({
    required this.name,
    required this.pokemonId,
    required this.stableId,
    required this.definition,
  });

  final String name;
  final int? pokemonId;
  final String? stableId;
  final dynamic definition;
}
""",
)
# The previous replacement targets the first closing brace only; restore by moving
# the helper to the end when needed.
source = Path(path).read_text(encoding='utf-8')
helper = """\nclass _ResolvedCustomReference {\n  const _ResolvedCustomReference({\n    required this.name,\n    required this.pokemonId,\n    required this.stableId,\n    required this.definition,\n  });\n\n  final String name;\n  final int? pokemonId;\n  final String? stableId;\n  final dynamic definition;\n}\n"""
if source.count(helper) == 1 and source.index(helper) < source.index('class EvolutionRepository'):
    source = source.replace(helper, '', 1).rstrip() + helper
    Path(path).write_text(source, encoding='utf-8')

# Bump application version for the feature release.
path = 'pubspec.yaml'
replace_once(path, 'version: 1.0.2+3\n', 'version: 1.1.0+4\n')

# Changelog entry.
path = 'CHANGELOG.md'
source = Path(path).read_text(encoding='utf-8')
marker = '## [Non rilasciato]\n'
if marker not in source:
    raise SystemExit('CHANGELOG marker missing')
source = source.replace(
    marker,
    """## [Non rilasciato]\n\n## [1.1.0] - 2026-07-22\n\n### Aggiunto\n\n- evoluzioni personalizzate tra Pokémon ufficiali e Fakemon, comprese catene ramificate;\n- forme Fakemon permanenti e momentanee di battaglia con artwork e statistiche dedicate;\n- artwork shiny separato per specie e forme;\n- esportazione sigillata e scoperta per profilo dei Fakemon segreti;\n- editor avanzato per condizioni evolutive, indizi e visibilità Pokédex.\n\n### Corretto\n\n- preservazione dei collegamenti avanzati durante importazione, duplicazione e rimappatura degli ID.\n""",
    1,
)
Path(path).write_text(source, encoding='utf-8')
