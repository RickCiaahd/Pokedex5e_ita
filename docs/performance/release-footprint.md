# Release footprint audit

This report is generated from release APK/AAB archives and an exact SHA-256 scan of every file below `assets/`.
It measures size and byte-identical duplication; it does not by itself prove that an asset is unused or safe to remove.

- Pinned Flutter version: **3.44.4**
- Flutter revision: `ad70ec4617166f1c38e5d2bfd388af71fda14f06`
- Asset files scanned: **8949**
- Source asset size: **253.9 MiB**
- Exact duplicate groups: **41**
- Redundant copies: **42**
- Theoretical maximum reclaimable bytes: **1.9 MiB**
- Duplicate groups spanning multiple policy families: **0**

The theoretical saving assumes one copy per identical hash and ignores path compatibility, runtime lookup rules and compression effects.

## Android release APK

- Archive size: **315.1 MiB** (330396222 bytes)
- ZIP entries: **9071**
- Compressed payload: **313.1 MiB**
- Uncompressed payload: **324.5 MiB**
- Embedded legal files: **`GPL-3.0.txt`, `NOTICE.txt`**

### Bundled Flutter asset families

| Family | Files | Compressed | Uncompressed |
|---|---:|---:|---:|
| `assets/textures/textures_webapp/pokemon` | 4823 | 194.0 MiB | 194.0 MiB |
| `assets/textures/textures_webapp/pokemon_transforms` | 263 | 31.1 MiB | 31.1 MiB |
| `assets/textures/pokemons` | 878 | 18.4 MiB | 18.4 MiB |
| `assets/data_webapp` | 11 | 505.3 KiB | 3.6 MiB |
| `assets/data` | 1647 | 1.1 MiB | 3.1 MiB |
| `assets/textures/trainers` | 6 | 2.3 MiB | 2.3 MiB |
| `assets/textures/gui` | 105 | 532.7 KiB | 532.7 KiB |
| `assets/textures/sprites` | 860 | 502.8 KiB | 502.8 KiB |
| `assets/textures/textures_webapp/items` | 316 | 374.7 KiB | 374.7 KiB |
| `assets/textures/type_names` | 36 | 82.3 KiB | 82.3 KiB |

### Largest archive entries

| Entry | Compressed | Uncompressed |
|---|---:|---:|
| `lib/x86_64/libflutter.so` | 12.3 MiB | 12.3 MiB |
| `lib/arm64-v8a/libflutter.so` | 11.0 MiB | 11.0 MiB |
| `lib/armeabi-v7a/libapp.so` | 10.3 MiB | 10.3 MiB |
| `lib/x86_64/libapp.so` | 9.6 MiB | 9.6 MiB |
| `lib/arm64-v8a/libapp.so` | 9.4 MiB | 9.4 MiB |
| `lib/armeabi-v7a/libflutter.so` | 8.1 MiB | 8.1 MiB |
| `classes.dex` | 2.6 MiB | 7.6 MiB |
| `assets/flutter_assets/assets/data_webapp/pokemon.json` | 335.9 KiB | 2.4 MiB |
| `assets/flutter_assets/AssetManifest.bin` | 86.4 KiB | 1.0 MiB |
| `assets/flutter_assets/assets/textures/trainers/onboarding_professor.png` | 936.8 KiB | 936.8 KiB |
| `assets/flutter_assets/assets/textures/trainers/trainer_atlas_logo.png` | 803.6 KiB | 803.6 KiB |
| `assets/flutter_assets/assets/data_webapp/moves.json` | 94.9 KiB | 629.5 KiB |
| `org/apache/tika/mime/tika-mimetypes.xml` | 47.5 KiB | 320.0 KiB |
| `assets/flutter_assets/assets/textures/trainers/trainers.png` | 318.7 KiB | 318.7 KiB |
| `assets/flutter_assets/assets/textures/textures_webapp/pokemon/pikachu/main-f-shiny.webp` | 285.0 KiB | 285.0 KiB |
| `assets/flutter_assets/assets/textures/textures_webapp/pokemon/pikachu/main-f.webp` | 273.9 KiB | 273.9 KiB |
| `assets/flutter_assets/assets/textures/textures_webapp/pokemon/hippowdon/main-f.webp` | 271.2 KiB | 271.2 KiB |
| `assets/flutter_assets/assets/textures/textures_webapp/pokemon/wobbuffet/main-f.webp` | 261.1 KiB | 261.1 KiB |
| `assets/flutter_assets/assets/textures/textures_webapp/pokemon/hippowdon/main-f-shiny.webp` | 259.6 KiB | 259.6 KiB |
| `assets/flutter_assets/packages/cupertino_icons/assets/CupertinoIcons.ttf` | 113.2 KiB | 251.6 KiB |

## Android release AAB

- Archive size: **312.3 MiB** (327445883 bytes)
- ZIP entries: **9089**
- Compressed payload: **310.2 MiB**
- Uncompressed payload: **407.8 MiB**
- Embedded legal files: **`GPL-3.0.txt`, `NOTICE.txt`**

### Bundled Flutter asset families

