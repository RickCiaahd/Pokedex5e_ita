# Asset delle forme di Arceus, Silvally e Genesect

Questi Pokémon non espongono forme selezionabili. Aspetto e regole vengono
scelti automaticamente dallo strumento tenuto:

- Arceus: Lastra elementale compatibile;
- Silvally: ROM compatibile;
- Genesect: Piromodulo, Gelomodulo, Idromodulo o Voltmodulo; il Pokémon resta
  Coleottero/Acciaio, mentre cambia il tipo di Tecnobotto;
- nessuno strumento o strumento non compatibile: forma Normale.

## Posizione e nomi dei file

I file vanno aggiunti direttamente nelle tre cartelle già dichiarate in
`pubspec.yaml`:

```text
assets/textures/textures_webapp/pokemon/arceus/
assets/textures/textures_webapp/pokemon/silvally/
assets/textures/textures_webapp/pokemon/genesect/
```

Per Arceus e Silvally, ciascuno dei 17 tipi non Normale richiede quattro file.
Per esempio, per il tipo Fuoco:

```text
main-fire.png
main-fire-shiny.png
sprite-fire.png
sprite-fire-shiny.png
```

Sono accettati anche file WebP con gli stessi nomi. Se PNG e WebP sono entrambi
presenti, l'app preferisce WebP. I suffissi validi sono:

```text
bug dark dragon electric fairy fighting fire flying ghost grass ground ice
poison psychic rock steel water
```

Le immagini della forma Normale già presenti (`main.webp`, `main-shiny.webp`,
`sprite.png`, `sprite-shiny.png`) restano il fallback.

Per Genesect servono invece quattro file per ciascuno dei suffissi `burn`,
`chill`, `douse` e `shock`. Per esempio:

```text
main-burn.png
main-burn-shiny.png
sprite-burn.png
sprite-burn-shiny.png
```

## Download assistito

Il repository contiene uno script PowerShell che scarica i 136 file di Arceus
e Silvally e i 16 file di Genesect, per un totale di 152 immagini:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\download_item_driven_form_assets.ps1
```

Per sostituire file già presenti:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\download_item_driven_form_assets.ps1 -Overwrite
```

Lo script usa una revisione fissata del repository
[PokeAPI/sprites](https://github.com/PokeAPI/sprites/tree/5841d46f1a0d2b8918a29a7376b1424878b86b59),
che documenta le immagini Pokémon HOME come PNG 512×512 e ospita anche sprite
standard e shiny. Le corrispondenze generali sono:

| File locale | Sorgente PokeAPI |
|---|---|
| `main-<forma>.png` | `sprites/pokemon/other/home/<numero>-<forma>.png` |
| `main-<forma>-shiny.png` | `sprites/pokemon/other/home/shiny/<numero>-<forma>.png` |
| `sprite-<forma>.png` | `sprites/pokemon/<numero>-<forma>.png` |
| `sprite-<forma>-shiny.png` | `sprites/pokemon/shiny/<numero>-<forma>.png` |

I numeri sono `493` per Arceus, `649` per Genesect e `773` per Silvally.

## Verifica

Dopo aver aggiunto le immagini:

1. eseguire `flutter pub get`;
2. aggiungere prima i nuovi file all'indice Git, quindi rigenerare gli
   inventari senza convertire immagini:

   ```powershell
   git add assets/textures/textures_webapp/pokemon/genesect
   python .\tooling\manage_webp_lossless_batches.py --refresh
   python .\tooling\generate_compliance_reports.py
   python .\tooling\manage_webp_lossless_batches.py --check
   python .\tooling\generate_compliance_reports.py --check
   ```

3. eseguire `flutter test`;
4. avviare l'app e assegnare almeno una Lastra ad Arceus, una ROM a Silvally e
   un Modulo a Genesect;
5. verificare dettaglio, squadra, PC, zaino e lotta sia normale sia shiny;
6. togliere lo strumento e verificare il ritorno alla forma Normale;
7. controllare che la sezione Forma non sia disponibile per i tre Pokémon;
8. verificare che Tecnobotto sia Normale senza Modulo e assuma il tipo corretto
   con ciascuno dei quattro Moduli.

Le immagini Pokémon e i relativi marchi restano proprietà dei rispettivi
titolari. Prima della distribuzione su Microsoft Store o Google Play va svolta
la verifica dei diritti d'uso; il fatto che i file siano pubblicamente
scaricabili non equivale a una licenza commerciale sugli asset Pokémon.
