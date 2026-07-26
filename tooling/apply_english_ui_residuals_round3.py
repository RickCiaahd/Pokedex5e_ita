from __future__ import annotations

import re
from pathlib import Path

BRANCH_MARKER = Path('tooling/.english_ui_round3_applied')


def dart_literal(value: str) -> str:
    return "'" + value.replace('\\', '\\\\').replace("'", "\\'") + "'"


def replace_required(text: str, old: str, new: str, *, path: Path) -> str:
    if old not in text:
        raise RuntimeError(f'Missing fragment in {path}: {old[:120]!r}')
    return text.replace(old, new)


def localize_literals(path: Path, translations: dict[str, str]) -> None:
    text = path.read_text(encoding='utf-8')
    for italian, english in translations.items():
        old = dart_literal(italian)
        new = f'uiTextForLanguage({old}, {dart_literal(english)})'
        if old not in text:
            continue
        text = text.replace(old, new)
    path.write_text(text, encoding='utf-8')


def ensure_import(path: Path, import_line: str, after: str) -> None:
    text = path.read_text(encoding='utf-8')
    if import_line in text:
        return
    if after not in text:
        raise RuntimeError(f'Import anchor not found in {path}: {after}')
    text = text.replace(after, after + '\n' + import_line, 1)
    path.write_text(text, encoding='utf-8')


def repair_const_widgets(path: Path) -> None:
    text = path.read_text(encoding='utf-8')
    widget_names = (
        'Text', 'InputDecoration', 'DropdownMenuItem', 'Chip', 'Card', 'Padding',
        'Center', 'AlertDialog', 'ListTile', 'SwitchListTile', 'ChoiceChip',
        'FilledButton', 'OutlinedButton', 'TextButton', 'Tooltip',
    )
    text = re.sub(r'\bconst (?=(' + '|'.join(widget_names) + r')\b)', '', text)
    text = text.replace('actions: const [', 'actions: [')
    text = text.replace('items: const [', 'items: [')
    path.write_text(text, encoding='utf-8')