| Family | Files | Compressed | Uncompressed |
|---|---:|---:|---:|
| `assets/textures/textures_webapp/pokemon` | 4823 | 193.9 MiB | 194.0 MiB |
| `assets/textures/textures_webapp/pokemon_transforms` | 263 | 30.9 MiB | 31.1 MiB |
| `assets/textures/pokemons` | 878 | 18.4 MiB | 18.4 MiB |
| `assets/data_webapp` | 11 | 505.3 KiB | 3.6 MiB |
| `assets/data` | 1647 | 1.1 MiB | 3.1 MiB |
| `assets/textures/trainers` | 6 | 2.3 MiB | 2.3 MiB |
| `assets/textures/gui` | 105 | 427.2 KiB | 532.7 KiB |
| `assets/textures/sprites` | 860 | 502.2 KiB | 502.8 KiB |
| `assets/textures/textures_webapp/items` | 316 | 373.7 KiB | 374.7 KiB |
| `assets/textures/type_names` | 36 | 82.5 KiB | 82.3 KiB |

### Largest archive entries

| Entry | Compressed | Uncompressed |
|---|---:|---:|
| `BUNDLE-METADATA/com.android.tools.build.debugsymbols/arm64-v8a/libflutter.so.sym` | 6.4 MiB | 17.7 MiB |
| `BUNDLE-METADATA/com.android.tools.build.debugsymbols/x86_64/libflutter.so.sym` | 6.2 MiB | 16.8 MiB |
| `BUNDLE-METADATA/com.android.tools.build.debugsymbols/armeabi-v7a/libflutter.so.sym` | 5.5 MiB | 13.0 MiB |
| `base/lib/x86_64/libflutter.so` | 5.3 MiB | 12.3 MiB |
| `BUNDLE-METADATA/com.android.tools.build.debugsymbols/armeabi-v7a/libapp.so.sym` | 4.5 MiB | 11.4 MiB |
| `base/lib/arm64-v8a/libflutter.so` | 5.2 MiB | 11.0 MiB |
| `BUNDLE-METADATA/com.android.tools.build.debugsymbols/x86_64/libapp.so.sym` | 4.1 MiB | 10.8 MiB |
| `BUNDLE-METADATA/com.android.tools.build.debugsymbols/arm64-v8a/libapp.so.sym` | 4.1 MiB | 10.6 MiB |
| `base/lib/armeabi-v7a/libapp.so` | 4.2 MiB | 10.3 MiB |
| `base/lib/x86_64/libapp.so` | 3.8 MiB | 9.6 MiB |
| `base/lib/arm64-v8a/libapp.so` | 3.8 MiB | 9.4 MiB |
| `base/lib/armeabi-v7a/libflutter.so` | 4.5 MiB | 8.1 MiB |
| `base/dex/classes.dex` | 2.6 MiB | 7.6 MiB |
| `base/assets/flutter_assets/assets/data_webapp/pokemon.json` | 335.9 KiB | 2.4 MiB |
| `META-INF/FOOTPRIN.SF` | 383.2 KiB | 1.3 MiB |
| `META-INF/MANIFEST.MF` | 381.4 KiB | 1.3 MiB |
| `base/assets/flutter_assets/AssetManifest.bin` | 86.4 KiB | 1.0 MiB |
| `base/assets/flutter_assets/assets/textures/trainers/onboarding_professor.png` | 933.2 KiB | 936.8 KiB |
| `base/assets/flutter_assets/assets/textures/trainers/trainer_atlas_logo.png` | 803.8 KiB | 803.6 KiB |
| `base/assets/flutter_assets/assets/data_webapp/moves.json` | 94.9 KiB | 629.5 KiB |

## Largest exact duplicate groups

