from pathlib import Path


def replace_once(path: Path, old: str, new: str, label: str) -> None:
    source = path.read_text(encoding='utf-8')
    count = source.count(old)
    if count != 1:
        raise SystemExit(f'{label}: expected one match, found {count}')
    path.write_text(source.replace(old, new, 1), encoding='utf-8')


backup = Path('lib/models/profile_backup.dart')
replace_once(
    backup,
    "import 'breeding_egg.dart';\n",
    "import 'breeding_egg.dart';\nimport 'custom_pokemon_definition.dart';\n",
    'backup custom import',
)
replace_once(
    backup,
    '  static const int currentFormatVersion = 5;\n',
    '  static const int currentFormatVersion = 6;\n',
    'backup version',
)
replace_once(
    backup,
    "    this.breedingEggs = const [],\n  });\n",
    "    this.breedingEggs = const [],\n    this.customPokemon = const [],\n  });\n",
    'backup constructor custom pokemon',
)
replace_once(
    backup,
    "  final List<BreedingEgg> breedingEggs;\n\n  int get seenSpecies",
    "  final List<BreedingEgg> breedingEggs;\n"
    "  final List<CustomPokemonDefinition> customPokemon;\n\n"
    "  int get seenSpecies",
    'backup custom field',
)
replace_once(
    backup,
    "  int get bagItemQuantity => bag.fold(\n    0,\n    (total, entry) => total + (entry.quantity > 0 ? entry.quantity : 0),\n  );\n\n  Map<String, dynamic> toJson() {\n",
    "  int get bagItemQuantity => bag.fold(\n"
    "    0,\n"
    "    (total, entry) => total + (entry.quantity > 0 ? entry.quantity : 0),\n"
    "  );\n\n"
    "  Set<int> get referencedPokemonIds {\n"
    "    final ids = <int>{};\n"
    "    for (final slot in team) {\n"
    "      final id = slot.pokemonId;\n"
    "      if (id != null && id > 0) ids.add(id);\n"
    "    }\n"
    "    ids.addAll(pc.map((pokemon) => pokemon.pokemonId).where((id) => id > 0));\n"
    "    ids.addAll(pokedex.map((entry) => entry.pokemonId).where((id) => id > 0));\n"
    "    for (final collection in encounterCollections) {\n"
    "      ids.addAll(\n"
    "        collection.entries.map((entry) => entry.pokemonId).where((id) => id > 0),\n"
    "      );\n"
    "    }\n"
    "    for (final encounter in savedEncounters) {\n"
    "      ids.addAll(\n"
    "        encounter.members.map((member) => member.pokemonId).where((id) => id > 0),\n"
    "      );\n"
    "    }\n"
    "    for (final trainer in savedNpcTrainers) {\n"
    "      ids.addAll(\n"
    "        trainer.team.map((member) => member.pokemonId).where((id) => id > 0),\n"
    "      );\n"
    "    }\n"
    "    final playerBattle = battleSession;\n"
    "    if (playerBattle != null) {\n"
    "      ids.addAll(\n"
    "        playerBattle.pokemonStates.values\n"
    "            .map((state) => state.pokemonId)\n"
    "            .where((id) => id > 0),\n"
    "      );\n"
    "    }\n"
    "    final masterBattle = masterBattleSession;\n"
    "    if (masterBattle != null) {\n"
    "      for (final participant in masterBattle.participants) {\n"
    "        ids.addAll(\n"
    "          participant.team\n"
    "              .map((state) => state.pokemon.pokemonId)\n"
    "              .where((id) => id > 0),\n"
    "        );\n"
    "      }\n"
    "    }\n"
    "    ids.addAll(\n"
    "      breedingEggs.map((egg) => egg.speciesId).where((id) => id > 0),\n"
    "    );\n"
    "    return Set<int>.unmodifiable(ids);\n"
    "  }\n\n"
    "  Map<String, dynamic> toJson() {\n",
    'backup referenced ids',
)
replace_once(
    backup,
    "      'breedingEggs': breedingEggs\n          .map((egg) => egg.toJson())\n          .toList(growable: false),\n    };\n",
    "      'breedingEggs': breedingEggs\n"
    "          .map((egg) => egg.toJson())\n"
    "          .toList(growable: false),\n"
    "      if (formatVersion >= 6)\n"
    "        'customPokemon': customPokemon\n"
    "            .map((definition) => definition.toJson())\n"
    "            .toList(growable: false),\n"
    "    };\n",
    'backup custom json',
)
replace_once(
    backup,
    "      breedingEggs: [\n        for (final value in _readMapList(json['breedingEggs'], 'breedingEggs'))\n          BreedingEgg.fromJson(value),\n      ],\n    );\n",
    "      breedingEggs: [\n"
    "        for (final value in _readMapList(json['breedingEggs'], 'breedingEggs'))\n"
    "          BreedingEgg.fromJson(value),\n"
    "      ],\n"
    "      customPokemon: [\n"
    "        for (final value in _readMapList(json['customPokemon'], 'customPokemon'))\n"
    "          CustomPokemonDefinition.fromJson(value),\n"
    "      ],\n"
    "    );\n",
    'backup custom decode',
)
replace_once(
    backup,
    "    final savedEncounterIds = <String>{};\n    for (final encounter in savedEncounters) {\n      if (!encounter.isValid) {\n        throw const FormatException(\n          'Il backup contiene un incontro salvato non valido.',\n        );\n      }\n      if (!savedEncounterIds.add(encounter.id)) {\n        throw FormatException(\n          'L’incontro ${encounter.name} è presente più volte.',\n        );\n      }\n    }\n  }\n",
    "    final savedEncounterIds = <String>{};\n"
    "    for (final encounter in savedEncounters) {\n"
    "      if (!encounter.isValid) {\n"
    "        throw const FormatException(\n"
    "          'Il backup contiene un incontro salvato non valido.',\n"
    "        );\n"
    "      }\n"
    "      if (!savedEncounterIds.add(encounter.id)) {\n"
    "        throw FormatException(\n"
    "          'L’incontro ${encounter.name} è presente più volte.',\n"
    "        );\n"
    "      }\n"
    "    }\n\n"
    "    final customByPokemonId = <int, CustomPokemonDefinition>{};\n"
    "    final customStableIds = <String>{};\n"
    "    for (final definition in customPokemon) {\n"
    "      definition.validate();\n"
    "      if (!customStableIds.add(definition.stableId) ||\n"
    "          customByPokemonId.containsKey(definition.pokemonId)) {\n"
    "        throw const FormatException(\n"
    "          'Il backup contiene definizioni Fakemon duplicate.',\n"
    "        );\n"
    "      }\n"
    "      customByPokemonId[definition.pokemonId] = definition;\n"
    "    }\n"
    "    if (formatVersion >= 6) {\n"
    "      final referencedCustomIds = referencedPokemonIds\n"
    "          .where(\n"
    "            (id) => id >= CustomPokemonDefinition.firstCustomPokemonId,\n"
    "          )\n"
    "          .toSet();\n"
    "      final missing = referencedCustomIds.difference(\n"
    "        customByPokemonId.keys.toSet(),\n"
    "      );\n"
    "      if (missing.isNotEmpty) {\n"
    "        final ordered = missing.toList()..sort();\n"
    "        throw FormatException(\n"
    "          'Il backup non include le definizioni Fakemon per '\n"
    "          '${ordered.map((id) => '#$id').join(', ')}.',\n"
    "        );\n"
    "      }\n"
    "      final unused = customByPokemonId.keys.toSet().difference(\n"
    "        referencedCustomIds,\n"
    "      );\n"
    "      if (unused.isNotEmpty) {\n"
    "        throw const FormatException(\n"
    "          'Il backup contiene definizioni Fakemon non utilizzate.',\n"
    "        );\n"
    "      }\n"
    "    }\n"
    "  }\n",
    'backup custom validation',
)

