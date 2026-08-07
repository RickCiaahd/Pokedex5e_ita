from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding='utf-8')


def write(path: str, text: str) -> None:
    (ROOT / path).write_text(text, encoding='utf-8')


def must_replace(path: str, old: str, new: str, *, count: int | None = None) -> None:
    text = read(path)
    found = text.count(old)
    expected = count if count is not None else 1
    if found < expected:
        raise RuntimeError(f'{path}: expected at least {expected} occurrence(s), found {found}: {old[:100]!r}')
    if count is None:
        text = text.replace(old, new, 1)
    else:
        text = text.replace(old, new, count)
    write(path, text)


def replace_all(path: str, old: str, new: str) -> None:
    text = read(path)
    if old not in text:
        return
    write(path, text.replace(old, new))


def regex_replace(path: str, pattern: str, replacement: str, *, count: int = 1) -> None:
    text = read(path)
    updated, matches = re.subn(pattern, replacement, text, count=count, flags=re.S)
    if matches != count:
        raise RuntimeError(f'{path}: regex expected {count} match(es), found {matches}: {pattern[:120]}')
    write(path, updated)


def add_import(path: str, anchor: str, import_line: str) -> None:
    text = read(path)
    if import_line in text:
        return
    if anchor not in text:
        raise RuntimeError(f'{path}: import anchor not found: {anchor!r}')
    write(path, text.replace(anchor, anchor + import_line, 1))


# ---------------------------------------------------------------------------
# Battle transformations: model + generated service text.
# ---------------------------------------------------------------------------
path = 'lib/models/battle_transformation.dart'
add_import(path, '', "import '../localization/ui_text.dart';\n\n")
regex_replace(
    path,
    r"  String get label => switch \(this\) \{.*?\n  \};",
    """  String get label => switch (this) {
    BattleTransformationKind.mega =>
      uiTextForLanguage('Mega Evoluzione', 'Mega Evolution'),
    BattleTransformationKind.zMove => uiTextForLanguage('Mossa Z', 'Z-Move'),
    BattleTransformationKind.dynamax => 'Dynamax',
    BattleTransformationKind.gigamax =>
      uiTextForLanguage('Gigamax', 'Gigantamax'),
    BattleTransformationKind.terastal =>
      uiTextForLanguage('Teracristal', 'Terastallization'),
  };""",
)
must_replace(
    path,
    "throw const FormatException('Trasformazione di battaglia non valida.');",
    "throw FormatException(\n        uiTextForLanguage(\n          'Trasformazione di battaglia non valida.',\n          'Invalid battle transformation.',\n        ),\n      );",
)

path = 'lib/services/battle_transformation_service.dart'
add_import(path, "import '../models/team_slot.dart';\n", "import '../localization/ui_text.dart';\n")
replacements = {
    "missing.add('Il Pokémon ha già una trasformazione attiva');": "missing.add(\n        uiTextForLanguage(\n          'Il Pokémon ha già una trasformazione attiva',\n          'The Pokémon already has an active transformation',\n        ),\n      );",
    "missing.add('Questo Pokémon ha già usato una trasformazione dopo l’ultimo riposo lungo');": "missing.add(\n        uiTextForLanguage(\n          'Questo Pokémon ha già usato una trasformazione dopo l’ultimo riposo lungo',\n          'This Pokémon has already used a transformation since the last long rest',\n        ),\n      );",
    "missing.add('Richiede lo stadio evolutivo finale');": "missing.add(\n            uiTextForLanguage(\n              'Richiede lo stadio evolutivo finale',\n              'Requires the final evolution stage',\n            ),\n          );",
    "if (pokemonLevel < 10) missing.add('Richiede livello 10');": "if (pokemonLevel < 10) {\n          missing.add(uiTextForLanguage('Richiede livello 10', 'Requires level 10'));\n        }",
    "missing.add('Il Pokémon deve tenere Megalite Stone');": "missing.add(\n            uiTextForLanguage(\n              'Il Pokémon deve tenere Megalite Stone',\n              'The Pokémon must hold a Megalite Stone',\n            ),\n          );",
    "missing.add('Richiede una Pietrachiave nello Zaino');": "missing.add(\n            uiTextForLanguage(\n              'Richiede una Pietrachiave nello Zaino',\n              'Requires a Key Stone in the Bag',\n            ),\n          );",
    "if (pokemonLevel < 6) missing.add('Richiede livello 6');": "if (pokemonLevel < 6) {\n          missing.add(uiTextForLanguage('Richiede livello 6', 'Requires level 6'));\n        }",
    "missing.add('Il Pokémon deve tenere un Cristallo Z');": "missing.add(\n            uiTextForLanguage(\n              'Il Pokémon deve tenere un Cristallo Z',\n              'The Pokémon must hold a Z-Crystal',\n            ),\n          );",
    "missing.add('Nessuna mossa conosciuta corrisponde al Cristallo Z');": "missing.add(\n            uiTextForLanguage(\n              'Nessuna mossa conosciuta corrisponde al Cristallo Z',\n              'No known move matches the Z-Crystal',\n            ),\n          );",
    "missing.add('Richiede un Cerchio Z nello Zaino');": "missing.add(\n            uiTextForLanguage(\n              'Richiede un Cerchio Z nello Zaino',\n              'Requires a Z-Ring in the Bag',\n            ),\n          );",
    "missing.add('Richiede un Polsino Dynamax nello Zaino');": "missing.add(\n            uiTextForLanguage(\n              'Richiede un Polsino Dynamax nello Zaino',\n              'Requires a Dynamax Band in the Bag',\n            ),\n          );",
    "missing.add('Richiede una Terasfera nello Zaino');": "missing.add(\n            uiTextForLanguage(\n              'Richiede una Terasfera nello Zaino',\n              'Requires a Tera Orb in the Bag',\n            ),\n          );",
}
for old, new in replacements.items():
    replace_all(path, old, new)
regex_replace(
    path,
    r"    if \(trainerUses\.contains\(kind\.trainerUseId\)\) \{\n      missing\.add\('L’Allenatore ha già usato \$\{_trainerUseLabel\(kind\)\} dopo l’ultimo riposo lungo'\);\n    \}",
    """    if (trainerUses.contains(kind.trainerUseId)) {
      missing.add(
        uiTextForLanguage(
          'L’Allenatore ha già usato ${_trainerUseLabel(kind)} dopo l’ultimo riposo lungo',
          'The Trainer has already used ${_trainerUseLabel(kind)} since the last long rest',
        ),
      );
    }""",
)
regex_replace(
    path,
    r"  static String effectSummary\(BattleTransformationState state\) \{.*?\n  \}\n\n  static String zMoveSummary",
    """  static String effectSummary(BattleTransformationState state) {
    switch (state.kind) {
      case BattleTransformationKind.mega:
        return uiTextForLanguage(
          'CA +2; raddoppia i modificatori di caratteristica per attacchi, danni, tiri salvezza e CD.',
          'AC +2; doubles ability modifiers for attacks, damage, saving throws and DCs.',
        );
      case BattleTransformationKind.zMove:
        return uiTextForLanguage(
          'La Mossa Z non manca; CD +5; raddoppia dadi di danno/guarigione e bonus MOVE.',
          'The Z-Move cannot miss; DC +5; doubles damage/healing dice and MOVE bonus.',
        );
      case BattleTransformationKind.dynamax:
      case BattleTransformationKind.gigamax:
        return uiTextForLanguage(
          'Taglia Gargantuan, immunità agli status volatili, niente cambio e tiri di danno due volte.',
          'Gargantuan size, immunity to volatile conditions, no switching, and damage rolls are made twice.',
        );
      case BattleTransformationKind.terastal:
        return uiTextForLanguage(
          'Il tipo diventa ${state.teraType ?? 'Tera'}; conserva lo STAB originale ed è vulnerabile a Stellar.',
          'Type becomes ${state.teraType ?? 'Tera'}; keeps its original STAB and is vulnerable to Stellar.',
        );
    }
  }

  static String zMoveSummary""",
)
regex_replace(
    path,
    r"  static String zMoveSummary\(MoveData move\) \{.*?\n  \}\n\n  static String _trainerUseLabel",
    """  static String zMoveSummary(MoveData move) {
    final parts = <String>[uiTextForLanguage('non può mancare', 'cannot miss')];
    if (move.save != null) parts.add(uiTextForLanguage('CD +5', 'DC +5'));
    if (move.damageByLevel.isNotEmpty) {
      parts.add(uiTextForLanguage('dadi di danno ×2', 'damage dice ×2'));
    }
    if (_key(move.damageModifier ?? '') == 'move') {
      parts.add(uiTextForLanguage('bonus MOVE ×2', 'MOVE bonus ×2'));
    }
    return parts.join(' · ');
  }

  static String _trainerUseLabel""",
)
regex_replace(
    path,
    r"  static String _trainerUseLabel\(BattleTransformationKind kind\) \{.*?\n  \}\n\n  static String _key",
    """  static String _trainerUseLabel(BattleTransformationKind kind) {
    return switch (kind) {
      BattleTransformationKind.mega =>
        uiTextForLanguage('la Mega Evoluzione', 'Mega Evolution'),
      BattleTransformationKind.zMove =>
        uiTextForLanguage('una Mossa Z', 'a Z-Move'),
      BattleTransformationKind.dynamax =>
        uiTextForLanguage('Dynamax/Gigamax', 'Dynamax/Gigantamax'),
      BattleTransformationKind.gigamax =>
        uiTextForLanguage('Dynamax/Gigamax', 'Dynamax/Gigantamax'),
      BattleTransformationKind.terastal =>
        uiTextForLanguage('la Teracristallizzazione', 'Terastallization'),
    };
  }

  static String _key""",
)

