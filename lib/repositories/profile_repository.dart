import 'package:hive_flutter/hive_flutter.dart';

import '../database/hive_boxes.dart';
import '../database/hive_keys.dart';
import '../models/user_profile.dart';

class ProfileRepository {
  Future<Box> _profilesBox() => Hive.openBox(HiveBoxes.profiles);
  Future<Box> _appStateBox() => Hive.openBox(HiveBoxes.appState);

  Future<List<UserProfile>> getProfiles() async {
    final box = await _profilesBox();

    return box.values
        .map((data) => UserProfile.fromJson(Map<String, dynamic>.from(data)))
        .toList();
  }

  Future<UserProfile> getActiveProfile() async {
    final appState = await _appStateBox();
    final profiles = await _profilesBox();

    final activeId = appState.get(HiveKeys.activeProfileId);

    if (activeId != null && profiles.containsKey(activeId)) {
      return UserProfile.fromJson(
        Map<String, dynamic>.from(profiles.get(activeId)),
      );
    }

    if (profiles.containsKey(UserProfile.defaultProfileId)) {
      await appState.put(HiveKeys.activeProfileId, UserProfile.defaultProfileId);

      return UserProfile.fromJson(
        Map<String, dynamic>.from(profiles.get(UserProfile.defaultProfileId)),
      );
    }

    final defaultProfile = UserProfile.defaultProfile();

    await profiles.put(defaultProfile.id, defaultProfile.toJson());
    await appState.put(HiveKeys.activeProfileId, defaultProfile.id);

    return defaultProfile;
  }

  Future<void> setActiveProfile(String profileId) async {
    final appState = await _appStateBox();
    await appState.put(HiveKeys.activeProfileId, profileId);
  }

  Future<UserProfile> createProfile(String name) async {
    final profile = UserProfile.create(name);

    await saveProfile(profile);

    return profile;
  }

  Future<void> saveProfile(UserProfile profile) async {
    final box = await _profilesBox();
    await box.put(profile.id, profile.toJson());
  }

  Future<void> deleteProfile(String profileId) async {
    final profiles = await _profilesBox();
    await profiles.delete(profileId);
  }
}
