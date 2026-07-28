# Audit di ottimizzazione delle immagini Pokémon

Questo documento riassume l'audit non distruttivo eseguito sulla famiglia `assets/textures/textures_webapp/pokemon`.

L'audit non modifica, converte, ridimensiona, rinomina o elimina alcun file. APK, AAB e pacchetto Windows continuano a includere tutte le immagini previste dall'app.

## Risultati dell'inventario

- File individuati: **4.719**
- Immagini leggibili: **4.696**
- File PNG non leggibili o corrotti: **23**
- Dimensione complessiva della famiglia: **304,9 MiB**
- Immagini leggibili con trasparenza: **4.696**
- Immagini animate: **0**
- Dimensione massima mediana: **475 px**
- Dimensione massima assoluta: **894 px**
- Immagini sopra 512 px: **11**
- Immagini sopra 768 px: **9**
- Immagini sopra 1.024 px: **0**

La riduzione generalizzata della risoluzione non appare quindi una strategia prioritaria: quasi tutto il catalogo principale è già intorno a 475 px. Le sole immagini nettamente più grandi sono alcune differenze di genere a 767 o 894 px e devono essere valutate individualmente.

La classificazione automatica per ruolo è basata sui nomi dei file e delle cartelle ed è soltanto indicativa; non sostituisce la verifica dei percorsi usati dall'app.

## Lotto lossless misurato

È stato selezionato un campione deterministico di **30 file**, privilegiando immagini pesanti e includendo categorie differenti.

| Variante | Peso del campione | Riduzione |
|---|---:|---:|
| File originali | 7,6 MiB | — |
| PNG riottimizzato senza perdita | 6,9 MiB | 9,8% |
| WebP lossless | 4,5 MiB | 41,1% |

Il risultato WebP è promettente, ma il campione è volutamente orientato verso file grandi e non deve essere moltiplicato automaticamente per tutto il catalogo. Prima di una conversione estesa servono verifiche visive e funzionali su Android, Windows e web.

## File da riparare

L'audit ha individuato **23 file con estensione PNG che Pillow non riesce a decodificare**. I file non sono stati eliminati e rimangono nel progetto. L'elenco stabile è disponibile in `docs/performance/unreadable-pokemon-images.csv`.

Questi file devono essere riparati o sostituiti con la corrispondente immagine valida prima di avviare una conversione globale.

## Strategia consigliata

1. Riparare i 23 PNG non leggibili mantenendo gli stessi percorsi e le stesse varianti.
2. Conservare l'attuale bundle PNG completo come riferimento.
3. Preparare un lotto pilota reversibile di immagini normali, shiny, sprite, forme e differenze di genere.
4. Confrontare PNG ottimizzato e WebP lossless nell'interfaccia reale, comprese trasparenza, zoom e resa desktop.
5. Applicare la strategia scelta a un lotto limitato e ricostruire APK, AAB, Windows e web.
6. Confrontare peso e qualità con la baseline completa: APK 389,7 MiB e AAB 384,8 MiB.
7. Estendere l'ottimizzazione soltanto dopo test automatici e controllo visivo.

## Riproducibilità

La pipeline `Image optimization audit` esegue:

- scansione completa dei metadati;
- inventario CSV file-per-file;
- elenco dei file non leggibili;
- campione deterministico di compressione lossless;
- verifica che nessuna immagine sorgente sia stata modificata;
- pubblicazione dei report completi come artefatto GitHub Actions.
