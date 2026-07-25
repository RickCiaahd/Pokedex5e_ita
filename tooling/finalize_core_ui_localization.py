from __future__ import annotations

from pathlib import Path


def dart_string(value: str) -> str:
    return "'" + value.replace('\\', '\\\\').replace("'", "\\'") + "'"


def localize_literals(path: str, pairs: list[tuple[str, str]]) -> None:
    file = Path(path)
    text = file.read_text(encoding='utf-8')
    for italian, english in pairs:
        source = dart_string(italian)
        target = f'context.uiText({dart_string(italian)}, {dart_string(english)})'
        if source in text:
            text = text.replace(source, target)
    text = text.replace(
        'const InputDecoration(labelText: context.uiText(',
        'InputDecoration(labelText: context.uiText(',
    )
    text = text.replace(
        'decoration: const InputDecoration(\n                      hintText: context.uiText(',
        'decoration: InputDecoration(\n                      hintText: context.uiText(',
    )
    file.write_text(text, encoding='utf-8')


localize_literals(
    'lib/screens/battle/battle_screen.dart',
    [
        ('SQUADRA', 'TEAM'),
        ('INIZIATIVA', 'INITIATIVE'),
        ('Partecipante esterno', 'External participant'),
        ('POKÉMON CENTER', 'POKÉMON CENTER'),
        ('Strumento tenuto', 'Held item'),
        ('Strumento tenuto: ${_itemTypeLabel(item.type)}.', 'Held item: ${_itemTypeLabel(item.type)}.'),
        ('${rule.label} attivato: ${_temporaryHpBySlot[slot.slotIndex]} PF temporanei.', '${rule.label} enabled: ${_temporaryHpBySlot[slot.slotIndex]} temporary HP.'),
        ('${rule.label} disattivato.', '${rule.label} disabled.'),
        ('$absorbed danni assorbiti: ${rule?.label ?? "protezione"} si spezza.', '$absorbed damage absorbed: ${rule?.label ?? "protection"} breaks.'),
        ('${_displayName(slot, pokemon)} è pronto a combattere.', '${_displayName(slot, pokemon)} is ready to battle.'),
        ('Non hai medicine, bacche utilizzabili o Poké Ball nello zaino.', 'You have no medicine, usable Berries or Poké Balls in the Bag.'),
        ('Impossibile aprire lo zaino rapido: $error', 'Could not open the quick Bag: $error'),
        ('Non hai più ${item.name} nello zaino.', 'You have no more ${item.name} in the Bag.'),
        ('Lancia ${ball.name}?', 'Throw ${ball.name}?'),
        ('Dopo il tiro, inserisci l’esito comunicato dal Master. La Poké Ball verrà consumata in ogni caso.', 'After the roll, enter the result given by the GM. The Poké Ball will be consumed either way.'),
        ('NO, FALLITA', 'NO, FAILED'),
        ('SÌ, CATTURATO', 'YES, CAUGHT'),
        ('Non hai più ${ball.name} nello zaino.', 'You have no more ${ball.name} in the Bag.'),
        ('${ball.name} consumata. Cattura fallita.', '${ball.name} consumed. Catch failed.'),
        ('${ball.name} consumata. Registra il Pokémon catturato.', '${ball.name} consumed. Record the caught Pokémon.'),
        ('${_displayName(slot, pokemon)} $effects usando ${item.name}.', '${_displayName(slot, pokemon)} $effects using ${item.name}.'),
        ('Meteo d100: $roll - ${weather.label}.', 'Weather d100: $roll - ${weather.label}.'),
        ('${_displayName(slot, pokemon)} subisce $damage danni da ${_environment.weather.label}.', '${_displayName(slot, pokemon)} takes $damage damage from ${_environment.weather.label}.'),
        ('Iniziativa allenatore/Pokémon: $roll.', 'Trainer/Pokémon initiative: $roll.'),
        ('Round $_round iniziato.', 'Round $_round started.'),
        ('Terminare la battaglia?', 'End the battle?'),
        ('Round, iniziativa, PP, PF temporanei, forme di battaglia e status volatili verranno rimossi. HP, status persistenti e oggetti consumati resteranno salvati.', 'Rounds, initiative, PP, temporary HP, battle forms and volatile conditions will be cleared. HP, persistent conditions and consumed items will remain saved.'),
        ('Lancia la Poké Ball. Dopo la risposta del Master verrà consumata.', 'Throw the Poké Ball. It will be consumed after the GM reports the result.'),
        ('Esempi: -12, +8 oppure 35. Attuali ${widget.currentHp}/${widget.maxHp}', 'Examples: -12, +8 or 35. Current ${widget.currentHp}/${widget.maxHp}'),
    ],
)

