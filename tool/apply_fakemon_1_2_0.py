from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    source = file.read_text(encoding='utf-8')
    count = source.count(old)
    if count != 1:
        raise SystemExit(f'{path}: expected one match, found {count}')
    file.write_text(source.replace(old, new, 1), encoding='utf-8')


def insert_before(path: str, marker: str, content: str) -> None:
    replace_once(path, marker, content + marker)


# ---------------------------------------------------------------------------
# Advanced Fakemon model: a whole custom definition can be attached as a form
# of an official Pokemon or another Fakemon.
# ---------------------------------------------------------------------------
advanced_model = 'lib/models/custom_pokemon_advanced_data.dart'
replace_once(
    advanced_model,
    """    this.secretHint,
    this.evolvesFrom = const [],
""",
    """    this.secretHint,
    this.alternateFormOf,
    this.alternateFormDuration = CustomPokemonFormDuration.permanent,
    this.alternateFormSecretUntilActivated = false,
    this.alternateFormTrackInPokedex = true,
    this.alternateFormHint,
    this.evolvesFrom = const [],
""",
)
replace_once(
    advanced_model,
    """  final String? secretHint;
  final List<CustomPokemonEvolutionLink> evolvesFrom;
""",
    """  final String? secretHint;
  final CustomPokemonReference? alternateFormOf;
  final CustomPokemonFormDuration alternateFormDuration;
  final bool alternateFormSecretUntilActivated;
  final bool alternateFormTrackInPokedex;
  final String? alternateFormHint;
  final List<CustomPokemonEvolutionLink> evolvesFrom;
""",
)
replace_once(
    advanced_model,
    """      secretHint == null &&
      evolvesFrom.isEmpty &&
""",
    """      secretHint == null &&
      alternateFormOf == null &&
      evolvesFrom.isEmpty &&
""",
)
replace_once(
    advanced_model,
    """    String? secretHint,
    bool clearSecretHint = false,
    List<CustomPokemonEvolutionLink>? evolvesFrom,
""",
    """    String? secretHint,
    bool clearSecretHint = false,
    CustomPokemonReference? alternateFormOf,
    bool clearAlternateFormOf = false,
    CustomPokemonFormDuration? alternateFormDuration,
    bool? alternateFormSecretUntilActivated,
    bool? alternateFormTrackInPokedex,
    String? alternateFormHint,
    bool clearAlternateFormHint = false,
    List<CustomPokemonEvolutionLink>? evolvesFrom,
""",
)
replace_once(
    advanced_model,
    """      secretHint: clearSecretHint ? null : secretHint ?? this.secretHint,
      evolvesFrom: evolvesFrom ?? this.evolvesFrom,
""",
    """      secretHint: clearSecretHint ? null : secretHint ?? this.secretHint,
      alternateFormOf: clearAlternateFormOf
          ? null
          : alternateFormOf ?? this.alternateFormOf,
      alternateFormDuration:
          alternateFormDuration ?? this.alternateFormDuration,
      alternateFormSecretUntilActivated:
          alternateFormSecretUntilActivated ??
          this.alternateFormSecretUntilActivated,
      alternateFormTrackInPokedex:
          alternateFormTrackInPokedex ?? this.alternateFormTrackInPokedex,
      alternateFormHint: clearAlternateFormHint
          ? null
          : alternateFormHint ?? this.alternateFormHint,
      evolvesFrom: evolvesFrom ?? this.evolvesFrom,
""",
)
replace_once(
    advanced_model,
    """      secretHint: _nullableText(json['secretHint']),
      evolvesFrom: _mapList(json['evolvesFrom'])
""",
    """      secretHint: _nullableText(json['secretHint']),
      alternateFormOf: json['alternateFormOf'] is Map
          ? CustomPokemonReference.fromJson(
              Map<String, dynamic>.from(json['alternateFormOf'] as Map),
            )
          : null,
      alternateFormDuration: CustomPokemonFormDuration.fromJson(
        json['alternateFormDuration'],
      ),
      alternateFormSecretUntilActivated:
          json['alternateFormSecretUntilActivated'] == true,
      alternateFormTrackInPokedex:
          json['alternateFormTrackInPokedex'] != false,
      alternateFormHint: _nullableText(json['alternateFormHint']),
      evolvesFrom: _mapList(json['evolvesFrom'])
""",
)
replace_once(
    advanced_model,
    """        if (secretHint != null) 'secretHint': secretHint,
        'evolvesFrom': evolvesFrom.map((link) => link.toJson()).toList(),
""",
    """        if (secretHint != null) 'secretHint': secretHint,
        if (alternateFormOf != null)
          'alternateFormOf': alternateFormOf!.toJson(),
        'alternateFormDuration': alternateFormDuration.name,
        'alternateFormSecretUntilActivated':
            alternateFormSecretUntilActivated,
        'alternateFormTrackInPokedex': alternateFormTrackInPokedex,
        if (alternateFormHint != null)
          'alternateFormHint': alternateFormHint,
        'evolvesFrom': evolvesFrom.map((link) => link.toJson()).toList(),
""",
)
replace_once(
    advanced_model,
    """    final formIds = <String>{};
""",
    """    final alternateParent = alternateFormOf;
    if (alternateParent != null) {
      alternateParent.validate();
      if (alternateParent.pokemonId == currentPokemonId) {
        throw const FormatException(
          'Un Fakemon non può essere una forma alternativa di se stesso.',
        );
      }
    }

    final formIds = <String>{};
""",
)