service = Path('lib/services/profile_backup_service.dart')
replace_once(
    service,
    "import '../repositories/team_repository.dart';\n",
    "import '../repositories/team_repository.dart';\n"
    "import 'embedded_custom_pokemon_transfer_service.dart';\n",
    'backup service embedded import',
)
replace_once(
    service,
    "    BreedingEggRepository? breedingEggRepository,\n  }) : _profileRepository",
    "    BreedingEggRepository? breedingEggRepository,\n"
    "    EmbeddedCustomPokemonTransferService? embeddedCustomPokemonService,\n"
    "  }) : _profileRepository",
    'backup service constructor parameter',
)
replace_once(
    service,
    "       _breedingEggRepository =\n           breedingEggRepository ?? BreedingEggRepository();\n",
    "       _breedingEggRepository =\n"
    "           breedingEggRepository ?? BreedingEggRepository(),\n"
    "       _embeddedCustomPokemonService =\n"
    "           embeddedCustomPokemonService ??\n"
    "           EmbeddedCustomPokemonTransferService();\n",
    'backup service initializer',
)
replace_once(
    service,
    "  final BreedingEggRepository _breedingEggRepository;\n\n  Future<ProfileBackup> createBackup",
    "  final BreedingEggRepository _breedingEggRepository;\n"
    "  final EmbeddedCustomPokemonTransferService _embeddedCustomPokemonService;\n\n"
    "  Future<ProfileBackup> createBackup",
    'backup service field',
)
replace_once(
    service,
    "    return ProfileBackup(\n      formatVersion: ProfileBackup.currentFormatVersion,\n      exportedAt: DateTime.now(),\n      profile: profile,\n      pokedex: pokedex,\n      team: team,\n      pc: pc,\n      bag: bag,\n      settings: settings,\n      battleSession: battleSession,\n      encounterCollections: encounterCollections,\n      savedEncounters: savedEncounters,\n      savedNpcTrainers: savedNpcTrainers,\n      masterBattleSession: masterBattleSession,\n      breedingEggs: breedingEggs,\n    );\n",
    "    final draft = ProfileBackup(\n"
    "      formatVersion: 5,\n"
    "      exportedAt: DateTime.now(),\n"
    "      profile: profile,\n"
    "      pokedex: pokedex,\n"
    "      team: team,\n"
    "      pc: pc,\n"
    "      bag: bag,\n"
    "      settings: settings,\n"
    "      battleSession: battleSession,\n"
    "      encounterCollections: encounterCollections,\n"
    "      savedEncounters: savedEncounters,\n"
    "      savedNpcTrainers: savedNpcTrainers,\n"
    "      masterBattleSession: masterBattleSession,\n"
    "      breedingEggs: breedingEggs,\n"
    "    );\n"
    "    final customPokemon = await _embeddedCustomPokemonService\n"
    "        .definitionsForPokemonIds(draft.referencedPokemonIds);\n"
    "    return ProfileBackup(\n"
    "      formatVersion: ProfileBackup.currentFormatVersion,\n"
    "      exportedAt: draft.exportedAt,\n"
    "      profile: draft.profile,\n"
    "      pokedex: draft.pokedex,\n"
    "      team: draft.team,\n"
    "      pc: draft.pc,\n"
    "      bag: draft.bag,\n"
    "      settings: draft.settings,\n"
    "      battleSession: draft.battleSession,\n"
    "      encounterCollections: draft.encounterCollections,\n"
    "      savedEncounters: draft.savedEncounters,\n"
    "      savedNpcTrainers: draft.savedNpcTrainers,\n"
    "      masterBattleSession: draft.masterBattleSession,\n"
    "      breedingEggs: draft.breedingEggs,\n"
    "      customPokemon: customPokemon,\n"
    "    );\n",
    'create portable profile backup',
)
replace_once(
    service,
    "    backup.validate();\n    final profiles = await _profileRepository.getProfiles();\n",
    "    backup.validate();\n"
    "    final installResult = await _embeddedCustomPokemonService\n"
    "        .installDefinitions(backup.customPokemon);\n"
    "    final resolvedBackup = _remapBackupPokemonIds(\n"
    "      backup,\n"
    "      installResult.pokemonIdMap,\n"
    "    );\n"
    "    final profiles = await _profileRepository.getProfiles();\n",
    'install backup fakemon',
)
replace_once(
    service,
    "    final trimmedName = (profileName ?? backup.profile.name).trim();\n",
    "    final trimmedName = (profileName ?? resolvedBackup.profile.name).trim();\n",
    'resolved backup name',
)
replace_once(
    service,
    "    final importedProfile = backup.profile.copyWith(\n",
    "    final importedProfile = resolvedBackup.profile.copyWith(\n",
    'resolved backup profile',
)
replace_once(
    service,
    "      await _writeBackupData(\n        backup: backup,\n        profile: importedProfile,\n",
    "      await _writeBackupData(\n"
    "        backup: resolvedBackup,\n"
    "        profile: importedProfile,\n",
    'write resolved backup',
)
replace_once(
    service,
    "  Future<UserProfile> duplicateProfile(String profileId) async {\n",
    "  ProfileBackup _remapBackupPokemonIds(\n"
    "    ProfileBackup backup,\n"
    "    Map<int, int> pokemonIdMap,\n"
    "  ) {\n"
    "    if (pokemonIdMap.isEmpty ||\n"
    "        pokemonIdMap.entries.every((entry) => entry.key == entry.value)) {\n"
    "      return backup;\n"
    "    }\n"
    "    final json = Map<String, dynamic>.from(backup.toJson());\n"
    "    json['formatVersion'] = 5;\n"
    "    json.remove('customPokemon');\n"
    "    _remapPokemonIdsInJson(json, pokemonIdMap);\n"
    "    return ProfileBackup.fromJson(json);\n"
    "  }\n\n"
    "  void _remapPokemonIdsInJson(\n"
    "    dynamic node,\n"
    "    Map<int, int> pokemonIdMap,\n"
    "  ) {\n"
    "    if (node is List) {\n"
    "      for (final value in node) {\n"
    "        _remapPokemonIdsInJson(value, pokemonIdMap);\n"
    "      }\n"
    "      return;\n"
    "    }\n"
    "    if (node is! Map) return;\n"
    "    for (final key in node.keys.toList()) {\n"
    "      final value = node[key];\n"
    "      if ((key == 'pokemonId' || key == 'speciesId') && value is num) {\n"
    "        node[key] = pokemonIdMap[value.toInt()] ?? value.toInt();\n"
    "      } else if (key == 'identityKey' && value is String) {\n"
    "        final separator = value.indexOf('::');\n"
    "        final rawId = separator < 0 ? value : value.substring(0, separator);\n"
    "        final sourceId = int.tryParse(rawId);\n"
    "        final targetId = sourceId == null ? null : pokemonIdMap[sourceId];\n"
    "        if (targetId != null) {\n"
    "          node[key] = separator < 0\n"
    "              ? targetId.toString()\n"
    "              : '${targetId}${value.substring(separator)}';\n"
    "        }\n"
    "      } else {\n"
    "        _remapPokemonIdsInJson(value, pokemonIdMap);\n"
    "      }\n"
    "    }\n"
    "  }\n\n"
    "  Future<UserProfile> duplicateProfile(String profileId) async {\n",
    'backup id remapper',
)

