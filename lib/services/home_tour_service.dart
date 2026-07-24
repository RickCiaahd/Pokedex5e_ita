import 'package:hive_flutter/hive_flutter.dart';

import '../database/hive_boxes.dart';
import '../database/hive_keys.dart';

class HomeTourService {
  Future<Box> _appStateBox() => Hive.openBox(HiveBoxes.appState);

  Future<bool> shouldShowTour() async {
    final appState = await _appStateBox();
    return appState.get(HiveKeys.homeTourCompleted, defaultValue: false) != true;
  }

  Future<void> markTourCompleted() async {
    final appState = await _appStateBox();
    await appState.put(HiveKeys.homeTourCompleted, true);
    await appState.flush();
  }
}
