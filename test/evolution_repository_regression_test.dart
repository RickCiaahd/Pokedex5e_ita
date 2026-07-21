import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/repositories/evolution_repository.dart';

// Copertura mirata delle regressioni su Eevee e sulle evoluzioni regionali.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Eevee espone soltanto le evoluzioni canoniche', () async {
    final evolutions = await EvolutionRepository().getEvolutionData();
    final eevee = evolutions['eevee'] ?? evolutions['Eevee'];

    expect(eevee, isNotNull);
    final names = eevee!.options
        .map((option) => option.toName.toLowerCase())
        .toSet();
    expect(
      names,
      containsAll(<String>{
        'vaporeon',
        'jolteon',
        'flareon',
        'espeon',
        'umbreon',
        'leafeon',
        'glaceon',
        'sylveon',
      }),
    );
    expect(
      names.intersection(<String>{
        'droideon',
        'brawleon',
        'specteon',
        'toxeon',
        'minereon',
        'aereon',
        'pesteon',
        'terreon',
        'drakeon',
      }),
      isEmpty,
    );
  });

  test('le evoluzioni regionali di Hisui usano nomi risolvibili', () async {
    final evolutions = await EvolutionRepository().getEvolutionData();

    expect(
      evolutions['dartrix']!.options.map((option) => option.toName),
      contains('Hisuian Decidueye'),
    );
    expect(
      evolutions['quilava']!.options.map((option) => option.toName),
      contains('Hisuian Typhlosion'),
    );
    expect(
      evolutions['dewott']!.options.map((option) => option.toName),
      contains('Hisuian Samurott'),
    );
  });
}
