import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/team_slot.dart';
import 'package:pokedex_5e_ita/repositories/pokemon_repository.dart';
import 'package:pokedex_5e_ita/services/battle_temporary_hp_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Fantasmanto exposes an extensible temporary HP rule', () async {
    final pokemon = await PokemonRepository().getAllPokemon();
    final mimikyu = pokemon.firstWhere((entry) => entry.id == 778);
    final slot = TeamSlot(slotIndex: 0, pokemonId: 778);

    final rule = BattleTemporaryHpService.ruleFor(mimikyu, slot);

    expect(rule, isNotNull);
    expect(rule!.id, 'disguise');
    expect(rule.label, 'Fantasmanto');
    expect(rule.maximumForLevel(1), 2);
    expect(rule.maximumForLevel(5), 10);
    expect(rule.maximumForLevel(20), 40);
    expect(rule.brokenFormName, 'Busted');
  });

  test('a Pokemon without a matching ability has no temporary HP rule', () async {
    final pokemon = await PokemonRepository().getAllPokemon();
    final pikachu = pokemon.firstWhere((entry) => entry.id == 25);
    final slot = TeamSlot(slotIndex: 0, pokemonId: 25);

    expect(BattleTemporaryHpService.ruleFor(pikachu, slot), isNull);
  });
}
