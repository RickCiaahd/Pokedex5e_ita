import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/trainer_origin_name_localization.dart';

void main() {
  test('in italiano usa il nome ufficiale della regione', () {
    const expectedNames = {
      'Alolan': 'Alola',
      'Hoennian': 'Hoenn',
      'Johtoan': 'Johto',
      'Kalosian': 'Kalos',
      'Kantoan': 'Kanto',
      'Sinnoan': 'Sinnoh',
      'Unovan': 'Unima',
      'Galarian': 'Galar',
    };

    for (final entry in expectedNames.entries) {
      expect(
        trainerOriginDisplayName(
          entry.key,
          isItalian: true,
          dmApprovedLabel: 'Origine 5e approvata dal DM',
        ),
        entry.value,
      );
    }
  });

  test('in inglese mantiene i nomi originali', () {
    for (final origin in ['Alolan', 'Hoennian', 'Unovan', 'Galarian']) {
      expect(
        trainerOriginDisplayName(
          origin,
          isItalian: false,
          dmApprovedLabel: 'DM-approved 5e origin',
        ),
        origin,
      );
    }
  });

  test('mantiene la traduzione dedicata per l origine approvata dal DM', () {
    expect(
      trainerOriginDisplayName(
        'Origine 5e approvata dal DM',
        isItalian: false,
        dmApprovedLabel: 'DM-approved 5e origin',
      ),
      'DM-approved 5e origin',
    );
  });
}