# ---------------------------------------------------------------------------
# Battle status assistance.
# ---------------------------------------------------------------------------
path = 'lib/services/battle_status_rules.dart'
add_import(path, '', "import '../localization/ui_text.dart';\n\n")
regex_replace(
    path,
    r"extension BattleStatusMomentLabel on BattleStatusMoment \{.*?\n\}\n\nclass BattleStatusReminder",
    """extension BattleStatusMomentLabel on BattleStatusMoment {
  String get label => switch (this) {
    BattleStatusMoment.turnStart =>
      uiTextForLanguage('INIZIO TURNO', 'START OF TURN'),
    BattleStatusMoment.actionAttempt => uiTextForLanguage('AZIONE', 'ACTION'),
    BattleStatusMoment.subjectedToMove =>
      uiTextForLanguage('MOSSA SUBITA', 'SUBJECTED TO MOVE'),
    BattleStatusMoment.turnEnd => uiTextForLanguage('FINE TURNO', 'END OF TURN'),
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

class BattleStatusReminder""",
)
replace_all(path, 'return const BattleStatusReminder(', 'return BattleStatusReminder(')
replace_all(path, 'const BattleStatusReminder(', 'BattleStatusReminder(')
status_pairs = {
    "title: 'Attacchi e prove penalizzati',": "title: uiTextForLanguage('Attacchi e prove penalizzati', 'Attacks and checks penalized'),",
    "'Ha svantaggio ai tiri per colpire e a tutte le prove di caratteristica.',": "uiTextForLanguage('Ha svantaggio ai tiri per colpire e a tutte le prove di caratteristica.', 'It has disadvantage on attack rolls and all ability checks.'),",
    "title: 'Danni ridotti',": "title: uiTextForLanguage('Danni ridotti', 'Reduced damage'),",
    "'Quando infligge danni, tira i dadi dei danni due volte e usa il risultato più basso.',": "uiTextForLanguage('Quando infligge danni, tira i dadi dei danni due volte e usa il risultato più basso.', 'When it deals damage, roll the damage dice twice and use the lower result.'),",
    "title: 'Incapacitato e trattenuto',": "title: uiTextForLanguage('Incapacitato e trattenuto', 'Incapacitated and restrained'),",
    "'Non può agire ed è trattenuto. Fuori dal combattimento lo status termina dopo 1 ora.',": "uiTextForLanguage('Non può agire ed è trattenuto. Fuori dal combattimento lo status termina dopo 1 ora.', 'It cannot act and is restrained. Outside combat, the condition ends after 1 hour.'),",
    "title: 'Movimento e tiri salvezza',": "title: uiTextForLanguage('Movimento e tiri salvezza', 'Movement and saving throws'),",
    "'Ha velocità dimezzata e svantaggio ai tiri salvezza di Forza e Destrezza.',": "uiTextForLanguage('Ha velocità dimezzata e svantaggio ai tiri salvezza di Forza e Destrezza.', 'Its Speed is halved and it has disadvantage on Strength and Dexterity saving throws.'),",
    "'Non può agire, è trattenuto ed effettua i tiri salvezza con svantaggio. Conta manualmente i prossimi 3 turni completi.',": "uiTextForLanguage('Non può agire, è trattenuto ed effettua i tiri salvezza con svantaggio. Conta manualmente i prossimi 3 turni completi.', 'It cannot act, is restrained, and makes saving throws with disadvantage. Manually count the next 3 full turns.'),",
    "title: 'Niente reazioni',": "title: uiTextForLanguage('Niente reazioni', 'No reactions'),",
    "'Non può usare reazioni e ha velocità dimezzata. Conta manualmente i prossimi 3 turni completi.',": "uiTextForLanguage('Non può usare reazioni e ha velocità dimezzata. Conta manualmente i prossimi 3 turni completi.', 'It cannot take reactions and its Speed is halved. Manually count the next 3 full turns.'),",
    "title: 'Penalità fino al prossimo turno',": "title: uiTextForLanguage('Penalità fino al prossimo turno', 'Penalty until the next turn'),",
    "'Fino alla fine del prossimo turno ha svantaggio a tiri per colpire, prove e tiri salvezza; le creature hanno vantaggio ai TS contro le sue mosse.',": "uiTextForLanguage('Fino alla fine del prossimo turno ha svantaggio a tiri per colpire, prove e tiri salvezza; le creature hanno vantaggio ai TS contro le sue mosse.', 'Until the end of its next turn it has disadvantage on attack rolls, checks, and saving throws; creatures have advantage on saves against its moves.'),",
    "title: 'Applica i danni da bruciatura',": "title: uiTextForLanguage('Applica i danni da bruciatura', 'Apply burn damage'),",
    "'All’inizio del turno subisce danni pari al bonus di competenza previsto dall’effetto che ha causato Burned.',": "uiTextForLanguage('All’inizio del turno subisce danni pari al bonus di competenza previsto dall’effetto che ha causato Burned.', 'At the start of its turn it takes damage equal to the proficiency bonus specified by the effect that caused Burned.'),",
    "title: 'Tira 1d4 prima degli altri status',": "title: uiTextForLanguage('Tira 1d4 prima degli altri status', 'Roll 1d4 before other conditions'),",
    "'Con 1 è incapacitato e trattenuto fino al prossimo turno e perde azione e azione bonus. Risolvi questo tiro prima di Asleep o Confused.',": "uiTextForLanguage('Con 1 è incapacitato e trattenuto fino al prossimo turno e perde azione e azione bonus. Risolvi questo tiro prima di Asleep o Confused.', 'On a 1 it is incapacitated and restrained until its next turn and loses its action and bonus action. Resolve this roll before Asleep or Confused.'),",
    "title: 'Controlla il d4 di inizio turno',": "title: uiTextForLanguage('Controlla il d4 di inizio turno', 'Check the start-of-turn d4'),",
    "'Se il risultato era 1, il Pokémon non può agire e non deve effettuare altri controlli legati all’azione.',": "uiTextForLanguage('Se il risultato era 1, il Pokémon non può agire e non deve effettuare altri controlli legati all’azione.', 'If the result was 1, the Pokémon cannot act and does not make any other action-related checks.'),",
    "title: 'Non può agire',": "title: uiTextForLanguage('Non può agire', 'Cannot act'),",
    "'Finché Asleep è attivo, il Pokémon è incapacitato e non può usare azioni o azioni bonus.',": "uiTextForLanguage('Finché Asleep è attivo, il Pokémon è incapacitato e non può usare azioni o azioni bonus.', 'While Asleep is active, the Pokémon is incapacitated and cannot take actions or bonus actions.'),",
    "title: 'Tira 1d20 prima di agire',": "title: uiTextForLanguage('Tira 1d20 prima di agire', 'Roll 1d20 before acting'),",
    "'1–10: perde la concentrazione, subisce i danni previsti e la mossa fallisce. 11–15: agisce normalmente. 16+: Confused termina immediatamente.',": "uiTextForLanguage('1–10: perde la concentrazione, subisce i danni previsti e la mossa fallisce. 11–15: agisce normalmente. 16+: Confused termina immediatamente.', '1–10: it loses focus, takes the listed damage, and the move fails. 11–15: it acts normally. 16+: Confused ends immediately.'),",
    "title: 'Applica svantaggio',": "title: uiTextForLanguage('Applica svantaggio', 'Apply disadvantage'),",
    "'Applica svantaggio a tiri per colpire, prove e tiri salvezza effettuati prima della fine del prossimo turno.',": "uiTextForLanguage('Applica svantaggio a tiri per colpire, prove e tiri salvezza effettuati prima della fine del prossimo turno.', 'Apply disadvantage to attack rolls, checks, and saving throws made before the end of the next turn.'),",
    "title: 'Tiro di risveglio',": "title: uiTextForLanguage('Tiro di risveglio', 'Wake-up roll'),",
    "'Quando è sottoposto a una mossa, tira 1d20. Con 11 o più Asleep termina immediatamente.',": "uiTextForLanguage('Quando è sottoposto a una mossa, tira 1d20. Con 11 o più Asleep termina immediatamente.', 'When subjected to a move, roll 1d20. On 11 or higher, Asleep ends immediately.'),",
    "title: 'Controlla il tipo di danno',": "title: uiTextForLanguage('Controlla il tipo di danno', 'Check the damage type'),",
    "'Se subisce danni da una mossa capace di applicare Burned, Frozen termina immediatamente.',": "uiTextForLanguage('Se subisce danni da una mossa capace di applicare Burned, Frozen termina immediatamente.', 'If it takes damage from a move capable of applying Burned, Frozen ends immediately.'),",
    "title: 'Applica i danni da veleno',": "title: uiTextForLanguage('Applica i danni da veleno', 'Apply poison damage'),",
    "'Alla fine del turno subisce danni pari al bonus di competenza previsto dall’effetto che ha causato lo status.',": "uiTextForLanguage('Alla fine del turno subisce danni pari al bonus di competenza previsto dall’effetto che ha causato lo status.', 'At the end of its turn it takes damage equal to the proficiency bonus specified by the effect that caused the condition.'),",
    "title: 'Tiro salvezza di Forza',": "title: uiTextForLanguage('Tiro salvezza di Forza', 'Strength saving throw'),",
    "'Effettua un TS di Forza contro CD 10 + bonus di competenza della fonte. Con successo Frozen termina.',": "uiTextForLanguage('Effettua un TS di Forza contro CD 10 + bonus di competenza della fonte. Con successo Frozen termina.', 'Make a Strength saving throw against DC 10 + the source’s proficiency bonus. On a success, Frozen ends.'),",
    "'Tira 1d20. Con 11 o più Asleep termina immediatamente; altrimenti conta un altro turno completo.',": "uiTextForLanguage('Tira 1d20. Con 11 o più Asleep termina immediatamente; altrimenti conta un altro turno completo.', 'Roll 1d20. On 11 or higher, Asleep ends immediately; otherwise count another full turn.'),",
    "title: 'Aggiorna la durata',": "title: uiTextForLanguage('Aggiorna la durata', 'Update duration'),",
    "'Conta il turno completo appena terminato. Dopo 3 turni completi Confused termina se non è già cessato.',": "uiTextForLanguage('Conta il turno completo appena terminato. Dopo 3 turni completi Confused termina se non è già cessato.', 'Count the full turn that just ended. After 3 full turns, Confused ends if it has not already ended.'),",
    "title: 'Verifica la scadenza',": "title: uiTextForLanguage('Verifica la scadenza', 'Check expiration'),",
    "'Se questo è il turno successivo all’applicazione, rimuovi Flinched alla fine del turno.',": "uiTextForLanguage('Se questo è il turno successivo all’applicazione, rimuovi Flinched alla fine del turno.', 'If this is the turn after the condition was applied, remove Flinched at the end of the turn.'),",
}
for old, new in status_pairs.items():
    replace_all(path, old, new)