def main() -> None:
    if BRANCH_MARKER.exists():
        print('Round 3 localization already applied.')
        return

    breeding_screen = Path('lib/screens/breeding/breeding_screen.dart')
    breeding_dialogs = Path('lib/widgets/breeding/breeder_trait_dialogs.dart')
    breeding_candidate = Path('lib/models/breeding_candidate.dart')
    breeding_egg = Path('lib/models/breeding_egg.dart')
    encounter_screen = Path('lib/screens/tools/encounter_generator_screen.dart')
    habitat_service = Path('lib/services/pokemon_habitat_service.dart')
    battle_screen = Path('lib/screens/battle/battle_screen.dart')
    egg_image = Path('lib/widgets/pokemon/egg_asset_image.dart')
    home_button = Path('lib/widgets/navigation/home_leading_button.dart')

    ensure_import(
        breeding_screen,
        "import '../../localization/ui_text.dart';",
        "import 'package:flutter/material.dart';",
    )
    ensure_import(
        breeding_dialogs,
        "import '../../localization/ui_text.dart';",
        "import 'package:flutter/material.dart';",
    )
    ensure_import(
        breeding_candidate,
        "import '../localization/ui_text.dart';",
        '',
    )
    ensure_import(
        breeding_egg,
        "import '../localization/ui_text.dart';",
        '',
    )
    ensure_import(
        egg_image,
        "import '../../localization/ui_text.dart';",
        "import 'package:flutter/material.dart';",
    )

    localize_literals(
        breeding_screen,
        {
            'Squadra ${slot.slotIndex + 1}': 'Team ${slot.slotIndex + 1}',
            'Non hai un Pokéslot libero. Libera uno slot oppure usa la Pensione Pokémon.': 'You do not have a free Poké Slot. Free a slot or use the Pokémon Day Care.',
            'Il risultato del d20 deve essere tra 1 e 20.': 'The d20 result must be between 1 and 20.',
            'Tentativo fallito: d20 $roll ${_signed(modifier)} = $total contro CD $dc.': 'Attempt failed: d20 $roll ${_signed(modifier)} = $total against DC $dc.',
            'affidato alla Pensione Pokémon': 'placed in the Pokémon Day Care',
            'inserito nello slot squadra ${freeSlot!.slotIndex + 1}': 'placed in team slot ${freeSlot!.slotIndex + 1}',
            'Successo: d20 $roll ${_signed(modifier)} = $total contro CD $dc. Uovo creato e $destination.': 'Success: d20 $roll ${_signed(modifier)} = $total against DC $dc. Egg created and $destination.',
            'Uovo affidato alla Pensione Pokémon.': 'Egg placed in the Pokémon Day Care.',
            'Uovo depositato nel PC. L’incubazione resta in pausa.': 'Egg deposited in the PC. Incubation is paused.',
            'Non hai un Pokéslot libero per ritirare l’uovo.': 'You do not have a free Poké Slot for the egg.',
            'Uovo ritirato nello slot squadra ${freeSlot.slotIndex + 1}.': 'Egg moved to team slot ${freeSlot.slotIndex + 1}.',
            'Nel PC l’incubazione è in pausa. Ritira l’uovo in squadra oppure affidalo alla Pensione.': 'Incubation is paused in the PC. Move the egg to the team or to the Day Care.',
            ' + incubatore ${result.incubatorRolls.join(' + ')}': ' + incubator ${result.incubatorRolls.join(' + ')}',
            'Incubazione: d100 $baseRoll$incubator. Contatore ridotto di ${result.reduction}.': 'Incubation: d100 $baseRoll$incubator. Counter reduced by ${result.reduction}.',
            'L’incubatore è già stato usato per questo uovo e non può essere trasferito.': 'The incubator has already been used for this egg and cannot be transferred.',
            'Non possiedi un Incubatore ${incubator.label} nello zaino.': 'You do not have a ${incubator.label} Incubator in the Bag.',
            'Incubatore ${incubator.label} applicato e consumato: aggiunge ${incubator.extraD20}d20 a ogni avanzamento.': '${incubator.label} Incubator applied and consumed: it adds ${incubator.extraD20}d20 to each incubation advance.',
            'Distruggere l’uovo?': 'Destroy the egg?',
            'Secondo il manuale un uovo è distrutto quando raggiunge 0 PF. Questa operazione non può essere annullata.': 'According to the manual, an egg is destroyed when it reaches 0 HP. This cannot be undone.',
            'ANNULLA': 'CANCEL',
            'PORTA A 0 PF': 'SET TO 0 HP',
            'L’uovo ha raggiunto 0 PF ed è stato distrutto.': 'The egg reached 0 HP and was destroyed.',
            'PF dell’uovo aggiornati a $nextHp/10.': 'Egg HP updated to $nextHp/10.',
            'Eliminare l’uovo?': 'Delete the egg?',
            'Il progresso di incubazione e i dati del Pokémon contenuto andranno persi.': 'Incubation progress and the contained Pokémon data will be lost.',
            'ELIMINA': 'DELETE',
            'Uovo eliminato.': 'Egg deleted.',
            'Un uovo depositato nel PC non può schiudersi. Ritiralo in squadra oppure spostalo in Pensione.': 'An egg stored in the PC cannot hatch. Move it to the team or to the Day Care.',
            'La specie dell’uovo non è nel catalogo.': 'The egg species is not in the catalog.',
            'Nato da un uovo nella Pensione Pokémon.': 'Hatched from an egg in the Pokémon Day Care.',
            'Mosse ereditate: ${hatchEgg.inheritedMoves.join(', ')}.': 'Inherited moves: ${hatchEgg.inheritedMoves.join(', ')}.',
            'è stato inviato al PC dalla Pensione Pokémon': 'was sent to the PC from the Pokémon Day Care',
            'ha sostituito l’uovo nello slot squadra ${eggSlot.slotIndex + 1}': 'replaced the egg in team slot ${eggSlot.slotIndex + 1}',
            ' Good Genes ha assegnato il talento ${hatchEgg.goodGenesFeat}.': ' Good Genes granted the ${hatchEgg.goodGenesFeat} feat.',
            ' Good Genes ha applicato ${hatchEgg.goodGenesAbilityBonuses.entries.map((entry) => '${entry.key} +${entry.value}').join(', ')}.': ' Good Genes applied ${hatchEgg.goodGenesAbilityBonuses.entries.map((entry) => '${entry.key} +${entry.value}').join(', ')}.',
            '${_displayName(pokemon: pokemon, formName: hatchEgg.formName)} si è schiuso, $destination, con Lealtà +$loyalty.$goodGenes': '${_displayName(pokemon: pokemon, formName: hatchEgg.formName)} hatched, $destination, with Loyalty +$loyalty.$goodGenes',
            'Allevamento e uova': 'Breeding and Eggs',
            'Errore: ${snapshot.error}': 'Error: ${snapshot.error}',
            'NUOVO TENTATIVO': 'NEW ATTEMPT',
            'Seleziona due Pokémon posseduti. L’app controlla Lealtà, sesso, Ditto e Gruppi Uova.': 'Select two owned Pokémon. The app checks Loyalty, gender, Ditto and Egg Groups.',
            'Primo genitore': 'First parent',
            'Secondo genitore': 'Second parent',
            'Usa Pensione Pokémon': 'Use Pokémon Day Care',
            'L’uovo non occupa un Pokéslot e alla schiusa il Pokémon andrà nel PC.': 'The egg does not occupy a Poké Slot and the Pokémon will go to the PC when it hatches.',
            'Nessun Pokéslot libero: attiva la Pensione per poter ottenere l’uovo.': 'No free Poké Slot: enable the Day Care to receive the egg.',
            'L’uovo occuperà lo slot squadra ${freeSlot.slotIndex + 1}.': 'The egg will occupy team slot ${freeSlot.slotIndex + 1}.',
            'TIRA IL D20': 'ROLL D20',
            'Risultato d20': 'd20 result',
            'Inserisci il risultato del d20.': 'Enter the d20 result.',
            'USA IL TIRO': 'USE ROLL',
            'UOVA IN INCUBAZIONE (${data.eggs.length})': 'INCUBATING EGGS (${data.eggs.length})',
            'Un uovo trasportato occupa davvero un Pokéslot. Un uovo affidato alla Pensione resta fuori dalla squadra e alla schiusa il Pokémon viene inviato al PC.': 'A carried egg occupies a Poké Slot. An egg placed in the Day Care stays outside the team and the Pokémon is sent to the PC when it hatches.',
            'Non ci sono uova. Completa con successo un tentativo di allevamento.': 'There are no eggs. Complete a breeding attempt successfully.',
            'ALLEVAMENTO POKÉMON': 'POKÉMON BREEDING',
            'Servono Lealtà +2, sesso compatibile e un Gruppo Uova condiviso. Ditto ignora sesso e Gruppo Uova; Undiscovered non può riprodursi.': 'Requires Loyalty +2, compatible genders and a shared Egg Group. Ditto ignores gender and Egg Groups; Undiscovered Pokémon cannot breed.',
            'Pokémon Breeder: tiro di accoppiamento ${rollModifier >= 0 ? '+' : ''}$rollModifier': 'Pokémon Breeder: breeding check ${rollModifier >= 0 ? '+' : ''}$rollModifier',
            'vantaggio ai d100 di incubazione': 'advantage on incubation d100 rolls',
            'Good Genes alla schiusa': 'Good Genes when hatching',
            'Master of Traits sulle uova future': 'Master of Traits on future eggs',
            '${candidate.displayName} · ${candidate.genderLabel} · Lealtà ${candidate.loyalty >= 0 ? '+' : ''}${candidate.loyalty} · ${candidate.location}': '${candidate.displayName} · ${candidate.genderLabel} · Loyalty ${candidate.loyalty >= 0 ? '+' : ''}${candidate.loyalty} · ${candidate.location}',
            'COMPATIBILI': 'COMPATIBLE',
            'NON COMPATIBILI': 'NOT COMPATIBLE',
            'Gruppo: ${compatibility.sharedEggGroups.join(', ')} · Risultato: ${resultPokemon?.name ?? '#${compatibility.childSpeciesId}'}': 'Group: ${compatibility.sharedEggGroups.join(', ')} · Result: ${resultPokemon?.name ?? '#${compatibility.childSpeciesId}'}',
            'Prova: d20 ${modifier >= 0 ? '+' : ''}$modifier contro CD $dc.': 'Check: d20 ${modifier >= 0 ? '+' : ''}$modifier against DC $dc.',
            'Uovo pronto a schiudersi': 'Egg ready to hatch',
            'Uovo di ${pokemon?.name ?? '#${egg.speciesId}'}': '${pokemon?.name ?? '#${egg.speciesId}'} Egg',
            'Genitori: ${egg.parentNames.join(' + ')}': 'Parents: ${egg.parentNames.join(' + ')}',
            'Incubazione completata': 'Incubation complete',
            '${egg.incubationRemaining}/${egg.hatchTime} punti rimanenti': '${egg.incubationRemaining}/${egg.hatchTime} points remaining',
            'Elimina uovo': 'Delete egg',
            'CA ${BreedingEgg.armorClass}': 'AC ${BreedingEgg.armorClass}',
            'PF ${egg.currentHp}/${BreedingEgg.maxHitPoints}': 'HP ${egg.currentHp}/${BreedingEgg.maxHitPoints}',
            'Mosse ereditate: ${egg.inheritedMoves.join(', ')}': 'Inherited moves: ${egg.inheritedMoves.join(', ')}',
            'Incubatore': 'Incubator',
            'Viene consumato quando lo assegni all’uovo.': 'It is consumed when assigned to the egg.',
            'Già consumato per questo uovo; non è trasferibile.': 'Already consumed for this egg; it cannot be transferred.',
            'MODIFICA PF UOVO': 'EDIT EGG HP',
            'Pensione Pokémon': 'Pokémon Day Care',
            'Squadra · Slot ${teamSlotIndex! + 1}': 'Team · Slot ${teamSlotIndex! + 1}',
            'L’incubazione è in pausa e l’uovo non occupa un Pokéslot.': 'Incubation is paused and the egg does not occupy a Poké Slot.',
            'Occupa un Pokéslot e nascerà con Lealtà +2.': 'Occupies a Poké Slot and will hatch with Loyalty +2.',
            'Non ha trascorso tutta l’incubazione in squadra: Lealtà +1.': 'It did not spend the entire incubation in the team: Loyalty +1.',
            'RITIRA IN SQUADRA': 'MOVE TO TEAM',
            'NESSUN POKÉSLOT LIBERO': 'NO FREE POKÉ SLOT',
            'DEPOSITA NEL PC': 'DEPOSIT IN PC',
            'SPOSTA IN PENSIONE': 'MOVE TO DAY CARE',
            'RITIRA L’UOVO PER SCHIUDERLO': 'MOVE THE EGG TO HATCH IT',
            'INCUBAZIONE IN PAUSA NEL PC': 'INCUBATION PAUSED IN PC',
            'FAI SCHIUDERE': 'HATCH EGG',
            'AVANZA INCUBAZIONE (2d100, migliore)': 'ADVANCE INCUBATION (2d100, best)',
            'AVANZA INCUBAZIONE (1d100)': 'ADVANCE INCUBATION (1d100)',
            'Nel PC l’uovo resta conservato ma non può schiudersi.': 'The egg is safely stored in the PC but cannot hatch there.',
            'Alla schiusa il Pokémon verrà inviato al PC dalla Pensione.': 'When it hatches, the Pokémon will be sent to the PC from the Day Care.',
            'Alla schiusa il Pokémon sostituirà l’uovo nello stesso Pokéslot.': 'When it hatches, the Pokémon will replace the egg in the same Poké Slot.',
        },
    )

    localize_literals(
        breeding_dialogs,
        {
            'Per ${widget.pokemon.name} puoi ignorare i tiri e scegliere sesso, natura e abilità tra le opzioni disponibili. Lascia Casuale per usare le normali regole di schiusa.': 'For ${widget.pokemon.name}, you may ignore the rolls and choose gender, nature and ability from the available options. Leave Random to use the normal hatching rules.',
            'Sesso': 'Gender',
            'Natura': 'Nature',
            'Abilità non nascosta': 'Non-hidden ability',
            'Egg Moves sostitutive (${_replacementMoves.length}/${widget.replaceableEggMoveCount})': 'Replacement Egg Moves (${_replacementMoves.length}/${widget.replaceableEggMoveCount})',
            'Puoi sostituire fino allo stesso numero di Egg Moves ereditate. Le selezioni non usate mantengono le mosse ereditate originali.': 'You may replace up to the same number of inherited Egg Moves. Unused selections keep the original inherited moves.',
            'ANNULLA': 'CANCEL',
            'CONFERMA': 'CONFIRM',
            'Casuale secondo il manuale': 'Random according to the manual',
            '${widget.pokemonName} sta per schiudersi. Il privilegio assegna 2 punti alle caratteristiche oppure un talento.': '${widget.pokemonName} is about to hatch. This feature grants 2 ability points or one feat.',
            '2 punti caratteristica': '2 ability points',
            'Un talento': 'One feat',
            'Punti spesi: $_spent/2': 'Points spent: $_spent/2',
            'Talento': 'Feat',
            'Terreno di Terrain Adept': 'Terrain for Terrain Adept',
            'APPLICA E SCHIUDI': 'APPLY AND HATCH',
            'PF dell’uovo': 'Egg HP',
            'Nuovi PF oppure modifica (+/-)': 'New HP or adjustment (+/-)',
            'Il manuale assegna CA 8 e $maxHp PF. A 0 PF l’uovo è distrutto.': 'The manual gives the egg AC 8 and $maxHp HP. At 0 HP the egg is destroyed.',
            'APPLICA': 'APPLY',
        },
    )

    localize_literals(
        breeding_candidate,
        {
            'Maschio': 'Male',
            'Femmina': 'Female',
            'Senza sesso': 'Genderless',
            'Sesso non impostato': 'Gender not set',
        },
    )
    localize_literals(breeding_egg, {'Nessuno': 'None'})
    localize_literals(egg_image, {'Uovo Pokémon': 'Pokémon Egg'})

    text = habitat_service.read_text(encoding='utf-8')
    anchor = "  static const List<String> habitats = [\n"
    if 'static String englishLabel' not in text:
        labels = """  static const Map<String, String> _englishLabels = {
    'Qualsiasi': 'Any',
    'Prateria': 'Grassland',
    'Foresta': 'Forest',
    'Grotta': 'Cave',
    'Montagna': 'Mountain',
    'Deserto': 'Desert',
    'Palude': 'Swamp',
    'Costa e fiumi': 'Coasts and rivers',
    'Mare': 'Sea',
    'Città': 'City',
    'Neve e ghiaccio': 'Snow and ice',
  };

  static String englishLabel(String habitat) =>
      _englishLabels[habitat] ?? habitat;

"""
        text = replace_required(text, anchor, labels + anchor, path=habitat_service)
    habitat_service.write_text(text, encoding='utf-8')

    text = encounter_screen.read_text(encoding='utf-8')
    text = replace_required(
        text,
        'DropdownMenuItem(value: habitat, child: Text(habitat))',
        "DropdownMenuItem(\n                  value: habitat,\n                  child: Text(\n                    context.usesItalianUi\n                        ? habitat\n                        : PokemonHabitatService.englishLabel(habitat),\n                  ),\n                )",
        path=encounter_screen,
    )
    encounter_screen.write_text(text, encoding='utf-8')

    text = battle_screen.read_text(encoding='utf-8')
    text = replace_required(
        text,
        "actionLabel: 'Ricarica',",
        "actionLabel: context.uiText('Ricarica', 'Reload'),",
        path=battle_screen,
    )
    text = replace_required(
        text,
        "'${profile.name} · INIZ. ${trainerInitiativeBonus >= 0 ? '+' : ''}$trainerInitiativeBonus',",
        "context.uiText(\n                      '${profile.name} · INIZ. ${trainerInitiativeBonus >= 0 ? '+' : ''}$trainerInitiativeBonus',\n                      '${profile.name} · INIT. ${trainerInitiativeBonus >= 0 ? '+' : ''}$trainerInitiativeBonus',\n                    ),",
        path=battle_screen,
    )
    text = replace_required(
        text,
        "return 'Bacca';",
        "return uiTextForLanguage('Bacca', 'Berry');",
        path=battle_screen,
    )
    text = replace_required(
        text,
        "return 'Medicina';",
        "return uiTextForLanguage('Medicina', 'Medicine');",
        path=battle_screen,
    )
    text = replace_required(
        text,
        "return 'MT';",
        "return uiTextForLanguage('MT', 'TM');",
        path=battle_screen,
    )
    text = replace_required(
        text,
        "return BattleQuickItemService.isPokeball(item) ? 'LANCIA' : 'USA';",
        "return BattleQuickItemService.isPokeball(item)\n      ? uiTextForLanguage('LANCIA', 'THROW')\n      : uiTextForLanguage('USA', 'USE');",
        path=battle_screen,
    )
    text = replace_required(
        text,
        "label: Text(formLabel ?? 'Forma'),",
        "label: Text(formLabel ?? context.uiText('Forma', 'Form')),
",
        path=battle_screen,
    )
    battle_screen.write_text(text, encoding='utf-8')

    if home_button.exists():
        text = home_button.read_text(encoding='utf-8')
        if "tooltip: 'Indietro'" in text:
            ensure_import(
                home_button,
                "import '../../localization/ui_text.dart';",
                "import 'package:flutter/material.dart';",
            )
            text = home_button.read_text(encoding='utf-8')
            text = text.replace("tooltip: 'Indietro'", "tooltip: context.uiText('Indietro', 'Back')")
            home_button.write_text(text, encoding='utf-8')

    repair_const_widgets(breeding_screen)
    repair_const_widgets(breeding_dialogs)
    repair_const_widgets(breeding_candidate)
    repair_const_widgets(breeding_egg)
    repair_const_widgets(egg_image)

    BRANCH_MARKER.write_text('applied\n', encoding='utf-8')
    print('Applied English UI residual fixes round 3.')


if __name__ == '__main__':
    main()
