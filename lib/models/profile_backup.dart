import 'bag_inventory_entry.dart';
import 'battle_session.dart';
import 'breeding_egg.dart';
import 'custom_pokemon_definition.dart';
import 'encounter_collection.dart';
import 'master_battle_session.dart';
import 'pc_pokemon.dart';
import 'pokedex_entry.dart';
import 'profile_settings.dart';
import 'saved_encounter.dart';
import 'saved_npc_trainer.dart';
import 'team_slot.dart';
import 'user_profile.dart';

class ProfileBackup {
  static const int currentFormatVersion = 6;

  ProfileBackup({
    required this.formatVersion,
    required this.exportedAt,
    required this.profile,
    required this.pokedex,
    required this.team,
    required this.pc,
    required this.bag,
    required this.settings,
    required this.battleSession,
    this.encounterCollections = const [],
    this.savedEncounters = const [],
    this.savedNpcTrainers = const [],
    this.masterBattleSession,
    this.breedingEggs = const [],
    this.customPokemon = const [],
  });

  final int formatVersion;
  final DateTime exportedAt;
  final UserProfile profile;
  final List<PokedexEntry> pokedex;
  final List<TeamSlot> team;
  final List<PcPokemon> pc;
  final List<BagInventoryEntry> bag;
  final ProfileSettings settings;
  final BattleSession? battleSession;
  final List<EncounterCollection> encounterCollections;
  final List<SavedEncounter> savedEncounters;
  final List<SavedNpcTrainer> savedNpcTrainers;
  final MasterBattleSession? masterBattleSession;
  final List<BreedingEgg> breedingEggs;
  final List<CustomPokemonDefinition> customPokemon;

  int get seenSpecies => pokedex.where((entry) => entry.seen).length;

  int get caughtSpecies => pokedex.where((entry) => entry.caught).length;

  int get caughtForms => pokedex.fold(
    0,
    (total, entry) =>
        total + entry.forms.values.where((form) => form.caught).length,
  );

  int get occupiedTeamSlots =>
      team.where((slot) => slot.pokemonId != null).length;

  int get bagItemKinds => bag.where((entry) => entry.quantity > 0).length;

  int get bagItemQuantity => bag.fold(
    0,
    (total, entry) => total + (entry.quantity > 0 ? entry.quantity : 0),
  );

  Set<int> get referencedPokemonIds {
    final ids = <int>{};
    for (final slot in team) {
      final id = slot.pokemonId;
      if (id != null && id > 0) ids.add(id);
    }
    ids.addAll(pc.map((pokemon) => pokemon.pokemonId).where((id) => id > 0));
    ids.addAll(pokedex.map((entry) => entry.pokemonId).where((id) => id > 0));
    for (final collection in encounterCollections) {
      ids.addAll(
        collection.entries
            .map((entry) => entry.pokemonId)
            .where((id) => id > 0),
      );
    }
    for (final encounter in savedEncounters) {
      ids.addAll(
        encounter.members
            .map((member) => member.pokemonId)
            .where((id) => id > 0),
      );
    }
    for (final trainer in savedNpcTrainers) {
      ids.addAll(
        trainer.team.map((member) => member.pokemonId).where((id) => id > 0),
      );
    }
    final playerBattle = battleSession;
    if (playerBattle != null) {
      ids.addAll(
        playerBattle.pokemonStates.values
            .map((state) => state.pokemonId)
            .where((id) => id > 0),
      );
    }
    final masterBattle = masterBattleSession;
    if (masterBattle != null) {
      for (final participant in masterBattle.participants) {
        ids.addAll(
          participant.team
              .map((state) => state.pokemon.pokemonId)
              .where((id) => id > 0),
        );
      }
    }
    ids.addAll(breedingEggs.map((egg) => egg.speciesId).where((id) => id > 0));
    return Set<int>.unmodifiable(ids);
  }

  Map<String, dynamic> toJson() {
    return {
      'formatVersion': formatVersion,
      'exportedAt': exportedAt.toIso8601String(),
      'profile': profile.toJson(),
      'pokedex': pokedex.map((entry) => entry.toJson()).toList(growable: false),
      'team': team.map((slot) => slot.toJson()).toList(growable: false),
      'pc': pc.map((pokemon) => pokemon.toJson()).toList(growable: false),
      'bag': bag.map((entry) => entry.toJson()).toList(growable: false),
      'settings': settings.toJson(),
      'battleSession': battleSession?.toJson(),
      'encounterCollections': encounterCollections
          .map((collection) => collection.toJson())
          .toList(growable: false),
      'savedEncounters': savedEncounters
          .map((encounter) => encounter.toJson())
          .toList(growable: false),
      'savedNpcTrainers': savedNpcTrainers
          .map((trainer) => trainer.toJson())
          .toList(growable: false),
      'masterBattleSession': masterBattleSession?.toJson(),
      'breedingEggs': breedingEggs
          .map((egg) => egg.toJson())
          .toList(growable: false),
      if (formatVersion >= 6)
        'customPokemon': customPokemon
            .map((definition) => definition.toJson())
            .toList(growable: false),
    };
  }

