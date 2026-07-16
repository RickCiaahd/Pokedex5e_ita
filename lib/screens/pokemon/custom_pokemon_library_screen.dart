import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/custom_pokemon_definition.dart';
import '../../models/move_data.dart';
import '../../models/pokemon_attributes.dart';
import '../../repositories/ability_repository.dart';
import '../../repositories/custom_pokemon_repository.dart';
import '../../repositories/move_repository.dart';
import '../../repositories/pokemon_repository.dart';
import '../../services/custom_pokemon_transfer_service.dart';
import '../../services/native_share_service.dart';
import '../../widgets/layout/responsive_content.dart';
import '../../widgets/navigation/home_leading_button.dart';
import '../../widgets/pokemon/pokemon_asset_image.dart';

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
  final NativeShareService _shareService = const NativeShareService();

  List<CustomPokemonDefinition> _definitions = const [];
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
      if (!mounted) return;
      setState(() {
        _definitions = definitions;
        _isLoading = false;
      });
    } catch (error) {
      _setMessage(_friendlyError(error), isError: true);
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
    _setMessage('${saved.name} salvato nel catalogo Fakemon.');
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
        name: '${source.name} (copia)',
        createdAt: now,
        updatedAt: now,
      );
      await _repository.save(duplicate);
      PokemonRepository.clearCache();
      await _load();
      _setMessage('${duplicate.name} creato.');
    } catch (error) {
      _setMessage(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _delete(CustomPokemonDefinition definition) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Eliminare ${definition.name}?'),
        content: const Text(
          'La specie verrà rimossa dal catalogo locale. Eventuali esemplari già '
          'presenti in squadre, PC, incontri o battaglie conserveranno il loro '
          'riferimento numerico ma non potranno più caricare la scheda completa.',
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

  Future<void> _export(CustomPokemonDefinition definition) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final encoded = _transferService.encode(definition);
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Esporta ${definition.name}',
        fileName: _transferService.fileNameFor(definition),
        type: FileType.custom,
        allowedExtensions: const ['p5fakemon'],
        bytes: Uint8List.fromList(utf8.encode(encoded)),
      );
      _setMessage(
        result == null
            ? 'Esportazione annullata.'
            : '${definition.name} esportato correttamente.',
      );
    } catch (error) {
      _setMessage(_friendlyError(error), isError: true);
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
        content: _transferService.encode(definition),
        fileName: _transferService.fileNameFor(definition),
        mimeType: 'application/json',
        title: 'Condividi ${definition.name}',
        subject: 'Fakemon ${definition.name}',
        text: 'Fakemon creato con Pokédex 5e ITA.',
      );
      _setMessage(
        _shareService.feedback(
          outcome,
          successMessage: '${definition.name} condiviso.',
        ),
      );
    } catch (error) {
      _setMessage(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _import() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Importa Fakemon',
        type: FileType.custom,
        allowedExtensions: const ['p5fakemon', 'json'],
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        _setMessage('Importazione annullata.');
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
          _setMessage('Importazione annullata.');
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
        imported.updatedExisting
            ? '${imported.definition.name} aggiornato.'
            : '${imported.definition.name} importato.',
      );
    } catch (error) {
      _setMessage(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const HomeLeadingButton(),
        title: const Text('I MIEI FAKEMON'),
        actions: [
          IconButton(
            tooltip: 'Importa Fakemon',
            onPressed: _isBusy ? null : _import,
            icon: const Icon(Icons.file_download_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isBusy ? null : () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('NUOVO FAKEMON'),
      ),
      body: ResponsiveContent(
        maxWidth: 980,
        child: Column(
          children: [
            if (_isBusy) const LinearProgressIndicator(),
            if (_message != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                padding: const EdgeInsets.all(10),
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
                  ? const Center(child: CircularProgressIndicator())
                  : _definitions.isEmpty
                  ? const _EmptyFakemonState()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
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
  static const _types = [
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
  static const _sizes = ['Tiny', 'Small', 'Medium', 'Large', 'Huge'];

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

  final Map<String, TextEditingController> _scores = {};
  late String _primaryType;
  String? _secondaryType;
  late String _size;
  Uint8List? _imageBytes;
  String? _imageMimeType;
  List<CustomPokemonMoveDefinition> _localMoves = [];
  List<CustomPokemonAbilityDefinition> _localAbilities = [];
  List<MoveData> _globalMoves = const [];
  Map<String, String> _globalAbilities = const {};
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
    _localMoves = [...?definition?.localMoves];
    _localAbilities = [...?definition?.localAbilities];
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

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Scegli immagine Fakemon',
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
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
      _imageBytes = bytes;
      _imageMimeType = mimeType;
    });
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
          MoveData.referenceKey(value) == MoveData.referenceKey(move.name),
    )) {
      values.add(move.name);
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
      builder: (_) => const _LocalAbilityDialog(),
    );
    if (definition == null) return;
    setState(() {
      _localAbilities = [..._localAbilities, definition];
      final names = _csv(_abilities.text);
      if (!names.contains(definition.name)) names.add(definition.name);
      _abilities.text = names.join(', ');
    });
  }

  Future<void> _addLocalMove() async {
    final definition = await showDialog<CustomPokemonMoveDefinition>(
      context: context,
      builder: (_) => const _LocalMoveDialog(),
    );
    if (definition == null) return;
    setState(() => _localMoves = [..._localMoves, definition]);
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
        localMoves: _localMoves,
        localAbilities: _localAbilities,
      );
      await _repository.save(definition);
      PokemonRepository.clearCache();
      if (!mounted) return;
      Navigator.of(context).pop(definition);
    } catch (error) {
      _showError(_friendlyError(error));
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
          widget.definition == null ? 'NUOVO FAKEMON' : 'MODIFICA FAKEMON',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ResponsiveContent(
          maxWidth: 900,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              _EditorSection(
                title: 'Identità e immagine',
                children: [
                  Center(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: _pickImage,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _imageBytes == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 48,
                                  ),
                                  SizedBox(height: 8),
                                  Text('CARICA IMMAGINE'),
                                ],
                              )
                            : Image.memory(_imageBytes!, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  if (_imageBytes != null)
                    Align(
                      alignment: Alignment.center,
                      child: TextButton.icon(
                        onPressed: () => setState(() {
                          _imageBytes = null;
                          _imageMimeType = null;
                        }),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Rimuovi immagine'),
                      ),
                    ),
                  _RequiredTextField(controller: _name, label: 'Nome'),
                  _RequiredTextField(controller: _author, label: 'Autore'),
                  TextFormField(
                    controller: _genus,
                    decoration: const InputDecoration(
                      labelText: 'Categoria / genere',
                    ),
                  ),
                  TextFormField(
                    controller: _description,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(labelText: 'Descrizione'),
                  ),
                  TextFormField(
                    controller: _notes,
                    minLines: 2,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Note del creatore',
                    ),
                  ),
                ],
              ),
              _EditorSection(
                title: 'Tipi e dati fisici',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _typeDropdown(
                          'Tipo principale',
                          _primaryType,
                          (value) => setState(() => _primaryType = value!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _typeDropdown(
                          'Tipo secondario',
                          _secondaryType,
                          (value) => setState(() => _secondaryType = value),
                          optional: true,
                        ),
                      ),
                    ],
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _size,
                    decoration: const InputDecoration(labelText: 'Taglia'),
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
                        child: _optionalNumber(_height, 'Altezza (decimetri)'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _optionalNumber(_weight, 'Peso (ettogrammi)'),
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: _genderRatio,
                    decoration: const InputDecoration(
                      labelText: 'Rapporto tra i sessi',
                    ),
                  ),
                ],
              ),
              _EditorSection(
                title: 'Statistiche 5e',
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _numberBox(_ac, 'CA', min: 1),
                      _numberBox(_hp, 'PF', min: 1),
                      _numberBox(_speed, 'Velocità', min: 0),
                      _numberBox(_hitDice, 'Dadi Vita', min: 1),
                      _decimalBox(_sr, 'SR', min: 0),
                      _numberBox(_minLevel, 'Livello minimo', min: 1),
                    ],
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final key in const [
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
                    decoration: const InputDecoration(
                      labelText: 'Competenze, separate da virgole',
                    ),
                  ),
                  TextFormField(
                    controller: _savingThrows,
                    decoration: const InputDecoration(
                      labelText: 'Tiri salvezza, separati da virgole',
                    ),
                  ),
                ],
              ),
              _EditorSection(
                title: 'Abilità',
                children: [
                  TextFormField(
                    controller: _abilities,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Abilità disponibili, separate da virgole',
                    ),
                  ),
                  TextFormField(
                    controller: _hiddenAbility,
                    decoration: const InputDecoration(
                      labelText: 'Abilità nascosta',
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _loadingCatalogs ? null : _pickGlobalAbility,
                        icon: const Icon(Icons.search),
                        label: const Text('DAL CATALOGO'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _addLocalAbility,
                        icon: const Icon(Icons.add),
                        label: const Text('NUOVA ESCLUSIVA'),
                      ),
                    ],
                  ),
                  for (final entry in _localAbilities.indexed)
                    ListTile(
                      title: Text(entry.$2.name),
                      subtitle: Text(entry.$2.description),
                      leading: const Icon(Icons.auto_awesome),
                      trailing: IconButton(
                        tooltip: 'Rimuovi',
                        onPressed: () =>
                            setState(() => _localAbilities.removeAt(entry.$1)),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                ],
              ),
              _EditorSection(
                title: 'Mosse',
                children: [
                  _MoveListField(
                    controller: _startingMoves,
                    label: 'Mosse iniziali',
                    onPick: () => _pickGlobalMove(_startingMoves),
                  ),
                  TextFormField(
                    controller: _levelMoves,
                    minLines: 3,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'Mosse per livello',
                      helperText:
                          'Una riga per livello, ad esempio: 5: Tuonoshock, Agilità',
                    ),
                    validator: (value) {
                      try {
                        _parseLevelMoves(value ?? '');
                        return null;
                      } catch (error) {
                        return _friendlyError(error);
                      }
                    },
                  ),
                  TextFormField(
                    controller: _tmMoves,
                    decoration: const InputDecoration(
                      labelText: 'Numeri MT, separati da virgole',
                    ),
                    validator: (value) {
                      try {
                        _intCsv(value ?? '');
                        return null;
                      } catch (_) {
                        return 'Inserisci soltanto numeri MT separati da virgole.';
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
                    icon: const Icon(Icons.add),
                    label: const Text('CREA MOSSA ESCLUSIVA'),
                  ),
                  for (final entry in _localMoves.indexed)
                    ListTile(
                      leading: const Icon(Icons.auto_awesome),
                      title: Text(entry.$2.name),
                      subtitle: Text(
                        '${entry.$2.type} · ${entry.$2.moveTime}\n${entry.$2.description}',
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        tooltip: 'Rimuovi',
                        onPressed: () =>
                            setState(() => _localMoves.removeAt(entry.$1)),
                        icon: const Icon(Icons.delete_outline),
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
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('SALVA FAKEMON'),
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
          const DropdownMenuItem<String?>(value: null, child: Text('Nessuno')),
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
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PokemonAssetImage(
              pokemon: pokemon,
              size: 104,
              useLargeArtwork: true,
            ),
            const SizedBox(width: 12),
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
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final type in definition.types)
                        PokemonTypeBadge(type: type, height: 22),
                    ],
                  ),
                  if (definition.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      definition.description!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('MODIFICA'),
                      ),
                      OutlinedButton.icon(
                        onPressed: onShare,
                        icon: const Icon(Icons.share_outlined),
                        label: const Text('CONDIVIDI'),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Altre azioni',
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
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'export',
                            child: Text('Esporta file'),
                          ),
                          PopupMenuItem(
                            value: 'duplicate',
                            child: Text('Duplica'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Elimina'),
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
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            for (final entry in children.indexed) ...[
              if (entry.$1 > 0) const SizedBox(height: 10),
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
          tooltip: 'Scegli dal catalogo',
          onPressed: onPick,
          icon: const Icon(Icons.search),
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
      title: const Text('Scegli mossa'),
      content: SizedBox(
        width: 560,
        height: 520,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Cerca',
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 8),
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
          child: const Text('ANNULLA'),
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
      title: const Text('Scegli abilità'),
      content: SizedBox(
        width: 560,
        height: 520,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Cerca',
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 8),
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
          child: const Text('ANNULLA'),
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
      title: const Text('Nuova abilità esclusiva'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nome'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _description,
            minLines: 3,
            maxLines: 7,
            decoration: const InputDecoration(labelText: 'Descrizione'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ANNULLA'),
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
          child: const Text('AGGIUNGI'),
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
      title: const Text('Nuova mossa esclusiva'),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: [
                  for (final type in _CustomPokemonEditorScreenState._types)
                    DropdownMenuItem(value: type, child: Text(type)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _type = value);
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pp,
                      decoration: const InputDecoration(labelText: 'PP'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _time,
                      decoration: const InputDecoration(labelText: 'Tempo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _range,
                      decoration: const InputDecoration(labelText: 'Gittata'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _duration,
                      decoration: const InputDecoration(labelText: 'Durata'),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Richiede tiro per colpire'),
                value: _isAttack,
                onChanged: (value) => setState(() => _isAttack = value),
              ),
              TextField(
                controller: _save,
                decoration: const InputDecoration(
                  labelText: 'Tiro salvezza, se previsto',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _damage,
                decoration: const InputDecoration(
                  labelText: 'Danno al livello 1, es. 2d6',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _description,
                minLines: 4,
                maxLines: 9,
                decoration: const InputDecoration(
                  labelText: 'Descrizione completa',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ANNULLA'),
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
                    ? const {}
                    : {1: _damage.text.trim()},
              ),
            );
          },
          child: const Text('AGGIUNGI'),
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
      title: Text('${incoming.name} è già presente'),
      content: Text(
        'La definizione locale è stata aggiornata il ${existing.updatedAt.toLocal()}. Vuoi aggiornarla mantenendo gli esemplari esistenti, oppure importare una copia separata?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ANNULLA'),
        ),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(_ImportChoice.copy),
          child: const Text('IMPORTA COPIA'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_ImportChoice.update),
          child: const Text('AGGIORNA'),
        ),
      ],
    );
  }
}

class _EmptyFakemonState extends StatelessWidget {
  const _EmptyFakemonState();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 72),
            SizedBox(height: 16),
            Text(
              'Nessun Fakemon creato',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 8),
            Text(
              'Crea una nuova specie completa oppure importa un file .p5fakemon.',
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
      throw const FormatException('Elenco numerico non valido.');
    }
    result.add(number);
  }
  return result;
}

Map<int, List<String>> _parseLevelMoves(String value) {
  final result = <int, List<String>>{};
  for (final rawLine in value.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;
    final separator = line.indexOf(':');
    if (separator <= 0) throw FormatException('Riga mosse non valida: $line');
    final level = int.tryParse(line.substring(0, separator).trim());
    final moves = _csv(line.substring(separator + 1));
    if (level == null || level <= 0 || moves.isEmpty) {
      throw FormatException('Riga mosse non valida: $line');
    }
    result[level] = moves;
  }
  return result;
}

String? _nullable(String value) => value.trim().isEmpty ? null : value.trim();
int? _optionalInt(String value) =>
    value.trim().isEmpty ? null : int.parse(value.trim());
String _friendlyError(Object error) => error
    .toString()
    .replaceFirst('FormatException: ', '')
    .replaceFirst('Bad state: ', '')
    .trim();