# ---------------------------------------------------------------------------
# Main Fakemon editor: normal and shiny artwork side-by-side.
# ---------------------------------------------------------------------------
editor = 'lib/screens/pokemon/custom_pokemon_library_screen.dart'
replace_once(
    editor,
    """  Uint8List? _imageBytes;
  String? _imageMimeType;
""",
    """  Uint8List? _imageBytes;
  String? _imageMimeType;
  Uint8List? _shinyImageBytes;
  String? _shinyImageMimeType;
""",
)
replace_once(
    editor,
    """    _imageBytes = definition?.imageBytes;
    _imageMimeType = definition?.imageMimeType;
""",
    """    _imageBytes = definition?.imageBytes;
    _imageMimeType = definition?.imageMimeType;
    _shinyImageBytes = definition?.shinyImageBytes;
    _shinyImageMimeType = definition?.shinyImageMimeType;
""",
)
replace_once(
    editor,
    """  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Scegli immagine Fakemon',
""",
    """  Future<void> _pickImage({bool shiny = false}) async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: shiny
          ? 'Scegli immagine shiny del Fakemon'
          : 'Scegli immagine Fakemon',
""",
)
replace_once(
    editor,
    """    setState(() {
      _imageBytes = bytes;
      _imageMimeType = mimeType;
    });
  }

  Future<void> _pickGlobalMove(TextEditingController controller) async {
""",
    """    setState(() {
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
        const SizedBox(height: 6),
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
                      const Icon(Icons.add_photo_alternate_outlined, size: 44),
                      const SizedBox(height: 8),
                      Text(shiny ? 'AGGIUNGI SHINY' : 'CARICA IMMAGINE'),
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
            icon: const Icon(Icons.delete_outline),
            label: const Text('Rimuovi'),
          ),
      ],
    );
  }

  Future<void> _pickGlobalMove(TextEditingController controller) async {
""",
)
replace_once(
    editor,
    """        imageMimeType: imageBytes == null ? null : _imageMimeType,
        imageBase64: imageBytes == null ? null : base64Encode(imageBytes),
        localMoves: _localMoves,
""",
    """        imageMimeType: imageBytes == null ? null : _imageMimeType,
        imageBase64: imageBytes == null ? null : base64Encode(imageBytes),
        shinyImageMimeType:
            _shinyImageBytes == null ? null : _shinyImageMimeType,
        shinyImageBase64: _shinyImageBytes == null
            ? null
            : base64Encode(_shinyImageBytes!),
        localMoves: _localMoves,
""",
)
replace_once(
    editor,
    """                  Center(
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
""",
    """                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _imagePickerCard(
                          label: 'IMMAGINE PRINCIPALE',
                          bytes: _imageBytes,
                          shiny: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _imagePickerCard(
                          label: 'SHINY (FACOLTATIVA)',
                          bytes: _shinyImageBytes,
                          shiny: true,
                        ),
                      ),
                    ],
                  ),
""",
)

