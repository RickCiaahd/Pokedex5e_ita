import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../localization/ui_text.dart';
import '../../localization/user_facing_error.dart';
import '../../models/custom_pokemon_advanced_data.dart';
import '../../models/custom_pokemon_definition.dart';
import '../../models/move_data.dart';
import '../../models/pokemon_attributes.dart';
import '../../repositories/ability_repository.dart';
import '../../repositories/custom_pokemon_repository.dart';
import '../../repositories/move_repository.dart';
import '../../repositories/pokemon_repository.dart';
import '../../services/custom_pokemon_catalog_service.dart';
import '../../services/custom_pokemon_discovery_service.dart';
import '../../services/custom_pokemon_reference_service.dart';
import '../../services/custom_pokemon_transfer_service.dart';
import '../../services/native_share_service.dart';
import '../../widgets/layout/responsive_content.dart';
import '../../widgets/navigation/home_leading_button.dart';
import '../../widgets/pokemon/pokemon_asset_image.dart';
import 'custom_pokemon_advanced_editor_screen.dart';

enum _ImportChoice { update, copy }

class CustomPokemonLibraryScreen extends StatefulWidget {
  const CustomPokemonLibraryScreen({super.key});

  @override
  State<CustomPokemonLibraryScreen> createState() =>
      _CustomPokemonLibraryScreenState();
}

