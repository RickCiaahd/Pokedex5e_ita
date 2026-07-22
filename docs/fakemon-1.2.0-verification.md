# Verifica Fakemon 1.2.0

- flutter analyze: 0
- fakemon_advanced_test: 0
- evolution_repository_regression_test: 0
- item_localization_integrity_test: 0
- suite completa: 0
- build APK debug: 0

## Analisi
```text
Resolving dependencies...
Downloading packages...
  file_picker 10.3.10 (11.0.2 available)
  hooks 2.0.2 (2.1.0 available)
  matcher 0.12.19 (0.12.20 available)
  meta 1.18.0 (1.19.0 available)
  package_config 2.2.0 (3.0.0 available)
  record_use 0.6.0 (1.0.0 available)
  share_plus 12.0.2 (13.2.1 available)
  share_plus_platform_interface 6.1.0 (7.1.0 available)
  test_api 0.7.11 (0.7.13 available)
  uuid 4.5.3 (4.6.0 available)
  vector_math 2.2.0 (2.4.0 available)
  win32 5.15.0 (6.3.0 available)
  xml 6.6.1 (7.0.1 available)
Got dependencies!
13 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
Analyzing Pokedex5e_ita...                                      
No issues found! (ran in 14.1s)
```

## Test Fakemon
```text
Resolving dependencies...
Downloading packages...
  file_picker 10.3.10 (11.0.2 available)
  hooks 2.0.2 (2.1.0 available)
  matcher 0.12.19 (0.12.20 available)
  meta 1.18.0 (1.19.0 available)
  package_config 2.2.0 (3.0.0 available)
  record_use 0.6.0 (1.0.0 available)
  share_plus 12.0.2 (13.2.1 available)
  share_plus_platform_interface 6.1.0 (7.1.0 available)
  test_api 0.7.11 (0.7.13 available)
  uuid 4.5.3 (4.6.0 available)
  vector_math 2.2.0 (2.4.0 available)
  win32 5.15.0 (6.3.0 available)
  xml 6.6.1 (7.0.1 available)
Got dependencies!
13 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
00:00 +0: loading /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/fakemon_advanced_test.dart
00:00 +0: una forma personalizzata sovrascrive statistiche e tipi
00:00 +1: un Fakemon può essere collegato come forma di una specie
00:00 +2: Eevee riceve una nuova evoluzione Fakemon
00:00 +3: il pacchetto segreto conserva checksum e flag sealed
00:00 +4: All tests passed!
```

## Test evoluzioni
```text
Resolving dependencies...
Downloading packages...
  file_picker 10.3.10 (11.0.2 available)
  hooks 2.0.2 (2.1.0 available)
  matcher 0.12.19 (0.12.20 available)
  meta 1.18.0 (1.19.0 available)
  package_config 2.2.0 (3.0.0 available)
  record_use 0.6.0 (1.0.0 available)
  share_plus 12.0.2 (13.2.1 available)
  share_plus_platform_interface 6.1.0 (7.1.0 available)
  test_api 0.7.11 (0.7.13 available)
  uuid 4.5.3 (4.6.0 available)
  vector_math 2.2.0 (2.4.0 available)
  win32 5.15.0 (6.3.0 available)
  xml 6.6.1 (7.0.1 available)
Got dependencies!
13 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
00:00 +0: loading /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/evolution_repository_regression_test.dart
00:00 +0: Eevee espone soltanto le evoluzioni canoniche
00:00 +1: le evoluzioni canoniche non sono duplicate dagli alias
00:00 +2: le evoluzioni regionali di Hisui usano nomi risolvibili
00:00 +3: All tests passed!
```

