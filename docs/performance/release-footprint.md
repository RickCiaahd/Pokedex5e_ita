# Release footprint audit

This report is generated from release APK/AAB archives and an exact SHA-256 scan of every file below `assets/`.
It measures size and byte-identical duplication; it does not by itself prove that an asset is unused or safe to remove.

- Pinned Flutter version: **3.44.4**
- Flutter revision: `ad70ec4617166f1c38e5d2bfd388af71fda14f06`
- Asset files scanned: **8541**
- Source asset size: **332.1 MiB**
- Exact duplicate groups: **51**
- Redundant copies: **81**
- Theoretical maximum reclaimable bytes: **4.3 MiB**
- Duplicate groups spanning multiple policy families: **0**

The theoretical saving assumes one copy per identical hash and ignores path compatibility, runtime lookup rules and compression effects.

## Android release APK

- Archive size: **389.7 MiB** (408677802 bytes)
- ZIP entries: **8629**
- Compressed payload: **387.8 MiB**
- Uncompressed payload: **399.2 MiB**
- Embedded legal files: **`GPL-3.0.txt`, `NOTICE.txt`**

### Bundled Flutter asset families

| Family | Files | Compressed | Uncompressed |
|---|---:|---:|---:|
| `assets/textures/textures_webapp/pokemon` | 4687 | 303.2 MiB | 303.2 MiB |
| `assets/textures/pokemons` | 861 | 17.8 MiB | 17.8 MiB |
| `assets/data_webapp` | 11 | 505.3 KiB | 3.6 MiB |
| `assets/data` | 1645 | 1.1 MiB | 3.0 MiB |
| `assets/textures/trainers` | 5 | 1.5 MiB | 1.5 MiB |
| `assets/textures/gui` | 105 | 532.7 KiB | 532.7 KiB |
| `assets/textures/sprites` | 860 | 502.8 KiB | 502.8 KiB |
| `assets/textures/textures_webapp/items` | 316 | 374.7 KiB | 374.7 KiB |
| `assets/textures/type_names` | 18 | 44.4 KiB | 44.4 KiB |
| `assets/textures/textures_webapp/pokemon_transforms` | 1 | 337 B | 778 B |

### Largest archive entries

| Entry | Compressed | Uncompressed |
|---|---:|---:|
| `lib/x86_64/libflutter.so` | 12.3 MiB | 12.3 MiB |
| `lib/arm64-v8a/libflutter.so` | 11.0 MiB | 11.0 MiB |
| `lib/armeabi-v7a/libapp.so` | 9.8 MiB | 9.8 MiB |
| `lib/x86_64/libapp.so` | 9.1 MiB | 9.1 MiB |
| `lib/arm64-v8a/libapp.so` | 8.8 MiB | 8.8 MiB |
| `lib/armeabi-v7a/libflutter.so` | 8.1 MiB | 8.1 MiB |
| `classes.dex` | 2.6 MiB | 7.6 MiB |
| `assets/flutter_assets/assets/data_webapp/pokemon.json` | 335.9 KiB | 2.4 MiB |
| `assets/flutter_assets/AssetManifest.bin` | 82.0 KiB | 978.8 KiB |
| `assets/flutter_assets/assets/textures/trainers/onboarding_professor.png` | 936.8 KiB | 936.8 KiB |
| `assets/flutter_assets/assets/data_webapp/moves.json` | 94.9 KiB | 629.5 KiB |
| `assets/flutter_assets/assets/textures/textures_webapp/pokemon/hippowdon/main-f.png` | 471.1 KiB | 471.1 KiB |
| `assets/flutter_assets/assets/textures/textures_webapp/pokemon/hippowdon/main-f-shiny.png` | 446.2 KiB | 446.2 KiB |
| `assets/flutter_assets/assets/textures/textures_webapp/pokemon/pikachu/main-f-shiny.png` | 445.6 KiB | 445.6 KiB |
| `assets/flutter_assets/assets/textures/textures_webapp/pokemon/pikachu/main-f.png` | 429.5 KiB | 429.5 KiB |
| `assets/flutter_assets/assets/textures/textures_webapp/pokemon/wobbuffet/main-f.png` | 422.7 KiB | 422.7 KiB |
| `assets/flutter_assets/assets/textures/textures_webapp/pokemon/raichu/main-f-shiny.png` | 387.8 KiB | 387.8 KiB |
| `assets/flutter_assets/assets/textures/textures_webapp/pokemon/raichu/main-f.png` | 358.3 KiB | 358.3 KiB |
| `assets/flutter_assets/assets/textures/textures_webapp/pokemon/unfezant/main-f-shiny.png` | 338.8 KiB | 338.8 KiB |
| `assets/flutter_assets/assets/textures/textures_webapp/pokemon/wobbuffet/main-f-shiny.png` | 336.2 KiB | 336.2 KiB |

## Android release AAB

- Archive size: **384.8 MiB** (403457066 bytes)
- ZIP entries: **8647**
- Compressed payload: **382.9 MiB**
- Uncompressed payload: **480.7 MiB**
- Embedded legal files: **`GPL-3.0.txt`, `NOTICE.txt`**