  factory ProfileBackup.fromJson(Map<String, dynamic> json) {
    final version = _readRequiredInt(json['formatVersion'], 'formatVersion');
    if (version < 1) {
      throw const FormatException('Versione del backup non valida.');
    }
    if (version > currentFormatVersion) {
      throw FormatException(
        'Questo backup usa il formato $version, ma l’app supporta fino al '
        'formato $currentFormatVersion.',
      );
    }

    final profileJson = _readRequiredMap(json['profile'], 'profile');
    final settingsJson = json['settings'];
    final battleJson = json['battleSession'];

    final backup = ProfileBackup(
      formatVersion: version,
      exportedAt:
          DateTime.tryParse(json['exportedAt']?.toString() ?? '') ??
          DateTime.now(),
      profile: UserProfile.fromJson(profileJson),
      pokedex: [
        for (final value in _readMapList(json['pokedex'], 'pokedex'))
          PokedexEntry.fromJson(value),
      ],
      team: [
        for (final value in _readMapList(json['team'], 'team'))
          TeamSlot.fromJson(value),
      ],
      pc: [
        for (final value in _readMapList(json['pc'], 'pc'))
          PcPokemon.fromJson(value),
      ],
      bag: [
        for (final value in _readMapList(json['bag'], 'bag'))
          BagInventoryEntry.fromJson(value),
      ],
      settings: settingsJson is Map
          ? ProfileSettings.fromJson(Map<String, dynamic>.from(settingsJson))
          : ProfileSettings.defaults(),
      battleSession: battleJson is Map
          ? BattleSession.fromJson(Map<String, dynamic>.from(battleJson))
          : null,
      encounterCollections: [
        for (final value in _readMapList(
          json['encounterCollections'],
          'encounterCollections',
        ))
          EncounterCollection.fromJson(value),
      ],
      savedEncounters: [
        for (final value in _readMapList(
          json['savedEncounters'],
          'savedEncounters',
        ))
          SavedEncounter.fromJson(value),
      ],
      savedNpcTrainers: [
        for (final value in _readMapList(
          json['savedNpcTrainers'],
          'savedNpcTrainers',
        ))
          SavedNpcTrainer.fromJson(value),
      ],
      masterBattleSession: json['masterBattleSession'] is Map
          ? MasterBattleSession.fromJson(
              Map<String, dynamic>.from(json['masterBattleSession'] as Map),
            )
          : null,
      breedingEggs: [
        for (final value in _readMapList(json['breedingEggs'], 'breedingEggs'))
          BreedingEgg.fromJson(value),
      ],
      customPokemon: [
        for (final value in _readMapList(
          json['customPokemon'],
          'customPokemon',
        ))
          CustomPokemonDefinition.fromJson(value),
      ],
    );

    backup.validate();
    return backup;
  }