## Test localizzazione
```text
Resolving dependencies...
Downloading packages...
  file_picker 10.3.10 (11.0.2 available)
  hooks 2.0.2 (2.1.0 available)
  matcher 0.12.19 (0.12.20 available)
  meta 1.18.0 (1.19.0 available)
  package_config 2.2.0 (3.0.0 available)
  record_use 0.6.0 (1.0.0 available)
  share_plus 12.0.2 (13.2.1 available)
  share_plus_platform_interface 6.1.0 (7.1.0 available)
  test_api 0.7.11 (0.7.13 available)
  uuid 4.5.3 (4.6.0 available)
  vector_math 2.2.0 (2.4.0 available)
  win32 5.15.0 (6.3.0 available)
  xml 6.6.1 (7.0.1 available)
Got dependencies!
13 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
00:00 +0: loading /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/item_localization_integrity_test.dart
00:00 +0: i cataloghi italiani coprono tutti i sei blocchi completati
00:00 +1: i 39 oggetti evolutivi usano i nomi verificati
00:00 +2: i 163 strumenti da tenere usano i nomi verificati
00:00 +3: i 49 strumenti dell’Allenatore usano i nomi verificati
00:00 +4: il repository localizza la UI e conserva i dati tecnici
00:00 +5: All tests passed!
```

