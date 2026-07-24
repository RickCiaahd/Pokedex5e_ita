import 'package:hive_flutter/hive_flutter.dart';

import '../database/hive_boxes.dart';
import '../database/hive_keys.dart';

class GuidedTourIds {
  const GuidedTourIds._();

  static const home = 'home_v1';
  static const battle = 'battle_v1';
  static const trainerSheet = 'trainer_sheet_v1';
  static const masterTools = 'master_tools_v1';
}

class GuidedTourService {
  Future<Box> _appStateBox() => Hive.openBox(HiveBoxes.appState);

  Future<bool> shouldShowTour(String tourId) async {
    final appState = await _appStateBox();

    if (tourId == GuidedTourIds.home &&
        appState.get(HiveKeys.homeTourCompleted, defaultValue: false) == true) {
      return false;
    }

    final completed = _completedTourIds(appState);
    return !completed.contains(tourId);
  }

  Future<void> markTourCompleted(String tourId) async {
    final appState = await _appStateBox();
    final completed = _completedTourIds(appState)..add(tourId);

    await appState.put(
      HiveKeys.guidedToursCompleted,
      completed.toList()..sort(),
    );
    if (tourId == GuidedTourIds.home) {
      await appState.put(HiveKeys.homeTourCompleted, true);
    }
    await appState.flush();
  }

  Set<String> _completedTourIds(Box appState) {
    final stored = appState.get(
      HiveKeys.guidedToursCompleted,
      defaultValue: const <String>[],
    );
    if (stored is! Iterable) return <String>{};

    return stored
        .whereType<Object>()
        .map((value) => value.toString().trim())
        .where((value) => value.isNotEmpty)
        .toSet();
  }
}
