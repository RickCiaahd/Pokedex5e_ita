from pathlib import Path
import re


def read(path: str) -> str:
    return Path(path).read_text(encoding='utf-8')


def write(path: str, text: str) -> None:
    Path(path).write_text(text, encoding='utf-8')


def replace_once(text: str, old: str, new: str, path: str) -> str:
    if old not in text:
        raise RuntimeError(f'Missing expected block in {path}: {old[:120]!r}')
    return text.replace(old, new, 1)


def regex_once(text: str, pattern: str, replacement: str, path: str) -> str:
    updated, count = re.subn(pattern, replacement, text, count=1, flags=re.S)
    if count != 1:
        raise RuntimeError(f'Expected one regex match in {path}, got {count}: {pattern}')
    return updated


# ---------------------------------------------------------------------------
# Manual starting equipment shared by onboarding and the Bag catalog.
# ---------------------------------------------------------------------------
starting_equipment_path = 'lib/models/trainer_starting_equipment.dart'
write(
    starting_equipment_path,
    r'''import '../localization/game_catalog_locale.dart';
import 'bag_item.dart';
import 'trainer_manual_options.dart';

class TrainerStartingEquipment {
  const TrainerStartingEquipment._();

  static const Map<String, int> baseInventory = {
    'poke-ball': 5,
    'potion': 1,
    'trainer-license': 1,
    'trainer-pokedex': 1,
  };

  static const Map<String, Map<String, int>> packInventory = {
    "Dungeoneer's pack": {
      'trainer-backpack': 1,
      'climbers-kit': 1,
      'flashlight': 1,
      'energy-cell': 5,
      'flint-and-steel': 1,
      'camping-ration': 10,
      'canteen': 1,
      'rope-30-feet': 1,
    },
    "Explorer's pack": {
      'trainer-backpack': 1,
      'sleeping-bag': 1,
      'mess-kit': 1,
      'flint-and-steel': 1,
      'flashlight': 1,
      'energy-cell': 5,
      'camping-ration': 10,
      'canteen': 1,
      'rope-30-feet': 1,
    },
    "Filcher's pack": {
      'trainer-backpack': 1,
      'thieves-tools': 1,
      'wire-20-feet': 1,
      'bell': 1,
      'lantern': 1,
      'energy-cell': 3,
      'camping-ration': 5,
      'flint-and-steel': 1,
      'canteen': 1,
    },
  };

  static Map<String, int> inventoryForPack(String pack) {
    final selected = packInventory[pack];
    if (selected == null) {
      throw ArgumentError.value(pack, 'pack', 'Unknown starting pack');
    }

    return Map<String, int>.unmodifiable({...baseInventory, ...selected});
  }

  static List<BagItem> get catalogItems {
    final italian = GameCatalogLocale.isItalian;
    String text(String it, String en) => italian ? it : en;

    return List<BagItem>.unmodifiable([
      BagItem(
        id: 'trainer-license',
        name: text('Licenza da Allenatore', 'Trainer License'),
        sourceName: 'Trainer License',
        type: 'key-item',
        description: [
          text(
            'Documento ufficiale che identifica il personaggio come Allenatore.',
            'Official document identifying the character as a Trainer.',
          ),
        ],
        cost: null,
        spriteAssetPath: null,
      ),
      BagItem(
        id: 'trainer-pokedex',
        name: 'Pokédex',
        sourceName: 'Pokédex',
        type: 'key-item',
        description: [
          text(
            'Dispositivo affidato all’Allenatore per consultare e registrare informazioni sui Pokémon.',
            'A device entrusted to the Trainer to consult and record Pokémon information.',
          ),
        ],
        cost: null,
        spriteAssetPath: null,
      ),
      BagItem(
        id: 'trainer-backpack',
        name: text('Zaino', 'Backpack'),
        sourceName: 'Backpack',
        type: 'trainer-gear',
        description: [
          text(
            'Contenitore da viaggio per trasportare equipaggiamento e provviste.',
            'Travel container used to carry equipment and supplies.',
          ),
        ],
        cost: null,
        spriteAssetPath: null,
      ),
      BagItem(
        id: 'climbers-kit',
        name: text('Kit da scalatore', "Climber's Kit"),
        sourceName: "Climber's Kit",
        type: 'trainer-gear',
        description: [
          text(
            'Attrezzatura concreta per affrontare arrampicate e pareti difficili.',
            'Practical equipment for climbing and difficult walls.',
          ),
        ],
        cost: null,
        spriteAssetPath: null,
      ),
      BagItem(
        id: 'flashlight',
        name: text('Torcia', 'Flashlight'),
        sourceName: 'Flashlight',
        type: 'trainer-gear',
        description: [
          text(
            'Fonte di luce portatile alimentata da celle energetiche.',
            'Portable light source powered by energy cells.',
          ),
        ],
        cost: null,
        spriteAssetPath: null,
      ),
      BagItem(
        id: 'energy-cell',
        name: text('Cella energetica', 'Energy Cell'),
        sourceName: 'Energy Cell',
        type: 'trainer-gear',
        description: [
          text(
            'Unità di alimentazione per torce, lanterne e altri dispositivi compatibili.',
            'Power unit for flashlights, lanterns, and compatible devices.',
          ),
        ],
        cost: null,
        spriteAssetPath: null,
      ),
      BagItem(
        id: 'flint-and-steel',
        name: text('Acciarino e pietra focaia', 'Flint and Steel'),
        sourceName: 'Flint and Steel',
        type: 'trainer-gear',
        description: [
          text(
            'Strumenti per produrre scintille e accendere un fuoco.',
            'Tools used to make sparks and light a fire.',
          ),
        ],
        cost: null,
        spriteAssetPath: null,
      ),
      BagItem(
        id: 'camping-ration',
        name: text('Razione da campeggio', 'Camping Ration'),
        sourceName: 'Camping Ration',
        type: 'trainer-gear',
        description: [
          text(
            'Una porzione di viveri conservabili per il viaggio.',
            'One portion of preserved food for travel.',
          ),
        ],
        cost: null,
        spriteAssetPath: null,
      ),
      BagItem(
        id: 'canteen',
        name: text('Borraccia', 'Canteen'),
        sourceName: 'Canteen',
        type: 'trainer-gear',
        description: [
          text(
            'Contenitore portatile per trasportare acqua o altre bevande.',
            'Portable container for carrying water or other drinks.',
          ),
        ],
        cost: null,
        spriteAssetPath: null,
      ),
      BagItem(
        id: 'rope-30-feet',
        name: text('Corda da 30 piedi', '30-foot Rope'),
        sourceName: '30-foot Rope',
        type: 'trainer-gear',
        description: [
          text(
            'Trenta piedi di corda utilizzabili per legare, calarsi, assicurare o improvvisare.',
            'Thirty feet of rope for tying, lowering, securing, or improvising.',
          ),
        ],
        cost: null,
        spriteAssetPath: null,
      ),
      BagItem(
        id: 'sleeping-bag',
        name: text('Sacco a pelo', 'Sleeping Bag'),
        sourceName: 'Sleeping Bag',
        type: 'trainer-gear',
        description: [
          text(
            'Giusta protezione per dormire durante i viaggi e i campeggi.',
            'Basic protection for sleeping during journeys and camps.',
          ),
        ],
        cost: null,
        spriteAssetPath: null,
      ),
      BagItem(
        id: 'mess-kit',
        name: text('Gavetta', 'Mess Kit'),
        sourceName: 'Mess Kit',
        type: 'trainer-gear',
        description: [
          text(
            'Utensili essenziali per preparare e consumare un pasto da campo.',
            'Essential utensils for preparing and eating a camp meal.',
          ),
        ],
        cost: null,
        spriteAssetPath: null,
      ),
      BagItem(
        id: 'thieves-tools',
        name: text('Arnesi da scasso', "Thieves' Tools"),
        sourceName: "Thieves' Tools",
        type: 'trainer-gear',
        description: [
          text(
            'Strumenti specialistici per lavorare su serrature e meccanismi.',
            'Specialized tools for working on locks and mechanisms.',
          ),
        ],
        cost: null,
        spriteAssetPath: null,
      ),
      BagItem(
        id: 'wire-20-feet',
        name: text('Filo da 20 piedi', '20-foot Wire'),
        sourceName: '20-foot Wire',
        type: 'trainer-gear',
        description: [
          text(
            'Venti piedi di filo sottile utilizzabili per legature, segnali o congegni improvvisati.',
            'Twenty feet of thin wire for bindings, signals, or improvised devices.',
          ),
        ],
        cost: null,
        spriteAssetPath: null,
      ),
      BagItem(
        id: 'bell',
        name: text('Campanella', 'Bell'),
        sourceName: 'Bell',
        type: 'trainer-gear',
        description: [
          text(
            'Piccola campana utile per segnali, allarmi e semplici congegni.',
            'Small bell useful for signals, alarms, and simple devices.',
          ),
        ],
        cost: null,
        spriteAssetPath: null,
      ),
      BagItem(
        id: 'lantern',
        name: text('Lanterna', 'Lantern'),
        sourceName: 'Lantern',
        type: 'trainer-gear',
        description: [
          text(
            'Fonte di luce protetta, alimentata da celle energetiche.',
            'Protected light source powered by energy cells.',
          ),
        ],
        cost: null,
        spriteAssetPath: null,
      ),
    ]);
  }

  static void validatePacks() {
    if (packInventory.keys.toSet().difference(
          TrainerManualOptions.startingPacks.toSet(),
        ).isNotEmpty ||
        TrainerManualOptions.startingPacks.toSet().difference(
          packInventory.keys.toSet(),
        ).isNotEmpty) {
      throw StateError('Starting pack inventory is out of sync');
    }
  }
}
''',
)


