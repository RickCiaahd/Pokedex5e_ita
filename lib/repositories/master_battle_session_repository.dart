import 'package:hive_flutter/hive_flutter.dart';

import '../database/hive_boxes.dart';
import '../models/master_battle_session.dart';

class MasterBattleSessionRepository {
  Future<Box> _box() => Hive.openBox(HiveBoxes.masterBattleSessions);

  Future<MasterBattleSession?> getSession(String profileId) async {
    final box = await _box();
    final raw = box.get(profileId);
    if (raw is! Map) return null;
    final session = MasterBattleSession.fromJson(
      Map<String, dynamic>.from(raw),
    );
    return session.isValid ? session : null;
  }

  Future<bool> hasSession(String profileId) async {
    return await getSession(profileId) != null;
  }

  Future<void> saveSession(MasterBattleSession session) async {
    if (!session.isValid) {
      throw const FormatException('La sessione del Master non è valida.');
    }
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