path = 'lib/widgets/battle/battle_status_assistance_card.dart'
replace_all(
    path,
    "Text(\n                        'ASSISTENZA STATUS',",
    "Text(\n                        uiTextForLanguage('ASSISTENZA STATUS', 'STATUS ASSISTANCE'),",
)

# ---------------------------------------------------------------------------
# Battle form labels, hints and mechanical notes.
# ---------------------------------------------------------------------------
path = 'lib/services/battle_form_change_service.dart'
add_import(path, "import 'dart:math' as math;\n\n", "import '../localization/ui_text.dart';\n")
regex_replace(
    path,
    r"  static String formLabel\(Pokemon pokemon, String\? formName\) \{.*?\n  \}\n\n  static String changeHint",
    """  static String formLabel(Pokemon pokemon, String? formName) {
    final key = canonicalFormKey(pokemon, formName);
    switch (pokemon.name) {
      case 'Deoxys':
        return switch (key) {
          'attack' => uiTextForLanguage('Forma Attacco', 'Attack Form'),
          'defense' => uiTextForLanguage('Forma Difesa', 'Defense Form'),
          'speed' => uiTextForLanguage('Forma Velocità', 'Speed Form'),
          _ => uiTextForLanguage('Forma Normale', 'Normal Form'),
        };
      case 'Castform':
        return switch (key) {
          'sunny' => uiTextForLanguage('Forma Sole', 'Sunny Form'),
          'rainy' => uiTextForLanguage('Forma Pioggia', 'Rainy Form'),
          'snowy' => uiTextForLanguage('Forma Neve', 'Snowy Form'),
          _ => uiTextForLanguage('Forma Normale', 'Normal Form'),
        };
      case 'Cherrim':
        return key == 'sunshine'
            ? uiTextForLanguage('Forma Splendore', 'Sunshine Form')
            : uiTextForLanguage('Forma Nuvola', 'Overcast Form');
      case 'Darmanitan':
        return switch (key) {
          'zen' => uiTextForLanguage('Stato Zen', 'Zen Mode'),
          'galarian-standard' => uiTextForLanguage(
            'Forma di Galar · Stato Normale',
            'Galarian Form · Standard Mode',
          ),
          'galarian-zen' => uiTextForLanguage(
            'Forma di Galar · Stato Zen',
            'Galarian Form · Zen Mode',
          ),
          _ => uiTextForLanguage('Stato Normale', 'Standard Mode'),
        };
      case 'Meloetta':
        return key == 'pirouette'
            ? uiTextForLanguage('Forma Danza', 'Pirouette Form')
            : uiTextForLanguage('Forma Canto', 'Aria Form');
      case 'Aegislash':
        return key == 'shield'
            ? uiTextForLanguage('Forma Scudo', 'Shield Form')
            : uiTextForLanguage('Forma Spada', 'Blade Form');
      case 'Zygarde':
        return switch (key) {
          '10' => uiTextForLanguage('Forma 10%', '10% Form'),
          'complete' => uiTextForLanguage('Forma Perfetta', 'Complete Form'),
          _ => uiTextForLanguage('Forma 50%', '50% Form'),
        };
      case 'Wishiwashi':
        return key == 'school'
            ? uiTextForLanguage('Forma Banco', 'School Form')
            : uiTextForLanguage('Forma Individuale', 'Solo Form');
      case 'Minior':
        return switch (key) {
          'core-red' => uiTextForLanguage('Nucleo Rosso', 'Red Core'),
          'core-orange' => uiTextForLanguage('Nucleo Arancione', 'Orange Core'),
          'core-yellow' => uiTextForLanguage('Nucleo Giallo', 'Yellow Core'),
          'core-green' => uiTextForLanguage('Nucleo Verde', 'Green Core'),
          'core-blue' => uiTextForLanguage('Nucleo Azzurro', 'Blue Core'),
          'core-indigo' => uiTextForLanguage('Nucleo Indaco', 'Indigo Core'),
          'core-violet' => uiTextForLanguage('Nucleo Violetto', 'Violet Core'),
          _ => uiTextForLanguage('Forma Meteora', 'Meteor Form'),
        };
      case 'Mimikyu':
        return key == 'busted'
            ? uiTextForLanguage('Forma Smascherata', 'Busted Form')
            : uiTextForLanguage('Forma Mascherata', 'Disguised Form');
      case 'Necrozma':
        return switch (key) {
          'dusk-mane' => uiTextForLanguage('Criniera del Vespro', 'Dusk Mane'),
          'dawn-wings' => uiTextForLanguage('Ali dell’Aurora', 'Dawn Wings'),
          'ultra' => 'Ultra Necrozma',
          _ => uiTextForLanguage('Forma Normale', 'Normal Form'),
        };
      case 'Cramorant':
        return switch (key) {
          'gulping' => uiTextForLanguage('Forma Inghiottitutto', 'Gulping Form'),
          'gorging' => uiTextForLanguage('Forma Ingozzata', 'Gorging Form'),
          _ => uiTextForLanguage('Forma Normale', 'Normal Form'),
        };
      case 'Eiscue':
        return key == 'noice-face'
            ? uiTextForLanguage('Forma Liquefaccia', 'Noice Face')
            : uiTextForLanguage('Forma Gelofaccia', 'Ice Face');
      case 'Morpeko':
        return key == 'hangry'
            ? uiTextForLanguage('Motivo Panciavuota', 'Hangry Mode')
            : uiTextForLanguage('Motivo Panciapiena', 'Full Belly Mode');
      case 'Palafin':
        return key == 'hero'
            ? uiTextForLanguage('Forma Possente', 'Hero Form')
            : uiTextForLanguage('Forma Ingenua', 'Zero Form');
      case 'Ogerpon':
        return switch (key) {
          'wellspring-mask' => uiTextForLanguage('Maschera Pozzo', 'Wellspring Mask'),
          'hearthflame-mask' => uiTextForLanguage('Maschera Focolare', 'Hearthflame Mask'),
          'cornerstone-mask' => uiTextForLanguage('Maschera Fondamenta', 'Cornerstone Mask'),
          _ => uiTextForLanguage('Maschera Turchese', 'Teal Mask'),
        };
      case 'Terapagos':
        return switch (key) {
          'terastal' => uiTextForLanguage('Forma Teracristal', 'Terastal Form'),
          'stellar' => uiTextForLanguage('Forma Astrale', 'Stellar Form'),
          _ => uiTextForLanguage('Forma Normale', 'Normal Form'),
        };
      default:
        return formName?.trim().isNotEmpty == true
            ? formName!
            : uiTextForLanguage('Forma', 'Form');
    }
  }

  static String changeHint""",
)
regex_replace(
    path,
    r"  static String changeHint\(Pokemon pokemon\) \{.*?\n  \}\n\n  static int armorClassBonus",
    """  static String changeHint(Pokemon pokemon) {
    switch (pokemon.name) {
      case 'Darmanitan':
        return uiTextForLanguage(
          'Lo Stato Zen si attiva sotto la metà dei PF se il Pokémon possiede l’abilità Stato Zen.',
          'Zen Mode activates below half HP if the Pokémon has the Zen Mode ability.',
        );
      case 'Aegislash':
        return uiTextForLanguage(
          'Accendilotta alterna Forma Spada e Forma Scudo in base alla mossa usata.',
          'Stance Change alternates Blade Form and Shield Form based on the move used.',
        );
      case 'Zygarde':
        return uiTextForLanguage(
          'La Forma 50% è quella predefinita; usa le altre forme quando la situazione di gioco lo richiede.',
          '50% Form is the default; use the other forms when the game situation requires them.',
        );
      case 'Minior':
        return uiTextForLanguage(
          'Scudi Giù alterna la Forma Meteora e il Nucleo; il colore del Nucleo è soltanto estetico.',
          'Shields Down alternates Meteor Form and Core; the Core color is cosmetic only.',
        );
      case 'Mimikyu':
        return uiTextForLanguage(
          'Fantasmanto mantiene la Forma Mascherata finché i suoi PF temporanei non vengono esauriti.',
          'Disguise keeps Disguised Form until its temporary HP are depleted.',
        );
      case 'Palafin':
        return uiTextForLanguage(
          'Supercambio consente di assumere la Forma Possente; al termine della lotta torna alla Forma Ingenua.',
          'Zero to Hero allows Hero Form; at the end of the battle it returns to Zero Form.',
        );
      default:
        return uiTextForLanguage(
          'Il cambio forma vale soltanto per la battaglia corrente.',
          'The form change applies only to the current battle.',
        );
    }
  }

  static int armorClassBonus""",
)
regex_replace(
    path,
    r"  static String\? effectNote\(Pokemon pokemon, String\? formName\) \{.*?\n  \}\n\n  static String _defaultFormKey",
    """  static String? effectNote(Pokemon pokemon, String? formName) {
    final key = canonicalFormKey(pokemon, formName);
    if (pokemon.name == 'Deoxys') {
      return switch (key) {
        'attack' => uiTextForLanguage('Mutante: +5 ai tiri per colpire.', 'Mutant: +5 to attack rolls.'),
        'defense' => uiTextForLanguage('Mutante: +3 alla CA.', 'Mutant: +3 AC.'),
        'speed' => uiTextForLanguage('Mutante: velocità raddoppiata.', 'Mutant: Speed is doubled.'),
        _ => uiTextForLanguage('Forma equilibrata, senza bonus di Mutante.', 'Balanced form, with no Mutant bonus.'),
      };
    }
    if (pokemon.name == 'Aegislash' && key == 'shield') {
      return uiTextForLanguage(
        'Accendilotta: CA 20 e DES 15 al posto dei valori della Forma Spada.',
        'Stance Change: AC 20 and DEX 15 instead of the Blade Form values.',
      );
    }
    if (pokemon.name == 'Zygarde') {
      return switch (key) {
        '10' => uiTextForLanguage('CA 16; FOR 16, DES 19, COS 15, INT 14, SAG 14, CAR 14.', 'AC 16; STR 16, DEX 19, CON 15, INT 14, WIS 14, CHA 14.'),
        'complete' => uiTextForLanguage('CA 20; FOR 19, DES 17, COS 30, INT 18, SAG 18, CAR 18.', 'AC 20; STR 19, DEX 17, CON 30, INT 18, WIS 18, CHA 18.'),
        _ => uiTextForLanguage('CA 18; FOR 19, DES 18, COS 20, INT 16, SAG 16, CAR 16.', 'AC 18; STR 19, DEX 18, CON 20, INT 16, WIS 16, CHA 16.'),
      };
    }
    if (pokemon.name == 'Darmanitan') {
      return switch (key) {
        'zen' => uiTextForLanguage('Tipo Fuoco/Psico, CA 18; FOR e SAG vengono scambiate.', 'Fire/Psychic type, AC 18; STR and WIS are swapped.'),
        'galarian-zen' => uiTextForLanguage('Tipo Ghiaccio/Fuoco; FOR e DES aumentano di 2.', 'Ice/Fire type; STR and DEX increase by 2.'),
        _ => null,
      };
    }
    if (pokemon.name == 'Mimikyu' && key == 'busted') {
      return uiTextForLanguage(
        'Fantasmanto è spezzato e non concede più PF temporanei.',
        'Disguise is broken and no longer grants temporary HP.',
      );
    }
    if (pokemon.name == 'Palafin' && key == 'hero') {
      return uiTextForLanguage(
        'Supercambio: +4 CA, +4 FOR e +4 DES (massimo 22) fino alla fine della lotta.',
        'Zero to Hero: +4 AC, +4 STR and +4 DEX (maximum 22) until the end of the battle.',
      );
    }
    return null;
  }

  static String _defaultFormKey""",
)