# ---------------------------------------------------------------------------
# Batch inventory writes.
# ---------------------------------------------------------------------------
path = 'lib/repositories/bag_inventory_repository.dart'
text = read(path)
insert_after = '''  Future<void> addItem({
    required String profileId,
    required String itemId,
    int quantity = 1,
  }) async {
    if (quantity <= 0) return;

    final box = await _box();
    final key = BagInventoryEntry.keyFor(profileId, itemId);
    final existingJson = box.get(key);
    final existing = existingJson == null
        ? BagInventoryEntry(profileId: profileId, itemId: itemId, quantity: 0)
        : BagInventoryEntry.fromJson(Map<String, dynamic>.from(existingJson));

    final updated = existing.copyWith(quantity: existing.quantity + quantity);

    await box.put(key, updated.toJson());
    await box.flush();
  }
'''
addition = insert_after + '''
  Future<void> addItems({
    required String profileId,
    required Map<String, int> quantities,
  }) async {
    final selected = quantities.entries
        .where((entry) => entry.key.trim().isNotEmpty && entry.value > 0)
        .toList(growable: false);
    if (selected.isEmpty) return;

    final box = await _box();
    final updates = <String, dynamic>{};

    for (final entry in selected) {
      final itemId = entry.key.trim();
      final key = BagInventoryEntry.keyFor(profileId, itemId);
      final existingJson = box.get(key);
      final existing = existingJson == null
          ? BagInventoryEntry(profileId: profileId, itemId: itemId, quantity: 0)
          : BagInventoryEntry.fromJson(
              Map<String, dynamic>.from(existingJson),
            );
      updates[key] = existing
          .copyWith(quantity: existing.quantity + entry.value)
          .toJson();
    }

    await box.putAll(updates);
    await box.flush();
  }
'''
text = replace_once(text, insert_after, addition, path)
write(path, text)


