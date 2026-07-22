import 'package:flutter/material.dart';

import '../../models/bag_inventory_entry.dart';
import '../../models/bag_item.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_nature.dart';
import '../../models/team_slot.dart';
import '../../models/trainer_progression.dart';
import '../../models/user_profile.dart';
import '../../repositories/bag_inventory_repository.dart';
import '../../repositories/item_repository.dart';
import '../../repositories/pokedex_repositry.dart';
import '../../repositories/pokemon_pc_repository.dart';
import '../../repositories/pokemon_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/team_repository.dart';
import '../../services/custom_pokemon_discovery_service.dart';
import '../../services/trainer_path_passive_service.dart';
import '../../widgets/navigation/home_leading_button.dart';
import '../../widgets/pokemon/pokemon_asset_image.dart';

class CapturePokemonScreen extends StatefulWidget {
  const CapturePokemonScreen({super.key});

  @override
  State<CapturePokemonScreen> createState() => _CapturePokemonScreenState();
}

class _CapturePokemonScreenState extends State<CapturePokemonScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final PokemonRepository _pokemonRepository = PokemonRepository();
  final PokedexRepository _pokedexRepository = PokedexRepository();
  final TeamRepository _teamRepository = TeamRepository();
  final PokemonPcRepository _pokemonPcRepository = PokemonPcRepository();
  final ItemRepository _itemRepository = ItemRepository();
  final BagInventoryRepository _bagRepository = BagInventoryRepository();
  final CustomPokemonDiscoveryService _discoveryService =
      CustomPokemonDiscoveryService();
  final TextEditingController _searchController = TextEditingController();

  UserProfile? _profile;
  List<Pokemon> _pokemon = [];
  List<TeamSlot> _team = [];
  List<BagItem> _items = [];
  List<BagInventoryEntry> _inventory = [];

  bool _isLoading = true;
  bool _isSaving = false;
  String _query = '';
  String? _successMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool clearMessages = true}) async {
    setState(() {
      _isLoading = true;
      if (clearMessages) {
        _successMessage = null;
        _errorMessage = null;
      }
    });

    try {
      final profile = await _profileRepository.getActiveProfile();
      final pokemon = await _pokemonRepository.getAllPokemon();
      final team = await _teamRepository.getTeam(profile.id);
      final items = await _itemRepository.getWebItems();
      final inventory = await _bagRepository.getInventory(profile.id);

      team.sort((a, b) => a.slotIndex.compareTo(b.slotIndex));

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _pokemon = pokemon..sort((a, b) => a.id.compareTo(b.id));
        _team = team;
        _items = items;
        _inventory = inventory;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  int get _unlockedPokeslots {
    final level = _profile?.trainerLevel ?? TrainerProgression.minLevel;
    return TrainerProgression.pokeslotsForLevel(level);
  }

  TeamSlot? get _firstFreeTeamSlot {
    final unlockedSlots =
        _team
            .where((slot) => slot.slotIndex < _unlockedPokeslots)
            .toList(growable: true)
          ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));

    for (final slot in unlockedSlots) {
      if (slot.isEmpty) return slot;
    }
    return null;
  }

  List<Pokemon> get _filteredPokemon {
    final query = _query.toLowerCase().trim();
    return _pokemon
        .where((pokemon) {
          return query.isEmpty ||
              pokemon.name.toLowerCase().contains(query) ||
              pokemon.id.toString().contains(query) ||
              pokemon.types.any((type) => type.toLowerCase().contains(query));
        })
        .toList(growable: false);
  }

  List<_OwnedPokeball> get _ownedPokeballs {
    final balls = <_OwnedPokeball>[];
    for (final entry in _inventory) {
      final item = _itemById(entry.itemId);
      if (item != null && item.type == 'pokeball') {
        balls.add(_OwnedPokeball(item: item, quantity: entry.quantity));
      }
    }
    balls.sort((a, b) => a.item.name.compareTo(b.item.name));
    return balls;
  }

  BagItem? _itemById(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  _OwnedPokeball? _ownedBallById(String? itemId) {
    if (itemId == null) return null;
    for (final ball in _ownedPokeballs) {
      if (ball.item.id == itemId) return ball;
    }
    return null;
  }

  Future<void> _openRegistrationSheet(Pokemon pokemon) async {
    final formChoices = await PokemonAssetPaths.formChoices(pokemon);
    if (!mounted) return;

    final result = await showModalBottomSheet<_CaptureRegistrationResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _RegisterCaughtSheet(
        pokemon: pokemon,
        ownedPokeballs: _ownedPokeballs,
        genderOptions: _genderOptionsFor(pokemon),
        formChoices: formChoices.length > 1 ? formChoices : const [],
      ),
    );

    if (!mounted || result == null) return;

    switch (result.action) {
      case _CaptureRegistrationAction.register:
        await _registerCaughtPokemon(pokemon, result);
        break;
      case _CaptureRegistrationAction.markSeen:
        await _markSeen(pokemon);
        break;
    }
  }

  Future<void> _registerCaughtPokemon(
    Pokemon pokemon,
    _CaptureRegistrationResult result,
  ) async {
    final profile = _profile;
    if (profile == null || _isSaving) return;

    setState(() {
      _isSaving = true;
      _successMessage = null;
      _errorMessage = null;
    });

    try {
      final selectedBall = _ownedBallById(result.ballId);
      if (selectedBall != null) {
        if (selectedBall.quantity < result.ballQuantity) {
          if (!mounted) return;
          setState(() {
            _errorMessage =
                'Non hai abbastanza ${selectedBall.item.name} nello zaino.';
          });
          return;
        }

        final consumed = await _bagRepository.consumeItem(
          profileId: profile.id,
          itemId: selectedBall.item.id,
          quantity: result.ballQuantity,
        );
        if (!consumed) {
          if (!mounted) return;
          setState(() {
            _errorMessage =
                'Non è stato possibile consumare ${selectedBall.item.name}.';
          });
          return;
        }
      }

      final destination = await _addPokemonToCollection(
        profile,
        pokemon,
        result,
      );
      final revealed = await _discoveryService.revealByPokemonId(pokemon.id);
      if (revealed) PokemonRepository.clearCache();
      await _loadData(clearMessages: false);

      if (!mounted) return;
      setState(() {
        _successMessage = revealed
            ? '${pokemon.name} scoperto, registrato come catturato e $destination.'
            : '${pokemon.name} registrato come catturato e $destination.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _markSeen(Pokemon pokemon) async {
    final profile = _profile;
    if (profile == null) return;

    await _pokedexRepository.updateMarkMode(
      profileId: profile.id,
      pokemonId: pokemon.id,
      seen: true,
      caught: false,
    );
    final revealed = await _discoveryService.revealByPokemonId(pokemon.id);
    if (revealed) PokemonRepository.clearCache();

    if (!mounted) return;
    setState(() => _successMessage = '${pokemon.name} registrato come visto.');
  }

  Future<String> _addPokemonToCollection(
    UserProfile profile,
    Pokemon pokemon,
    _CaptureRegistrationResult result,
  ) async {
    final teamSlot = _firstFreeTeamSlot;
    final nickname = result.nickname.trim().isEmpty
        ? null
        : result.nickname.trim();
    final selectedPokemon = pokemon.resolveVariant(
      formName: result.formName,
      gender: result.gender,
    );
    final startingMoves = selectedPokemon.moves.startingMoves
        .take(4)
        .toList(growable: false);
    final naturalAbilities = selectedPokemon.abilities
        .take(2)
        .toList(growable: false);
    final initialLoyalty = TrainerPathPassiveService.initialCapturedLoyalty(
      profile,
    );

    if (teamSlot != null) {
      await _teamRepository.updateSlot(
        profileId: profile.id,
        updatedSlot: TeamSlot(
          slotIndex: teamSlot.slotIndex,
          pokemonId: pokemon.id,
          currentHp: result.currentHp,
          nickname: nickname,
          isShiny: result.isShiny,
          gender: result.gender,
          formName: result.formName,
          nature: result.nature,
          selectedMoves: startingMoves,
          abilities: naturalAbilities,
          loyalty: initialLoyalty,
        ),
      );
    } else {
      await _pokemonPcRepository.depositPokemon(
        profileId: profile.id,
        pokemonId: pokemon.id,
        currentHp: result.currentHp,
        nickname: nickname,
        isShiny: result.isShiny,
        gender: result.gender,
        formName: result.formName,
        nature: result.nature,
        selectedMoves: startingMoves,
        abilities: naturalAbilities,
        loyalty: initialLoyalty,
      );
    }

    await _pokedexRepository.updateMarkMode(
      profileId: profile.id,
      pokemonId: pokemon.id,
      formName: result.formName,
      speciesName: pokemon.name,
      seen: true,
      caught: true,
    );

    return teamSlot == null
        ? 'inviato al PC'
        : 'aggiunto allo slot squadra ${teamSlot.slotIndex + 1}';
  }

  @override
  Widget build(BuildContext context) {
    final freeSlot = _firstFreeTeamSlot;

    return Scaffold(
      appBar: AppBar(
        leading: const HomeLeadingButton(),
        title: const Text('Aggiungi Pokémon'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadData(clearMessages: false),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null && _pokemon.isEmpty)
              _CaptureErrorState(message: _errorMessage!, onRetry: _loadData)
            else ...[
              _CaptureHeader(
                freeSlotIndex: freeSlot?.slotIndex,
                unlockedSlots: _unlockedPokeslots,
              ),
              if (_isSaving) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
              ],
              if (_successMessage != null) ...[
                const SizedBox(height: 12),
                _InlineStatusMessage(
                  icon: Icons.check_circle_outline,
                  message: _successMessage!,
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Cerca per nome, numero o tipo...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 12),
              for (final pokemon in _filteredPokemon)
                _CapturePokemonCard(
                  pokemon: pokemon,
                  isSaving: _isSaving,
                  onSelect: () => _openRegistrationSheet(pokemon),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OwnedPokeball {
  const _OwnedPokeball({required this.item, required this.quantity});

  final BagItem item;
  final int quantity;
}

class _GenderOption {
  const _GenderOption({required this.value, required this.label});

  final String? value;
  final String label;
}

enum _CaptureRegistrationAction { register, markSeen }

class _CaptureRegistrationResult {
  const _CaptureRegistrationResult({
    required this.action,
    required this.ballId,
    required this.ballQuantity,
    required this.nickname,
    required this.gender,
    required this.nature,
    required this.formName,
    required this.isShiny,
    required this.currentHp,
  });

  final _CaptureRegistrationAction action;
  final String? ballId;
  final int ballQuantity;
  final String nickname;
  final String? gender;
  final String nature;
  final String? formName;
  final bool isShiny;
  final int currentHp;
}

class _CaptureHeader extends StatelessWidget {
  const _CaptureHeader({
    required this.freeSlotIndex,
    required this.unlockedSlots,
  });

  final int? freeSlotIndex;
  final int unlockedSlots;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final destination = freeSlotIndex == null
        ? 'La squadra è piena: le catture andranno al PC.'
        : 'Prossima cattura nello slot squadra ${freeSlotIndex! + 1}.';

    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.catching_pokemon,
              color: colorScheme.onPrimaryContainer,
              size: 36,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Registra Pokémon catturato',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$destination Pokeslot sbloccati: $unlockedSlots.',
                    style: TextStyle(color: colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Il calcolo della cattura resta al Master: qui registri solo il risultato finale.',
                    style: TextStyle(color: colorScheme.onPrimaryContainer),
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

class _RegisterCaughtSheet extends StatefulWidget {
  const _RegisterCaughtSheet({
    required this.pokemon,
    required this.ownedPokeballs,
    required this.genderOptions,
    required this.formChoices,
  });

  final Pokemon pokemon;
  final List<_OwnedPokeball> ownedPokeballs;
  final List<_GenderOption> genderOptions;
  final List<PokemonFormChoice> formChoices;

  @override
  State<_RegisterCaughtSheet> createState() => _RegisterCaughtSheetState();
}

class _RegisterCaughtSheetState extends State<_RegisterCaughtSheet> {
  late final TextEditingController _nicknameController;
  late final TextEditingController _hpController;
  String? _selectedBallId;
  int _ballQuantity = 1;
  String? _gender;
  String _nature = 'No Nature';
  String? _formName;
  bool _isShiny = false;

  Pokemon get _selectedPokemon =>
      widget.pokemon.resolveVariant(formName: _formName, gender: _gender);

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController();
    _hpController = TextEditingController(
      text: widget.pokemon.hitPoints.toString(),
    );
    _gender = widget.genderOptions.length == 1
        ? widget.genderOptions.first.value
        : null;
    _formName = widget.formChoices.isEmpty
        ? null
        : widget.formChoices.first.name;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _hpController.dispose();
    super.dispose();
  }

  _OwnedPokeball? get _selectedOwnedBall {
    if (_selectedBallId == null) return null;
    for (final ball in widget.ownedPokeballs) {
      if (ball.item.id == _selectedBallId) return ball;
    }
    return null;
  }

  void _setGender(String? value) {
    final oldPokemon = _selectedPokemon;
    final usedDefaultHp =
        _hpController.text.trim() == oldPokemon.hitPoints.toString();
    setState(() => _gender = value);
    if (usedDefaultHp) {
      _hpController.text = _selectedPokemon.hitPoints.toString();
    }
  }

  void _setForm(String? value) {
    final oldPokemon = _selectedPokemon;
    final usedDefaultHp =
        _hpController.text.trim() == oldPokemon.hitPoints.toString();
    setState(() => _formName = value);
    if (usedDefaultHp) {
      _hpController.text = _selectedPokemon.hitPoints.toString();
    }
  }

  void _submit(_CaptureRegistrationAction action) {
    final parsedHp = int.tryParse(_hpController.text.trim());
    if (action == _CaptureRegistrationAction.register && parsedHp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un valore HP valido.')),
      );
      return;
    }

    Navigator.of(context).pop(
      _CaptureRegistrationResult(
        action: action,
        ballId: _selectedBallId,
        ballQuantity: _ballQuantity,
        nickname: _nicknameController.text.trim(),
        gender: _gender,
        nature: _nature,
        formName: _formName,
        isShiny: _isShiny,
        currentHp: (parsedHp ?? _selectedPokemon.hitPoints)
            .clamp(0, 9999)
            .toInt(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedOwnedBall = _selectedOwnedBall;
    final selectedMaxQuantity = selectedOwnedBall?.quantity ?? 0;
    final genderOptions = widget.genderOptions;
    final genderLocked = genderOptions.length == 1;
    final formChoices = widget.formChoices;
    final selectedPokemon = _selectedPokemon;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Row(
              children: [
                PokemonAssetImage(
                  pokemon: widget.pokemon,
                  formName: _formName,
                  gender: _gender,
                  isShiny: _isShiny,
                  useLargeArtwork: true,
                  size: 86,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.pokemon.name.toUpperCase(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('#${widget.pokemon.id.toString().padLeft(3, '0')}'),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final type in selectedPokemon.types)
                            PokemonTypeBadge(type: type, height: 20),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: 'Nickname opzionale',
                hintText: 'Lascia vuoto per usare il nome del Pokémon',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: _gender,
                    decoration: const InputDecoration(labelText: 'Sesso'),
                    items: [
                      for (final option in genderOptions)
                        DropdownMenuItem<String?>(
                          value: option.value,
                          child: Text(option.label),
                        ),
                    ],
                    onChanged: genderLocked ? null : _setGender,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _nature,
                    decoration: const InputDecoration(labelText: 'Natura'),
                    items: [
                      for (final nature in PokemonNature.names)
                        DropdownMenuItem(value: nature, child: Text(nature)),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _nature = value);
                    },
                  ),
                ),
              ],
            ),
            if (formChoices.isNotEmpty) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _formName,
                decoration: const InputDecoration(labelText: 'Forma'),
                items: [
                  for (final form in formChoices)
                    DropdownMenuItem(value: form.name, child: Text(form.name)),
                ],
                onChanged: _setForm,
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hpController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'HP iniziali'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Shiny'),
                    value: _isShiny,
                    onChanged: (value) => setState(() => _isShiny = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String?>(
              initialValue: _selectedBallId,
              decoration: const InputDecoration(
                labelText: 'Poké Ball da consumare (facoltativo)',
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Nessuna / già consumata'),
                ),
                for (final ball in widget.ownedPokeballs)
                  DropdownMenuItem<String?>(
                    value: ball.item.id,
                    child: Text('${ball.item.name}  x${ball.quantity}'),
                  ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedBallId = value;
                  _ballQuantity = 1;
                });
              },
            ),
            if (selectedOwnedBall != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text('Ball usate da scalare: $_ballQuantity'),
                  ),
                  IconButton(
                    onPressed: _ballQuantity <= 1
                        ? null
                        : () => setState(() => _ballQuantity -= 1),
                    icon: const Icon(Icons.remove),
                  ),
                  IconButton(
                    onPressed: _ballQuantity >= selectedMaxQuantity
                        ? null
                        : () => setState(() => _ballQuantity += 1),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => _submit(_CaptureRegistrationAction.register),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('REGISTRA CATTURA'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _submit(_CaptureRegistrationAction.markSeen),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('SEGNA VISTO'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CapturePokemonCard extends StatelessWidget {
  const _CapturePokemonCard({
    required this.pokemon,
    required this.isSaving,
    required this.onSelect,
  });

  final Pokemon pokemon;
  final bool isSaving;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final number = '#${pokemon.id.toString().padLeft(3, '0')}';

    return Card(
      child: ListTile(
        leading: PokemonAssetImage(pokemon: pokemon, size: 48),
        title: Text(
          pokemon.name,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(number),
            for (final type in pokemon.types)
              PokemonTypeBadge(type: type, height: 18),
          ],
        ),
        trailing: FilledButton(
          onPressed: isSaving ? null : onSelect,
          child: const Text('Scegli'),
        ),
      ),
    );
  }
}

class _InlineStatusMessage extends StatelessWidget {
  const _InlineStatusMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.onSecondaryContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colorScheme.onSecondaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureErrorState extends StatelessWidget {
  const _CaptureErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 16),
          Text('Errore: $message', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Riprova')),
        ],
      ),
    );
  }
}

List<_GenderOption> _genderOptionsFor(Pokemon pokemon) {
  if (_genderlessPokemonIds.contains(pokemon.id)) {
    return const [_GenderOption(value: 'Genderless', label: 'Senza sesso')];
  }
  if (_femaleOnlyPokemonIds.contains(pokemon.id)) {
    return const [_GenderOption(value: 'Female', label: 'Femmina')];
  }
  if (_maleOnlyPokemonIds.contains(pokemon.id)) {
    return const [_GenderOption(value: 'Male', label: 'Maschio')];
  }

  return const [
    _GenderOption(value: null, label: 'Non specificato'),
    _GenderOption(value: 'Male', label: 'Maschio'),
    _GenderOption(value: 'Female', label: 'Femmina'),
  ];
}

const Set<int> _maleOnlyPokemonIds = {
  32,
  33,
  34,
  106,
  107,
  128,
  236,
  237,
  313,
  381,
  414,
  475,
  538,
  539,
  627,
  628,
  641,
  642,
  645,
  674,
  675,
};

const Set<int> _femaleOnlyPokemonIds = {
  29,
  30,
  31,
  113,
  115,
  124,
  238,
  241,
  242,
  314,
  380,
  413,
  416,
  440,
  478,
  548,
  549,
  629,
  630,
  669,
  670,
  671,
  758,
  761,
  762,
  763,
};

const Set<int> _genderlessPokemonIds = {
  81,
  82,
  100,
  101,
  120,
  121,
  137,
  144,
  145,
  146,
  150,
  151,
  201,
  233,
  243,
  244,
  245,
  249,
  250,
  251,
  292,
  337,
  338,
  343,
  344,
  374,
  375,
  376,
  377,
  378,
  379,
  382,
  383,
  384,
  385,
  386,
  436,
  437,
  462,
  474,
  479,
  480,
  481,
  482,
  483,
  484,
  486,
  487,
  489,
  490,
  491,
  492,
  493,
  494,
  599,
  600,
  601,
  615,
  622,
  623,
  638,
  639,
  640,
  643,
  644,
  646,
  647,
  648,
  649,
  703,
  716,
  717,
  718,
  719,
  720,
  721,
  772,
  773,
  774,
  781,
  785,
  786,
  787,
  788,
  789,
  790,
  791,
  792,
  793,
  794,
  795,
  796,
  797,
  798,
  799,
  800,
  801,
  802,
  807,
};
