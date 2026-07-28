# Audit di ottimizzazione delle immagini Pokémon

Questo documento riassume l'audit non distruttivo eseguito sulla famiglia `assets/textures/textures_webapp/pokemon` e il successivo intervento di riparazione lossless.

L'audit e la riparazione non eliminano, sostituiscono, ridimensionano o rinominano alcuna immagine. APK, AAB e pacchetto Windows continuano a includere tutte le immagini previste dall'app.

## Stato attuale dell'inventario

- File individuati: **4.719**
- Immagini leggibili: **4.719**
- File non leggibili: **0**
- Dimensione complessiva della famiglia: circa **304,8 MiB**
- Immagini animate: **0**
- Dimensione massima mediana: **475 px**
- Dimensione massima assoluta: **894 px**
- Immagini sopra 512 px: **11**
- Immagini sopra 768 px: **9**
- Immagini sopra 1.024 px: **0**

La riduzione generalizzata della risoluzione non appare una strategia prioritaria: quasi tutto il catalogo principale è già intorno a 475 px. Le sole immagini nettamente più grandi sono alcune differenze di genere a 767 o 894 px e devono essere valutate individualmente.

La classificazione automatica per ruolo è basata sui nomi dei file e delle cartelle ed è soltanto indicativa; non sostituisce la verifica dei percorsi usati dall'app.

## Riparazione dei 23 PNG problematici

L'audit iniziale aveva individuato 23 PNG che Pillow non riusciva a decodificare rigorosamente. I file contenevano dati immagine recuperabili ma metadati o terminazioni non conformi.

La riparazione ha:

- caricato esclusivamente i 23 file censiti in modalità tollerante;
- riscritto ciascun file come PNG lossless pulito;
- mantenuto percorso e dimensioni originali di **96×96 px**;
- confrontato l'hash SHA-256 dei pixel RGBA prima e dopo la riscrittura;
- confermato che tutti i pixel decodificati sono rimasti identici;
- ridotto complessivamente il peso di **114.632 byte** eliminando dati corrotti o superflui.

Il dettaglio file-per-file, comprensivo degli hash originali, nuovi hash e hash dei pixel, è disponibile in `docs/performance/repaired-pokemon-images.csv`. L'elenco `docs/performance/unreadable-pokemon-images.csv` è ora vuoto, oltre all'intestazione.

## Lotto lossless misurato

Prima della riparazione era stato selezionato un campione deterministico di **30 file**, privilegiando immagini pesanti e includendo categorie differenti.

| Variante | Peso del campione | Riduzione |
|---|---:|---:|
| File originali | 7,6 MiB | — |
| PNG riottimizzato senza perdita | 6,9 MiB | 9,8% |
| WebP lossless | 4,5 MiB | 41,1% |

Il risultato WebP è promettente, ma il campione è volutamente orientato verso file grandi e non deve essere moltiplicato automaticamente per tutto il catalogo. Prima di una conversione estesa servono verifiche visive e funzionali su Android, Windows e web.

## Controllo permanente

La pipeline `Image optimization audit` ora:

- richiede che tutte le immagini Pokémon siano decodificabili rigorosamente;
- blocca la PR se viene introdotto un nuovo file corrotto o illeggibile;
- esegue la scansione completa dei metadati;
- genera un inventario CSV file-per-file;
- misura un campione deterministico di compressione lossless;
- verifica che l'audit non modifichi gli asset sorgente;
- pubblica i report completi come artefatto GitHub Actions.

## Strategia consigliata

1. Conservare l'attuale bundle PNG completo come riferimento.
2. Preparare un lotto pilota reversibile di immagini normali, shiny, sprite, forme e differenze di genere.
3. Confrontare PNG ottimizzato e WebP lossless nell'interfaccia reale, comprese trasparenza, zoom e resa desktop.
4. Applicare la strategia scelta a un lotto limitato e ricostruire APK, AAB, Windows e web.
5. Confrontare peso e qualità con la baseline completa: APK 389,7 MiB e AAB 384,8 MiB.
6. Estendere l'ottimizzazione soltanto dopo test automatici e controllo visivo.