# ---------------------------------------------------------------------------
# Add trainer gear/key items to the catalog.
# ---------------------------------------------------------------------------
path = 'lib/repositories/item_repository.dart'
text = read(path)
text = replace_once(
    text,
    "import '../models/tm_data.dart';\n",
    "import '../models/tm_data.dart';\nimport '../models/trainer_starting_equipment.dart';\n",
    path,
)
text = replace_once(
    text,
    '      items.addAll(await _getTmItems());\n\n      items.sort((a, b) {',
    '      items.addAll(await _getTmItems());\n      items.addAll(TrainerStartingEquipment.catalogItems);\n\n      items.sort((a, b) {',
    path,
)
write(path, text)


# ---------------------------------------------------------------------------
# Profile creation assigns all concrete starting possessions and rolls back.
# ---------------------------------------------------------------------------
path = 'lib/services/profile_creation_service.dart'
text = read(path)
text = replace_once(
    text,
    "import '../repositories/pokedex_repositry.dart';\n",
    "import '../repositories/bag_inventory_repository.dart';\nimport '../repositories/pokedex_repositry.dart';\n",
    path,
)
text = replace_once(
    text,
    '''  ProfileCreationService({
    ProfileRepository? profileRepository,
    TeamRepository? teamRepository,
    PokedexRepository? pokedexRepository,
    AppLaunchService? appLaunchService,
  }) : _profileRepository = profileRepository ?? ProfileRepository(),
       _teamRepository = teamRepository ?? TeamRepository(),
       _pokedexRepository = pokedexRepository ?? PokedexRepository(),
       _appLaunchService = appLaunchService ?? AppLaunchService();

  final ProfileRepository _profileRepository;
  final TeamRepository _teamRepository;
  final PokedexRepository _pokedexRepository;
  final AppLaunchService _appLaunchService;
''',
    '''  ProfileCreationService({
    ProfileRepository? profileRepository,
    TeamRepository? teamRepository,
    PokedexRepository? pokedexRepository,
    BagInventoryRepository? bagInventoryRepository,
    AppLaunchService? appLaunchService,
  }) : _profileRepository = profileRepository ?? ProfileRepository(),
       _teamRepository = teamRepository ?? TeamRepository(),
       _pokedexRepository = pokedexRepository ?? PokedexRepository(),
       _bagInventoryRepository =
           bagInventoryRepository ?? BagInventoryRepository(),
       _appLaunchService = appLaunchService ?? AppLaunchService();

  final ProfileRepository _profileRepository;
  final TeamRepository _teamRepository;
  final PokedexRepository _pokedexRepository;
  final BagInventoryRepository _bagInventoryRepository;
  final AppLaunchService _appLaunchService;
''',
    path,
)
text = replace_once(
    text,
    '''    required int starterPokemonId,
    required String starterSpeciesName,
    bool markOnboardingCompleted = false,
  }) {
''',
    '''    required int starterPokemonId,
    required String starterSpeciesName,
    Map<String, int> initialInventory = const {},
    bool markOnboardingCompleted = false,
  }) {
''',
    path,
)
text = replace_once(
    text,
    '''      starterPokemonId: starterPokemonId,
      starterSpeciesName: starterSpeciesName,
      markOnboardingCompleted: markOnboardingCompleted,
''',
    '''      starterPokemonId: starterPokemonId,
      starterSpeciesName: starterSpeciesName,
      initialInventory: initialInventory,
      markOnboardingCompleted: markOnboardingCompleted,
''',
    path,
)
text = replace_once(
    text,
    '''    int? starterPokemonId,
    String? starterSpeciesName,
    bool markOnboardingCompleted = false,
  }) async {
''',
    '''    int? starterPokemonId,
    String? starterSpeciesName,
    Map<String, int> initialInventory = const {},
    bool markOnboardingCompleted = false,
  }) async {
''',
    path,
)
text = replace_once(
    text,
    '''      await _profileRepository.saveProfile(profile);

      if (starterSlot != null) {
''',
    '''      await _profileRepository.saveProfile(profile);
      await _bagInventoryRepository.addItems(
        profileId: profile.id,
        quantities: initialInventory,
      );

      if (starterSlot != null) {
''',
    path,
)
text = replace_once(
    text,
    '''    await _ignoreFailure(
      () => _pokedexRepository.clearProfilePokedex(profileId),
    );
    await _ignoreFailure(() => _teamRepository.deleteTeam(profileId));
''',
    '''    await _ignoreFailure(
      () => _pokedexRepository.clearProfilePokedex(profileId),
    );
    await _ignoreFailure(() => _bagInventoryRepository.deleteInventory(profileId));
    await _ignoreFailure(() => _teamRepository.deleteTeam(profileId));
''',
    path,
)
write(path, text)


