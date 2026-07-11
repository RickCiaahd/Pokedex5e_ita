from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file_path = Path(path)
    text = file_path.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"Expected one match in {path}, found {count}: {old[:80]!r}")
    file_path.write_text(text.replace(old, new, 1), encoding="utf-8")


pokemon_path = "lib/models/pokemon.dart"
replace_once(
    pokemon_path,
    """    this.assetSlug,\n    this.genderRatio,\n    this.description,\n    this.formDefinitions = const [],\n""",
    """    this.assetSlug,\n    this.genderRatio,\n    this.description,\n    this.genus,\n    this.height,\n    this.weight,\n    this.formDefinitions = const [],\n""",
)
replace_once(
    pokemon_path,
    """  final String? assetSlug;\n  final String? genderRatio;\n  final String? description;\n  final List<PokemonFormDefinition> formDefinitions;\n""",
    """  final String? assetSlug;\n  final String? genderRatio;\n  final String? description;\n  final String? genus;\n  final int? height;\n  final int? weight;\n  final List<PokemonFormDefinition> formDefinitions;\n\n  double? get heightMeters => height == null ? null : height! / 10;\n  double? get weightKg => weight == null ? null : weight! / 10;\n""",
)
replace_once(
    pokemon_path,
    """  factory Pokemon.fromWebJson(Map<String, dynamic> json) {\n    final abilities = _readWebAbilities(json['abilities']);\n    final assetSlug = json['id']?.toString();\n\n    return Pokemon(\n      id: _readInt(json['number']),\n      name: _readWebDisplayName(json),\n      types: _readStringList(json['type']),\n      armorClass: _readInt(json['ac']),\n      hitPoints: _readInt(json['hp']),\n      size: json['size']?.toString() ?? 'Unknown',\n      speed: _readWebSpeed(json['speed']),\n      attributes: PokemonAttributes.fromWebJson(\n        Map<String, dynamic>.from(json['attributes'] ?? const {}),\n      ),\n      abilities: abilities.normal,\n      hiddenAbility: abilities.hidden,\n      skills: _readStringList(json['skills']).map(labelFromId).toList(),\n      savingThrows: _readStringList(\n        json['savingThrows'],\n      ).map((value) => value.toUpperCase()).toList(),\n      moves: PokemonMoves.fromWebJson(\n        Map<String, dynamic>.from(json['moves'] ?? const {}),\n      ),\n      hitDice: _readHitDice(json['hitDice']),\n      sr: _readDouble(json['sr']),\n      minLevelFound: _readInt(json['minLevel']),\n      assetSlug: assetSlug,\n      genderRatio: json['gender']?.toString(),\n      description: json['description']?.toString(),\n    );\n  }\n""",
    """  factory Pokemon.fromWebJson(\n    Map<String, dynamic> json, {\n    Map<String, dynamic>? physicalMetadata,\n  }) {\n    final abilities = _readWebAbilities(json['abilities']);\n    final assetSlug = json['id']?.toString();\n    final description = _parseWebDescription(json['description']?.toString());\n\n    return Pokemon(\n      id: _readInt(json['number']),\n      name: _readWebDisplayName(json),\n      types: _readStringList(json['type']),\n      armorClass: _readInt(json['ac']),\n      hitPoints: _readInt(json['hp']),\n      size: json['size']?.toString() ?? 'Unknown',\n      speed: _readWebSpeed(json['speed']),\n      attributes: PokemonAttributes.fromWebJson(\n        Map<String, dynamic>.from(json['attributes'] ?? const {}),\n      ),\n      abilities: abilities.normal,\n      hiddenAbility: abilities.hidden,\n      skills: _readStringList(json['skills']).map(labelFromId).toList(),\n      savingThrows: _readStringList(\n        json['savingThrows'],\n      ).map((value) => value.toUpperCase()).toList(),\n      moves: PokemonMoves.fromWebJson(\n        Map<String, dynamic>.from(json['moves'] ?? const {}),\n      ),\n      hitDice: _readHitDice(json['hitDice']),\n      sr: _readDouble(json['sr']),\n      minLevelFound: _readInt(json['minLevel']),\n      assetSlug: assetSlug,\n      genderRatio: json['gender']?.toString(),\n      description: description.flavor,\n      genus: description.genus,\n      height: _readNullableInt(physicalMetadata?['height']),\n      weight: _readNullableInt(physicalMetadata?['weight']),\n    );\n  }\n""",
)
replace_once(
    pokemon_path,
    """    for (final definition in formDefinitions) {\n      definitionsByKey.putIfAbsent(identity(definition), () => definition);\n    }\n    for (final definition in additionalDefinitions) {\n      definitionsByKey.putIfAbsent(identity(definition), () => definition);\n    }\n\n    return copyWith(\n      formDefinitions: definitionsByKey.values.toList(growable: false),\n    );\n  }\n\n  Pokemon copyWith({\n""",
    """    for (final definition in formDefinitions) {\n      definitionsByKey.putIfAbsent(identity(definition), () => definition);\n    }\n    for (final definition in additionalDefinitions) {\n      final key = identity(definition);\n      final existing = definitionsByKey[key];\n      if (existing == null) {\n        definitionsByKey[key] = definition;\n        continue;\n      }\n\n      definitionsByKey[key] = PokemonFormDefinition(\n        key: existing.key,\n        displayName: existing.displayName,\n        pokemon: existing.pokemon.withMetadataFrom(definition.pokemon),\n        gender: existing.gender ?? definition.gender,\n      );\n    }\n\n    return copyWith(\n      formDefinitions: definitionsByKey.values.toList(growable: false),\n    );\n  }\n\n  Pokemon withMetadataFrom(Pokemon metadata) {\n    return copyWith(\n      assetSlug: metadata.assetSlug,\n      genderRatio: metadata.genderRatio,\n      description: metadata.description,\n      genus: metadata.genus,\n      height: metadata.height,\n      weight: metadata.weight,\n    );\n  }\n\n  Pokemon copyWith({\n""",
)
replace_once(
    pokemon_path,
    """    String? assetSlug,\n    String? genderRatio,\n    String? description,\n    List<PokemonFormDefinition>? formDefinitions,\n""",
    """    String? assetSlug,\n    String? genderRatio,\n    String? description,\n    String? genus,\n    int? height,\n    int? weight,\n    List<PokemonFormDefinition>? formDefinitions,\n""",
)
replace_once(
    pokemon_path,
    """      assetSlug: assetSlug ?? this.assetSlug,\n      genderRatio: genderRatio ?? this.genderRatio,\n      description: description ?? this.description,\n      formDefinitions: formDefinitions ?? this.formDefinitions,\n""",
    """      assetSlug: assetSlug ?? this.assetSlug,\n      genderRatio: genderRatio ?? this.genderRatio,\n      description: description ?? this.description,\n      genus: genus ?? this.genus,\n      height: height ?? this.height,\n      weight: weight ?? this.weight,\n      formDefinitions: formDefinitions ?? this.formDefinitions,\n""",
)
replace_once(
    pokemon_path,
    """  static int _readInt(dynamic value) {\n    if (value is int) return value;\n    if (value is num) return value.toInt();\n    return int.tryParse(value?.toString() ?? '') ?? 0;\n  }\n""",
    """  static ({String? genus, String? flavor}) _parseWebDescription(\n    String? value,\n  ) {\n    final text = value?.trim() ?? '';\n    if (text.isEmpty) return (genus: null, flavor: null);\n\n    final match = RegExp(\n      r'^The (.+? Pokémon)\\.\\s*(.*)$',\n      caseSensitive: false,\n    ).firstMatch(text);\n    if (match == null) return (genus: null, flavor: text);\n\n    final genus = match.group(1)?.trim();\n    final flavor = match.group(2)?.trim();\n    return (\n      genus: genus == null || genus.isEmpty ? null : genus,\n      flavor: flavor == null || flavor.isEmpty ? null : flavor,\n    );\n  }\n\n  static int? _readNullableInt(dynamic value) {\n    if (value == null) return null;\n    if (value is int) return value;\n    if (value is num) return value.toInt();\n    return int.tryParse(value.toString());\n  }\n\n  static int _readInt(dynamic value) {\n    if (value is int) return value;\n    if (value is num) return value.toInt();\n    return int.tryParse(value?.toString() ?? '') ?? 0;\n  }\n""",
)