localize_literals(
    'lib/screens/trainer/trainer_sheet_screen.dart',
    [
        ('ALLENATORE', 'TRAINER'),
        ('CARATTERISTICHE', 'ABILITY SCORES'),
        ('AVANZAMENTO', 'PROGRESSION'),
        ('Scegli', 'Choose'),
        ('Tocca per scegliere dal manuale', 'Tap to choose from the manual'),
        ('Tocca per scegliere tra i percorsi disponibili.', 'Tap to choose from the available paths.'),
        ('LIVELLO $trainerLevel', 'LEVEL $trainerLevel'),
        ('Nuovo Pokéslot al livello $nextPokeslotLevel.', 'New Poké Slot at level $nextPokeslotLevel.'),
        ('Nuovo limite SR al livello $nextControlLevel.', 'New SR limit at level $nextControlLevel.'),
        ('Pokéslot: massimo già raggiunto.', 'Poké Slots: maximum already reached.'),
        ('SR: massimo già raggiunto.', 'SR: maximum already reached.'),
        ('Salvataggio...', 'Saving...'),
        ('Scegli starter', 'Choose starter'),
        ('Errore: $message', 'Error: $message'),
        ('${starter.name} aggiunto alla squadra.', '${starter.name} added to the team.'),
        ('Diminuisci $label', 'Decrease $label'),
        ('Aumenta $label', 'Increase $label'),
    ],
)

# The existing localization regression test assumed an Italian-only UI. Keep
# the Italian assertions and add explicit English coverage instead of checking
# for hardcoded Italian-only source fragments.
Path('test/trainer_ui_localization_test.dart').write_text(
    """import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/localization/game_catalog_locale.dart';
import 'package:pokedex_5e_ita/models/trainer_ui_localization.dart';

void main() {
  setUp(() {
    GameCatalogLocale.setLanguageCode('it');
  });

  tearDown(() {
    GameCatalogLocale.setLanguageCode('it');
  });

  test('caratteristiche e abilità vengono mostrate in italiano', () {
    expect(TrainerUiLocalization.abilityAbbreviation('STR'), 'FOR');
    expect(TrainerUiLocalization.abilityAbbreviation('DEX'), 'DES');
    expect(TrainerUiLocalization.abilityAbbreviation('CON'), 'COS');
    expect(TrainerUiLocalization.abilityAbbreviation('WIS'), 'SAG');
    expect(TrainerUiLocalization.abilityAbbreviation('CHA'), 'CAR');
    expect(
      TrainerUiLocalization.skillName('Animal Handling'),
      'Addestrare Animali',
    );
    expect(
      TrainerUiLocalization.skillName('Sleight of Hand'),
      'Rapidità di Mano',
    );
  });

  test('etichette tecniche rimangono inglesi con interfaccia inglese', () {
    GameCatalogLocale.setLanguageCode('en');

    expect(TrainerUiLocalization.abilityAbbreviation('STR'), 'STR');
    expect(TrainerUiLocalization.abilityAbbreviation('DEX'), 'DEX');
    expect(
      TrainerUiLocalization.skillName('Animal Handling'),
      'Animal Handling',
    );
    expect(TrainerUiLocalization.trainerPathName('Ace Trainer'), 'Ace Trainer');
    expect(TrainerUiLocalization.natureName('Adamant'), 'Adamant');
    expect(TrainerUiLocalization.sizeName('Medium'), 'Medium');
    expect(TrainerUiLocalization.genderName('Female'), 'Female');
  });

  test('nomi tecnici mantengono etichette italiane separate', () {
    expect(
      TrainerUiLocalization.trainerPathName('Ace Trainer'),
      'Fantallenatore',
    );
    expect(TrainerUiLocalization.trainerPathName('Grunt'), 'Recluta');
    expect(
      TrainerUiLocalization.specializationName('Bird Keeper'),
      'Avicoltore',
    );
    expect(TrainerUiLocalization.featureName('Rapid Switching'), 'Cambio Rapido');
    expect(TrainerUiLocalization.natureName('Adamant'), 'Decisa');
    expect(TrainerUiLocalization.sizeName('Medium'), 'Media');
    expect(TrainerUiLocalization.genderName('Female'), 'Femmina');
  });

  test('le schermate migrate contengono entrambe le lingue', () {
    final pokemonDetail = File(
      'lib/screens/pokemon/pokemon_detail_screen_legacy.dart',
    ).readAsStringSync();
    final trainerSheet = File(
      'lib/screens/trainer/trainer_sheet_screen.dart',
    ).readAsStringSync();

    expect(pokemonDetail, contains("Tab(text: 'PRIVILEGI')"));
    expect(pokemonDetail, contains("Tab(text: 'TRATTI')"));
    expect(trainerSheet, contains("context.uiText('ALLENATORE', 'TRAINER')"));
    expect(trainerSheet, contains("context.uiText('ABILITÀ', 'SKILLS')"));
    expect(
      trainerSheet,
      contains("context.uiText('TIRI SALVEZZA', 'SAVING THROWS')"),
    );
    expect(trainerSheet, contains("context.uiText('AVANZAMENTO', 'PROGRESSION')"));
  });
}
""",
    encoding='utf-8',
)

print('Core UI finalization applied.')