  void validate() {
    if (profile.id.trim().isEmpty) {
      throw const FormatException('Il profilo del backup non ha un ID valido.');
    }
    if (profile.name.trim().isEmpty) {
      throw const FormatException(
        'Il profilo del backup non ha un nome valido.',
      );
    }

    final teamSlots = <int>{};
    for (final slot in team) {
      if (slot.slotIndex < 0 || slot.slotIndex > 5) {
        throw FormatException(
          'Lo slot squadra ${slot.slotIndex} non è valido.',
        );
      }
      if (!teamSlots.add(slot.slotIndex)) {
        throw FormatException(
          'Lo slot squadra ${slot.slotIndex} è presente più volte.',
        );
      }
    }

    final pokedexIds = <int>{};
    for (final entry in pokedex) {
      if (entry.pokemonId <= 0) {
        throw const FormatException(
          'Il backup contiene un Pokémon non valido.',
        );
      }
      if (!pokedexIds.add(entry.pokemonId)) {
        throw FormatException(
          'Il Pokémon #${entry.pokemonId} è duplicato nel Pokédex.',
        );
      }
    }

    final pcIds = <String>{};
    for (final pokemon in pc) {
      if (pokemon.id.trim().isEmpty || pokemon.pokemonId <= 0) {
        throw const FormatException(
          'Il backup contiene un Pokémon del PC non valido.',
        );
      }
      if (!pcIds.add(pokemon.id)) {
        throw FormatException(
          'Il Pokémon del PC ${pokemon.id} è presente più volte.',
        );
      }
    }

    final bagIds = <String>{};
    for (final entry in bag) {
      if (entry.itemId.trim().isEmpty || entry.quantity <= 0) {
        throw const FormatException(
          'Il backup contiene un oggetto dello zaino non valido.',
        );
      }
      final key = entry.itemId.trim().toLowerCase();
      if (!bagIds.add(key)) {
        throw FormatException(
          'L’oggetto ${entry.itemId} è presente più volte nello zaino.',
        );
      }
    }

    final collectionIds = <String>{};
    for (final collection in encounterCollections) {
      if (collection.id.trim().isEmpty || collection.name.trim().isEmpty) {
        throw const FormatException(
          'Il backup contiene una raccolta incontri non valida.',
        );
      }
      if (!collectionIds.add(collection.id)) {
        throw FormatException(
          'La raccolta ${collection.name} è presente più volte.',
        );
      }
      if (!collection.isReady) {
        throw FormatException(
          'La raccolta ${collection.name} non totalizza il 100%.',
        );
      }
    }

    final trainerIds = <String>{};
    for (final trainer in savedNpcTrainers) {
      if (!trainer.isValid) {
        throw const FormatException(
          'Il backup contiene un Allenatore PNG non valido.',
        );
      }
      if (!trainerIds.add(trainer.id)) {
        throw FormatException(
          'L’Allenatore PNG ${trainer.name} è presente più volte.',
        );
      }
    }
    if (masterBattleSession != null && !masterBattleSession!.isValid) {
      throw const FormatException(
        'Il backup contiene una sessione del Master non valida.',
      );
    }

    final eggIds = <String>{};
    for (final egg in breedingEggs) {
      if (egg.id.trim().isEmpty ||
          egg.speciesId <= 0 ||
          egg.hatchTime <= 0 ||
          egg.incubationRemaining < 0 ||
          egg.incubationRemaining > egg.hatchTime) {
        throw const FormatException(
          'Il backup contiene un uovo Pokémon non valido.',
        );
      }
      if (!eggIds.add(egg.id)) {
        throw FormatException('L’uovo ${egg.id} è presente più volte.');
      }
    }

    final savedEncounterIds = <String>{};
    for (final encounter in savedEncounters) {
      if (!encounter.isValid) {
        throw const FormatException(
          'Il backup contiene un incontro salvato non valido.',
        );
      }
      if (!savedEncounterIds.add(encounter.id)) {
        throw FormatException(
          'L’incontro ${encounter.name} è presente più volte.',
        );
      }
    }

    final customByPokemonId = <int, CustomPokemonDefinition>{};
    final customStableIds = <String>{};
    for (final definition in customPokemon) {
      definition.validate();
      if (!customStableIds.add(definition.stableId) ||
          customByPokemonId.containsKey(definition.pokemonId)) {
        throw const FormatException(
          'Il backup contiene definizioni Fakemon duplicate.',
        );
      }
      customByPokemonId[definition.pokemonId] = definition;
    }
    if (formatVersion >= 6) {
      final referencedCustomIds = referencedPokemonIds
          .where((id) => id >= CustomPokemonDefinition.firstCustomPokemonId)
          .toSet();
      final missing = referencedCustomIds.difference(
        customByPokemonId.keys.toSet(),
      );
      if (missing.isNotEmpty) {
        final ordered = missing.toList()..sort();
        throw FormatException(
          'Il backup non include le definizioni Fakemon per '
          '${ordered.map((id) => '#$id').join(', ')}.',
        );
      }
      final unused = customByPokemonId.keys.toSet().difference(
        referencedCustomIds,
      );
      if (unused.isNotEmpty) {
        throw const FormatException(
          'Il backup contiene definizioni Fakemon non utilizzate.',
        );
      }
    }
  }

  static Map<String, dynamic> _readRequiredMap(dynamic value, String label) {
    if (value is! Map) {
      throw FormatException('La sezione "$label" del backup non è valida.');
    }
    return Map<String, dynamic>.from(value);
  }

  static List<Map<String, dynamic>> _readMapList(dynamic value, String label) {
    if (value == null) return const [];
    if (value is! List) {
      throw FormatException('La sezione "$label" del backup non è valida.');
    }

    return [
      for (final item in value)
        if (item is Map)
          Map<String, dynamic>.from(item)
        else
          throw FormatException(
            'La sezione "$label" contiene un elemento non valido.',
          ),
    ];
  }

  static int _readRequiredInt(dynamic value, String label) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed == null) {
      throw FormatException('Il campo "$label" del backup non è valido.');
    }
    return parsed;
  }
}
