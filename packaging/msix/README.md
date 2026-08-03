# Asset del pacchetto MSIX

Inserire in questa cartella i PNG definitivi per Microsoft Store con questi nomi esatti:

- `StoreLogo.png` — 50 × 50 px;
- `Square44x44Logo.png` — 44 × 44 px;
- `Square150x150Logo.png` — 150 × 150 px;
- `Wide310x150Logo.png` — 310 × 150 px;
- `Square310x310Logo.png` — 310 × 310 px;
- `SplashScreen.png` — 620 × 300 px.

Gli asset devono essere PNG, senza marchi o elementi grafici di terzi privi di autorizzazione alla ridistribuzione. Lo script `tool/build_msix_store.ps1` interrompe la preparazione se questa cartella non esiste; `makeappx` segnala eventuali file mancanti indicati dal manifest.

La normale icona desktop continua a provenire da `windows/runner/resources/app_icon.ico`.