### Bundled Flutter asset families

| Family | Files | Compressed | Uncompressed |
|---|---:|---:|---:|
| `assets/textures/textures_webapp/pokemon` | 4687 | 300.5 MiB | 303.2 MiB |
| `assets/textures/pokemons` | 861 | 17.7 MiB | 17.8 MiB |
| `assets/data_webapp` | 11 | 505.3 KiB | 3.6 MiB |
| `assets/data` | 1645 | 1.1 MiB | 3.0 MiB |
| `assets/textures/trainers` | 5 | 1.5 MiB | 1.5 MiB |
| `assets/textures/gui` | 105 | 427.2 KiB | 532.7 KiB |
| `assets/textures/sprites` | 860 | 502.2 KiB | 502.8 KiB |
| `assets/textures/textures_webapp/items` | 316 | 373.7 KiB | 374.7 KiB |
| `assets/textures/type_names` | 18 | 44.4 KiB | 44.4 KiB |
| `assets/textures/textures_webapp/pokemon_transforms` | 1 | 337 B | 778 B |

### Largest archive entries

| Entry | Compressed | Uncompressed |
|---|---:|---:|
| `BUNDLE-METADATA/com.android.tools.build.debugsymbols/arm64-v8a/libflutter.so.sym` | 6.4 MiB | 17.7 MiB |
| `BUNDLE-METADATA/com.android.tools.build.debugsymbols/x86_64/libflutter.so.sym` | 6.2 MiB | 16.8 MiB |
| `BUNDLE-METADATA/com.android.tools.build.debugsymbols/armeabi-v7a/libflutter.so.sym` | 5.5 MiB | 13.0 MiB |
| `base/lib/x86_64/libflutter.so` | 5.3 MiB | 12.3 MiB |
| `base/lib/arm64-v8a/libflutter.so` | 5.2 MiB | 11.0 MiB |
| `BUNDLE-METADATA/com.android.tools.build.debugsymbols/armeabi-v7a/libapp.so.sym` | 4.2 MiB | 10.8 MiB |
| `BUNDLE-METADATA/com.android.tools.build.debugsymbols/x86_64/libapp.so.sym` | 3.9 MiB | 10.3 MiB |
| `BUNDLE-METADATA/com.android.tools.build.debugsymbols/arm64-v8a/libapp.so.sym` | 3.9 MiB | 10.0 MiB |
| `base/lib/armeabi-v7a/libapp.so` | 4.0 MiB | 9.8 MiB |
| `base/lib/x86_64/libapp.so` | 3.6 MiB | 9.1 MiB |
| `base/lib/arm64-v8a/libapp.so` | 3.6 MiB | 8.8 MiB |
| `base/lib/armeabi-v7a/libflutter.so` | 4.5 MiB | 8.1 MiB |
| `base/dex/classes.dex` | 2.6 MiB | 7.6 MiB |
| `base/assets/flutter_assets/assets/data_webapp/pokemon.json` | 335.9 KiB | 2.4 MiB |
| `META-INF/FOOTPRIN.SF` | 363.6 KiB | 1.3 MiB |
| `META-INF/MANIFEST.MF` | 361.6 KiB | 1.3 MiB |
| `base/assets/flutter_assets/AssetManifest.bin` | 82.0 KiB | 978.8 KiB |
| `base/assets/flutter_assets/assets/textures/trainers/onboarding_professor.png` | 933.2 KiB | 936.8 KiB |
| `base/assets/flutter_assets/assets/data_webapp/moves.json` | 94.9 KiB | 629.5 KiB |
| `base/assets/flutter_assets/assets/textures/textures_webapp/pokemon/hippowdon/main-f.png` | 467.3 KiB | 471.1 KiB |

## Largest exact duplicate groups