# ---------------------------------------------------------------------------
# Guided onboarding: free narrative background, explicit pack choice, items.
# ---------------------------------------------------------------------------
path = 'lib/screens/onboarding/first_launch_onboarding_screen.dart'
text = read(path)
text = replace_once(
    text,
    "import '../../models/trainer_manual_options.dart';\n",
    "import '../../models/trainer_manual_options.dart';\nimport '../../models/trainer_starting_equipment.dart';\n",
    path,
)
text = replace_once(
    text,
    '''  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
''',
    '''  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _backgroundController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
''',
    path,
)
text = replace_once(
    text,
    '''  String? _errorMessage;
  String _background = _backgroundOptions.first.name;
  String _profileImageBase64 = '';
''',
    '''  String? _errorMessage;
  String _startingPack = TrainerManualOptions.startingPacks.first;
  String _profileImageBase64 = '';
''',
    path,
)
text = replace_once(text, '  static const int _totalSteps = 11;\n', '  static const int _totalSteps = 12;\n', path)
text = regex_once(
    text,
    r'''\n  static const List<_BackgroundOption> _backgroundOptions = \[.*?\n  \];\n''',
    '\n',
    path,
)
text = replace_once(
    text,
    '''    _nameController.dispose();
    _searchController
''',
    '''    _nameController.dispose();
    _backgroundController.dispose();
    _searchController
''',
    path,
)
text = regex_once(
    text,
    r'''\n  _BackgroundOption get _selectedBackground =>.*?\n  String _originDisplayName\(''',
    '\n  String _originDisplayName(',
    path,
)
text = replace_once(
    text,
    '''      case 6:
        return _background.trim().isNotEmpty;
      case 7:
        return _starter != null;
      case 9:
        return !_isSaving && _errorMessage != null;
''',
    '''      case 7:
        return _startingPack.trim().isNotEmpty;
      case 8:
        return _starter != null;
      case 10:
        return !_isSaving && _errorMessage != null;
''',
    path,
)
text = replace_once(
    text,
    '''      case 8:
        return l10n.onboardingConfirm;
      case 9:
        return _errorMessage == null
            ? l10n.onboardingCreatingProfile
            : l10n.retryAction.toUpperCase();
      case 10:
        return l10n.onboardingBegin;
''',
    '''      case 9:
        return l10n.onboardingConfirm;
      case 10:
        return _errorMessage == null
            ? l10n.onboardingCreatingProfile
            : l10n.retryAction.toUpperCase();
      case 11:
        return l10n.onboardingBegin;
''',
    path,
)
text = replace_once(
    text,
    '''    if (_step < 8) {
''',
    '''    if (_step < 9) {
''',
    path,
)
text = replace_once(
    text,
    '''    if (_step == 8 || _step == 9) {
      setState(() {
        _step = 9;
''',
    '''    if (_step == 9 || _step == 10) {
      setState(() {
        _step = 10;
''',
    path,
)
text = replace_once(text, '    if (_step == 10) {\n', '    if (_step == 11) {\n', path)
text = replace_once(
    text,
    '    if (_step <= 0 || _step >= 9 || _isSaving) return;\n',
    '    if (_step <= 0 || _step >= 10 || _isSaving) return;\n',
    path,
)
text = replace_once(
    text,
    '''        (_step < 9 || (_step == 9 && _errorMessage != null));
''',
    '''        (_step < 10 || (_step == 10 && _errorMessage != null));
''',
    path,
)
text = replace_once(
    text,
    '''      7 => .30,
      8 => .36,
      9 || 10 => .50,
''',
    '''      8 => .30,
      9 => .36,
      10 || 11 => .50,
''',
    path,
)

