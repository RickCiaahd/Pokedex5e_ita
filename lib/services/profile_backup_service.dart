import 'dart:convert';

import '../models/bag_inventory_entry.dart';
import '../models/battle_session.dart';
import '../models/profile_backup.dart';
import '../models/team_slot.dart';
import '../models/user_profile.dart';
import '../repositories/bag_inventory_repository.dart';
import '../repositories/battle_session_repository.dart';
import '../repositories/encounter_collection_repository.dart';
import '../repositories/pokedex_repositry.dart';
import '../repositories/pokemon_pc_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/setting_repository.dart';
import '../repositories/team_repository.dart';

class ProfileBackupService {
  ProfileBackupService({
    ProfileRepository? profileRepository,
    PokedexRepository? pokedexRepository,
    TeamRepository? teamRepository,
    PokemonPcRepository? pokemonPcRepository,
    BagInventoryRepository? bagRepository,
    SettingsRepository? settingsRepository,
    BattleSessionRepository? battleSessionRepository,
    EncounterCollectionRepository? encounterCollectionRepository,
  }) : _profileRepository = profileRepository ?? ProfileRepository(),
       _pokedexRepository = pokedexRepository ?? PokedexRepository(),
       _teamRepository = teamRepository ?? TeamRepository(),
       _pokemonPcRepository = pokemonPcRepository ?? PokemonPcRepository(),
       _bagRepository = bagRepository ?? BagInventoryRepository(),
       _settingsRepository = settingsRepository ?? SettingsRepository(),
       _battleSessionRepository =
           battleSessionRepository ?? BattleSessionRepository(),
       _encounterCollectionRepository =
           encounterCollectionRepository ?? EncounterCollectionRepository();

  final ProfileRepository _profileRepository;
  final PokedexRepository _pokedexRepository;
  final TeamRepository _teamRepository;
  final PokemonPcRepository _pokemonPcRepository;
  final BagInventoryRepository _bagRepository;
  final SettingsRepository _settingsRepository;
  final BattleSessionRepository _battleSessionRepository;
  final EncounterCollectionRepository _encounterCollectionRepository;

  Future<ProfileBackup> createBackup(String profileId) async {
    final profiles = await _profileRepository.getProfiles();
    UserProfile? profile;
    for (final candidate in profiles) {
      if (candidate.id == profileId) {
        profile = candidate;
        break;
      }
    }
    if (profile == null) {
      throw StateError('Il profilo richiesto non esiste.');
    }

    final pokedexEntries = await _pokedexRepository.getEntriesForProfile(
      profileId,
    );
    final team = await _teamRepository.getTeam(profileId);
    final pc = await _pokemonPcRepository.getPokemon(profileId);
    final bag = await _bagRepository.getInventory(profileId);
    final settings = await _settingsRepository.getSettings(profileId);
    final battleSession = await _battleSessionRepository.getSession(profileId);
    final encounterCollections = await _encounterCollectionRepository
        .getCollections(profileId);

    final pokedex = pokedexEntries.values.toList(growable: false)
      ..sort((a, b) => a.pokemonId.compareTo(b.pokemonId));
    team.sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
    bag.sort((a, b) => a.itemId.compareTo(b.itemId));

    return ProfileBackup(
      formatVersion: ProfileBackup.currentFormatVersion,
      exportedAt: DateTime.now(),
      profile: profile,
      pokedex: pokedex,
      team: team,
      pc: pc,
      bag: bag,
      settings: settings,
      battleSession: battleSession,
      encounterCollections: encounterCollections,
    );
  }

  String encodeBackup(ProfileBackup backup) {
    backup.validate();
    return const JsonEncoder.withIndent('  ').convert(backup.toJson());
  }

  ProfileBackup decodeBackup(String source) {
    final normalized = source.startsWith('\uFEFF')
        ? source.substring(1)
        : source;
    final decoded = jsonDecode(normalized);
    if (decoded is! Map) {
      throw const FormatException(
        'Il file selezionato non è un backup valido.',
      );
    }
    return ProfileBackup.fromJson(Map<String, dynamic>.from(decoded));
  }

