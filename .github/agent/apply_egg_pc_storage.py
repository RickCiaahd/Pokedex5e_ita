from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f'{label}: atteso 1 match, trovati {count}')
    return text.replace(old, new, 1)


# Breeding screen: support three explicit egg locations.
path = Path('lib/screens/breeding/breeding_screen.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    '      if (slot.slotIndex >= unlockedPokeslots || egg.isInDayCare) {',
    '      if (\n          slot.slotIndex >= unlockedPokeslots ||\n          egg.isInDayCare ||\n          egg.isInPc\n      ) {',
    'breeding stale team egg condition',
)
text = replace_once(
    text,
    '''        if (!egg.isInDayCare) {
          await _eggRepository.saveEgg(
            profile.id,
            egg.copyWith(isInDayCare: true, carriedEntireIncubation: false),
          );
        }''',
    '''        if (!egg.isInDayCare && !egg.isInPc) {
          await _eggRepository.saveEgg(
            profile.id,
            egg.copyWith(
              isInDayCare: true,
              isInPc: false,
              carriedEntireIncubation: false,
            ),
          );
        }''',
    'breeding locked egg migration',
)
text = replace_once(
    text,
    '      if (egg.isInDayCare) continue;',
    '      if (egg.isInDayCare || egg.isInPc) continue;',
    'breeding skip externally stored eggs',
)
text = replace_once(
    text,
    '''      final egg = created.copyWith(
        isInDayCare: _useDayCare,
        carriedEntireIncubation: !_useDayCare,
      );''',
    '''      final egg = created.copyWith(
        isInDayCare: _useDayCare,
        isInPc: false,
        carriedEntireIncubation: !_useDayCare,
      );''',
    'breeding created egg location',
)
text = replace_once(
    text,
    '''      egg.copyWith(isInDayCare: true, carriedEntireIncubation: false),''',
    '''      egg.copyWith(
        isInDayCare: true,
        isInPc: false,
        carriedEntireIncubation: false,
      ),''',
    'move egg to daycare flags',
)
text = replace_once(
    text,
    '''    await _reload(message: 'Uovo affidato alla Pensione Pokémon.');
  }

  Future<void> _moveEggToTeam''',
    '''    await _reload(message: 'Uovo affidato alla Pensione Pokémon.');
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

  Future<void> _moveEggToTeam''',
    'insert move egg to pc',
)
text = replace_once(
    text,
    '''      egg.copyWith(isInDayCare: false),''',
    '''      egg.copyWith(isInDayCare: false, isInPc: false),''',
    'move egg to team flags',
)
text = replace_once(
    text,
    '''  Future<void> _advanceEgg(_BreedingScreenData data, BreedingEgg egg) async {
    final result = _breedingService.advanceIncubation(''',
    '''  Future<void> _advanceEgg(_BreedingScreenData data, BreedingEgg egg) async {
    if (egg.isInPc) {
      setState(() {
        _message =
            'Nel PC l’incubazione è in pausa. Ritira l’uovo in squadra oppure affidalo alla Pensione.';
      });
      return;
    }
    final result = _breedingService.advanceIncubation(''',
    'pause incubation in pc',
)
text = replace_once(
    text,
    '''  Future<void> _hatchEgg(_BreedingScreenData data, BreedingEgg egg) async {
    if (!egg.isReady) return;''',
    '''  Future<void> _hatchEgg(_BreedingScreenData data, BreedingEgg egg) async {
    if (!egg.isReady) return;
    if (egg.isInPc) {
      setState(() {
        _message =
            'Un uovo depositato nel PC non può schiudersi. Ritiralo in squadra oppure spostalo in Pensione.';
      });
      return;
    }''',
    'prevent hatch in pc',
)
text = replace_once(
    text,
    '''                       onMoveToDayCare: () => _moveEggToDayCare(data, egg),
                       onMoveToTeam: () => _moveEggToTeam(data, egg),''',
    '''                       onMoveToDayCare: () => _moveEggToDayCare(data, egg),
                       onMoveToPc: () => _moveEggToPc(data, egg),
                       onMoveToTeam: () => _moveEggToTeam(data, egg),''',
    'pass move to pc callback',
)
text = replace_once(
    text,
    '''    required this.onMoveToDayCare,
    required this.onMoveToTeam,''',
    '''    required this.onMoveToDayCare,
    required this.onMoveToPc,
    required this.onMoveToTeam,''',
    'egg card constructor pc callback',
)
text = replace_once(
    text,
    '''  final VoidCallback onMoveToDayCare;
  final VoidCallback onMoveToTeam;''',
    '''  final VoidCallback onMoveToDayCare;
  final VoidCallback onMoveToPc;
  final VoidCallback onMoveToTeam;''',
    'egg card field pc callback',
)
text = replace_once(
    text,
    '                const EggAssetImage(size: 64),',
    '                const EggAssetImage(size: 54),',
    'smaller breeding egg sprite',
)
old_storage = '''            Card(
              margin: EdgeInsets.zero,
              color: colors.surfaceContainerHighest,
              child: ListTile(
                leading: Icon(
                  teamSlotIndex == null
                      ? Icons.home_work_outlined
                      : Icons.group_outlined,
                ),
                title: Text(
                  teamSlotIndex == null
                      ? 'Pensione Pokémon'
                      : 'Squadra · Slot ${teamSlotIndex! + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  egg.carriedEntireIncubation
                      ? 'Occupa un Pokéslot e nascerà con Lealtà +2.'
                      : 'Non ha trascorso tutta l’incubazione in squadra: Lealtà +1.',
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (teamSlotIndex == null)
              OutlinedButton.icon(
                onPressed: canMoveToTeam ? onMoveToTeam : null,
                icon: const Icon(Icons.login),
                label: Text(
                  canMoveToTeam
                      ? 'RITIRA IN SQUADRA'
                      : 'NESSUN POKÉSLOT LIBERO',
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: onMoveToDayCare,
                icon: const Icon(Icons.home_work_outlined),
                label: const Text('SPOSTA IN PENSIONE'),
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
                teamSlotIndex == null
                    ? 'Alla schiusa il Pokémon verrà inviato al PC dalla Pensione.'
                    : 'Alla schiusa il Pokémon sostituirà l’uovo nello stesso Pokéslot.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ],'''
new_storage = '''            Card(
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
            ],'''
text = replace_once(text, old_storage, new_storage, 'egg storage controls')
path.write_text(text, encoding='utf-8')


# PC screen: load, display, deposit and withdraw eggs.
path = Path('lib/screens/pc/pokemon_pc_screen.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    "import '../../models/pc_pokemon.dart';",
    "import '../../models/breeding_egg.dart';\nimport '../../models/pc_pokemon.dart';",
    'pc breeding egg import',
)
text = replace_once(
    text,
    "import '../../repositories/pokemon_pc_repository.dart';",
    "import '../../repositories/breeding_egg_repository.dart';\nimport '../../repositories/pokemon_pc_repository.dart';",
    'pc egg repository import',
)
text = replace_once(
    text,
    "import '../../widgets/pokemon/pokemon_asset_image.dart';",
    "import '../../widgets/pokemon/pokemon_asset_image.dart';\nimport '../../widgets/pc/pc_egg_widgets.dart';\nimport '../breeding/breeding_screen.dart';",
    'pc egg widgets import',
)
text = replace_once(
    text,
    '''  final PokemonPcRepository _pokemonPcRepository = PokemonPcRepository();
  final TeamRepository _teamRepository = TeamRepository();''',
    '''  final PokemonPcRepository _pokemonPcRepository = PokemonPcRepository();
  final BreedingEggRepository _eggRepository = BreedingEggRepository();
  final TeamRepository _teamRepository = TeamRepository();''',
    'pc egg repository field',
)
text = replace_once(
    text,
    '''  List<PcPokemon> _pcPokemon = [];
  List<TeamSlot> _team = [];''',
    '''  List<PcPokemon> _pcPokemon = [];
  List<BreedingEgg> _eggs = [];
  List<TeamSlot> _team = [];''',
    'pc eggs state',
)
text = replace_once(
    text,
    '''      final pcPokemon = await _pokemonPcRepository.getPokemon(profile.id);
      final team = await _teamRepository.getTeam(profile.id);''',
    '''      final pcPokemon = await _pokemonPcRepository.getPokemon(profile.id);
      final eggs = await _eggRepository.getEggs(profile.id);
      final team = await _teamRepository.getTeam(profile.id);''',
    'pc load eggs',
)
text = replace_once(
    text,
    '''        _pcPokemon = pcPokemon;
        _team = team;''',
    '''        _pcPokemon = pcPokemon;
        _eggs = eggs;
        _team = team;''',
    'pc assign eggs',
)
insert_after_filtered = '''  List<PcPokemon> get _filteredPcPokemon {
    final query = _pcQuery.trim().toLowerCase();
    if (query.isEmpty) return _pcPokemon;

    return _pcPokemon
        .where((item) {
          final pokemon = _pokemonById(item.pokemonId);
          final baseName = pokemon?.name.toLowerCase() ?? '';
          final nickname = item.displayName.toLowerCase();
          final number = item.pokemonId.toString();
          final types =
              pokemon?.types.any(
                (type) => type.toLowerCase().contains(query),
              ) ??
              false;

          return baseName.contains(query) ||
              nickname.contains(query) ||
              number.contains(query) ||
              types;
        })
        .toList(growable: false);
  }
'''
replacement_filtered = insert_after_filtered + '''
  List<BreedingEgg> get _pcEggs =>
      _eggs.where((egg) => egg.isInPc).toList(growable: false);

  List<BreedingEgg> get _filteredPcEggs {
    final query = _pcQuery.trim().toLowerCase();
    if (query.isEmpty) return _pcEggs;
    return _pcEggs.where((egg) {
      final pokemon = _pokemonById(egg.speciesId);
      return 'uovo'.contains(query) ||
          (pokemon?.name.toLowerCase().contains(query) ?? false) ||
          egg.parentNames.any((name) => name.toLowerCase().contains(query));
    }).toList(growable: false);
  }

  BreedingEgg? _eggById(String? eggId) {
    if (eggId == null) return null;
    for (final egg in _eggs) {
      if (egg.id == eggId) return egg;
    }
    return null;
  }
'''
text = replace_once(text, insert_after_filtered, replacement_filtered, 'pc filtered eggs getters')
old_deposit_start = '''  Future<void> _depositTeamSlot(TeamSlot slot) async {
    final profile = _profile;
    final pokemon = _pokemonById(slot.pokemonId);
    if (profile == null || slot.pokemonId == null) return;

    final displayName = _slotDisplayName(slot, pokemon);'''
new_deposit_start = '''  Future<void> _depositTeamSlot(TeamSlot slot) async {
    final profile = _profile;
    if (profile == null) return;

    if (slot.isEgg) {
      final egg = _eggById(slot.eggId);
      if (egg == null) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Deposita l’uovo nel PC?'),
          content: const Text(
            'L’uovo libererà il Pokéslot. Nel PC l’incubazione resterà in pausa e il bonus di Lealtà +2 non sarà più disponibile.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Deposita'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await _teamRepository.clearSlot(
        profileId: profile.id,
        slotIndex: slot.slotIndex,
      );
      await _eggRepository.saveEgg(
        profile.id,
        egg.copyWith(
          isInDayCare: false,
          isInPc: true,
          carriedEntireIncubation: false,
        ),
      );
      await _loadPc(clearMessages: false);
      if (!mounted) return;
      setState(() => _successMessage = 'Uovo depositato nel PC.');
      return;
    }

    final pokemon = _pokemonById(slot.pokemonId);
    if (slot.pokemonId == null) return;
    final displayName = _slotDisplayName(slot, pokemon);'''
text = replace_once(text, old_deposit_start, new_deposit_start, 'pc deposit egg branch')
text = replace_once(
    text,
    '''  Future<void> _releaseFromPc(PcPokemon pcPokemon) async {''',
    '''  Future<void> _moveEggToTeam(BreedingEgg egg) async {
    final profile = _profile;
    final freeSlot = _firstFreeTeamSlot;
    if (profile == null || freeSlot == null) return;
    await _teamRepository.setEggInSlot(
      profileId: profile.id,
      slotIndex: freeSlot.slotIndex,
      eggId: egg.id,
    );
    await _eggRepository.saveEgg(
      profile.id,
      egg.copyWith(isInDayCare: false, isInPc: false),
    );
    await _loadPc(clearMessages: false);
    if (!mounted) return;
    setState(() {
      _successMessage =
          'Uovo spostato nello slot squadra ${freeSlot.slotIndex + 1}.';
    });
  }

  Future<void> _releaseFromPc(PcPokemon pcPokemon) async {''',
    'insert move pc egg to team',
)
text = replace_once(
    text,
    '''    final visibleTeam = _visibleTeam;
    final filteredPcPokemon = _filteredPcPokemon;''',
    '''    final visibleTeam = _visibleTeam;
    final filteredPcPokemon = _filteredPcPokemon;
    final filteredPcEggs = _filteredPcEggs;
    final storedCount = _pcPokemon.length + _pcEggs.length;
    final filteredCount = filteredPcPokemon.length + filteredPcEggs.length;''',
    'pc build egg counts',
)
text = replace_once(text, 'storedCount: _pcPokemon.length,', 'storedCount: storedCount,', 'pc header total count')
text = replace_once(
    text,
    '''                       storedCount: filteredPcPokemon.length,
                       totalCount: _pcPokemon.length,''',
    '''                       storedCount: filteredCount,
                       totalCount: storedCount,''',
    'pc toolbar egg counts',
)
old_grid = '''                   Expanded(
                     child: _pcPokemon.isEmpty
                         ? const Padding(
                             padding: EdgeInsets.symmetric(horizontal: 16),
                             child: _PcEmptyState(),
                           )
                         : filteredPcPokemon.isEmpty
                         ? const _PcNoSearchResults()
                         : GridView.builder(
                             padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                             gridDelegate:
                                 const SliverGridDelegateWithMaxCrossAxisExtent(
                                   maxCrossAxisExtent: 88,
                                   mainAxisSpacing: 8,
                                   crossAxisSpacing: 8,
                                   childAspectRatio: 1,
                                 ),
                             itemCount: filteredPcPokemon.length,
                             itemBuilder: (context, index) {
                               final item = filteredPcPokemon[index];
                               return _PcGridCell(
                                 pcPokemon: item,
                                 pokemon: _pokemonById(item.pokemonId),
                                 onTap: () => _openPcPokemonActions(item),
                               );
                             },
                           ),
                   ),'''
new_grid = '''                   Expanded(
                     child: storedCount == 0
                         ? const Padding(
                             padding: EdgeInsets.symmetric(horizontal: 16),
                             child: _PcEmptyState(),
                           )
                         : filteredCount == 0
                         ? const _PcNoSearchResults()
                         : GridView.builder(
                             padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                             gridDelegate:
                                 const SliverGridDelegateWithMaxCrossAxisExtent(
                                   maxCrossAxisExtent: 88,
                                   mainAxisSpacing: 8,
                                   crossAxisSpacing: 8,
                                   childAspectRatio: 1,
                                 ),
                             itemCount: filteredCount,
                             itemBuilder: (context, index) {
                               if (index < filteredPcPokemon.length) {
                                 final item = filteredPcPokemon[index];
                                 return _PcGridCell(
                                   pcPokemon: item,
                                   pokemon: _pokemonById(item.pokemonId),
                                   onTap: () => _openPcPokemonActions(item),
                                 );
                               }
                               final egg = filteredPcEggs[
                                   index - filteredPcPokemon.length];
                               return PcEggGridCell(
                                 egg: egg,
                                 pokemon: _pokemonById(egg.speciesId),
                                 onTap: () => _openPcEggActions(egg),
                               );
                             },
                           ),
                   ),'''
text = replace_once(text, old_grid, new_grid, 'pc combined grid')
text = replace_once(
    text,
    '''  Future<void> _openPcPokemonActions(PcPokemon item) async {''',
    '''  Future<void> _openPcEggActions(BreedingEgg egg) async {
    final action = await showModalBottomSheet<PcEggAction>(
      context: context,
      showDragHandle: true,
      builder: (_) => PcEggActionSheet(
        egg: egg,
        pokemon: _pokemonById(egg.speciesId),
        teamIsFull: _firstFreeTeamSlot == null,
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case PcEggAction.moveToTeam:
        await _moveEggToTeam(egg);
        break;
      case PcEggAction.openBreeding:
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BreedingScreen()),
        );
        await _loadPc(clearMessages: false);
        break;
    }
  }

  Future<void> _openPcPokemonActions(PcPokemon item) async {''',
    'insert pc egg actions',
)
text = replace_once(
    text,
    '''        final childAspectRatio = veryCompact
            ? 1.20
            : compact
            ? 1.45
            : 1.55;''',
    '''        final childAspectRatio = veryCompact
            ? 0.95
            : compact
            ? 1.05
            : 1.25;''',
    'taller pc team cards',
)
text = replace_once(
    text,
    '''                 onDeposit: slot.isPokemon ? () => onDeposit(slot) : null,''',
    '''                 onDeposit: slot.isEmpty ? null : () => onDeposit(slot),''',
    'enable egg deposit from pc team panel',
)
text = replace_once(
    text,
    '''        final spriteSize = dense ? 34.0 : 42.0;
        final gap = dense ? 5.0 : 8.0;''',
    '''        final spriteSize = dense ? 34.0 : 42.0;
        final eggSpriteSize = dense ? 26.0 : 30.0;
        final gap = dense ? 5.0 : 8.0;''',
    'smaller pc egg sprite variable',
)
text = replace_once(
    text,
    '''                 slot.isEgg
                     ? EggAssetImage(size: spriteSize)''',
    '''                 slot.isEgg
                     ? EggAssetImage(size: eggSpriteSize)''',
    'use smaller pc egg sprite',
)
text = replace_once(
    text,
    '''                       if (pokemon != null)
                         TextButton(''',
    '''                       if (onDeposit != null)
                         TextButton(''',
    'show deposit button for egg',
)
text = replace_once(
    text,
    '''          'Nessun Pokémon nel PC. Quando catturi con la squadra piena o depositi dalla squadra, finirà qui.',''',
    '''          'Nessun Pokémon o uovo nel PC. Quando catturi con la squadra piena o depositi dalla squadra, finirà qui.',''',
    'pc empty state eggs',
)
path.write_text(text, encoding='utf-8')


# Team screen: keep the egg visually smaller than a Pokémon.
path = Path('lib/screens/team/team_selection_screen.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    '            ? const EggAssetImage(size: 46)',
    '            ? const EggAssetImage(size: 38)',
    'smaller team egg sprite',
)
path.write_text(text, encoding='utf-8')


# Persist and test PC storage.
path = Path('test/breeding_egg_test.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    '''      carriedEntireIncubation: false,
    );''',
    '''      carriedEntireIncubation: false,
      isInPc: true,
    );''',
    'egg test pc setup',
)
text = replace_once(
    text,
    '''    expect(decoded.carriedEntireIncubation, isFalse);
    expect(decoded.isReady, isFalse);''',
    '''    expect(decoded.carriedEntireIncubation, isFalse);
    expect(decoded.isInPc, isTrue);
    expect(decoded.isInTeam, isFalse);
    expect(decoded.isReady, isFalse);''',
    'egg test pc assertions',
)
path.write_text(text, encoding='utf-8')

Path('test/egg_pc_storage_test.dart').write_text('''import 'package:flutter_test/flutter_test.dart';

