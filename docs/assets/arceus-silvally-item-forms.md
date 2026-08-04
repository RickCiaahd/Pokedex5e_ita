# Asset delle forme di Arceus e Silvally

Arceus e Silvally non espongono forme selezionabili. La forma, il tipo e le
immagini vengono scelti automaticamente dallo strumento tenuto:

- Arceus: Lastra elementale compatibile;
- Silvally: ROM (Memory Disc) compatibile;
- nessuno strumento o strumento non compatibile: forma Normale.

## Posizione e nomi dei file

I file vanno aggiunti direttamente nelle due cartelle già dichiarate in
`pubspec.yaml`:

```text
assets/textures/textures_webapp/pokemon/arceus/
assets/textures/textures_webapp/pokemon/silvally/
```

Per ciascuno dei 17 tipi non Normale servono quattro file. Per esempio, per il
tipo Fuoco:

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

## Download assistito

Il repository contiene uno script PowerShell che scarica tutti i 136 file
(2 Pokémon × 17 tipi × 4 immagini) con i nomi corretti:

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
standard e shiny. Le corrispondenze sono:

| File locale | Sorgente PokeAPI |
|---|---|
| `main-<tipo>.png` | `sprites/pokemon/other/home/<numero>-<tipo>.png` |
| `main-<tipo>-shiny.png` | `sprites/pokemon/other/home/shiny/<numero>-<tipo>.png` |
| `sprite-<tipo>.png` | `sprites/pokemon/<numero>-<tipo>.png` |
| `sprite-<tipo>-shiny.png` | `sprites/pokemon/shiny/<numero>-<tipo>.png` |

I numeri sono `493` per Arceus e `773` per Silvally.

## Verifica

Dopo aver aggiunto le immagini:

1. eseguire `flutter pub get` e `flutter test`;
2. avviare l'app e assegnare almeno una Lastra ad Arceus e una ROM a Silvally;
3. verificare dettaglio, squadra, PC, zaino e lotta sia normale sia shiny;
4. togliere lo strumento e verificare il ritorno alla forma Normale;
5. controllare che la sezione Forma non sia disponibile per i due Pokémon.

Le immagini Pokémon e i relativi marchi restano proprietà dei rispettivi
titolari. Prima della distribuzione su Microsoft Store o Google Play va svolta
la verifica dei diritti d'uso; il fatto che i file siano pubblicamente
scaricabili non equivale a una licenza commerciale sugli asset Pokémon.
