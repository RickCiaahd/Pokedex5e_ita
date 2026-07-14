enum BattleStatusMoment {
  turnStart,
  actionAttempt,
  subjectedToMove,
  turnEnd,
}

extension BattleStatusMomentLabel on BattleStatusMoment {
  String get label => switch (this) {
    BattleStatusMoment.turnStart => 'INIZIO TURNO',
    BattleStatusMoment.actionAttempt => 'AZIONE',
    BattleStatusMoment.subjectedToMove => 'MOSSA SUBITA',
    BattleStatusMoment.turnEnd => 'FINE TURNO',
  };

  String get description => switch (this) {
    BattleStatusMoment.turnStart =>
      'Controlli da risolvere appena comincia il turno del Pokémon.',
    BattleStatusMoment.actionAttempt =>
      'Controlli da risolvere prima di un’azione o azione bonus.',
    BattleStatusMoment.subjectedToMove =>
      'Controlli da risolvere quando il Pokémon è sottoposto a una mossa.',
    BattleStatusMoment.turnEnd =>
      'Danni e tiri da risolvere alla fine del turno del Pokémon.',
  };
}

class BattleStatusReminder {
  const BattleStatusReminder({
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
    return switch (status) {
      'Poisoned' || 'Badly Poisoned' => BattleStatusReminder(
        status: status,
        title: 'Attacchi e prove penalizzati',
        instruction:
            'Ha svantaggio ai tiri per colpire e a tutte le prove di caratteristica.',
      ),
      'Burned' => const BattleStatusReminder(
        status: 'Burned',
        title: 'Danni ridotti',
        instruction:
            'Quando infligge danni, tira i dadi dei danni due volte e usa il risultato più basso.',
      ),
      'Frozen' => const BattleStatusReminder(
        status: 'Frozen',
        title: 'Incapacitato e trattenuto',
        instruction:
            'Non può agire ed è trattenuto. Fuori dal combattimento lo status termina dopo 1 ora.',
      ),
      'Paralyzed' => const BattleStatusReminder(
        status: 'Paralyzed',
        title: 'Movimento e tiri salvezza',
        instruction:
            'Ha velocità dimezzata e svantaggio ai tiri salvezza di Forza e Destrezza.',
      ),
      'Asleep' => const BattleStatusReminder(
        status: 'Asleep',
        title: 'Incapacitato e trattenuto',
        instruction:
            'Non può agire, è trattenuto ed effettua i tiri salvezza con svantaggio. Conta manualmente i prossimi 3 turni completi.',
      ),
      'Confused' => const BattleStatusReminder(
        status: 'Confused',
        title: 'Niente reazioni',
        instruction:
            'Non può usare reazioni e ha velocità dimezzata. Conta manualmente i prossimi 3 turni completi.',
      ),
      'Flinched' => const BattleStatusReminder(
        status: 'Flinched',
        title: 'Penalità fino al prossimo turno',
        instruction:
            'Fino alla fine del prossimo turno ha svantaggio a tiri per colpire, prove e tiri salvezza; le creature hanno vantaggio ai TS contro le sue mosse.',
      ),
      _ => null,
    };
  }

  static BattleStatusReminder? _momentReminder(
    String status,
    BattleStatusMoment moment,
  ) {
    return switch ((status, moment)) {
      ('Burned', BattleStatusMoment.turnStart) =>
        const BattleStatusReminder(
          status: 'Burned',
          title: 'Applica i danni da bruciatura',
          instruction:
              'All’inizio del turno subisce danni pari al bonus di competenza previsto dall’effetto che ha causato Burned.',
        ),
      ('Paralyzed', BattleStatusMoment.turnStart) =>
        const BattleStatusReminder(
          status: 'Paralyzed',
          title: 'Tira 1d4 prima degli altri status',
          instruction:
              'Con 1 è incapacitato e trattenuto fino al prossimo turno e perde azione e azione bonus. Risolvi questo tiro prima di Asleep o Confused.',
        ),
      ('Paralyzed', BattleStatusMoment.actionAttempt) =>
        const BattleStatusReminder(
          status: 'Paralyzed',
          title: 'Controlla il d4 di inizio turno',
          instruction:
              'Se il risultato era 1, il Pokémon non può agire e non deve effettuare altri controlli legati all’azione.',
        ),
      ('Asleep', BattleStatusMoment.actionAttempt) =>
        const BattleStatusReminder(
          status: 'Asleep',
          title: 'Non può agire',
          instruction:
              'Finché Asleep è attivo, il Pokémon è incapacitato e non può usare azioni o azioni bonus.',
        ),
      ('Confused', BattleStatusMoment.actionAttempt) =>
        const BattleStatusReminder(
          status: 'Confused',
          title: 'Tira 1d20 prima di agire',
          instruction:
              '1–10: perde la concentrazione, subisce i danni previsti e la mossa fallisce. 11–15: agisce normalmente. 16+: Confused termina immediatamente.',
        ),
      ('Flinched', BattleStatusMoment.actionAttempt) =>
        const BattleStatusReminder(
          status: 'Flinched',
          title: 'Applica svantaggio',
          instruction:
              'Applica svantaggio a tiri per colpire, prove e tiri salvezza effettuati prima della fine del prossimo turno.',
        ),
      ('Asleep', BattleStatusMoment.subjectedToMove) =>
        const BattleStatusReminder(
          status: 'Asleep',
          title: 'Tiro di risveglio',
          instruction:
              'Quando è sottoposto a una mossa, tira 1d20. Con 11 o più Asleep termina immediatamente.',
        ),
      ('Frozen', BattleStatusMoment.subjectedToMove) =>
        const BattleStatusReminder(
          status: 'Frozen',
          title: 'Controlla il tipo di danno',
          instruction:
              'Se subisce danni da una mossa capace di applicare Burned, Frozen termina immediatamente.',
        ),
      ('Poisoned', BattleStatusMoment.turnEnd) ||
      ('Badly Poisoned', BattleStatusMoment.turnEnd) =>
        BattleStatusReminder(
          status: status,
          title: 'Applica i danni da veleno',
          instruction:
              'Alla fine del turno subisce danni pari al bonus di competenza previsto dall’effetto che ha causato lo status.',
        ),
      ('Frozen', BattleStatusMoment.turnEnd) =>
        const BattleStatusReminder(
          status: 'Frozen',
          title: 'Tiro salvezza di Forza',
          instruction:
              'Effettua un TS di Forza contro CD 10 + bonus di competenza della fonte. Con successo Frozen termina.',
        ),
      ('Asleep', BattleStatusMoment.turnEnd) =>
        const BattleStatusReminder(
          status: 'Asleep',
          title: 'Tiro di risveglio',
          instruction:
              'Tira 1d20. Con 11 o più Asleep termina immediatamente; altrimenti conta un altro turno completo.',
        ),
      ('Confused', BattleStatusMoment.turnEnd) =>
        const BattleStatusReminder(
          status: 'Confused',
          title: 'Aggiorna la durata',
          instruction:
              'Conta il turno completo appena terminato. Dopo 3 turni completi Confused termina se non è già cessato.',
        ),
      ('Flinched', BattleStatusMoment.turnEnd) =>
        const BattleStatusReminder(
          status: 'Flinched',
          title: 'Verifica la scadenza',
          instruction:
              'Se questo è il turno successivo all’applicazione, rimuovi Flinched alla fine del turno.',
        ),
      _ => null,
    };
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
