# Runtime and catalog performance baseline

This document defines the repeatable runtime measurements used before and after
catalog optimisations. Archive size remains covered separately by
`release-footprint.md`.

## Automated CI baseline

The Flutter CI workflow runs:

```text
flutter test tool/performance/catalog_runtime_benchmark.dart --reporter expanded
```

The benchmark measures Italian and English independently after clearing every
catalog cache. It records:

- complete Pokémon catalog load;
- 830-move catalog load;
- 330-ability catalog load;
- item and TM catalog load;
- 36-feat catalog load;
- the same sequence from new repository instances with warm shared caches.

Each result is emitted as one JSON line prefixed with
`CATALOG_RUNTIME_BASELINE` and uploaded in `catalog-performance-log`. CI values
are useful for regression comparisons but are not presented as Android device
times.

## Android profile baseline

Profile or debug captures expose these timeline events:

| Event | Start | End |
|---|---|---|
| `app.cold_start` | entry into `main()` | first rendered Flutter frame |
| `home.dashboard.load` | Home dashboard refresh starts | Home data is usable |
| `catalog.pokemon.load` | uncached Pokémon load starts | merged catalog is ready |
| `catalog.moves.load` | uncached move load starts | localized catalog is ready |
| `catalog.abilities.load` | uncached ability load starts | localized catalog is ready |
| `catalog.items.load` | uncached item load starts | items and TMs are ready |

Debug builds also print the same measurements as JSON lines prefixed with
`TRAINER_ATLAS_PERF`, so an Android `logcat` capture can be archived without
manually timing the interface.

For comparable device runs:

1. record device model, Android version, app commit and selected language;
2. force-stop the app before every cold-start sample;
3. run at least five samples without changing battery or thermal conditions;
4. report the median and slowest sample;
5. repeat catalog openings once more without restarting to capture warm-cache
   behaviour.

## Acceptance criteria

- no catalog is parsed twice when different screens create separate repository
  instances under the same locale;
- concurrent callers share the same in-flight Pokémon load;
- switching locale invalidates locale-sensitive runtime caches;
- performance tests never fail on a fixed millisecond threshold, because CI
  hosts and physical devices are not comparable;
- optimisations must preserve complete catalog counts and offline behaviour.
