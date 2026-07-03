import '../models/pokedex_entry.dart';
import '../models/user_profile.dart';
import '../repositories/pokedex_repositry.dart';
import '../repositories/profile_repository.dart';

class ProfileStorageService {
  final ProfileRepository _profileRepository = ProfileRepository();
  final PokedexRepository _pokedexRepository = PokedexRepository();

  Future<UserProfile> getDefaultProfile() async {
    return _profileRepository.getActiveProfile();
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _profileRepository.saveProfile(profile);
  }

  Future<Map<int, PokedexEntry>> loadPokedexEntries() async {
    final profile = await getDefaultProfile();
    return _pokedexRepository.getEntriesForProfile(profile.id);
  }

  Future<void> savePokedexEntries(
    Map<int, PokedexEntry> entries,
  ) async {
    final profile = await getDefaultProfile();

    for (final entry in entries.values) {
      await _pokedexRepository.saveEntry(
        profileId: profile.id,
        entry: entry,
      );
    }
  }
}
