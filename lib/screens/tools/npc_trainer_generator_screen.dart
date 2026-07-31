import 'package:flutter/material.dart';

import '../../localization/ui_text.dart';
import '../../localization/user_facing_error.dart';

import '../../models/bag_item.dart';
import '../../models/generated_npc_trainer.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_type_localization.dart';
import '../../models/trainer_manual_content.dart';
import '../../models/trainer_manual_options.dart';
import '../../models/trainer_ui_localization.dart';
import '../../repositories/item_repository.dart';
import '../../repositories/pokemon_repository.dart';
import '../../repositories/trainer_manual_repository.dart';
import '../../services/npc_trainer_generator_service.dart';
import '../../widgets/navigation/home_leading_button.dart';
import 'npc_trainer_result_screen.dart';

class NpcTrainerGeneratorScreen extends StatefulWidget {
  const NpcTrainerGeneratorScreen({super.key});

  @override
  State<NpcTrainerGeneratorScreen> createState() =>
      _NpcTrainerGeneratorScreenState();
}

class _NpcTrainerGeneratorScreenState extends State<NpcTrainerGeneratorScreen> {
  static const String _randomSpecialization = '__random__';

  final PokemonRepository _pokemonRepository = PokemonRepository();
  final TrainerManualRepository _trainerManualRepository =
      TrainerManualRepository();
  final ItemRepository _itemRepository = ItemRepository();
  final NpcTrainerGeneratorService _generatorService =
      const NpcTrainerGeneratorService();

  List<Pokemon> _catalog = const [];
  List<TrainerOrigin> _origins = const [];
  List<TrainerPath> _paths = const [];
  List<BagItem> _items = const [];
  List<String> _specializations = const [];

