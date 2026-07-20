# Audit della localizzazione italiana delle mosse 651-830

## Ambito

Questo blocco localizza le mosse dalla posizione **651** alla **830** del catalogo unificato restituito da `MoveRepository.getAllMoves()`, da `Sludge Wave` a `Zing Zap`.

Sono state aggiunte **180 localizzazioni**, suddivise in tre overlay da 50 elementi e un overlay finale da 30 elementi. La copertura raggiunge così **830 mosse su 830**.

## Nomi italiani

I nomi visualizzati sono stati confrontati con Pokémon Central e con i dati italiani di PokéAPI. `Syrup Bomb`, assente nel dump PokéAPI utilizzato dall’audit iniziale, è stata verificata manualmente come **Bomba Sciroppata**.

## Descrizioni 5e

Per ogni mossa restano invariati numero e ordine dei blocchi descrittivi, presenza di `higherLevels`, dadi, numeri, formule, distanze, livelli, durate e riferimenti tecnici. ID, slug, nomi tecnici inglesi, tipi, PP, potenza, TM, tiri salvezza, attacchi e dati di danno continuano a provenire dai file sorgente originali.

## Compatibilità

I nomi inglesi continuano a essere usati nei salvataggi, nei learnset, nei trasferimenti e nei Fakemon. Il repository risolve una mossa tramite ID, nome tecnico inglese o nome italiano visualizzato.

## Controlli

I test automatici verificano la copertura esatta di tutte le 830 mosse, l’assenza di duplicati, la corrispondenza dei nomi tecnici, il numero dei blocchi e la conservazione dei token meccanici.
