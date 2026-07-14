import 'package:flutter_test/flutter_test.dart';

import 'package:pokedex_5e_ita/models/breeding_species_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'il catalogo Gruppi Uova include specie comuni e casi speciali',
    () async {
      final data = await BreedingDataService().load();
      expect(data.length, greaterThan(900));
      expect(data[1]?.eggGroups, containsAll(['Monster', 'Grass']));
      expect(data[132]?.isDitto, isTrue);
      expect(data[150]?.isUndiscovered, isTrue);
      expect(data[26]?.baseSpeciesId, 172);
    },
  );
}
