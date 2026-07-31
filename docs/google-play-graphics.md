# Grafiche e screenshot Google Play

Ultimo aggiornamento: 31 luglio 2026

## Risorse da preparare

### Icona Play Store

- formato: PNG 32 bit con trasparenza;
- dimensioni: 512 × 512 px;
- peso massimo: 1024 KB;
- niente badge, prezzi, ranking o simboli ingannevoli;
- mantenere il soggetto principale centrato e leggibile anche in piccolo.

L'icona dello Store è distinta tecnicamente dall'icona launcher inclusa nell'AAB, ma deve usare la stessa identità visiva.

### Grafica in primo piano

- formato: JPEG oppure PNG 24 bit senza trasparenza;
- dimensioni: 1024 × 500 px;
- elementi importanti nella zona centrale;
- testo ridotto al minimo;
- nessun riferimento che faccia apparire l'app ufficiale o affiliata a terzi.

Proposta di composizione:

- sfondo coerente con il rosso e il bianco dell'app;
- logo o simbolo di Trainer Atlas 5e al centro-sinistra;
- breve richiamo visivo alla gestione di squadra e campagna;
- nessun logo Google Play e nessun marchio di terzi usato come elemento promozionale dominante.

### Screenshot telefono

Usare catture reali della build distribuita tramite Play Store. Non inserire funzioni non presenti e non modificare le schermate per simulare risultati diversi.

Sequenza proposta in italiano:

1. Home con accesso alle aree principali;
2. profilo Allenatore e riepilogo della campagna;
3. squadra con quattro o più Pokémon visibili;
4. dettaglio Pokémon con statistiche e informazioni;
5. Pokédex o catalogo con ricerca;
6. zaino e inventario;
7. strumenti del Master o gestione incontri;
8. Impostazioni con selezione della lingua e informazioni legali.

Preparare la stessa sequenza in inglese oppure usare gli stessi screenshot soltanto dove il testo è neutro. Le localizzazioni della scheda Store dovrebbero mostrare preferibilmente l'interfaccia nella lingua corrispondente.

## Preparazione del dispositivo

Prima delle catture:

- installare la build dal canale interno o chiuso di Google Play;
- selezionare tema e dimensione caratteri standard;
- impostare lingua italiana per il primo set e inglese per il secondo;
- usare un profilo dimostrativo senza nomi, email o dati reali;
- riempire squadra, PC e zaino con dati sufficienti a evitare schermate vuote;
- disattivare notifiche e modalità non disturbare;
- nascondere eventuali informazioni personali nella barra di stato;
- verificare che non siano visibili overlay di debug, indicatori FPS o banner di test.

## Criteri di qualità

- nessun overflow, testo tagliato o immagine mancante;
- immagini nitide e orientamento coerente;
- stessa risoluzione e rapporto tra gli screenshot dello stesso gruppo;
- contenuto leggibile su un normale schermo da telefono;
- niente cornici di dispositivi, claim, premi o classifiche non verificabili;
- niente schermate contenenti backup, nomi reali o identificativi personali;
- disclaimer e attribuzioni coerenti con la scheda Store.

## Controllo legale e di policy

Prima del caricamento, verificare separatamente:

- provenienza e licenza di ogni elemento grafico usato per icona e feature graphic;
- uso corretto di marchi e personaggi di terzi;
- assenza di elementi che suggeriscano affiliazione ufficiale;
- coerenza con il nome sviluppatore, la descrizione e il disclaimer;
- adeguatezza delle immagini al pubblico di destinazione dichiarato.

## Cartella di lavoro locale consigliata

Non inserire bozze contenenti dati personali nella repository. Organizzare localmente:

```text
play-store-assets/
  icon/
    trainer-atlas-512.png
  feature-graphic/
    trainer-atlas-feature-1024x500.png
  screenshots/
    it/
    en/
  source/
  export/
```

Conservare i file sorgente modificabili separatamente dagli export finali e annotare per ogni risorsa autore, provenienza e licenza.