# Replace the old preset-background stage with narrative text and insert pack stage.
old_stage = r'''      case 6:
        final selected = _selectedBackground;
        return _DialogueCard(
          speaker: l10n.onboardingProfessor,
          title: l10n.onboardingBackgroundTitle,
          body: l10n.onboardingBackgroundBody,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _background,
                isExpanded: true,
                items: [
                  for (final option in _backgroundOptions)
                    DropdownMenuItem(
                      value: option.name,
                      child: Row(
                        children: [
                          Icon(option.icon, size: 20),
                          const SizedBox(width: 10),
                          Text(_backgroundLabel(option, l10n)),
                        ],
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _background = value);
                },
                decoration: InputDecoration(
                  labelText: l10n.onboardingBackgroundLabel,
                ),
              ),
              const SizedBox(height: 16),
              _InfoBanner(
                icon: selected.icon,
                text: _backgroundDescription(selected, l10n),
              ),
            ],
          ),
        );
      case 7:
'''
new_stage = r'''      case 6:
        return _DialogueCard(
          speaker: l10n.onboardingProfessor,
          title: context.uiText(
            'Racconta chi sei',
            'Tell us who you are',
          ),
          body: context.uiText(
            'Scrivi liberamente il background narrativo del tuo Allenatore. Non assegna bonus automatici e potrai modificarlo dalla scheda.',
            'Write your Trainer’s narrative background freely. It grants no automatic bonuses and can be edited from the sheet.',
          ),
          content: TextField(
            controller: _backgroundController,
            minLines: 4,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: const [LengthLimitingTextInputFormatter(4000)],
            decoration: InputDecoration(
              labelText: context.uiText(
                'Background narrativo',
                'Narrative background',
              ),
              hintText: context.uiText(
                'Da dove vieni? Perché hai iniziato il viaggio? Chi o cosa hai lasciato alle spalle?',
                'Where are you from? Why did you begin your journey? Who or what did you leave behind?',
              ),
              alignLabelWithHint: true,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 86),
                child: Icon(Icons.auto_stories_outlined),
              ),
            ),
          ),
        );
      case 7:
        return _DialogueCard(
          speaker: l10n.onboardingProfessor,
          title: context.uiText(
            'Scegli la dotazione iniziale',
            'Choose your starting pack',
          ),
          body: context.uiText(
            'La dotazione scelta verrà aperta e ogni oggetto sarà inserito concretamente nello Zaino.',
            'The selected pack will be unpacked and every item will be placed in the Bag.',
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _startingPack,
                isExpanded: true,
                items: [
                  for (final pack in TrainerManualOptions.startingPacks)
                    DropdownMenuItem(
                      value: pack,
                      child: Text(
                        TrainerUiLocalization.startingPackName(pack),
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _startingPack = value);
                },
                decoration: InputDecoration(
                  labelText: context.uiText('Dotazione', 'Starting pack'),
                  prefixIcon: const Icon(Icons.backpack_outlined),
                ),
              ),
              const SizedBox(height: 16),
              _InfoBanner(
                icon: Icons.inventory_2_outlined,
                text: TrainerUiLocalization.startingPackDescription(
                  _startingPack,
                ),
              ),
            ],
          ),
        );
      case 8:
'''
text = replace_once(text, old_stage, new_stage, path)

# Shift the remaining dialogue cases after the inserted pack stage.
dialogue_start = text.index('  Widget _buildDialogue()')
dialogue_end = text.index('\nclass _', dialogue_start)
dialogue = text[dialogue_start:dialogue_end]
dialogue = dialogue.replace('      case 9:\n', '      case 10:\n', 1)
dialogue = dialogue.replace('      case 8:\n', '      case 9:\n', 1)
# The first case 8 is the newly inserted starter; shift the following original summary only.
second_case8 = dialogue.find('      case 8:\n', dialogue.find('      case 8:\n') + 1)
if second_case8 != -1:
    dialogue = dialogue[:second_case8] + dialogue[second_case8:].replace(
        '      case 8:\n', '      case 9:\n', 1
    )
# Normalize accidental duplicate renumbering by using recognizable titles.
dialogue = dialogue.replace(
    '      case 9:\n        return _DialogueCard(\n          speaker: l10n.onboardingProfessor,\n          title: l10n.onboardingStarterTitle,',
    '      case 8:\n        return _DialogueCard(\n          speaker: l10n.onboardingProfessor,\n          title: l10n.onboardingStarterTitle,',
)
dialogue = dialogue.replace(
    '      case 8:\n        return _DialogueCard(\n          speaker: l10n.onboardingProfessor,\n          title: l10n.onboardingSummaryTitle,',
    '      case 9:\n        return _DialogueCard(\n          speaker: l10n.onboardingProfessor,\n          title: l10n.onboardingSummaryTitle,',
)
dialogue = dialogue.replace(
    '      case 9:\n        return _DialogueCard(\n          speaker: l10n.onboardingProfessor,\n          title: l10n.onboardingSavingTitle,',
    '      case 10:\n        return _DialogueCard(\n          speaker: l10n.onboardingProfessor,\n          title: l10n.onboardingSavingTitle,',
)
text = text[:dialogue_start] + dialogue + text[dialogue_end:]

text = replace_once(
    text,
    '''              _SummaryRow(
                icon: Icons.menu_book_outlined,
                label: l10n.onboardingBackgroundLabel,
                value: _backgroundLabel(_selectedBackground, l10n),
              ),
              _SummaryRow(
                icon: Icons.catching_pokemon,
''',
    '''              _SummaryRow(
                icon: Icons.auto_stories_outlined,
                label: context.uiText(
                  'Background narrativo',
                  'Narrative background',
                ),
                value: _backgroundController.text.trim().isEmpty
                    ? context.uiText('Non compilato', 'Not provided')
                    : _backgroundController.text.trim(),
              ),
              _SummaryRow(
                icon: Icons.backpack_outlined,
                label: context.uiText('Dotazione', 'Starting pack'),
                value: TrainerUiLocalization.startingPackName(_startingPack),
              ),
              _SummaryRow(
                icon: Icons.catching_pokemon,
''',
    path,
)
text = replace_once(
    text,
    '        background: _background,\n',
    '        background: _backgroundController.text.trim(),\n',
    path,
)
text = replace_once(
    text,
    '        startingPack: TrainerManualOptions.startingPacks.first,\n',
    '        startingPack: _startingPack,\n',
    path,
)
text = replace_once(
    text,
    '''        starterSpeciesName: starter.name,
        markOnboardingCompleted: widget.markOnboardingCompleted,
''',
    '''        starterSpeciesName: starter.name,
        initialInventory: TrainerStartingEquipment.inventoryForPack(
          _startingPack,
        ),
        markOnboardingCompleted: widget.markOnboardingCompleted,
''',
    path,
)
# Remove the obsolete private option class if it still exists.
text = re.sub(r'\nclass _BackgroundOption \{.*?\n\}\n', '\n', text, flags=re.S)
write(path, text)


