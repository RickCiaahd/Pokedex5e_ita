import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    test('reads older saved profiles with trainer defaults', () {
      final profile = UserProfile.fromJson({
        'id': 'old-profile',
        'name': 'Riccardo',
        'createdAt': '2026-07-07T10:00:00.000',
        'updatedAt': '2026-07-07T10:00:00.000',
      });

      expect(profile.trainerLevel, 1);
      expect(profile.money, 0);
    });

    test('persists trainer companion fields', () {
      final profile = UserProfile(
        id: 'profile',
        name: 'Trainer',
        createdAt: DateTime(2026, 7, 7),
        updatedAt: DateTime(2026, 7, 7),
        trainerLevel: 5,
        money: 1200,
      );

      final json = profile.toJson();

      expect(json['trainerLevel'], 5);
      expect(json['money'], 1200);
    });
  });
}