library = Path('lib/screens/pokemon/custom_pokemon_library_screen.dart')
replace_once(
    library,
    "import '../../services/custom_pokemon_transfer_service.dart';\n",
    "import '../../services/custom_pokemon_catalog_service.dart';\n"
    "import '../../services/custom_pokemon_reference_service.dart';\n"
    "import '../../services/custom_pokemon_transfer_service.dart';\n",
    'library service imports',
)
replace_once(
    library,
    "  final NativeShareService _shareService = const NativeShareService();\n",
    "  final NativeShareService _shareService = const NativeShareService();\n"
    "  final CustomPokemonCatalogService _catalogService =\n"
    "      CustomPokemonCatalogService();\n"
    "  final CustomPokemonReferenceService _referenceService =\n"
    "      CustomPokemonReferenceService();\n",
    'library service fields',
)
start = library.read_text(encoding='utf-8')
old_delete_start = start.index('  Future<void> _delete(CustomPokemonDefinition definition) async {')
old_delete_end = start.index('\n  Future<void> _export(CustomPokemonDefinition definition) async {', old_delete_start)
new_delete = """  Future<void> _delete(CustomPokemonDefinition definition) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    CustomPokemonReferenceReport report;
    try {
      report = await _referenceService.findReferences(definition.pokemonId);
    } catch (error) {
      _setMessage(_friendlyError(error), isError: true);
      if (mounted) setState(() => _isBusy = false);
      return;
    }
    if (!mounted) return;
    setState(() => _isBusy = false);

    if (report.isInUse) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Impossibile eliminare ${definition.name}'),
          content: SizedBox(
            width: 620,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'La specie è ancora utilizzata. Rimuovi prima tutti i riferimenti elencati:',
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final reference in report.references)
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.link),
                            title: Text(reference.location),
                            subtitle: Text(
                              '${reference.profileName} · ${reference.detail}',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Eliminare ${definition.name}?'),
        content: const Text(
          'La specie non è utilizzata da nessun profilo e verrà rimossa dal catalogo globale.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ANNULLA'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('ELIMINA'),
          ),
        ],
      ),
    );
    if (confirmed != true || _isBusy) return;

    setState(() => _isBusy = true);
    try {
      await _repository.delete(definition.stableId);
      PokemonRepository.clearCache();
      await _load();
      _setMessage('${definition.name} eliminato.');
    } catch (error) {
      _setMessage(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _exportCatalog() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final bundle = await _catalogService.createBundle();
      final encoded = _catalogService.encode(bundle);
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Esporta catalogo Fakemon',
        fileName: _catalogService.fileNameFor(bundle),
        type: FileType.custom,
        allowedExtensions: const ['p5fakemonpack'],
        bytes: Uint8List.fromList(utf8.encode(encoded)),
      );
      _setMessage(
        result == null
            ? 'Esportazione catalogo annullata.'
            : '${bundle.definitions.length} Fakemon esportati.',
      );
    } catch (error) {
      _setMessage(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _importCatalog() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Importa catalogo Fakemon',
        type: FileType.custom,
        allowedExtensions: const ['p5fakemonpack', 'json'],
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        _setMessage('Importazione catalogo annullata.');
        return;
      }
      final picked = result.files.single;
      final bytes = picked.bytes ?? await picked.xFile.readAsBytes();
      final bundle = _catalogService.decode(
        utf8.decode(bytes, allowMalformed: false),
      );
      final imported = await _catalogService.importBundle(bundle);
      PokemonRepository.clearCache();
      await _load();
      _setMessage(
        'Catalogo importato: ${imported.installed} installati, '
        '${imported.updated} aggiornati, ${imported.remapped} rimappati.',
      );
    } catch (error) {
      _setMessage(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }
"""
start = start[:old_delete_start] + new_delete + start[old_delete_end:]
library.write_text(start, encoding='utf-8')
replace_once(
    library,
    "        actions: [\n          IconButton(\n            tooltip: 'Importa Fakemon',\n            onPressed: _isBusy ? null : _import,\n            icon: const Icon(Icons.file_download_outlined),\n          ),\n        ],\n",
    "        actions: [\n"
    "          PopupMenuButton<String>(\n"
    "            tooltip: 'Importa ed esporta',\n"
    "            enabled: !_isBusy,\n"
    "            onSelected: (value) {\n"
    "              switch (value) {\n"
    "                case 'import-single':\n"
    "                  _import();\n"
    "                  break;\n"
    "                case 'import-catalog':\n"
    "                  _importCatalog();\n"
    "                  break;\n"
    "                case 'export-catalog':\n"
    "                  _exportCatalog();\n"
    "                  break;\n"
    "              }\n"
    "            },\n"
    "            itemBuilder: (_) => const [\n"
    "              PopupMenuItem(\n"
    "                value: 'import-single',\n"
    "                child: Text('Importa Fakemon'),\n"
    "              ),\n"
    "              PopupMenuItem(\n"
    "                value: 'import-catalog',\n"
    "                child: Text('Importa catalogo'),\n"
    "              ),\n"
    "              PopupMenuItem(\n"
    "                value: 'export-catalog',\n"
    "                child: Text('Esporta catalogo'),\n"
    "              ),\n"
    "            ],\n"
    "          ),\n"
    "        ],\n",
    'library catalog menu',
)

changelog = Path('CHANGELOG.md')
replace_once(
    changelog,
    '### Modificato\n\n',
    '### Modificato\n\n'
    '- i backup profilo includono automaticamente i Fakemon utilizzati e ne rimappano i riferimenti durante l importazione; il catalogo globale può essere esportato e importato in blocco e l eliminazione di una specie è bloccata finché esistono riferimenti nei profili;\n',
    'changelog backup safe delete',
)
