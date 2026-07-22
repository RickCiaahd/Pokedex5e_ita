from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    source = file.read_text(encoding='utf-8')
    count = source.count(old)
    if count != 1:
        raise SystemExit(f'{path}: expected one match, found {count}')
    file.write_text(source.replace(old, new, 1), encoding='utf-8')


# Transfer bundle v2 supports sealed player packages.
path = 'lib/models/custom_pokemon_transfer_bundle.dart'
replace_once(
    path,
    """    required this.definition,
    required this.checksum,
  });
""",
    """    required this.definition,
    required this.checksum,
    this.sealed = false,
  });
""",
)
replace_once(path, '  static const int currentFormatVersion = 1;\n', '  static const int currentFormatVersion = 2;\n')
replace_once(
    path,
    """  final CustomPokemonDefinition definition;
  final String checksum;
""",
    """  final CustomPokemonDefinition definition;
  final String checksum;
  final bool sealed;
""",
)
replace_once(
    path,
    """  factory CustomPokemonTransferBundle.create(
    CustomPokemonDefinition definition, {
    DateTime? exportedAt,
  }) {
""",
    """  factory CustomPokemonTransferBundle.create(
    CustomPokemonDefinition definition, {
    DateTime? exportedAt,
    bool sealed = false,
  }) {
""",
)
replace_once(
    path,
    """      definition: definition,
    );
    return CustomPokemonTransferBundle(
""",
    """      definition: definition,
      sealed: sealed,
    );
    return CustomPokemonTransferBundle(
""",
)
replace_once(
    path,
    """      definition: definition,
      checksum: _checksum(jsonEncode(payload)),
    );
""",
    """      definition: definition,
      checksum: _checksum(jsonEncode(payload)),
      sealed: sealed,
    );
""",
)
replace_once(
    path,
    """    final definition = CustomPokemonDefinition.fromJson(
      Map<String, dynamic>.from(rawDefinition),
    );
    final checksum = json['checksum']?.toString() ?? '';
""",
    """    final definition = CustomPokemonDefinition.fromJson(
      Map<String, dynamic>.from(rawDefinition),
    );
    final sealed = json['sealed'] == true;
    final checksum = json['checksum']?.toString() ?? '';
""",
)
replace_once(
    path,
    """          definition: definition,
        ),
""",
    """          definition: definition,
          sealed: sealed,
        ),
""",
)
replace_once(
    path,
    """      definition: definition,
      checksum: checksum,
    );
""",
    """      definition: definition,
      checksum: checksum,
      sealed: sealed,
    );
""",
)
replace_once(
    path,
    """      definition: definition,
    );
    return {...payload, 'checksum': checksum};
""",
    """      definition: definition,
      sealed: sealed,
    );
    return {...payload, 'checksum': checksum};
""",
)
replace_once(
    path,
    """    required CustomPokemonDefinition definition,
  }) {
""",
    """    required CustomPokemonDefinition definition,
    required bool sealed,
  }) {
""",
)
replace_once(
    path,
    """      'exportedAt': exportedAt.toUtc().toIso8601String(),
      'definition': definition.toJson(),
""",
    """      'exportedAt': exportedAt.toUtc().toIso8601String(),
      'sealed': sealed,
      'definition': definition.toJson(),
""",
)

# Transfer service seals imports and neutralizes file names.
path = 'lib/services/custom_pokemon_transfer_service.dart'
replace_once(
    path,
    """  String encode(CustomPokemonDefinition definition) {
    final bundle = CustomPokemonTransferBundle.create(definition);
""",
    """  String encode(
    CustomPokemonDefinition definition, {
    bool sealed = false,
  }) {
    final exportedDefinition = CustomPokemonDefinition.fromJson({
      ...definition.toJson(),
      'advanced': definition.advanced
          .copyWith(clearSealedForPlayer: true)
          .toJson(),
    });
    final bundle = CustomPokemonTransferBundle.create(
      exportedDefinition,
      sealed: sealed,
    );
""",
)
replace_once(
    path,
    """  String fileNameFor(CustomPokemonDefinition definition) {
""",
    """  String fileNameFor(
    CustomPokemonDefinition definition, {
    bool sealed = false,
  }) {
""",
)
replace_once(
    path,
    """    return '${safeName.isEmpty ? 'fakemon' : safeName}.p5fakemon';
""",
    """    if (sealed) {
      return 'contenuto-campagna-${definition.stableId.hashCode.abs()}.p5secret';
    }
    return '${safeName.isEmpty ? 'fakemon' : safeName}.p5fakemon';
""",
)
replace_once(
    path,
    """    final incoming = bundle.definition;
    final existing = await _repository.getByStableId(incoming.stableId);
""",
    """    final incomingBase = bundle.definition;
    final incoming = CustomPokemonDefinition.fromJson({
      ...incomingBase.toJson(),
      'advanced': incomingBase.advanced
          .copyWith(sealedForPlayer: bundle.sealed)
          .toJson(),
    });
    final existing = await _repository.getByStableId(incoming.stableId);
""",
)

