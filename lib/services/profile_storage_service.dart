import 'package:hive_flutter/hive_flutter.dart';

import '../database/hive_boxes.dart';
import '../models/pokedex_entry.dart';
import '../models/user_profile.dart';
import 'package:flutter/foundation.dart';

class ProfileStorageService {
  Future<Box> _openProfilesBox() {
    return Hive.openBox(HiveBoxes.profiles);
  }

  Future<UserProfile> getDefaultProfile() async {
    final box = await _openProfilesBox();

    final data = box.get('default');

    if (data == null) {
      final profile = UserProfile.defaultProfile();
      await saveProfile(profile);
      return profile;
    }

    return UserProfile.fromJson(
      _normalizeMap(data),
    );
  }

  Future<void> saveProfile(UserProfile profile) async {
    final box = await _openProfilesBox();
    await box.put(profile.id, profile.toJson());
  }

  Future<Map<int, PokedexEntry>> loadPokedexEntries() async {
    final profile = await getDefaultProfile();

    return profile.pokedexEntries.map(
      (pokemonId, data) => MapEntry(
        pokemonId,
        PokedexEntry(
          pokemonId: pokemonId,
          seen: data['seen'] ?? false,
          caught: data['caught'] ?? false,
        ),
      ),
    );
  }

  Future<void> savePokedexEntries(
    Map<int, PokedexEntry> entries,
  ) async {
    debugPrint('PROFILE STORAGE: entrato nel metodo');

    final profile = await getDefaultProfile();

    debugPrint('PROFILE STORAGE: profilo caricato ${profile.id}');

    final updatedEntries = entries.map(
      (pokemonId, entry) => MapEntry(
        pokemonId,
        {
          'seen': entry.seen,
          'caught': entry.caught,
        },
      ),
    );

    await saveProfile(
      profile.copyWith(
        pokedexEntries: updatedEntries,
      ),
    );

    debugPrint('PROFILE STORAGE: saveProfile completato');
  }

  Map<String, dynamic> _normalizeMap(dynamic value) {
    final map = Map<dynamic, dynamic>.from(value as Map);
  
    return map.map(
      (key, value) {
        if (value is Map) {
          return MapEntry(
            key.toString(),
            _normalizeMap(value),
          );
        }
  
        if (value is List) {
          return MapEntry(
            key.toString(),
            value.map((item) {
              if (item is Map) return _normalizeMap(item);
              return item;
            }).toList(),
          );
        }
  
        return MapEntry(key.toString(), value);
      },
    );
  }

}