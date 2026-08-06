import '../models/team_slot.dart';
import '../models/user_profile.dart';
import '../repositories/bag_inventory_repository.dart';
import '../repositories/pokedex_repositry.dart';
import '../repositories/profile_repository.dart';
import '../repositories/team_repository.dart';
import 'app_launch_service.dart';

class ProfileCreationService {
  ProfileCreationService({
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

  Future<UserProfile> createEmptyProfile(
    String name, {
    String profileImageBase64 = '',
  }) {
    return _create(
      profile: UserProfile.create(name, profileImageBase64: profileImageBase64),
    );
  }

  Future<UserProfile> createGuidedProfile({
    required UserProfile profile,
    required TeamSlot starterSlot,
    required int starterPokemonId,
    required String starterSpeciesName,
    Map<String, int> initialInventory = const {},
    bool markOnboardingCompleted = false,
  }) {
    return _create(
      profile: profile,
      starterSlot: starterSlot,
      starterPokemonId: starterPokemonId,
      starterSpeciesName: starterSpeciesName,
      initialInventory: initialInventory,
      markOnboardingCompleted: markOnboardingCompleted,
    );
  }

  Future<UserProfile> _create({
    required UserProfile profile,
    TeamSlot? starterSlot,
    int? starterPokemonId,
    String? starterSpeciesName,
    Map<String, int> initialInventory = const {},
    bool markOnboardingCompleted = false,
  }) async {
    final previousActiveProfileId = await _profileRepository
        .getActiveProfileId();
    final previousOnboardingCompleted = markOnboardingCompleted
        ? await _appLaunchService.isOnboardingCompleted()
        : null;

    try {
      await _profileRepository.saveProfile(profile);
      await _bagInventoryRepository.addItems(
        profileId: profile.id,
        quantities: initialInventory,
      );

      if (starterSlot != null) {
        await _teamRepository.updateSlot(
          profileId: profile.id,
          updatedSlot: starterSlot,
        );
      }

      if (starterPokemonId != null) {
        await _pokedexRepository.updateMarkMode(
          profileId: profile.id,
          pokemonId: starterPokemonId,
          speciesName: starterSpeciesName ?? '',
          seen: true,
          caught: true,
        );
      }

      await _profileRepository.setActiveProfile(profile.id);

      if (markOnboardingCompleted) {
        await _appLaunchService.markOnboardingCompleted();
      }

      return profile;
    } catch (_) {
      await _rollback(
        profileId: profile.id,
        previousActiveProfileId: previousActiveProfileId,
        previousOnboardingCompleted: previousOnboardingCompleted,
      );
      rethrow;
    }
  }

  Future<void> _rollback({
    required String profileId,
    required String? previousActiveProfileId,
    required bool? previousOnboardingCompleted,
  }) async {
    await _ignoreFailure(() {
      if (previousActiveProfileId == null) {
        return _profileRepository.clearActiveProfile();
      }
      return _profileRepository.setActiveProfile(previousActiveProfileId);
    });
    await _ignoreFailure(
      () => _pokedexRepository.clearProfilePokedex(profileId),
    );
    await _ignoreFailure(
      () => _bagInventoryRepository.deleteInventory(profileId),
    );
    await _ignoreFailure(() => _teamRepository.deleteTeam(profileId));
    await _ignoreFailure(() => _profileRepository.deleteProfile(profileId));
    if (previousOnboardingCompleted != null) {
      await _ignoreFailure(
        () => _appLaunchService.setOnboardingCompleted(
          previousOnboardingCompleted,
        ),
      );
    }
  }

  Future<void> _ignoreFailure(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Preserve the original creation error after the best-effort rollback.
    }
  }
}
