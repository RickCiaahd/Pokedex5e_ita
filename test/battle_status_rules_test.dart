import 'package:flutter_test/flutter_test.dart';

import 'package:pokedex_5e_ita/services/battle_status_rules.dart';

void main() {
  group('BattleStatusRules', () {
    test('non mostra assistenza senza status supportati', () {
      expect(
        BattleStatusRules.hasSupportedStatus(
          nonVolatileStatus: null,
          volatileStatuses: const {},
        ),
        isFalse,
      );
      expect(
        BattleStatusRules.hasSupportedStatus(
          nonVolatileStatus: 'Unknown',
          volatileStatuses: const {'Custom'},
        ),
        isFalse,
      );
    });

    test('ordina Paralyzed prima di Asleep e Confused', () {
      final reminders = BattleStatusRules.remindersForMoment(
        nonVolatileStatus: 'Paralyzed',
        volatileStatuses: const {'Confused'},
        moment: BattleStatusMoment.actionAttempt,
      );

      expect(reminders.map((item) => item.status), ['Paralyzed', 'Confused']);
      expect(reminders.first.instruction, contains('non può agire'));
    });

    test('Burned ricorda danni a inizio turno e riduzione dei danni', () {
      final passive = BattleStatusRules.passiveReminders(
        nonVolatileStatus: 'Burned',
        volatileStatuses: const {},
      );
      final start = BattleStatusRules.remindersForMoment(
        nonVolatileStatus: 'Burned',
        volatileStatuses: const {},
        moment: BattleStatusMoment.turnStart,
      );

      expect(passive.single.instruction, contains('due volte'));
      expect(start.single.instruction, contains('All’inizio del turno'));
    });

    test('Poisoned e Badly Poisoned usano il promemoria di fine turno', () {
      for (final status in ['Poisoned', 'Badly Poisoned']) {
        final reminders = BattleStatusRules.remindersForMoment(
          nonVolatileStatus: status,
          volatileStatuses: const {},
          moment: BattleStatusMoment.turnEnd,
        );

        expect(reminders.single.status, status);
        expect(reminders.single.instruction, contains('fine del turno'));
      }
    });

    test('Frozen ricorda sia il TS sia lo scioglimento da mossa', () {
      final targeted = BattleStatusRules.remindersForMoment(
        nonVolatileStatus: 'Frozen',
        volatileStatuses: const {},
        moment: BattleStatusMoment.subjectedToMove,
      );
      final end = BattleStatusRules.remindersForMoment(
        nonVolatileStatus: 'Frozen',
        volatileStatuses: const {},
        moment: BattleStatusMoment.turnEnd,
      );

      expect(targeted.single.instruction, contains('Burned'));
      expect(end.single.instruction, contains('CD 10'));
    });

    test('Asleep ricorda entrambi i tiri di risveglio', () {
      final targeted = BattleStatusRules.remindersForMoment(
        nonVolatileStatus: 'Asleep',
        volatileStatuses: const {},
        moment: BattleStatusMoment.subjectedToMove,
      );
      final end = BattleStatusRules.remindersForMoment(
        nonVolatileStatus: 'Asleep',
        volatileStatuses: const {},
        moment: BattleStatusMoment.turnEnd,
      );

      expect(targeted.single.instruction, contains('11 o più'));
      expect(end.single.instruction, contains('11 o più'));
    });

    test('Flinched ricorda penalità e scadenza senza autorimozione', () {
      final passive = BattleStatusRules.passiveReminders(
        nonVolatileStatus: null,
        volatileStatuses: const {'Flinched'},
      );
      final end = BattleStatusRules.remindersForMoment(
        nonVolatileStatus: null,
        volatileStatuses: const {'Flinched'},
        moment: BattleStatusMoment.turnEnd,
      );

      expect(passive.single.instruction, contains('prossimo turno'));
      expect(
        end.single.instruction,
        contains('Se questo è il turno successivo'),
      );
    });
  });
}