class _CustomPokemonLibraryScreenState
    extends State<CustomPokemonLibraryScreen> {
  final CustomPokemonRepository _repository = CustomPokemonRepository();
  final CustomPokemonTransferService _transferService =
      CustomPokemonTransferService();
  final NativeShareService _shareService = NativeShareService();
  final CustomPokemonCatalogService _catalogService =
      CustomPokemonCatalogService();
  final CustomPokemonReferenceService _referenceService =
      CustomPokemonReferenceService();
  final CustomPokemonDiscoveryService _discoveryService =
      CustomPokemonDiscoveryService();

  List<CustomPokemonDefinition> _definitions = [];
  bool _isLoading = true;
  bool _isBusy = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final definitions = await _repository.getAll();
      final visibleDefinitions = await _discoveryService.visibleDefinitions(
        definitions,
      );
      if (!mounted) return;
      setState(() {
        _definitions = visibleDefinitions;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      _setMessage(
        context.userFacingError(error, action: UserFacingErrorAction.load),
        isError: true,
      );
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _message = message;
      _messageIsError = isError;
    });
  }

  Future<void> _openEditor([CustomPokemonDefinition? definition]) async {
    final saved = await Navigator.of(context).push<CustomPokemonDefinition>(
      MaterialPageRoute(
        builder: (_) => CustomPokemonEditorScreen(definition: definition),
      ),
    );
    if (!mounted || saved == null) return;
    PokemonRepository.clearCache();
    await _load();
    _setMessage(
      uiTextForLanguage(
        '${saved.name} salvato nel catalogo Fakemon.',
        """${saved.name} saved to the Fakemon catalog.""",
      ),
    );
  }

  Future<void> _duplicate(CustomPokemonDefinition source) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final now = DateTime.now().toUtc();
      final duplicate = _copyDefinition(
        source,
        stableId: _repository.createStableId(),
        pokemonId: await _repository.allocatePokemonId(),
        name: uiTextForLanguage(
          '${source.name} (copia)',
          '${source.name} (copy)',
        ),
        createdAt: now,
        updatedAt: now,
      );
      await _repository.save(duplicate);
      PokemonRepository.clearCache();
      await _load();
      _setMessage(
        uiTextForLanguage(
          '${duplicate.name} creato.',
          '${duplicate.name} created.',
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _setMessage(
        context.userFacingError(error, action: UserFacingErrorAction.save),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _delete(CustomPokemonDefinition definition) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    CustomPokemonReferenceReport report;
    try {
      report = await _referenceService.findReferences(definition.pokemonId);
    } catch (error) {
      if (!mounted) return;
      _setMessage(context.userFacingError(error), isError: true);
      if (mounted) setState(() => _isBusy = false);
      return;
    }
    if (!mounted) return;
    setState(() => _isBusy = false);

    if (report.isInUse) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(
            uiTextForLanguage(
              'Impossibile eliminare ${definition.name}',
              'Cannot delete ${definition.name}',
            ),
          ),
          content: SizedBox(
            width: 620,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  uiTextForLanguage(
                    'La specie è ancora utilizzata. Rimuovi prima tutti i riferimenti elencati:',
                    """This species is still in use. Remove all listed references first:""",
                  ),
                ),
                SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 420),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: report.references.length,
                    itemBuilder: (context, index) {
                      final reference = report.references[index];
                      return ListTile(
                        dense: true,
                        leading: Icon(Icons.link),
                        title: Text(reference.location),
                        subtitle: Text(
                          '${reference.profileName} · ${reference.detail}',
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          uiTextForLanguage(
            'Eliminare ${definition.name}?',
            'Delete ${definition.name}?',
          ),
        ),
        content: Text(
          uiTextForLanguage(
            'La specie non è utilizzata da nessun profilo e verrà rimossa dal catalogo globale.',
            """This species is not used by any profile and will be removed from the global catalog.""",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(uiTextForLanguage('ANNULLA', """CANCEL""")),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(uiTextForLanguage('ELIMINA', """DELETE""")),
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
      _setMessage(
        uiTextForLanguage(
          '${definition.name} eliminato.',
          '${definition.name} deleted.',
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _setMessage(
        context.userFacingError(error, action: UserFacingErrorAction.save),
        isError: true,
      );
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
        dialogTitle: uiTextForLanguage(
          'Esporta catalogo Fakemon',
          """Export Fakemon catalog""",
        ),
        fileName: _catalogService.fileNameFor(bundle),
        type: FileType.custom,
        allowedExtensions: ['p5fakemonpack'],
        bytes: Uint8List.fromList(utf8.encode(encoded)),
      );
      _setMessage(
        result == null
            ? uiTextForLanguage(
                'Esportazione catalogo annullata.',
                """Catalog export cancelled.""",
              )
            : uiTextForLanguage(
                '${bundle.definitions.length} Fakemon esportati.',
                '${bundle.definitions.length} Fakemon exported.',
              ),
      );
    } catch (error) {
      if (!mounted) return;
      _setMessage(
        context.userFacingError(
          error,
          action: UserFacingErrorAction.exportFile,
        ),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _importCatalog() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: uiTextForLanguage(
          'Importa catalogo Fakemon',
          """Import Fakemon catalog""",
        ),
        type: FileType.custom,
        allowedExtensions: ['p5fakemonpack', 'json'],
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        _setMessage(
          uiTextForLanguage(
            'Importazione catalogo annullata.',
            """Catalog import cancelled.""",
          ),
        );
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
        uiTextForLanguage(
          'Catalogo importato: ${imported.installed} installati, '
              '${imported.updated} aggiornati, ${imported.remapped} rimappati.',
          'Catalog imported: ${imported.installed} installed, '
              '${imported.updated} updated, ${imported.remapped} remapped.',
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _setMessage(
        context.userFacingError(
          error,
          action: UserFacingErrorAction.importFile,
        ),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _export(CustomPokemonDefinition definition) async {
    if (_isBusy) return;
    var sealed = false;
    if (definition.advanced.secretUntilDiscovered) {
      final choice = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(
            uiTextForLanguage('Modalità esportazione', """Export mode"""),
          ),
          content: Text(
            uiTextForLanguage(
              'Il pacchetto segreto non mostra nome, immagine o dati nell’app del giocatore prima della scoperta.',
              """The secret package does not show its name, image or data in the player app before discovery.""",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(uiTextForLanguage('NORMALE', 'NORMAL')),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: Icon(Icons.lock_outline),
              label: Text(uiTextForLanguage('SEGRETA', 'SECRET')),
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
        dialogTitle: sealed
            ? uiTextForLanguage(
                'Esporta contenuto segreto',
                """Export secret content""",
              )
            : uiTextForLanguage(
                'Esporta ${definition.name}',
                """Export ${definition.name}""",
              ),
        fileName: _transferService.fileNameFor(definition, sealed: sealed),
        type: FileType.custom,
        allowedExtensions: sealed ? ['p5secret'] : ['p5fakemon'],
        bytes: Uint8List.fromList(utf8.encode(encoded)),
      );
      _setMessage(
        result == null
            ? uiTextForLanguage(
                'Esportazione annullata.',
                """Export cancelled.""",
              )
            : uiTextForLanguage(
                '${definition.name} esportato correttamente.',
                """${definition.name} exported successfully.""",
              ),
      );
    } catch (error) {
      if (!mounted) return;
      _setMessage(
        context.userFacingError(
          error,
          action: UserFacingErrorAction.exportFile,
        ),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _share(CustomPokemonDefinition definition) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final outcome = await _shareService.shareTextFile(
        context: context,
        content: _transferService.encode(
          definition,
          sealed: definition.advanced.secretUntilDiscovered,
        ),
        fileName: _transferService.fileNameFor(
          definition,
          sealed: definition.advanced.secretUntilDiscovered,
        ),
        mimeType: 'application/json',
        title: uiTextForLanguage(
          'Condividi ${definition.name}',
          """Share ${definition.name}""",
        ),
        subject: 'Fakemon ${definition.name}',
        text: uiTextForLanguage(
          'Fakemon creato con Trainer Atlas 5e.',
          'Fakemon created with Trainer Atlas 5e.',
        ),
      );
      _setMessage(
        _shareService.feedback(
          outcome,
          successMessage: uiTextForLanguage(
            '${definition.name} condiviso.',
            '${definition.name} shared.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _setMessage(
        context.userFacingError(error, action: UserFacingErrorAction.share),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _import() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: uiTextForLanguage('Importa Fakemon', """Import Fakemon"""),
        type: FileType.custom,
        allowedExtensions: ['p5fakemon', 'p5secret', 'json'],
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        _setMessage(
          uiTextForLanguage('Importazione annullata.', """Import cancelled."""),
        );
        return;
      }
      final picked = result.files.single;
      final bytes = picked.bytes ?? await picked.xFile.readAsBytes();
      final bundle = _transferService.decode(
        utf8.decode(bytes, allowMalformed: false),
      );
      final existing = await _repository.getByStableId(
        bundle.definition.stableId,
      );

      var duplicate = false;
      if (existing != null && mounted) {
        final choice = await showDialog<_ImportChoice>(
          context: context,
          builder: (_) => _FakemonImportDialog(
            incoming: bundle.definition,
            existing: existing,
          ),
        );
        if (choice == null) {
          _setMessage(
            uiTextForLanguage(
              'Importazione annullata.',
              """Import cancelled.""",
            ),
          );
          return;
        }
        duplicate = choice == _ImportChoice.copy;
      }

      final imported = await _transferService.importBundle(
        bundle,
        duplicate: duplicate,
      );
      PokemonRepository.clearCache();
      await _load();
      _setMessage(
        bundle.sealed
            ? uiTextForLanguage(
                'Contenuto segreto installato. Sarà rivelato al momento della cattura o dell’evoluzione.',
                """Secret content installed. It will be revealed upon capture or evolution.""",
              )
            : imported.updatedExisting
            ? uiTextForLanguage(
                '${imported.definition.name} aggiornato.',
                '${imported.definition.name} updated.',
              )
            : uiTextForLanguage(
                '${imported.definition.name} importato.',
                """${imported.definition.name} imported.""",
              ),
      );
    } catch (error) {
      if (!mounted) return;
      _setMessage(
        context.userFacingError(
          error,
          action: UserFacingErrorAction.importFile,
        ),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: HomeLeadingButton(),
        title: Text(uiTextForLanguage('I MIEI FAKEMON', 'MY FAKEMON')),
        actions: [
          PopupMenuButton<String>(
            tooltip: uiTextForLanguage(
              'Importa ed esporta',
              """Import and export""",
            ),
            enabled: !_isBusy,
            onSelected: (value) {
              switch (value) {
                case 'import-single':
                  _import();
                  break;
                case 'import-catalog':
                  _importCatalog();
                  break;
                case 'export-catalog':
                  _exportCatalog();
                  break;
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'import-single',
                child: Text(
                  uiTextForLanguage('Importa Fakemon', """Import Fakemon"""),
                ),
              ),
              PopupMenuItem(
                value: 'import-catalog',
                child: Text(
                  uiTextForLanguage('Importa catalogo', """Import catalog"""),
                ),
              ),
              PopupMenuItem(
                value: 'export-catalog',
                child: Text(
                  uiTextForLanguage('Esporta catalogo', """Export catalog"""),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isBusy ? null : () => _openEditor(),
        icon: Icon(Icons.add),
        label: Text(uiTextForLanguage('NUOVO FAKEMON', """NEW FAKEMON""")),
      ),
      body: ResponsiveContent(
        maxWidth: 980,
        child: Column(
          children: [
            if (_isBusy) LinearProgressIndicator(),
            if (_message != null)
              Container(
                width: double.infinity,
                margin: EdgeInsets.fromLTRB(12, 10, 12, 0),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _messageIsError
                      ? Theme.of(context).colorScheme.errorContainer
                      : Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_message!),
              ),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _definitions.isEmpty
                  ? _EmptyFakemonState()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: EdgeInsets.fromLTRB(12, 8, 12, 100),
                        itemCount: _definitions.length,
                        itemBuilder: (context, index) {
                          final definition = _definitions[index];
                          return _FakemonCard(
                            definition: definition,
                            onEdit: () => _openEditor(definition),
                            onDuplicate: () => _duplicate(definition),
                            onExport: () => _export(definition),
                            onShare: () => _share(definition),
                            onDelete: () => _delete(definition),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomPokemonEditorScreen extends StatefulWidget {
  const CustomPokemonEditorScreen({super.key, this.definition});

  final CustomPokemonDefinition? definition;

  @override
  State<CustomPokemonEditorScreen> createState() =>
      _CustomPokemonEditorScreenState();
}

class _CustomPokemonEditorScreenState extends State<CustomPokemonEditorScreen> {
  static final _types = [
    'Bug',
    'Dark',
    'Dragon',
    'Electric',
    'Fairy',
    'Fighting',
    'Fire',
    'Flying',
    'Ghost',
    'Grass',
    'Ground',
    'Ice',
    'Normal',
    'Poison',
    'Psychic',
    'Rock',
    'Steel',
    'Water',
  ];
  static final _sizes = ['Tiny', 'Small', 'Medium', 'Large', 'Huge'];
  static final _eggGroups = [
    'Monster',
    'Water 1',
    'Bug',
    'Flying',
    'Field',
    'Fairy',
    'Grass',
    'Human-Like',
    'Water 3',
    'Mineral',
    'Amorphous',
    'Water 2',
    'Ditto',
    'Dragon',
    'Undiscovered',
  ];

  final _formKey = GlobalKey<FormState>();
  final CustomPokemonRepository _repository = CustomPokemonRepository();
  final MoveRepository _moveRepository = MoveRepository();
  final AbilityRepository _abilityRepository = AbilityRepository();

  late final TextEditingController _name;
  late final TextEditingController _author;
  late final TextEditingController _genus;
  late final TextEditingController _description;
  late final TextEditingController _notes;
  late final TextEditingController _ac;
  late final TextEditingController _hp;
  late final TextEditingController _speed;
  late final TextEditingController _hitDice;
  late final TextEditingController _sr;
  late final TextEditingController _minLevel;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  late final TextEditingController _genderRatio;
  late final TextEditingController _skills;
  late final TextEditingController _savingThrows;
  late final TextEditingController _abilities;
  late final TextEditingController _hiddenAbility;
  late final TextEditingController _startingMoves;
  late final TextEditingController _levelMoves;
  late final TextEditingController _tmMoves;
  late final TextEditingController _eggMoves;
  late final TextEditingController _eggGroupsController;
  late final TextEditingController _baseSpeciesId;

  final Map<String, TextEditingController> _scores = {};
  late String _primaryType;
  String? _secondaryType;
  late String _size;
  Uint8List? _imageBytes;
  String? _imageMimeType;
  Uint8List? _shinyImageBytes;
  String? _shinyImageMimeType;
  List<CustomPokemonMoveDefinition> _localMoves = [];
  List<CustomPokemonAbilityDefinition> _localAbilities = [];
  CustomPokemonAdvancedData _advanced = CustomPokemonAdvancedData();
  List<MoveData> _globalMoves = [];
  Map<String, String> _globalAbilities = {};
  bool _loadingCatalogs = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final definition = widget.definition;
    _name = TextEditingController(text: definition?.name ?? '');
    _author = TextEditingController(text: definition?.author ?? '');
    _genus = TextEditingController(text: definition?.genus ?? '');
    _description = TextEditingController(text: definition?.description ?? '');
    _notes = TextEditingController(text: definition?.creatorNotes ?? '');
    _ac = TextEditingController(text: '${definition?.armorClass ?? 10}');
    _hp = TextEditingController(text: '${definition?.hitPoints ?? 10}');
    _speed = TextEditingController(text: '${definition?.speed ?? 30}');
    _hitDice = TextEditingController(text: '${definition?.hitDice ?? 1}');
    _sr = TextEditingController(text: '${definition?.sr ?? 0.5}');
    _minLevel = TextEditingController(
      text: '${definition?.minLevelFound ?? 1}',
    );
    _height = TextEditingController(text: definition?.height?.toString() ?? '');
    _weight = TextEditingController(text: definition?.weight?.toString() ?? '');
    _genderRatio = TextEditingController(text: definition?.genderRatio ?? '');
    _skills = TextEditingController(text: definition?.skills.join(', ') ?? '');
    _savingThrows = TextEditingController(
      text: definition?.savingThrows.join(', ') ?? '',
    );
    _abilities = TextEditingController(
      text: definition?.abilities.join(', ') ?? '',
    );
    _hiddenAbility = TextEditingController(
      text: definition?.hiddenAbility ?? '',
    );
    _startingMoves = TextEditingController(
      text: definition?.startingMoves.join(', ') ?? '',
    );
    _levelMoves = TextEditingController(
      text: definition == null
          ? ''
          : (definition.levelMoves.entries.toList()
                  ..sort((a, b) => a.key.compareTo(b.key)))
                .map((entry) => '${entry.key}: ${entry.value.join(', ')}')
                .join('\n'),
    );
    _tmMoves = TextEditingController(
      text: definition?.tmMoves.join(', ') ?? '',
    );
    _eggMoves = TextEditingController(
      text: definition?.eggMoves.join(', ') ?? '',
    );
    _eggGroupsController = TextEditingController(
      text: definition?.eggGroups.join(', ') ?? '',
    );
    _baseSpeciesId = TextEditingController(
      text: definition?.baseSpeciesId?.toString() ?? '',
    );

    final attributes = definition?.attributes;
    final initialScores = {
      'STR': attributes?.strength ?? 10,
      'DEX': attributes?.dexterity ?? 10,
      'CON': attributes?.constitution ?? 10,
      'INT': attributes?.intelligence ?? 10,
      'WIS': attributes?.wisdom ?? 10,
      'CHA': attributes?.charisma ?? 10,
    };
    for (final entry in initialScores.entries) {
      _scores[entry.key] = TextEditingController(text: '${entry.value}');
    }

    _primaryType = definition?.types.firstOrNull ?? 'Normal';
    _secondaryType = definition != null && definition.types.length > 1
        ? definition.types[1]
        : null;
    _size = definition?.size ?? 'Medium';
    _imageBytes = definition?.imageBytes;
    _imageMimeType = definition?.imageMimeType;
    _shinyImageBytes = definition?.shinyImageBytes;
    _shinyImageMimeType = definition?.shinyImageMimeType;
    _localMoves = [...?definition?.localMoves];
    _localAbilities = [...?definition?.localAbilities];
    _advanced = definition?.advanced ?? CustomPokemonAdvancedData();
    _loadCatalogs();
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _author,
      _genus,
      _description,
      _notes,
      _ac,
      _hp,
      _speed,
      _hitDice,
      _sr,
      _minLevel,
      _height,
      _weight,
      _genderRatio,
      _skills,
      _savingThrows,
      _abilities,
      _hiddenAbility,
      _startingMoves,
      _levelMoves,
      _tmMoves,
      _eggMoves,
      _eggGroupsController,
      _baseSpeciesId,
      ..._scores.values,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCatalogs() async {
    final moves = await _moveRepository.getAllMoves();
    final abilities = await _abilityRepository.getAbilityDescriptions();
    if (!mounted) return;
    setState(() {
      _globalMoves = moves;
      _globalAbilities = abilities;
      _loadingCatalogs = false;
    });
  }

  Future<void> _pickImage({bool shiny = false}) async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: shiny
          ? uiTextForLanguage(
              'Scegli immagine shiny del Fakemon',
              """Choose Fakemon shiny image""",
            )
          : uiTextForLanguage(
              'Scegli immagine Fakemon',
              """Choose Fakemon image""",
            ),
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.single;
    final bytes = picked.bytes ?? await picked.xFile.readAsBytes();
    if (bytes.length > CustomPokemonDefinition.maxImageBytes) {
      _showError('L’immagine supera il limite di 5 MB.');
      return;
    }
    final extension = picked.extension?.toLowerCase();
    final mimeType = switch (extension) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      _ => null,
    };
    if (mimeType == null) {
      _showError('Formato immagine non supportato.');
      return;
    }
    if (!mounted) return;
    setState(() {
      if (shiny) {
        _shinyImageBytes = bytes;
        _shinyImageMimeType = mimeType;
      } else {
        _imageBytes = bytes;
        _imageMimeType = mimeType;
      }
    });
  }

  Widget _imagePickerCard({
    required String label,
    required Uint8List? bytes,
    required bool shiny,
  }) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _pickImage(shiny: shiny),
          child: Container(
            height: 170,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: bytes == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 44),
                      SizedBox(height: 8),
                      Text(
                        shiny
                            ? uiTextForLanguage(
                                'AGGIUNGI SHINY',
                                """ADD SHINY""",
                              )
                            : 'CARICA IMMAGINE',
                      ),
                    ],
                  )
                : Image.memory(bytes, fit: BoxFit.contain),
          ),
        ),
        if (bytes != null)
          TextButton.icon(
            onPressed: () => setState(() {
              if (shiny) {
                _shinyImageBytes = null;
                _shinyImageMimeType = null;
              } else {
                _imageBytes = null;
                _imageMimeType = null;
              }
            }),
            icon: Icon(Icons.delete_outline),
            label: Text(uiTextForLanguage('Rimuovi', """Remove""")),
          ),
      ],
    );
  }

  Future<void> _pickGlobalMove(TextEditingController controller) async {
    final move = await showDialog<MoveData>(
      context: context,
      builder: (_) => _MoveCatalogDialog(moves: _globalMoves),
    );
    if (move == null) return;
    final values = _csv(controller.text);
    if (!values.any(
      (value) =>
          MoveData.referenceKey(value) ==
          MoveData.referenceKey(move.technicalName),
    )) {
      values.add(move.technicalName);
      controller.text = values.join(', ');
    }
  }

  Future<void> _pickGlobalAbility() async {
    final ability = await showDialog<String>(
      context: context,
      builder: (_) => _AbilityCatalogDialog(abilities: _globalAbilities),
    );
    if (ability == null) return;
    final values = _csv(_abilities.text);
    if (!values.contains(ability)) {
      values.add(ability);
      _abilities.text = values.join(', ');
    }
  }

  Future<void> _addLocalAbility() async {
    final definition = await showDialog<CustomPokemonAbilityDefinition>(
      context: context,
      builder: (_) => _LocalAbilityDialog(),
    );
    if (definition == null) return;
    setState(() {
      _localAbilities = [..._localAbilities, definition];
      final names = _csv(_abilities.text);
      if (!names.contains(definition.name)) names.add(definition.name);
      _abilities.text = names.join(', ');
    });
  }

  Future<void> _openAdvancedEditor() async {
    final result = await Navigator.of(context).push<CustomPokemonAdvancedData>(
      MaterialPageRoute(
        builder: (_) => CustomPokemonAdvancedEditorScreen(
          initial: _advanced,
          currentName: _name.text.trim().isEmpty
              ? uiTextForLanguage('Nuovo Fakemon', """New Fakemon""")
              : _name.text.trim(),
          currentPokemonId: widget.definition?.pokemonId,
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _advanced = result);
  }

  Future<void> _addLocalMove() async {
    final definition = await showDialog<CustomPokemonMoveDefinition>(
      context: context,
      builder: (_) => _LocalMoveDialog(),
    );
    if (definition == null) return;
    setState(() {
      _localMoves = [..._localMoves, definition];
      final startingMoveNames = _csv(_startingMoves.text);
      final newMoveKey = MoveData.referenceKey(definition.name);
      final isAlreadyAssigned = startingMoveNames.any(
        (move) => MoveData.referenceKey(move) == newMoveKey,
      );
      if (!isAlreadyAssigned) {
        startingMoveNames.add(definition.name);
        _startingMoves.text = startingMoveNames.join(', ');
      }
    });
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final existing = widget.definition;
      final now = DateTime.now().toUtc();
      final imageBytes = _imageBytes;
      final types = <String>[_primaryType];
      if (_secondaryType != null && _secondaryType != _primaryType) {
        types.add(_secondaryType!);
      }
      final definition = CustomPokemonDefinition(
        formatVersion: CustomPokemonDefinition.currentFormatVersion,
        stableId: existing?.stableId ?? _repository.createStableId(),
        pokemonId: existing?.pokemonId ?? await _repository.allocatePokemonId(),
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
        name: _name.text.trim(),
        author: _author.text.trim(),
        types: types,
        armorClass: int.parse(_ac.text),
        hitPoints: int.parse(_hp.text),
        size: _size,
        speed: int.parse(_speed.text),
        attributes: PokemonAttributes(
          strength: int.parse(_scores['STR']!.text),
          dexterity: int.parse(_scores['DEX']!.text),
          constitution: int.parse(_scores['CON']!.text),
          intelligence: int.parse(_scores['INT']!.text),
          wisdom: int.parse(_scores['WIS']!.text),
          charisma: int.parse(_scores['CHA']!.text),
        ),
        abilities: _csv(_abilities.text),
        hiddenAbility: _nullable(_hiddenAbility.text),
        skills: _csv(_skills.text),
        savingThrows: _csv(_savingThrows.text),
        startingMoves: _csv(_startingMoves.text),
        levelMoves: _parseLevelMoves(_levelMoves.text),
        tmMoves: _intCsv(_tmMoves.text),
        eggMoves: _csv(_eggMoves.text),
        eggGroups: _csv(_eggGroupsController.text),
        baseSpeciesId: _optionalInt(_baseSpeciesId.text),
        hitDice: int.parse(_hitDice.text),
        sr: double.parse(_sr.text.replaceAll(',', '.')),
        minLevelFound: int.parse(_minLevel.text),
        description: _nullable(_description.text),
        genus: _nullable(_genus.text),
        height: _optionalInt(_height.text),
        weight: _optionalInt(_weight.text),
        genderRatio: _nullable(_genderRatio.text),
        creatorNotes: _nullable(_notes.text),
        imageMimeType: imageBytes == null ? null : _imageMimeType,
        imageBase64: imageBytes == null ? null : base64Encode(imageBytes),
        shinyImageMimeType: _shinyImageBytes == null
            ? null
            : _shinyImageMimeType,
        shinyImageBase64: _shinyImageBytes == null
            ? null
            : base64Encode(_shinyImageBytes!),
        localMoves: _localMoves,
        localAbilities: _localAbilities,
        advanced: _advanced,
      );
      await _repository.save(definition);
      PokemonRepository.clearCache();
      if (!mounted) return;
      Navigator.of(context).pop(definition);
    } catch (error) {
      if (!mounted) return;
      _showError(
        context.userFacingError(error, action: UserFacingErrorAction.save),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.definition == null
              ? uiTextForLanguage('NUOVO FAKEMON', """NEW FAKEMON""")
              : uiTextForLanguage('MODIFICA FAKEMON', """EDIT FAKEMON"""),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ResponsiveContent(
          maxWidth: 900,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              _EditorSection(
                title: uiTextForLanguage(
                  'Identità e immagine',
                  """Identity and image""",
                ),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _imagePickerCard(
                          label: uiTextForLanguage(
                            'IMMAGINE PRINCIPALE',
                            'MAIN IMAGE',
                          ),
                          bytes: _imageBytes,
                          shiny: false,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _imagePickerCard(
                          label: uiTextForLanguage(
                            'SHINY (FACOLTATIVA)',
                            'SHINY (OPTIONAL)',
                          ),
                          bytes: _shinyImageBytes,
                          shiny: true,
                        ),
                      ),
                    ],
                  ),
                  _RequiredTextField(
                    controller: _name,
                    label: uiTextForLanguage('Nome', """Name"""),
                  ),
                  _RequiredTextField(
                    controller: _author,
                    label: uiTextForLanguage('Autore', 'Author'),
                  ),
                  TextFormField(
                    controller: _genus,
                    decoration: InputDecoration(
                      labelText: uiTextForLanguage(
                        'Categoria / genere',
                        'Category / genus',
                      ),
                    ),
                  ),
                  TextFormField(
                    controller: _description,
                    minLines: 3,
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: uiTextForLanguage(
                        'Descrizione',
                        """Description""",
                      ),
                    ),
                  ),
                  TextFormField(
                    controller: _notes,
                    minLines: 2,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: uiTextForLanguage(
                        'Note del creatore',
                        'Creator notes',
                      ),
                    ),
                  ),
                ],
              ),
              _EditorSection(
                title: uiTextForLanguage(
                  'Tipi e dati fisici',
                  'Types and physical data',
                ),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _typeDropdown(
                          uiTextForLanguage('Tipo principale', 'Primary type'),
                          _primaryType,
                          (value) => setState(() => _primaryType = value!),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _typeDropdown(
                          uiTextForLanguage(
                            'Tipo secondario',
                            'Secondary type',
                          ),
                          _secondaryType,
                          (value) => setState(() => _secondaryType = value),
                          optional: true,
                        ),
                      ),
                    ],
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _size,
                    decoration: InputDecoration(
                      labelText: uiTextForLanguage('Taglia', 'Size'),
                    ),
                    items: [
                      for (final size in _sizes)
                        DropdownMenuItem(value: size, child: Text(size)),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _size = value);
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _optionalNumber(
                          _height,
                          uiTextForLanguage(
                            'Altezza (decimetri)',
                            'Height (decimeters)',
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _optionalNumber(
                          _weight,
                          uiTextForLanguage(
                            'Peso (ettogrammi)',
                            """Weight (hectograms)""",
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: _genderRatio,
                    decoration: InputDecoration(
                      labelText: uiTextForLanguage(
                        'Rapporto tra i sessi',
                        'Gender ratio',
                      ),
                    ),
                  ),
                ],
              ),
              _EditorSection(
                title: uiTextForLanguage('Statistiche 5e', '5e statistics'),
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _numberBox(_ac, uiTextForLanguage('CA', 'AC'), min: 1),
                      _numberBox(_hp, uiTextForLanguage('PF', 'HP'), min: 1),
                      _numberBox(
                        _speed,
                        uiTextForLanguage('Velocità', """Speed"""),
                        min: 0,
                      ),
                      _numberBox(
                        _hitDice,
                        uiTextForLanguage('Dadi Vita', 'Hit Dice'),
                        min: 1,
                      ),
                      _decimalBox(_sr, 'SR', min: 0),
                      _numberBox(
                        _minLevel,
                        uiTextForLanguage(
                          'Livello minimo',
                          """Minimum level""",
                        ),
                        min: 1,
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final key in [
                        'STR',
                        'DEX',
                        'CON',
                        'INT',
                        'WIS',
                        'CHA',
                      ])
                        _numberBox(_scores[key]!, key, min: 1, max: 40),
                    ],
                  ),
                  TextFormField(
                    controller: _skills,
                    decoration: InputDecoration(
                      labelText: uiTextForLanguage(
                        'Competenze, separate da virgole',
                        """Proficiencies, comma-separated""",
                      ),
                    ),
                  ),
                  TextFormField(
                    controller: _savingThrows,
                    decoration: InputDecoration(
                      labelText: uiTextForLanguage(
                        'Tiri salvezza, separati da virgole',
                        'Saving throws, comma-separated',
                      ),
                    ),
                  ),
                ],
              ),
              _EditorSection(
                title: uiTextForLanguage('Abilità', """Abilities"""),
                children: [
                  TextFormField(
                    controller: _abilities,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: uiTextForLanguage(
                        'Abilità disponibili, separate da virgole',
                        """Available abilities, comma-separated""",
                      ),
                    ),
                  ),
                  TextFormField(
                    controller: _hiddenAbility,
                    decoration: InputDecoration(
                      labelText: uiTextForLanguage(
                        'Abilità nascosta',
                        """Hidden ability""",
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _loadingCatalogs ? null : _pickGlobalAbility,
                        icon: Icon(Icons.search),
                        label: Text(
                          uiTextForLanguage('DAL CATALOGO', """FROM CATALOG"""),
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _addLocalAbility,
                        icon: Icon(Icons.add),
                        label: Text(
                          uiTextForLanguage('NUOVA ESCLUSIVA', 'NEW EXCLUSIVE'),
                        ),
                      ),
                    ],
                  ),
                  for (final entry in _localAbilities.indexed)
                    ListTile(
                      title: Text(entry.$2.name),
                      subtitle: Text(entry.$2.description),
                      leading: Icon(Icons.auto_awesome),
                      trailing: IconButton(
                        tooltip: uiTextForLanguage('Rimuovi', """Remove"""),
                        onPressed: () =>
                            setState(() => _localAbilities.removeAt(entry.$1)),
                        icon: Icon(Icons.delete_outline),
                      ),
                    ),
                ],
              ),
              _EditorSection(
                title: uiTextForLanguage(
                  'Evoluzioni, forme e segreti',
                  """Evolutions, forms and secrets""",
                ),
                children: [
                  Text(
                    uiTextForLanguage(
                      '${_advanced.evolvesFrom.length} pre-evoluzioni · '
                          '${_advanced.evolvesTo.length} evoluzioni · '
                          '${_advanced.forms.length} forme',
                      '${_advanced.evolvesFrom.length} pre-evolutions · '
                          '${_advanced.evolvesTo.length} evolutions · '
                          '${_advanced.forms.length} forms',
                    ),
                  ),
                  if (_advanced.secretUntilDiscovered)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.lock_outline),
                      title: Text(
                        uiTextForLanguage(
                          'Esportazione segreta disponibile',
                          """Secret export available""",
                        ),
                      ),
                      subtitle: Text(
                        uiTextForLanguage(
                          'Il giocatore non vedrà il contenuto prima della scoperta.',
                          """The player will not see the content before discovery.""",
                        ),
                      ),
                    ),
                  FilledButton.tonalIcon(
                    onPressed: _openAdvancedEditor,
                    icon: Icon(Icons.account_tree_outlined),
                    label: Text(
                      uiTextForLanguage(
                        'APRI EDITOR AVANZATO',
                        """OPEN ADVANCED EDITOR""",
                      ),
                    ),
                  ),
                ],
              ),
              _EditorSection(
                title: uiTextForLanguage('Allevamento', """Breeding"""),
                children: [
                  TextFormField(
                    controller: _eggGroupsController,
                    decoration: InputDecoration(
                      labelText: uiTextForLanguage(
                        'Gruppi Uova, separati da virgole',
                        """Egg Groups, comma-separated""",
                      ),
                      helperText: uiTextForLanguage(
                        'Lascia vuoto per rendere la specie non disponibile all’allevamento.',
                        """Leave blank to make the species unavailable for breeding.""",
                      ),
                    ),
                    validator: (value) {
                      final groups = _csv(value ?? '');
                      if (groups.length > 2) {
                        return uiTextForLanguage(
                          'Scegli al massimo due Gruppi Uova.',
                          """Choose at most two Egg Groups.""",
                        );
                      }
                      for (final group in groups) {
                        if (!_eggGroups.contains(group)) {
                          return uiTextForLanguage(
                            'Gruppo Uova non riconosciuto: $group',
                            """Unrecognized Egg Group: $group""",
                          );
                        }
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _baseSpeciesId,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: uiTextForLanguage(
                        'ID specie base per la schiusa',
                        """Base species ID for hatching""",
                      ),
                      helperText: uiTextForLanguage(
                        'Facoltativo. Se vuoto, dall’uovo nascerà questa specie.',
                        """Optional. If blank, this species will hatch from the egg.""",
                      ),
                    ),
                    validator: (value) {
                      final text = (value ?? '').trim();
                      if (text.isEmpty) return null;
                      final id = int.tryParse(text);
                      return id == null || id <= 0
                          ? uiTextForLanguage('ID non valido', 'Invalid ID')
                          : null;
                    },
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final group in _eggGroups)
                        ActionChip(
                          label: Text(group),
                          onPressed: () {
                            final groups = _csv(_eggGroupsController.text);
                            if (!groups.contains(group) && groups.length < 2) {
                              groups.add(group);
                              _eggGroupsController.text = groups.join(', ');
                            }
                          },
                        ),
                    ],
                  ),
                ],
              ),
              _EditorSection(
                title: uiTextForLanguage('Mosse', """Moves"""),
                children: [
                  _MoveListField(
                    controller: _startingMoves,
                    label: uiTextForLanguage(
                      'Mosse iniziali',
                      """Starting moves""",
                    ),
                    onPick: () => _pickGlobalMove(_startingMoves),
                  ),
                  TextFormField(
                    controller: _levelMoves,
                    minLines: 3,
                    maxLines: 8,
                    decoration: InputDecoration(
                      labelText: uiTextForLanguage(
                        'Mosse per livello',
                        """Moves by level""",
                      ),
                      helperText: uiTextForLanguage(
                        'Una riga per livello, ad esempio: 5: Tuonoshock, Agilità',
                        """One line per level, for example: 5: Thunder Shock, Agility""",
                      ),
                    ),
                    validator: (value) {
                      try {
                        _parseLevelMoves(value ?? '');
                        return null;
                      } catch (_) {
                        return context.uiText(
                          'Usa una riga per livello nel formato “5: Mossa, Mossa”.',
                          'Use one line per level in the format “5: Move, Move”.',
                        );
                      }
                    },
                  ),
                  TextFormField(
                    controller: _tmMoves,
                    decoration: InputDecoration(
                      labelText: uiTextForLanguage(
                        'Numeri MT, separati da virgole',
                        'TM numbers, comma-separated',
                      ),
                    ),
                    validator: (value) {
                      try {
                        _intCsv(value ?? '');
                        return null;
                      } catch (_) {
                        return uiTextForLanguage(
                          'Inserisci soltanto numeri MT separati da virgole.',
                          'Enter only comma-separated TM numbers.',
                        );
                      }
                    },
                  ),
                  _MoveListField(
                    controller: _eggMoves,
                    label: 'Egg Moves',
                    onPick: () => _pickGlobalMove(_eggMoves),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _addLocalMove,
                    icon: Icon(Icons.add),
                    label: Text(
                      uiTextForLanguage(
                        'CREA MOSSA ESCLUSIVA',
                        """CREATE EXCLUSIVE MOVE""",
                      ),
                    ),
                  ),
                  for (final entry in _localMoves.indexed)
                    ListTile(
                      leading: Icon(Icons.auto_awesome),
                      title: Text(entry.$2.name),
                      subtitle: Text(
                        '${entry.$2.type} · ${entry.$2.moveTime}\n${entry.$2.description}',
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        tooltip: uiTextForLanguage('Rimuovi', """Remove"""),
                        onPressed: () =>
                            setState(() => _localMoves.removeAt(entry.$1)),
                        icon: Icon(Icons.delete_outline),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.save_outlined),
            label: Text(uiTextForLanguage('SALVA FAKEMON', """SAVE FAKEMON""")),
          ),
        ),
      ),
    );
  }

  Widget _typeDropdown(
    String label,
    String? value,
    ValueChanged<String?> onChanged, {
    bool optional = false,
  }) {
    return DropdownButtonFormField<String?>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        if (optional)
          DropdownMenuItem<String?>(
            value: null,
            child: Text(uiTextForLanguage('Nessuno', """None""")),
          ),
        for (final type in _types)
          DropdownMenuItem<String?>(value: type, child: Text(type)),
      ],
      onChanged: onChanged,
    );
  }

  Widget _numberBox(
    TextEditingController controller,
    String label, {
    required int min,
    int? max,
  }) {
    return SizedBox(
      width: 130,
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          final number = int.tryParse(value ?? '');
          if (number == null || number < min || (max != null && number > max)) {
            return max == null ? 'Minimo $min' : '$min–$max';
          }
          return null;
        },
      ),
    );
  }

  Widget _decimalBox(
    TextEditingController controller,
    String label, {
    required double min,
  }) {
    return SizedBox(
      width: 130,
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          final number = double.tryParse((value ?? '').replaceAll(',', '.'));
          return number == null || number < min ? 'Minimo $min' : null;
        },
      ),
    );
  }

  Widget _optionalNumber(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if ((value ?? '').trim().isEmpty) return null;
        final number = int.tryParse(value!.trim());
        return number == null || number < 0 ? 'Numero non valido' : null;
      },
    );
  }
}

class _FakemonCard extends StatelessWidget {
  const _FakemonCard({
    required this.definition,
    required this.onEdit,
    required this.onDuplicate,
    required this.onExport,
    required this.onShare,
    required this.onDelete,
  });

  final CustomPokemonDefinition definition;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onExport;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final pokemon = definition.toPokemon();
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PokemonAssetImage(
              pokemon: pokemon,
              size: 104,
              useLargeArtwork: true,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    definition.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text('di ${definition.author} · ID ${definition.pokemonId}'),
                  if (definition.advanced.secretUntilDiscovered)
                    Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Chip(
                        avatar: Icon(Icons.lock_outline, size: 18),
                        label: Text(
                          uiTextForLanguage(
                            'CONTENUTO SEGRETO',
                            """SECRET CONTENT""",
                          ),
                        ),
                      ),
                    ),
                  SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final type in definition.types)
                        PokemonTypeBadge(type: type, height: 22),
                    ],
                  ),
                  if (definition.description != null) ...[
                    SizedBox(height: 8),
                    Text(
                      definition.description!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: Icon(Icons.edit_outlined),
                        label: Text(uiTextForLanguage('MODIFICA', """EDIT""")),
                      ),
                      OutlinedButton.icon(
                        onPressed: onShare,
                        icon: Icon(Icons.share_outlined),
                        label: Text(
                          uiTextForLanguage('CONDIVIDI', """SHARE"""),
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: uiTextForLanguage(
                          'Altre azioni',
                          """More actions""",
                        ),
                        onSelected: (value) {
                          switch (value) {
                            case 'export':
                              onExport();
                              break;
                            case 'duplicate':
                              onDuplicate();
                              break;
                            case 'delete':
                              onDelete();
                              break;
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'export',
                            child: Text(
                              uiTextForLanguage(
                                'Esporta file',
                                """Export file""",
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'duplicate',
                            child: Text('Duplica'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              uiTextForLanguage('Elimina', """Delete"""),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorSection extends StatelessWidget {
  const _EditorSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 12),
            for (final entry in children.indexed) ...[
              if (entry.$1 > 0) SizedBox(height: 10),
              entry.$2,
            ],
          ],
        ),
      ),
    );
  }
}

class _RequiredTextField extends StatelessWidget {
  const _RequiredTextField({required this.controller, required this.label});
  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      validator: (value) =>
          (value ?? '').trim().isEmpty ? 'Campo obbligatorio' : null,
    );
  }
}