# Temporary HP rule keeps stable technical data but exposes localized text.
path = 'lib/services/battle_temporary_hp_service.dart'
add_import(path, "import '../models/pokemon.dart';\n", "import '../localization/ui_text.dart';\n")
must_replace(
    path,
    "  final String? brokenFormName;\n\n  int maximumForLevel(int level) {",
    """  final String? brokenFormName;

  String get localizedLabel => switch (id) {
    'disguise' => uiTextForLanguage('Fantasmanto', 'Disguise'),
    _ => label,
  };

  String get localizedDescription => switch (id) {
    'disguise' => uiTextForLanguage(
      'Concede PF temporanei pari al doppio del livello. Quando vengono esauriti, il Fantasmanto si rompe e Mimikyu assume la Forma Smascherata.',
      'Grants temporary HP equal to twice the level. When they are depleted, Disguise breaks and Mimikyu assumes Busted Form.',
    ),
    _ => description,
  };

  int maximumForLevel(int level) {""",
)

# ---------------------------------------------------------------------------
# Trainer Path: localize generated display text without changing saved values.
# ---------------------------------------------------------------------------
path = 'lib/services/trainer_path_automation_service.dart'
add_import(path, "import '../models/trainer_manual_content.dart';\n", "import '../localization/ui_text.dart';\n")
regex_replace(
    path,
    r"  String get resetLabel => switch \(reset\) \{.*?\n      \};",
    """  String get resetLabel => switch (reset) {
        TrainerPathResourceReset.shortRest =>
          uiTextForLanguage('Riposo breve', 'Short rest'),
        TrainerPathResourceReset.longRest =>
          uiTextForLanguage('Riposo lungo', 'Long rest'),
      };""",
)

path = 'lib/models/trainer_ui_localization.dart'
must_replace(
    path,
    "  static String optionLabel(String value) {\n    if (!_isItalian) return value;",
    """  static String optionLabel(String value) {
    if (!_isItalian) return _englishLegacyText(value);""",
)
must_replace(
    path,
    "  static String visibleText(String value) {\n    if (!_isItalian) return value;",
    """  static String visibleText(String value) {
    if (!_isItalian) return _englishLegacyText(value);""",
)
must_replace(
    path,
    "  static String optionLabel(String value) {",
    """  static String _englishLegacyText(String value) {
    const exact = <String, String>{
      'Dadi battaglia d6': 'Battle Dice d6',
      'Dadi abilità d6': 'Ability Dice d6',
      'Riserva di guarigione': 'Healing Pool',
      'Potenziamento permanente': 'Permanent boost',
      'La scelta si applica a tutti i Pokémon dell’Allenatore.':
          'The choice applies to all of the Trainer’s Pokémon.',
      'Privilegio copiato': 'Copied feature',
      'Scegli un privilegio di livello 2, 5 o 9 appartenente a un altro Trainer Path.':
          'Choose a level 2, 5 or 9 feature from another Trainer Path.',
      'Caratteristica di ricerca': 'Research ability score',
      'Il modificatore scelto viene aggiunto alle prove di abilità dei tuoi Pokémon, minimo +1.':
          'The chosen modifier is added to your Pokémon’s ability checks, minimum +1.',
      'Resistenza scelta': 'Chosen resistance',
      'La resistenza deve appartenere a uno dei tipi delle tue specializzazioni.':
          'The resistance must match one of your specialization types.',
      'Caratteristica di Deep Connection': 'Deep Connection ability score',
      'Determina il numero di utilizzi giornalieri, con un minimo di 1.':
          'Determines the number of daily uses, with a minimum of 1.',
      'Primo legame': 'First bond',
      'Il legame può essere ridefinito dopo un riposo lungo.':
          'The bond can be redefined after a long rest.',
      'Secondo legame': 'Second bond',
      'Nessun secondo legame': 'No second bond',
      'Scegli Nessun secondo legame per mantenere un solo Pokémon legato.':
          'Choose No second bond to keep only one bonded Pokémon.',
      '+10 ft velocità': '+10 ft Speed',
      'dadi': 'dice',
      'punti': 'points',
      'usi': 'uses',
    };
    return exact[value] ?? value;
  }

  static String optionLabel(String value) {""",
)

