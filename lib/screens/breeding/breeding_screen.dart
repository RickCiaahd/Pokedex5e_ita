import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/breeding_candidate.dart';
import '../../models/breeding_egg.dart';
import '../../models/breeding_species_data.dart';
import '../../models/level_progression.dart';
import '../../models/pc_pokemon.dart';
import '../../models/pokemon.dart';
import '../../models/team_slot.dart';
import '../../models/user_profile.dart';
import '../../repositories/breeding_egg_repository.dart';
import '../../repositories/pokemon_pc_repository.dart';
import '../../repositories/pokemon_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/team_repository.dart';
import '../../services/breeding_service.dart';
import '../../services/pokemon_generator_service.dart';
import '../../widgets/navigation/home_leading_button.dart';
import '../../widgets/pokemon/pokemon_asset_image.dart';

class BreedingScreen extends StatefulWidget {
  const BreedingScreen({super.key});

  @override
  State<BreedingScreen> createState() => _BreedingScreenState();
}

class _BreedingScreenState extends State<BreedingScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final PokemonRepository _pokemonRepository = PokemonRepository();
  final TeamRepository _teamRepository = TeamRepository();
  final PokemonPcRepository _pcRepository = PokemonPcRepository();
  final BreedingEggRepository _eggRepository = BreedingEggRepository();
  final BreedingDataService _dataService = BreedingDataService();
  final BreedingService _breedingService = const BreedingService();
  final PokemonGeneratorService _generator = const PokemonGeneratorService();
  final Random _random = Random();
  final TextEditingController _manualRollController = TextEditingController();

  late Future<_BreedingScreenData> _future;
  String? _firstKey;
  String? _secondKey;
  String? _message;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _manualRollController.dispose();
    super.dispose();
  }

  Future<_BreedingScreenData> _load() async {
    final profile = await _profileRepository.getActiveProfile();
    final results = await Future.wait([
      _pokemonRepository.getAllPokemon(),
      _teamRepository.getTeam(profile.id),
      _pcRepository.getPokemon(profile.id),
      _eggRepository.getEggs(profile.id),
      _dataService.load(),
    ]);
    final catalog = results[0] as List<Pokemon>;
    final team = results[1] as List<TeamSlot>;
    final pc = results[2] as List<PcPokemon>;
    final eggs = results[3] as List<BreedingEgg>;
    final speciesData = results[4] as Map<int, BreedingSpeciesData>;
    final byId = {for (final pokemon in catalog) pokemon.id: pokemon};
    final candidates = <BreedingCandidate>[];

    for (final slot in team) {
      final pokemonId = slot.pokemonId;
      if (pokemonId == null) continue;
      final base = byId[pokemonId];
      if (base == null) continue;
      final pokemon = base.resolveVariant(
        formName: slot.formName,
        gender: slot.gender,
      );
      candidates.add(
        BreedingCandidate(
          key: 'team:${slot.slotIndex}',
          pokemonId: pokemonId,
          formName: slot.formName,
          displayName: _displayName(
            nickname: slot.nickname,
            pokemon: pokemon,
            formName: slot.formName,
          ),
          location: 'Squadra ${slot.slotIndex + 1}',
          gender: slot.gender,
          loyalty: slot.loyalty,
          selectedMoves: _knownMoves(
            pokemon: pokemon,
            experience: slot.experience,
            selectedMoves: slot.selectedMoves,
          ),
          abilities: slot.abilities.isEmpty
              ? pokemon.abilities.take(1).toList()
              : slot.abilities,
        ),
      );
    }

    for (final stored in pc) {
      final base = byId[stored.pokemonId];
      if (base == null) continue;
      final pokemon = base.resolveVariant(
        formName: stored.formName,
        gender: stored.gender,
      );
      candidates.add(
        BreedingCandidate(
          key: 'pc:${stored.id}',
          pokemonId: stored.pokemonId,
          formName: stored.formName,
          displayName: _displayName(
            nickname: stored.nickname,
            pokemon: pokemon,
            formName: stored.formName,
          ),
          location: 'PC',
          gender: stored.gender,
          loyalty: stored.loyalty,
          selectedMoves: _knownMoves(
            pokemon: pokemon,
            experience: stored.experience,
            selectedMoves: stored.selectedMoves,
          ),
          abilities: stored.abilities.isEmpty
              ? pokemon.abilities.take(1).toList()
              : stored.abilities,
        ),
      );
    }

    candidates.sort((a, b) => a.displayName.compareTo(b.displayName));
    return _BreedingScreenData(
      profile: profile,
      catalog: catalog,
      catalogById: byId,
      team: team,
      candidates: candidates,
      eggs: eggs,
      speciesData: speciesData,
    );
  }

  Future<void> _reload({String? message}) async {
    if (!mounted) return;
    setState(() {
      _message = message;
      _future = _load();
    });
  }

  BreedingCandidate? _candidateFor(_BreedingScreenData data, String? key) {
    if (key == null) return null;
    for (final candidate in data.candidates) {
      if (candidate.key == key) return candidate;
    }
    return null;
  }

  BreedingCompatibility? _compatibility(_BreedingScreenData data) {
    final first = _candidateFor(data, _firstKey);
    final second = _candidateFor(data, _secondKey);
    if (first == null || second == null) return null;
    return _breedingService.compatibility(
      first: first,
      second: second,
      speciesData: data.speciesData,
      catalog: data.catalogById,
    );
  }

  Future<void> _attemptBreeding(
    _BreedingScreenData data, {
    int? manualRoll,
  }) async {
    final first = _candidateFor(data, _firstKey);
    final second = _candidateFor(data, _secondKey);
    final compatibility = _compatibility(data);
    if (first == null || second == null || compatibility == null) return;
    if (!compatibility.isCompatible) {
      setState(() => _message = compatibility.errors.join(' '));
      return;
    }

    final roll = manualRoll ?? _random.nextInt(20) + 1;
    if (roll < 1 || roll > 20) {
      setState(() => _message = 'Il risultato del d20 deve essere tra 1 e 20.');
      return;
    }
    final modifier = _breedingService.breedingRollModifier(data.profile);
    final dc = _breedingService.successDc(first.loyalty + second.loyalty);
    final total = roll + modifier;
    if (total < dc) {
      setState(() {
        _message =
            'Tentativo fallito: d20 $roll ${_signed(modifier)} = $total contro CD $dc.';
      });
      return;
    }

    try {
      final egg = _breedingService.createEgg(
        first: first,
        second: second,
        compatibility: compatibility,
        catalog: data.catalogById,
        random: _random,
      );
      await _eggRepository.saveEgg(data.profile.id, egg);
      _manualRollController.clear();
      _firstKey = null;
      _secondKey = null;
      await _reload(
        message:
            'Successo: d20 $roll ${_signed(modifier)} = $total contro CD $dc. Uovo creato.',
      );
    } catch (error) {
      setState(() => _message = error.toString());
    }
  }

  Future<void> _advanceEgg(_BreedingScreenData data, BreedingEgg egg) async {
    final result = _breedingService.advanceIncubation(
      egg: egg,
      profile: data.profile,
      random: _random,
    );
    await _eggRepository.saveEgg(data.profile.id, result.egg);
    final baseRoll = result.d100Rolls.join(' / ');
    final incubator = result.incubatorRolls.isEmpty
        ? ''
        : ' + incubatore ${result.incubatorRolls.join(' + ')}';
    await _reload(
      message:
          'Incubazione: d100 $baseRoll$incubator. Contatore ridotto di ${result.reduction}.',
    );
  }

  Future<void> _updateEgg(_BreedingScreenData data, BreedingEgg egg) async {
    await _eggRepository.saveEgg(data.profile.id, egg);
    await _reload();
  }

  Future<void> _deleteEgg(_BreedingScreenData data, BreedingEgg egg) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare l’uovo?'),
        content: const Text(
          'Il progresso di incubazione e i dati del Pokémon contenuto andranno persi.',
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
    if (!mounted || confirmed != true) return;
    await _eggRepository.deleteEgg(data.profile.id, egg.id);
    await _reload(message: 'Uovo eliminato.');
  }

  Future<void> _hatchEgg(_BreedingScreenData data, BreedingEgg egg) async {
    if (!egg.isReady) return;
    final base = data.catalogById[egg.speciesId];
    if (base == null) {
      setState(() => _message = 'La specie dell’uovo non è nel catalogo.');
      return;
    }
    final pokemon = base.resolveVariant(
      formName: egg.formName,
      gender: egg.gender,
    );
    final level = max(1, pokemon.minLevelFound);
    final experience = LevelProgression.thresholdForLevel(level);
    final maxHp = _generator.maxHpFor(
      pokemon: pokemon,
      level: level,
      nature: egg.nature,
    );
    final loyalty = egg.carriedEntireIncubation ? 2 : 1;
    TeamSlot? emptySlot;
    for (final slot in data.team) {
      if (slot.pokemonId == null) {
        emptySlot = slot;
        break;
      }
    }

    if (emptySlot != null) {
      await _teamRepository.updateSlot(
        profileId: data.profile.id,
        updatedSlot: TeamSlot(
          slotIndex: emptySlot.slotIndex,
          pokemonId: egg.speciesId,
          experience: experience,
          currentHp: maxHp,
          selectedMoves: egg.selectedMoves,
          isShiny: egg.isShiny,
          gender: egg.gender,
          formName: egg.formName,
          nature: egg.nature,
          abilities: egg.ability == null ? const [] : [egg.ability!],
          loyalty: loyalty,
        ),
      );
    } else {
      await _pcRepository.depositPokemon(
        profileId: data.profile.id,
        pokemonId: egg.speciesId,
        experience: experience,
        currentHp: maxHp,
        selectedMoves: egg.selectedMoves,
        isShiny: egg.isShiny,
        gender: egg.gender,
        formName: egg.formName,
        nature: egg.nature,
        abilities: egg.ability == null ? const [] : [egg.ability!],
        loyalty: loyalty,
        notes: egg.inheritedMoves.isEmpty
            ? 'Nato da un uovo.'
            : 'Nato da un uovo. Mosse ereditate: ${egg.inheritedMoves.join(', ')}.',
      );
    }
    await _eggRepository.deleteEgg(data.profile.id, egg.id);
    await _reload(
      message:
          '${_displayName(pokemon: pokemon, formName: egg.formName)} si è schiuso ed è stato aggiunto ${emptySlot == null ? 'al PC' : 'alla squadra'} con Lealtà +$loyalty.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const HomeLeadingButton(),
        title: const Text('Allevamento e uova'),
        actions: const [HomeAppBarAction()],
      ),
      body: FutureBuilder<_BreedingScreenData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Errore: ${snapshot.error}'),
              ),
            );
          }
          final data = snapshot.data!;
          final compatibility = _compatibility(data);
          final first = _candidateFor(data, _firstKey);
          final second = _candidateFor(data, _secondKey);
          final modifier = _breedingService.breedingRollModifier(data.profile);
          final dc = first == null || second == null
              ? null
              : _breedingService.successDc(first.loyalty + second.loyalty);

          return RefreshIndicator(
            onRefresh: () => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _RulesCard(
                  profile: data.profile,
                  rollModifier: modifier,
                  incubationAdvantage: _breedingService.hasIncubationAdvantage(
                    data.profile,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'NUOVO TENTATIVO',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Seleziona due Pokémon posseduti. L’app controlla Lealtà, sesso, Ditto e Gruppi Uova.',
                        ),
                        const SizedBox(height: 12),
                        _CandidateDropdown(
                          label: 'Primo genitore',
                          value: _firstKey,
                          candidates: data.candidates,
                          onChanged: (value) => setState(() {
                            _firstKey = value;
                            _message = null;
                          }),
                        ),
                        const SizedBox(height: 10),
                        _CandidateDropdown(
                          label: 'Secondo genitore',
                          value: _secondKey,
                          candidates: data.candidates,
                          onChanged: (value) => setState(() {
                            _secondKey = value;
                            _message = null;
                          }),
                        ),
                        if (compatibility != null) ...[
                          const SizedBox(height: 12),
                          _CompatibilityCard(
                            compatibility: compatibility,
                            resultPokemon: compatibility.childSpeciesId == null
                                ? null
                                : data.catalogById[compatibility
                                      .childSpeciesId!],
                            dc: dc,
                            modifier: modifier,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            FilledButton.icon(
                              onPressed: compatibility?.isCompatible == true
                                  ? () => _attemptBreeding(data)
                                  : null,
                              icon: const Icon(Icons.casino_outlined),
                              label: const Text('TIRA IL D20'),
                            ),
                            SizedBox(
                              width: 145,
                              child: TextField(
                                controller: _manualRollController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Risultato d20',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            OutlinedButton(
                              onPressed: compatibility?.isCompatible == true
                                  ? () {
                                      final roll = int.tryParse(
                                        _manualRollController.text.trim(),
                                      );
                                      if (roll == null) {
                                        setState(() {
                                          _message =
                                              'Inserisci il risultato del d20.';
                                        });
                                        return;
                                      }
                                      _attemptBreeding(data, manualRoll: roll);
                                    }
                                  : null,
                              child: const Text('USA IL TIRO'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(_message!),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  'UOVA IN INCUBAZIONE (${data.eggs.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ogni uovo occupa un Pokéslot secondo il manuale. Il limite resta sotto il controllo del tavolo.',
                ),
                const SizedBox(height: 8),
                if (data.eggs.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Non ci sono uova. Completa con successo un tentativo di allevamento.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  for (final egg in data.eggs) ...[
                    _EggCard(
                      egg: egg,
                      pokemon: data.catalogById[egg.speciesId],
                      incubationAdvantage: _breedingService
                          .hasIncubationAdvantage(data.profile),
                      onAdvance: () => _advanceEgg(data, egg),
                      onHatch: () => _hatchEgg(data, egg),
                      onDelete: () => _deleteEgg(data, egg),
                      onIncubatorChanged: (incubator) =>
                          _updateEgg(data, egg.copyWith(incubator: incubator)),
                      onCarriedChanged: (value) => _updateEgg(
                        data,
                        egg.copyWith(carriedEntireIncubation: value),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }

  List<String> _knownMoves({
    required Pokemon pokemon,
    required int experience,
    required List<String> selectedMoves,
  }) {
    if (selectedMoves.isNotEmpty) return selectedMoves.take(4).toList();
    final level = LevelProgression.levelFromExperience(experience);
    final moves = <String>[...pokemon.moves.startingMoves];
    final learned =
        pokemon.moves.levelMoves.entries
            .where((entry) => entry.key <= level)
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));
    for (final entry in learned) {
      moves.addAll(entry.value);
    }
    return moves.toSet().take(4).toList();
  }

  String _displayName({
    String? nickname,
    required Pokemon pokemon,
    String? formName,
  }) {
    final trimmed = nickname?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;
    final form = formName?.trim() ?? '';
    return form.isEmpty ? pokemon.name : '${pokemon.name} ($form)';
  }

  String _signed(int value) => value >= 0 ? '+$value' : '$value';
}

class _RulesCard extends StatelessWidget {
  const _RulesCard({
    required this.profile,
    required this.rollModifier,
    required this.incubationAdvantage,
  });

  final UserProfile profile;
  final int rollModifier;
  final bool incubationAdvantage;

  @override
  Widget build(BuildContext context) {
    final breeder = profile.trainerPath == 'Pokémon Breeder';
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ALLEVAMENTO POKÉMON',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Servono Lealtà +2, sesso compatibile e un Gruppo Uova condiviso. Ditto ignora sesso e Gruppo Uova; Undiscovered non può riprodursi.',
            ),
            if (breeder || rollModifier != 0 || incubationAdvantage) ...[
              const SizedBox(height: 10),
              Text(
                'Pokémon Breeder: tiro di accoppiamento ${rollModifier >= 0 ? '+' : ''}$rollModifier${incubationAdvantage ? ' · vantaggio ai d100 di incubazione' : ''}.',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CandidateDropdown extends StatelessWidget {
  const _CandidateDropdown({
    required this.label,
    required this.value,
    required this.candidates,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<BreedingCandidate> candidates;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: candidates.any((candidate) => candidate.key == value)
          ? value
          : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final candidate in candidates)
          DropdownMenuItem(
            value: candidate.key,
            child: Text(
              '${candidate.displayName} · ${candidate.genderLabel} · Lealtà ${candidate.loyalty >= 0 ? '+' : ''}${candidate.loyalty} · ${candidate.location}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _CompatibilityCard extends StatelessWidget {
  const _CompatibilityCard({
    required this.compatibility,
    required this.resultPokemon,
    required this.dc,
    required this.modifier,
  });

  final BreedingCompatibility compatibility;
  final Pokemon? resultPokemon;
  final int? dc;
  final int modifier;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final compatible = compatibility.isCompatible;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: compatible ? colors.primaryContainer : colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              compatible ? 'COMPATIBILI' : 'NON COMPATIBILI',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            if (compatible) ...[
              Text(
                'Gruppo: ${compatibility.sharedEggGroups.join(', ')} · Risultato: ${resultPokemon?.name ?? '#${compatibility.childSpeciesId}'}',
              ),
              if (dc != null)
                Text(
                  'Prova: d20 ${modifier >= 0 ? '+' : ''}$modifier contro CD $dc.',
                ),
            ] else
              for (final error in compatibility.errors) Text('• $error'),
          ],
        ),
      ),
    );
  }
}

class _EggCard extends StatelessWidget {
  const _EggCard({
    required this.egg,
    required this.pokemon,
    required this.incubationAdvantage,
    required this.onAdvance,
    required this.onHatch,
    required this.onDelete,
    required this.onIncubatorChanged,
    required this.onCarriedChanged,
  });

  final BreedingEgg egg;
  final Pokemon? pokemon;
  final bool incubationAdvantage;
  final VoidCallback onAdvance;
  final VoidCallback onHatch;
  final VoidCallback onDelete;
  final ValueChanged<EggIncubator> onIncubatorChanged;
  final ValueChanged<bool> onCarriedChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (pokemon != null)
                  PokemonAssetImage(
                    pokemon: pokemon!,
                    formName: egg.formName,
                    size: 64,
                  )
                else
                  const SizedBox(
                    width: 64,
                    height: 64,
                    child: Icon(Icons.egg_outlined, size: 48),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        egg.isReady
                            ? 'Uovo pronto a schiudersi'
                            : 'Uovo di ${pokemon?.name ?? '#${egg.speciesId}'}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text('Genitori: ${egg.parentNames.join(' + ')}'),
                      Text(
                        egg.isReady
                            ? 'Incubazione completata'
                            : '${egg.incubationRemaining}/${egg.hatchTime} punti rimanenti',
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Elimina uovo',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: egg.progress, minHeight: 8),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(egg.nature)),
                if (egg.gender != null) Chip(label: Text(egg.gender!)),
                if (egg.ability != null) Chip(label: Text(egg.ability!)),
              ],
            ),
            if (egg.inheritedMoves.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Mosse ereditate: ${egg.inheritedMoves.join(', ')}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
            const SizedBox(height: 10),
            DropdownButtonFormField<EggIncubator>(
              value: egg.incubator,
              decoration: const InputDecoration(
                labelText: 'Incubatore',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                for (final incubator in EggIncubator.values)
                  DropdownMenuItem(
                    value: incubator,
                    child: Text(
                      incubator.extraD20 == 0
                          ? incubator.label
                          : '${incubator.label} (+${incubator.extraD20}d20)',
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value != null) onIncubatorChanged(value);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Trasportato per tutta l’incubazione'),
              subtitle: const Text(
                'Attivo: nascerà con Lealtà +2. Disattivo: Lealtà +1.',
              ),
              value: egg.carriedEntireIncubation,
              onChanged: onCarriedChanged,
            ),
            const SizedBox(height: 4),
            if (egg.isReady)
              FilledButton.icon(
                onPressed: onHatch,
                icon: const Icon(Icons.egg_alt_outlined),
                label: const Text('FAI SCHIUDERE'),
              )
            else
              FilledButton.icon(
                onPressed: onAdvance,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  incubationAdvantage
                      ? 'AVANZA INCUBAZIONE (2d100, migliore)'
                      : 'AVANZA INCUBAZIONE (1d100)',
                ),
              ),
            if (egg.isReady) ...[
              const SizedBox(height: 6),
              Text(
                'Lo spazio libero in squadra viene usato per primo; altrimenti il Pokémon va nel PC.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BreedingScreenData {
  const _BreedingScreenData({
    required this.profile,
    required this.catalog,
    required this.catalogById,
    required this.team,
    required this.candidates,
    required this.eggs,
    required this.speciesData,
  });

  final UserProfile profile;
  final List<Pokemon> catalog;
  final Map<int, Pokemon> catalogById;
  final List<TeamSlot> team;
  final List<BreedingCandidate> candidates;
  final List<BreedingEgg> eggs;
  final Map<int, BreedingSpeciesData> speciesData;
}
