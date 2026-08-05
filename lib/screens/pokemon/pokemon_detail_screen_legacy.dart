import 'package:flutter/material.dart';

import '../../localization/ui_text.dart';
import '../../localization/feat_display_name.dart';
import '../../localization/pokemon_form_localization.dart';
import '../../models/bag_item.dart';
import '../../models/evolution_data.dart';
import '../../models/item_driven_pokemon_form.dart';
import '../../models/level_progression.dart';
import '../../models/move_data.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_nature.dart';
import '../../models/team_slot.dart';
import '../../models/trainer_ui_localization.dart';
import '../../models/user_profile.dart';
import '../../repositories/ability_repository.dart';
import '../../repositories/bag_inventory_repository.dart';
import '../../repositories/evolution_repository.dart';
import '../../repositories/feat_repository.dart';
import '../../repositories/item_repository.dart';
import '../../repositories/move_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/pokemon_repository.dart';
import '../../services/battle_form_change_service.dart';
import '../../services/custom_pokemon_discovery_service.dart';
import '../../services/custom_pokemon_runtime_registry.dart';
import '../../services/evolution_catalog_resolver.dart';
import '../../services/evolution_service.dart';
import '../../services/trainer_path_passive_service.dart';
import '../../widgets/layout/responsive_content.dart';
import '../../widgets/pokemon/pokemon_asset_image.dart';
import '../../widgets/trainer/trainer_path_passive_card.dart';
import 'evolution_selector_sheet.dart';
import 'pokemon_edit_screen.dart';

class PokemonDetailScreen extends StatefulWidget {
  const PokemonDetailScreen({
    super.key,
    required this.pokemon,
    this.teamSlot,
    this.allPokemon = const [],
    this.team = const [],
    this.onTeamSlotChanged,
  });

  final Pokemon pokemon;
  final TeamSlot? teamSlot;
  final List<Pokemon> allPokemon;
  final List<TeamSlot> team;
  final ValueChanged<TeamSlot>? onTeamSlotChanged;

  @override
  State<PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}

class _StatusEffectInfo {
  const _StatusEffectInfo({
    required this.name,
    required this.displayName,
    required this.shortLabel,
    required this.description,
    required this.assetCandidates,
  });

  final String name;
  final String displayName;
  final String shortLabel;
  final String description;
  final List<String> assetCandidates;
}

final _statusEffectInfos = [
  _StatusEffectInfo(
    name: 'Asleep',
    displayName: 'Addormentato',
    shortLabel: 'SLP',
    description: uiTextForLanguage(
      'È incapacitato e trattenuto e ha svantaggio a tutti i tiri salvezza. Dura tre round. Quando subisce un movimento forzato e alla fine di ciascun suo turno, tira 1d20: con 11 o più la condizione termina.',
      """It is incapacitated and restrained and has disadvantage on all saving throws. It lasts three rounds. When it is forcibly moved and at the end of each of its turns, roll 1d20: on 11 or higher, the condition ends.""",
    ),
    assetCandidates: [
      'assets/textures/gui/status/sleep_down.png',
      'assets/textures/gui/status/sleep_up.png',
    ],
  ),
  _StatusEffectInfo(
    name: 'Burned',
    displayName: 'Scottato',
    shortLabel: 'BRN',
    description: uiTextForLanguage(
      'Tira due volte tutti i dadi di danno e usa il risultato inferiore. Finché non viene curato o perde i sensi, subisce danni pari al proprio bonus di competenza alla fine di ciascun turno. I Pokémon di tipo Fuoco sono immuni.',
      """Roll all damage dice twice and use the lower result. Until cured or unconscious, it takes damage equal to its proficiency bonus at the end of each turn. Fire-type Pokémon are immune.""",
    ),
    assetCandidates: [
      'assets/textures/gui/status/burn_down.png',
      'assets/textures/gui/status/burn_up.png',
    ],
  ),
  _StatusEffectInfo(
    name: 'Confused',
    displayName: 'Confuso',
    shortLabel: 'CNF',
    description: uiTextForLanguage(
      "Non può effettuare reazioni. Dura tre round. All'inizio del suo turno tira 1d8 per determinarne il comportamento; con 8 la condizione termina.",
      """It cannot take reactions. It lasts three rounds. At the start of its turn, roll 1d8 to determine its behavior; on 8, the condition ends.""",
    ),
    assetCandidates: [
      'assets/textures/gui/status/confuse_down.png',
      'assets/textures/gui/status/confuse_up.png',
    ],
  ),
  _StatusEffectInfo(
    name: 'Flinched',
    displayName: 'Tentennamento',
    shortLabel: 'FLN',
    description: uiTextForLanguage(
      'Ha svantaggio a tutti i tiri per colpire, alle prove di caratteristica e ai tiri salvezza fino alla fine del suo prossimo turno. È mostrato solo come riferimento e non può essere selezionato manualmente.',
      """It has disadvantage on all attack rolls, ability checks and saving throws until the end of its next turn. It is shown for reference only and cannot be selected manually.""",
    ),
    assetCandidates: [],
  ),
  _StatusEffectInfo(
    name: 'Frozen',
    displayName: 'Congelato',
    shortLabel: 'FRZ',
    description: uiTextForLanguage(
      'È incapacitato e trattenuto. La condizione termina se si libera, subisce danni di tipo Fuoco o viene colpito da una mossa che può provocare Scottatura. I Pokémon di tipo Ghiaccio sono immuni.',
      """It is incapacitated and restrained. The condition ends if it breaks free, takes Fire-type damage or is hit by a move that can cause Burn. Ice-type Pokémon are immune.""",
    ),
    assetCandidates: [
      'assets/textures/gui/status/frozen_down.png',
      'assets/textures/gui/status/frozen_up.png',
    ],
  ),
  _StatusEffectInfo(
    name: 'Paralyzed',
    displayName: 'Paralizzato',
    shortLabel: 'PAR',
    description: uiTextForLanguage(
      'Ha svantaggio ai tiri salvezza su FOR e DES e si muove a velocità dimezzata. All’inizio del suo turno tira 1d4: con 1 è incapacitato e trattenuto fino all’inizio del turno successivo. I Pokémon di tipo Elettro sono immuni.',
      """It has disadvantage on STR and DEX saving throws and moves at half speed. At the start of its turn, roll 1d4: on 1, it is incapacitated and restrained until the start of its next turn. Electric-type Pokémon are immune.""",
    ),
    assetCandidates: [
      'assets/textures/gui/status/paralyze_down.png',
      'assets/textures/gui/status/paralyze_up.png',
    ],
  ),
  _StatusEffectInfo(
    name: 'Poisoned',
    displayName: 'Avvelenato',
    shortLabel: 'PSN',
    description: uiTextForLanguage(
      'Ha svantaggio a tutte le prove di caratteristica e ai tiri per colpire. Finché non viene curato o perde i sensi, subisce danni pari al proprio bonus di competenza alla fine di ciascun turno. I Pokémon di tipo Veleno e Acciaio sono immuni.',
      """It has disadvantage on all ability checks and attack rolls. Until cured or unconscious, it takes damage equal to its proficiency bonus at the end of each turn. Poison- and Steel-type Pokémon are immune.""",
    ),
    assetCandidates: [
      'assets/textures/gui/status/poisoned_down.png',
      'assets/textures/gui/status/poisoned_up.png',
    ],
  ),
];

Map<String, _StatusEffectInfo> get _statusEffectInfoByName => {
  for (final info in _statusEffectInfos) info.name: info,
};

class _PokemonDetailScreenState extends State<PokemonDetailScreen> {
  final MoveRepository _moveRepository = MoveRepository();
  final AbilityRepository _abilityRepository = AbilityRepository();
  final EvolutionRepository _evolutionRepository = EvolutionRepository();
  final FeatRepository _featRepository = FeatRepository();
  final BagInventoryRepository _bagInventoryRepository =
      BagInventoryRepository();
  final ItemRepository _itemRepository = ItemRepository();
  final ProfileRepository _profileRepository = ProfileRepository();
  final EvolutionCatalogResolver _evolutionCatalogResolver =
      const EvolutionCatalogResolver();
  final EvolutionService _evolutionService = const EvolutionService();
  final CustomPokemonDiscoveryService _customDiscoveryService =
      CustomPokemonDiscoveryService();

  late Pokemon _basePokemon;
  late Pokemon _pokemon;
  late List<TeamSlot> _team;
  TeamSlot? _teamSlot;
  UserProfile? _profile;
  Map<String, MoveData?> _moves = {};
  Map<String, String> _abilities = {};
  Map<String, String> _abilityDisplayNames = {};
  Map<String, String> _featDescriptions = {};
  Map<String, String> _featDisplayNames = {};
  Map<String, BagItem> _itemCatalog = {};
  Map<String, EvolutionData> _evolutions = {};
  List<EvolutionEligibility> _evolutionChoices = const [];
  bool _isLoading = true;
  String? _message;

  bool get _isPartyMode => _teamSlot != null;
  int get _experience => _teamSlot?.experience ?? 0;
  int get _level => _teamSlot == null
      ? _pokemon.minLevelFound
      : LevelProgression.levelFromExperience(_experience);
  int get _loyalty => (_teamSlot?.loyalty ?? 0).clamp(-3, 3).toInt();
  int get _savingThrowLoyaltyBonus =>
      TrainerPathPassiveService.loyaltySavingThrowBonus(
        profile: _profile,
        loyalty: _loyalty,
      );
  List<String> get _currentStatusEffects =>
      _teamSlot?.statusEffects ?? const [];

