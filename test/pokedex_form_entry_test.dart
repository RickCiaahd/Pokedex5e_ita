import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/pokedex_entry.dart';

void main() {
  group('PokedexEntry form migration', () {
    test('legacy species state becomes the base form', () {
      final entry = PokedexEntry.fromJson({
        'pokemonId': 19,
        'seen': true,
        'caught': false,
        'updatedAt': '2026-07-11T00:00:00.000Z',
      });

      expect(entry.seen, isTrue);
      expect(entry.caught, isFalse);
      expect(entry.formFor(null).seen, isTrue);
      expect(entry.forms.keys, contains('base'));
    });

    test('stored full form names resolve to the canonical species form', () {
      final timestamp = DateTime.utc(2026, 7, 11);
      final entry = PokedexEntry(
        pokemonId: 19,
        forms: {
          'alolan-rattata': PokedexFormEntry(
            key: 'alolan-rattata',
            formName: 'Alolan Rattata',
            seen: true,
            caught: true,
            updatedAt: timestamp,
          ),
        },
      );

      expect(
        entry.formFor('Alolan', speciesName: 'Rattata').caught,
        isTrue,
      );

      final normalized = entry.setFormState(
        formName: 'Alolan',
        speciesName: 'Rattata',
        seen: true,
        caught: true,
      );
      expect(normalized.forms.keys, contains('alolan'));
      expect(normalized.forms.keys, isNot(contains('alolan-rattata')));
    });
  });

  group('PokedexEntry preview priority', () {
    PokedexEntry withBase({required bool seen, required bool caught}) {
      return PokedexEntry.empty(19).setFormState(
        formName: null,
        speciesName: 'Rattata',
        seen: seen,
        caught: caught,
      );
    }

    PokedexEntry withAlolan(
      PokedexEntry entry, {
      required bool seen,
      required bool caught,
    }) {
      return entry.setFormState(
        formName: 'Alolan',
        speciesName: 'Rattata',
        seen: seen,
        caught: caught,
      );
    }

    test('base wins when both forms have the same state', () {
      final bothSeen = withAlolan(
        withBase(seen: true, caught: false),
        seen: true,
        caught: false,
      );
      expect(bothSeen.preferredFormName, isNull);

      final bothCaught = withAlolan(
        withBase(seen: true, caught: true),
        seen: true,
        caught: true,
      );
      expect(bothCaught.preferredFormName, isNull);
    });

    test('caught form wins over a form that is only seen', () {
      final alternateCaught = withAlolan(
        withBase(seen: true, caught: false),
        seen: true,
        caught: true,
      );
      expect(alternateCaught.preferredFormName, 'Alolan');

      final baseCaught = withAlolan(
        withBase(seen: true, caught: true),
        seen: true,
        caught: false,
      );
      expect(baseCaught.preferredFormName, isNull);
    });

    test('an alternative is used when the base form is unknown', () {
      final entry = withAlolan(
        PokedexEntry.empty(19),
        seen: true,
        caught: false,
      );
      expect(entry.preferredFormName, 'Alolan');
    });
  });

  test('temporary battle transformations are not tracked as forms', () {
    expect(
      PokedexEntry.isTrackableForm('Mega Charizard X', speciesName: 'Charizard'),
      isFalse,
    );
    expect(
      PokedexEntry.isTrackableForm('Gigantamax', speciesName: 'Pikachu'),
      isFalse,
    );
    expect(
      PokedexEntry.isTrackableForm('Dusk Mane', speciesName: 'Necrozma'),
      isTrue,
    );
  });

  test('form state survives JSON serialization', () {
    final original = PokedexEntry.empty(26)
        .setFormState(
          formName: 'Alolan',
          speciesName: 'Raichu',
          seen: true,
          caught: true,
        )
        .setFormState(
          formName: null,
          speciesName: 'Raichu',
          seen: true,
          caught: false,
        );

    final restored = PokedexEntry.fromJson(original.toJson());

    expect(restored.caught, isTrue);
    expect(
      restored.formFor('Alolan', speciesName: 'Raichu').caught,
      isTrue,
    );
    expect(restored.formFor(null, speciesName: 'Raichu').seen, isTrue);
  });
}
