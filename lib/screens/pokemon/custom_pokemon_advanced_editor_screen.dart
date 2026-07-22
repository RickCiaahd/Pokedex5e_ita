import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/bag_item.dart';
import '../../models/custom_pokemon_advanced_data.dart';
import '../../models/move_data.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_attributes.dart';
import '../../repositories/item_repository.dart';
import '../../repositories/move_repository.dart';
import '../../repositories/pokemon_repository.dart';
import '../../services/custom_pokemon_runtime_registry.dart';
import '../../widgets/layout/responsive_content.dart';

class CustomPokemonAdvancedEditorScreen extends StatefulWidget {
  const CustomPokemonAdvancedEditorScreen({
    super.key,
    required this.initial,
    required this.currentName,
    this.currentPokemonId,
  });

  final CustomPokemonAdvancedData initial;
  final String currentName;
  final int? currentPokemonId;

  @override
  State<CustomPokemonAdvancedEditorScreen> createState() =>
      _CustomPokemonAdvancedEditorScreenState();
}

class _CustomPokemonAdvancedEditorScreenState
    extends State<CustomPokemonAdvancedEditorScreen> {
  late bool _secretUntilDiscovered;
  late final TextEditingController _secretHint;
  late final TextEditingController _alternateFormHint;
  CustomPokemonReference? _alternateFormOf;
  late CustomPokemonFormDuration _alternateFormDuration;
  late bool _alternateFormSecretUntilActivated;
  late bool _alternateFormTrackInPokedex;
  late List<CustomPokemonEvolutionLink> _evolvesFrom;
  late List<CustomPokemonEvolutionLink> _evolvesTo;
  late List<CustomPokemonForm> _forms;
  List<Pokemon> _catalog = const [];
  List<BagItem> _itemCatalog = const [];
  List<MoveData> _moveCatalog = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _secretUntilDiscovered = widget.initial.secretUntilDiscovered;
    _secretHint = TextEditingController(text: widget.initial.secretHint ?? '');
    _alternateFormHint = TextEditingController(
      text: widget.initial.alternateFormHint ?? '',
    );
    _alternateFormOf = widget.initial.alternateFormOf;
    _alternateFormDuration = widget.initial.alternateFormDuration;
    _alternateFormSecretUntilActivated =
        widget.initial.alternateFormSecretUntilActivated;
    _alternateFormTrackInPokedex = widget.initial.alternateFormTrackInPokedex;
    _evolvesFrom = [...widget.initial.evolvesFrom];
    _evolvesTo = [...widget.initial.evolvesTo];
    _forms = [...widget.initial.forms];
    _loadCatalog();
  }

  @override
  void dispose() {
    _secretHint.dispose();
    _alternateFormHint.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
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

  Future<void> _addEvolution({required bool evolvesFrom}) async {
    final link = await showDialog<CustomPokemonEvolutionLink>(
      context: context,
      builder: (_) => _EvolutionLinkDialog(
        title: evolvesFrom ? 'Si evolve da' : 'Può evolversi in',
        catalog: _catalog,
        itemCatalog: _itemCatalog,
        moveCatalog: _moveCatalog,
        currentPokemonId: widget.currentPokemonId,
      ),
    );
    if (link == null || !mounted) return;
    setState(() {
      if (evolvesFrom) {
        _evolvesFrom = [..._evolvesFrom, link];
      } else {
        _evolvesTo = [..._evolvesTo, link];
      }
    });
  }

  Future<void> _addForm([CustomPokemonForm? existing]) async {
    final form = await Navigator.of(context).push<CustomPokemonForm>(
      MaterialPageRoute(
        builder: (_) => _CustomFormEditorScreen(initial: existing),
      ),
    );
    if (form == null || !mounted) return;
    setState(() {
      if (existing == null) {
        _forms = [..._forms, form];
      } else {
        final index = _forms.indexOf(existing);
        if (index >= 0) _forms = [..._forms]..[index] = form;
      }
    });
  }

  void _save() {
    Navigator.of(context).pop(
      CustomPokemonAdvancedData(
        secretUntilDiscovered: _secretUntilDiscovered,
        sealedForPlayer: widget.initial.sealedForPlayer,
        secretHint: _nullable(_secretHint.text),
        alternateFormOf: _alternateFormOf,
        alternateFormDuration: _alternateFormDuration,
        alternateFormSecretUntilActivated: _alternateFormSecretUntilActivated,
        alternateFormTrackInPokedex: _alternateFormTrackInPokedex,
        alternateFormHint: _nullable(_alternateFormHint.text),
        evolvesFrom: List.unmodifiable(_evolvesFrom),
        evolvesTo: List.unmodifiable(_evolvesTo),
        forms: List.unmodifiable(_forms),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('FAKEMON AVANZATO · ${widget.currentName}')),
      body: ResponsiveContent(
        maxWidth: 900,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  _AdvancedSection(
                    title: 'Contenuto segreto',
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Segreto fino alla scoperta'),
                        subtitle: const Text(
                          'L’esportazione per i giocatori può essere sigillata: nome, immagine e dati non saranno mostrati prima della cattura o dell’evoluzione.',
                        ),
                        value: _secretUntilDiscovered,
                        onChanged: (value) =>
                            setState(() => _secretUntilDiscovered = value),
                      ),
                      TextField(
                        controller: _secretHint,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Indizio facoltativo',
                          helperText:
                              'Può essere mostrato senza rivelare nome e aspetto.',
                        ),
                      ),
                    ],
                  ),
                  _AdvancedSection(
                    title: 'Forma alternativa di una specie esistente',
                    children: [
                      const Text(
                        'Collega questo Fakemon a un Pokémon già presente: apparirà nel selettore delle forme di quella specie, senza creare una voce separata nel Pokédex.',
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.hub_outlined),
                        title: Text(
                          _alternateFormOf?.name ?? 'Nessuna specie collegata',
                        ),
                        subtitle: _alternateFormOf == null
                            ? const Text(
                                'Tocca per scegliere Pokémon o Fakemon',
                              )
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
                          title: const Text(
                            'Registra questa forma nel Pokédex',
                          ),
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
                    description:
                        '${widget.currentName} diventa una nuova evoluzione delle specie elencate.',
                    links: _evolvesFrom,
                    onAdd: () => _addEvolution(evolvesFrom: true),
                    onDelete: (index) => setState(
                      () => _evolvesFrom = [..._evolvesFrom]..removeAt(index),
                    ),
                  ),
                  _EvolutionSection(
                    title: 'Evoluzioni successive',
                    description:
                        '${widget.currentName} può evolversi nelle specie elencate, comprese specie ufficiali o altri Fakemon.',
                    links: _evolvesTo,
                    onAdd: () => _addEvolution(evolvesFrom: false),
                    onDelete: (index) => setState(
                      () => _evolvesTo = [..._evolvesTo]..removeAt(index),
                    ),
                  ),
                  _AdvancedSection(
                    title: 'Sottoforme del Fakemon',
                    children: [
                      const Text(
                        'Se questo Fakemon possiede a sua volta più aspetti, puoi aggiungerli qui. Per collegare il Fakemon come forma di una specie esistente usa la sezione precedente.',
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => _addForm(),
                        icon: const Icon(Icons.add),
                        label: const Text('AGGIUNGI FORMA'),
                      ),
                      if (_forms.isEmpty)
                        const Text('Nessuna forma personalizzata.')
                      else
                        for (final entry in _forms.indexed)
                          Card(
                            child: ListTile(
                              leading: entry.$2.imageBytes == null
                                  ? const Icon(Icons.auto_awesome)
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        entry.$2.imageBytes!,
                                        width: 54,
                                        height: 54,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                              title: Text(entry.$2.name),
                              subtitle: Text(
                                entry.$2.duration ==
                                        CustomPokemonFormDuration.battle
                                    ? 'Forma momentanea di battaglia'
                                    : 'Forma permanente',
                              ),
                              onTap: () => _addForm(entry.$2),
                              trailing: IconButton(
                                tooltip: 'Rimuovi',
                                onPressed: () => setState(
                                  () =>
                                      _forms = [..._forms]..removeAt(entry.$1),
                                ),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ),
                          ),
                    ],
                  ),
                ],
              ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('SALVA DATI AVANZATI'),
          ),
        ),
      ),
    );
  }
}

