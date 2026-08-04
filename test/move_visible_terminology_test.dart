import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/bag_item.dart';
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
        'DEX saving throw against your Move DC. Lose 5 hit points.',
      ],
      'save': {
        'attribute': ['dex'],
        'dc': 'MOVE',
      },
    });
    final reactionMove = MoveData.fromWebJson({
      'id': 'reaction-test',
      'name': 'Reaction Test',
      'type': 'normal',
      'time': '1 reaction',
      'duration': 'instantaneous',
      'range': 'melee',
      'pp': 1,
      'description': const <String>[],
    });

    expect(move.moveTime, '1 azione bonus');
    expect(move.duration, '1 minuto, concentrazione');
    expect(move.range, 'personale (raggio di 30 piedi)');
    expect(move.save, 'DES');
    expect(move.movePowers, ['DEX', 'WIS']);
    expect(move.description, contains('DES'));
    expect(move.description, contains('tiro salvezza'));
    expect(move.description, contains('CD della mossa'));
    expect(move.description, contains('5 punti ferita'));
    expect(move.description, isNot(contains('Move DC')));
    expect(reactionMove.moveTime, '1 reazione');
    expect(reactionMove.duration, 'istantanea');
    expect(reactionMove.range, 'mischia');
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

  test('Trasformazione conserva i PF e non copia la CA', () async {
    final move = await MoveRepository().getMove('Transform');

    expect(move, isNotNull);
    expect(move?.description, contains('competenze'));
    expect(move?.description, contains('Mantieni i tuoi privilegi'));
    expect(move?.description, contains('i tuoi PF'));
    expect(move?.description, isNot(matches(RegExp(r'\bCA\b'))));
  });

  test('la ricerca oggetti comprende nomi italiani e inglesi', () {
    const item = BagItem(
      id: 'water-memory-disc',
      name: 'ROM Acqua',
      sourceName: 'Water Memory Disc',
      type: 'held-item',
      description: <String>['Cambia il tipo di Silvally in Acqua.'],
      cost: null,
      spriteAssetPath: null,
    );

    expect(item.matchesSearchQuery('ROM'), isTrue);
    expect(item.matchesSearchQuery('Memory Disc'), isTrue);
    expect(item.matchesSearchQuery('water'), isTrue);
    expect(item.matchesSearchQuery('pozione'), isFalse);
  });

  test('i termini tecnici inglesi non arrivano alle descrizioni italiane', () {
    final move = MoveData.fromWebJson({
      'id': 'terminology-test',
      'name': 'Terminology Test',
      'type': 'varies',
      'time': '1 action',
      'duration': 'instantaneous',
      'range': '30ft',
      'pp': 5,
      'description': <String>[
        'Deal 1d8 + MOVE danni. A Memory Disc or Burn Drive changes Techno Blast.',
      ],
    });

    expect(
      move.description,
      contains('modificatore di caratteristica della mossa'),
    );
    expect(move.description, contains('ROM'));
    expect(move.description, contains('Piromodulo'));
    expect(move.description, contains('Tecnobotto'));
    expect(
      move.description,
      isNot(matches(RegExp(r'\b(?:MOVE|Memory Disc|Drive)\b'))),
    );
  });

  test('l’intero catalogo mosse non espone MOVE, Memory Disc o Drive', () async {
    final moves = await MoveRepository().getAllMoves();
    final forbidden = RegExp(r'\b(?:MOVE|Memory Disc|Drive)\b');

    for (final move in moves) {
      expect(
        move.description,
        isNot(matches(forbidden)),
        reason: '${move.id}: ${move.description}',
      );
      if (move.higherLevels != null) {
        expect(
          move.higherLevels,
          isNot(matches(forbidden)),
          reason: '${move.id}: ${move.higherLevels}',
        );
      }
    }
  });
}