# ---------------------------------------------------------------------------
# Trainer sheet edits the saved background as free multiline narrative text.
# ---------------------------------------------------------------------------
path = 'lib/screens/trainer/trainer_sheet_screen.dart'
text = read(path)
old_editor = r'''  Future<void> _openBackgroundPicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => _StringPickerSheet(
        title: context.uiText('Background', 'Background'),
        options: TrainerUiLocalization.backgroundOptions,
        selected: _background,
        descriptions: TrainerUiLocalization.backgroundDescriptions,
        displayNames: TrainerUiLocalization.backgroundLabels,
      ),
    );
    _changeBackground(selected);
  }
'''
new_editor = r'''  Future<void> _openBackgroundEditor() async {
    final controller = TextEditingController(text: _background);
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          context.uiText('Background narrativo', 'Narrative background'),
        ),
        content: SizedBox(
          width: 560,
          child: TextField(
            controller: controller,
            autofocus: true,
            minLines: 7,
            maxLines: 14,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: const [LengthLimitingTextInputFormatter(4000)],
            decoration: InputDecoration(
              hintText: context.uiText(
                'Scrivi storia, legami, motivazioni ed esperienze del personaggio.',
                'Write the character’s history, bonds, motivations, and experiences.',
              ),
              helperText: context.uiText(
                'Testo narrativo libero: non assegna bonus automatici.',
                'Free narrative text: it grants no automatic bonuses.',
              ),
              helperMaxLines: 2,
              alignLabelWithHint: true,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.uiText('ANNULLA', 'CANCEL')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(''),
            child: Text(context.uiText('SVUOTA', 'CLEAR')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(
              dialogContext,
            ).pop(controller.text.trim()),
            child: Text(context.uiText('APPLICA', 'APPLY')),
          ),
        ],
      ),
    );
    controller.dispose();
    _changeBackground(selected);
  }
'''
text = replace_once(text, old_editor, new_editor, path)
text = text.replace('onBackgroundTap: _openBackgroundPicker,', 'onBackgroundTap: _openBackgroundEditor,')
text = replace_once(
    text,
    '''                          backgroundDescription:
                              TrainerUiLocalization.backgroundDescription(
                                _background,
                              ),
''',
    '''                          backgroundDescription: _background,
''',
    path,
)
text = text.replace(
    "label: context.uiText('Background', 'Background'),",
    "label: context.uiText('Background narrativo', 'Narrative background'),",
)
text = text.replace(
    "? context.uiText('Scegli', 'Choose')\n              : background,",
    "? context.uiText('Aggiungi storia', 'Add story')\n              : context.uiText('Storia del personaggio', 'Character story'),",
)
text = text.replace(
    "'Scelta narrativa, senza bonus automatici alle caratteristiche.',\n                  'Narrative choice, with no automatic ability-score bonuses.',",
    "'Scrivi liberamente storia, legami e motivazioni del personaggio.',\n                  'Write the character’s history, bonds, and motivations freely.',",
)
write(path, text)

path = 'lib/screens/trainer/trainer_sheet_mobile.dart'
text = read(path)
text = text.replace(
    "label: context.uiText('BACKGROUND', 'BACKGROUND'),",
    "label: context.uiText('BACKGROUND NARRATIVO', 'NARRATIVE BACKGROUND'),",
)
text = text.replace(
    "value: background.isEmpty\n              ? context.uiText('Scegli', 'Choose')\n              : TrainerUiLocalization.backgroundName(background),",
    "value: background.isEmpty\n              ? context.uiText('Aggiungi storia', 'Add story')\n              : context.uiText('Storia del personaggio', 'Character story'),",
)
text = text.replace(
    "'Scelta narrativa, senza bonus automatici alle caratteristiche.',\n                  'Narrative choice, with no automatic ability-score bonuses.',",
    "'Scrivi liberamente storia, legami e motivazioni del personaggio.',\n                  'Write the character’s history, bonds, and motivations freely.',",
)
write(path, text)