path = 'lib/services/trainer_path_passive_service.dart'
add_import(path, "import '../models/level_progression.dart';\n", "import '../localization/ui_text.dart';\n")
add_import(path, "import '../models/trainer_manual_options.dart';\n", "import '../models/trainer_ui_localization.dart';\n")
regex_replace(
    path,
    r"  static List<TrainerPathPassiveNote> passiveNotes\(\{.*?\n  \}\n\n  static String _normalizeType",
    """  static List<TrainerPathPassiveNote> passiveNotes({
    required UserProfile? profile,
    required Pokemon pokemon,
    required TeamSlot? slot,
  }) {
    if (profile == null || slot == null || profile.trainerPath.isEmpty) {
      return const [];
    }
    final notes = <TrainerPathPassiveNote>[];

    final attackBonus = attackRollBonus(
      profile: profile,
      pokemon: pokemon,
      slot: slot,
    );
    final damageBonus = damageRollBonus(profile: profile, slot: slot);
    if (attackBonus != 0 || damageBonus != 0) {
      notes.add(
        TrainerPathPassiveNote(
          title: uiTextForLanguage('Combattimento', 'Battle'),
          detail: uiTextForLanguage(
            'Tiri per colpire ${_signed(attackBonus)} · danni ${_signed(damageBonus)}.',
            'Attack rolls ${_signed(attackBonus)} · damage ${_signed(damageBonus)}.',
          ),
        ),
      );
    }

    if (hasFeature(profile, trainerPath: 'Ace Trainer', level: 9)) {
      final choice = profile.trainerPathChoices['aceMaxPotential'];
      if (choice != null && choice.isNotEmpty) {
        final detail = choice == '+10 ft velocità'
            ? uiTextForLanguage(
                'Velocità effettiva: ${effectiveSpeed(profile: profile, pokemon: pokemon, slot: slot)} ft.',
                'Effective Speed: ${effectiveSpeed(profile: profile, pokemon: pokemon, slot: slot)} ft.',
              )
            : uiTextForLanguage(
                '$choice applicato alle caratteristiche mostrate.',
                '${TrainerUiLocalization.optionLabel(choice)} applied to the displayed ability scores.',
              );
        notes.add(TrainerPathPassiveNote(title: 'Max Potential', detail: detail));
      }
    }

    if (hasFeature(profile, trainerPath: 'Researcher', level: 2)) {
      final ability = profile.trainerPathChoices['researcherAbility'];
      if (ability != null) {
        final score = profile.abilityScores[ability] ?? 10;
        final modifier = ((score - 10) / 2).floor().clamp(1, 99).toInt();
        notes.add(
          TrainerPathPassiveNote(
            title: 'Researcher',
            detail: uiTextForLanguage(
              '+$modifier alle prove di abilità del Pokémon ($ability).',
              '+$modifier to the Pokémon’s ability checks ($ability).',
            ),
          ),
        );
      }
    }

    final typeMatches = matchingSpecializationCount(profile, pokemon);
    if (hasFeature(profile, trainerPath: 'Type Master', level: 2) &&
        typeMatches > 0) {
      final resistance = profile.trainerPathChoices['typeMasterResistance'];
      notes.add(
        TrainerPathPassiveNote(
          title: 'Type Master',
          detail: [
            uiTextForLanguage('Bonus STAB del Path: +$typeMatches', 'Path STAB bonus: +$typeMatches'),
            if (profile.trainerLevel >= 5)
              uiTextForLanguage('+2 ai tiri per colpire già incluso', '+2 to attack rolls already included'),
            if (resistance != null)
              uiTextForLanguage('resistenza scelta: $resistance', 'chosen resistance: $resistance'),
            if (profile.trainerLevel >= 15)
              uiTextForLanguage('STAB applicabile a ogni mossa dannosa', 'STAB can apply to every damaging move'),
          ].join(' · '),
        ),
      );
    }

    if (hasFeature(profile, trainerPath: 'Commander', level: 2) && slot.loyalty > 0) {
      notes.add(
        TrainerPathPassiveNote(
          title: 'Commander',
          detail: uiTextForLanguage(
            'I bonus positivi di Lealtà a PF e tiri salvezza sono raddoppiati.',
            'Positive Loyalty bonuses to HP and saving throws are doubled.',
          ),
        ),
      );
    }

    if (hasFeature(profile, trainerPath: 'Guru', level: 5)) {
      notes.add(
        TrainerPathPassiveNote(
          title: 'Mind',
          detail: uiTextForLanguage(
            'Competenza nei tiri salvezza di Saggezza.',
            'Proficiency in Wisdom saving throws.',
          ),
        ),
      );
    }

    final copied = profile.trainerPathChoices['hobbyistManyFaces'];
    if (profile.trainerPath == 'Hobbyist' && copied != null) {
      notes.add(
        TrainerPathPassiveNote(
          title: 'Many Faces',
          detail: uiTextForLanguage(
            'Privilegio copiato: $copied.',
            'Copied feature: ${TrainerUiLocalization.optionLabel(copied)}.',
          ),
        ),
      );
    }

    return List.unmodifiable(notes);
  }

  static String _normalizeType""",
)

path = 'lib/widgets/trainer/trainer_path_automation_panel.dart'
replace_all(path, "label: Text('RIPOSO BREVE'),", "label: Text(uiTextForLanguage('RIPOSO BREVE', 'SHORT REST'))," )
replace_all(path, "label: Text('RIPOSO LUNGO'),", "label: Text(uiTextForLanguage('RIPOSO LUNGO', 'LONG REST'))," )
replace_all(path, "tooltip: 'Consuma',", "tooltip: uiTextForLanguage('Consuma', 'Spend'),")
replace_all(path, "tooltip: 'Recupera',", "tooltip: uiTextForLanguage('Recupera', 'Restore'),")
replace_all(
    path,
    "'Liv. ${definition.featureLevel} · ${TrainerUiLocalization.featureName(definition.featureTitle)} · ${definition.resetLabel}',",
    "'${uiTextForLanguage('Liv.', 'Lv.')} ${definition.featureLevel} · ${TrainerUiLocalization.featureName(definition.featureTitle)} · ${definition.resetLabel}',",
)
replace_all(
    path,
    "'$current/${definition.maxUses} ${definition.unitLabel}',",
    "'$current/${definition.maxUses} ${TrainerUiLocalization.visibleText(definition.unitLabel)}',",
)

# ---------------------------------------------------------------------------
# Evolution requirement generation and selector.
# ---------------------------------------------------------------------------
path = 'lib/services/evolution_service.dart'
add_import(path, "import '../models/bag_inventory_entry.dart';\n", "import '../localization/ui_text.dart';\n")
replace_all(path, "conditionLabels.add('Livello $requiredLevel');", "conditionLabels.add(uiTextForLanguage('Livello $requiredLevel', 'Level $requiredLevel'));" )
replace_all(path, "missing.add('Richiede ₽9.999 nel portafogli');", "missing.add(uiTextForLanguage('Richiede ₽9.999 nel portafogli', 'Requires ₽9,999 in the wallet'));" )
replace_all(path, "missing.add('Richiede livello $requiredLevel');", "missing.add(uiTextForLanguage('Richiede livello $requiredLevel', 'Requires level $requiredLevel'));" )
replace_all(path, "conditionLabels.add('Lealtà $requiredLoyalty');", "conditionLabels.add(uiTextForLanguage('Lealtà $requiredLoyalty', 'Loyalty $requiredLoyalty'));" )
replace_all(path, "missing.add('Richiede lealtà $requiredLoyalty');", "missing.add(uiTextForLanguage('Richiede lealtà $requiredLoyalty', 'Requires Loyalty $requiredLoyalty'));" )
replace_all(path, "conditionLabels.add('Sesso: ${_genderLabel(requiredGender)}');", "conditionLabels.add(uiTextForLanguage('Sesso: ${_genderLabel(requiredGender)}', 'Gender: ${_genderLabel(requiredGender)}'));" )
replace_all(path, "missing.add('Richiede sesso ${_genderLabel(requiredGender)}');", "missing.add(uiTextForLanguage('Richiede sesso ${_genderLabel(requiredGender)}', 'Requires gender ${_genderLabel(requiredGender)}'));" )
replace_all(path, "conditionLabels.add('Mossa: ${condition.valueLabel}');", "conditionLabels.add(uiTextForLanguage('Mossa: ${condition.valueLabel}', 'Move: ${condition.valueLabel}'));" )
replace_all(path, "missing.add('Richiede la mossa ${condition.valueLabel}');", "missing.add(uiTextForLanguage('Richiede la mossa ${condition.valueLabel}', 'Requires the move ${condition.valueLabel}'));" )
regex_replace(
    path,
    r"            missing\.add\(\n              'Oggetto richiesto non trovato: \$\{condition\.valueLabel\}',\n            \);",
    """            missing.add(
              uiTextForLanguage(
                'Oggetto richiesto non trovato: ${condition.valueLabel}',
                'Required item not found: ${condition.valueLabel}',
              ),
            );""",
)
replace_all(path, "missing.add('Richiede ${requiredItem.name} nello zaino');", "missing.add(uiTextForLanguage('Richiede ${requiredItem.name} nello zaino', 'Requires ${requiredItem.name} in the Bag'));" )
replace_all(path, "return 'Oppure prima del livello 10 consumando ₽9.999';", "return uiTextForLanguage('Oppure prima del livello 10 consumando ₽9.999', 'Or before level 10 by spending ₽9,999');" )
regex_replace(
    path,
    r"  String _genderLabel\(String value\) \{.*?\n  \}\n\n  String _referenceKey",
    """  String _genderLabel(String value) {
    switch (value) {
      case 'male':
        return uiTextForLanguage('Maschio', 'Male');
      case 'female':
        return uiTextForLanguage('Femmina', 'Female');
      case 'genderless':
        return uiTextForLanguage('Senza sesso', 'Genderless');
      default:
        return value;
    }
  }

  String _referenceKey""",
)