## Suite completa
```text
00:11 +63: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/pokemon_summary_dialog_layout_test.dart: Pokédex summary dialog lays out the horizontal form selector
00:11 +64: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/pokemon_summary_dialog_layout_test.dart: Pokédex summary dialog lays out the horizontal form selector
00:11 +65: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/pokemon_summary_dialog_layout_test.dart: Pokédex summary dialog lays out the horizontal form selector
00:12 +66: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/trainer_path_passive_service_test.dart: TrainerPathPassiveService Ace Trainer applica attacco, danno e Max Potential
00:12 +67: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/trainer_path_passive_service_test.dart: TrainerPathPassiveService Max Potential velocità non crea movimento da una velocità zero
00:12 +68: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/trainer_path_passive_service_test.dart: TrainerPathPassiveService Type Master usa al massimo due specializzazioni compatibili
00:12 +69: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/trainer_path_passive_service_test.dart: TrainerPathPassiveService Commander raddoppia soltanto i bonus positivi di Lealtà
00:12 +70: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/trainer_path_passive_service_test.dart: TrainerPathPassiveService Guru aggiunge competenza ai TS di Saggezza
00:12 +71: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/trainer_path_passive_service_test.dart: TrainerPathPassiveService Many Faces applica i privilegi passivi copiati supportati
00:12 +72: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/data_integrity_test.dart: (setUpAll)
00:12 +73: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/data_integrity_test.dart: (setUpAll)
00:12 +74: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/data_integrity_test.dart: (setUpAll)
00:12 +75: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/data_integrity_test.dart: (setUpAll)
00:13 +75: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/pokemon_asset_paths_test.dart: Abomasnow shiny artwork is included in the Flutter asset bundle
00:13 +76: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/pokemon_asset_paths_test.dart: Abomasnow shiny artwork is included in the Flutter asset bundle
00:13 +77: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/data_integrity_test.dart: File sorgente i cataloghi web hanno identificatori univoci e campi minimi
00:13 +78: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/data_integrity_test.dart: File sorgente i cataloghi web hanno identificatori univoci e campi minimi
00:13 +79: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/pokemon_asset_paths_test.dart: Dusk Mane Necrozma shiny artwork uses the form-first folder
00:13 +80: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/pokemon_asset_paths_test.dart: Dusk Mane Necrozma shiny artwork uses the form-first folder
00:13 +81: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/data_integrity_test.dart: Catalogo unificato statistiche, mosse e forme rispettano i vincoli minimi
00:13 +82: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/data_integrity_test.dart: Catalogo unificato statistiche, mosse e forme rispettano i vincoli minimi
00:13 +83: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/data_integrity_test.dart: Catalogo unificato ogni specie ha almeno un immagine inclusa nel bundle
00:13 +84: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/data_integrity_test.dart: Catalogo unificato i cataloghi di mosse e abilita sono caricabili
00:13 +85: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/data_integrity_test.dart: (tearDownAll)
00:13 +85: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/item_localization_integrity_test.dart: i cataloghi italiani coprono tutti i sei blocchi completati
00:13 +86: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/item_localization_integrity_test.dart: i 39 oggetti evolutivi usano i nomi verificati
00:13 +87: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/item_localization_integrity_test.dart: i 163 strumenti da tenere usano i nomi verificati
00:13 +88: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/item_localization_integrity_test.dart: i 49 strumenti dell’Allenatore usano i nomi verificati
00:13 +89: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/item_localization_integrity_test.dart: il repository localizza la UI e conserva i dati tecnici
00:14 +90: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/item_localization_integrity_test.dart: il repository localizza la UI e conserva i dati tecnici
00:14 +91: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/item_localization_integrity_test.dart: il repository localizza la UI e conserva i dati tecnici
00:14 +92: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/item_localization_integrity_test.dart: il repository localizza la UI e conserva i dati tecnici
00:14 +93: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/item_localization_integrity_test.dart: il repository localizza la UI e conserva i dati tecnici
00:14 +94: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/item_localization_integrity_test.dart: il repository localizza la UI e conserva i dati tecnici
00:14 +95: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/item_localization_integrity_test.dart: il repository localizza la UI e conserva i dati tecnici
00:14 +96: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/item_localization_integrity_test.dart: il repository localizza la UI e conserva i dati tecnici
00:14 +97: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/item_localization_integrity_test.dart: il repository localizza la UI e conserva i dati tecnici
00:14 +98: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/item_localization_integrity_test.dart: il repository localizza la UI e conserva i dati tecnici
00:14 +99: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/team_slot_egg_test.dart: TeamSlot conserva un uovo e lo considera uno slot occupato
00:14 +100: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/team_slot_egg_test.dart: inserire un Pokémon rimuove l’uovo dallo slot
00:14 +101: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/portable_fakemon_transfer_test.dart: il trasferimento di un Pokémon incorpora la specie Fakemon
00:14 +102: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/portable_fakemon_transfer_test.dart: un incontro incorpora una sola volta ogni Fakemon usato
00:14 +103: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/portable_fakemon_transfer_test.dart: un conflitto numerico rimappa la specie importata
00:14 +104: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/portable_fakemon_transfer_test.dart: i trasferimenti versione 1 restano importabili
00:15 +105: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/battle_round_controls_test.dart: ogni fight espone un solo controllo Prossimo turno
00:15 +106: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/full_move_catalog_test.dart: il catalogo completo delle mosse contiene Surf
00:15 +107: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/full_move_catalog_test.dart: l editor separa learnset e scelta manuale globale
00:15 +108: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/move_localization_integrity_test.dart: i cataloghi italiani coprono tutte le 830 mosse in ordine
00:16 +109: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/move_localization_integrity_test.dart: tutte le 830 mosse usano i nomi italiani verificati
00:16 +110: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/move_localization_integrity_test.dart: il repository mostra l’italiano e conserva i riferimenti inglesi
00:16 +111: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/move_localization_integrity_test.dart: il repository mostra l’italiano e conserva i riferimenti inglesi
00:16 +112: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/move_localization_integrity_test.dart: il repository mostra l’italiano e conserva i riferimenti inglesi
00:16 +113: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/move_localization_integrity_test.dart: il repository mostra l’italiano e conserva i riferimenti inglesi
00:16 +114: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/move_localization_integrity_test.dart: il repository mostra l’italiano e conserva i riferimenti inglesi
00:16 +115: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/encounter_generator_service_test.dart: a 100 percent collection always selects its only species
00:16 +116: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/encounter_generator_service_test.dart: weighted collections preserve an explicitly selected form
00:16 +117: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/encounter_generator_service_test.dart: collection generation without duplicates returns unique species
00:16 +118: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/profile_backup_test.dart: round-trips every profile section through JSON
00:16 +119: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/layout_final_block_integration_test.dart: l’ultimo blocco layout copre combattimenti e strumenti del Master
00:16 +120: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/layout_final_block_integration_test.dart: l’ultimo blocco layout copre combattimenti e strumenti del Master
00:16 +121: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/layout_final_block_integration_test.dart: l’ultimo blocco layout copre combattimenti e strumenti del Master
00:17 +122: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/native_share_service_test.dart: restituisce il messaggio di successo personalizzato
00:17 +123: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/native_share_service_test.dart: distingue annullamento ed esito non comunicato
00:17 +124: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/ability_localization_integrity_test.dart: le traduzioni coprono una sola volta tutte le abilità sorgente
00:17 +125: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/ability_localization_integrity_test.dart: numeri, dadi e percentuali restano invariati
00:17 +126: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/ability_localization_integrity_test.dart: il repository applica 330 descrizioni senza cambiare i metadati
00:18 +127: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/evolution_repository_regression_test.dart: Eevee espone soltanto le evoluzioni canoniche
00:18 +128: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/evolution_repository_regression_test.dart: le evoluzioni canoniche non sono duplicate dagli alias
00:18 +129: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/evolution_repository_regression_test.dart: le evoluzioni regionali di Hisui usano nomi risolvibili
00:18 +130: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/battle_form_change_service_test.dart: battle form support covers in-combat transformations
00:18 +131: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/battle_form_change_service_test.dart: battle form support covers in-combat transformations
00:18 +132: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/battle_form_change_service_test.dart: battle form support covers in-combat transformations
00:19 +133: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/battle_form_change_service_test.dart: Deoxys uses official Italian form labels and 5e bonuses
00:19 +134: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/battle_form_change_service_test.dart: Darmanitan does not mix Unovan and Galarian battle forms
00:19 +135: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/battle_form_change_service_test.dart: Zygarde uses Forma 50% as base and keeps all three stat profiles
00:19 +136: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/battle_form_change_service_test.dart: Palafin Forma Possente applies battle-only CA, FOR and DES bonuses
00:19 +137: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/move_visible_terminology_test.dart: i metadati tecnici delle mosse vengono mostrati in italiano
00:19 +138: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/move_visible_terminology_test.dart: Tackle viene mostrata come Azione senza perdere il nome tecnico
00:19 +139: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/evolution_form_alias_service_test.dart: Alolan Rattata prefers Alolan Raticate for the base target name
00:20 +140: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/evolution_form_alias_service_test.dart: explicit Alolan Raichu evolution target is available by name
00:20 +141: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/evolution_form_alias_service_test.dart: temporary battle transformations are not evolution aliases
00:20 +142: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/fakemon_advanced_test.dart: una forma personalizzata sovrascrive statistiche e tipi
00:20 +143: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/fakemon_advanced_test.dart: un Fakemon può essere collegato come forma di una specie
00:20 +144: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/fakemon_advanced_test.dart: Eevee riceve una nuova evoluzione Fakemon
00:20 +145: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/fakemon_advanced_test.dart: il pacchetto segreto conserva checksum e flag sealed
00:20 +146: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/pokemon_battle_attributes_card_test.dart: mostra tutte le caratteristiche e i modificatori
00:21 +147: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/pokemon_battle_attributes_card_test.dart: mostra tutte le caratteristiche e i modificatori
00:21 +148: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/pokemon_battle_attributes_card_test.dart: mostra tutte le caratteristiche e i modificatori
00:21 +149: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/fakemon_backup_safe_delete_test.dart: una voce Pokédex vuota non blocca l’eliminazione
00:21 +150: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/fakemon_backup_safe_delete_test.dart: il catalogo globale ha checksum e rileva le modifiche
00:22 +151: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/breeder_features_test.dart: riconosce Good Genes e Master of Traits ai livelli corretti
00:22 +152: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/breeder_features_test.dart: Master of Traits sostituisce solo il numero di Egg Moves ereditate
00:22 +153: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/breeder_features_test.dart: il modello uovo conserva PF e scelte Good Genes nei backup
00:22 +154: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/breeder_features_test.dart: gli incubatori espongono costo, oggetto e dadi del manuale
00:22 +155: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/level_progression_test.dart: LevelProgression adds experience with signed input and recalculates level
00:22 +156: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/level_progression_test.dart: LevelProgression sets absolute experience with unsigned input
00:22 +157: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/pokemon_localization_integrity_test.dart: i file italiani coprono una sola volta tutti i Pokémon localizzati
00:22 +158: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/pokemon_localization_integrity_test.dart: il repository carica le 1025 traduzioni italiane
00:22 +159: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/pokemon_localization_integrity_test.dart: le categorie coincidono con il riferimento italiano ufficiale
00:22 +160: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/ability_name_localization_integrity_test.dart: il riferimento ufficiale copre 308 delle 330 voci del catalogo
00:22 +161: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/ability_name_localization_integrity_test.dart: il riferimento ufficiale copre 308 delle 330 voci del catalogo
00:22 +162: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/ability_name_localization_integrity_test.dart: i nomi verificati coincidono con le denominazioni italiane attese
00:22 +163: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/ability_name_localization_integrity_test.dart: il repository conserva il nome tecnico e localizza solo la UI
00:23 +164: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/responsive_content_test.dart: limita la larghezza sulle finestre desktop
00:24 +165: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/responsive_content_test.dart: limita la larghezza sulle finestre desktop
00:24 +166: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/responsive_content_test.dart: limita la larghezza sulle finestre desktop
00:24 +167: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/minior_color_forms_test.dart: Minior colour candidates point to the bundled shared folder
00:24 +168: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/responsive_content_test.dart: usa tutta la larghezza disponibile su smartphone
00:24 +169: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/minior_color_forms_test.dart: gender-only textures do not create a Forma selector
00:24 +170: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/minior_color_forms_test.dart: Pyroar gender changes appearance without changing battle data
00:24 +171: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/minior_color_forms_test.dart: Meowstic keeps its stats but changes learnset and hidden ability
00:24 +172: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/trainer_path_passive_smoke_test.dart: senza profilo o Pokémon posseduto non applica bonus del Trainer Path
00:24 +173: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/profile_backup_service_test.dart: (setUpAll)
00:24 +173: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/profile_backup_service_test.dart: imports every section with a new ID and deletes it completely
00:25 +174: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/profile_backup_service_test.dart: (tearDownAll)
00:25 +174: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/campaign_transfer_service_test.dart: CampaignTransferBundle serializza e rilegge un incontro
00:25 +175: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/campaign_transfer_service_test.dart: CampaignTransferBundle serializza e rilegge un Allenatore PNG
00:25 +176: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/campaign_transfer_service_test.dart: CampaignTransferService imports importa un incontro con nuovo id e nome non distruttivo
00:25 +177: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/campaign_transfer_service_test.dart: CampaignTransferService imports importa un Allenatore PNG e conserva la scheda
00:25 +178: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/campaign_transfer_service_test.dart: CampaignTransferService imports rifiuta specie non presenti nel catalogo
00:25 +179: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/campaign_transfer_service_test.dart: il riepilogo del Fight include turno, PF, status e PP
00:25 +180: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/npc_trainer_generator_service_test.dart: a themed trainer receives only Pokémon of the preferred type
00:25 +181: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/npc_trainer_generator_service_test.dart: duplicates disabled produces distinct species
00:25 +182: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/npc_trainer_generator_service_test.dart: trainer rank increases the maximum controllable SR
00:25 +183: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/npc_trainer_generator_service_test.dart: themed generation fails clearly when the type has no candidates
00:25 +184: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/battle_quick_item_service_test.dart: resolves usable battle items even with non-standard catalog types
00:25 +185: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/battle_quick_item_service_test.dart: classifies Poké Ball IDs without relying on the type field
00:26 +186: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/pokemon_generator_multi_select_test.dart: deduplicates type aliases and sorts them by Italian label
00:26 +187: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/pokemon_generator_multi_select_test.dart: accepts Italian type labels in filters and free-text search
00:26 +188: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/pokemon_generator_multi_select_test.dart: generates one independent result for every selected species
00:26 +189: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/pokemon_transfer_service_test.dart: il file di un singolo Pokémon conserva tutti i dati utili
00:26 +190: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/pokemon_transfer_service_test.dart: importare un Pokémon sostituisce lo slot e salva il precedente nel PC
00:26 +191: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/pokemon_transfer_service_test.dart: importare una squadra preserva le uova e manda gli esuberi nel PC
00:26 +192: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/pokemon_transfer_service_test.dart: un uovo non può essere esportato come Pokémon
00:26 +193: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/trainer_ui_localization_test.dart: caratteristiche e abilità vengono mostrate in italiano
00:26 +194: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/trainer_ui_localization_test.dart: nomi tecnici mantengono etichette italiane separate
00:26 +195: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/trainer_ui_localization_test.dart: la UI non reintroduce le principali etichette inglesi
00:27 +196: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/battle_environment_service_test.dart: la tabella meteo rispetta i confini stagionali del manuale
00:27 +197: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/battle_environment_service_test.dart: il vantaggio opzionale usa il tipo della mossa e Weather Ball
00:27 +198: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/battle_environment_service_test.dart: Terrain Adept configurato concede +2 solo nel terreno scelto
00:27 +199: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/battle_environment_service_test.dart: abilità ambientali modificano CA, velocità e danni
00:27 +200: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/battle_environment_service_test.dart: Grandine e Tempesta di sabbia rispettano immunità e livello
00:27 +201: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/battle_environment_service_test.dart: durate e ambiente sopravvivono al salvataggio della battaglia
00:27 +202: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/alolan_raichu_asset_test.dart: Raichu di Alola usa l artwork regionale nella scheda
00:27 +203: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/alolan_raichu_asset_test.dart: Raichu di Alola usa l artwork regionale nella scheda
00:27 +204: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/alolan_raichu_asset_test.dart: Raichu di Alola usa l artwork regionale nella scheda
00:27 +205: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/alolan_raichu_asset_test.dart: Raichu di Alola usa l artwork regionale nella scheda
00:27 +206: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/alolan_raichu_asset_test.dart: Raichu di Alola usa l artwork regionale nella scheda
00:27 +207: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/alolan_raichu_asset_test.dart: Raichu di Alola usa l artwork regionale nella scheda
00:27 +208: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/alolan_raichu_asset_test.dart: Raichu di Alola usa l artwork regionale nella scheda
00:27 +209: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/alolan_raichu_asset_test.dart: Raichu di Alola usa l artwork regionale nella scheda
00:27 +210: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/alolan_raichu_asset_test.dart: Raichu di Alola usa l artwork regionale nella scheda
00:28 +211: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/user_profile_test.dart: UserProfile reads older saved profiles with trainer defaults
00:28 +212: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/user_profile_test.dart: UserProfile persists trainer companion fields
00:28 +213: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/user_profile_test.dart: UserProfile copyWith updates trainer companion fields
00:28 +214: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/trainer_progression_test.dart: TrainerProgression returns pokeslots from trainer level breakpoints
00:28 +215: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/trainer_progression_test.dart: TrainerProgression returns max controlled SR from trainer level breakpoints
00:28 +216: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/trainer_progression_test.dart: TrainerProgression checks if a trainer can control a Pokemon SR
00:28 +217: /home/runner/work/Pokedex5e_ita/Pokedex5e_ita/test/trainer_progression_test.dart: TrainerProgression returns the next progression upgrade levels
00:28 +218: All tests passed!
```