# ---------------------------------------------------------------------------
# Bag add/buy sheets become multi-item carts with quantities starting at zero.
# ---------------------------------------------------------------------------
path = 'lib/screens/bag/bag_screen.dart'
text = read(path)
new_open_finder = r'''  Future<void> _openFinder(_BagData data, _BagAction action) async {
    final result = await showModalBottomSheet<_ItemCartResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ItemPickerSheet(
        action: action,
        items: data.catalog,
        availableMoney: data.profile.money,
      ),
    );

    if (!mounted || result == null || result.quantities.isEmpty) return;

    final itemsById = data.itemById;
    final selected = <BagItem, int>{};
    for (final entry in result.quantities.entries) {
      final item = itemsById[entry.key];
      if (item != null && entry.value > 0) selected[item] = entry.value;
    }
    if (selected.isEmpty) return;

    final quantities = {
      for (final entry in selected.entries) entry.key.id: entry.value,
    };
    final totalUnits = selected.values.fold<int>(0, (sum, value) => sum + value);
    final typeCount = selected.length;

    try {
      if (action == _BagAction.buy) {
        var totalCost = 0;
        for (final entry in selected.entries) {
          final cost = entry.key.cost;
          if (cost == null || cost <= 0) {
            await _reload(
              message: context.uiText(
                '${entry.key.name} non si può acquistare.',
                '${entry.key.name} cannot be purchased.',
              ),
            );
            return;
          }
          totalCost += cost * entry.value;
        }

        if (data.profile.money < totalCost) {
          await _reload(
            message: context.uiText(
              'Pokédollari insufficienti: servono ₽ $totalCost.',
              'Not enough Pokédollars: ₽ $totalCost are required.',
            ),
          );
          return;
        }

        final updatedProfile = data.profile.copyWith(
          money: data.profile.money - totalCost,
        );
        await _profileRepository.saveProfile(updatedProfile);
        try {
          await _bagRepository.addItems(
            profileId: data.profile.id,
            quantities: quantities,
          );
        } catch (_) {
          await _profileRepository.saveProfile(data.profile);
          rethrow;
        }

        await _reload(
          message: context.uiText(
            '$totalUnits oggetti di $typeCount tipi acquistati per ₽ $totalCost.',
            '$totalUnits items across $typeCount types purchased for ₽ $totalCost.',
          ),
        );
        return;
      }

      await _bagRepository.addItems(
        profileId: data.profile.id,
        quantities: quantities,
      );
      await _reload(
        message: context.uiText(
          '$totalUnits oggetti di $typeCount tipi aggiunti allo zaino.',
          '$totalUnits items across $typeCount types added to the Bag.',
        ),
      );
    } catch (error) {
      await _reload(
        message: context.userFacingError(
          error,
          action: UserFacingErrorAction.save,
        ),
      );
    }
  }
'''
text = regex_once(
    text,
    r'''  Future<void> _openFinder\(_BagData data, _BagAction action\) async \{.*?\n  \}\n\n  Future<void> _useBagItem''',
    new_open_finder + '\n  Future<void> _useBagItem',
    path,
)
text = text.replace("context.uiText('Trova oggetto', 'Find item')", "context.uiText('Aggiungi oggetti', 'Add items')")

new_picker = r'''class _ItemCartResult {
  const _ItemCartResult({required this.quantities});

  final Map<String, int> quantities;
}

class _ItemPickerSheet extends StatefulWidget {
  const _ItemPickerSheet({
    required this.action,
    required this.items,
    required this.availableMoney,
  });

  final _BagAction action;
  final List<BagItem> items;
  final int availableMoney;

  @override
  State<_ItemPickerSheet> createState() => _ItemPickerSheetState();
}

class _ItemPickerSheetState extends State<_ItemPickerSheet> {
  final TextEditingController _controller = TextEditingController();
  final Map<String, int> _quantities = {};
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isBuy => widget.action == _BagAction.buy;

  int _quantityFor(BagItem item) => _quantities[item.id] ?? 0;

  int get _selectedTypeCount =>
      _quantities.values.where((quantity) => quantity > 0).length;

  int get _selectedUnitCount => _quantities.values.fold<int>(
    0,
    (sum, quantity) => sum + quantity,
  );

  int get _totalCost {
    if (!_isBuy) return 0;
    final byId = {for (final item in widget.items) item.id: item};
    var total = 0;
    for (final entry in _quantities.entries) {
      if (entry.value <= 0) continue;
      final cost = byId[entry.key]?.cost;
      if (cost != null) total += cost * entry.value;
    }
    return total;
  }

  bool get _canConfirm {
    if (_selectedUnitCount <= 0) return false;
    return !_isBuy || _totalCost <= widget.availableMoney;
  }

  int _maxQuantityFor(BagItem item) {
    if (!_isBuy) return 99;
    final cost = item.cost;
    if (cost == null || cost <= 0) return 0;
    return (widget.availableMoney ~/ cost).clamp(0, 99).toInt();
  }

  bool _canIncrease(BagItem item) {
    final quantity = _quantityFor(item);
    if (quantity >= _maxQuantityFor(item)) return false;
    if (!_isBuy) return true;
    final cost = item.cost;
    return cost != null && _totalCost + cost <= widget.availableMoney;
  }

  void _setQuantity(BagItem item, int value) {
    final maxQuantity = _maxQuantityFor(item);
    final next = value.clamp(0, maxQuantity).toInt();
    setState(() {
      if (next == 0) {
        _quantities.remove(item.id);
      } else {
        _quantities[item.id] = next;
      }
    });
  }

  void _showItemDetails(BagItem item) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            _ItemSprite(item: item),
            const SizedBox(width: 12),
            Expanded(child: Text(item.name)),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(item.displayDescription),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.uiText('CHIUDI', 'CLOSE')),
          ),
        ],
      ),
    );
  }

  void _confirmCart() {
    if (!_canConfirm) return;
    Navigator.of(context).pop(
      _ItemCartResult(
        quantities: Map<String, int>.unmodifiable(_quantities),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = widget.items.where((item) {
      return item.matchesSearchQuery(
        _query,
        aliases: [_typeLabel(item.type)],
      );
    }).toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.84,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isBuy
                    ? context.uiText('Compra oggetti', 'Buy items')
                    : context.uiText('Aggiungi oggetti', 'Add items'),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                _isBuy
                    ? context.uiText(
                        'Prepara il carrello. Disponibili: ₽ ${widget.availableMoney}',
                        'Prepare the cart. Available: ₽ ${widget.availableMoney}',
                      )
                    : context.uiText(
                        'Imposta le quantità desiderate, poi conferma una sola volta.',
                        'Set the desired quantities, then confirm once.',
                      ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                autofocus: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  labelText: context.uiText('Cerca oggetto', 'Search items'),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final quantity = _quantityFor(item);
                    final maxQuantity = _maxQuantityFor(item);
                    final canSelect = maxQuantity > 0;
                    final costLabel = item.cost == null
                        ? context.uiText('Non acquistabile', 'Not for sale')
                        : '₽ ${item.cost}';
                    final selectionLabel = quantity <= 0
                        ? context.uiText(
                            'Quantità da aggiungere: 0',
                            'Quantity to add: 0',
                          )
                        : _isBuy && item.cost != null
                        ? context.uiText(
                            'Nel carrello: $quantity • ₽ ${item.cost! * quantity}',
                            'In cart: $quantity • ₽ ${item.cost! * quantity}',
                          )
                        : context.uiText(
                            'Da aggiungere: $quantity',
                            'To add: $quantity',
                          );

                    return Card(
                      child: ListTile(
                        leading: _ItemSprite(item: item),
                        title: Text(item.name),
                        subtitle: Text(
                          '${_typeLabel(item.type)} • $costLabel\n$selectionLabel',
                        ),
                        isThreeLine: true,
                        onTap: () => _showItemDetails(item),
                        trailing: _QuantitySelector(
                          quantity: quantity,
                          canDecrease: quantity > 0,
                          canIncrease: canSelect && _canIncrease(item),
                          onDecrease: () => _setQuantity(item, quantity - 1),
                          onIncrease: () => _setQuantity(item, quantity + 1),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isBuy
                          ? context.uiText(
                              '$_selectedTypeCount tipi • $_selectedUnitCount unità • Totale ₽ $_totalCost',
                              '$_selectedTypeCount types • $_selectedUnitCount units • Total ₽ $_totalCost',
                            )
                          : context.uiText(
                              '$_selectedTypeCount tipi • $_selectedUnitCount unità',
                              '$_selectedTypeCount types • $_selectedUnitCount units',
                            ),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _canConfirm ? _confirmCart : null,
                    icon: Icon(
                      _isBuy ? Icons.shopping_cart_checkout : Icons.add_box,
                    ),
                    label: Text(
                      _isBuy
                          ? context.uiText('COMPRA', 'BUY')
                          : context.uiText('AGGIUNGI', 'ADD'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

'''
text = regex_once(
    text,
    r'''class _ItemPickerResult \{.*?\nclass _QuantitySelector''',
    new_picker + 'class _QuantitySelector',
    path,
)
write(path, text)


