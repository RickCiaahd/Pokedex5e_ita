import 'package:hive_flutter/hive_flutter.dart';

import '../database/hive_boxes.dart';
import '../database/hive_keys.dart';

class AppLaunchService {
  Future<Box> _profilesBox() => Hive.openBox(HiveBoxes.profiles);
  Future<Box> _appStateBox() => Hive.openBox(HiveBoxes.appState);

  Future<bool> shouldShowOnboarding() async {
    final profiles = await _profilesBox();
    if (profiles.isNotEmpty) return false;

    final appState = await _appStateBox();
    return appState.get(HiveKeys.onboardingCompleted, defaultValue: false) !=
        true;
  }

  Future<void> markOnboardingCompleted() async {
    final appState = await _appStateBox();
    await appState.put(HiveKeys.onboardingCompleted, true);
    await appState.flush();
  }
}
