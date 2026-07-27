# Audit del funzionamento offline

Stato: controllo tecnico automatico introdotto per la roadmap #129.

## Risultato del blocco

- gli sprite degli oggetti vengono caricati esclusivamente da `spriteAssetPath` e da asset inclusi nel bundle;
- sono stati rimossi i fallback verso `poke5e.app` e `raw.githubusercontent.com`;
- `Image.network` non viene più usato dal codice applicativo;
- il manifest Android principale non richiede `android.permission.INTERNET`;
- un test verifica che ogni percorso locale dichiarato per gli sprite degli oggetti sia incluso nell'AssetManifest;
- un controllo sorgente impedisce di reintrodurre loader di immagini remote o host di fallback noti.

## Funzioni che possono coinvolgere applicazioni esterne

Esportazione, condivisione e selezione di file avvengono soltanto su iniziativa dell'utente tramite i picker o il menu di condivisione del sistema operativo. Trainer Atlas 5e non invia automaticamente profili, backup o telemetria a un server dello sviluppatore.

## Verifiche manuali ancora consigliate

1. installare una build release su un dispositivo in modalità aereo;
2. aprire Pokédex, squadra, PC, Zaino, allevamento e strumenti del Master;
3. verificare artwork, sprite, tipi e icone di stato;
4. creare, chiudere e riprendere una battaglia;
5. riavviare l'app e verificare la persistenza dei dati;
6. controllare che soltanto condivisione ed esportazione richiedano un'app esterna scelta dall'utente.

Il test manuale su dispositivi reali resta necessario prima della beta pubblica.
