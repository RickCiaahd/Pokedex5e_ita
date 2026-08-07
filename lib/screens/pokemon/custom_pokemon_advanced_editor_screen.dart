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
import '../../localization/ui_text.dart';

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
        title: evolvesFrom
            ? 'Si evolve da'
            : uiTextForLanguage('Può evolversi in', """Can evolve into"""),
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
      appBar: AppBar(
        title: Text(
          uiTextForLanguage(
            'FAKEMON AVANZATO · ${widget.currentName}',
            'ADVANCED FAKEMON · ${widget.currentName}',
          ),
        ),
      ),
      body: ResponsiveContent(
        maxWidth: 900,
        child: _loading
            ? Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  _AdvancedSection(
                    title: uiTextForLanguage(
                      'Contenuto segreto',
                      """Secret content""",
                    ),
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          uiTextForLanguage(
                            'Segreto fino alla scoperta',
                            """Secret until discovery""",
                          ),
                        ),
                        subtitle: Text(
                          uiTextForLanguage(
                            'L’esportazione per i giocatori può essere sigillata: nome, immagine e dati non saranno mostrati prima della cattura o dell’evoluzione.',
                            """Player exports can be sealed: name, image and data will not be shown before capture or evolution.""",
                          ),
                        ),
                        value: _secretUntilDiscovered,
                        onChanged: (value) =>
                            setState(() => _secretUntilDiscovered = value),
                      ),
                      TextField(
                        controller: _secretHint,
                        minLines: 2,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: uiTextForLanguage(
                            'Indizio facoltativo',
                            'Optional hint',
                          ),
                          helperText: uiTextForLanguage(
                            'Può essere mostrato senza rivelare nome e aspetto.',
                            """It can be shown without revealing its name and appearance.""",
                          ),
                        ),
                      ),
                    ],
                  ),
                  _AdvancedSection(
                    title: uiTextForLanguage(
                      'Forma alternativa di una specie esistente',
                      """Alternative form of an existing species""",
                    ),
                    children: [
                      Text(
                        uiTextForLanguage(
                          'Collega questo Fakemon a un Pokémon già presente: apparirà nel selettore delle forme di quella specie, senza creare una voce separata nel Pokédex.',
                          """Link this Fakemon to an existing Pokémon: it will appear in that species' form selector without creating a separate Pokédex entry.""",
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.hub_outlined),
                        title: Text(
                          _alternateFormOf?.name ??
                              uiTextForLanguage(
                                'Nessuna specie collegata',
                                """No linked species""",
                              ),
                        ),
                        subtitle: _alternateFormOf == null
                            ? Text(
                                uiTextForLanguage(
                                  'Tocca per scegliere Pokémon o Fakemon',
                                  """Tap to choose a Pokémon or Fakemon""",
                                ),
                              )
                            : Text('#${_alternateFormOf!.pokemonId ?? '-'}'),
                        trailing: const Icon(Icons.search),
                        onTap: _pickAlternateFormParent,
                      ),
                      if (_alternateFormOf != null) ...[
                        DropdownButtonFormField<CustomPokemonFormDuration>(
                          initialValue: _alternateFormDuration,
                          decoration: InputDecoration(
                            labelText: uiTextForLanguage(
                              'Durata della forma',
                              """Form duration""",
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: CustomPokemonFormDuration.permanent,
                              child: Text(
                                uiTextForLanguage(
                                  'Permanente',
                                  """Permanent""",
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: CustomPokemonFormDuration.battle,
                              child: Text(
                                uiTextForLanguage(
                                  'Momentanea di battaglia',
                                  """Temporary battle form""",
                                ),
                              ),
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
                          title: Text(
                            uiTextForLanguage(
                              'Segreta fino all’attivazione',
                              'Secret until activation',
                            ),
                          ),
                          value: _alternateFormSecretUntilActivated,
                          onChanged: (value) => setState(
                            () => _alternateFormSecretUntilActivated = value,
                          ),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            uiTextForLanguage(
                              'Registra questa forma nel Pokédex',
                              """Register this form in the Pokédex""",
                            ),
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
                          decoration: InputDecoration(
                            labelText: uiTextForLanguage(
                              'Indizio sulla forma, facoltativo',
                              """Optional form hint""",
                            ),
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
                            label: Text(
                              uiTextForLanguage(
                                'RIMUOVI COLLEGAMENTO',
                                """REMOVE LINK""",
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  _EvolutionSection(
                    title: uiTextForLanguage(
                      'Nuove pre-evoluzioni',
                      'New pre-evolutions',
                    ),
                    description: uiTextForLanguage(
                      '${widget.currentName} diventa una nuova evoluzione delle specie elencate.',
                      '${widget.currentName} becomes a new evolution of the listed species.',
                    ),
                    links: _evolvesFrom,
                    onAdd: () => _addEvolution(evolvesFrom: true),
                    onDelete: (index) => setState(
                      () => _evolvesFrom = [..._evolvesFrom]..removeAt(index),
                    ),
                  ),
                  _EvolutionSection(
                    title: uiTextForLanguage(
                      'Evoluzioni successive',
                      'Further evolutions',
                    ),
                    description: uiTextForLanguage(
                      '${widget.currentName} può evolversi nelle specie elencate, comprese specie ufficiali o altri Fakemon.',
                      """${widget.currentName} can evolve into the listed species, including official species or other Fakemon.""",
                    ),
                    links: _evolvesTo,
                    onAdd: () => _addEvolution(evolvesFrom: false),
                    onDelete: (index) => setState(
                      () => _evolvesTo = [..._evolvesTo]..removeAt(index),
                    ),
                  ),
                  _AdvancedSection(
                    title: uiTextForLanguage(
                      'Sottoforme del Fakemon',
                      'Fakemon subforms',
                    ),
                    children: [
                      Text(
                        uiTextForLanguage(
                          'Se questo Fakemon possiede a sua volta più aspetti, puoi aggiungerli qui. Per collegare il Fakemon come forma di una specie esistente usa la sezione precedente.',
                          """If this Fakemon has multiple appearances, add them here. To link it as a form of an existing species, use the previous section.""",
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => _addForm(),
                        icon: const Icon(Icons.add),
                        label: Text(
                          uiTextForLanguage('AGGIUNGI FORMA', """ADD FORM"""),
                        ),
                      ),
                      if (_forms.isEmpty)
                        Text(
                          uiTextForLanguage(
                            'Nessuna forma personalizzata.',
                            """No custom forms.""",
                          ),
                        )
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
                                    ? uiTextForLanguage(
                                        'Forma momentanea di battaglia',
                                        """Temporary battle form""",
                                      )
                                    : uiTextForLanguage(
                                        'Forma permanente',
                                        """Permanent form""",
                                      ),
                              ),
                              onTap: () => _addForm(entry.$2),
                              trailing: IconButton(
                                tooltip: uiTextForLanguage(
                                  'Rimuovi',
                                  """Remove""",
                                ),
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
            label: Text(
              uiTextForLanguage(
                'SALVA DATI AVANZATI',
                """SAVE ADVANCED DATA""",
              ),
            ),
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
          label: Text(
            uiTextForLanguage('AGGIUNGI COLLEGAMENTO', """ADD LINK"""),
          ),
        ),
        if (links.isEmpty)
          Text(
            uiTextForLanguage(
              'Nessun collegamento configurato.',
              """No links configured.""",
            ),
          )
        else
          for (final entry in links.indexed)
            Card(
              child: ListTile(
                leading: const Icon(Icons.arrow_forward),
                title: Text(entry.$2.pokemon.name),
                subtitle: Text(_evolutionSummary(entry.$2)),
                trailing: IconButton(
                  tooltip: uiTextForLanguage('Rimuovi', """Remove"""),
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
                title: Text(
                  _selected?.name ??
                      uiTextForLanguage(
                        'Scegli Pokémon o Fakemon',
                        """Choose a Pokémon or Fakemon""",
                      ),
                ),
                subtitle: _selected == null
                    ? null
                    : Text('#${_selected!.pokemonId ?? '-'}'),
                trailing: const Icon(Icons.search),
                onTap: _pickPokemon,
              ),
              TextField(
                controller: _form,
                decoration: InputDecoration(
                  labelText: uiTextForLanguage(
                    'Forma specifica, facoltativa',
                    """Optional specific form""",
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _numberField(
                      _level,
                      uiTextForLanguage('Livello minimo', """Minimum level"""),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _numberField(
                      _loyalty,
                      uiTextForLanguage('Lealtà minima', """Minimum Loyalty"""),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _numberField(
                      _asi,
                      uiTextForLanguage('Punti ASI', 'ASI points'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _item,
                readOnly: true,
                onTap: _pickItem,
                decoration: InputDecoration(
                  labelText: uiTextForLanguage(
                    'Oggetto richiesto',
                    """Required item""",
                  ),
                  helperText: uiTextForLanguage(
                    'Seleziona dal catalogo degli oggetti',
                    """Choose from the item catalog""",
                  ),
                  suffixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _move,
                readOnly: true,
                onTap: _pickMove,
                decoration: InputDecoration(
                  labelText: uiTextForLanguage(
                    'Mossa richiesta',
                    """Required move""",
                  ),
                  helperText: uiTextForLanguage(
                    'Seleziona dal catalogo delle mosse',
                    """Choose from the move catalog""",
                  ),
                  suffixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String?>(
                initialValue: _gender,
                decoration: InputDecoration(
                  labelText: uiTextForLanguage(
                    'Sesso richiesto',
                    """Required gender""",
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(uiTextForLanguage('Nessuno', """None""")),
                  ),
                  DropdownMenuItem(
                    value: 'male',
                    child: Text(uiTextForLanguage('Maschio', """Male""")),
                  ),
                  DropdownMenuItem(
                    value: 'female',
                    child: Text(uiTextForLanguage('Femmina', """Female""")),
                  ),
                  DropdownMenuItem(
                    value: 'genderless',
                    child: Text(
                      uiTextForLanguage('Senza sesso', """Genderless"""),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _gender = value),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _hint,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: uiTextForLanguage(
                    'Indizio evolutivo facoltativo',
                    'Optional evolution hint',
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
          onPressed: _selected == null ? null : _submit,
          child: Text(uiTextForLanguage('AGGIUNGI', """ADD""")),
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
      tooltip: uiTextForLanguage('Pulisci', 'Clear'),
      onPressed: () => query = '',
      icon: const Icon(Icons.clear),
    ),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    tooltip: uiTextForLanguage('Indietro', """Back"""),
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
      tooltip: uiTextForLanguage('Pulisci', 'Clear'),
      onPressed: () => query = '',
      icon: const Icon(Icons.clear),
    ),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    tooltip: uiTextForLanguage('Indietro', """Back"""),
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
      tooltip: uiTextForLanguage('Pulisci', 'Clear'),
      onPressed: () => query = '',
      icon: const Icon(Icons.clear),
    ),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    tooltip: uiTextForLanguage('Indietro', """Back"""),
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
          ? uiTextForLanguage(
              'Scegli artwork shiny',
              """Choose shiny artwork""",
            )
          : uiTextForLanguage(
              'Scegli artwork della forma',
              """Choose form artwork""",
            ),
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
        SnackBar(
          content: Text(
            uiTextForLanguage(
              'Compila tutte le caratteristiche oppure lasciale vuote.',
              'Fill in all ability scores or leave them all blank.',
            ),
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
      appBar: AppBar(
        title: Text(
          uiTextForLanguage('FORMA PERSONALIZZATA', """CUSTOM FORM"""),
        ),
      ),
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
              decoration: InputDecoration(
                labelText: uiTextForLanguage('Nome forma', """Form name"""),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CustomPokemonFormDuration>(
              initialValue: _duration,
              decoration: InputDecoration(
                labelText: uiTextForLanguage('Durata', 'Duration'),
              ),
              items: [
                DropdownMenuItem(
                  value: CustomPokemonFormDuration.permanent,
                  child: Text(uiTextForLanguage('Permanente', """Permanent""")),
                ),
                DropdownMenuItem(
                  value: CustomPokemonFormDuration.battle,
                  child: Text(
                    uiTextForLanguage(
                      'Momentanea, solo battaglia',
                      """Temporary, battle only""",
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _duration = value);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                uiTextForLanguage(
                  'Segreta fino alla prima attivazione',
                  'Secret until first activation',
                ),
              ),
              value: _secret,
              onChanged: (value) => setState(() => _secret = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                uiTextForLanguage(
                  'Registra nel Pokédex',
                  """Register in the Pokédex""",
                ),
              ),
              value: _trackInPokedex,
              onChanged: (value) => setState(() => _trackInPokedex = value),
            ),
            TextField(
              controller: _hint,
              decoration: InputDecoration(
                labelText: uiTextForLanguage(
                  'Indizio / attivazione',
                  'Hint / activation',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _typeDropdown(
                    label: uiTextForLanguage('Tipo principale', 'Primary type'),
                    value: _primaryType,
                    onChanged: (value) => setState(() => _primaryType = value),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _typeDropdown(
                    label: uiTextForLanguage(
                      'Tipo secondario',
                      'Secondary type',
                    ),
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
                Expanded(
                  child: _numberField(
                    _speed,
                    uiTextForLanguage('Velocità', """Speed"""),
                  ),
                ),
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
              decoration: InputDecoration(
                labelText: uiTextForLanguage(
                  'Abilità sostitutive, separate da virgole',
                  """Replacement abilities, comma-separated""",
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hiddenAbility,
              decoration: InputDecoration(
                labelText: uiTextForLanguage(
                  'Abilità nascosta',
                  """Hidden ability""",
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              minLines: 3,
              maxLines: 7,
              decoration: InputDecoration(
                labelText: uiTextForLanguage(
                  'Descrizione forma',
                  """Form description""",
                ),
              ),
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
            label: Text(uiTextForLanguage('SALVA FORMA', """SAVE FORM""")),
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
        DropdownMenuItem(
          value: null,
          child: Text(uiTextForLanguage('Eredita', 'Inherit')),
        ),
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
    labels.insert(
      0,
      uiTextForLanguage(
        'Forma: ${link.pokemon.formName}',
        """Form: ${link.pokemon.formName}""",
      ),
    );
  }
  if (link.asiPoints > 0) labels.add('ASI +${link.asiPoints}');
  if (link.hint != null) labels.add('Indizio: ${link.hint}');
  return labels.isEmpty
      ? uiTextForLanguage('Nessuna condizione', """No conditions""")
      : labels.join(' · ');
}

List<String> _csv(String value) => value
    .split(',')
    .map((entry) => entry.trim())
    .where((entry) => entry.isNotEmpty)
    .toList(growable: false);

String? _nullable(String value) => value.trim().isEmpty ? null : value.trim();

int? _optionalInt(String value) =>
    value.trim().isEmpty ? null : int.tryParse(value.trim());
