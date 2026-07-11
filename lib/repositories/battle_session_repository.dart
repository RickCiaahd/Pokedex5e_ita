import 'package:hive_flutter/hive_flutter.dart';

import '../database/hive_boxes.dart';
import '../models/battle_session.dart';

class BattleSessionRepository {
  Future<Box> _box() => Hive.openBox(HiveBoxes.battleSessions);

  Future<BattleSession?> getSession(String profileId) async {
    final box = await _box();
    final value = box.get(profileId);
    if (value == null) return null;

    try {
      return BattleSession.fromJson(Map<String, dynamic>.from(value));
    } catch (_) {
      await box.delete(profileId);
      await box.flush();
      return null;
    }
  }

  Future<bool> hasSession(String profileId) async {
    final session = await getSession(profileId);
    return session != null;
  }

  Future<void> saveSession(BattleSession session) async {
    final box = await _box();
    await box.put(session.profileId, session.toJson());
    await box.flush();
  }

  Future<void> deleteSession(String profileId) async {
    final box = await _box();
    await box.delete(profileId);
    await box.flush();
  }
}