## Build Android debug
```text
Resolving dependencies...
Downloading packages...
  file_picker 10.3.10 (11.0.2 available)
  hooks 2.0.2 (2.1.0 available)
  matcher 0.12.19 (0.12.20 available)
  meta 1.18.0 (1.19.0 available)
  package_config 2.2.0 (3.0.0 available)
  record_use 0.6.0 (1.0.0 available)
  share_plus 12.0.2 (13.2.1 available)
  share_plus_platform_interface 6.1.0 (7.1.0 available)
  test_api 0.7.11 (0.7.13 available)
  uuid 4.5.3 (4.6.0 available)
  vector_math 2.2.0 (2.4.0 available)
  win32 5.15.0 (6.3.0 available)
  xml 6.6.1 (7.0.1 available)
Got dependencies!
13 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
Running Gradle task 'assembleDebug'...                          
WARNING: Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP): file_picker, share_plus
Future versions of Flutter will fail to build if your app uses plugins that apply KGP.

Please check the changelogs of these plugins and upgrade to a version that supports Built-in Kotlin.
If no such version exists, report the issue to the plugin. If necessary, here is a guide on filing 
an issue against a plugin: https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers#report-incompatible-kotlin-gradle-plugin-usage-to-plugin-authors

If you are a plugin author, please migrate your plugin to Built-in Kotlin using this guide: https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-plugin-authors
Checking the license for package CMake 3.22.1 in /usr/local/lib/android/sdk/licenses
License for package CMake 3.22.1 accepted.
Preparing "Install CMake 3.22.1 v.3.22.1".
"Install CMake 3.22.1 v.3.22.1" ready.
Installing CMake 3.22.1 in /usr/local/lib/android/sdk/cmake/3.22.1
"Install CMake 3.22.1 v.3.22.1" complete.
"Install CMake 3.22.1 v.3.22.1" finished.
Running Gradle task 'assembleDebug'...                            231.3s
✓ Built build/app/outputs/flutter-apk/app-debug.apk
```
