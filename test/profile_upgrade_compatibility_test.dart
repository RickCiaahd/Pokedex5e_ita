import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pokedex_5e_ita/models/bag_inventory_entry.dart';
import 'package:pokedex_5e_ita/models/profile_settings.dart';
import 'package:pokedex_5e_ita/models/team_slot.dart';
import 'package:pokedex_5e_ita/repositories/bag_inventory_repository.dart';
import 'package:pokedex_5e_ita/repositories/profile_repository.dart';
import 'package:pokedex_5e_ita/repositories/setting_repository.dart';
import 'package:pokedex_5e_ita/repositories/team_repository.dart';
import 'package:pokedex_5e_ita/services/profile_backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'trainer_atlas_upgrade_compatibility_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await hiveDirectory.exists()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test('profili e dati locali sopravvivono alla riapertura dello stesso store', () async {
    final profiles = ProfileRepository();
    final teams = TeamRepository();
    final bag = BagInventoryRepository();
    final settings = SettingsRepository();

    final profile = await profiles.createProfile('Aggiornamento sicuro');
    await profiles.setActiveProfile(profile.id);
    await teams.saveTeam(profile.id, [
      TeamSlot(
        slotIndex: 0,
        pokemonId: 25,
        nickname: 'Compagno',
        currentHp: 19,
        selectedMoves: const ['thunder-shock'],
      ),
      for (var index = 1; index < 6; index++)
        TeamSlot(slotIndex: index, pokemonId: null),
    ]);
    await bag.replaceInventory(
      profileId: profile.id,
      entries: [
        BagInventoryEntry(
          profileId: profile.id,
          itemId: 'potion',
          quantity: 7,
        ),
      ],
    );
    await settings.saveSettings(
      profile.id,
      ProfileSettings(
        selectedRegion: 'Johto',
        showOnlyCaught: true,
        showOnlySeen: false,
      ),
    );

    // Simula la chiusura della vecchia versione e l'avvio della nuova senza
    // cancellare o ricreare la directory dati dell'applicazione.
    await Hive.close();
    Hive.init(hiveDirectory.path);

    final reopenedProfiles = ProfileRepository();
    final reopenedTeams = TeamRepository();
    final reopenedBag = BagInventoryRepository();
    final reopenedSettings = SettingsRepository();

    final active = await reopenedProfiles.getActiveProfile();
    expect(active.id, profile.id);
    expect(active.name, 'Aggiornamento sicuro');

    final reopenedTeam = await reopenedTeams.getTeam(profile.id);
    expect(reopenedTeam, hasLength(6));
    expect(reopenedTeam.first.pokemonId, 25);
    expect(reopenedTeam.first.nickname, 'Compagno');
    expect(reopenedTeam.first.selectedMoves, ['thunder-shock']);

    final reopenedInventory = await reopenedBag.getInventory(profile.id);
    expect(reopenedInventory.single.itemId, 'potion');
    expect(reopenedInventory.single.quantity, 7);
    expect(
      (await reopenedSettings.getSettings(profile.id)).selectedRegion,
      'Johto',
    );
  });

  test('i formati backup storici da 1 a 5 restano decodificabili', () {
    final service = ProfileBackupService();
    final timestamp = DateTime.utc(2025, 1, 15, 12).toIso8601String();

    for (var version = 1; version <= 5; version++) {
      final source = jsonEncode({
        'formatVersion': version,
        'exportedAt': timestamp,
        'profile': {
          'id': 'legacy-v$version',
          'name': 'Backup storico v$version',
          'createdAt': timestamp,
          'updatedAt': timestamp,
          'trainerLevel': 4,
          'money': 1200,
        },
        'pokedex': <Object>[],
        'team': <Object>[],
        'pc': <Object>[],
        'bag': <Object>[],
      });

      final backup = service.decodeBackup(source);

      expect(backup.formatVersion, version);
      expect(backup.profile.name, 'Backup storico v$version');
      expect(backup.profile.trainerLevel, 4);
      expect(backup.profile.money, 1200);
      expect(backup.settings.selectedRegion, 'Kanto');
      expect(backup.encounterCollections, isEmpty);
      expect(backup.savedEncounters, isEmpty);
      expect(backup.savedNpcTrainers, isEmpty);
      expect(backup.breedingEggs, isEmpty);
      expect(backup.customPokemon, isEmpty);
    }
  });
}