class _EvolutionSection extends StatelessWidget {
  const _EvolutionSection({
    required this.title,
    required this.description,
    required this.links,
    required this.onAdd,
    required this.onDelete,
  });

  final String title;
  final String description;
  final List<CustomPokemonEvolutionLink> links;
  final VoidCallback onAdd;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    return _AdvancedSection(
      title: title,
      children: [
        Text(description),
        FilledButton.tonalIcon(
          onPressed: onAdd,
          icon: const Icon(Icons.account_tree_outlined),
          label: const Text('AGGIUNGI COLLEGAMENTO'),
        ),
        if (links.isEmpty)
          const Text('Nessun collegamento configurato.')
        else
          for (final entry in links.indexed)
            Card(
              child: ListTile(
                leading: const Icon(Icons.arrow_forward),
                title: Text(entry.$2.pokemon.name),
                subtitle: Text(_evolutionSummary(entry.$2)),
                trailing: IconButton(
                  tooltip: 'Rimuovi',
                  onPressed: () => onDelete(entry.$1),
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            ),
      ],
    );
  }
}

class _EvolutionLinkDialog extends StatefulWidget {
  const _EvolutionLinkDialog({
    required this.title,
    required this.catalog,
    required this.itemCatalog,
    required this.moveCatalog,
    this.currentPokemonId,
  });