class _MoveListField extends StatelessWidget {
  const _MoveListField({
    required this.controller,
    required this.label,
    required this.onPick,
  });
  final TextEditingController controller;
  final String label;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      minLines: 2,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: '$label, separate da virgole',
        suffixIcon: IconButton(
          tooltip: uiTextForLanguage(
            'Scegli dal catalogo',
            """Choose from catalog""",
          ),
          onPressed: onPick,
          icon: Icon(Icons.search),
        ),
      ),
    );
  }
}

class _MoveCatalogDialog extends StatefulWidget {
  const _MoveCatalogDialog({required this.moves});
  final List<MoveData> moves;

  @override
  State<_MoveCatalogDialog> createState() => _MoveCatalogDialogState();
}

class _MoveCatalogDialogState extends State<_MoveCatalogDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final moves = widget.moves
        .where(
          (move) =>
              query.isEmpty ||
              move.name.toLowerCase().contains(query) ||
              move.type.toLowerCase().contains(query),
        )
        .toList(growable: false);
    return AlertDialog(
      title: Text(uiTextForLanguage('Scegli mossa', """Choose move""")),
      content: SizedBox(
        width: 560,
        height: 520,
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: uiTextForLanguage('Cerca', """Search"""),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: moves.length,
                itemBuilder: (context, index) {
                  final move = moves[index];
                  return ListTile(
                    title: Text(move.name),
                    subtitle: Text(
                      '${move.type} · ${move.moveTime}\n${move.description}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    isThreeLine: true,
                    onTap: () => Navigator.of(context).pop(move),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(uiTextForLanguage('ANNULLA', """CANCEL""")),
        ),
      ],
    );
  }
}