# ---------------------------------------------------------------------------
# Advanced editor: link the current Fakemon as an external form, and select
# evolution items/moves from the real catalogs.
# ---------------------------------------------------------------------------
advanced_editor = 'lib/screens/pokemon/custom_pokemon_advanced_editor_screen.dart'
replace_once(
    advanced_editor,
    """import '../../models/custom_pokemon_advanced_data.dart';
import '../../models/pokemon.dart';
""",
    """import '../../models/bag_item.dart';
import '../../models/custom_pokemon_advanced_data.dart';
import '../../models/move_data.dart';
import '../../models/pokemon.dart';
""",
)
replace_once(
    advanced_editor,
    """import '../../repositories/pokemon_repository.dart';
""",
    """import '../../repositories/item_repository.dart';
import '../../repositories/move_repository.dart';
import '../../repositories/pokemon_repository.dart';
""",
)
replace_once(
    advanced_editor,
    """  late final TextEditingController _secretHint;
  late List<CustomPokemonEvolutionLink> _evolvesFrom;
""",
    """  late final TextEditingController _secretHint;
  late final TextEditingController _alternateFormHint;
  CustomPokemonReference? _alternateFormOf;
  late CustomPokemonFormDuration _alternateFormDuration;
  late bool _alternateFormSecretUntilActivated;
  late bool _alternateFormTrackInPokedex;
  late List<CustomPokemonEvolutionLink> _evolvesFrom;
""",
)
replace_once(
    advanced_editor,
    """  List<Pokemon> _catalog = const [];
  bool _loading = true;
""",
    """  List<Pokemon> _catalog = const [];
  List<BagItem> _itemCatalog = const [];
  List<MoveData> _moveCatalog = const [];
  bool _loading = true;
""",
)
replace_once(
    advanced_editor,
    """    _secretHint = TextEditingController(text: widget.initial.secretHint ?? '');
    _evolvesFrom = [...widget.initial.evolvesFrom];
""",
    """    _secretHint = TextEditingController(text: widget.initial.secretHint ?? '');
    _alternateFormHint = TextEditingController(
      text: widget.initial.alternateFormHint ?? '',
    );
    _alternateFormOf = widget.initial.alternateFormOf;
    _alternateFormDuration = widget.initial.alternateFormDuration;
    _alternateFormSecretUntilActivated =
        widget.initial.alternateFormSecretUntilActivated;
    _alternateFormTrackInPokedex =
        widget.initial.alternateFormTrackInPokedex;
    _evolvesFrom = [...widget.initial.evolvesFrom];
""",
)
replace_once(
    advanced_editor,
    """    _secretHint.dispose();
    super.dispose();
""",
    """    _secretHint.dispose();
    _alternateFormHint.dispose();
    super.dispose();
""",
)
replace_once(
    advanced_editor,
    """  Future<void> _loadCatalog() async {
    final catalog = await PokemonRepository().getAllPokemon(
      includeSealed: true,
    );
    if (!mounted) return;
    setState(() {
      _catalog = catalog;
      _loading = false;
    });
  }
""",
    """  Future<void> _loadCatalog() async {
    final catalog = await PokemonRepository().getAllPokemon(
      includeSealed: true,
    );
    final items = await ItemRepository().getWebItems();
    final moves = await MoveRepository().getAllMoves();
    if (!mounted) return;
    setState(() {
      _catalog = catalog;
      _itemCatalog = items;
      _moveCatalog = moves;
      _loading = false;
    });
  }

  Future<void> _pickAlternateFormParent() async {
    final pokemon = await showSearch<Pokemon?>(
      context: context,
      delegate: _PokemonSearchDelegate(
        _catalog
            .where((entry) => entry.id != widget.currentPokemonId)
            .toList(growable: false),
      ),
    );
    if (pokemon == null || !mounted) return;
    final custom = CustomPokemonRuntimeRegistry.definitionFor(pokemon.id);
    setState(() {
      _alternateFormOf = CustomPokemonReference(
        pokemonId: pokemon.id,
        stableId: custom?.stableId,
        name: pokemon.name,
      );
    });
  }
""",
)
replace_once(
    advanced_editor,
    """        builder: (_) => _EvolutionLinkDialog(
          title: evolvesFrom ? 'Si evolve da' : 'Può evolversi in',
          catalog: _catalog,
          currentPokemonId: widget.currentPokemonId,
        ),
""",
    """        builder: (_) => _EvolutionLinkDialog(
          title: evolvesFrom ? 'Si evolve da' : 'Può evolversi in',
          catalog: _catalog,
          itemCatalog: _itemCatalog,
          moveCatalog: _moveCatalog,
          currentPokemonId: widget.currentPokemonId,
        ),
""",
)
replace_once(
    advanced_editor,
    """        secretHint: _nullable(_secretHint.text),
        evolvesFrom: List.unmodifiable(_evolvesFrom),
""",
    """        secretHint: _nullable(_secretHint.text),
        alternateFormOf: _alternateFormOf,
        alternateFormDuration: _alternateFormDuration,
        alternateFormSecretUntilActivated:
            _alternateFormSecretUntilActivated,
        alternateFormTrackInPokedex: _alternateFormTrackInPokedex,
        alternateFormHint: _nullable(_alternateFormHint.text),
        evolvesFrom: List.unmodifiable(_evolvesFrom),
""",
)
replace_once(
    advanced_editor,
    """                  _EvolutionSection(
                    title: 'Nuove pre-evoluzioni',
""",
    """                  _AdvancedSection(
                    title: 'Forma alternativa di una specie esistente',
                    children: [
                      const Text(
                        'Collega questo Fakemon a un Pokémon già presente: apparirà nel selettore delle forme di quella specie, senza creare una voce separata nel Pokédex.',
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.hub_outlined),
                        title: Text(
                          _alternateFormOf?.name ??
                              'Nessuna specie collegata',
                        ),
                        subtitle: _alternateFormOf == null
                            ? const Text('Tocca per scegliere Pokémon o Fakemon')
                            : Text('#${_alternateFormOf!.pokemonId ?? '-'}'),
                        trailing: const Icon(Icons.search),
                        onTap: _pickAlternateFormParent,
                      ),
                      if (_alternateFormOf != null) ...[
                        DropdownButtonFormField<CustomPokemonFormDuration>(
                          initialValue: _alternateFormDuration,
                          decoration: const InputDecoration(
                            labelText: 'Durata della forma',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: CustomPokemonFormDuration.permanent,
                              child: Text('Permanente'),
                            ),
                            DropdownMenuItem(
                              value: CustomPokemonFormDuration.battle,
                              child: Text('Momentanea di battaglia'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _alternateFormDuration = value);
                            }
                          },
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Segreta fino all’attivazione'),
                          value: _alternateFormSecretUntilActivated,
                          onChanged: (value) => setState(
                            () => _alternateFormSecretUntilActivated = value,
                          ),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Registra questa forma nel Pokédex'),
                          value: _alternateFormTrackInPokedex,
                          onChanged: (value) => setState(
                            () => _alternateFormTrackInPokedex = value,
                          ),
                        ),
                        TextField(
                          controller: _alternateFormHint,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Indizio sulla forma, facoltativo',
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => setState(() {
                              _alternateFormOf = null;
                              _alternateFormHint.clear();
                            }),
                            icon: const Icon(Icons.link_off),
                            label: const Text('RIMUOVI COLLEGAMENTO'),
                          ),
                        ),
                      ],
                    ],
                  ),
                  _EvolutionSection(
                    title: 'Nuove pre-evoluzioni',
""",
)
replace_once(
    advanced_editor,
    """                    title: 'Forme alternative',
                    children: [
                      const Text(
                        'Le forme permanenti restano associate all’esemplare. Le forme di battaglia tornano alla forma precedente quando termina la sessione.',
                      ),
""",
    """                    title: 'Sottoforme del Fakemon',
                    children: [
                      const Text(
                        'Se questo Fakemon possiede a sua volta più aspetti, puoi aggiungerli qui. Per collegare il Fakemon come forma di una specie esistente usa la sezione precedente.',
                      ),
""",
)
replace_once(
    advanced_editor,
    """    required this.catalog,
    this.currentPokemonId,
  });

  final String title;
  final List<Pokemon> catalog;
""",
    """    required this.catalog,
    required this.itemCatalog,
    required this.moveCatalog,
    this.currentPokemonId,
  });

  final String title;
  final List<Pokemon> catalog;
  final List<BagItem> itemCatalog;
  final List<MoveData> moveCatalog;
""",
)
replace_once(
    advanced_editor,
    """  CustomPokemonReference? _selected;
  String? _gender;
""",
    """  CustomPokemonReference? _selected;
  BagItem? _selectedItem;
  MoveData? _selectedMove;
  String? _gender;
""",
)
insert_before(
    advanced_editor,
    """  void _submit() {
""",
    """  Future<void> _pickItem() async {
    final item = await showSearch<BagItem?>(
      context: context,
      delegate: _ItemSearchDelegate(widget.itemCatalog),
    );
    if (item == null || !mounted) return;
    setState(() {
      _selectedItem = item;
      _item.text = item.name;
    });
  }

  Future<void> _pickMove() async {
    final move = await showSearch<MoveData?>(
      context: context,
      delegate: _MoveSearchDelegate(widget.moveCatalog),
    );
    if (move == null || !mounted) return;
    setState(() {
      _selectedMove = move;
      _move.text = move.name;
    });
  }

""",
)
replace_once(
    advanced_editor,
    """    if (_item.text.trim().isNotEmpty) {
      conditions.add(
        CustomPokemonEvolutionCondition(type: 'item', value: _item.text.trim()),
      );
    }
    if (_move.text.trim().isNotEmpty) {
      conditions.add(
        CustomPokemonEvolutionCondition(type: 'move', value: _move.text.trim()),
      );
    }
""",
    """    final selectedItem = _selectedItem;
    if (selectedItem != null) {
      conditions.add(
        CustomPokemonEvolutionCondition(type: 'item', value: selectedItem.id),
      );
    }
    final selectedMove = _selectedMove;
    if (selectedMove != null) {
      conditions.add(
        CustomPokemonEvolutionCondition(
          type: 'move',
          value: selectedMove.technicalName,
        ),
      );
    }
""",
)
replace_once(
    advanced_editor,
    """              TextField(
                controller: _item,
                decoration: const InputDecoration(
                  labelText: 'Oggetto richiesto',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _move,
                decoration: const InputDecoration(labelText: 'Mossa richiesta'),
              ),
""",
    """              TextField(
                controller: _item,
                readOnly: true,
                onTap: _pickItem,
                decoration: const InputDecoration(
                  labelText: 'Oggetto richiesto',
                  helperText: 'Seleziona dal catalogo degli oggetti',
                  suffixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _move,
                readOnly: true,
                onTap: _pickMove,
                decoration: const InputDecoration(
                  labelText: 'Mossa richiesta',
                  helperText: 'Seleziona dal catalogo delle mosse',
                  suffixIcon: Icon(Icons.search),
                ),
              ),
""",
)
insert_before(
    advanced_editor,
    """class _CustomFormEditorScreen extends StatefulWidget {
""",
    """class _ItemSearchDelegate extends SearchDelegate<BagItem?> {
  _ItemSearchDelegate(this.items);

  final List<BagItem> items;

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(
          tooltip: 'Pulisci',
          onPressed: () => query = '',
          icon: const Icon(Icons.clear),
        ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        tooltip: 'Indietro',
        onPressed: () => close(context, null),
        icon: const Icon(Icons.arrow_back),
      );

  @override
  Widget buildResults(BuildContext context) => _results();

  @override
  Widget buildSuggestions(BuildContext context) => _results();

  Widget _results() {
    final normalized = query.trim().toLowerCase();
    final results = items
        .where(
          (item) =>
              normalized.isEmpty ||
              item.name.toLowerCase().contains(normalized) ||
              item.technicalName.toLowerCase().contains(normalized) ||
              item.id.toLowerCase().contains(normalized),
        )
        .take(150)
        .toList(growable: false);
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return ListTile(
          leading: const Icon(Icons.backpack_outlined),
          title: Text(item.name),
          subtitle: Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis),
          onTap: () => close(context, item),
        );
      },
    );
  }
}

class _MoveSearchDelegate extends SearchDelegate<MoveData?> {
  _MoveSearchDelegate(this.moves);

  final List<MoveData> moves;

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(
          tooltip: 'Pulisci',
          onPressed: () => query = '',
          icon: const Icon(Icons.clear),
        ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        tooltip: 'Indietro',
        onPressed: () => close(context, null),
        icon: const Icon(Icons.arrow_back),
      );

  @override
  Widget buildResults(BuildContext context) => _results();

  @override
  Widget buildSuggestions(BuildContext context) => _results();

  Widget _results() {
    final normalized = query.trim().toLowerCase();
    final results = moves
        .where(
          (move) =>
              normalized.isEmpty ||
              move.name.toLowerCase().contains(normalized) ||
              move.technicalName.toLowerCase().contains(normalized) ||
              move.type.toLowerCase().contains(normalized),
        )
        .take(150)
        .toList(growable: false);
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final move = results[index];
        return ListTile(
          leading: const Icon(Icons.bolt_outlined),
          title: Text(move.name),
          subtitle: Text('${move.type} · ${move.description}', maxLines: 2, overflow: TextOverflow.ellipsis),
          onTap: () => close(context, move),
        );
      },
    );
  }
}

""",
)