  int get _maxHp => _maxHpFor(_pokemon, _teamSlot);

  int get _currentHp {
    final savedHp = _teamSlot?.currentHp ?? 0;
    return savedHp.clamp(0, _maxHp).toInt();
  }

  int get _armorClass {
    final natureScores = PokemonNature.forName(
      _teamSlot?.nature ?? 'No Nature',
    );
    return _pokemon.armorClass + (natureScores['AC'] ?? 0);
  }

  @override
  void initState() {
    super.initState();
    _basePokemon = widget.pokemon;
    _team = [...widget.team];
    _teamSlot = widget.teamSlot;
    _pokemon = _basePokemon.resolveVariant(
      formName: _teamSlot?.effectiveFormName,
      gender: _teamSlot?.gender,
    );
    _ensureSelectedMovesIsSaved();
    _loadData();
  }

  int _maxHpFor(Pokemon pokemon, TeamSlot? slot) {
    return TrainerPathPassiveService.maxHp(
      profile: _profile,
      pokemon: pokemon,
      slot: slot,
      level: slot == null
          ? pokemon.minLevelFound
          : LevelProgression.levelFromExperience(slot.experience),
    );
  }

  void _replaceTeamSlot(TeamSlot updatedSlot) {
    final index = _team.indexWhere(
      (slot) => slot.slotIndex == updatedSlot.slotIndex,
    );
    if (index == -1) {
      _team = [..._team, updatedSlot];
      return;
    }

    _team = [..._team]..[index] = updatedSlot;
  }

  void _saveTeamSlot(TeamSlot updatedSlot) {
    setState(() {
      _teamSlot = updatedSlot;
      _pokemon = _basePokemon.resolveVariant(
        formName: updatedSlot.effectiveFormName,
        gender: updatedSlot.gender,
      );
      _replaceTeamSlot(updatedSlot);
    });
    widget.onTeamSlotChanged?.call(updatedSlot);
    _refreshEvolutionChoices();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    setState(() => _message = message);
  }

  Future<void> _loadData() async {
    final moveNames = <String>{
      ..._pokemon.moves.startingMoves,
      ..._pokemon.moves.levelMoves.values.expand((moves) => moves),
      ...?_teamSlot?.selectedMoves,
      ..._defaultSelectedMoves(_pokemon, _level),
      'Struggle',
    };

    final results = await Future.wait([
      _moveRepository.getMoves(moveNames, pokemonId: _pokemon.id),
      _abilityRepository.getAbilityDescriptions(pokemonId: _pokemon.id),
      _abilityRepository.getAbilityDisplayNames(pokemonId: _pokemon.id),
      _evolutionRepository.getEvolutionData(),
      _featRepository.getFeatDescriptions(),
      _featRepository.getFeatDisplayNames(),
      _itemRepository.getWebItems(),
      _profileRepository.getActiveProfile(),
    ]);

    final evolutions = results[3] as Map<String, EvolutionData>;
    final items = results[6] as List<BagItem>;
    final evolutionChoices = await _buildEvolutionChoices(
      evolution: _evolutionForPokemon(_pokemon, evolutions),
      slot: _teamSlot,
    );

    if (!mounted) return;

    setState(() {
      _moves = results[0] as Map<String, MoveData?>;
      _abilities = results[1] as Map<String, String>;
      _abilityDisplayNames = results[2] as Map<String, String>;
      _evolutions = evolutions;
      _featDescriptions = results[4] as Map<String, String>;
      _featDisplayNames = results[5] as Map<String, String>;
      _itemCatalog = {for (final item in items) item.id: item};
      _profile = results[7] as UserProfile;
      _evolutionChoices = evolutionChoices;
      _isLoading = false;
    });
  }

  Future<void> _refreshEvolutionChoices() async {
    final choices = await _buildEvolutionChoices(
      evolution: _evolutionForCurrentPokemon(),
      slot: _teamSlot,
    );
    if (!mounted) return;
    setState(() => _evolutionChoices = choices);
  }

  Future<List<EvolutionEligibility>> _buildEvolutionChoices({
    required EvolutionData? evolution,
    required TeamSlot? slot,
  }) async {
    if (!_isPartyMode || evolution == null || slot == null) return const [];

    final profile = await _profileRepository.getActiveProfile();
    final inventory = await _bagInventoryRepository.getInventory(profile.id);
    final itemCatalog = await _itemRepository.getWebItems();

    return _evolutionService.evaluateOptions(
      pokemon: _pokemon,
      slot: slot,
      evolution: evolution,
      inventory: inventory,
      itemCatalog: itemCatalog,
      trainerMoney: profile.money,
    );
  }

  List<String> _learnedMovesFor(Pokemon pokemon, int level) {
    final names = <String>[...pokemon.moves.startingMoves];
    final levelEntries =
        pokemon.moves.levelMoves.entries
            .where((entry) => entry.key <= level)
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in levelEntries) {
      names.addAll(entry.value);
    }

