import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/move_data.dart';
import 'package:pokedex_5e_ita/repositories/move_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('i metadati tecnici delle mosse vengono mostrati in italiano', () {
    final move = MoveData.fromWebJson({
      'id': 'test-move',
      'name': 'Test Move',
      'type': 'normal',
      'time': '1 bonus action',
      'duration': '1 minute, concentration',
      'range': 'self (30ft radius)',
      'pp': 5,
      'power': ['dex', 'wis'],
      'description': [
        'The target makes a DEX saving throw against your Move DC. On a failure it loses 5 hit points.',
      ],
      'save': {
        'attribute': ['dex'],
        'dc': 'MOVE',
      },
    });

    expect(move.moveTime, '1 azione bonus');
    expect(move.duration, '1 minuto, concentrazione');
    expect(move.range, 'personale (raggio di 30 piedi)');
    expect(move.save, 'DES');
    expect(move.movePowers, ['DEX', 'WIS']);
    expect(move.description, contains('tiro salvezza su DES'));
    expect(move.description, contains('CD della mossa'));
    expect(move.description, contains('5 punti ferita'));
    expect(move.description, isNot(contains('Move DC')));
  });

  test('Tackle viene mostrata come Azione senza perdere il nome tecnico', () async {
    final repository = MoveRepository();
    final byEnglishName = await repository.getMove('Tackle');
    final byItalianName = await repository.getMove('Azione');
    final byId = await repository.getMove('tackle');

    expect(byEnglishName, isNotNull);
    expect(byEnglishName?.name, 'Azione');
    expect(byEnglishName?.technicalName, 'Tackle');
    expect(byItalianName?.id, 'tackle');
    expect(byId?.name, 'Azione');
    expect(byId?.moveTime, '1 azione');
    expect(byId?.duration, 'istantanea');
    expect(byId?.range, 'mischia');
  });
}