repository_path = "lib/repositories/pokemon_repository.dart"
replace_once(
    repository_path,
    """      pokemonByNumber[pokemon.id] = existing == null\n          ? pokemon\n          : existing.withAdditionalFormDefinitions(pokemon.formDefinitions);\n""",
    """      pokemonByNumber[pokemon.id] = existing == null\n          ? pokemon\n          : existing\n                .withMetadataFrom(pokemon)\n                .withAdditionalFormDefinitions(pokemon.formDefinitions);\n""",
)
replace_once(
    repository_path,
    """      final items = List<dynamic>.from(json['items'] ?? const []);\n      final grouped = <int, List<Pokemon>>{};\n\n      for (final item in items) {\n""",
    """      final items = List<dynamic>.from(json['items'] ?? const []);\n      final physicalMetadata = await _getWebappPhysicalMetadata();\n      final grouped = <int, List<Pokemon>>{};\n\n      for (final item in items) {\n""",
)
replace_once(
    repository_path,
    """          final pokemon = Pokemon.fromWebJson(Map<String, dynamic>.from(item));\n""",
    """          final itemJson = Map<String, dynamic>.from(item);\n          final assetSlug = itemJson['id']?.toString();\n          final pokemon = Pokemon.fromWebJson(\n            itemJson,\n            physicalMetadata: assetSlug == null\n                ? null\n                : physicalMetadata[assetSlug],\n          );\n""",
)
replace_once(
    repository_path,
    """  Pokemon _mergeWebFormGroup(List<Pokemon> group) {\n""",
    """  Future<Map<String, Map<String, dynamic>>>\n  _getWebappPhysicalMetadata() async {\n    try {\n      final jsonString = await rootBundle.loadString(\n        'assets/data_webapp/pokemon_physical.json',\n      );\n      final json = Map<String, dynamic>.from(jsonDecode(jsonString));\n      final rawItems = json['items'];\n      if (rawItems is! Map) return const {};\n\n      return {\n        for (final entry in rawItems.entries)\n          if (entry.value is Map)\n            entry.key.toString(): Map<String, dynamic>.from(entry.value as Map),\n      };\n    } catch (error) {\n      debugPrint('Metadati fisici delle forme non disponibili: $error');\n      return const {};\n    }\n  }\n\n  Pokemon _mergeWebFormGroup(List<Pokemon> group) {\n""",
)