class _AbilityCatalogDialog extends StatefulWidget {
  const _AbilityCatalogDialog({required this.abilities});
  final Map<String, String> abilities;

  @override
  State<_AbilityCatalogDialog> createState() => _AbilityCatalogDialogState();
}

class _AbilityCatalogDialogState extends State<_AbilityCatalogDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final names =
        widget.abilities.keys
            .where(
              (name) =>
                  query.isEmpty ||
                  name.toLowerCase().contains(query) ||
                  (widget.abilities[name] ?? '').toLowerCase().contains(query),
            )
            .toList()
          ..sort();
    return AlertDialog(
      title: Text(uiTextForLanguage('Scegli abilità', """Choose ability""")),
      content: SizedBox(
        width: 560,
        height: 520,
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: uiTextForLanguage('Cerca', """Search"""),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: names.length,
                itemBuilder: (context, index) {
                  final name = names[index];
                  return ListTile(
                    title: Text(name),
                    subtitle: Text(
                      widget.abilities[name] ?? '',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => Navigator.of(context).pop(name),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(uiTextForLanguage('ANNULLA', """CANCEL""")),
        ),
      ],
    );
  }
}

class _LocalAbilityDialog extends StatefulWidget {
  const _LocalAbilityDialog();
  @override
  State<_LocalAbilityDialog> createState() => _LocalAbilityDialogState();
}

