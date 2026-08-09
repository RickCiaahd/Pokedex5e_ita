import '../localization/ui_text.dart';

enum BattleStatusMoment { turnStart, actionAttempt, subjectedToMove, turnEnd }

extension BattleStatusMomentLabel on BattleStatusMoment {
  String get label => switch (this) {
    BattleStatusMoment.turnStart => uiTextForLanguage(
      'INIZIO TURNO',
      'START OF TURN',
    ),
    BattleStatusMoment.actionAttempt => uiTextForLanguage('AZIONE', 'ACTION'),
    BattleStatusMoment.subjectedToMove => uiTextForLanguage(
      'MOSSA SUBITA',
      'SUBJECTED TO MOVE',
    ),
    BattleStatusMoment.turnEnd => uiTextForLanguage(
      'FINE TURNO',
      'END OF TURN',
    ),
  };

  String get description => switch (this) {
    BattleStatusMoment.turnStart => uiTextForLanguage(
      'Controlli da risolvere appena comincia il turno del Pokémon.',
      'Checks to resolve as soon as the Pokémon’s turn begins.',
    ),
    BattleStatusMoment.actionAttempt => uiTextForLanguage(
      'Controlli da risolvere prima di un’azione o azione bonus.',
      'Checks to resolve before an action or bonus action.',
    ),
    BattleStatusMoment.subjectedToMove => uiTextForLanguage(
      'Controlli da risolvere quando il Pokémon è sottoposto a una mossa.',
      'Checks to resolve when the Pokémon is subjected to a move.',
    ),
    BattleStatusMoment.turnEnd => uiTextForLanguage(
      'Danni e tiri da risolvere alla fine del turno del Pokémon.',
      'Damage and rolls to resolve at the end of the Pokémon’s turn.',
    ),
  };
}

class BattleStatusReminder {
  BattleStatusReminder({
    required this.status,
    required this.title,
    required this.instruction,
  });

  final String status;
  final String title;
  final String instruction;
}

class BattleStatusRules {
  const BattleStatusRules._();

  static const Set<String> supportedStatuses = {
    'Asleep',
    'Burned',
    'Frozen',
    'Paralyzed',
    'Poisoned',
    'Badly Poisoned',
    'Confused',
    'Flinched',
  };

  static bool hasSupportedStatus({
    required String? nonVolatileStatus,
    required Set<String> volatileStatuses,
  }) {
    return _orderedStatuses(
      nonVolatileStatus: nonVolatileStatus,
      volatileStatuses: volatileStatuses,
    ).isNotEmpty;
  }

  static List<BattleStatusReminder> passiveReminders({
    required String? nonVolatileStatus,
    required Set<String> volatileStatuses,
  }) {
    final reminders = <BattleStatusReminder>[];
    for (final status in _orderedStatuses(
      nonVolatileStatus: nonVolatileStatus,
      volatileStatuses: volatileStatuses,
    )) {
      final reminder = _passiveReminder(status);
      if (reminder != null) reminders.add(reminder);
    }
    return reminders;
  }

  static List<BattleStatusReminder> remindersForMoment({
    required String? nonVolatileStatus,
    required Set<String> volatileStatuses,
    required BattleStatusMoment moment,
  }) {
    final reminders = <BattleStatusReminder>[];
    for (final status in _orderedStatuses(
      nonVolatileStatus: nonVolatileStatus,
      volatileStatuses: volatileStatuses,
    )) {
      final reminder = _momentReminder(status, moment);
      if (reminder != null) reminders.add(reminder);
    }
    return reminders;
  }

  static List<String> _orderedStatuses({
    required String? nonVolatileStatus,
    required Set<String> volatileStatuses,
  }) {
    final statuses = <String>{
      if (nonVolatileStatus != null &&
          supportedStatuses.contains(nonVolatileStatus))
        nonVolatileStatus,
      ...volatileStatuses.where(supportedStatuses.contains),
    }.toList(growable: false);

    statuses.sort((a, b) {
      final orderCompare = (_statusOrder[a] ?? 99).compareTo(
        _statusOrder[b] ?? 99,
      );
      return orderCompare != 0 ? orderCompare : a.compareTo(b);
    });
    return statuses;
  }

