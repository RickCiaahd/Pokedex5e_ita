# Ottimizzazione pre-merge dell'AAB

Audit eseguito prima del merge della PR #182 sulla variante release non minificata, usando Flutter 3.44.4 e una chiave CI temporanea esclusivamente per la misurazione.

- AAB prima della deduplicazione: **327.841.510 byte**
- AAB dopo la deduplicazione: **327.445.883 byte**
- Riduzione effettiva: **395.627 byte**
- Alias asset Minior rimossi: **44**, tutti verificati byte-per-byte come duplicati esatti prima della rimozione.
- Inventario duplicati residuo: **41 gruppi**, **42 copie ridondanti**, massimo teorico residuo **1.945.478 byte**.

L'intervento conserva un'unica copia canonica dell'artwork Shiny dei sette nuclei di Minior, mantiene le immagini normali dedicate per i colori non rossi e usa l'artwork normale canonico per il nucleo rosso. Il resolver e i test sono stati aggiornati di conseguenza.

Verifiche completate con successo durante l'audit:

- test dedicati alle forme colore di Minior;
- test del resolver degli asset Pokémon;
- `flutter analyze`;
- build APK release;
- build AAB release;
- rigenerazione degli inventari di conformità e dei duplicati;
- rigenerazione del report di footprint.

La riduzione è intenzionalmente conservativa: non vengono rimossi asset soltanto perché sembrano inutilizzati e non viene abilitata di default la minificazione R8/resource shrinking. La release pubblicabile resta quindi la variante standard finché la variante minificata non supera anche il collaudo reale di aggiornamento e persistenza dati.