# ---------------------------------------------------------------------------
# Tests reflect free narrative background and concrete starting equipment.
# ---------------------------------------------------------------------------
path = 'test/trainer_manual_identity_fields_test.dart'
write(
    path,
    r'''import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/trainer_manual_options.dart';
import 'package:pokedex_5e_ita/models/trainer_starting_equipment.dart';
import 'package:pokedex_5e_ita/models/trainer_ui_localization.dart';

void main() {
  test('manual starting packs expose descriptions and inventory', () {
    expect(TrainerManualOptions.startingPacks, hasLength(3));
    TrainerStartingEquipment.validatePacks();

    for (final value in TrainerManualOptions.startingPacks) {
      expect(TrainerUiLocalization.startingPackDescriptions[value], isNotEmpty);
      final inventory = TrainerStartingEquipment.inventoryForPack(value);
      expect(inventory['poke-ball'], 5);
      expect(inventory['potion'], 1);
      expect(inventory['trainer-license'], 1);
      expect(inventory['trainer-pokedex'], 1);
      expect(inventory['trainer-backpack'], 1);
    }
  });

  test('trainer equipment catalog contains every custom starting item', () {
    final catalogIds = TrainerStartingEquipment.catalogItems
        .map((item) => item.id)
        .toSet();
    final customInventoryIds = <String>{
      ...TrainerStartingEquipment.baseInventory.keys,
      for (final pack in TrainerStartingEquipment.packInventory.values)
        ...pack.keys,
    }..removeAll({'poke-ball', 'potion'});

    expect(catalogIds, containsAll(customInventoryIds));
  });
}
''',
)

# Keep the downloadable debug APK workflow sensitive to the new prototype files.
path = '.github/workflows/build-compact-test-apk.yml'
text = read(path)
text = re.sub(
    r'^# Rebuild marker:.*$',
    '# Rebuild marker: narrative background, starting inventory, and cart sheets',
    text,
    count=1,
    flags=re.M,
)
anchor = '      - lib/screens/trainer/trainer_sheet_mobile.dart\n'
extra_paths = '''      - lib/screens/trainer/trainer_sheet_mobile.dart
      - lib/screens/onboarding/first_launch_onboarding_screen.dart
      - lib/screens/bag/bag_screen.dart
      - lib/services/profile_creation_service.dart
      - lib/repositories/bag_inventory_repository.dart
      - lib/repositories/item_repository.dart
      - lib/models/trainer_starting_equipment.dart
'''
text = replace_once(text, anchor, extra_paths, path)
write(path, text)