# Editor and library integration.
path = 'lib/screens/pokemon/custom_pokemon_library_screen.dart'
replace_once(
    path,
    """import '../../models/custom_pokemon_definition.dart';
""",
    """import '../../models/custom_pokemon_advanced_data.dart';
import '../../models/custom_pokemon_definition.dart';
""",
)
replace_once(
    path,
    """import '../../services/custom_pokemon_catalog_service.dart';
import '../../services/custom_pokemon_reference_service.dart';
""",
    """import '../../services/custom_pokemon_catalog_service.dart';
import '../../services/custom_pokemon_discovery_service.dart';
import '../../services/custom_pokemon_reference_service.dart';
""",
)
replace_once(
    path,
    """import '../../widgets/pokemon/pokemon_asset_image.dart';
""",
    """import '../../widgets/pokemon/pokemon_asset_image.dart';
import 'custom_pokemon_advanced_editor_screen.dart';
""",
)
replace_once(
    path,
    """  final CustomPokemonReferenceService _referenceService =
      CustomPokemonReferenceService();
""",
    """  final CustomPokemonReferenceService _referenceService =
      CustomPokemonReferenceService();
  final CustomPokemonDiscoveryService _discoveryService =
      CustomPokemonDiscoveryService();
""",
)
replace_once(
    path,
    """      final definitions = await _repository.getAll();
      if (!mounted) return;
      setState(() {
        _definitions = definitions;
""",
    """      final definitions = await _repository.getAll();
      final visibleDefinitions = await _discoveryService.visibleDefinitions(
        definitions,
      );
      if (!mounted) return;
      setState(() {
        _definitions = visibleDefinitions;
""",
)
replace_once(
    path,
    """  Future<void> _export(CustomPokemonDefinition definition) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final encoded = _transferService.encode(definition);
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Esporta ${definition.name}',
        fileName: _transferService.fileNameFor(definition),
        type: FileType.custom,
        allowedExtensions: const ['p5fakemon'],
""",
    """  Future<void> _export(CustomPokemonDefinition definition) async {
    if (_isBusy) return;
    var sealed = false;
    if (definition.advanced.secretUntilDiscovered) {
      final choice = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Modalità esportazione'),
          content: const Text(
            'Il pacchetto segreto non mostra nome, immagine o dati nell’app del giocatore prima della scoperta.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('NORMALE'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.lock_outline),
              label: const Text('SEGRETA'),
            ),
          ],
        ),
      );
      if (choice == null) return;
      sealed = choice;
    }
    setState(() => _isBusy = true);
    try {
      final encoded = _transferService.encode(definition, sealed: sealed);
      final result = await FilePicker.platform.saveFile(
        dialogTitle: sealed ? 'Esporta contenuto segreto' : 'Esporta ${definition.name}',
        fileName: _transferService.fileNameFor(definition, sealed: sealed),
        type: FileType.custom,
        allowedExtensions: sealed ? const ['p5secret'] : const ['p5fakemon'],
""",
)
replace_once(
    path,
    """        content: _transferService.encode(definition),
        fileName: _transferService.fileNameFor(definition),
""",
    """        content: _transferService.encode(
          definition,
          sealed: definition.advanced.secretUntilDiscovered,
        ),
        fileName: _transferService.fileNameFor(
          definition,
          sealed: definition.advanced.secretUntilDiscovered,
        ),
""",
)
replace_once(
    path,
    """        allowedExtensions: const ['p5fakemon', 'json'],
""",
    """        allowedExtensions: const ['p5fakemon', 'p5secret', 'json'],
""",
)
replace_once(
    path,
    """      _setMessage(
        imported.updatedExisting
            ? '${imported.definition.name} aggiornato.'
            : '${imported.definition.name} importato.',
      );
""",
    """      _setMessage(
        bundle.sealed
            ? 'Contenuto segreto installato. Sarà rivelato al momento della cattura o dell’evoluzione.'
            : imported.updatedExisting
                ? '${imported.definition.name} aggiornato.'
                : '${imported.definition.name} importato.',
      );
""",
)
replace_once(
    path,
    """  List<CustomPokemonAbilityDefinition> _localAbilities = [];
  List<MoveData> _globalMoves = const [];
""",
    """  List<CustomPokemonAbilityDefinition> _localAbilities = [];
  CustomPokemonAdvancedData _advanced = const CustomPokemonAdvancedData();
  List<MoveData> _globalMoves = const [];
""",
)
replace_once(
    path,
    """    _localMoves = [...?definition?.localMoves];
    _localAbilities = [...?definition?.localAbilities];
    _loadCatalogs();
""",
    """    _localMoves = [...?definition?.localMoves];
    _localAbilities = [...?definition?.localAbilities];
    _advanced = definition?.advanced ?? const CustomPokemonAdvancedData();
    _loadCatalogs();
""",
)
replace_once(
    path,
    """  Future<void> _addLocalMove() async {
""",
    """  Future<void> _openAdvancedEditor() async {
    final result = await Navigator.of(context).push<CustomPokemonAdvancedData>(
      MaterialPageRoute(
        builder: (_) => CustomPokemonAdvancedEditorScreen(
          initial: _advanced,
          currentName: _name.text.trim().isEmpty ? 'Nuovo Fakemon' : _name.text.trim(),
          currentPokemonId: widget.definition?.pokemonId,
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _advanced = result);
  }

  Future<void> _addLocalMove() async {
""",
)
replace_once(
    path,
    """        localMoves: _localMoves,
        localAbilities: _localAbilities,
      );
""",
    """        localMoves: _localMoves,
        localAbilities: _localAbilities,
        advanced: _advanced,
      );
""",
)
replace_once(
    path,
    """              _EditorSection(
                title: 'Allevamento',
""",
    """              _EditorSection(
                title: 'Evoluzioni, forme e segreti',
                children: [
                  Text(
                    '${_advanced.evolvesFrom.length} pre-evoluzioni · '
                    '${_advanced.evolvesTo.length} evoluzioni · '
                    '${_advanced.forms.length} forme',
                  ),
                  if (_advanced.secretUntilDiscovered)
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.lock_outline),
                      title: Text('Esportazione segreta disponibile'),
                      subtitle: Text(
                        'Il giocatore non vedrà il contenuto prima della scoperta.',
                      ),
                    ),
                  FilledButton.tonalIcon(
                    onPressed: _openAdvancedEditor,
                    icon: const Icon(Icons.account_tree_outlined),
                    label: const Text('APRI EDITOR AVANZATO'),
                  ),
                ],
              ),
              _EditorSection(
                title: 'Allevamento',
""",
)
replace_once(
    path,
    """                  Text('di ${definition.author} · ID ${definition.pokemonId}'),
                  const SizedBox(height: 6),
""",
    """                  Text('di ${definition.author} · ID ${definition.pokemonId}'),
                  if (definition.advanced.secretUntilDiscovered)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Chip(
                        avatar: Icon(Icons.lock_outline, size: 18),
                        label: Text('CONTENUTO SEGRETO'),
                      ),
                    ),
                  const SizedBox(height: 6),
""",
)

