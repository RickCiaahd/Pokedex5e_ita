import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/breeding_candidate.dart';
import '../../models/breeding_egg.dart';
import '../../models/breeding_species_data.dart';
import '../../models/level_progression.dart';
import '../../models/pc_pokemon.dart';
import '../../models/trainer_progression.dart';
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
import '../../widgets/pokemon/egg_asset_image.dart';

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
  bool _useDayCare = false;

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
    var team = results[1] as List<TeamSlot>;
    var pc = results[2] as List<PcPokemon>;
    var eggs = results[3] as List<BreedingEgg>;
    final unlockedPokeslots = TrainerProgression.pokeslotsForLevel(
      profile.trainerLevel,
    );

    final occupiedLockedSlots = _breedingService.occupiedLockedTeamSlots(
      team: team,
      unlockedPokeslots: unlockedPokeslots,
    );
    for (final slot in occupiedLockedSlots) {
      await _pcRepository.depositTeamSlot(profileId: profile.id, slot: slot);
      await _teamRepository.clearSlot(
        profileId: profile.id,
        slotIndex: slot.slotIndex,
      );
    }
    if (occupiedLockedSlots.isNotEmpty) {
      team = await _teamRepository.getTeam(profile.id);
      pc = await _pcRepository.getPokemon(profile.id);
    }

    var eggStorageChanged = false;
    var eggsById = {for (final egg in eggs) egg.id: egg};
    for (final slot in [...team]) {
      final eggId = slot.eggId;
      if (eggId == null) continue;
      final egg = eggsById[eggId];
      if (egg == null) {
        await _teamRepository.clearSlot(
          profileId: profile.id,
          slotIndex: slot.slotIndex,
        );
        eggStorageChanged = true;
        continue;
      }
      if (
          slot.slotIndex >= unlockedPokeslots ||
          egg.isInDayCare ||
          egg.isInPc
      ) {
        await _teamRepository.clearSlot(
          profileId: profile.id,
          slotIndex: slot.slotIndex,
        );
        if (!egg.isInDayCare && !egg.isInPc) {
          await _eggRepository.saveEgg(
            profile.id,
            egg.copyWith(
              isInDayCare: true,
              isInPc: false,
              carriedEntireIncubation: false,
            ),
          );
        }
        eggStorageChanged = true;
      }
    }
    if (eggStorageChanged) {
      team = await _teamRepository.getTeam(profile.id);
      eggs = await _eggRepository.getEggs(profile.id);
      eggsById = {for (final egg in eggs) egg.id: egg};
    }

    for (final egg in [...eggs]) {
      if (egg.isInDayCare || egg.isInPc) continue;
      final assigned = _breedingService.teamSlotForEgg(
        team: team,
        eggId: egg.id,
      );
      if (assigned != null) continue;
      final freeSlot = _breedingService.firstFreeUnlockedTeamSlot(
        team: team,
        unlockedPokeslots: unlockedPokeslots,
      );
      if (freeSlot == null) {
        await _eggRepository.saveEgg(
          profile.id,
          egg.copyWith(
        isInDayCare: true,
        isInPc: false,
        carriedEntireIncubation: false,
      ),
        );
      } else {
        await _teamRepository.setEggInSlot(
          profileId: profile.id,
          slotIndex: freeSlot.slotIndex,
          eggId: egg.id,
        );
      }
      eggStorageChanged = true;
      team = await _teamRepository.getTeam(profile.id);
    }
    if (eggStorageChanged) {
      eggs = await _eggRepository.getEggs(profile.id);
    }

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

    final unlockedPokeslots = TrainerProgression.pokeslotsForLevel(
      data.profile.trainerLevel,
    );
    final freeSlot = _breedingService.firstFreeUnlockedTeamSlot(
      team: data.team,
      unlockedPokeslots: unlockedPokeslots,
    );
    if (!_useDayCare && freeSlot == null) {
      setState(() {
        _message =
            'Non hai un Pokéslot libero. Libera uno slot oppure usa la Pensione Pokémon.';
      });
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
      final created = _breedingService.createEgg(
        first: first,
        second: second,
        compatibility: compatibility,
        catalog: data.catalogById,
        random: _random,
      );
      final egg = created.copyWith(
        isInDayCare: _useDayCare,
        isInPc: false,
        carriedEntireIncubation: !_useDayCare,
      );
      await _eggRepository.saveEgg(data.profile.id, egg);
      if (!_useDayCare && freeSlot != null) {
        await _teamRepository.setEggInSlot(
          profileId: data.profile.id,
          slotIndex: freeSlot.slotIndex,
          eggId: egg.id,
        );
      }
      final destination = _useDayCare
          ? 'affidato alla Pensione Pokémon'
          : 'inserito nello slot squadra ${freeSlot!.slotIndex + 1}';
      _manualRollController.clear();
      _firstKey = null;
      _secondKey = null;
      _useDayCare = false;
      await _reload(
        message:
            'Successo: d20 $roll ${_signed(modifier)} = $total contro CD $dc. Uovo creato e $destination.',
      );
    } catch (error) {
      setState(() => _message = error.toString());
    }
  }

  TeamSlot? _teamSlotForEgg(_BreedingScreenData data, BreedingEgg egg) {
    return _breedingService.teamSlotForEgg(team: data.team, eggId: egg.id);
  }

  Future<void> _moveEggToDayCare(
    _BreedingScreenData data,
    BreedingEgg egg,
  ) async {
    final slot = _teamSlotForEgg(data, egg);
    if (slot != null) {
      await _teamRepository.clearSlot(
        profileId: data.profile.id,
        slotIndex: slot.slotIndex,
      );
    }
    await _eggRepository.saveEgg(
      data.profile.id,
      egg.copyWith(
        isInDayCare: true,
        isInPc: false,
        carriedEntireIncubation: false,
      ),
    );
    await _reload(message: 'Uovo affidato alla Pensione Pokémon.');
  }

  Future<void> _moveEggToPc(
    _BreedingScreenData data,
    BreedingEgg egg,
  ) async {
    final slot = _teamSlotForEgg(data, egg);
    if (slot != null) {
      await _teamRepository.clearSlot(
        profileId: data.profile.id,
        slotIndex: slot.slotIndex,
      );
    }
    await _eggRepository.saveEgg(
      data.profile.id,
      egg.copyWith(
        isInDayCare: false,
        isInPc: true,
        carriedEntireIncubation: false,
      ),
    );
    await _reload(
      message: 'Uovo depositato nel PC. L’incubazione resta in pausa.',
    );
  }

  Future<void> _moveEggToTeam(_BreedingScreenData data, BreedingEgg egg) async {
    final unlockedPokeslots = TrainerProgression.pokeslotsForLevel(
      data.profile.trainerLevel,
    );
    final freeSlot = _breedingService.firstFreeUnlockedTeamSlot(
      team: data.team,
      unlockedPokeslots: unlockedPokeslots,
    );
    if (freeSlot == null) {
      setState(
        () => _message = 'Non hai un Pokéslot libero per ritirare l’uovo.',
      );
      return;
    }
    await _teamRepository.setEggInSlot(
      profileId: data.profile.id,
      slotIndex: freeSlot.slotIndex,
      eggId: egg.id,
    );
    await _eggRepository.saveEgg(
      data.profile.id,
      egg.copyWith(isInDayCare: false, isInPc: false),
    );
    await _reload(
      message: 'Uovo ritirato nello slot squadra ${freeSlot.slotIndex + 1}.',
    );
  }

  Future<void> _advanceEgg(_BreedingScreenData data, BreedingEgg egg) async {
    if (egg.isInPc) {
      setState(() {
        _message =
            'Nel PC l’incubazione è in pausa. Ritira l’uovo in squadra oppure affidalo alla Pensione.';
      });
      return;
    }
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
    final slot = _teamSlotForEgg(data, egg);
    if (slot != null) {
      await _teamRepository.clearSlot(
        profileId: data.profile.id,
        slotIndex: slot.slotIndex,
      );
    }
    await _eggRepository.deleteEgg(data.profile.id, egg.id);
    await _reload(message: 'Uovo eliminato.');
  }

  Future<void> _hatchEgg(_BreedingScreenData data, BreedingEgg egg) async {
    if (!egg.isReady) return;
    if (egg.isInPc) {
      setState(() {
        _message =
            'Un uovo depositato nel PC non può schiudersi. Ritiralo in squadra oppure spostalo in Pensione.';
      });
      return;
    }
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
    final eggSlot = _teamSlotForEgg(data, egg);

    if (eggSlot != null) {
      await _teamRepository.updateSlot(
        profileId: data.profile.id,
        updatedSlot: TeamSlot(
          slotIndex: eggSlot.slotIndex,
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
            ? 'Nato da un uovo nella Pensione Pokémon.'
            : 'Nato da un uovo nella Pensione Pokémon. Mosse ereditate: ${egg.inheritedMoves.join(', ')}.',
      );
    }
    await _eggRepository.deleteEgg(data.profile.id, egg.id);
    final destination = eggSlot == null
        ? 'è stato inviato al PC dalla Pensione Pokémon'
        : 'ha sostituito l’uovo nello slot squadra ${eggSlot.slotIndex + 1}';
    await _reload(
      message:
          '${_displayName(pokemon: pokemon, formName: egg.formName)} si è schiuso, $destination, con Lealtà +$loyalty.',
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
          final unlockedPokeslots = TrainerProgression.pokeslotsForLevel(
            data.profile.trainerLevel,
          );
          final freeSlot = _breedingService.firstFreeUnlockedTeamSlot(
            team: data.team,
            unlockedPokeslots: unlockedPokeslots,
          );
          final canStoreEgg = _useDayCare || freeSlot != null;

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
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Usa Pensione Pokémon'),
                          subtitle: Text(
                            _useDayCare
                                ? 'L’uovo non occupa un Pokéslot e alla schiusa il Pokémon andrà nel PC.'
                                : freeSlot == null
                                ? 'Nessun Pokéslot libero: attiva la Pensione per poter ottenere l’uovo.'
                                : 'L’uovo occuperà lo slot squadra ${freeSlot.slotIndex + 1}.',
                          ),
                          value: _useDayCare,
                          onChanged: (value) => setState(() {
                            _useDayCare = value;
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
                              onPressed:
                                  compatibility?.isCompatible == true &&
                                      canStoreEgg
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
                              onPressed:
                                  compatibility?.isCompatible == true &&
                                      canStoreEgg
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
                  'Un uovo trasportato occupa davvero un Pokéslot. Un uovo affidato alla Pensione resta fuori dalla squadra e alla schiusa il Pokémon viene inviato al PC.',
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
                      teamSlotIndex: _teamSlotForEgg(data, egg)?.slotIndex,
                      canMoveToTeam: freeSlot != null,
                      onDelete: () => _deleteEgg(data, egg),
                      onIncubatorChanged: (incubator) =>
                          _updateEgg(data, egg.copyWith(incubator: incubator)),
                      onMoveToDayCare: () => _moveEggToDayCare(data, egg),
                       onMoveToPc: () => _moveEggToPc(data, egg),
                      onMoveToTeam: () => _moveEggToTeam(data, egg),
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
    required this.teamSlotIndex,
    required this.canMoveToTeam,
    required this.onDelete,
    required this.onIncubatorChanged,
    required this.onMoveToDayCare,
    required this.onMoveToPc,
    required this.onMoveToTeam,
  });

  final BreedingEgg egg;
  final Pokemon? pokemon;
  final bool incubationAdvantage;
  final VoidCallback onAdvance;
  final VoidCallback onHatch;
  final int? teamSlotIndex;
  final bool canMoveToTeam;
  final VoidCallback onDelete;
  final ValueChanged<EggIncubator> onIncubatorChanged;
  final VoidCallback onMoveToDayCare;
  final VoidCallback onMoveToPc;
  final VoidCallback onMoveToTeam;

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
                const EggAssetImage(size: 54),
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
            Card(
              margin: EdgeInsets.zero,
              color: colors.surfaceContainerHighest,
              child: ListTile(
                leading: Icon(
                  egg.isInPc
                      ? Icons.computer_outlined
                      : teamSlotIndex == null
                      ? Icons.home_work_outlined
                      : Icons.group_outlined,
                ),
                title: Text(
                  egg.isInPc
                      ? 'PC Pokémon'
                      : teamSlotIndex == null
                      ? 'Pensione Pokémon'
                      : 'Squadra · Slot ${teamSlotIndex! + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  egg.isInPc
                      ? 'L’incubazione è in pausa e l’uovo non occupa un Pokéslot.'
                      : egg.carriedEntireIncubation
                      ? 'Occupa un Pokéslot e nascerà con Lealtà +2.'
                      : 'Non ha trascorso tutta l’incubazione in squadra: Lealtà +1.',
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (teamSlotIndex == null)
                  OutlinedButton.icon(
                    onPressed: canMoveToTeam ? onMoveToTeam : null,
                    icon: const Icon(Icons.login),
                    label: Text(
                      canMoveToTeam
                          ? 'RITIRA IN SQUADRA'
                          : 'NESSUN POKÉSLOT LIBERO',
                    ),
                  ),
                if (teamSlotIndex != null || egg.isInDayCare)
                  OutlinedButton.icon(
                    onPressed: onMoveToPc,
                    icon: const Icon(Icons.computer_outlined),
                    label: const Text('DEPOSITA NEL PC'),
                  ),
                if (teamSlotIndex != null || egg.isInPc)
                  OutlinedButton.icon(
                    onPressed: onMoveToDayCare,
                    icon: const Icon(Icons.home_work_outlined),
                    label: const Text('SPOSTA IN PENSIONE'),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            if (egg.isInPc)
              FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.pause_circle_outline),
                label: Text(
                  egg.isReady
                      ? 'RITIRA L’UOVO PER SCHIUDERLO'
                      : 'INCUBAZIONE IN PAUSA NEL PC',
                ),
              )
            else if (egg.isReady)
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
                egg.isInPc
                    ? 'Nel PC l’uovo resta conservato ma non può schiudersi.'
                    : teamSlotIndex == null
                    ? 'Alla schiusa il Pokémon verrà inviato al PC dalla Pensione.'
                    : 'Alla schiusa il Pokémon sostituirà l’uovo nello stesso Pokéslot.',
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
