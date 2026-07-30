import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/trainer_origin_name_localization.dart';

void main() {
  test('in italiano usa il nome della regione', () {
    expect(
      trainerOriginDisplayName(
        'Alolan',
        isItalian: true,
        dmApprovedLabel: 'Origine 5e approvata dal DM',
      ),
      'Alola',
    );
    expect(
      trainerOriginDisplayName(
        'Hoennian',
        isItalian: true,
        dmApprovedLabel: 'Origine 5e approvata dal DM',
      ),
      'Hoenn',
    );
    expect(
      trainerOriginDisplayName(
        'Unovan',
        isItalian: true,
        dmApprovedLabel: 'Origine 5e approvata dal DM',
      ),
      'Unima',
    );
  });

  test('in inglese mantiene il nome originale', () {
    expect(
      trainerOriginDisplayName(
        'Alolan',
        isItalian: false,
        dmApprovedLabel: 'DM-approved 5e origin',
      ),
      'Alolan',
    );
    expect(
      trainerOriginDisplayName(
        'Hoennian',
        isItalian: false,
        dmApprovedLabel: 'DM-approved 5e origin',
      ),
      'Hoennian',
    );
  });
}
