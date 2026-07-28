# Public-safe asset profile

This report is generated from `pubspec.yaml` and the file-level compliance inventory.
It defines a reproducible build profile that excludes every asset currently marked `not-cleared` without deleting the private/full asset set from the repository.

- Full source inventory: **8539 files**, **332.1 MiB**
- Assets excluded from the public bundle: **6441 files**, **323.1 MiB**
- Assets still declared in the public profile: **2098 files**, **9.0 MiB**
- Source-size reduction before Flutter/native overhead: **97.3%**

The generated public pubspec is written below `build/public/` and is intentionally not committed. The normal `pubspec.yaml` remains the full private profile.

## Excluded roots

- `assets/textures/pokemons/`
- `assets/textures/sprites/`
- `assets/textures/textures_webapp/pokemon/`
- `assets/textures/textures_webapp/pokemon_transforms/`

## Family coverage

| Family | Excluded files | Excluded size | Remaining files | Remaining size |
|---|---:|---:|---:|---:|
| `assets/textures/textures_webapp/pokemon` | 4719 | 304.9 MiB | 0 | 0 B |
| `assets/textures/pokemons` | 861 | 17.8 MiB | 0 | 0 B |
| `assets/textures/sprites` | 860 | 502.8 KiB | 0 | 0 B |
| `assets/textures/textures_webapp/pokemon_transforms` | 1 | 778 B | 0 | 0 B |
| `assets/data_webapp` | 0 | 0 B | 11 | 3.6 MiB |
| `assets/data` | 0 | 0 B | 1643 | 3.0 MiB |
| `assets/textures/trainers` | 0 | 0 B | 5 | 1.5 MiB |
| `assets/textures/gui` | 0 | 0 B | 105 | 532.7 KiB |
| `assets/textures/textures_webapp/items` | 0 | 0 B | 316 | 374.7 KiB |
| `assets/textures/type_names` | 0 | 0 B | 18 | 44.4 KiB |

## Excluded artwork roles

The role classification is filename-based and is used only to estimate migration work; it is not proof that a file is reachable at runtime.

| Role | Files | Size |
|---|---:|---:|
| `shiny` | 2353 | 156.9 MiB |
| `standard-or-form` | 2336 | 145.0 MiB |
| `other-variant` | 1714 | 18.1 MiB |
| `gender-variant` | 38 | 3.1 MiB |

## Static and dynamic reference map

The complete source-level map is stored in `docs/performance/pokemon-artwork-references.csv`.

| Reference kind | Occurrences |
|---|---:|
| `test-contract` | 33 |
| `build-declaration` | 4 |
| `build-pipeline` | 4 |
| `tooling` | 4 |
| `runtime-dynamic` | 2 |
| `runtime-static` | 1 |

## Residual policy status

Excluding `not-cleared` files is a packaging safeguard, not a legal clearance. The remaining `mixed`, `unverified`, and `project-created-pending-proof` families still require provenance and licence work before publication.

| Status | Files in public profile |
|---|---:|
| `mixed` | 1643 |
| `unverified` | 432 |
| `project-created-pending-proof` | 23 |

## Build strategy

1. Generate a temporary public pubspec from the full source pubspec.
2. Remove only declarations rooted at the four blocked prefixes above; do not delete source assets.
3. Build APK/AAB in an isolated CI workspace so the normal private build remains unchanged.
4. Verify the produced archives contain no blocked paths and still embed GPL/NOTICE.
5. Exercise `PokemonAssetImage` with the filtered `AssetManifest`; missing artwork must resolve to the existing in-app fallback instead of throwing.
6. Replace the fallback with original, documented artwork only after authorship and redistribution terms are archived.
