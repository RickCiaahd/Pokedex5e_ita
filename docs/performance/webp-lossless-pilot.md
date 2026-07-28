# Lotto pilota WebP lossless

Il lotto converte un insieme piccolo e rappresentativo di artwork e sprite 
da PNG a WebP lossless. I file PNG selezionati sono sostituiti dai relativi 
WebP, mantenendo invariati percorso logico, dimensioni e pixel RGBA decodificati.

- File convertiti: **12**
- Peso PNG di partenza: **0.69 MiB**
- Peso WebP lossless: **0.42 MiB**
- Risparmio: **0.27 MiB (39.1%)**
- Pixel RGBA modificati: **0**
- Immagini o varianti eliminate: **0**

## Copertura del campione

Il campione include artwork grandi, shiny, sprite, forma regionale, forma 
alternativa, differenze di genere e alcuni file riparati nel blocco precedente.

## Compatibilità

Il risolutore prova prima il corrispondente `.webp` e mantiene il `.png` come 
fallback generale. In questo modo la migrazione può essere estesa per lotti 
senza cambiare gli ID tecnici o le regole di selezione delle immagini.

Il report file-per-file è disponibile in 
`docs/performance/webp-lossless-pilot.csv`.