  String fileNameFor(ProfileBackup backup) {
    final safeName = backup.profile.name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9àèéìòù]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final date = backup.exportedAt.toIso8601String().split('T').first;
    return 'pokedex-5e-${safeName.isEmpty ? 'profilo' : safeName}-$date.json';
  }

  Future<UserProfile> importBackup(
    ProfileBackup backup, {
    String? targetProfileId,
    String? profileName,
    bool setActive = true,
  }) async {
    backup.validate();
    final profiles = await _profileRepository.getProfiles();
    final existingIds = profiles.map((profile) => profile.id).toSet();
    final isNewProfile = targetProfileId == null;
    final destinationId = targetProfileId ?? _newProfileId(existingIds);
    final trimmedName = (profileName ?? backup.profile.name).trim();
    if (trimmedName.isEmpty) {
      throw const FormatException('Inserisci un nome valido per il profilo.');
    }
    if (!isNewProfile && !existingIds.contains(destinationId)) {
      throw StateError('Il profilo da sostituire non esiste più.');
    }

    final previousActiveProfile = await _profileRepository.getActiveProfile();
    final previousBackup = isNewProfile
        ? null
        : await createBackup(destinationId);
    final now = DateTime.now();
    final importedProfile = backup.profile.copyWith(
      id: destinationId,
      name: trimmedName,
      createdAt: isNewProfile ? now : backup.profile.createdAt,
      updatedAt: now,
    );

    try {
      await _writeBackupData(
        backup: backup,
        profile: importedProfile,
        destinationId: destinationId,
      );
      if (setActive) {
        await _profileRepository.setActiveProfile(destinationId);
      }
      return importedProfile;
    } catch (_) {
      if (previousBackup != null) {
        await _writeBackupData(
          backup: previousBackup,
          profile: previousBackup.profile,
          destinationId: destinationId,
        );
      } else {
        await deleteProfileCompletely(destinationId);
      }
      await _profileRepository.setActiveProfile(previousActiveProfile.id);
      rethrow;
    }
  }

  Future<UserProfile> duplicateProfile(String profileId) async {
    final backup = await createBackup(profileId);
    final profiles = await _profileRepository.getProfiles();
    final copyName = _nextCopyName(
      backup.profile.name,
      profiles.map((profile) => profile.name),
    );
    return importBackup(backup, profileName: copyName);
  }

  Future<void> deleteProfileCompletely(String profileId) async {
    await _clearProfileData(profileId);
    await _profileRepository.deleteProfile(profileId);
  }

  Future<void> _writeBackupData({
    required ProfileBackup backup,
    required UserProfile profile,
    required String destinationId,
  }) async {
    await _clearProfileData(destinationId);
    await _profileRepository.saveProfile(profile);

    final normalizedTeam = _normalizeTeam(backup.team);
    await _teamRepository.saveTeam(destinationId, normalizedTeam);
    await _pokemonPcRepository.savePokemon(destinationId, backup.pc);
    await _bagRepository.replaceInventory(
      profileId: destinationId,
      entries: [
        for (final entry in backup.bag)
          BagInventoryEntry(
            profileId: destinationId,
            itemId: entry.itemId,
            quantity: entry.quantity,
          ),
      ],
    );
    await _settingsRepository.saveSettings(destinationId, backup.settings);
    await _encounterCollectionRepository.replaceCollections(
      destinationId,
      backup.encounterCollections,
    );

    await _pokedexRepository.clearProfilePokedex(destinationId);
    for (final entry in backup.pokedex) {
      await _pokedexRepository.saveEntry(
        profileId: destinationId,
        entry: entry,
      );
    }

    final battleSession = backup.battleSession;
    if (battleSession != null) {
      await _battleSessionRepository.saveSession(
        BattleSession(
          profileId: destinationId,
          round: battleSession.round,
          turnIndex: battleSession.turnIndex,
          activeSlotIndex: battleSession.activeSlotIndex,
          pokemonStates: battleSession.pokemonStates,
          initiativeEntries: battleSession.initiativeEntries,
          updatedAt: battleSession.updatedAt,
        ),
      );
    }
  }

  Future<void> _clearProfileData(String profileId) async {
    await _pokedexRepository.clearProfilePokedex(profileId);
    await _pokemonPcRepository.deletePc(profileId);
    await _teamRepository.deleteTeam(profileId);
    await _bagRepository.deleteInventory(profileId);
    await _settingsRepository.deleteSettings(profileId);
    await _battleSessionRepository.deleteSession(profileId);
    await _encounterCollectionRepository.deleteCollections(profileId);
  }

  List<TeamSlot> _normalizeTeam(List<TeamSlot> source) {
    final byIndex = {for (final slot in source) slot.slotIndex: slot};
    return List<TeamSlot>.generate(
      6,
      (index) => byIndex[index] ?? TeamSlot(slotIndex: index, pokemonId: null),
      growable: false,
    );
  }

  String _newProfileId(Set<String> existingIds) {
    var timestamp = DateTime.now().microsecondsSinceEpoch;
    var candidate = timestamp.toString();
    while (existingIds.contains(candidate)) {
      timestamp += 1;
      candidate = timestamp.toString();
    }
    return candidate;
  }

  String _nextCopyName(String sourceName, Iterable<String> existingNames) {
    final existing = existingNames
        .map((name) => name.trim().toLowerCase())
        .toSet();
    final base = '${sourceName.trim()} (copia)'.trim();
    if (!existing.contains(base.toLowerCase())) return base;

    var index = 2;
    while (existing.contains('$base $index'.toLowerCase())) {
      index += 1;
    }
    return '$base $index';
  }
}
