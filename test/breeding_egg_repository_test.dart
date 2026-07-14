import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pokedex_5e_ita/models/breeding_egg.dart';
import 'package:pokedex_5e_ita/repositories/breeding_egg_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;
  final repository = BreedingEggRepository();
  const profileId = 'breeding-first-egg-profile';

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'pokedex_breeding_egg_repository_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  test(
    'salva il primo uovo anche quando il profilo non ne contiene ancora',
    () async {
      await repository.deleteEggs(profileId);

      final egg = BreedingEgg(
        id: 'egg-first',
        speciesId: 403,
        parentNames: const ['Ditto', 'Luxio'],
        createdAt: DateTime.utc(2026, 7, 14),
        hatchTime: 250,
        incubationRemaining: 250,
        nature: 'Jolly',
        gender: 'Female',
        ability: 'Rivalry',
        selectedMoves: const ['Tackle'],
        inheritedMoves: const [],
      );

      await repository.saveEgg(profileId, egg);

      final saved = await repository.getEggs(profileId);
      expect(saved, hasLength(1));
      expect(saved.single.id, 'egg-first');
      expect(saved.single.speciesId, 403);

      await repository.saveEgg(
        profileId,
        egg.copyWith(incubationRemaining: 180),
      );

      final updated = await repository.getEggs(profileId);
      expect(updated, hasLength(1));
      expect(updated.single.incubationRemaining, 180);
    },
  );
}