  static BattleStatusReminder? _passiveReminder(String status) {
    switch (status) {
      case 'Poisoned':
      case 'Badly Poisoned':
        return BattleStatusReminder(
          status: status,
          title: uiTextForLanguage(
            'Attacchi e prove penalizzati',
            'Attacks and checks penalized',
          ),
          instruction: uiTextForLanguage(
            'Ha svantaggio ai tiri per colpire e a tutte le prove di caratteristica.',
            'It has disadvantage on attack rolls and all ability checks.',
          ),
        );
      case 'Burned':
        return BattleStatusReminder(
          status: 'Burned',
          title: uiTextForLanguage('Danni ridotti', 'Reduced damage'),
          instruction: uiTextForLanguage(
            'Quando infligge danni, tira i dadi dei danni due volte e usa il risultato più basso.',
            'When it deals damage, roll the damage dice twice and use the lower result.',
          ),
        );
      case 'Frozen':
        return BattleStatusReminder(
          status: 'Frozen',
          title: uiTextForLanguage(
            'Incapacitato e trattenuto',
            'Incapacitated and restrained',
          ),
          instruction: uiTextForLanguage(
            'Non può agire ed è trattenuto. Fuori dal combattimento lo status termina dopo 1 ora.',
            'It cannot act and is restrained. Outside combat, the condition ends after 1 hour.',
          ),
        );
      case 'Paralyzed':
        return BattleStatusReminder(
          status: 'Paralyzed',
          title: uiTextForLanguage(
            'Movimento e tiri salvezza',
            'Movement and saving throws',
          ),
          instruction: uiTextForLanguage(
            'Ha velocità dimezzata e svantaggio ai tiri salvezza di Forza e Destrezza.',
            'Its Speed is halved and it has disadvantage on Strength and Dexterity saving throws.',
          ),
        );
      case 'Asleep':
        return BattleStatusReminder(
          status: 'Asleep',
          title: uiTextForLanguage(
            'Incapacitato e trattenuto',
            'Incapacitated and restrained',
          ),
          instruction: uiTextForLanguage(
            'Non può agire, è trattenuto ed effettua i tiri salvezza con svantaggio. Conta manualmente i prossimi 3 turni completi.',
            'It cannot act, is restrained, and makes saving throws with disadvantage. Manually count the next 3 full turns.',
          ),
        );
      case 'Confused':
        return BattleStatusReminder(
          status: 'Confused',
          title: uiTextForLanguage('Niente reazioni', 'No reactions'),
          instruction: uiTextForLanguage(
            'Non può usare reazioni e ha velocità dimezzata. Conta manualmente i prossimi 3 turni completi.',
            'It cannot take reactions and its Speed is halved. Manually count the next 3 full turns.',
          ),
        );
      case 'Flinched':
        return BattleStatusReminder(
          status: 'Flinched',
          title: uiTextForLanguage(
            'Penalità fino al prossimo turno',
            'Penalty until the next turn',
          ),
          instruction: uiTextForLanguage(
            'Fino alla fine del prossimo turno ha svantaggio a tiri per colpire, prove e tiri salvezza; le creature hanno vantaggio ai TS contro le sue mosse.',
            'Until the end of its next turn it has disadvantage on attack rolls, checks, and saving throws; creatures have advantage on saves against its moves.',
          ),
        );
      default:
        return null;
    }
  }

