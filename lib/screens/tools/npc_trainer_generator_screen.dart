import 'package:flutter/material.dart';

import '../../models/bag_item.dart';
import '../../models/generated_npc_trainer.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_type_localization.dart';
import '../../models/trainer_manual_content.dart';
import '../../models/trainer_manual_options.dart';
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
        _error = error.toString();
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
          _error =
              'Nessuna squadra completa rispetta i parametri scelti. Amplia le generazioni, consenti duplicati oppure cambia composizione.';
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
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  String get _specializationSummary {
    if (_specialization == _randomSpecialization) {
      return 'L’app sceglierà casualmente una specializzazione e il relativo tipo preferito.';
    }
    final type = _generatorService.preferredTypeFor(_specialization);
    return 'Tipo preferito: ${PokemonTypeLocalization.italianLabel(type)}.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const HomeLeadingButton(),
        title: const Text('Allenatore PNG'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  _IntroCard(catalogSize: _catalog.length),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'IDENTITÀ E GRADO',
                    children: [
                      DropdownButtonFormField<NpcTrainerRank>(
                        key: ValueKey(_rank),
                        initialValue: _rank,
                        decoration: const InputDecoration(
                          labelText: 'Grado dell’allenatore',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final rank in NpcTrainerRank.values)
                            DropdownMenuItem(
                              value: rank,
                              child: Text(rank.label),
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
                      Text(_rank.description),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        key: ValueKey(_specialization),
                        initialValue: _specialization,
                        decoration: const InputDecoration(
                          labelText: 'Specializzazione principale',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: _randomSpecialization,
                            child: Text('Casuale'),
                          ),
                          for (final specialization in _specializations)
                            DropdownMenuItem(
                              value: specialization,
                              child: Text(specialization),
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
                    title: 'LIVELLI E SQUADRA',
                    children: [
                      _NumberSlider(
                        label: 'Livello allenatore',
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
                        label: 'Livello dei Pokémon',
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
                        label: 'Pokémon in squadra',
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
                        key: ValueKey(_composition),
                        initialValue: _composition,
                        decoration: const InputDecoration(
                          labelText: 'Composizione della squadra',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final composition in NpcTeamComposition.values)
                            DropdownMenuItem(
                              value: composition,
                              child: Text(composition.label),
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
                      Text(_composition.description),
                      const SizedBox(height: 8),
                      Text(
                        'SR massimo controllabile: ${_generatorService.maxSrFor(_options).toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'CATALOGO E VARIANTI',
                    children: [
                      Text(
                        'Generazioni ${_generationRange.start.round()}–${_generationRange.end.round()}',
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
                        title: const Text('Forme permanenti'),
                        subtitle: const Text(
                          'Consente forme regionali e altre varianti permanenti.',
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
                        title: const Text('Leggendari e misteriosi'),
                        subtitle: const Text(
                          'Da attivare soltanto per PNG o boss eccezionali.',
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
                        title: const Text('Specie duplicate'),
                        subtitle: const Text(
                          'Permette più esemplari della stessa specie nella squadra.',
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
                          ? 'GENERAZIONE...'
                          : 'GENERA ALLENATORE PNG',
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
                    'Generatore di Allenatori PNG',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Crea identità, personalità, tattiche, ricompense e una squadra completa da $catalogSize specie disponibili.',
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