  final String title;
  final List<Pokemon> catalog;
  final List<BagItem> itemCatalog;
  final List<MoveData> moveCatalog;
  final int? currentPokemonId;

  @override
  State<_EvolutionLinkDialog> createState() => _EvolutionLinkDialogState();
}

class _EvolutionLinkDialogState extends State<_EvolutionLinkDialog> {
  final _level = TextEditingController();
  final _item = TextEditingController();
  final _loyalty = TextEditingController();
  final _move = TextEditingController();
  final _form = TextEditingController();
  final _hint = TextEditingController();
  final _asi = TextEditingController(text: '0');
  CustomPokemonReference? _selected;
  BagItem? _selectedItem;
  MoveData? _selectedMove;
  String? _gender;

  @override
  void dispose() {
    for (final controller in [
      _level,
      _item,
      _loyalty,
      _move,
      _form,
      _hint,
      _asi,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPokemon() async {
    final pokemon = await showSearch<Pokemon?>(
      context: context,
      delegate: _PokemonSearchDelegate(
        widget.catalog
            .where((pokemon) => pokemon.id != widget.currentPokemonId)
            .toList(growable: false),
      ),
    );
    if (pokemon == null || !mounted) return;
    final custom = CustomPokemonRuntimeRegistry.definitionFor(pokemon.id);
    setState(() {
      _selected = CustomPokemonReference(
        pokemonId: pokemon.id,
        stableId: custom?.stableId,
        name: pokemon.name,
        formName: _nullable(_form.text),
      );
    });
  }

  Future<void> _pickItem() async {
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

  void _submit() {
    final selected = _selected;
    if (selected == null) return;
    final conditions = <CustomPokemonEvolutionCondition>[];
    void addNumber(String type, TextEditingController controller) {
      final value = int.tryParse(controller.text.trim());
      if (value != null && value > 0) {
        conditions.add(
          CustomPokemonEvolutionCondition(type: type, value: value),
        );
      }
    }

    addNumber('level', _level);
    addNumber('loyalty', _loyalty);
    final selectedItem = _selectedItem;
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
    if (_gender != null) {
      conditions.add(
        CustomPokemonEvolutionCondition(type: 'gender', value: _gender),
      );
    }

    final reference = CustomPokemonReference(
      pokemonId: selected.pokemonId,
      stableId: selected.stableId,
      name: selected.name,
      formName: _nullable(_form.text),
    );
    Navigator.of(context).pop(
      CustomPokemonEvolutionLink(
        id: 'evo-${DateTime.now().microsecondsSinceEpoch}',
        pokemon: reference,
        conditions: conditions,
        asiPoints: int.tryParse(_asi.text.trim()) ?? 0,
        hint: _nullable(_hint.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.catching_pokemon),
                title: Text(_selected?.name ?? 'Scegli Pokémon o Fakemon'),
                subtitle: _selected == null
                    ? null
                    : Text('#${_selected!.pokemonId ?? '-'}'),
                trailing: const Icon(Icons.search),
                onTap: _pickPokemon,
              ),
              TextField(
                controller: _form,
                decoration: const InputDecoration(
                  labelText: 'Forma specifica, facoltativa',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _numberField(_level, 'Livello minimo')),
                  const SizedBox(width: 8),
                  Expanded(child: _numberField(_loyalty, 'Lealtà minima')),
                  const SizedBox(width: 8),
                  Expanded(child: _numberField(_asi, 'Punti ASI')),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
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
              const SizedBox(height: 10),
              DropdownButtonFormField<String?>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Sesso richiesto'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Nessuno')),
                  DropdownMenuItem(value: 'male', child: Text('Maschio')),
                  DropdownMenuItem(value: 'female', child: Text('Femmina')),
                  DropdownMenuItem(
                    value: 'genderless',
                    child: Text('Senza sesso'),
                  ),
                ],
                onChanged: (value) => setState(() => _gender = value),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _hint,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Indizio evolutivo facoltativo',
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
          onPressed: _selected == null ? null : _submit,
          child: const Text('AGGIUNGI'),
        ),
      ],
    );
  }
}

class _PokemonSearchDelegate extends SearchDelegate<Pokemon?> {
  _PokemonSearchDelegate(this.catalog);

