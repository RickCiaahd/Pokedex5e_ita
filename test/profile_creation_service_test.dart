import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/team_slot.dart';
import 'package:pokedex_5e_ita/models/user_profile.dart';
import 'package:pokedex_5e_ita/repositories/pokedex_repositry.dart';
import 'package:pokedex_5e_ita/repositories/profile_repository.dart';
import 'package:pokedex_5e_ita/repositories/team_repository.dart';
import 'package:pokedex_5e_ita/services/app_launch_service.dart';
import 'package:pokedex_5e_ita/services/profile_creation_service.dart';

void main() {
  group('ProfileCreationService', () {
    test('creates and activates a complete guided profile', () async {
      final profiles = _FakeProfileRepository(
        initialProfiles: [_profile(id: 'old', name: 'Old')],
        activeProfileId: 'old',
      );
      final teams = _FakeTeamRepository();
      final pokedex = _FakePokedexRepository();
      final launch = _FakeAppLaunchService();
      final service = ProfileCreationService(
        profileRepository: profiles,
        teamRepository: teams,
        pokedexRepository: pokedex,
        appLaunchService: launch,
      );
      final profile = _profile(id: 'guided', name: 'Misty');
      final starterSlot = TeamSlot(slotIndex: 0, pokemonId: 7);

      final created = await service.createGuidedProfile(
        profile: profile,
        starterSlot: starterSlot,
        starterPokemonId: 7,
        starterSpeciesName: 'Squirtle',
      );

      expect(created, same(profile));
      expect(profiles.saved.keys, containsAll(['old', 'guided']));
      expect(profiles.activeProfileId, 'guided');
      expect(teams.slots['guided'], starterSlot);
      expect(pokedex.markedProfiles, {'guided'});
      expect(launch.completed, isFalse);
    });

    test('rolls back every write and restores the previous profile', () async {
      final profiles = _FakeProfileRepository(
        initialProfiles: [_profile(id: 'old', name: 'Old')],
        activeProfileId: 'old',
      );
      final teams = _FakeTeamRepository();
      final pokedex = _FakePokedexRepository(failOnUpdate: true);
      final service = ProfileCreationService(
        profileRepository: profiles,
        teamRepository: teams,
        pokedexRepository: pokedex,
        appLaunchService: _FakeAppLaunchService(),
      );

      await expectLater(
        service.createGuidedProfile(
          profile: _profile(id: 'broken', name: 'Broken'),
          starterSlot: TeamSlot(slotIndex: 0, pokemonId: 4),
          starterPokemonId: 4,
          starterSpeciesName: 'Charmander',
        ),
        throwsStateError,
      );

      expect(profiles.saved.keys, ['old']);
      expect(profiles.activeProfileId, 'old');
      expect(teams.slots, isEmpty);
      expect(pokedex.markedProfiles, isEmpty);
    });

    test('first launch failure does not leave a partial profile active', () async {
      final profiles = _FakeProfileRepository();
      final teams = _FakeTeamRepository();
      final pokedex = _FakePokedexRepository();
      final launch = _FakeAppLaunchService(failOnComplete: true);
      final service = ProfileCreationService(
        profileRepository: profiles,
        teamRepository: teams,
        pokedexRepository: pokedex,
        appLaunchService: launch,
      );

      await expectLater(
        service.createGuidedProfile(
          profile: _profile(id: 'first', name: 'First'),
          starterSlot: TeamSlot(slotIndex: 0, pokemonId: 1),
          starterPokemonId: 1,
          starterSpeciesName: 'Bulbasaur',
          markOnboardingCompleted: true,
        ),
        throwsStateError,
      );

      expect(profiles.saved, isEmpty);
      expect(profiles.activeProfileId, isNull);
      expect(teams.slots, isEmpty);
      expect(pokedex.markedProfiles, isEmpty);
      expect(launch.completed, isFalse);
    });

    test('quick creation uses the same safe activation flow', () async {
      final profiles = _FakeProfileRepository(
        initialProfiles: [_profile(id: 'old', name: 'Old')],
        activeProfileId: 'old',
      );
      final service = ProfileCreationService(
        profileRepository: profiles,
        teamRepository: _FakeTeamRepository(),
        pokedexRepository: _FakePokedexRepository(),
        appLaunchService: _FakeAppLaunchService(),
      );

      final created = await service.createEmptyProfile(
        'Brock',
        profileImageBase64: 'encoded-image',
      );

      expect(created.name, 'Brock');
      expect(created.profileImageBase64, 'encoded-image');
      expect(profiles.activeProfileId, created.id);
      expect(profiles.saved[created.id], same(created));
    });
  });
}

UserProfile _profile({required String id, required String name}) {
  final now = DateTime(2026, 7, 30);
  return UserProfile(id: id, name: name, createdAt: now, updatedAt: now);
}

class _FakeProfileRepository extends ProfileRepository {
  _FakeProfileRepository({
    List<UserProfile> initialProfiles = const [],
    this.activeProfileId,
  }) : saved = {for (final profile in initialProfiles) profile.id: profile};

  final Map<String, UserProfile> saved;
  String? activeProfileId;

  @override
  Future<String?> getActiveProfileId() async {
    return saved.containsKey(activeProfileId) ? activeProfileId : null;
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    saved[profile.id] = profile;
  }

  @override
  Future<void> setActiveProfile(String profileId) async {
    activeProfileId = profileId;
  }

  @override
  Future<void> clearActiveProfile() async {
    activeProfileId = null;
  }

  @override
  Future<void> deleteProfile(String profileId) async {
    saved.remove(profileId);
    if (activeProfileId == profileId) activeProfileId = null;
  }
}

class _FakeTeamRepository extends TeamRepository {
  final Map<String, TeamSlot> slots = {};

  @override
  Future<void> updateSlot({
    required String profileId,
    required TeamSlot updatedSlot,
  }) async {
    slots[profileId] = updatedSlot;
  }

  @override
  Future<void> deleteTeam(String profileId) async {
    slots.remove(profileId);
  }
}

class _FakePokedexRepository extends PokedexRepository {
  _FakePokedexRepository({this.failOnUpdate = false});

  final bool failOnUpdate;
  final Set<String> markedProfiles = {};

  @override
  Future<void> updateMarkMode({
    required String profileId,
    required int pokemonId,
    required bool seen,
    required bool caught,
    String? formName,
    String speciesName = '',
  }) async {
    markedProfiles.add(profileId);
    if (failOnUpdate) {
      throw StateError('Pokedex write failed');
    }
  }

  @override
  Future<void> clearProfilePokedex(String profileId) async {
    markedProfiles.remove(profileId);
  }
}

class _FakeAppLaunchService extends AppLaunchService {
  _FakeAppLaunchService({this.failOnComplete = false});

  final bool failOnComplete;
  bool completed = false;

  @override
  Future<bool> isOnboardingCompleted() async => completed;

  @override
  Future<void> markOnboardingCompleted() async {
    completed = true;
    if (failOnComplete) {
      throw StateError('App state write failed');
    }
  }

  @override
  Future<void> setOnboardingCompleted(bool value) async {
    completed = value;
  }
}
