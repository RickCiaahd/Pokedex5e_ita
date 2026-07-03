import 'package:hive_flutter/hive_flutter.dart';

import '../database/hive_boxes.dart';
import '../models/profile_settings.dart';

class SettingsRepository {
  Future<Box> _box() => Hive.openBox(HiveBoxes.settings);

  Future<ProfileSettings> getSettings(String profileId) async {
    final box = await _box();
    final data = box.get(profileId);

    if (data == null) {
      return ProfileSettings.defaults();
    }

    return ProfileSettings.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> saveSettings(
    String profileId,
    ProfileSettings settings,
  ) async {
    final box = await _box();
    await box.put(profileId, settings.toJson());
  }
}