# ---------------------------------------------------------------------------
# Pokemon catalog: external Fakemon forms are merged into their parent species
# and sealed forms are hidden until discovery.
# ---------------------------------------------------------------------------
pokemon_repository = 'lib/repositories/pokemon_repository.dart'
replace_once(
    pokemon_repository,
    """    final customDefinitions = await CustomPokemonRepository().getAll();
    for (final definition in customDefinitions) {
      pokemonByNumber[definition.pokemonId] = definition.toPokemon();
    }

    final localizedTexts = await PokemonLocalizationRepository()
""",
    """    final customDefinitions = await CustomPokemonRepository().getAll();
    for (final definition in customDefinitions) {
      if (definition.advanced.alternateFormOf != null) continue;
      pokemonByNumber[definition.pokemonId] = definition.toPokemon();
    }
    for (final definition in customDefinitions) {
      final parentReference = definition.advanced.alternateFormOf;
      if (parentReference == null) continue;
      final parentId = _resolveAlternateFormParentId(
        parentReference,
        customDefinitions,
        pokemonByNumber,
      );
      final parent = parentId == null ? null : pokemonByNumber[parentId];
      if (parent == null) continue;
      final formPokemon = definition.toPokemon().copyWith(
        name: parent.name,
        formDefinitions: const [],
      );
      pokemonByNumber[parent.id] = parent.withAdditionalFormDefinitions([
        PokemonFormDefinition(
          key: 'fakemon-${definition.stableId}',
          displayName: definition.name,
          pokemon: formPokemon,
        ),
      ]);
    }

    final localizedTexts = await PokemonLocalizationRepository()
""",
)
insert_before(
    pokemon_repository,
    """  Future<List<Pokemon>> _filterSealed(
""",
    """  int? _resolveAlternateFormParentId(
    dynamic reference,
    List<dynamic> customDefinitions,
    Map<int, Pokemon> pokemonByNumber,
  ) {
    final directId = reference.pokemonId as int?;
    if (directId != null && pokemonByNumber.containsKey(directId)) {
      return directId;
    }
    final stableId = reference.stableId as String?;
    if (stableId != null && stableId.isNotEmpty) {
      for (final definition in customDefinitions) {
        if (definition.stableId == stableId) return definition.pokemonId as int;
      }
    }
    final name = (reference.name as String).trim().toLowerCase();
    if (name.isEmpty) return null;
    for (final entry in pokemonByNumber.entries) {
      if (entry.value.name.trim().toLowerCase() == name) return entry.key;
    }
    return null;
  }

""",
)
replace_once(
    pokemon_repository,
    """    return pokemon
        .where((entry) => !hiddenIds.contains(entry.id))
        .toList(growable: false);
""",
    """    return pokemon
        .where((entry) => !hiddenIds.contains(entry.id))
        .map((entry) {
          final visibleForms = entry.formDefinitions
              .where((form) => !hiddenIds.contains(form.pokemon.id))
              .toList(growable: false);
          if (visibleForms.length == entry.formDefinitions.length) return entry;
          return entry.copyWith(formDefinitions: visibleForms);
        })
        .toList(growable: false);
""",
)
replace_once(
    pokemon_repository,
    """        return 'Male';
""",
    """        return 'Maschio';
""",
)
replace_once(
    pokemon_repository,
    """        return 'Female';
""",
    """        return 'Femmina';
""",
)
replace_once(pokemon_repository, "return 'Alolan';", "return 'Alola';")
replace_once(pokemon_repository, "return 'Galarian';", "return 'Galar';")
replace_once(pokemon_repository, "return 'Hisuian';", "return 'Hisui';")
replace_once(pokemon_repository, "return 'Paldean';", "return 'Paldea';")

