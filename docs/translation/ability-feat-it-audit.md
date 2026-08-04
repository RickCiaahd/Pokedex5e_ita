# Audit italiano di abilità e privilegi

## Ambito

- 330 abilità del catalogo completo;
- 36 privilegi selezionabili dai Pokémon;
- nomi tecnici citati nelle descrizioni di abilità;
- visualizzazione in Modifica Pokémon, dettaglio Pokémon e Allevamento.

## Fonti

- nomi ufficiali delle abilità Pokémon: Pokémon Central e riferimenti PokeAPI già registrati in `ability_names_it_official.json`;
- effetti delle abilità e dei privilegi specifici: manuale Pokémon 5e allegato, in particolare pagina 18 per i privilegi;
- denominazioni italiane dei talenti D&D 5e: Manuale del Giocatore, capitolo 6, pagine 165-170;
- nomi italiani di mosse e oggetti: cataloghi localizzati già inclusi nell'app.

## Scelte tecniche

- ID, nomi tecnici inglesi e valori salvati non vengono modificati;
- 308 nomi ufficiali e 22 traduzioni specifiche del catalogo formano una copertura completa di 330 abilità;
- i riferimenti a mosse, abilità, oggetti e forme nelle descrizioni italiane usano il nome visualizzato italiano;
- il token sorgente `MOVE` viene mostrato come **modificatore di caratteristica della mossa**; `STAB`, `PP`, `CA`, `PF`, formule, dadi, percentuali e distanze restano invariati;
- i frammenti inglesi richiesti da regole basate sul nome, come `Cut`, `Blade` e `Slash` per Affilama, sono esplicitamente indicati come parti del nome tecnico inglese;
- l'interfaccia italiana usa **privilegio**, mentre la lingua inglese continua a usare **feat**.

## Controlli automatici

- copertura uno-a-uno di 330 nomi abilità e 330 descrizioni;
- copertura uno-a-uno di 36 privilegi;
- conservazione di tutti i token numerici e meccanici dei privilegi;
- regressioni sui riferimenti visibili segnalati: Sfuriate, Doppiasberla, Acqualame, Scudo Reale, Forma Scudo e Forma Spada;
- mantenimento dei nomi tecnici inglesi quando la lingua dell'app è inglese.
