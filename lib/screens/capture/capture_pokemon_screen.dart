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
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _formController = TextEditingController();
  final TextEditingController _initialHpController = TextEditingController();

  UserProfile? _profile;
  List<Pokemon> _pokemon = [];
  List<TeamSlot> _team = [];
  List<BagItem> _items = [];
  List<BagInventoryEntry> _inventory = [];

  Pokemon? _selectedPokemon;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isShiny = false;
  String _query = '';
  String _selectedNature = 'No Nature';
  String? _selectedBallId;
  String? _selectedGender;
  int _ballQuantity = 1;
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
    _nicknameController.dispose();
    _formController.dispose();
    _initialHpController.dispose();
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
        if (_selectedBallId != null && _ownedPokeballs.every((ball) => ball.item.id != _selectedBallId)) {
          _selectedBallId = null;
          _ballQuantity = 1;
        }
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
    final unlockedSlots = _team
        .where((slot) => slot.slotIndex < _unlockedPokeslots)
        .toList(growable: true)
      ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));

    for (final slot in unlockedSlots) {
      if (slot.pokemonId == null) return slot;
    }
    return null;
  }

  List<Pokemon> get _filteredPokemon {
    final query = _query.toLowerCase().trim();
    return _pokemon.where((pokemon) {
      return query.isEmpty ||
          pokemon.name.toLowerCase().contains(query) ||
          pokemon.id.toString().contains(query) ||
          pokemon.types.any((type) => type.toLowerCase().contains(query));
    }).toList(growable: false);
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

  _OwnedPokeball? get _selectedOwnedBall {
    final selectedId = _selectedBallId;
    if (selectedId == null) return null;
    for (final ball in _ownedPokeballs) {
      if (ball.item.id == selectedId) return ball;
    }
    return null;
  }

  void _selectPokemon(Pokemon pokemon) {
    setState(() {
      _selectedPokemon = pokemon;
      _successMessage = null;
      _errorMessage = null;
      _nicknameController.clear();
      _formController.clear();
      _initialHpController.text = pokemon.hitPoints.toString();
      _selectedGender = null;
      _selectedNature = 'No Nature';
      _isShiny = false;
    });
  }

  Future<void> _registerCaughtPokemon() async {
    final profile = _profile;
    final pokemon = _selectedPokemon;
    if (profile == null || pokemon == null || _isSaving) return;

    final initialHp = int.tryParse(_initialHpController.text.trim());
    if (initialHp == null || initialHp < 0) {
      setState(() => _errorMessage = 'Inserisci un valore HP iniziali valido.');
      return;
    }

    setState(() {
      _isSaving = true;
      _successMessage = null;
      _errorMessage = null;
    });

    try {
      final selectedBall = _selectedOwnedBall;
      if (selectedBall != null) {
        if (selectedBall.quantity < _ballQuantity) {
          if (!mounted) return;
          setState(() {
            _errorMessage = 'Non hai abbastanza ${selectedBall.item.name} nello zaino.';
          });
          return;
        }

        final consumed = await _bagRepository.consumeItem(
          profileId: profile.id,
          itemId: selectedBall.item.id,
          quantity: _ballQuantity,
        );
        if (!consumed) {
          if (!mounted) return;
          setState(() {
            _errorMessage = 'Non è stato possibile consumare ${selectedBall.item.name}.';
          });
          return;
        }
      }

      final nickname = _emptyToNull(_nicknameController.text);
      final formName = _emptyToNull(_formController.text);
      final destination = await _addPokemonToCollection(
        profile,
        pokemon,
        currentHp: initialHp,
        nickname: nickname,
        gender: _selectedGender,
        isShiny: _isShiny,
        nature: _selectedNature,
        formName: formName,
      );
      await _loadData(clearMessages: false);

      if (!mounted) return;
      setState(() {
        _selectedPokemon = null;
        _selectedBallId = null;
        _selectedGender = null;
        _selectedNature = 'No Nature';
        _isShiny = false;
        _ballQuantity = 1;
        _nicknameController.clear();
        _formController.clear();
        _initialHpController.clear();
        _successMessage = '${nickname ?? pokemon.name} registrato come catturato e $destination.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _markSeen() async {
    final profile = _profile;
    final pokemon = _selectedPokemon;
    if (profile == null || pokemon == null) return;

    await _pokedexRepository.updateMarkMode(
      profileId: profile.id,
      pokemonId: pokemon.id,
      seen: true,
      caught: false,
    );

    if (!mounted) return;
    setState(() => _successMessage = '${pokemon.name} registrato come visto.');
  }

  Future<String> _addPokemonToCollection(
    UserProfile profile,
    Pokemon pokemon, {
    required int currentHp,
    String? nickname,
    String? gender,
    required bool isShiny,
    required String nature,
    String? formName,
  }) async {
    final teamSlot = _firstFreeTeamSlot;
    if (teamSlot != null) {
      await _teamRepository.updateSlot(
        profileId: profile.id,
        updatedSlot: TeamSlot(
          slotIndex: teamSlot.slotIndex,
          pokemonId: pokemon.id,
          currentHp: currentHp,
          nickname: nickname,
          isShiny: isShiny,
          gender: gender,
          formName: formName,
          nature: nature,
        ),
      );
    } else {
      await _pokemonPcRepository.depositPokemon(
        profileId: profile.id,
        pokemonId: pokemon.id,
        currentHp: currentHp,
        nickname: nickname,
        isShiny: isShiny,
        gender: gender,
        formName: formName,
        nature: nature,
      );
    }

    await _pokedexRepository.updateMarkMode(
      profileId: profile.id,
      pokemonId: pokemon.id,
      seen: true,
      caught: true,
    );

    return teamSlot == null
        ? 'inviato al PC'
        : 'aggiunto allo slot squadra ${teamSlot.slotIndex + 1}';
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final selectedPokemon = _selectedPokemon;
    final selectedOwnedBall = _selectedOwnedBall;
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
              _CaptureErrorState(
                message: _errorMessage!,
                onRetry: _loadData,
              )
            else ...[
              _CaptureHeader(
                freeSlotIndex: freeSlot?.slotIndex,
                unlockedSlots: _unlockedPokeslots,
              ),
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
              if (selectedPokemon != null) ...[
                const SizedBox(height: 12),
                _RegisterCaughtPanel(
                  pokemon: selectedPokemon,
                  nicknameController: _nicknameController,
                  formController: _formController,
                  initialHpController: _initialHpController,
                  ownedPokeballs: _ownedPokeballs,
                  selectedBallId: _selectedBallId,
                  selectedOwnedBall: selectedOwnedBall,
                  ballQuantity: _ballQuantity,
                  selectedGender: _selectedGender,
                  selectedNature: _selectedNature,
                  isShiny: _isShiny,
                  isSaving: _isSaving,
                  onBallChanged: (value) {
                    setState(() {
                      _selectedBallId = value;
                      _ballQuantity = 1;
                    });
                  },
                  onQuantityChanged: (value) {
                    setState(() => _ballQuantity = value.clamp(1, 99).toInt());
                  },
                  onGenderChanged: (value) => setState(() => _selectedGender = value),
                  onNatureChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedNature = value);
                  },
                  onShinyChanged: (value) => setState(() => _isShiny = value),
                  onRegister: _registerCaughtPokemon,
                  onMarkSeen: _markSeen,
                  onClose: () => setState(() => _selectedPokemon = null),
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
                  selected: selectedPokemon?.id == pokemon.id,
                  onSelect: () => _selectPokemon(pokemon),
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

class _CaptureHeader extends StatelessWidget {
  const _CaptureHeader({required this.freeSlotIndex, required this.unlockedSlots});

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

class _RegisterCaughtPanel extends StatelessWidget {
  const _RegisterCaughtPanel({
    required this.pokemon,
    required this.nicknameController,
    required this.formController,
    required this.initialHpController,
    required this.ownedPokeballs,
    required this.selectedBallId,
    required this.selectedOwnedBall,
    required this.ballQuantity,
    required this.selectedGender,
    required this.selectedNature,
    required this.isShiny,
    required this.isSaving,
    required this.onBallChanged,
    required this.onQuantityChanged,
    required this.onGenderChanged,
    required this.onNatureChanged,
    required this.onShinyChanged,
    required this.onRegister,
    required this.onMarkSeen,
    required this.onClose,
  });

  final Pokemon pokemon;
  final TextEditingController nicknameController;
  final TextEditingController formController;
  final TextEditingController initialHpController;
  final List<_OwnedPokeball> ownedPokeballs;
  final String? selectedBallId;
  final _OwnedPokeball? selectedOwnedBall;
  final int ballQuantity;
  final String? selectedGender;
  final String selectedNature;
  final bool isShiny;
  final bool isSaving;
  final ValueChanged<String?> onBallChanged;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<String?> onGenderChanged;
  final ValueChanged<String?> onNatureChanged;
  final ValueChanged<bool> onShinyChanged;
  final VoidCallback onRegister;
  final VoidCallback onMarkSeen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final selectedMaxQuantity = selectedOwnedBall?.quantity ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                PokemonAssetImage(
                  pokemon: pokemon,
                  useLargeArtwork: true,
                  size: 86,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pokemon.name.toUpperCase(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text('#${pokemon.id.toString().padLeft(3, '0')}'),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final type in pokemon.types)
                            PokemonTypeBadge(type: type, height: 20),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Chiudi',
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'DETTAGLI CATTURA',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nicknameController,
              enabled: !isSaving,
              decoration: const InputDecoration(
                labelText: 'Nickname',
                hintText: 'Lascia vuoto per usare il nome originale',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    key: ValueKey(selectedGender ?? 'none'),
                    initialValue: selectedGender,
                    decoration: const InputDecoration(labelText: 'Sesso'),
                    items: const [
                      DropdownMenuItem<String?>(value: null, child: Text('Non specificato')),
                      DropdownMenuItem<String?>(value: 'Male', child: Text('Maschio')),
                      DropdownMenuItem<String?>(value: 'Female', child: Text('Femmina')),
                      DropdownMenuItem<String?>(value: 'Genderless', child: Text('Senza sesso')),
                    ],
                    onChanged: isSaving ? null : onGenderChanged,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(selectedNature),
                    initialValue: selectedNature,
                    decoration: const InputDecoration(labelText: 'Natura'),
                    items: [
                      for (final nature in PokemonNature.names)
                        DropdownMenuItem<String>(value: nature, child: Text(nature)),
                    ],
                    onChanged: isSaving ? null : onNatureChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: initialHpController,
                    enabled: !isSaving,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'HP iniziali'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: formController,
                    enabled: !isSaving,
                    decoration: const InputDecoration(
                      labelText: 'Forma',
                      hintText: 'Opzionale',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: isShiny,
              onChanged: isSaving ? null : onShinyChanged,
              title: const Text('Shiny'),
              subtitle: const Text('Salva lo sprite shiny dove disponibile.'),
            ),
            const Divider(height: 22),
            DropdownButtonFormField<String?>(
              key: ValueKey(selectedBallId ?? 'none'),
              initialValue: selectedBallId,
              decoration: const InputDecoration(
                labelText: 'Poké Ball da consumare (facoltativo)',
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Nessuna / già consumata'),
                ),
                for (final ball in ownedPokeballs)
                  DropdownMenuItem<String?>(
                    value: ball.item.id,
                    child: Text('${ball.item.name}  x${ball.quantity}'),
                  ),
              ],
              onChanged: isSaving ? null : onBallChanged,
            ),
            if (selectedOwnedBall != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text('Ball usate da scalare: $ballQuantity'),
                  ),
                  IconButton(
                    onPressed: ballQuantity <= 1 || isSaving
                        ? null
                        : () => onQuantityChanged(ballQuantity - 1),
                    icon: const Icon(Icons.remove),
                  ),
                  IconButton(
                    onPressed: ballQuantity >= selectedMaxQuantity || isSaving
                        ? null
                        : () => onQuantityChanged(ballQuantity + 1),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: isSaving ? null : onRegister,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('REGISTRA CATTURA'),
                ),
                OutlinedButton.icon(
                  onPressed: isSaving ? null : onMarkSeen,
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
    required this.selected,
    required this.onSelect,
  });

  final Pokemon pokemon;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final number = '#${pokemon.id.toString().padLeft(3, '0')}';
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: selected ? colorScheme.primaryContainer : null,
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
          onPressed: onSelect,
          child: Text(selected ? 'Scelto' : 'Scegli'),
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