  static BattleStatusReminder? _momentReminder(
    String status,
    BattleStatusMoment moment,
  ) {
    switch (moment) {
      case BattleStatusMoment.turnStart:
        if (status == 'Burned') {
          return BattleStatusReminder(
            status: 'Burned',
            title: uiTextForLanguage(
              'Applica i danni da bruciatura',
              'Apply burn damage',
            ),
            instruction: uiTextForLanguage(
              'All’inizio del turno subisce danni pari al bonus di competenza previsto dall’effetto che ha causato Burned.',
              'At the start of its turn it takes damage equal to the proficiency bonus specified by the effect that caused Burned.',
            ),
          );
        }
        if (status == 'Paralyzed') {
          return BattleStatusReminder(
            status: 'Paralyzed',
            title: uiTextForLanguage(
              'Tira 1d4 prima degli altri status',
              'Roll 1d4 before other conditions',
            ),
            instruction: uiTextForLanguage(
              'Con 1 è incapacitato e trattenuto fino al prossimo turno e perde azione e azione bonus. Risolvi questo tiro prima di Asleep o Confused.',
              'On a 1 it is incapacitated and restrained until its next turn and loses its action and bonus action. Resolve this roll before Asleep or Confused.',
            ),
          );
        }
        return null;
      case BattleStatusMoment.actionAttempt:
        if (status == 'Paralyzed') {
          return BattleStatusReminder(
            status: 'Paralyzed',
            title: uiTextForLanguage(
              'Controlla il d4 di inizio turno',
              'Check the start-of-turn d4',
            ),
            instruction: uiTextForLanguage(
              'Se il risultato era 1, il Pokémon non può agire e non deve effettuare altri controlli legati all’azione.',
              'If the result was 1, the Pokémon cannot act and does not make any other action-related checks.',
            ),
          );
        }
        if (status == 'Asleep') {
          return BattleStatusReminder(
            status: 'Asleep',
            title: uiTextForLanguage('Non può agire', 'Cannot act'),
            instruction: uiTextForLanguage(
              'Finché Asleep è attivo, il Pokémon è incapacitato e non può usare azioni o azioni bonus.',
              'While Asleep is active, the Pokémon is incapacitated and cannot take actions or bonus actions.',
            ),
          );
        }
        if (status == 'Confused') {
          return BattleStatusReminder(
            status: 'Confused',
            title: uiTextForLanguage(
              'Tira 1d20 prima di agire',
              'Roll 1d20 before acting',
            ),
            instruction: uiTextForLanguage(
              '1–10: perde la concentrazione, subisce i danni previsti e la mossa fallisce. 11–15: agisce normalmente. 16+: Confused termina immediatamente.',
              '1–10: it loses focus, takes the listed damage, and the move fails. 11–15: it acts normally. 16+: Confused ends immediately.',
            ),
          );
        }
        if (status == 'Flinched') {
          return BattleStatusReminder(
            status: 'Flinched',
            title: uiTextForLanguage(
              'Applica svantaggio',
              'Apply disadvantage',
            ),
            instruction: uiTextForLanguage(
              'Applica svantaggio a tiri per colpire, prove e tiri salvezza effettuati prima della fine del prossimo turno.',
              'Apply disadvantage to attack rolls, checks, and saving throws made before the end of the next turn.',
            ),
          );
        }
        return null;
      case BattleStatusMoment.subjectedToMove:
        if (status == 'Asleep') {
          return BattleStatusReminder(
            status: 'Asleep',
            title: uiTextForLanguage('Tiro di risveglio', 'Wake-up roll'),
            instruction: uiTextForLanguage(
              'Quando è sottoposto a una mossa, tira 1d20. Con 11 o più Asleep termina immediatamente.',
              'When subjected to a move, roll 1d20. On 11 or higher, Asleep ends immediately.',
            ),
          );
        }
        if (status == 'Frozen') {
          return BattleStatusReminder(
            status: 'Frozen',
            title: uiTextForLanguage(
              'Controlla il tipo di danno',
              'Check the damage type',
            ),
            instruction: uiTextForLanguage(
              'Se subisce danni da una mossa capace di applicare Burned, Frozen termina immediatamente.',
              'If it takes damage from a move capable of applying Burned, Frozen ends immediately.',
            ),
          );
        }
        return null;
      case BattleStatusMoment.turnEnd:
        if (status == 'Poisoned' || status == 'Badly Poisoned') {
          return BattleStatusReminder(
            status: status,
            title: uiTextForLanguage(
              'Applica i danni da veleno',
              'Apply poison damage',
            ),
            instruction: uiTextForLanguage(
              'Alla fine del turno subisce danni pari al bonus di competenza previsto dall’effetto che ha causato lo status.',
              'At the end of its turn it takes damage equal to the proficiency bonus specified by the effect that caused the condition.',
            ),
          );
        }
        if (status == 'Frozen') {
          return BattleStatusReminder(
            status: 'Frozen',
            title: uiTextForLanguage(
              'Tiro salvezza di Forza',
              'Strength saving throw',
            ),
            instruction: uiTextForLanguage(
              'Effettua un TS di Forza contro CD 10 + bonus di competenza della fonte. Con successo Frozen termina.',
              'Make a Strength saving throw against DC 10 + the source’s proficiency bonus. On a success, Frozen ends.',
            ),
          );
        }
        if (status == 'Asleep') {
          return BattleStatusReminder(
            status: 'Asleep',
            title: uiTextForLanguage('Tiro di risveglio', 'Wake-up roll'),
            instruction: uiTextForLanguage(
              'Tira 1d20. Con 11 o più Asleep termina immediatamente; altrimenti conta un altro turno completo.',
              'Roll 1d20. On 11 or higher, Asleep ends immediately; otherwise count another full turn.',
            ),
          );
        }
        if (status == 'Confused') {
          return BattleStatusReminder(
            status: 'Confused',
            title: uiTextForLanguage('Aggiorna la durata', 'Update duration'),
            instruction: uiTextForLanguage(
              'Conta il turno completo appena terminato. Dopo 3 turni completi Confused termina se non è già cessato.',
              'Count the full turn that just ended. After 3 full turns, Confused ends if it has not already ended.',
            ),
          );
        }
        if (status == 'Flinched') {
          return BattleStatusReminder(
            status: 'Flinched',
            title: uiTextForLanguage(
              'Verifica la scadenza',
              'Check expiration',
            ),
            instruction: uiTextForLanguage(
              'Se questo è il turno successivo all’applicazione, rimuovi Flinched alla fine del turno.',
              'If this is the turn after the condition was applied, remove Flinched at the end of the turn.',
            ),
          );
        }
        return null;
    }
  }

  static const Map<String, int> _statusOrder = {
    'Paralyzed': 0,
    'Asleep': 1,
    'Confused': 2,
    'Burned': 3,
    'Poisoned': 4,
    'Badly Poisoned': 5,
    'Frozen': 6,
    'Flinched': 7,
  };
}