    return names.toSet().toList();
  }

  List<String> _defaultSelectedMoves(Pokemon pokemon, int level) {
    return _learnedMovesFor(pokemon, level).take(4).toList();
  }

  List<String> _selectedMoves() {
    final slot = _teamSlot;
    if (slot == null || slot.selectedMoves.isEmpty) {
      return _defaultSelectedMoves(_pokemon, _level);
    }
    return slot.selectedMoves.take(4).toList();
  }

  void _ensureSelectedMovesIsSaved() {
    final slot = _teamSlot;
    if (slot == null || slot.selectedMoves.isNotEmpty) return;

    final updatedSlot = slot.copyWith(
      selectedMoves: _defaultSelectedMoves(_pokemon, _level),
    );
    _teamSlot = updatedSlot;
    _replaceTeamSlot(updatedSlot);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onTeamSlotChanged?.call(updatedSlot);
    });
  }

  Future<void> _editExperience() async {
    final slot = _teamSlot;
    if (slot == null) return;

    final oldMaxHp = _maxHp;
    final oldCurrentHp = _currentHp;
    final wasFullHp = oldCurrentHp >= oldMaxHp;

    final input = await showDialog<String>(
      context: context,
      builder: (_) => _ExperienceDialog(currentExperience: slot.experience),
    );
    if (!mounted || input == null) return;

    final oldLevel = LevelProgression.levelFromExperience(slot.experience);
    final updatedExperience = LevelProgression.applyExperienceInput(
      currentExperience: slot.experience,
      input: input,
    );
    final newLevel = LevelProgression.levelFromExperience(updatedExperience);
    var updatedSlot = slot.copyWith(experience: updatedExperience);

    final scaledMaxHp = _maxHpFor(_pokemon, updatedSlot);
    updatedSlot = updatedSlot.copyWith(
      currentHp: wasFullHp
          ? scaledMaxHp
          : oldCurrentHp.clamp(0, scaledMaxHp).toInt(),
    );

    if (newLevel > oldLevel) {
      updatedSlot = await _applyLevelUpMoves(updatedSlot, oldLevel, newLevel);
      if (!mounted) return;
      updatedSlot = await _applyLevelUpAbilityScores(
        updatedSlot,
        oldLevel,
        newLevel,
      );
      if (!mounted) return;
    }

    final finalMaxHp = _maxHpFor(_pokemon, updatedSlot);
    updatedSlot = updatedSlot.copyWith(
      currentHp: wasFullHp
          ? finalMaxHp
          : updatedSlot.currentHp.clamp(0, finalMaxHp).toInt(),
    );

    _saveTeamSlot(updatedSlot);
    await _loadData();
  }

  Future<void> _editHp() async {
    final slot = _teamSlot;
    if (slot == null) return;

    final input = await showDialog<String>(
      context: context,
      builder: (_) => _HpDialog(currentHp: _currentHp, maxHp: _maxHp),
    );
    if (!mounted || input == null) return;

    final updatedHp = _applyHpInput(
      currentHp: _currentHp,
      maxHp: _maxHp,
      input: input,
    );
    _saveTeamSlot(slot.copyWith(currentHp: updatedHp));
  }

  int _applyHpInput({
    required int currentHp,
    required int maxHp,
    required String input,
  }) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return currentHp;

    final value = int.tryParse(trimmed);
    if (value == null) return currentHp;

    if (trimmed.startsWith('+') || trimmed.startsWith('-')) {
      return (currentHp + value).clamp(0, maxHp).toInt();
    }

    return value.clamp(0, maxHp).toInt();
  }

  void _changeHp(int delta) {
    final slot = _teamSlot;
    if (slot == null) return;

    final updatedHp = (_currentHp + delta).clamp(0, _maxHp).toInt();
    _saveTeamSlot(slot.copyWith(currentHp: updatedHp));
  }

  void _changeLoyalty(int delta) {
    final slot = _teamSlot;
    if (slot == null) return;

    final oldMaxHp = _maxHp;
    final oldCurrentHp = _currentHp;
    final wasFullHp = oldCurrentHp >= oldMaxHp;
    final updatedLoyalty = (slot.loyalty + delta).clamp(-3, 3).toInt();
    final updatedSlot = slot.copyWith(loyalty: updatedLoyalty);
    final updatedMaxHp = _maxHpFor(_pokemon, updatedSlot);
    final updatedHp = wasFullHp
        ? updatedMaxHp
        : oldCurrentHp.clamp(0, updatedMaxHp).toInt();

    _saveTeamSlot(updatedSlot.copyWith(currentHp: updatedHp));
  }

  void _setStatusEffects(List<String> statuses) {
    final slot = _teamSlot;
    if (slot == null) return;
    _saveTeamSlot(slot.copyWith(statusEffects: statuses));
  }

  Future<void> _usePokemonCenter() async {
    final slot = _teamSlot;
    if (slot == null) return;

    final shouldHeal = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _PokemonCenterDialog(),
    );
    if (!mounted || shouldHeal != true) return;

    _saveTeamSlot(slot.copyWith(currentHp: _maxHp, statusEffects: const []));
    _showMessage(
      uiTextForLanguage(
        '${_pokemon.name} è stato curato al Pokémon Center.',
        """${_pokemon.name} was healed at the Pokémon Center.""",
      ),
    );
  }

  String _heldItemDisplayLabel() {
    final heldItem = _teamSlot?.heldItem;
    if (heldItem == null || heldItem.trim().isEmpty) {
      return uiTextForLanguage('NESSUNO', 'NONE');
    }

    return _itemByReference(heldItem)?.name.toUpperCase() ??
        heldItem.toUpperCase();
  }

  BagItem? _itemByReference(String reference) {
    final trimmed = reference.trim();
    if (trimmed.isEmpty) return null;

    final direct = _itemCatalog[trimmed];
    if (direct != null) return direct;

    final target = _itemReferenceKey(trimmed);
    for (final item in _itemCatalog.values) {
      if (_itemReferenceKey(item.id) == target ||
          _itemReferenceKey(item.name) == target) {
        return item;
      }
    }

    return null;
  }

  Future<void> _changeHeldItemFromDetail() async {
    final slot = _teamSlot;
    if (slot == null) return;

    final profile = await _profileRepository.getActiveProfile();
    final inventory = await _bagInventoryRepository.getInventory(profile.id);
    final catalog = _itemCatalog.isEmpty
        ? {
            for (final item in await _itemRepository.getWebItems())
              item.id: item,
          }
        : _itemCatalog;

    final options = <_HeldItemInventoryOption>[];
    for (final entry in inventory) {
      final item = catalog[entry.itemId];
      if (item == null) continue;
      if (item.type != 'held-item' && item.type != 'berry') continue;
      options.add(
        _HeldItemInventoryOption(item: item, quantity: entry.quantity),
      );
    }
    options.sort((a, b) => a.item.name.compareTo(b.item.name));

    final currentItem = slot.heldItem == null
        ? null
        : _itemByReference(slot.heldItem!);

    if (!mounted) return;

    final selection = await showModalBottomSheet<_HeldItemSelection>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) =>
          _HeldItemPickerSheet(currentItem: currentItem, options: options),
    );

    if (!mounted || selection == null) return;

    if (selection.clear) {
      if (currentItem != null) {
        await _bagInventoryRepository.addItem(
          profileId: profile.id,
          itemId: currentItem.id,
        );
      }

      _saveTeamSlot(slot.copyWith(heldItem: null));
      _showMessage(
        uiTextForLanguage(
          '${_pokemon.name} non tiene più strumenti.',
          """${_pokemon.name} is no longer holding an item.""",
        ),
      );
      await _loadData();
      return;
    }

    final selectedItem = selection.item;
    if (selectedItem == null) return;

    if (currentItem?.id == selectedItem.id) {
      _showMessage(
        uiTextForLanguage(
          '${_pokemon.name} tiene già ${selectedItem.name}.',
          """${_pokemon.name} is already holding ${selectedItem.name}.""",
        ),
      );
      return;
    }

    final consumed = await _bagInventoryRepository.consumeItem(
      profileId: profile.id,
      itemId: selectedItem.id,
    );
    if (!consumed) {
      _showMessage(
        uiTextForLanguage(
          'Non hai più ${selectedItem.name} nello zaino.',
          """You no longer have ${selectedItem.name} in the Bag.""",
        ),
      );
      return;
    }

    if (currentItem != null) {
      await _bagInventoryRepository.addItem(
        profileId: profile.id,
        itemId: currentItem.id,
      );
    }

    _saveTeamSlot(slot.copyWith(heldItem: selectedItem.id));
    final replacementText = currentItem == null
        ? ''
        : uiTextForLanguage(
            ' ${currentItem.name} è tornato nello zaino.',
            """ ${currentItem.name} was returned to the Bag.""",
          );
    _showMessage(
      '${_pokemon.name} ora tiene ${selectedItem.name}.$replacementText',
    );
    await _loadData();
  }

  Future<void> _pickStatusEffect() async {
    if (_teamSlot == null) return;

    final current = _currentStatusEffects;
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 12),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Text(
                context.uiText('AGGIUNGI STATUS', 'ADD STATUS'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            for (final info in _statusEffectInfos.where(
              (info) => info.name != 'Flinched',
            ))
              CheckboxListTile(
                secondary: _StatusIcon(info: info, size: 28),
                title: Text(info.displayName.toUpperCase()),
                subtitle: Text(info.description),
                value: current.contains(info.name),
                onChanged: (_) => Navigator.of(context).pop(info.name),
              ),
            ListTile(
              leading: _StatusIcon(
                info: _statusEffectInfoByName['Flinched'],
                size: 28,
              ),
              title: Text(
                _statusEffectInfoByName['Flinched']!.displayName.toUpperCase(),
              ),
              subtitle: Text(_statusEffectInfoByName['Flinched']!.description),
            ),
            if (current.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.clear),
                title: Text(
                  context.uiText(
                    'RIMUOVI TUTTI GLI STATUS',
                    'REMOVE ALL STATUSES',
                  ),
                ),
                onTap: () => Navigator.of(context).pop('__clear__'),
              ),
          ],
        ),
      ),
    );

    if (!mounted || result == null) return;
    if (result == '__clear__') {
      _setStatusEffects([]);
      return;
    }

    final updated = [...current];
    if (updated.contains(result)) {
      updated.remove(result);
    } else {
      updated.add(result);
    }
    _setStatusEffects(updated);
  }

  Future<TeamSlot> _applyLevelUpMoves(
    TeamSlot slot,
    int oldLevel,
    int newLevel,
  ) async {
    var selectedMoves = slot.selectedMoves.isEmpty
        ? _defaultSelectedMoves(_pokemon, oldLevel)
        : slot.selectedMoves.take(4).toList();

    final learnedEntries =
        _pokemon.moves.levelMoves.entries
            .where((entry) => entry.key > oldLevel && entry.key <= newLevel)
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in learnedEntries) {
      for (final move in entry.value) {
        if (selectedMoves.contains(move)) continue;
        if (selectedMoves.length < 4) {
          selectedMoves.add(move);
          continue;
        }

        final moveData = _moves[move] ?? await _moveRepository.getMove(move);
        if (!mounted) return slot.copyWith(selectedMoves: selectedMoves);

        final replacedMove = await _askMoveReplacement(
          move,
          selectedMoves,
          moveData,
        );
        if (replacedMove == null) continue;

        final replaceIndex = selectedMoves.indexOf(replacedMove);
        if (replaceIndex >= 0) selectedMoves[replaceIndex] = move;
      }
    }

    return slot.copyWith(selectedMoves: selectedMoves);
  }

  Future<TeamSlot> _applyLevelUpAbilityScores(
    TeamSlot slot,
    int oldLevel,
    int newLevel,
  ) async {
    if (_asiMilestoneCountForLevel(newLevel) <=
        _asiMilestoneCountForLevel(oldLevel)) {
      return slot;
    }

    var updatedSlot = slot;

    while (_availableAsiPointsForSlot(updatedSlot) > 0) {
      final remaining = _availableAsiPointsForSlot(updatedSlot);
      final attribute = await _pickAbilityScoreIncrease(updatedSlot, remaining);
      if (!mounted || attribute == null) break;

      final currentAttributes = _attributeScores(_pokemon, updatedSlot);
      if ((currentAttributes[attribute] ?? 0) >= 20) continue;

      final customScores = Map<String, int>.from(
        updatedSlot.customAbilityScores,
      );
      customScores[attribute] = (customScores[attribute] ?? 0) + 1;
      updatedSlot = updatedSlot.copyWith(customAbilityScores: customScores);
    }

    return updatedSlot;
  }

  int _availableAsiPointsForSlot(TeamSlot slot) {
    final level = LevelProgression.levelFromExperience(slot.experience);
    final evolution = _evolutionForCurrentPokemon();
    final totalStages = (evolution?.totalStages ?? 1).clamp(1, 5).toInt();
    final pointsPerMilestone = (5 - totalStages).clamp(0, 4).toInt();
    final earnedPoints = _asiMilestoneCountForLevel(level) * pointsPerMilestone;
    final spentPoints = slot.customAbilityScores.values
        .where((value) => value > 0)
        .fold<int>(0, (sum, value) => sum + value);

    return (earnedPoints - spentPoints).clamp(0, 999).toInt();
  }

  int _asiMilestoneCountForLevel(int level) {
    if (level >= 20) return 5;
    if (level >= 16) return 4;
    if (level >= 12) return 3;
    if (level >= 8) return 2;
    if (level >= 4) return 1;
    return 0;
  }

  Future<String?> _pickAbilityScoreIncrease(
    TeamSlot slot,
    int remainingPoints,
  ) async {
    final attributes = _attributeScores(_pokemon, slot);
    const labels = ['STR', 'DEX', 'CON', 'INT', 'WIS', 'CHA'];

    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Aumento di Caratteristica'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                uiTextForLanguage(
                  'Punti disponibili: $remainingPoints',
                  """Available points: $remainingPoints""",
                ),
              ),
              const SizedBox(height: 8),
              for (final label in labels)
                ListTile(
                  title: Text(TrainerUiLocalization.abilityAbbreviation(label)),
                  subtitle: Text(
                    '${attributes[label] ?? 0} → ${(attributes[label] ?? 0) + 1}',
                  ),
                  enabled: (attributes[label] ?? 0) < 20,
                  onTap: (attributes[label] ?? 0) >= 20
                      ? null
                      : () => Navigator.of(context).pop(label),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(uiTextForLanguage('Più tardi', """Later""")),
          ),
        ],
      ),
    );
  }

  Future<void> _distributePendingAsi() async {
    final slot = _teamSlot;
    if (slot == null) return;

    final oldMaxHp = _maxHp;
    final oldCurrentHp = _currentHp;
    final wasFullHp = oldCurrentHp >= oldMaxHp;
    var updatedSlot = slot;

    while (_availableAsiPointsForSlot(updatedSlot) > 0) {
      final remaining = _availableAsiPointsForSlot(updatedSlot);
      final attribute = await _pickAbilityScoreIncrease(updatedSlot, remaining);
      if (!mounted || attribute == null) break;

      final currentAttributes = _attributeScores(_pokemon, updatedSlot);
      if ((currentAttributes[attribute] ?? 0) >= 20) continue;

      final customScores = Map<String, int>.from(
        updatedSlot.customAbilityScores,
      );
      customScores[attribute] = (customScores[attribute] ?? 0) + 1;
      updatedSlot = updatedSlot.copyWith(customAbilityScores: customScores);
    }

    final updatedMaxHp = _maxHpFor(_pokemon, updatedSlot);
    updatedSlot = updatedSlot.copyWith(
      currentHp: wasFullHp
          ? updatedMaxHp
          : oldCurrentHp.clamp(0, updatedMaxHp).toInt(),
    );

    _saveTeamSlot(updatedSlot);
    await _loadData();
  }

  Future<String?> _askMoveReplacement(
    String newMove,
    List<String> selectedMoves,
    MoveData? moveData,
  ) async {
    final localizedNewMove = moveData?.name ?? _moveLabel(newMove);

    return showDialog<String?>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          context.uiText(
            'Vuoi imparare $localizedNewMove?',
            'Do you want to learn $localizedNewMove?',
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MoveCard(
                reference: newMove,
                move: moveData,
                moveType: moveData == null
                    ? null
                    : _effectiveMoveType(moveData),
                stats: moveData == null ? null : _moveStats(moveData),
              ),
              const SizedBox(height: 8),
              Text(
                uiTextForLanguage(
                  'Il moveset è già pieno. Scegli una mossa da dimenticare.',
                  """The move set is full. Choose a move to forget.""",
                ),
              ),
            ],
          ),
        ),
        actions: [
          for (final move in selectedMoves)
            TextButton(
              onPressed: () => Navigator.of(context).pop(move),
              child: Text(
                context.uiText(
                  'Dimentica ${_moveLabel(move)}',
                  'Forget ${_moveLabel(move)}',
                ),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              context.uiText(
                'Non imparare $localizedNewMove',
                'Do not learn $localizedNewMove',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Pokemon? _pokemonById(int? pokemonId) {
    if (pokemonId == null) return null;
    for (final pokemon in widget.allPokemon) {
      if (pokemon.id == pokemonId) return pokemon;
    }
    return null;
  }

  Pokemon? _pokemonByName(String name) {
    final targetKey = _referenceKey(name);
    for (final pokemon in widget.allPokemon) {
      if (pokemon.name == name || _referenceKey(pokemon.name) == targetKey) {
        return pokemon;
      }
    }
    for (final definition in CustomPokemonRuntimeRegistry.definitions) {
      if (definition.name == name ||
          _referenceKey(definition.name) == targetKey) {
        return definition.toPokemon();
      }
    }

    return null;
  }

  Pokemon? _pokemonForEvolutionOption(EvolutionOption option) {
    final targetId = option.targetPokemonId;
    if (targetId != null) {
      for (final pokemon in widget.allPokemon) {
        if (pokemon.id == targetId) return pokemon;
      }
      final custom = CustomPokemonRuntimeRegistry.definitionFor(targetId);
      if (custom != null) return custom.toPokemon();
    }
    final stable = CustomPokemonRuntimeRegistry.definitionByStableId(
      option.targetStableId,
    );
    return stable?.toPokemon() ??
        _evolutionCatalogResolver.targetPokemonFor(
          option: option,
          catalog: widget.allPokemon,
        ) ??
        _pokemonByName(option.toName);
  }

  String _referenceKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('♀', '-f')
        .replaceAll('♂', '-m')
        .replaceAll(RegExp(r"[’']"), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  Future<void> _openEditScreen() async {
    final slot = _teamSlot;
    if (slot == null) return;

    final result = await Navigator.of(context).push<PokemonEditResult>(
      MaterialPageRoute(
        builder: (_) => PokemonEditScreen(
          pokemon: _basePokemon,
          slot: slot,
          availableMoves: _learnedMovesFor(_pokemon, _level),
        ),
      ),
    );

    if (!mounted || result == null) return;

    _saveTeamSlot(result.slot);
    await _loadData();
  }

  EvolutionData? _evolutionForPokemon(
    Pokemon pokemon,
    Map<String, EvolutionData> evolutions,
  ) {
    return _evolutionCatalogResolver.evolutionFor(
      pokemon: pokemon,
      evolutions: evolutions,
    );
  }

  EvolutionData? _evolutionForCurrentPokemon() {
    return _evolutionForPokemon(_pokemon, _evolutions);
  }

  bool _canShowEvolutionButton() {
    return _isPartyMode && _evolutionChoices.isNotEmpty;
  }

  List<EvolutionEligibility> _availableEvolutionChoices() {
    return _evolutionChoices
        .where(
          (choice) =>
              choice.isAvailable &&
              _pokemonForEvolutionOption(choice.option) != null,
        )
        .toList(growable: false);
  }

  String? _evolutionLabel() {
    if (!_canShowEvolutionButton()) return null;

    final availableChoices = _availableEvolutionChoices();
    if (availableChoices.isEmpty) {
      return uiTextForLanguage(
        'REQUISITI EVOLUZIONE',
        'EVOLUTION REQUIREMENTS',
      );
    }
    if (availableChoices.length == 1) {
      return uiTextForLanguage('FAI EVOLVERE', 'EVOLVE');
    }
    return uiTextForLanguage('SCEGLI EVOLUZIONE', 'CHOOSE EVOLUTION');
  }

  Future<void> _evolveCurrentPokemon() async {
    final slot = _teamSlot;
    final evolution = _evolutionForCurrentPokemon();
    if (slot == null || evolution == null) return;

    final choices = await _buildEvolutionChoices(
      evolution: evolution,
      slot: slot,
    );
    if (!mounted) return;

    setState(() => _evolutionChoices = choices);

    if (choices.isEmpty) {
      _showMessage(
        uiTextForLanguage(
          'Nessuna evoluzione disponibile per ${_pokemon.name}.',
          """No evolution is available for ${_pokemon.name}.""",
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<EvolutionEligibility>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => EvolutionSelectorSheet(
        currentPokemon: _pokemon,
        choices: choices,
        pokemonByName: _pokemonByName,
        pokemonForOption: _pokemonForEvolutionOption,
      ),
    );

    if (!mounted || selected == null) return;

    await _evolveSlot(slot, selected);
  }

  Future<TeamSlot?> _evolveSlot(
    TeamSlot slot,
    EvolutionEligibility selected,
  ) async {
    if (!selected.isAvailable) return null;

    final targetName = PokemonFormLocalization.evolutionName(
      selected.option.toName,
    );
    final evolvedPokemon = _pokemonForEvolutionOption(selected.option);
    if (evolvedPokemon == null) {
      _showMessage(
        uiTextForLanguage(
          '$targetName non è presente nel catalogo attuale.',
          """${selected.option.toName} is not available in the current catalog.""",
        ),
      );
      return null;
    }

    final profile = await _profileRepository.getActiveProfile();
    final requiredMoney = selected.requiredMoney;
    if (requiredMoney > 0 && profile.money < requiredMoney) {
      _showMessage(
        uiTextForLanguage(
          'Servono ₽9.999 nel portafogli per questa evoluzione.',
          'You need ₽9,999 in your wallet for this evolution.',
        ),
      );
      await _refreshEvolutionChoices();
      return null;
    }

    final requiredItemId = selected.requiredItemId;
    if (requiredItemId != null) {
      final consumed = await _bagInventoryRepository.consumeItem(
        profileId: profile.id,
        itemId: requiredItemId,
      );
      if (!consumed) {
        _showMessage(
          uiTextForLanguage(
            'Oggetto evolutivo non disponibile nello zaino.',
            """The required evolution item is not available in the Bag.""",
          ),
        );
        return null;
      }
    }

    final wasFullHp = _currentHp >= _maxHp;
    final oldName = _pokemon.name;
    final evolvedMaxHp = _maxHpFor(evolvedPokemon, slot);
    final updatedSlot = slot.copyWith(
      pokemonId: evolvedPokemon.id,
      currentHp: wasFullHp
          ? evolvedMaxHp
          : _currentHp.clamp(0, evolvedMaxHp).toInt(),
      selectedMoves: List<String>.from(slot.selectedMoves),
      formName: selected.option.targetFormName,
    );

    var updatedProfile = profile;
    if (requiredMoney > 0) {
      updatedProfile = profile.copyWith(
        money: _evolutionService.moneyAfterSuccessfulEvolution(
          currentMoney: profile.money,
          eligibility: selected,
        ),
      );
      await _profileRepository.saveProfile(updatedProfile);
    }

    if (!mounted) return updatedSlot;

    setState(() {
      _basePokemon = evolvedPokemon;
      _pokemon = evolvedPokemon;
      _teamSlot = updatedSlot;
      _replaceTeamSlot(updatedSlot);
      _profile = updatedProfile;
      _isLoading = true;
      _message = uiTextForLanguage(
        '$oldName si è evoluto in $targetName!',
        """$oldName evolved into ${selected.option.toName}!""",
      );
    });

    widget.onTeamSlotChanged?.call(updatedSlot);
    final revealed = await _customDiscoveryService.revealByPokemonId(
      evolvedPokemon.id,
    );
    if (revealed) {
      PokemonRepository.clearCache();
      _showMessage(
        uiTextForLanguage(
          '$oldName si è evoluto in $targetName! Nuova specie scoperta.',
          """$oldName evolved into ${selected.option.toName}! New species discovered.""",
        ),
      );
    }
    await _loadData();

    return updatedSlot;
  }

  Future<void> _switchPartySlot(TeamSlot slot) async {
    final pokemon = _pokemonById(slot.pokemonId);
    if (pokemon == null) return;

    setState(() {
      _basePokemon = pokemon;
      _pokemon = pokemon.resolveVariant(
        formName: slot.effectiveFormName,
        gender: slot.gender,
      );
      _teamSlot = slot;
      _isLoading = true;
      _message = null;
      _evolutionChoices = const [];
    });
    _ensureSelectedMovesIsSaved();
    await _loadData();
  }

  int _modifier(int score) => ((score - 10) / 2).floor();

  int _proficiency(int level) {
    if (level >= 17) return 6;
    if (level >= 13) return 5;
    if (level >= 9) return 4;
    if (level >= 5) return 3;
    return 2;
  }

  Map<String, int> _attributeScores(Pokemon pokemon, TeamSlot? slot) {
    return TrainerPathPassiveService.effectiveAttributeScores(
      profile: _profile,
      pokemon: pokemon,
      slot: slot,
    );
  }

  int _bestMoveModifier(MoveData move) {
    final attributes = _attributeScores(_pokemon, _teamSlot);
    final modifiers = move.movePowers
        .where(attributes.containsKey)
        .map((power) => _modifier(attributes[power]!))
        .toList();

    if (modifiers.isEmpty) return 0;
    modifiers.sort();
    return modifiers.last;
  }

  String _moveStats(MoveData move) {
    final parts = <String>[];
    final effectiveMoveType = _effectiveMoveType(move);
    final moveModifier = _bestMoveModifier(move);
    final proficiency = _proficiency(_level);
    final attackPathBonus = TrainerPathPassiveService.attackRollBonus(
      profile: _profile,
      pokemon: _pokemon,
      slot: _teamSlot,
    );
    final damagePathBonus = TrainerPathPassiveService.damageRollBonus(
      profile: _profile,
      slot: _teamSlot,
    );
    final stab = TrainerPathPassiveService.stabEffect(
      profile: _profile,
      pokemon: _pokemon,
      slot: _teamSlot,
      move: move,
      pokemonLevel: _level,
      moveTypeOverride: effectiveMoveType,
    );

    if (move.isAttack) {
      final attackBonus = moveModifier + proficiency + attackPathBonus;
      parts.add('AB: ${attackBonus >= 0 ? '+' : ''}$attackBonus');
    }
    if (move.save != null) {
      parts.add('CD: ${8 + proficiency + moveModifier}');
    }

    final damage = move.damageForLevel(_level);
    if (damage != null) {
      final bonus = damagePathBonus == 0
          ? ''
          : ' ${damagePathBonus > 0 ? '+' : ''}$damagePathBonus';
      parts.add('${damage.label}$bonus');
    }
    if (stab.applies) {
      final source = stab.extendedByPath ? 'STAB esteso' : 'STAB';
      final bonus = stab.pathBonus == 0 ? '' : ' Path +${stab.pathBonus}';
      parts.add('$source$bonus');
    }
    if (move.range != '-') parts.add(move.range);
    if (move.duration != '-') parts.add(move.duration);

    return parts.join('  ||  ');
  }

  String _effectiveMoveType(MoveData move) {
    return ItemDrivenPokemonForm.effectiveMoveType(
      pokemonId: _teamSlot?.pokemonId ?? _pokemon.id,
      moveReference: move.technicalName,
      heldItem: _teamSlot?.heldItem,
      fallbackType: move.type,
    );
  }

  String _moveLabel(String reference) {
    return _moves[reference]?.name ?? reference;
  }

  @override
  Widget build(BuildContext context) {
    final pokemon = _pokemon;
    final attributes = _attributeScores(pokemon, _teamSlot);
    final evolutionLabel = _evolutionLabel();
    final savingThrows = TrainerPathPassiveService.savingThrowProficiencies(
      profile: _profile,
      pokemon: pokemon,
      slot: _teamSlot,
    );
    final passiveNotes = TrainerPathPassiveService.passiveNotes(
      profile: _profile,
      pokemon: pokemon,
      slot: _teamSlot,
    );
    final tabBar = TabBar(
      tabs: [
        Tab(text: context.uiText('MOSSE', 'MOVES')),
        Tab(text: context.uiText('PRIVILEGI', 'FEATURES')),
        Tab(text: context.uiText('TRATTI', 'TRAITS')),
      ],
    );

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_teamSlot?.nickname ?? pokemon.name),
          actions: [
            if (_isPartyMode)
              IconButton(
                tooltip: context.uiText('Modifica', 'Edit'),
                onPressed: _openEditScreen,
                icon: const Icon(Icons.edit),
              ),
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: NestedScrollView(
                      headerSliverBuilder: (context, innerBoxIsScrolled) => [
                        SliverToBoxAdapter(
                          child: _Header(
                            pokemon: pokemon,
                            imagePokemon: _basePokemon,
                            slot: _teamSlot,
                            level: _level,
                            armorClass: _armorClass,
                            experience: _experience,
                            currentHp: _currentHp,
                            maxHp: _maxHp,
                            loyalty: _loyalty,
                            isPartyMode: _isPartyMode,
                            attributes: attributes,
                            modifierBuilder: _modifier,
                            proficiency: _proficiency(_level),
                            savingThrowLoyaltyBonus: _savingThrowLoyaltyBonus,
                            savingThrows: savingThrows,
                            statusEffects: _currentStatusEffects,
                            message: _message,
                            heldItemLabel: _heldItemDisplayLabel(),
                            onEditExperience: _editExperience,
                            onEditHp: _editHp,
                            onDecreaseHp: () => _changeHp(-1),
                            onIncreaseHp: () => _changeHp(1),
                            onDecreaseLoyalty: () => _changeLoyalty(-1),
                            onIncreaseLoyalty: () => _changeLoyalty(1),
                            onPokemonCenter: _usePokemonCenter,
                            onAddStatusEffect: _pickStatusEffect,
                            onEditHeldItem: _changeHeldItemFromDetail,
                            evolutionLabel: evolutionLabel,
                            onEvolve: _evolveCurrentPokemon,
                          ),
                        ),
                        if (passiveNotes.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                              child: TrainerPathPassiveCard(
                                trainerPath: _profile?.trainerPath ?? '',
                                notes: passiveNotes,
                              ),
                            ),
                          ),
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _PokemonDetailTabBarDelegate(
                            tabBar: tabBar,
                          ),
                        ),
                      ],
                      body: TabBarView(
                        children: [
                          _MovesView(
                            selectedMoves: _selectedMoves(),
                            moves: _moves,
                            moveStatsBuilder: _moveStats,
                            moveTypeBuilder: _effectiveMoveType,
                          ),
                          _FeaturesView(
                            pokemon: pokemon,
                            slot: _teamSlot,
                            abilityDescriptions: _abilities,
                            abilityDisplayNames: _abilityDisplayNames,
                            featDescriptions: _featDescriptions,
                            featDisplayNames: _featDisplayNames,
                          ),
                          _TraitsView(
                            pokemon: pokemon,
                            basePokemon: _basePokemon,
                            slot: _teamSlot,
                            attributes: attributes,
                            modifierBuilder: _modifier,
                            proficiency: _proficiency(_level),
                            availableAsiPoints: _teamSlot == null
                                ? 0
                                : _availableAsiPointsForSlot(_teamSlot!),
                            onDistributeAsi: _distributePendingAsi,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isPartyMode)
                    SafeArea(
                      top: false,
                      child: _PartySwitcher(
                        team: _team,
                        currentSlotIndex: _teamSlot!.slotIndex,
                        pokemonById: _pokemonById,
                        onSelect: _switchPartySlot,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _PokemonDetailTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _PokemonDetailTabBarDelegate({required this.tabBar});

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      elevation: overlapsContent ? 2 : 0,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _PokemonDetailTabBarDelegate oldDelegate) {
    return oldDelegate.tabBar != tabBar;
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.pokemon,
    required this.imagePokemon,
    required this.slot,
    required this.level,
    required this.armorClass,
    required this.experience,
    required this.currentHp,
    required this.maxHp,
    required this.loyalty,
    required this.isPartyMode,
    required this.attributes,
    required this.modifierBuilder,
    required this.proficiency,
    required this.savingThrowLoyaltyBonus,
    required this.savingThrows,
    required this.statusEffects,
    required this.message,
    required this.heldItemLabel,
    required this.onEditExperience,
    required this.onEditHp,
    required this.onDecreaseHp,
    required this.onIncreaseHp,
    required this.onDecreaseLoyalty,
    required this.onIncreaseLoyalty,
    required this.onPokemonCenter,
    required this.onAddStatusEffect,
    required this.onEditHeldItem,
    required this.evolutionLabel,
    required this.onEvolve,
  });

  final Pokemon pokemon;
  final Pokemon imagePokemon;
  final TeamSlot? slot;
  final int level;
  final int armorClass;
  final int experience;
  final int currentHp;
  final int maxHp;
  final int loyalty;
  final bool isPartyMode;
  final Map<String, int> attributes;
  final int Function(int score) modifierBuilder;
  final int proficiency;
  final int savingThrowLoyaltyBonus;
  final List<String> savingThrows;
  final List<String> statusEffects;
  final String? message;
  final String heldItemLabel;
  final VoidCallback onEditExperience;
  final VoidCallback onEditHp;
  final VoidCallback onDecreaseHp;
  final VoidCallback onIncreaseHp;
  final VoidCallback onDecreaseLoyalty;
  final VoidCallback onIncreaseLoyalty;
  final VoidCallback onPokemonCenter;
  final VoidCallback onAddStatusEffect;
  final VoidCallback onEditHeldItem;
  final String? evolutionLabel;
  final VoidCallback onEvolve;

  @override
  Widget build(BuildContext context) {
    final number = '#${pokemon.id.toString().padLeft(3, '0')}';
    final nextThreshold = LevelProgression.nextThresholdForLevel(level);
    final currentThreshold = LevelProgression.thresholdForLevel(level);
    final range = nextThreshold - currentThreshold;
    final expProgress = range <= 0
        ? 1.0
        : ((experience - currentThreshold) / range).clamp(0.0, 1.0).toDouble();
    final hpProgress = maxHp <= 0
        ? 0.0
        : (currentHp / maxHp).clamp(0.0, 1.0).toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PokemonCenterButton(onTap: isPartyMode ? onPokemonCenter : null),
              const SizedBox(width: 6),
              Card(
                child: SizedBox(
                  width: 132,
                  height: 142,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      children: [
                        Expanded(
                          child: PokemonAssetImage(
                            pokemon: imagePokemon,
                            formName: slot?.effectiveFormName,
                            gender: slot?.gender,
                            isShiny: slot?.isShiny,
                            useLargeArtwork: true,
                            size: 112,
                          ),
                        ),
                        Text(
                          '$number ${pokemon.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      pokemon.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final type in pokemon.types)
                          PokemonTypeBadge(type: type, height: 20),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _LoyaltyRow(
                      loyalty: loyalty,
                      onDecrease: loyalty <= -3 ? null : onDecreaseLoyalty,
                      onIncrease: loyalty >= 3 ? null : onIncreaseLoyalty,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricBox(
                            label: context.uiText('Liv.', 'Lv.'),
                            value: '$level',
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _MetricBox(
                            label: context.uiText('CA:', 'AC:'),
                            value: '$armorClass',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: isPartyMode ? onEditExperience : null,
                      borderRadius: BorderRadius.circular(8),
                      child: _ProgressPanel(
                        label: 'EXP: $experience/$nextThreshold',
                        value: expProgress,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _FightStatsGrid(
            attributes: attributes,
            modifierBuilder: modifierBuilder,
          ),
          const SizedBox(height: 4),
          _SavingThrowsRow(
            attributes: attributes,
            savingThrows: savingThrows,
            modifierBuilder: modifierBuilder,
            proficiency: proficiency,
            loyaltyBonus: savingThrowLoyaltyBonus,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _StatusPanelButton(
                  statuses: statusEffects,
                  onTap: isPartyMode ? onAddStatusEffect : null,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: InkWell(
                  onTap: isPartyMode ? onEditHeldItem : null,
                  borderRadius: BorderRadius.circular(8),
                  child: _PanelButton(
                    label: context.uiText(
                      'STRUMENTO: $heldItemLabel',
                      'ITEM: $heldItemLabel',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _FightIconButton(icon: Icons.remove, onPressed: onDecreaseHp),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: isPartyMode ? onEditHp : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Text(
                          context.uiText(
                            'PF: $currentHp/$maxHp',
                            'HP: $currentHp/$maxHp',
                          ),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: hpProgress,
                              minHeight: 16,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _hpProgressColor(hpProgress),
                              ),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _FightIconButton(icon: Icons.add, onPressed: onIncreaseHp),
            ],
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            _InlineDetailMessage(message: message!),
          ],
          if (isPartyMode && evolutionLabel != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onEvolve,
                child: Text(evolutionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Color _hpProgressColor(double value) {
  if (value <= 0.25) return Colors.red;
  if (value <= 0.5) return Colors.amber;
  return Colors.green;
}

class _InlineDetailMessage extends StatelessWidget {
  const _InlineDetailMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colorScheme.onSecondaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _HeldItemInventoryOption {
  const _HeldItemInventoryOption({required this.item, required this.quantity});

  final BagItem item;
  final int quantity;
}

class _HeldItemSelection {
  const _HeldItemSelection._({this.item, this.clear = false});

  const _HeldItemSelection.item(BagItem item) : this._(item: item);
  const _HeldItemSelection.clear() : this._(clear: true);

  final BagItem? item;
  final bool clear;
}

class _DetailItemSprite extends StatelessWidget {
  const _DetailItemSprite({required this.item});

  final BagItem item;

  @override
  Widget build(BuildContext context) {
    final assetPath = item.spriteAssetPath;
    if (assetPath == null || !assetPath.startsWith('assets/')) {
      return Icon(_detailItemIconForType(item.type));
    }

    return SizedBox(
      width: 42,
      height: 42,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        errorBuilder: (_, __, ___) => Icon(_detailItemIconForType(item.type)),
      ),
    );
  }
}

IconData _detailItemIconForType(String type) {
  switch (type) {
    case 'berry':
      return Icons.eco_outlined;
    case 'held-item':
      return Icons.inventory_2_outlined;
    default:
      return Icons.category_outlined;
  }
}

class _HeldItemPickerSheet extends StatelessWidget {
  const _HeldItemPickerSheet({
    required this.currentItem,
    required this.options,
  });

  final BagItem? currentItem;
  final List<_HeldItemInventoryOption> options;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              uiTextForLanguage('Strumento tenuto', """Held item"""),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              uiTextForLanguage(
                'Scegli solo tra gli oggetti presenti nello zaino.',
                """Choose only from items available in the Bag.""",
              ),
            ),
            if (currentItem != null) ...[
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.remove_circle_outline),
                  title: Text('Togli ${currentItem!.name}'),
                  subtitle: Text(
                    uiTextForLanguage(
                      'Lo strumento torna nello zaino.',
                      """The item is returned to the Bag.""",
                    ),
                  ),
                  onTap: () => Navigator.of(
                    context,
                  ).pop(const _HeldItemSelection.clear()),
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (options.isEmpty)
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  uiTextForLanguage(
                    'Non hai strumenti tenuti o bacche nello zaino.',
                    """You do not have held items or berries in the Bag.""",
                  ),
                ),
              )
            else
              for (final option in options)
                Card(
                  child: ListTile(
                    leading: _DetailItemSprite(item: option.item),
                    title: Text(option.item.name),
                    subtitle: Text(
                      '${_detailItemTypeLabel(option.item.type)} • x${option.quantity}',
                    ),
                    onTap: () => Navigator.of(
                      context,
                    ).pop(_HeldItemSelection.item(option.item)),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

String _detailItemTypeLabel(String type) {
  switch (type) {
    case 'berry':
      return uiTextForLanguage('Bacca', """Berry""");
    case 'held-item':
      return uiTextForLanguage('Oggetto tenuto', """Held item""");
    default:
      return type;
  }
}

String _itemReferenceKey(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r"[’']"), '')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

class _PokemonCenterButton extends StatelessWidget {
  const _PokemonCenterButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 46,
        height: 142,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 32,
              child: Center(
                child: Icon(Icons.local_hospital, color: colorScheme.primary),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      uiTextForLanguage('POKÉMON CENTER', """POKÉMON CENTER"""),
                      maxLines: 1,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 9.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PokemonCenterDialog extends StatelessWidget {
  const _PokemonCenterDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(uiTextForLanguage('Pokémon Center', """Pokémon Center""")),
      content: Text(
        context.uiText(
          'Vuoi curare completamente questo Pokémon?',
          'Fully heal this Pokémon?',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('NO'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(context.uiText('SÌ', 'YES')),
        ),
      ],
    );
  }
}

class _LoyaltyRow extends StatelessWidget {
  const _LoyaltyRow({
    required this.loyalty,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int loyalty;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FightIconButton(icon: Icons.remove, onPressed: onDecrease),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  context.uiText('LEALTÀ', 'LOYALTY'),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                Text(
                  _signed(loyalty),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        _FightIconButton(icon: Icons.add, onPressed: onIncrease),
      ],
    );
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _PanelButton(label: '$label $value');
  }
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: textScaleAwareValue(
        context,
        normal: 46,
        enlarged: 62,
      ),
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.primary, width: 1.5),
      ),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          LinearProgressIndicator(value: value, minHeight: 6),
        ],
      ),
    );
  }
}

class _PanelButton extends StatelessWidget {
  const _PanelButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: textScaleAwareValue(
          context,
          normal: 36,
          enlarged: 50,
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: label.startsWith('+')
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _FightIconButton extends StatelessWidget {
  const _FightIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton.filled(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(icon, size: 26),
      ),
    );
  }
}

class _FightStatsGrid extends StatelessWidget {
  const _FightStatsGrid({
    required this.attributes,
    required this.modifierBuilder,
  });

  final Map<String, int> attributes;
  final int Function(int score) modifierBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final compactAspectRatio = textScaleAwareValue(
          context,
          normal: 1.85,
          enlarged: 1.1,
        );
        final wideAspectRatio = textScaleAwareValue(
          context,
          normal: 1.18,
          enlarged: 0.82,
        );
        return GridView.count(
          crossAxisCount: compact ? 3 : 6,
          childAspectRatio: compact
              ? compactAspectRatio
              : wideAspectRatio,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final entry in attributes.entries)
              _FightStatBox(
                label: TrainerUiLocalization.abilityAbbreviation(entry.key),
                score: entry.value,
                modifier: modifierBuilder(entry.value),
              ),
          ],
        );
      },
    );
  }
}

class _FightStatBox extends StatelessWidget {
  const _FightStatBox({
    required this.label,
    required this.score,
    required this.modifier,
  });

  final String label;
  final int score;
  final int modifier;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(color: muted, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 5),
              Text(
                '$score',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          Text(
            _signed(modifier),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SavingThrowsRow extends StatelessWidget {
  const _SavingThrowsRow({
    required this.attributes,
    required this.savingThrows,
    required this.modifierBuilder,
    required this.proficiency,
    required this.loyaltyBonus,
  });

  final Map<String, int> attributes;
  final List<String> savingThrows;
  final int Function(int score) modifierBuilder;
  final int proficiency;
  final int loyaltyBonus;

  @override
  Widget build(BuildContext context) {
    final labels = attributes.keys.toList();

    return Column(
      children: [
        Text(
          context.uiText('TIRI SALVEZZA', 'SAVING THROWS'),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            for (final label in labels) ...[
              Expanded(
                child: _SaveBox(
                  value: _savingThrowValue(label),
                  proficient: _isSavingThrowProficient(label),
                ),
              ),
              if (label != labels.last) const SizedBox(width: 4),
            ],
          ],
        ),
      ],
    );
  }

  int _savingThrowValue(String label) {
    final base = modifierBuilder(attributes[label] ?? 10) + loyaltyBonus;
    return _isSavingThrowProficient(label) ? base + proficiency : base;
  }

  bool _isSavingThrowProficient(String label) {
    return savingThrows.any((save) => save.toUpperCase().contains(label));
  }
}

class _SaveBox extends StatelessWidget {
  const _SaveBox({required this.value, required this.proficient});

  final int value;
  final bool proficient;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: textScaleAwareValue(
        context,
        normal: 26,
        enlarged: 42,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: proficient
            ? Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.72)
            : Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Text(
        _signed(value),
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _StatusPanelButton extends StatelessWidget {
  const _StatusPanelButton({required this.statuses, required this.onTap});

  final List<String> statuses;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: textScaleAwareValue(
          context,
          normal: 42,
          enlarged: 52,
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: statuses.isEmpty
            ? Text(
                context.uiText('+ AGGIUNGI STATUS', '+ ADD STATUS'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final status in statuses.take(5)) ...[
                    _StatusIcon(
                      info: _statusEffectInfoByName[status],
                      size: 32,
                    ),
                    const SizedBox(width: 4),
                  ],
                  if (statuses.length > 5)
                    Text(
                      '+${statuses.length - 5}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                ],
              ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.info, required this.size});

  final _StatusEffectInfo? info;
  final double size;

  @override
  Widget build(BuildContext context) {
    final statusInfo = info;
    if (statusInfo == null) return const SizedBox.shrink();

    return _FallbackAssetIcon(
      paths: statusInfo.assetCandidates,
      fallbackLabel: statusInfo.shortLabel,
      size: size,
    );
  }
}

class _FallbackAssetIcon extends StatelessWidget {
  const _FallbackAssetIcon({
    required this.paths,
    required this.fallbackLabel,
    required this.size,
    this.index = 0,
  });

  final List<String> paths;
  final String fallbackLabel;
  final double size;
  final int index;

  @override
  Widget build(BuildContext context) {
    if (index >= paths.length) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          fallbackLabel,
          style: TextStyle(fontSize: size * 0.32, fontWeight: FontWeight.w900),
        ),
      );
    }

    return Image.asset(
      paths[index],
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _FallbackAssetIcon(
        paths: paths,
        fallbackLabel: fallbackLabel,
        size: size,
        index: index + 1,
      ),
    );
  }
}

String _signed(int value) => value >= 0 ? '+$value' : '$value';

class _MovesView extends StatelessWidget {
  const _MovesView({
    required this.selectedMoves,
    required this.moves,
    required this.moveStatsBuilder,
    required this.moveTypeBuilder,
  });

  final List<String> selectedMoves;
  final Map<String, MoveData?> moves;
  final String Function(MoveData move) moveStatsBuilder;
  final String Function(MoveData move) moveTypeBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _MoveSection(
          title: context.uiText('Mosse equipaggiate', 'Equipped moves'),
          names: [...selectedMoves, 'Struggle'],
          moves: moves,
          moveStatsBuilder: moveStatsBuilder,
          moveTypeBuilder: moveTypeBuilder,
        ),
      ],
    );
  }
}

class _MoveSection extends StatelessWidget {
  const _MoveSection({
    required this.title,
    required this.names,
    required this.moves,
    required this.moveStatsBuilder,
    required this.moveTypeBuilder,
  });

  final String title;
  final List<String> names;
  final Map<String, MoveData?> moves;
  final String Function(MoveData move) moveStatsBuilder;
  final String Function(MoveData move) moveTypeBuilder;

  @override
  Widget build(BuildContext context) {
    if (names.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
          child: Text(title.toUpperCase()),
        ),
        for (final name in names)
          _MoveCard(
            reference: name,
            move: moves[name],
            moveType: moves[name] == null
                ? null
                : moveTypeBuilder(moves[name]!),
            stats: moves[name] == null ? null : moveStatsBuilder(moves[name]!),
          ),
      ],
    );
  }
}

class _MoveCard extends StatelessWidget {
  const _MoveCard({
    required this.reference,
    required this.move,
    required this.moveType,
    required this.stats,
  });

  final String reference;
  final MoveData? move;
  final String? moveType;
  final String? stats;

  @override
  Widget build(BuildContext context) {
    final move = this.move;
    final name = move?.name ?? reference;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.radio_button_unchecked, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name.toUpperCase(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (move != null) Text('PP ${move.pp}'),
              ],
            ),
            const SizedBox(height: 8),
            if (move == null)
              Text(
                context.uiText(
                  'Dettagli mossa non disponibili.',
                  'Move details are unavailable.',
                ),
              )
            else ...[
              if (stats != null && stats!.isNotEmpty) Text(stats!),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  PokemonTypeBadge(type: moveType ?? move.type, height: 24),
                  Chip(label: Text(move.moveTime)),
                ],
              ),
              if (move.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(move.description),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _FeaturesView extends StatelessWidget {
  const _FeaturesView({
    required this.pokemon,
    required this.slot,
    required this.abilityDescriptions,
    required this.abilityDisplayNames,
    required this.featDescriptions,
    required this.featDisplayNames,
  });

  final Pokemon pokemon;
  final TeamSlot? slot;
  final Map<String, String> abilityDescriptions;
  final Map<String, String> abilityDisplayNames;
  final Map<String, String> featDescriptions;
  final Map<String, String> featDisplayNames;

  @override
  Widget build(BuildContext context) {
    String? lookup(Map<String, String> values, String reference) {
      final direct = values[reference];
      if (direct != null) return direct;
      final key = _itemReferenceKey(reference);
      for (final entry in values.entries) {
        if (_itemReferenceKey(entry.key) == key) return entry.value;
      }
      return null;
    }

    final feats = slot?.feats ?? const <String>[];
    final abilities = slot?.abilities.isNotEmpty == true
        ? slot!.abilities
        : [
            ...pokemon.abilities,
            if (pokemon.hiddenAbility != null &&
                feats.contains('Hidden Ability'))
              pokemon.hiddenAbility!,
          ];

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final ability in abilities)
          _InfoCard(
            title: lookup(abilityDisplayNames, ability) ?? ability,
            child: Text(
              lookup(abilityDescriptions, ability) ??
                  uiTextForLanguage(
                    'Descrizione non disponibile.',
                    """Description unavailable.""",
                  ),
            ),
          ),
        for (final feat in feats)
          _InfoCard(
            title: localizedFeatDisplayName(feat, featDisplayNames),
            child: Text(
              localizedFeatDescription(feat, featDescriptions) ??
                  uiTextForLanguage(
                    'Descrizione non disponibile.',
                    """Description unavailable.""",
                  ),
            ),
          ),
        if (abilities.isEmpty && feats.isEmpty)
          _InfoCard(
            title: uiTextForLanguage('Privilegi', """Features"""),
            child: Text(
              uiTextForLanguage(
                'Nessun privilegio disponibile.',
                """No features available.""",
              ),
            ),
          ),
      ],
    );
  }
}

class _TraitsView extends StatelessWidget {
  const _TraitsView({
    required this.pokemon,
    required this.basePokemon,
    required this.slot,
    required this.attributes,
    required this.modifierBuilder,
    required this.proficiency,
    required this.availableAsiPoints,
    required this.onDistributeAsi,
  });

  final Pokemon pokemon;
  final Pokemon basePokemon;
  final TeamSlot? slot;
  final Map<String, int> attributes;
  final int Function(int score) modifierBuilder;
  final int proficiency;
  final int availableAsiPoints;
  final VoidCallback onDistributeAsi;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _PendingAsiCard(
          availablePoints: availableAsiPoints,
          onDistribute: onDistributeAsi,
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              children: [
                for (final entry in attributes.entries)
                  _AttributeBox(
                    label: TrainerUiLocalization.abilityAbbreviation(entry.key),
                    score: entry.value,
                    modifier: modifierBuilder(entry.value),
                  ),
              ],
            ),
          ),
        ),
        _InfoCard(
          title: context.uiText('Dettagli', 'Details'),
          child: Column(
            children: [
              _InfoRow(
                label: context.uiText('Taglia', 'Size'),
                value: TrainerUiLocalization.sizeName(pokemon.size),
              ),
              _InfoRow(
                label: context.uiText('Velocità', 'Speed'),
                value: context.uiText(
                  '${pokemon.speed} piedi',
                  '${pokemon.speed} feet',
                ),
              ),
              _InfoRow(
                label: context.uiText('Dado vita', 'Hit Die'),
                value: 'd${pokemon.hitDice}',
              ),
              _InfoRow(
                label: context.uiText('Competenza', 'Proficiency'),
                value: '+$proficiency',
              ),
              _InfoRow(
                label: context.uiText('Livello minimo', 'Minimum level'),
                value: '${pokemon.minLevelFound}',
              ),
              _InfoRow(
                label: context.uiText('Tiri salvezza', 'Saving throws'),
                value: pokemon.savingThrows
                    .map(TrainerUiLocalization.abilityAbbreviation)
                    .join(', '),
              ),
              _InfoRow(
                label: context.uiText('Competenze', 'Skills'),
                value: [
                  ...pokemon.skills,
                  ...?slot?.extraSkills,
                ].map(TrainerUiLocalization.skillName).join(', '),
              ),
              _InfoRow(
                label: context.uiText('Natura', 'Nature'),
                value: TrainerUiLocalization.natureName(
                  slot?.nature ?? 'No Nature',
                ),
              ),
              _InfoRow(
                label: context.uiText('Forma', 'Form'),
                value: slot == null
                    ? '-'
                    : ItemDrivenPokemonForm.usesHeldItemForm(
                        basePokemon.id,
                      )
                    ? PokemonAssetPaths.localizedTypeLabel(
                        slot?.effectiveFormName ?? 'Normal',
                      )
                    : BattleFormChangeService.supports(basePokemon)
                    ? BattleFormChangeService.formLabel(
                        basePokemon,
                        slot?.effectiveFormName,
                      )
                    : PokemonFormLocalization.formLabel(
                        basePokemon,
                        slot?.effectiveFormName,
                      ),
              ),
              _InfoRow(
                label: context.uiText('Cromatico', 'Shiny'),
                value: slot?.isShiny == true
                    ? context.uiText('Sì', 'Yes')
                    : context.uiText('No', 'No'),
              ),
              _InfoRow(
                label: context.uiText('Sesso', 'Gender'),
                value: TrainerUiLocalization.genderName(slot?.gender ?? '-'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PendingAsiCard extends StatelessWidget {
  const _PendingAsiCard({
    required this.availablePoints,
    required this.onDistribute,
  });

  final int availablePoints;
  final VoidCallback onDistribute;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasPoints = availablePoints > 0;

    return Card(
      color: hasPoints ? colorScheme.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.trending_up,
              color: hasPoints ? colorScheme.onPrimaryContainer : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.uiText('ASI DISPONIBILI', 'AVAILABLE ASI'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: hasPoints ? colorScheme.onPrimaryContainer : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasPoints
                        ? context.uiText(
                            'Hai $availablePoints punti accumulati da distribuire.',
                            'You have $availablePoints accumulated points to distribute.',
                          )
                        : context.uiText(
                            'Nessun punto ASI disponibile.',
                            'No ASI points available.',
                          ),
                    style: TextStyle(
                      color: hasPoints ? colorScheme.onPrimaryContainer : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: hasPoints ? onDistribute : null,
              child: Text(context.uiText('DISTRIBUISCI', 'DISTRIBUTE')),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttributeBox extends StatelessWidget {
  const _AttributeBox({
    required this.label,
    required this.score,
    required this.modifier,
  });

  final String label;
  final int score;
  final int modifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$label $score'),
        Text(
          _signed(modifier),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }
}

class _PartySwitcher extends StatelessWidget {
  const _PartySwitcher({
    required this.team,
    required this.currentSlotIndex,
    required this.pokemonById,
    required this.onSelect,
  });

  final List<TeamSlot> team;
  final int currentSlotIndex;
  final Pokemon? Function(int? pokemonId) pokemonById;
  final ValueChanged<TeamSlot> onSelect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sortedTeam = [...team]
      ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));

    return SafeArea(
      top: false,
      child: Container(
        height: textScaleAwareValue(
          context,
          normal: 68,
          enlarged: 98,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: Row(
          children: [
            for (final slot in sortedTeam)
              Expanded(
                child: _PartySlotButton(
                  slot: slot,
                  pokemon: pokemonById(slot.pokemonId),
                  isActive: slot.slotIndex == currentSlotIndex,
                  onTap: slot.pokemonId == null ? null : () => onSelect(slot),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PartySlotButton extends StatelessWidget {
  const _PartySlotButton({
    required this.slot,
    required this.pokemon,
    required this.isActive,
    required this.onTap,
  });

  final TeamSlot slot;
  final Pokemon? pokemon;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pokemon = this.pokemon;

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? colorScheme.primary : colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            pokemon == null
                ? Icon(Icons.radio_button_unchecked, color: colorScheme.outline)
                : PokemonAssetImage(
                    pokemon: pokemon,
                    formName: slot.effectiveFormName,
                    gender: slot.gender,
                    isShiny: slot.isShiny,
                    size: 30,
                  ),
            const SizedBox(height: 2),
            Text(
              pokemon == null
                  ? '${slot.slotIndex + 1}'
                  : '#${pokemon.id.toString().padLeft(3, '0')}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExperienceDialog extends StatefulWidget {
  const _ExperienceDialog({required this.currentExperience});

  final int currentExperience;

  @override
  State<_ExperienceDialog> createState() => _ExperienceDialogState();
}

class _ExperienceDialogState extends State<_ExperienceDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        uiTextForLanguage('Modifica esperienza', """Edit experience"""),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Esperienza',
          helperText: uiTextForLanguage(
            'Usa +2000 per aggiungere, 2000 per impostare.',
            """Use +2000 to add, or 2000 to set.""",
          ),
          hintText: widget.currentExperience.toString(),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(uiTextForLanguage('Annulla', """Cancel""")),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(uiTextForLanguage('Salva', """Save""")),
        ),
      ],
    );
  }
}

class _HpDialog extends StatefulWidget {
  const _HpDialog({required this.currentHp, required this.maxHp});

  final int currentHp;
  final int maxHp;

  @override
  State<_HpDialog> createState() => _HpDialogState();
}

class _HpDialogState extends State<_HpDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(uiTextForLanguage('Modifica PF', """Edit HP""")),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'PF',
          helperText: uiTextForLanguage(
            'Usa +5 per curare, -5 per danneggiare, 5 per impostare.',
            """Use +5 to heal, -5 to damage, or 5 to set.""",
          ),
          hintText: widget.currentHp.toString(),
          suffixText: '/ ${widget.maxHp}',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(uiTextForLanguage('Annulla', """Cancel""")),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(uiTextForLanguage('Salva', """Save""")),
        ),
      ],
    );
  }
}
