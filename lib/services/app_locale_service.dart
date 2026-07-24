import 'package:hive_flutter/hive_flutter.dart';

import '../database/hive_boxes.dart';
import '../database/hive_keys.dart';

abstract class AppLocaleStore {
  Future<String?> readLocalePreference();

  Future<void> writeLocalePreference(String value);
}

class AppLocaleService implements AppLocaleStore {
  Future<Box<dynamic>> _box() => Hive.openBox(HiveBoxes.appState);

  @override
  Future<String?> readLocalePreference() async {
    final box = await _box();
    return box.get(HiveKeys.appLocalePreference)?.toString();
  }

  @override
  Future<void> writeLocalePreference(String value) async {
    final box = await _box();
    await box.put(HiveKeys.appLocalePreference, value);
    await box.flush();
  }
}