path = 'lib/screens/pokemon/evolution_selector_sheet.dart'
replace_all(path, "? 'Evoluzione'", "? uiTextForLanguage('Evoluzione', 'Evolution')")
replace_all(path, "? 'Controlla i requisiti per far evolvere ${currentPokemon.name}.'", "? uiTextForLanguage('Controlla i requisiti per far evolvere ${currentPokemon.name}.', 'Check the requirements to evolve ${currentPokemon.name}.')")
replace_all(path, "? 'Evolvi'", "? uiTextForLanguage('Evolvi', 'Evolve')")
replace_all(path, "? 'EVOLUZIONE SCONOSCIUTA'", "? uiTextForLanguage('EVOLUZIONE SCONOSCIUTA', 'UNKNOWN EVOLUTION')")

# ---------------------------------------------------------------------------
# Battle Companion direct messages and panels.
# ---------------------------------------------------------------------------
path = 'lib/screens/battle/battle_screen.dart'
replace_all(
    path,
    "_message =\n          '${_displayName(slot, basePokemon)} assume la ${BattleFormChangeService.formLabel(basePokemon, selected)}.';",
    "_message = context.uiText(\n        '${_displayName(slot, basePokemon)} assume la ${BattleFormChangeService.formLabel(basePokemon, selected)}.',\n        '${_displayName(slot, basePokemon)} changes to ${BattleFormChangeService.formLabel(basePokemon, selected)}.',\n      );",
)
replace_all(path, "setState(() => _message = 'Un Pokémon esausto non può megaevolversi.');", "setState(() => _message = context.uiText('Un Pokémon esausto non può megaevolversi.', 'A fainted Pokémon cannot Mega Evolve.'));" )
replace_all(path, "title: 'Scegli la Mega Evoluzione',", "title: context.uiText('Scegli la Mega Evoluzione', 'Choose Mega Evolution'),")
replace_all(
    path,
    "_message =\n          '${_displayName(slot, pokemon)} attiva ${selected?.label ?? 'Mega Evoluzione'}.';",
    "_message = context.uiText(\n        '${_displayName(slot, pokemon)} attiva ${selected?.label ?? 'Mega Evoluzione'}.',\n        '${_displayName(slot, pokemon)} activates ${selected?.label ?? 'Mega Evolution'}.',\n      );",
)
replace_all(path, "setState(() => _message = 'Un Pokémon esausto non può Dynamaxizzarsi.');", "setState(() => _message = context.uiText('Un Pokémon esausto non può Dynamaxizzarsi.', 'A fainted Pokémon cannot Dynamax.'));" )
replace_all(
    path,
    "_message =\n          '${_displayName(slot, pokemon)} attiva ${selectedArt?.label ?? 'Dynamax'} e ottiene $currentHp PF temporanei.';",
    "_message = context.uiText(\n        '${_displayName(slot, pokemon)} attiva ${selectedArt?.label ?? 'Dynamax'} e ottiene $currentHp PF temporanei.',\n        '${_displayName(slot, pokemon)} activates ${selectedArt?.label ?? 'Dynamax'} and gains $currentHp temporary HP.',\n      );",
)
replace_all(path, "() => _message = 'Un Pokémon esausto non può teracristallizzarsi.',", "() => _message = context.uiText('Un Pokémon esausto non può teracristallizzarsi.', 'A fainted Pokémon cannot Terastallize.'),")
replace_all(
    path,
    "_message =\n          '${_displayName(slot, pokemon)} si teracristallizza nel tipo $teraType.';",
    "_message = context.uiText(\n        '${_displayName(slot, pokemon)} si teracristallizza nel tipo $teraType.',\n        '${_displayName(slot, pokemon)} Terastallizes into the $teraType type.',\n      );",
)
replace_all(path, "() => _message = 'Un Pokémon esausto non può usare una Mossa Z.',", "() => _message = context.uiText('Un Pokémon esausto non può usare una Mossa Z.', 'A fainted Pokémon cannot use a Z-Move.'),")
replace_all(path, "() => _message = 'Nessuna Mossa Z compatibile ha PP disponibili.',", "() => _message = context.uiText('Nessuna Mossa Z compatibile ha PP disponibili.', 'No compatible Z-Move has PP available.'),")
replace_all(
    path,
    "_message =\n          'Mossa Z · ${selected.move.name}: ${BattleTransformationService.zMoveSummary(selected.move)}.';",
    "_message = context.uiText(\n        'Mossa Z · ${selected.move.name}: ${BattleTransformationService.zMoveSummary(selected.move)}.',\n        'Z-Move · ${selected.move.name}: ${BattleTransformationService.zMoveSummary(selected.move)}.',\n      );",
)
replace_all(path, "'${rule.label} attivato: ${_temporaryHpBySlot[slot.slotIndex]} PF temporanei.',", "'${rule.localizedLabel} attivato: ${_temporaryHpBySlot[slot.slotIndex]} PF temporanei.',")
replace_all(path, "'${rule.label} enabled: ${_temporaryHpBySlot[slot.slotIndex]} temporary HP.',", "'${rule.localizedLabel} enabled: ${_temporaryHpBySlot[slot.slotIndex]} temporary HP.',")
replace_all(path, "'${rule.label} disattivato.',", "'${rule.localizedLabel} disattivato.',")
replace_all(path, "'${rule.label} disabled.',", "'${rule.localizedLabel} disabled.',")
regex_replace(
    path,
    r"    if \(dynamaxAbsorbed > 0\) \{.*?\n    \}\n    if \(absorbed > 0\) \{.*?\n    \}",
    """    if (dynamaxAbsorbed > 0) {
      final stillActive =
          _transformationBySlot[slot.slotIndex]?.isDynamaxLike == true;
      messages.add(
        stillActive
            ? context.uiText(
                '$dynamaxAbsorbed danni assorbiti dai PF Dynamax.',
                '$dynamaxAbsorbed damage absorbed by Dynamax HP.',
              )
            : context.uiText(
                '$dynamaxAbsorbed danni assorbiti: Dynamax/Gigamax termina.',
                '$dynamaxAbsorbed damage absorbed: Dynamax/Gigantamax ends.',
              ),
      );
    }
    if (absorbed > 0) {
      messages.add(
        (_temporaryHpBySlot[slot.slotIndex] ?? 0) > 0
            ? context.uiText(
                '$absorbed danni assorbiti dai PF temporanei.',
                '$absorbed damage absorbed by temporary HP.',
              )
            : context.uiText(
                '$absorbed danni assorbiti: ${rule?.localizedLabel ?? 'la protezione'} si spezza.',
                '$absorbed damage absorbed: ${rule?.localizedLabel ?? 'the protection'} breaks.',
              ),
      );
    }""",
)
replace_all(path, "'${rule.label}: $currentHp PF temporanei',", "context.uiText('${rule.localizedLabel}: $currentHp PF temporanei', '${rule.localizedLabel}: $currentHp temporary HP'),")
replace_all(path, "rule.description,", "rule.localizedDescription,")
regex_replace(
    path,
    r"                  state\.isDynamaxLike\n                      \? '\$\{state\.kind\.label\} attiva · \$\{state\.dynamaxTemporaryHp\} PF Dynamax'\n                      : state\.kind == BattleTransformationKind\.terastal\n                      \? '\$\{state\.kind\.label\} attiva · \$\{state\.teraType\}'\n                      : state\.kind == BattleTransformationKind\.zMove\n                      \? 'Mossa Z già usata in questo riposo lungo'\n                      : '\$\{state\.kind\.label\} attiva',",
    """                  state.isDynamaxLike
                      ? context.uiText(
                          '${state.kind.label} attiva · ${state.dynamaxTemporaryHp} PF Dynamax',
                          '${state.kind.label} active · ${state.dynamaxTemporaryHp} Dynamax HP',
                        )
                      : state.kind == BattleTransformationKind.terastal
                      ? context.uiText(
                          '${state.kind.label} attiva · ${state.teraType}',
                          '${state.kind.label} active · ${state.teraType}',
                        )
                      : state.kind == BattleTransformationKind.zMove
                      ? context.uiText(
                          'Mossa Z già usata in questo riposo lungo',
                          'Z-Move already used during this long rest',
                        )
                      : context.uiText(
                          '${state.kind.label} attiva',
                          '${state.kind.label} active',
                        ),""",
)
replace_all(path, "Text('$pokemonName · Cristallo Z $crystalType'),", "Text(context.uiText('$pokemonName · Cristallo Z $crystalType', '$pokemonName · $crystalType Z-Crystal'))," )

