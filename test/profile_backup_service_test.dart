import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pokedex_5e_ita/models/bag_inventory_entry.dart';
import 'package:pokedex_5e_ita/models/battle_session.dart';
import 'package:pokedex_5e_ita/models/pc_pokemon.dart';
import 'package:pokedex_5e_ita/models/pokedex_entry.dart';
import 'package:pokedex_5e_ita/models/profile_settings.dart';
import 'package:pokedex_5e_ita/models/team_slot.dart';
import 'package:pokedex_5e_ita/repositories/bag_inventory_repository.dart';
import 'package:pokedex_5e_ita/repositories/battle_session_repository.dart';
import 'package:pokedex_5e_ita/repositories/pokedex_repositry.dart';
import 'package:pokedex_5e_ita/repositories/pokemon_pc_repository.dart';
import 'package:pokedex_5e_ita/repositories/profile_repository.dart';
import 'package:pokedex_5e_ita/repositories/setting_repository.dart';
import 'package:pokedex_5e_ita/repositories/team_repository.dart';
import 'package:pokedex_5e_ita/services/profile_backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;
  final profileRepository = ProfileRepository();
  final pokedexRepository = PokedexRepository();
  final teamRepository = TeamRepository();
  final pcRepository = PokemonPcRepository();
  final bagRepository = BagInventoryRepository();
  final settingsRepository = SettingsRepository();
  final battleRepository = BattleSessionRepository();
  final backupService = ProfileBackupService();

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'pokedex_profile_backup_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  test(
    'imports every section with a new ID and deletes it completely',
    () async {
      final source = await profileRepository.createProfile('Ash');
      await profileRepository.setActiveProfile(source.id);

      final team = [
        TeamSlot(
          slotIndex: 0,
          pokemonId: 25,
          currentHp: 21,
          nickname: 'Pikachu',
          isShiny: true,
        ),
        for (var index = 1; index < 6; index++)
          TeamSlot(slotIndex: index, pokemonId: null),
      ];
      await teamRepository.saveTeam(source.id, team);
      await pcRepository.savePokemon(source.id, [
        PcPokemon(
          id: 'pc-bulbasaur',
          pokemonId: 1,
          currentHp: 18,
          nickname: 'Bulby',
        ),
      ]);
      await bagRepository.replaceInventory(
        profileId: source.id,
        entries: [
          BagInventoryEntry(
            profileId: source.id,
            itemId: 'potion',
            quantity: 4,
          ),
        ],
      );
      await settingsRepository.saveSettings(
        source.id,
        ProfileSettings(
          selectedRegion: 'Johto',
          showOnlyCaught: true,
          showOnlySeen: false,
        ),
      );
      await pokedexRepository.saveEntry(
        profileId: source.id,
        entry: PokedexEntry.empty(
          25,
        ).setFormState(formName: null, seen: true, caught: true),
      );
      await battleRepository.saveSession(
        BattleSession(
          profileId: source.id,
          round: 3,
          turnIndex: 0,
          activeSlotIndex: 0,
          pokemonStates: {
            0: BattlePokemonState(
              slotIndex: 0,
              pokemonId: 25,
              identityKey: BattlePokemonState.identityKeyFor(team.first),
              remainingPp: const {'thunder-shock': 8},
              volatileStatuses: const {'Confused'},
            ),
          },
          initiativeEntries: const [
            BattleInitiativeEntry(
              id: 'trainer',
              name: 'Ash + Pokémon',
              initiative: 17,
              isTrainerGroup: true,
            ),
          ],
          updatedAt: DateTime.utc(2026, 7, 11),
        ),
      );

      final backup = await backupService.createBackup(source.id);
      final imported = await backupService.importBackup(
        backup,
        profileName: 'Ash importato',
      );

      expect(imported.id, isNot(source.id));
      expect(imported.name, 'Ash importato');
      expect((await profileRepository.getActiveProfile()).id, imported.id);

      final importedTeam = await teamRepository.getTeam(imported.id);
      expect(importedTeam, hasLength(6));
      expect(importedTeam.first.pokemonId, 25);
      expect(importedTeam.first.isShiny, isTrue);
      expect(
        (await pcRepository.getPokemon(imported.id)).single.nickname,
        'Bulby',
      );

      final importedBag = await bagRepository.getInventory(imported.id);
      expect(importedBag.single.profileId, imported.id);
      expect(importedBag.single.quantity, 4);
      expect(
        (await settingsRepository.getSettings(imported.id)).selectedRegion,
        'Johto',
      );
      expect(
        (await pokedexRepository.getEntry(
          profileId: imported.id,
          pokemonId: 25,
        )).caught,
        isTrue,
      );
      final importedBattle = await battleRepository.getSession(imported.id);
      expect(importedBattle?.profileId, imported.id);
      expect(importedBattle?.round, 3);
      expect(importedBattle?.pokemonStates[0]?.remainingPp['thunder-shock'], 8);

      await profileRepository.setActiveProfile(source.id);
      await backupService.deleteProfileCompletely(imported.id);

      expect(
        (await profileRepository.getProfiles()).any(
          (profile) => profile.id == imported.id,
        ),
        isFalse,
      );
      expect(
        (await teamRepository.getTeam(
          imported.id,
        )).every((slot) => slot.pokemonId == null),
        isTrue,
      );
      expect(await pcRepository.getPokemon(imported.id), isEmpty);
      expect(await bagRepository.getInventory(imported.id), isEmpty);
      expect(
        await pokedexRepository.getEntriesForProfile(imported.id),
        isEmpty,
      );
      expect(
        (await settingsRepository.getSettings(imported.id)).selectedRegion,
        'Kanto',
      );
      expect(await battleRepository.getSession(imported.id), isNull);
    },
  );
}