| Reclaimable | Copies | Single file | Families | Example paths |
|---:|---:|---:|---|---|
| 1.3 MiB | 15 | 97.9 KiB | assets/textures/textures_webapp/pokemon | `assets/textures/textures_webapp/pokemon/minior-core-blue/main-shiny.png`<br>`assets/textures/textures_webapp/pokemon/minior-core-green/main-shiny.png`<br>`assets/textures/textures_webapp/pokemon/minior-core-indigo/main-shiny.png`<br>`assets/textures/textures_webapp/pokemon/minior-core-orange/main-shiny.png`<br>… and 11 more |
| 200.7 KiB | 3 | 100.3 KiB | assets/textures/textures_webapp/pokemon | `assets/textures/textures_webapp/pokemon/minior-core-red/main.png`<br>`assets/textures/textures_webapp/pokemon/minior-core/main-red.png`<br>`assets/textures/textures_webapp/pokemon/minior-core/main.png` |
| 170.4 KiB | 2 | 170.4 KiB | assets/textures/textures_webapp/pokemon | `assets/textures/textures_webapp/pokemon/darmanitan-galar-standard/main-shiny.png`<br>`assets/textures/textures_webapp/pokemon/galarian-darmanitan/main-shiny.png` |
| 149.9 KiB | 2 | 149.9 KiB | assets/textures/textures_webapp/pokemon | `assets/textures/textures_webapp/pokemon/hippowdon/main-m-shiny.png`<br>`assets/textures/textures_webapp/pokemon/hippowdon/main-shiny.png` |
| 146.1 KiB | 2 | 146.1 KiB | assets/textures/textures_webapp/pokemon | `assets/textures/textures_webapp/pokemon/hippopotas/main-m-shiny.png`<br>`assets/textures/textures_webapp/pokemon/hippopotas/main-shiny.png` |
| 139.6 KiB | 2 | 139.6 KiB | assets/textures/textures_webapp/pokemon | `assets/textures/textures_webapp/pokemon/minior-core-blue/main.png`<br>`assets/textures/textures_webapp/pokemon/minior-core/main-blue.png` |
| 133.9 KiB | 2 | 133.9 KiB | assets/textures/textures_webapp/pokemon | `assets/textures/textures_webapp/pokemon/hippowdon/main-m.png`<br>`assets/textures/textures_webapp/pokemon/hippowdon/main.png` |
| 131.8 KiB | 2 | 131.8 KiB | assets/textures/textures_webapp/pokemon | `assets/textures/textures_webapp/pokemon/minior-meteor-form/main-shiny.png`<br>`assets/textures/textures_webapp/pokemon/minior/main-shiny.png` |
| 125.1 KiB | 2 | 125.1 KiB | assets/textures/textures_webapp/pokemon | `assets/textures/textures_webapp/pokemon/minior-meteor-form/main.png`<br>`assets/textures/textures_webapp/pokemon/minior/main.png` |
| 122.1 KiB | 2 | 122.1 KiB | assets/textures/textures_webapp/pokemon | `assets/textures/textures_webapp/pokemon/wobbuffet/main-m-shiny.png`<br>`assets/textures/textures_webapp/pokemon/wobbuffet/main-shiny.png` |
| 122.0 KiB | 2 | 122.0 KiB | assets/textures/textures_webapp/pokemon | `assets/textures/textures_webapp/pokemon/hippopotas/main-m.png`<br>`assets/textures/textures_webapp/pokemon/hippopotas/main.png` |
| 118.3 KiB | 2 | 118.3 KiB | assets/textures/textures_webapp/pokemon | `assets/textures/textures_webapp/pokemon/wobbuffet/main-m.png`<br>`assets/textures/textures_webapp/pokemon/wobbuffet/main.png` |
| 116.8 KiB | 2 | 116.8 KiB | assets/textures/textures_webapp/pokemon | `assets/textures/textures_webapp/pokemon/unfezant/main-m.png`<br>`assets/textures/textures_webapp/pokemon/unfezant/main.png` |
| 115.3 KiB | 2 | 115.3 KiB | assets/textures/textures_webapp/pokemon | `assets/textures/textures_webapp/pokemon/pikachu/main-m.png`<br>`assets/textures/textures_webapp/pokemon/pikachu/main.png` |
| 114.8 KiB | 2 | 114.8 KiB | assets/textures/textures_webapp/pokemon | `assets/textures/textures_webapp/pokemon/pikachu/main-m-shiny.png`<br>`assets/textures/textures_webapp/pokemon/pikachu/main-shiny.png` |
| 112.6 KiB | 2 | 112.6 KiB | assets/textures/textures_webapp/pokemon | `assets/textures/textures_webapp/pokemon/unfezant/main-m-shiny.png`<br>`assets/textures/textures_webapp/pokemon/unfezant/main-shiny.png` |
| 111.1 KiB | 2 | 111.1 KiB | assets/textures/textures_webapp/pokemon | `assets/textures/textures_webapp/pokemon/minior-core-green/main.png`<br>`assets/textures/textures_webapp/pokemon/minior-core/main-green.png` |
| 107.4 KiB | 2 | 107.4 KiB | assets/textures/textures_webapp/pokemon | `assets/textures/textures_webapp/pokemon/minior-core-violet/main.png`<br>`assets/textures/textures_webapp/pokemon/minior-core/main-violet.png` |
| 106.2 KiB | 2 | 106.2 KiB | assets/textures/textures_webapp/pokemon | `assets/textures/textures_webapp/pokemon/raichu/main-m-shiny.png`<br>`assets/textures/textures_webapp/pokemon/raichu/main-shiny.png` |
| 103.5 KiB | 2 | 103.5 KiB | assets/textures/textures_webapp/pokemon | `assets/textures/textures_webapp/pokemon/minior-core-orange/main.png`<br>`assets/textures/textures_webapp/pokemon/minior-core/main-orange.png` |

## Interpretation and next safe actions

1. Prioritise duplicate groups that cross legacy and web-app families, because they offer measurable savings without inventing new artwork.
2. Do not delete a path until all static and dynamically constructed references have been mapped and tested.
3. Measure a second release after each removal batch; ZIP compression means source-byte savings and AAB savings will differ.
4. Keep the generated GPL and NOTICE assets embedded in Flutter archives and the source documents beside downloadable releases.
5. Treat rights clearance separately from size optimisation: identical files can still have unverified redistribution terms.

The complete duplicate inventory is stored in `docs/performance/asset-duplicates.csv`.