# ---------------------------------------------------------------------------
# Master battle + exported summary.
# ---------------------------------------------------------------------------
path = 'lib/services/master_fight_summary_service.dart'
add_import(path, "import '../models/master_battle_session.dart';\n", "import '../localization/ui_text.dart';\n")
regex_replace(
    path,
    r"  String build\(\{.*?\n  \}\n\n  String fileName",
    """  String build({
    required MasterBattleSession session,
    required Map<int, Pokemon> pokemonById,
    DateTime? exportedAt,
  }) {
    final generatedAt = exportedAt ?? DateTime.now();
    final buffer = StringBuffer()
      ..writeln(
        uiTextForLanguage(
          'POKÉDEX 5E ITA — RIEPILOGO FIGHT DEL MASTER',
          'TRAINER ATLAS 5E — MASTER FIGHT SUMMARY',
        ),
      )
      ..writeln(uiTextForLanguage('Esportato: $generatedAt', 'Exported: $generatedAt'))
      ..writeln(uiTextForLanguage('Round: ${session.round}', 'Round: ${session.round}'))
      ..writeln(
        uiTextForLanguage(
          'Allenatori PNG: ${session.participants.length}',
          'NPC Trainers: ${session.participants.length}',
        ),
      )
      ..writeln();

    buffer.writeln(uiTextForLanguage('INIZIATIVA', 'INITIATIVE'));
    if (session.initiativeEntries.isEmpty) {
      buffer.writeln(uiTextForLanguage('- Nessun partecipante in iniziativa', '- No initiative entries'));
    } else {
      for (var index = 0; index < session.initiativeEntries.length; index++) {
        final entry = session.initiativeEntries[index];
        final current = index == session.turnIndex
            ? uiTextForLanguage(' ← TURNO ATTUALE', ' ← CURRENT TURN')
            : '';
        buffer.writeln('- ${entry.initiative}: ${entry.name}$current');
      }
    }

    for (final participant in session.participants) {
      buffer
        ..writeln()
        ..writeln(participant.displayName.toUpperCase())
        ..writeln(
          uiTextForLanguage(
            '${participant.rank} · limite attivi ${participant.activeLimit}',
            '${participant.rank} · active limit ${participant.activeLimit}',
          ),
        );
      if (participant.personality.trim().isNotEmpty) {
        buffer.writeln(uiTextForLanguage('Personalità: ${participant.personality.trim()}', 'Personality: ${participant.personality.trim()}'));
      }
      if (participant.tactics.trim().isNotEmpty) {
        buffer.writeln(uiTextForLanguage('Tattiche: ${participant.tactics.trim()}', 'Tactics: ${participant.tactics.trim()}'));
      }
      if (participant.rewardMoney > 0) {
        buffer.writeln(uiTextForLanguage('Ricompensa: ₽${participant.rewardMoney}', 'Reward: ₽${participant.rewardMoney}'));
      }
      if (participant.rewards.isNotEmpty) {
        buffer.writeln(uiTextForLanguage('Oggetti: ${participant.rewards.join(', ')}', 'Items: ${participant.rewards.join(', ')}'));
      }
      buffer.writeln(uiTextForLanguage('Squadra:', 'Team:'));

      for (final state in participant.team) {
        final pokemon = pokemonById[state.pokemon.pokemonId];
        final name = pokemon == null
            ? '#${state.pokemon.pokemonId}'
            : pokemonFormDisplayName(pokemon.name, state.pokemon.formName);
        final active = participant.activeSlotIndices.contains(state.slotIndex)
            ? uiTextForLanguage('ATTIVO', 'ACTIVE')
            : uiTextForLanguage('RISERVA', 'RESERVE');
        final fainted = state.isFainted
            ? uiTextForLanguage(' · ESAUSTO', ' · FAINTED')
            : '';
        final statuses = <String>[
          if (state.nonVolatileStatus != null) state.nonVolatileStatus!,
          ...(state.volatileStatuses.toList()..sort()),
        ];
        final statusText = statuses.isEmpty
            ? uiTextForLanguage('nessuno', 'none')
            : statuses.join(', ');
        buffer.writeln(
          uiTextForLanguage(
            '- [$active] $name Lv. ${state.pokemon.level} · PF ${state.currentHp}/${state.pokemon.maxHp}$fainted · Status: $statusText',
            '- [$active] $name Lv. ${state.pokemon.level} · HP ${state.currentHp}/${state.pokemon.maxHp}$fainted · Conditions: $statusText',
          ),
        );

        final moves = state.pokemon.selectedMoves;
        if (moves.isEmpty) {
          buffer.writeln(uiTextForLanguage('  Mosse: nessuna', '  Moves: none'));
        } else {
          final pp = [
            for (final move in moves)
              '$move ${state.remainingPp.containsKey(move) ? state.remainingPp[move] : '?'} PP',
          ];
          buffer.writeln(uiTextForLanguage('  Mosse: ${pp.join(' · ')}', '  Moves: ${pp.join(' · ')}'));
        }
      }
    }

    return buffer.toString().trimRight();
  }

  String fileName""",
)

path = 'lib/screens/battle/npc_battle_screen.dart'
replace_all(path, "message: 'Fight azzerato.',", "message: uiTextForLanguage('Fight azzerato.', 'Fight reset.'),")
replace_all(path, "title: Text('Terminare il fight?'),", "title: Text(uiTextForLanguage('Terminare il fight?', 'End the fight?'))," )
replace_all(path, "title: Text('Fight del Master'),", "title: Text(uiTextForLanguage('Fight del Master', 'Master Fight'))," )
replace_all(path, "'Tattiche: ${participant.tactics}',", "uiTextForLanguage('Tattiche: ${participant.tactics}', 'Tactics: ${participant.tactics}'),")
replace_all(path, ": 'Partecipante esterno non gestito',", ": uiTextForLanguage('Partecipante esterno non gestito', 'External participant not managed by the app'),")
replace_all(
    path,
    "'Lv. ${state.pokemon.level} · PF ${state.currentHp}/${state.pokemon.maxHp}'\n                      '${state.isFainted ? ' · ESAUSTO' : ''}',",
    "context.uiText(\n                        'Lv. ${state.pokemon.level} · PF ${state.currentHp}/${state.pokemon.maxHp}${state.isFainted ? ' · ESAUSTO' : ''}',\n                        'Lv. ${state.pokemon.level} · HP ${state.currentHp}/${state.pokemon.maxHp}${state.isFainted ? ' · FAINTED' : ''}',\n                      ),",
)
replace_all(path, "'PF ${state.currentHp}/${state.pokemon.maxHp}',", "context.uiText('PF ${state.currentHp}/${state.pokemon.maxHp}', 'HP ${state.currentHp}/${state.pokemon.maxHp}'),")
replace_all(path, "label: Text('RIPRISTINA'),", "label: Text(uiTextForLanguage('RIPRISTINA', 'RESTORE'))," )
replace_all(path, "save == null ? null : 'TS $save',", "save == null ? null : uiTextForLanguage('TS $save', 'Save $save'),")
replace_all(path, "tooltip: 'Ripristina PP',", "tooltip: uiTextForLanguage('Ripristina PP', 'Restore PP'),")
replace_all(
    path,
    "helperText:\n              'Esempi: -12, +8 oppure 35. Attuali ${widget.currentHp}/${widget.maxHp}',",
    "helperText: uiTextForLanguage(\n              'Esempi: -12, +8 oppure 35. Attuali ${widget.currentHp}/${widget.maxHp}',\n              'Examples: -12, +8 or 35. Current ${widget.currentHp}/${widget.maxHp}',\n            ),",
)
replace_all(path, "labelText: 'Status persistente',", "labelText: uiTextForLanguage('Status persistente', 'Persistent condition'),")
replace_all(path, "'Status temporanei',", "uiTextForLanguage('Status temporanei', 'Temporary conditions'),")

