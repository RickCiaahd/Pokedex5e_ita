import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/bag_inventory_entry.dart';
import 'package:pokedex_5e_ita/models/battle_session.dart';
import 'package:pokedex_5e_ita/models/breeding_egg.dart';
import 'package:pokedex_5e_ita/models/pc_pokemon.dart';
import 'package:pokedex_5e_ita/models/generated_encounter.dart';
import 'package:pokedex_5e_ita/models/pokedex_entry.dart';
import 'package:pokedex_5e_ita/models/profile_backup.dart';
import 'package:pokedex_5e_ita/models/profile_settings.dart';
import 'package:pokedex_5e_ita/models/saved_encounter.dart';
import 'package:pokedex_5e_ita/models/team_slot.dart';
import 'package:pokedex_5e_ita/models/user_profile.dart';
import 'package:pokedex_5e_ita/services/profile_backup_service.dart';

void main() {
  test('round-trips every profile section through JSON', () {
    final now = DateTime.utc(2026, 7, 11, 18, 30);
    final profile = UserProfile(
      id: 'profile-1',
      name: 'Misty',
      createdAt: now,
      updatedAt: now,
      trainerLevel: 7,
      money: 4200,
      trainerRace: 'Umano',
      starterPokemon: 'Staryu',
    );
    final pokedexEntry = PokedexEntry.empty(19)
        .setFormState(formName: null, seen: true, caught: false)
        .setFormState(formName: 'Alolan', seen: true, caught: true);
    final teamSlot = TeamSlot(
      slotIndex: 0,
      pokemonId: 19,
      experience: 1500,
      currentHp: 14,
      nickname: 'Topolino',
      formName: 'Alolan',
      isShiny: true,
      selectedMoves: const ['quick-attack'],
    );
    final pcPokemon = PcPokemon(
      id: 'pc-1',
      pokemonId: 25,
      capturedAt: now,
      currentHp: 18,
      nickname: 'Sparky',
    );
    final battleSession = BattleSession(
      profileId: profile.id,
      round: 4,
      turnIndex: 1,
      activeSlotIndex: 0,
      pokemonStates: {
        0: BattlePokemonState(
          slotIndex: 0,
          pokemonId: 19,
          identityKey: BattlePokemonState.identityKeyFor(teamSlot),
          remainingPp: const {'quick-attack': 7},
          volatileStatuses: const {'Confused'},
        ),
      },
      initiativeEntries: const [
        BattleInitiativeEntry(
          id: 'trainer',
          name: 'Misty + Pokémon',
          initiative: 16,
          isTrainerGroup: true,
        ),
      ],
      updatedAt: now,
    );
    final backup = ProfileBackup(
      formatVersion: ProfileBackup.currentFormatVersion,
      exportedAt: now,
      profile: profile,
      pokedex: [pokedexEntry],
      team: [
        teamSlot,
        for (var index = 1; index < 6; index++)
          TeamSlot(slotIndex: index, pokemonId: null),
      ],
      pc: [pcPokemon],
      bag: const [
        BagInventoryEntry(
          profileId: 'profile-1',
          itemId: 'potion',
          quantity: 3,
        ),
      ],
      settings: ProfileSettings(
        selectedRegion: 'Alola',
        showOnlyCaught: true,
        showOnlySeen: false,
      ),
      battleSession: battleSession,
      breedingEggs: [
        BreedingEgg(
          id: 'egg-1',
          speciesId: 403,
          parentNames: const ['Raticate', 'Luxio'],
          createdAt: now,
          hatchTime: 250,
          incubationRemaining: 120,
          nature: 'Jolly',
          gender: 'Female',
          ability: 'Rivalry',
          selectedMoves: const ['Tackle', 'Quick Attack'],
          inheritedMoves: const ['Quick Attack'],
        ),
      ],
      savedEncounters: [
        SavedEncounter(
          id: 'route-24',
          name: 'Percorso 24',
          source: EncounterSource.collection,
          party: const EncounterPartyProfile(averageLevel: 5),
          filters: const EncounterGeneratorFilters(level: 4),
          targetDifficulty: EncounterDifficulty.medium,
          members: const [
            SavedEncounterMember(
              pokemonId: 19,
              formName: 'Alolan',
              level: 4,
              nature: 'Jolly',
              selectedMoves: ['Tackle'],
              isShiny: false,
              maxHp: 18,
            ),
          ],
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );

    final service = ProfileBackupService();
    final decoded = service.decodeBackup(service.encodeBackup(backup));

    expect(decoded.profile.name, 'Misty');
    expect(decoded.profile.trainerLevel, 7);
    expect(decoded.pokedex.single.formFor('Alolan').caught, isTrue);
    expect(decoded.team.first.formName, 'Alolan');
    expect(decoded.team.first.isShiny, isTrue);
    expect(decoded.pc.single.nickname, 'Sparky');
    expect(decoded.bag.single.quantity, 3);
    expect(decoded.settings.selectedRegion, 'Alola');
    expect(decoded.battleSession?.round, 4);
    expect(decoded.savedEncounters.single.name, 'Percorso 24');
    expect(decoded.breedingEggs.single.speciesId, 403);
    expect(decoded.breedingEggs.single.incubationRemaining, 120);
    expect(decoded.savedEncounters.single.members.single.formName, 'Alolan');
    expect(decoded.battleSession?.pokemonStates[0]?.remainingPp, {
      'quick-attack': 7,
    });
    expect(decoded.seenSpecies, 1);
    expect(decoded.caughtSpecies, 1);
    expect(decoded.caughtForms, 1);
    expect(decoded.occupiedTeamSlots, 1);
    expect(decoded.bagItemQuantity, 3);
  });

  test('rejects backups created by a newer unsupported format', () {
    final service = ProfileBackupService();
    expect(
      () => service.decodeBackup('''
        {
          "formatVersion": 999,
          "profile": {}
        }
      '''),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects duplicate team slots before importing', () {
    final now = DateTime.utc(2026, 7, 11);
    final profile = UserProfile(
      id: 'profile-1',
      name: 'Duplicato',
      createdAt: now,
      updatedAt: now,
    );
    final backup = ProfileBackup(
      formatVersion: 1,
      exportedAt: now,
      profile: profile,
      pokedex: const [],
      team: [
        TeamSlot(slotIndex: 0, pokemonId: 1),
        TeamSlot(slotIndex: 0, pokemonId: 4),
      ],
      pc: const [],
      bag: const [],
      settings: ProfileSettings.defaults(),
      battleSession: null,
    );

    expect(backup.validate, throwsA(isA<FormatException>()));
  });
}