# ---------------------------------------------------------------------------
# Runtime registry: custom artwork and temporary-form behavior also work when
# the custom definition is attached to an official parent species.
# ---------------------------------------------------------------------------
runtime = 'lib/services/custom_pokemon_runtime_registry.dart'
replace_once(
    runtime,
    """    final definition = _definitions[pokemonId];
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
""",
    """    final definition = _definitions[pokemonId];
    if (definition != null) {
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
      if (key.isEmpty || key == 'base') {
        return shiny
            ? definition.shinyImageBytes ?? definition.imageBytes
            : definition.imageBytes;
      }
    }

    final alternate = alternateFormDefinitionFor(pokemonId, formName);
    if (alternate == null) return null;
    return shiny
        ? alternate.shinyImageBytes ?? alternate.imageBytes
        : alternate.imageBytes;
""",
)
insert_before(
    runtime,
    """  static CustomPokemonDefinition? definitionByStableId(String? stableId) {
""",
    """  static CustomPokemonDefinition? alternateFormDefinitionFor(
    int parentPokemonId,
    String? formName,
  ) {
    final requested = _referenceKey(formName ?? '');
    if (requested.isEmpty || requested == 'base') return null;
    for (final candidate in _definitions.values) {
      final parent = candidate.advanced.alternateFormOf;
      if (parent == null) continue;
      final resolvedParent = resolveReference(parent);
      final resolvedParentId = resolvedParent?.pokemonId ?? parent.pokemonId;
      if (resolvedParentId != parentPokemonId) continue;
      final keys = <String>{
        _referenceKey(candidate.name),
        _referenceKey(candidate.stableId),
        _referenceKey('fakemon-${candidate.stableId}'),
      };
      if (keys.contains(requested)) return candidate;
    }
    return null;
  }

""",
)
replace_once(
    runtime,
    """  static bool isTemporaryForm(int pokemonId, String? formName) {
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
    """  static bool isTemporaryForm(int pokemonId, String? formName) {
    final definition = _definitions[pokemonId];
    if (definition != null) {
      final key = Pokemon.formReferenceKey(formName ?? '', definition.name);
      if (definition.advanced.forms.any(
        (form) =>
            form.duration == CustomPokemonFormDuration.battle &&
            (Pokemon.formReferenceKey(form.name, definition.name) == key ||
                Pokemon.formReferenceKey(form.id, definition.name) == key),
      )) {
        return true;
      }
    }
    return alternateFormDefinitionFor(pokemonId, formName)
            ?.advanced
            .alternateFormDuration ==
        CustomPokemonFormDuration.battle;
  }

  static bool hasTemporaryForms(int pokemonId) {
    if (_definitions[pokemonId]?.advanced.forms.any(
          (form) => form.duration == CustomPokemonFormDuration.battle,
        ) ==
        true) {
      return true;
    }
    return _definitions.values.any((candidate) {
      final parent = candidate.advanced.alternateFormOf;
      if (parent == null ||
          candidate.advanced.alternateFormDuration !=
              CustomPokemonFormDuration.battle) {
        return false;
      }
      final resolvedParent = resolveReference(parent);
      return (resolvedParent?.pokemonId ?? parent.pokemonId) == pokemonId;
    });
  }
""",
)
insert_before(
    runtime,
    """  static Map<String, MoveData> moveCatalogFor(int pokemonId) {
""",
    """  static String _referenceKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r\"[’']\"), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

""",
)

# ---------------------------------------------------------------------------
# Evolution list de-duplication: aliases in the repository must not duplicate
# each canonical option.
# ---------------------------------------------------------------------------
evolution_repository = 'lib/repositories/evolution_repository.dart'
replace_once(
    evolution_repository,
    """    final grouped = <String, List<EvolutionOption>>{};
    for (final entry in base.entries) {
      final options = grouped.putIfAbsent(
        _referenceKey(entry.key),
        () => <EvolutionOption>[],
      );
      options.addAll(entry.value.options);
    }
""",
    """    final grouped = <String, List<EvolutionOption>>{};
    final signaturesBySource = <String, Set<String>>{};
    for (final entry in base.entries) {
      final sourceKey = _referenceKey(entry.key);
      final options = grouped.putIfAbsent(sourceKey, () => <EvolutionOption>[]);
      final signatures = signaturesBySource.putIfAbsent(
        sourceKey,
        () => <String>{},
      );
      for (final option in entry.value.options) {
        if (signatures.add(_optionSignature(option))) options.add(option);
      }
    }
""",
)
insert_before(
    evolution_repository,
    """  void _addCustomOption(
""",
    """  String _optionSignature(EvolutionOption option) {
    return <String>[
      option.id,
      option.fromKey,
      option.toKey,
      option.targetPokemonId?.toString() ?? '',
      option.targetStableId ?? '',
      option.targetFormName ?? '',
      for (final condition in option.conditions)
        '${condition.type}:${condition.valueLabel}',
      for (final effect in option.effects)
        '${effect.type}:${effect.valueLabel}',
    ].join('|');
  }

""",
)

# ---------------------------------------------------------------------------
# Italian labels while retaining stable English storage keys.
# ---------------------------------------------------------------------------
nature = 'lib/models/pokemon_nature.dart'
replace_once(
    nature,
    """  static List<String> get names => modifiers.keys.toList();

  static Map<String, int> forName(String nature) {
""",
    """  static const Map<String, String> labels = {
    'Reckless': 'Sconsiderata',
    'Rash': 'Impulsiva',
    'Brave': 'Coraggiosa',
    'Arrogant': 'Arrogante',
    'Skittish': 'Timorosa',
    'Hasty': 'Frettolosa',
    'Energetic': 'Energica',
    'Clumsy': 'Goffa',
    'Apathetic': 'Apatica',
    'Stubborn': 'Testarda',
    'Grumpy': 'Scontrosa',
    'Relaxed': 'Rilassata',
    'Careful': 'Prudente',
    'Curious': 'Curiosa',
    'Naughty': 'Birichina',
    'Cheerful': 'Allegra',
    'Sassy': 'Insolente',
    'Innocent': 'Innocente',
    'Hardy': 'Tenace',
    'Nimble': 'Agile',
    'No Nature': 'Nessuna natura',
  };

  static List<String> get names => modifiers.keys.toList();

  static String labelFor(String nature) => labels[nature] ?? nature;

  static Map<String, int> forName(String nature) {
""",
)

pokemon_edit = 'lib/screens/pokemon/pokemon_edit_screen.dart'
replace_once(
    pokemon_edit,
    """  static const _skills = [
""",
    """  static const _skillLabels = <String, String>{
    'Acrobatics': 'Acrobazia',
    'Animal Handling': 'Addestrare Animali',
    'Arcana': 'Arcano',
    'Athletics': 'Atletica',
    'Deception': 'Inganno',
    'History': 'Storia',
    'Insight': 'Intuizione',
    'Intimidation': 'Intimidire',
    'Investigation': 'Investigazione',
    'Medicine': 'Medicina',
    'Nature': 'Natura',
    'Perception': 'Percezione',
    'Performance': 'Intrattenere',
    'Persuasion': 'Persuasione',
    'Religion': 'Religione',
    'Sleight of Hand': 'Rapidità di Mano',
    'Stealth': 'Furtività',
    'Survival': 'Sopravvivenza',
  };

  static const _skills = [
""",
)
replace_once(
    pokemon_edit,
    """          title: 'Scegli skill',
          options: _skills,
          blockedOptions: blocked,
""",
    """          title: 'Scegli competenza',
          options: _skills,
          blockedOptions: blocked,
          labels: _skillLabels,
""",
)
replace_once(pokemon_edit, "child: Text(nature),", "child: Text(PokemonNature.labelFor(nature)),")
replace_once(pokemon_edit, "child: Text('Genderless'),", "child: Text('Senza sesso'),")
replace_once(pokemon_edit, "title: 'Move set',", "title: 'Mosse',")
replace_once(pokemon_edit, "title: 'Abilities',", "title: 'Abilità',")
replace_once(pokemon_edit, "emptyLabel: 'ABILITY',", "emptyLabel: 'ABILITÀ',")
replace_once(pokemon_edit, "title: 'Feats',", "title: 'Privilegi',")
replace_once(pokemon_edit, "emptyLabel: 'FEAT',", "emptyLabel: 'PRIVILEGIO',")
replace_once(pokemon_edit, "title: 'Skills',", "title: 'Competenze',")
replace_once(
    pokemon_edit,
    """                    values: _extraSkills,
                    emptyLabel: 'SKILL',
""",
    """                    values: _extraSkills,
                    labels: _skillLabels,
                    emptyLabel: 'COMPETENZA',
""",
)
replace_once(pokemon_edit, "title: 'Extra ability score',", "title: 'Punteggi caratteristica extra',")
replace_once(pokemon_edit, "title: const Text('Terrain Adept'),", "title: const Text('Esperto del terreno'),")

selector = 'lib/screens/pokemon/evolution_selector_sheet.dart'
replace_once(
    selector,
    """              : choice.option.toName.toUpperCase(),
""",
    """              : _localizedEvolutionName(choice.option.toName).toUpperCase(),
""",
)
insert_before(
    selector,
    """class _ConditionChip extends StatelessWidget {
""",
    """String _localizedEvolutionName(String value) {
  final trimmed = value.trim();
  final regional = RegExp(
    r'^(Alolan|Galarian|Hisuian|Paldean)\\s+(.+)$',
    caseSensitive: false,
  ).firstMatch(trimmed);
  if (regional == null) return trimmed;
  final region = switch (regional.group(1)!.toLowerCase()) {
    'alolan' => 'Alola',
    'galarian' => 'Galar',
    'hisuian' => 'Hisui',
    'paldean' => 'Paldea',
    _ => regional.group(1)!,
  };
  return '${regional.group(2)} di $region';
}

""",
)

evolution_service = 'lib/services/evolution_service.dart'
replace_once(evolution_service, "return 'Genderless';", "return 'Senza sesso';")

# ---------------------------------------------------------------------------
# Catalog import remaps the new alternate-form parent reference as well.
# ---------------------------------------------------------------------------
embedded_transfer = 'lib/services/embedded_custom_pokemon_transfer_service.dart'
replace_once(
    embedded_transfer,
    """      for (final key in ['evolvesFrom', 'evolvesTo']) {
""",
    """      final rawAlternateFormOf = advanced['alternateFormOf'];
      if (rawAlternateFormOf is Map) {
        final alternateJson = Map<String, dynamic>.from(rawAlternateFormOf);
        final sourcePokemonId = int.tryParse(
          alternateJson['pokemonId']?.toString() ?? '',
        );
        if (sourcePokemonId != null) {
          alternateJson['pokemonId'] =
              idMap[sourcePokemonId] ?? sourcePokemonId;
        }
        advanced['alternateFormOf'] = alternateJson;
      }
      for (final key in ['evolvesFrom', 'evolvesTo']) {
""",
)

# ---------------------------------------------------------------------------
# Tests and release metadata.
# ---------------------------------------------------------------------------
fakemon_test = 'test/fakemon_advanced_test.dart'
insert_before(
    fakemon_test,
    """  test('Eevee riceve una nuova evoluzione Fakemon', () async {
""",
    """  test('un Fakemon può essere collegato come forma di una specie', () {
    final definition = _definition(
      stableId: 'storm-eon',
      pokemonId: 2000000,
      name: 'Stormeon',
      advanced: const CustomPokemonAdvancedData(
        alternateFormOf: CustomPokemonReference(
          pokemonId: 133,
          name: 'Eevee',
        ),
        alternateFormDuration: CustomPokemonFormDuration.battle,
      ),
    );
    final decoded = CustomPokemonDefinition.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(jsonEncode(definition.toJson())) as Map,
      ),
    );

    expect(decoded.advanced.alternateFormOf?.pokemonId, 133);
    expect(
      decoded.advanced.alternateFormDuration,
      CustomPokemonFormDuration.battle,
    );

    CustomPokemonRuntimeRegistry.replaceAll([decoded]);
    expect(
      CustomPokemonRuntimeRegistry.isTemporaryForm(133, 'Stormeon'),
      isTrue,
    );
  });

""",
)

evolution_regression = 'test/evolution_repository_regression_test.dart'
insert_before(
    evolution_regression,
    """  test('le evoluzioni regionali di Hisui usano nomi risolvibili', () async {
""",
    """  test('le evoluzioni canoniche non sono duplicate dagli alias', () async {
    final evolutions = await EvolutionRepository().getEvolutionData();

    final pidgeyTargets = evolutions['pidgey']!.options
        .map((option) => option.toKey)
        .toList(growable: false);
    expect(pidgeyTargets, ['pidgeotto']);

    final exeggcuteTargets = evolutions['exeggcute']!.options
        .map((option) => '${option.toKey}:${option.conditions.map((condition) => condition.valueLabel).join(',')}')
        .toSet();
    expect(exeggcuteTargets.length, 2);
  });

""",
)

replace_once('pubspec.yaml', 'version: 1.1.0+4', 'version: 1.2.0+5')
replace_once(
    'CHANGELOG.md',
    """## [Non rilasciato]

""",
    """## [Non rilasciato]

Nessuna modifica successiva alla release 1.2.0.

## [1.2.0] - 2026-07-22

### Aggiunto

- possibilità di collegare un Fakemon come forma alternativa permanente o momentanea di una specie esistente;
- selettori ricercabili per oggetti e mosse richiesti dalle evoluzioni personalizzate;
- artwork shiny facoltativo accanto all’immagine principale nell’editor Fakemon.

### Corretto

- rimozione delle evoluzioni duplicate nel selettore;
- localizzazione italiana delle nature e di varie etichette residue dell’editor Pokémon;
- visualizzazione e comportamento delle forme Fakemon collegate a Pokémon ufficiali.

""",
)