dialog_path = "lib/widgets/pokedex/pokemon_summary_dialog.dart"
replace_once(
    dialog_path,
    """    final description = pokemon.description?.trim().isNotEmpty == true\n        ? pokemon.description!.trim()\n        : widget.flavor?.flavor.trim() ?? '';\n    final isBase = _selectedFormName == null;\n""",
    """    final isBase = _selectedFormName == null;\n    final webDescription = pokemon.description?.trim() ?? '';\n    final baseDescription = widget.flavor?.flavor.trim() ?? '';\n    final description = isBase\n        ? (baseDescription.isNotEmpty ? baseDescription : webDescription)\n        : (webDescription.isNotEmpty ? webDescription : baseDescription);\n    final webGenus = pokemon.genus?.trim() ?? '';\n    final baseGenus = widget.flavor?.genus.trim() ?? '';\n    final genus = isBase\n        ? (baseGenus.isNotEmpty ? baseGenus : webGenus)\n        : (webGenus.isNotEmpty ? webGenus : baseGenus);\n    final heightMeters = pokemon.heightMeters ?? widget.flavor?.heightMeters;\n    final weightKg = pokemon.weightKg ?? widget.flavor?.weightKg;\n""",
)
replace_once(
    dialog_path,
    """                if (isBase && widget.flavor != null) ...[\n                  Text(\n                    widget.flavor!.genus,\n                    style: const TextStyle(fontWeight: FontWeight.bold),\n                    textAlign: TextAlign.center,\n                  ),\n                  const SizedBox(height: 4),\n                  Text(\n                    'Altezza: ${widget.flavor!.heightMeters.toStringAsFixed(1)} m · '\n                    'Peso: ${widget.flavor!.weightKg.toStringAsFixed(1)} kg',\n                    textAlign: TextAlign.center,\n                  ),\n                  const SizedBox(height: 10),\n                ],\n""",
    """                if (genus.isNotEmpty) ...[\n                  Text(\n                    genus,\n                    style: const TextStyle(fontWeight: FontWeight.bold),\n                    textAlign: TextAlign.center,\n                  ),\n                  const SizedBox(height: 4),\n                ],\n                if (heightMeters != null && weightKg != null) ...[\n                  Text(\n                    'Altezza: ${heightMeters.toStringAsFixed(1)} m · '\n                    'Peso: ${weightKg.toStringAsFixed(1)} kg',\n                    textAlign: TextAlign.center,\n                  ),\n                  const SizedBox(height: 10),\n                ],\n""",
)

test_path = "test/pokemon_form_mechanics_test.dart"
replace_once(
    test_path,
    """    expect(alolan.types, containsAll(<String>['Dark', 'Normal']));\n    expect(alolan.abilities, contains('Gluttony'));\n    expect(alolan.moves.startingMoves, contains('Quick Attack'));\n""",
    """    expect(alolan.types, containsAll(<String>['Dark', 'Normal']));\n    expect(alolan.abilities, contains('Gluttony'));\n    expect(alolan.moves.startingMoves, contains('Quick Attack'));\n    expect(alolan.genus, 'Mouse Pokémon');\n    expect(alolan.description, startsWith('Night after night'));\n    expect(alolan.heightMeters, 0.3);\n    expect(alolan.weightKg, 3.8);\n""",
)

print("Applied form-specific Pokédex metadata changes")
