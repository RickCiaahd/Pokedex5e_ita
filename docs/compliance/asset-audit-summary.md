# Asset audit summary

This report scans every file below `assets/` and records path, size, SHA-256, policy family, and nearby attribution/licence evidence.
The presence of an attribution file does not prove that redistribution is authorised.

- Asset files: **8539**
- Total asset size: **318.6 MiB**
- Files with nearby attribution/licence evidence: **2**
- Files without nearby evidence: **8537**

## Policy status

| Status | Files |
|---|---:|
| not-cleared | 6441 |
| mixed | 1643 |
| unverified | 432 |
| project-created-pending-proof | 23 |

## Families

| Family | Files | Size | With evidence |
|---|---:|---:|---:|
| `assets/data` | 1643 | 3.0 MiB | 0 |
| `assets/data_webapp` | 11 | 3.6 MiB | 0 |
| `assets/textures/gui` | 105 | 532.7 KiB | 0 |
| `assets/textures/pokemons` | 861 | 17.8 MiB | 0 |
| `assets/textures/sprites` | 860 | 502.8 KiB | 0 |
| `assets/textures/textures_webapp/items` | 316 | 374.7 KiB | 2 |
| `assets/textures/textures_webapp/pokemon` | 4719 | 291.3 MiB | 0 |
| `assets/textures/textures_webapp/pokemon_transforms` | 1 | 778 B | 0 |
| `assets/textures/trainers` | 5 | 1.5 MiB | 0 |
| `assets/textures/type_names` | 18 | 44.4 KiB | 0 |

## Machine-readable inventory

The complete file-level report is stored in `docs/compliance/asset-manifest.csv`.
A public build must not treat `unverified`, `not-cleared`, `mixed`, or `unclassified` as permission to redistribute.