| Reclaimable | Copies | Single file | Families | Example paths |
|---:|---:|---:|---|---|
| 197.8 KiB | 2 | 197.8 KiB | assets/textures/textures_webapp/pokemon_transforms | `assets/textures/textures_webapp/pokemon_transforms/gigamax/toxtricity-amped-gmax-shiny.png`<br>`assets/textures/textures_webapp/pokemon_transforms/gigamax/toxtricity-low-key-gmax-shiny.png` |
| 172.3 KiB | 2 | 172.3 KiB | assets/textures/textures_webapp/pokemon_transforms | `assets/textures/textures_webapp/pokemon_transforms/gigamax/toxtricity-amped-gmax.png`<br>`assets/textures/textures_webapp/pokemon_transforms/gigamax/toxtricity-low-key-gmax.png` |
| 165.7 KiB | 2 | 165.7 KiB | assets/textures/textures_webapp/pokemon_transforms | `assets/textures/textures_webapp/pokemon_transforms/gigamax/appletun-gmax-shiny.png`<br>`assets/textures/textures_webapp/pokemon_transforms/gigamax/flapple-gmax-shiny.png` |
| 107.2 KiB | 2 | 107.2 KiB | assets/textures/textures_webapp/pokemon | `assets/textures/textures_webapp/pokemon/darmanitan-galar-standard/main-shiny.webp`<br>`assets/textures/textures_webapp/pokemon/galarian-darmanitan/main-shiny.webp` |
| 90.7 KiB | 2 | 90.7 KiB | assets/textures/textures_webapp/pokemon_transforms | `assets/textures/textures_webapp/pokemon_transforms/mega/meowstic-female-mega-shiny.png`<br>`assets/textures/textures_webapp/pokemon_transforms/mega/meowstic-male-mega-shiny.png` |
| 85.2 KiB | 2 | 85.2 KiB | assets/textures/textures_webapp/pokemon | `assets/textures/textures_webapp/pokemon/hippowdon/main-m-shiny.webp`<br>`assets/textures/textures_webapp/pokemon/hippowdon/main-shiny.webp` |
| 85.0 KiB | 2 | 85.0 KiB | assets/textures/textures_webapp/pokemon | `assets/textures/textures_webapp/pokemon/hippowdon/main-m.webp`<br>`assets/textures/textures_webapp/pokemon/hippowdon/main.webp` |
| 78.1 KiB | 2 | 78.1 KiB | assets/textures/textures_webapp/pokemon | `assets/textures/textures_webapp/pokemon/hippopotas/main-m.webp`<br>`assets/textures/textures_webapp/pokemon/hippopotas/main.webp` |
| 77.9 KiB | 2 | 77.9 KiB | assets/textures/textures_webapp/pokemon | `assets/textures/textures_webapp/pokemon/pikachu/main-m-shiny.webp`<br>`assets/textures/textures_webapp/pokemon/pikachu/main-shiny.webp` |
| 76.9 KiB | 2 | 76.9 KiB | assets/textures/textures_webapp/pokemon | `assets/textures/textures_webapp/pokemon/hippopotas/main-m-shiny.webp`<br>`assets/textures/textures_webapp/pokemon/hippopotas/main-shiny.webp` |
| 74.1 KiB | 2 | 74.1 KiB | assets/textures/textures_webapp/pokemon | `assets/textures/textures_webapp/pokemon/minior-meteor-form/main.webp`<br>`assets/textures/textures_webapp/pokemon/minior/main.webp` |
| 73.9 KiB | 2 | 73.9 KiB | assets/textures/textures_webapp/pokemon | `assets/textures/textures_webapp/pokemon/wobbuffet/main-m.webp`<br>`assets/textures/textures_webapp/pokemon/wobbuffet/main.webp` |
| 72.8 KiB | 2 | 72.8 KiB | assets/textures/textures_webapp/pokemon | `assets/textures/textures_webapp/pokemon/unfezant/main-m-shiny.webp`<br>`assets/textures/textures_webapp/pokemon/unfezant/main-shiny.webp` |
| 72.3 KiB | 2 | 72.3 KiB | assets/textures/textures_webapp/pokemon | `assets/textures/textures_webapp/pokemon/pikachu/main-m.webp`<br>`assets/textures/textures_webapp/pokemon/pikachu/main.webp` |
| 71.5 KiB | 2 | 71.5 KiB | assets/textures/textures_webapp/pokemon | `assets/textures/textures_webapp/pokemon/unfezant/main-m.webp`<br>`assets/textures/textures_webapp/pokemon/unfezant/main.webp` |
| 64.9 KiB | 2 | 64.9 KiB | assets/textures/textures_webapp/pokemon | `assets/textures/textures_webapp/pokemon/wobbuffet/main-m-shiny.webp`<br>`assets/textures/textures_webapp/pokemon/wobbuffet/main-shiny.webp` |
| 64.3 KiB | 2 | 64.3 KiB | assets/textures/textures_webapp/pokemon | `assets/textures/textures_webapp/pokemon/minior-meteor-form/main-shiny.webp`<br>`assets/textures/textures_webapp/pokemon/minior/main-shiny.webp` |
| 59.7 KiB | 2 | 59.7 KiB | assets/textures/textures_webapp/pokemon | `assets/textures/textures_webapp/pokemon/darmanitan-galar-standard/main.webp`<br>`assets/textures/textures_webapp/pokemon/galarian-darmanitan/main.webp` |
| 58.1 KiB | 2 | 58.1 KiB | assets/textures/textures_webapp/pokemon | `assets/textures/textures_webapp/pokemon/raichu/main-m-shiny.webp`<br>`assets/textures/textures_webapp/pokemon/raichu/main-shiny.webp` |
| 56.5 KiB | 2 | 56.5 KiB | assets/textures/textures_webapp/pokemon | `assets/textures/textures_webapp/pokemon/raichu/main-m.webp`<br>`assets/textures/textures_webapp/pokemon/raichu/main.webp` |

## Interpretation and next safe actions

1. Prioritise duplicate groups that cross legacy and web-app families, because they offer measurable savings without inventing new artwork.
2. Do not delete a path until all static and dynamically constructed references have been mapped and tested.
3. Measure a second release after each removal batch; ZIP compression means source-byte savings and AAB savings will differ.
4. Keep the generated GPL and NOTICE assets embedded in Flutter archives and the source documents beside downloadable releases.
5. Treat rights clearance separately from size optimisation: identical files can still have unverified redistribution terms.

The complete duplicate inventory is stored in `docs/performance/asset-duplicates.csv`.