# ---------------------------------------------------------------------------
# Fakemon tools: visible editor/library residue only; saved schema stays intact.
# ---------------------------------------------------------------------------
path = 'lib/screens/pokemon/custom_pokemon_library_screen.dart'
aux_replacements = {
    "name: '${source.name} (copia)',": "name: uiTextForLanguage('${source.name} (copia)', '${source.name} (copy)'),",
    "_setMessage('${duplicate.name} creato.');": "_setMessage(uiTextForLanguage('${duplicate.name} creato.', '${duplicate.name} created.'));",
    "title: Text('Impossibile eliminare ${definition.name}'),": "title: Text(uiTextForLanguage('Impossibile eliminare ${definition.name}', 'Cannot delete ${definition.name}')),
",
    "title: Text('Eliminare ${definition.name}?'),": "title: Text(uiTextForLanguage('Eliminare ${definition.name}?', 'Delete ${definition.name}?')),
",
    "_setMessage('${definition.name} eliminato.');": "_setMessage(uiTextForLanguage('${definition.name} eliminato.', '${definition.name} deleted.'));",
    "'${bundle.definitions.length} Fakemon esportati.',": "uiTextForLanguage('${bundle.definitions.length} Fakemon esportati.', '${bundle.definitions.length} Fakemon exported.'),",
    "child: Text('NORMALE'),": "child: Text(uiTextForLanguage('NORMALE', 'NORMAL')),",
    "label: Text('SEGRETA'),": "label: Text(uiTextForLanguage('SEGRETA', 'SECRET')),",
    "text: 'Fakemon creato con Trainer Atlas 5e.',": "text: uiTextForLanguage('Fakemon creato con Trainer Atlas 5e.', 'Fakemon created with Trainer Atlas 5e.'),",
    "successMessage: '${definition.name} condiviso.',": "successMessage: uiTextForLanguage('${definition.name} condiviso.', '${definition.name} shared.'),",
    "? '${imported.definition.name} aggiornato.'": "? uiTextForLanguage('${imported.definition.name} aggiornato.', '${imported.definition.name} updated.')",
    "title: Text('I MIEI FAKEMON'),": "title: Text(uiTextForLanguage('I MIEI FAKEMON', 'MY FAKEMON')),",
    "return 'Formato immagine non supportato.';": "return uiTextForLanguage('Formato immagine non supportato.', 'Unsupported image format.');",
    "label: 'IMMAGINE PRINCIPALE',": "label: uiTextForLanguage('IMMAGINE PRINCIPALE', 'MAIN IMAGE'),",
    "label: 'SHINY (FACOLTATIVA)',": "label: uiTextForLanguage('SHINY (FACOLTATIVA)', 'SHINY (OPTIONAL)'),",
    "_RequiredTextField(controller: _author, label: 'Autore'),": "_RequiredTextField(controller: _author, label: uiTextForLanguage('Autore', 'Author')),",
    "labelText: 'Categoria / genere',": "labelText: uiTextForLanguage('Categoria / genere', 'Category / genus'),",
    "decoration: InputDecoration(labelText: 'Note del creatore'),": "decoration: InputDecoration(labelText: uiTextForLanguage('Note del creatore', 'Creator notes')),",
    "title: 'Tipi e dati fisici',": "title: uiTextForLanguage('Tipi e dati fisici', 'Types and physical data'),",
    "'Tipo principale',": "uiTextForLanguage('Tipo principale', 'Primary type'),",
    "'Tipo secondario',": "uiTextForLanguage('Tipo secondario', 'Secondary type'),",
    "decoration: InputDecoration(labelText: 'Taglia'),": "decoration: InputDecoration(labelText: uiTextForLanguage('Taglia', 'Size')),",
    "_optionalNumber(_height, 'Altezza (decimetri)'),": "_optionalNumber(_height, uiTextForLanguage('Altezza (decimetri)', 'Height (decimeters)')),",
    "labelText: 'Rapporto tra i sessi',": "labelText: uiTextForLanguage('Rapporto tra i sessi', 'Gender ratio'),",
    "title: 'Statistiche 5e',": "title: uiTextForLanguage('Statistiche 5e', '5e statistics'),",
    "_numberBox(_ac, 'CA', min: 1),": "_numberBox(_ac, uiTextForLanguage('CA', 'AC'), min: 1),",
    "_numberBox(_hp, 'PF', min: 1),": "_numberBox(_hp, uiTextForLanguage('PF', 'HP'), min: 1),",
    "_numberBox(_hitDice, 'Dadi Vita', min: 1),": "_numberBox(_hitDice, uiTextForLanguage('Dadi Vita', 'Hit Dice'), min: 1),",
    "labelText: 'Tiri salvezza, separati da virgole',": "labelText: uiTextForLanguage('Tiri salvezza, separati da virgole', 'Saving throws, comma-separated'),",
    "label: Text('NUOVA ESCLUSIVA'),": "label: Text(uiTextForLanguage('NUOVA ESCLUSIVA', 'NEW EXCLUSIVE')),",
    "return id == null || id <= 0 ? 'ID non valido' : null;": "return id == null || id <= 0 ? uiTextForLanguage('ID non valido', 'Invalid ID') : null;",
    "labelText: 'Numeri MT, separati da virgole',": "labelText: uiTextForLanguage('Numeri MT, separati da virgole', 'TM numbers, comma-separated'),",
    "return 'Inserisci soltanto numeri MT separati da virgole.';": "return uiTextForLanguage('Inserisci soltanto numeri MT separati da virgole.', 'Enter only comma-separated TM numbers.');",
    "title: Text('Nuova mossa esclusiva'),": "title: Text(uiTextForLanguage('Nuova mossa esclusiva', 'New exclusive move')),",
    "title: Text('Richiede tiro per colpire'),": "title: Text(uiTextForLanguage('Richiede tiro per colpire', 'Requires an attack roll')),",
    "labelText: 'Tiro salvezza, se previsto',": "labelText: uiTextForLanguage('Tiro salvezza, se previsto', 'Saving throw, if any'),",
    "labelText: 'Danno al livello 1, es. 2d6',": "labelText: uiTextForLanguage('Danno al livello 1, es. 2d6', 'Damage at level 1, e.g. 2d6'),",
    "labelText: 'Descrizione completa',": "labelText: uiTextForLanguage('Descrizione completa', 'Full description'),",
}
for old, new in aux_replacements.items():
    replace_all(path, old, new)

path = 'lib/screens/pokemon/custom_pokemon_advanced_editor_screen.dart'
advanced_replacements = {
    "appBar: AppBar(title: Text('FAKEMON AVANZATO · ${widget.currentName}')),": "appBar: AppBar(title: Text(uiTextForLanguage('FAKEMON AVANZATO · ${widget.currentName}', 'ADVANCED FAKEMON · ${widget.currentName}'))),",
    "labelText: 'Indizio facoltativo',": "labelText: uiTextForLanguage('Indizio facoltativo', 'Optional hint'),",
    "title: Text('Segreta fino all’attivazione'),": "title: Text(uiTextForLanguage('Segreta fino all’attivazione', 'Secret until activation')),",
    "title: 'Nuove pre-evoluzioni',": "title: uiTextForLanguage('Nuove pre-evoluzioni', 'New pre-evolutions'),",
    "description:\n                        '${widget.currentName} diventa una nuova evoluzione delle specie elencate.',": "description: uiTextForLanguage('${widget.currentName} diventa una nuova evoluzione delle specie elencate.', '${widget.currentName} becomes a new evolution of the listed species.'),",
    "title: 'Evoluzioni successive',": "title: uiTextForLanguage('Evoluzioni successive', 'Further evolutions'),",
    "title: 'Sottoforme del Fakemon',": "title: uiTextForLanguage('Sottoforme del Fakemon', 'Fakemon subforms'),",
    "Expanded(child: _numberField(_asi, 'Punti ASI')),": "Expanded(child: _numberField(_asi, uiTextForLanguage('Punti ASI', 'ASI points'))),",
    "labelText: 'Indizio evolutivo facoltativo',": "labelText: uiTextForLanguage('Indizio evolutivo facoltativo', 'Optional evolution hint'),",
    "tooltip: 'Pulisci',": "tooltip: uiTextForLanguage('Pulisci', 'Clear'),",
    "'Compila tutte le caratteristiche oppure lasciale vuote.',": "uiTextForLanguage('Compila tutte le caratteristiche oppure lasciale vuote.', 'Fill in all ability scores or leave them all blank.'),",
    "decoration: InputDecoration(labelText: 'Durata'),": "decoration: InputDecoration(labelText: uiTextForLanguage('Durata', 'Duration')),",
    "title: Text('Segreta fino alla prima attivazione'),": "title: Text(uiTextForLanguage('Segreta fino alla prima attivazione', 'Secret until first activation')),",
    "decoration: InputDecoration(labelText: 'Indizio / attivazione'),": "decoration: InputDecoration(labelText: uiTextForLanguage('Indizio / attivazione', 'Hint / activation')),",
    "label: 'Tipo principale',": "label: uiTextForLanguage('Tipo principale', 'Primary type'),",
    "label: 'Tipo secondario',": "label: uiTextForLanguage('Tipo secondario', 'Secondary type'),",
    "DropdownMenuItem(value: null, child: Text('Eredita')),": "DropdownMenuItem(value: null, child: Text(uiTextForLanguage('Eredita', 'Inherit'))),",
}
for old, new in advanced_replacements.items():
    replace_all(path, old, new)

# ---------------------------------------------------------------------------
# Regression test: English mode must localize service-generated text while
# preserving the legacy stored values used by Trainer Path logic.
# ---------------------------------------------------------------------------
test_path = ROOT / 'test/english_ui_localization_test.dart'
test_path.write_text(
    """import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/localization/game_catalog_locale.dart';
import 'package:pokedex_5e_ita/models/battle_transformation.dart';
import 'package:pokedex_5e_ita/models/trainer_ui_localization.dart';
import 'package:pokedex_5e_ita/services/battle_form_change_service.dart';
import 'package:pokedex_5e_ita/services/battle_status_rules.dart';
import 'package:pokedex_5e_ita/services/battle_transformation_service.dart';

void main() {
  tearDown(() => GameCatalogLocale.setLanguageCode('it'));

  test('English mode localizes generated Battle Companion text', () {
    GameCatalogLocale.setLanguageCode('en');

    expect(BattleTransformationKind.mega.label, 'Mega Evolution');
    expect(BattleStatusMoment.turnStart.label, 'START OF TURN');
    expect(
      BattleTransformationService.effectSummary(
        const BattleTransformationState(kind: BattleTransformationKind.mega),
      ),
      contains('AC +2'),
    );

    final blocked = BattleTransformationService.eligibility(
      kind: BattleTransformationKind.mega,
      pokemonLevel: 10,
      isFinalEvolutionStage: true,
      heldItemId: null,
      inventory: const [],
      trainerUses: const {},
      pokemonAlreadyTransformed: false,
      hasActiveTransformation: false,
    );
    expect(blocked.missingRequirements, contains('Requires a Key Stone in the Bag'));
  });

  test('English mode translates legacy Trainer Path display values only', () {
    GameCatalogLocale.setLanguageCode('en');

    expect(TrainerUiLocalization.optionLabel('+10 ft velocità'), '+10 ft Speed');
    expect(TrainerUiLocalization.visibleText('Dadi battaglia d6'), 'Battle Dice d6');
  });

  test('Italian mode remains the default presentation', () {
    GameCatalogLocale.setLanguageCode('it');
    expect(BattleTransformationKind.mega.label, 'Mega Evoluzione');
    expect(BattleStatusMoment.turnStart.label, 'INIZIO TURNO');
  });
}
""",
    encoding='utf-8',
)

print('English UI localization pass applied.')