class _LocalAbilityDialogState extends State<_LocalAbilityDialog> {
  final _name = TextEditingController();
  final _description = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        uiTextForLanguage(
          'Nuova abilità esclusiva',
          """New exclusive ability""",
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: InputDecoration(
              labelText: uiTextForLanguage('Nome', """Name"""),
            ),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _description,
            minLines: 3,
            maxLines: 7,
            decoration: InputDecoration(
              labelText: uiTextForLanguage('Descrizione', """Description"""),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(uiTextForLanguage('ANNULLA', """CANCEL""")),
        ),
        FilledButton(
          onPressed: () {
            final name = _name.text.trim();
            final description = _description.text.trim();
            if (name.isEmpty || description.isEmpty) return;
            Navigator.of(context).pop(
              CustomPokemonAbilityDefinition(
                id: 'ability-${MoveData.referenceKey(name)}-${DateTime.now().microsecondsSinceEpoch}',
                name: name,
                description: description,
              ),
            );
          },
          child: Text(uiTextForLanguage('AGGIUNGI', """ADD""")),
        ),
      ],
    );
  }
}

class _LocalMoveDialog extends StatefulWidget {
  const _LocalMoveDialog();
  @override
  State<_LocalMoveDialog> createState() => _LocalMoveDialogState();
}

