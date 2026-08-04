# Audit italiano delle mosse #001-050

Questo blocco avvia la localizzazione delle 830 mosse presenti in `assets/data_webapp/moves.json`, applicando un livello italiano separato dai dati tecnici sorgente.

## Verifica dei nomi

- Pokémon Central è il riferimento principale per il nome mostrato nell'interfaccia.
- I dati italiani di PokéAPI sono usati come confronto automatico e controllo incrociato.
- L'audit automatico ha riconosciuto 824 delle 830 voci del catalogo tramite PokéAPI.
- Le sei voci non riconosciute automaticamente sono state esaminate separatamente:
  - `Blood Moon` → **Luna Rossa**;
  - `Ivy Cudgel` → **Clava di Liane**;
  - `Matcha Gotcha` → **Spruzzatè**;
  - `Syrup Bomb` → **Bomba Sciroppata**;
  - `Draco Power` e `Halo Song` sono mosse personalizzate del catalogo 5e e manterranno il nome tecnico finché non verrà approvata una localizzazione specifica.
- Le prime 50 mosse di questo blocco possiedono tutte una corrispondenza ufficiale verificata.

## Criteri di traduzione

- ID, nomi tecnici inglesi, tipi, PP, poteri, TM, tiri salvezza, attacchi e dati di danno restano invariati.
- Il nome italiano viene applicato soltanto alla UI; il riferimento inglese continua a risolvere la stessa mossa.
- Le descrizioni 5e conservano numero e ordine dei paragrafi, tabelle, dadi, valori numerici, distanze, livelli e formule.
- Le sigle seguono il glossario del progetto: **CA**, **PF**, **CD**, **FOR**, **DES**, **COS**, **SAG**, **CAR**; il token sorgente `MOVE` viene mostrato come **modificatore di caratteristica della mossa**, mentre **PP**, **SR**, **STAB** e `FLINCHED` restano tecnici quando richiesto.
- I nomi di altre mosse citate nelle descrizioni usano la denominazione italiana ufficiale quando disponibile.
- I nomi delle forme di Morpeko sono stati verificati come **Motivo Panciapiena** e **Motivo Panciavuota**.

## Copertura del blocco

Le mosse dalla posizione 1 alla 50 del catalogo, da `Absorb` a `Behemoth Bash`, sono localizzate con cataloghi separati e controlli automatici permanenti. Il prossimo blocco parte da `Behemoth Blade`.