# Advanced payload preserved when embedded catalog IDs are remapped.
path = 'lib/services/embedded_custom_pokemon_transfer_service.dart'
replace_once(
    path,
    """    for (final definition in installedDefinitions) {
      final baseSpeciesId = definition.baseSpeciesId;
      if (baseSpeciesId == null) continue;
      final resolvedBaseSpeciesId = idMap[baseSpeciesId] ?? baseSpeciesId;
      if (resolvedBaseSpeciesId == baseSpeciesId) continue;
      final updatedDefinition = CustomPokemonDefinition.fromJson({
        ...definition.toJson(),
        'baseSpeciesId': resolvedBaseSpeciesId,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      });
      await _repository.save(updatedDefinition);
    }
""",
    """    for (final definition in installedDefinitions) {
      final json = definition.toJson();
      final baseSpeciesId = definition.baseSpeciesId;
      if (baseSpeciesId != null) {
        json['baseSpeciesId'] = idMap[baseSpeciesId] ?? baseSpeciesId;
      }
      final advanced = Map<String, dynamic>.from(
        json['advanced'] is Map ? json['advanced'] as Map : const {},
      );
      for (final key in ['evolvesFrom', 'evolvesTo']) {
        final links = advanced[key];
        if (links is! List) continue;
        advanced[key] = [
          for (final rawLink in links)
            if (rawLink is Map)
              {
                ...Map<String, dynamic>.from(rawLink),
                'pokemon': rawLink['pokemon'] is Map
                    ? {
                        ...Map<String, dynamic>.from(rawLink['pokemon'] as Map),
                        if ((rawLink['pokemon'] as Map)['pokemonId'] != null)
                          'pokemonId': idMap[
                                int.tryParse(
                                  (rawLink['pokemon'] as Map)['pokemonId']
                                      .toString(),
                                ),
                              ] ??
                              int.tryParse(
                                (rawLink['pokemon'] as Map)['pokemonId']
                                    .toString(),
                              ),
                      }
                    : rawLink['pokemon'],
              },
        ];
      }
      if (advanced.isNotEmpty) json['advanced'] = advanced;
      json['updatedAt'] = DateTime.now().toUtc().toIso8601String();
      await _repository.save(CustomPokemonDefinition.fromJson(json));
    }
""",
)