class _LocalMoveDialogState extends State<_LocalMoveDialog> {
  final _name = TextEditingController();
  final _pp = TextEditingController(text: '10');
  final _range = TextEditingController(text: 'Melee');
  final _duration = TextEditingController(text: 'Instantaneous');
  final _time = TextEditingController(text: '1 Action');
  final _description = TextEditingController();
  final _save = TextEditingController();
  final _damage = TextEditingController();
  String _type = 'Normal';
  bool _isAttack = true;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _pp,
      _range,
      _duration,
      _time,
      _description,
      _save,
      _damage,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        uiTextForLanguage('Nuova mossa esclusiva', """New exclusive move"""),
      ),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: uiTextForLanguage('Nome', """Name"""),
                ),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: InputDecoration(labelText: 'Tipo'),
                items: [
                  for (final type in _CustomPokemonEditorScreenState._types)
                    DropdownMenuItem(value: type, child: Text(type)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _type = value);
                },
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pp,
                      decoration: InputDecoration(labelText: 'PP'),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _time,
                      decoration: InputDecoration(labelText: 'Tempo'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _range,
                      decoration: InputDecoration(labelText: 'Gittata'),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _duration,
                      decoration: InputDecoration(labelText: 'Durata'),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  uiTextForLanguage(
                    'Richiede tiro per colpire',
                    'Requires an attack roll',
                  ),
                ),
                value: _isAttack,
                onChanged: (value) => setState(() => _isAttack = value),
              ),
              TextField(
                controller: _save,
                decoration: InputDecoration(
                  labelText: uiTextForLanguage(
                    'Tiro salvezza, se previsto',
                    'Saving throw, if any',
                  ),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _damage,
                decoration: InputDecoration(
                  labelText: uiTextForLanguage(
                    'Danno al livello 1, es. 2d6',
                    """Damage at level 1, e.g. 2d6""",
                  ),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _description,
                minLines: 4,
                maxLines: 9,
                decoration: InputDecoration(
                  labelText: uiTextForLanguage(
                    'Descrizione completa',
                    """Full description""",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(uiTextForLanguage('ANNULLA', """CANCEL""")),
        ),
        FilledButton(
          onPressed: () {
            final name = _name.text.trim();
            final description = _description.text.trim();
            if (name.isEmpty || description.isEmpty) return;
            Navigator.of(context).pop(
              CustomPokemonMoveDefinition(
                id: 'move-${MoveData.referenceKey(name)}-${DateTime.now().microsecondsSinceEpoch}',
                name: name,
                type: _type,
                pp: _pp.text.trim().isEmpty ? '-' : _pp.text.trim(),
                range: _range.text.trim().isEmpty ? '-' : _range.text.trim(),
                duration: _duration.text.trim().isEmpty
                    ? '-'
                    : _duration.text.trim(),
                moveTime: _time.text.trim().isEmpty ? '-' : _time.text.trim(),
                description: description,
                isAttack: _isAttack,
                save: _nullable(_save.text),
                damageByLevel: _damage.text.trim().isEmpty
                    ? {}
                    : {1: _damage.text.trim()},
              ),
            );
          },
          child: Text(uiTextForLanguage('AGGIUNGI', """ADD""")),
        ),
      ],
    );
  }
}

