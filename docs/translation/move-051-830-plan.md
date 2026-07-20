# Piano di localizzazione delle mosse 51-830

Le 780 mosse ancora da localizzare vengono completate in quattro pull request indipendenti, mantenendo un solo criterio di ordinamento: quello restituito dal catalogo unificato di `MoveRepository.getAllMoves()`.

## Blocchi

1. mosse 51-250;
2. mosse 251-450;
3. mosse 451-650;
4. mosse 651-830.

La suddivisione non modifica l’ordine o la struttura dei dati sorgente. Serve esclusivamente a rendere revisionabili le traduzioni e a isolare più rapidamente eventuali errori nei controlli meccanici.

## Regole per ogni blocco

- verificare il nome italiano su Pokémon Central e confrontarlo con i dati italiani di PokéAPI;
- preferire Pokémon Central in caso di divergenza documentata;
- lasciare invariati ID, slug, nome tecnico inglese, tipo, PP, TM, potenza, tiri salvezza, attacchi, danni e ogni altro campo meccanico;
- tradurre soltanto nome visualizzato e descrizione tramite overlay separati;
- conservare dadi, numeri, formule, distanze, durate, livelli e riferimenti tecnici;
- mantenere la retrocompatibilità di salvataggi, learnset, trasferimenti e Fakemon;
- estendere fixture e test di copertura e integrità;
- eseguire `flutter analyze`, validazione dei dati, suite completa e build Android prima del merge.

## Motivazione

Una singola pull request con 780 descrizioni produrrebbe una differenza troppo ampia da revisionare e renderebbe più difficile individuare una singola traduzione o un singolo token meccanico errato. Quattro blocchi da circa 200 mosse mantengono invece il lavoro rapido, ma limitano il rischio di dover correggere o annullare l’intero catalogo in caso di problema.