  int _trainerLevel = 5;
  int _pokemonLevel = 5;
  int _teamSize = 3;
  NpcTrainerRank _rank = NpcTrainerRank.common;
  NpcTeamComposition _composition = NpcTeamComposition.mixed;
  String _specialization = _randomSpecialization;
  RangeValues _generationRange = const RangeValues(1, 9);
  bool _includeForms = true;
  bool _allowLegendary = false;
  bool _allowDuplicates = false;
  bool _isLoading = true;
  bool _isGenerating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final catalog = await _pokemonRepository.getAllPokemon();
      final origins = await _trainerManualRepository.getOrigins();
      final paths = await _trainerManualRepository.getTrainerPaths();
      List<BagItem> items = const [];
      try {
        items = await _itemRepository.getWebItems();
      } catch (_) {
        items = const [];
      }
      final specializations = [...TrainerManualOptions.specializations]..sort();
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _origins = origins;
        _paths = paths;
        _items = items;
        _specializations = specializations;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = context.userFacingError(
          error,
          action: UserFacingErrorAction.load,
        );
        _isLoading = false;
      });
    }
  }

  NpcTrainerGeneratorOptions get _options => NpcTrainerGeneratorOptions(
    trainerLevel: _trainerLevel,
    pokemonLevel: _pokemonLevel,
    teamSize: _teamSize,
    rank: _rank,
    specialization: _specialization == _randomSpecialization
        ? null
        : _specialization,
    composition: _composition,
    minGeneration: _generationRange.start.round(),
    maxGeneration: _generationRange.end.round(),
    includeForms: _includeForms,
    allowLegendary: _allowLegendary,
    allowDuplicates: _allowDuplicates,
  );

  Future<void> _generate() async {
    if (_isGenerating || _catalog.isEmpty) return;
    setState(() {
      _isGenerating = true;
      _error = null;
    });
    try {
      final trainer = _generatorService.generate(
        catalog: _catalog,
        options: _options,
        specializations: _specializations,
        origins: _origins,
        paths: _paths,
        items: _items,
      );
      if (trainer == null) {
        setState(() {
          _error = context.uiText(
            'Nessuna squadra completa rispetta i parametri scelti. Amplia le generazioni, consenti duplicati oppure cambia composizione.',
            'No complete team matches the selected parameters. Widen the generation range, allow duplicates or change the composition.',
          );
        });
        return;
      }
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => NpcTrainerResultScreen(
            trainer: trainer,
            catalog: _catalog,
            origins: _origins,
            paths: _paths,
            specializations: _specializations,
            items: _items,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = context.userFacingError(error));
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  List<String> get _localizedSpecializations {
    final values = [..._specializations];
    values.sort(
      (a, b) => TrainerUiLocalization.specializationName(
        a,
      ).compareTo(TrainerUiLocalization.specializationName(b)),
    );
    return values;
  }

  String get _specializationSummary {
    if (_specialization == _randomSpecialization) {
      return context.uiText(
        'L’app sceglierà casualmente una specializzazione e il relativo tipo preferito.',
        'The app will randomly choose a specialization and its preferred type.',
      );
    }
    final type = _generatorService.preferredTypeFor(_specialization);
    final typeLabel = context.usesItalianUi
        ? PokemonTypeLocalization.italianLabel(type)
        : PokemonTypeLocalization.englishValue(type);
    return context.uiText(
      'Tipo preferito: $typeLabel.',
      'Preferred type: $typeLabel.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const HomeLeadingButton(),
        title: Text(context.uiText('Allenatore PNG', 'NPC Trainer')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  32.0 + MediaQuery.viewPaddingOf(context).bottom,
                ),
                children: [
                  _IntroCard(catalogSize: _catalog.length),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: context.uiText(
                      'IDENTITÀ E GRADO',
                      'IDENTITY AND RANK',
                    ),
                    children: [
                      DropdownButtonFormField<NpcTrainerRank>(
                        isExpanded: true,
                        key: ValueKey(_rank),
                        initialValue: _rank,
                        decoration: InputDecoration(
                          labelText: context.uiText(
                            'Grado dell’allenatore',
                            'Trainer rank',
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          for (final rank in NpcTrainerRank.values)
                            DropdownMenuItem(
                              value: rank,
                              child: Text(
                                context.uiText(rank.label, rank.englishLabel),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _rank = value;
                            _error = null;
                          });
                        },
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.uiText(
                          _rank.description,
                          _rank.englishDescription,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        key: ValueKey(_specialization),
                        initialValue: _specialization,
                        decoration: InputDecoration(
                          labelText: context.uiText(
                            'Specializzazione principale',
                            'Primary specialization',
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: _randomSpecialization,
                            child: Text(
                              context.uiText('Casuale', 'Random'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          for (final specialization in
                              _localizedSpecializations)
                            DropdownMenuItem(
                              value: specialization,
                              child: Text(
                                TrainerUiLocalization.specializationName(
                                  specialization,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _specialization = value;
                            _error = null;
                          });
                        },
                      ),
                      const SizedBox(height: 6),
                      Text(_specializationSummary),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: context.uiText(
                      'LIVELLI E SQUADRA',
                      'LEVELS AND TEAM',
                    ),
                    children: [
                      _NumberSlider(
                        label: context.uiText(
                          'Livello allenatore',
                          'Trainer level',
                        ),
                        value: _trainerLevel,
                        min: 1,
                        max: 20,
                        onChanged: (value) {
                          setState(() {
                            _trainerLevel = value;
                            _error = null;
                          });
                        },
                      ),
                      _NumberSlider(
                        label: context.uiText(
                          'Livello dei Pokémon',
                          'Pokémon level',
                        ),
                        value: _pokemonLevel,
                        min: 1,
                        max: 20,
                        onChanged: (value) {
                          setState(() {
                            _pokemonLevel = value;
                            _error = null;
                          });
                        },
                      ),
                      _NumberSlider(
                        label: context.uiText(
                          'Pokémon in squadra',
                          'Pokémon on team',
                        ),
                        value: _teamSize,
                        min: 1,
                        max: 6,
                        onChanged: (value) {
                          setState(() {
                            _teamSize = value;
                            _error = null;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<NpcTeamComposition>(
                        isExpanded: true,
                        key: ValueKey(_composition),
                        initialValue: _composition,
                        decoration: InputDecoration(
                          labelText: context.uiText(
                            'Composizione della squadra',
                            'Team composition',
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          for (final composition in NpcTeamComposition.values)
                            DropdownMenuItem(
                              value: composition,
                              child: Text(
                                context.uiText(
                                  composition.label,
                                  composition.englishLabel,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _composition = value;
                            _error = null;
                          });
                        },
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.uiText(
                          _composition.description,
                          _composition.englishDescription,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.uiText(
                          'SR massimo controllabile: ${_generatorService.maxSrFor(_options).toStringAsFixed(0)}',
                          'Maximum controllable SR: ${_generatorService.maxSrFor(_options).toStringAsFixed(0)}',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: context.uiText(
                      'CATALOGO E VARIANTI',
                      'CATALOG AND VARIANTS',
                    ),
                    children: [
                      Text(
                        context.uiText(
                          'Generazioni ${_generationRange.start.round()}–${_generationRange.end.round()}',
                          'Generations ${_generationRange.start.round()}–${_generationRange.end.round()}',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      RangeSlider(
                        values: _generationRange,
                        min: 1,
                        max: 9,
                        divisions: 8,
                        labels: RangeLabels(
                          '${_generationRange.start.round()}',
                          '${_generationRange.end.round()}',
                        ),
                        onChanged: (values) {
                          setState(() {
                            _generationRange = RangeValues(
                              values.start.roundToDouble(),
                              values.end.roundToDouble(),
                            );
                            _error = null;
                          });
                        },
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          context.uiText('Forme permanenti', 'Permanent forms'),
                        ),
                        subtitle: Text(
                          context.uiText(
                            'Consente forme regionali e altre varianti permanenti.',
                            'Allows regional forms and other permanent variants.',
                          ),
                        ),
                        value: _includeForms,
                        onChanged: (value) {
                          setState(() {
                            _includeForms = value;
                            _error = null;
                          });
                        },
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          context.uiText(
                            'Leggendari e misteriosi',
                            'Legendary and Mythical Pokémon',
                          ),
                        ),
                        subtitle: Text(
                          context.uiText(
                            'Da attivare soltanto per PNG o boss eccezionali.',
                            'Enable only for exceptional NPCs or bosses.',
                          ),
                        ),
                        value: _allowLegendary,
                        onChanged: (value) {
                          setState(() {
                            _allowLegendary = value;
                            _error = null;
                          });
                        },
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          context.uiText(
                            'Specie duplicate',
                            'Duplicate species',
                          ),
                        ),
                        subtitle: Text(
                          context.uiText(
                            'Permette più esemplari della stessa specie nella squadra.',
                            'Allows multiple members of the same species on the team.',
                          ),
                        ),
                        value: _allowDuplicates,
                        onChanged: (value) {
                          setState(() {
                            _allowDuplicates = value;
                            _error = null;
                          });
                        },
                      ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _isGenerating ? null : _generate,
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.groups_2_outlined),
                    label: Text(
                      _isGenerating
                          ? context.uiText('GENERAZIONE...', 'GENERATING...')
                          : context.uiText(
                              'GENERA ALLENATORE PNG',
                              'GENERATE NPC TRAINER',
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.catalogSize});

  final int catalogSize;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.groups_2_outlined,
              size: 38,
              color: colors.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.uiText(
                      'Generatore di Allenatori PNG',
                      'NPC Trainer Generator',
                    ),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.uiText(
                      'Crea identità, personalità, tattiche, ricompense e una squadra completa da $catalogSize specie disponibili.',
                      'Create an identity, personality, tactics, rewards and a full team from $catalogSize available species.',
                    ),
                    style: TextStyle(color: colors.onPrimaryContainer),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _NumberSlider extends StatelessWidget {
  const _NumberSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '$value',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          label: '$value',
          onChanged: (next) => onChanged(next.round()),
        ),
      ],
    );
  }
}