class _FakemonImportDialog extends StatelessWidget {
  const _FakemonImportDialog({required this.incoming, required this.existing});
  final CustomPokemonDefinition incoming;
  final CustomPokemonDefinition existing;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        uiTextForLanguage(
          '${incoming.name} è già presente',
          """${incoming.name} already exists""",
        ),
      ),
      content: Text(
        uiTextForLanguage(
          'La definizione locale è stata aggiornata il ${existing.updatedAt.toLocal()}. Vuoi aggiornarla mantenendo gli esemplari esistenti, oppure importare una copia separata?',
          """The local definition was updated on ${existing.updatedAt.toLocal()}. Update it while keeping existing specimens, or import a separate copy?""",
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(uiTextForLanguage('ANNULLA', """CANCEL""")),
        ),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(_ImportChoice.copy),
          child: Text(uiTextForLanguage('IMPORTA COPIA', """IMPORT COPY""")),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_ImportChoice.update),
          child: Text(uiTextForLanguage('AGGIORNA', """UPDATE""")),
        ),
      ],
    );
  }
}

class _EmptyFakemonState extends StatelessWidget {
  const _EmptyFakemonState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 72),
            SizedBox(height: 16),
            Text(
              uiTextForLanguage(
                'Nessun Fakemon creato',
                """No Fakemon created""",
              ),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 8),
            Text(
              uiTextForLanguage(
                'Crea una nuova specie completa oppure importa un file .p5fakemon.',
                """Create a complete new species or import a .p5fakemon file.""",
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

CustomPokemonDefinition _copyDefinition(
  CustomPokemonDefinition source, {
  required String stableId,
  required int pokemonId,
  required String name,
  required DateTime createdAt,
  required DateTime updatedAt,
}) {
  return CustomPokemonDefinition.fromJson({
    ...source.toJson(),
    'stableId': stableId,
    'pokemonId': pokemonId,
    'name': name,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  });
}

List<String> _csv(String value) => value
    .split(',')
    .map((entry) => entry.trim())
    .where((entry) => entry.isNotEmpty)
    .toList();

List<int> _intCsv(String value) {
  final result = <int>[];
  for (final entry in _csv(value)) {
    final number = int.tryParse(entry);
    if (number == null) {
      throw FormatException(
        uiTextForLanguage(
          'Elenco numerico non valido.',
          """Invalid numeric list.""",
        ),
      );
    }
    result.add(number);
  }
  return result;
}

Map<int, List<String>> _parseLevelMoves(String value) {
  final result = <int, List<String>>{};
  for (final rawLine in value.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty) {
      continue;
    }
    final separator = line.indexOf(':');
    if (separator <= 0) {
      throw FormatException(
        uiTextForLanguage(
          'Riga mosse non valida: $line',
          """Invalid move row: $line""",
        ),
      );
    }
    final level = int.tryParse(line.substring(0, separator).trim());
    final moves = _csv(line.substring(separator + 1));
    if (level == null || level <= 0 || moves.isEmpty) {
      throw FormatException(
        uiTextForLanguage(
          'Riga mosse non valida: $line',
          """Invalid move row: $line""",
        ),
      );
    }
    result[level] = moves;
  }
  return result;
}

String? _nullable(String value) => value.trim().isEmpty ? null : value.trim();
int? _optionalInt(String value) =>
    value.trim().isEmpty ? null : int.parse(value.trim());