import 'package:pokedex_5e_ita/models/breeding_egg.dart';

void main() {
  test('i salvataggi precedenti considerano l’uovo fuori dal PC', () {
    final egg = BreedingEgg.fromJson({
      'id': 'legacy-egg',
      'speciesId': 1,
      'parentNames': <String>[],
      'createdAt': DateTime.utc(2026, 7, 14).toIso8601String(),
      'hatchTime': 100,
      'incubationRemaining': 50,
      'nature': 'Hardy',
      'selectedMoves': <String>[],
      'inheritedMoves': <String>[],
    });

    expect(egg.isInPc, isFalse);
    expect(egg.isInDayCare, isFalse);
    expect(egg.isInTeam, isTrue);
  });

  test('deposito e ritiro dal PC mantengono il contenuto dell’uovo', () {
    final source = BreedingEgg(
      id: 'pc-egg',
      speciesId: 403,
      parentNames: const ['Luxio', 'Ditto'],
      createdAt: DateTime.utc(2026, 7, 14),
      hatchTime: 250,
      incubationRemaining: 100,
      nature: 'Jolly',
      gender: 'Female',
      ability: 'Rivalry',
      selectedMoves: const ['Tackle'],
      inheritedMoves: const ['Quick Attack'],
    );

    final stored = source.copyWith(
      isInPc: true,
      isInDayCare: false,
      carriedEntireIncubation: false,
    );
    final decoded = BreedingEgg.fromJson(stored.toJson());
    expect(decoded.isInPc, isTrue);
    expect(decoded.isInTeam, isFalse);
    expect(decoded.speciesId, source.speciesId);
    expect(decoded.selectedMoves, source.selectedMoves);
    expect(decoded.inheritedMoves, source.inheritedMoves);

    final withdrawn = decoded.copyWith(isInPc: false, isInDayCare: false);
    expect(withdrawn.isInTeam, isTrue);
    expect(withdrawn.carriedEntireIncubation, isFalse);
  });
}
''', encoding='utf-8')

# Changelog.
path = Path('CHANGELOG.md')
text = path.read_text(encoding='utf-8')
anchor = '- uova come entità reali della squadra: occupano un Pokéslot, possono essere affidate alla Pensione Pokémon e alla schiusa vengono sostituite dal Pokémon nato nello stesso slot.'
addition = '- deposito delle uova nel PC Pokémon, con incubazione in pausa, ritiro in squadra e visualizzazione nel PC Box.'
if addition not in text:
    text = replace_once(text, anchor, anchor + '\n' + addition, 'changelog egg pc')
layout = '- sprite delle uova ridimensionati e schede della squadra nel PC rese più alte per evitare overflow alle larghezze intermedie.'
anchor_modified = '- la schiusa considera soltanto i Pokéslot sbloccati: con tutti gli slot disponibili occupati il Pokémon viene depositato nel PC, e gli esemplari finiti in slot bloccati vengono recuperati automaticamente.'
if layout not in text:
    text = replace_once(text, anchor_modified, anchor_modified + '\n' + layout, 'changelog egg layout')
path.write_text(text, encoding='utf-8')