  final List<Pokemon> catalog;

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
    final results = catalog
        .where(
          (pokemon) =>
              normalized.isEmpty ||
              pokemon.name.toLowerCase().contains(normalized) ||
              pokemon.id.toString() == normalized,
        )
        .take(100)
        .toList(growable: false);
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final pokemon = results[index];
        return ListTile(
          leading: CircleAvatar(child: Text('${pokemon.id}')),
          title: Text(pokemon.name),
          subtitle: Text(pokemon.types.join(' / ')),
          onTap: () => close(context, pokemon),
        );
      },
    );
  }
}

class _ItemSearchDelegate extends SearchDelegate<BagItem?> {
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
          subtitle: Text(
            item.displayDescription,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
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
          subtitle: Text(
            '${move.type} · ${move.description}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => close(context, move),
        );
      },
    );
  }
}

class _CustomFormEditorScreen extends StatefulWidget {
  const _CustomFormEditorScreen({this.initial});

  final CustomPokemonForm? initial;

  @override
  State<_CustomFormEditorScreen> createState() =>
      _CustomFormEditorScreenState();
}

class _CustomFormEditorScreenState extends State<_CustomFormEditorScreen> {
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

  late final TextEditingController _name;
  late final TextEditingController _hint;
  late final TextEditingController _description;
  late final TextEditingController _ac;
  late final TextEditingController _hp;
  late final TextEditingController _speed;
  late final TextEditingController _abilities;
  late final TextEditingController _hiddenAbility;
  final Map<String, TextEditingController> _scores = {};
  late CustomPokemonFormDuration _duration;
  late bool _secret;
  late bool _trackInPokedex;
  String? _primaryType;
  String? _secondaryType;
  Uint8List? _imageBytes;
  String? _imageMimeType;
  Uint8List? _shinyImageBytes;
  String? _shinyImageMimeType;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _name = TextEditingController(text: initial?.name ?? '');
    _hint = TextEditingController(text: initial?.activationHint ?? '');
    _description = TextEditingController(text: initial?.description ?? '');
    _ac = TextEditingController(text: initial?.armorClass?.toString() ?? '');
    _hp = TextEditingController(text: initial?.hitPoints?.toString() ?? '');
    _speed = TextEditingController(text: initial?.speed?.toString() ?? '');
    _abilities = TextEditingController(
      text: initial?.abilities.join(', ') ?? '',
    );
    _hiddenAbility = TextEditingController(text: initial?.hiddenAbility ?? '');
    final attributes = initial?.attributes;
    final values = {
      'STR': attributes?.strength,
      'DEX': attributes?.dexterity,
      'CON': attributes?.constitution,
      'INT': attributes?.intelligence,
      'WIS': attributes?.wisdom,
      'CHA': attributes?.charisma,
    };
    for (final entry in values.entries) {
      _scores[entry.key] = TextEditingController(
        text: entry.value?.toString() ?? '',
      );
    }
    _duration = initial?.duration ?? CustomPokemonFormDuration.permanent;
    _secret = initial?.secretUntilActivated ?? false;
    _trackInPokedex = initial?.trackInPokedex ?? true;
    _primaryType = initial?.types.firstOrNull;
    _secondaryType = initial != null && initial.types.length > 1
        ? initial.types[1]
        : null;
    _imageBytes = initial?.imageBytes;
    _imageMimeType = initial?.imageMimeType;
    _shinyImageBytes = initial?.shinyImageBytes;
    _shinyImageMimeType = initial?.shinyImageMimeType;
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _hint,
      _description,
      _ac,
      _hp,
      _speed,
      _abilities,
      _hiddenAbility,
      ..._scores.values,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage({required bool shiny}) async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: shiny
          ? 'Scegli artwork shiny'
          : 'Scegli artwork della forma',
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.single;
    final bytes = picked.bytes ?? await picked.xFile.readAsBytes();
    if (bytes.length > CustomPokemonForm.maxImageBytes) return;
    final mime = switch (picked.extension?.toLowerCase()) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      _ => null,
    };
    if (mime == null || !mounted) return;
    setState(() {
      if (shiny) {
        _shinyImageBytes = bytes;
        _shinyImageMimeType = mime;
      } else {
        _imageBytes = bytes;
        _imageMimeType = mime;
      }
    });
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final scoreValues = {
      for (final entry in _scores.entries)
        entry.key: int.tryParse(entry.value.text.trim()),
    };
    final hasScores = scoreValues.values.any((value) => value != null);
    if (hasScores && scoreValues.values.any((value) => value == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Compila tutte le caratteristiche oppure lasciale vuote.',
          ),
        ),
      );
      return;
    }
    final types = <String>[];
    final primaryType = _primaryType;
    if (primaryType != null) {
      types.add(primaryType);
    }
    final secondaryType = _secondaryType;
    if (secondaryType != null && secondaryType != primaryType) {
      types.add(secondaryType);
    }
    Navigator.of(context).pop(
      CustomPokemonForm(
        id:
            widget.initial?.id ??
            'form-${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        duration: _duration,
        secretUntilActivated: _secret,
        trackInPokedex: _trackInPokedex,
        activationHint: _nullable(_hint.text),
        types: types,
        armorClass: _optionalInt(_ac.text),
        hitPoints: _optionalInt(_hp.text),
        speed: _optionalInt(_speed.text),
        attributes: hasScores
            ? PokemonAttributes(
                strength: scoreValues['STR']!,
                dexterity: scoreValues['DEX']!,
                constitution: scoreValues['CON']!,
                intelligence: scoreValues['INT']!,
                wisdom: scoreValues['WIS']!,
                charisma: scoreValues['CHA']!,
              )
            : null,
        abilities: _csv(_abilities.text),
        hiddenAbility: _nullable(_hiddenAbility.text),
        description: _nullable(_description.text),
        imageMimeType: _imageBytes == null ? null : _imageMimeType,
        imageBase64: _imageBytes == null ? null : base64Encode(_imageBytes!),
        shinyImageMimeType: _shinyImageBytes == null
            ? null
            : _shinyImageMimeType,
        shinyImageBase64: _shinyImageBytes == null
            ? null
            : base64Encode(_shinyImageBytes!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FORMA PERSONALIZZATA')),
      body: ResponsiveContent(
        maxWidth: 800,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            Row(
              children: [
                Expanded(
                  child: _ImagePicker(
                    label: 'ARTWORK',
                    bytes: _imageBytes,
                    onTap: () => _pickImage(shiny: false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ImagePicker(
                    label: 'SHINY',
                    bytes: _shinyImageBytes,
                    onTap: () => _pickImage(shiny: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nome forma'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CustomPokemonFormDuration>(
              initialValue: _duration,
              decoration: const InputDecoration(labelText: 'Durata'),
              items: const [
                DropdownMenuItem(
                  value: CustomPokemonFormDuration.permanent,
                  child: Text('Permanente'),
                ),
                DropdownMenuItem(
                  value: CustomPokemonFormDuration.battle,
                  child: Text('Momentanea, solo battaglia'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _duration = value);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Segreta fino alla prima attivazione'),
              value: _secret,
              onChanged: (value) => setState(() => _secret = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Registra nel Pokédex'),
              value: _trackInPokedex,
              onChanged: (value) => setState(() => _trackInPokedex = value),
            ),
            TextField(
              controller: _hint,
              decoration: const InputDecoration(
                labelText: 'Indizio / attivazione',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _typeDropdown(
                    label: 'Tipo principale',
                    value: _primaryType,
                    onChanged: (value) => setState(() => _primaryType = value),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _typeDropdown(
                    label: 'Tipo secondario',
                    value: _secondaryType,
                    onChanged: (value) =>
                        setState(() => _secondaryType = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _numberField(_ac, 'CA')),
                const SizedBox(width: 8),
                Expanded(child: _numberField(_hp, 'PF')),
                const SizedBox(width: 8),
                Expanded(child: _numberField(_speed, 'Velocità')),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in _scores.entries)
                  SizedBox(
                    width: 110,
                    child: _numberField(entry.value, entry.key),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _abilities,
              decoration: const InputDecoration(
                labelText: 'Abilità sostitutive, separate da virgole',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hiddenAbility,
              decoration: const InputDecoration(labelText: 'Abilità nascosta'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              minLines: 3,
              maxLines: 7,
              decoration: const InputDecoration(labelText: 'Descrizione forma'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('SALVA FORMA'),
          ),
        ),
      ),
    );
  }

  Widget _typeDropdown({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String?>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        const DropdownMenuItem(value: null, child: Text('Eredita')),
        for (final type in _types)
          DropdownMenuItem(value: type, child: Text(type)),
      ],
      onChanged: onChanged,
    );
  }
}

class _ImagePicker extends StatelessWidget {
  const _ImagePicker({
    required this.label,
    required this.bytes,
    required this.onTap,
  });

  final String label;
  final Uint8List? bytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: bytes == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_photo_alternate_outlined, size: 42),
                  const SizedBox(height: 8),
                  Text(label),
                ],
              )
            : Image.memory(bytes!, fit: BoxFit.contain),
      ),
    );
  }
}

class _AdvancedSection extends StatelessWidget {
  const _AdvancedSection({required this.title, required this.children});

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
            const SizedBox(height: 10),
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

Widget _numberField(TextEditingController controller, String label) {
  return TextField(
    controller: controller,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(labelText: label),
  );
}

String _evolutionSummary(CustomPokemonEvolutionLink link) {
  final labels = link.conditions
      .map((condition) => condition.toEvolutionRule().displayLabel)
      .toList();
  if (link.pokemon.formName != null) {
    labels.insert(0, 'Forma: ${link.pokemon.formName}');
  }
  if (link.asiPoints > 0) labels.add('ASI +${link.asiPoints}');
  if (link.hint != null) labels.add('Indizio: ${link.hint}');
  return labels.isEmpty ? 'Nessuna condizione' : labels.join(' · ');
}

List<String> _csv(String value) => value
    .split(',')
    .map((entry) => entry.trim())
    .where((entry) => entry.isNotEmpty)
    .toList(growable: false);

String? _nullable(String value) => value.trim().isEmpty ? null : value.trim();

int? _optionalInt(String value) =>
    value.trim().isEmpty ? null : int.tryParse(value.trim());
