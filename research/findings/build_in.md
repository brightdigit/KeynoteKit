# Experiment 5 — build present vs absent (one Build In)

**Fixtures:** `fixtures/build_in_A.key` (untouched copy of `builds_base`, no
animation) vs `fixtures/build_in_B.key` (same deck + one **Build In = Dissolve**
on "Item 1", default timing, added by hand in the Animate inspector).
**Pair diffed:** `findings/build_in/` (run: `run_experiment.py build_in
--skip-generate --a fixtures/build_in_A.key --b fixtures/build_in_B.key`).

This is the Phase-2 analogue of Exp 1 (transition present/absent): it localizes
where a build lives and what a single build adds to the file.

## Which component changed

The real signal is in **`Index/Slide-2652176.iwa.yaml`** (the `KN.SlideArchive`
for the one content slide) and **`Index/Document.iwa.yaml`** (the per-slide cache
node). Everything else changed is the characterized noise
(`CalculationEngine`, `DocumentMetadata`, `DocumentStylesheet`, `Metadata`,
`ViewState` rename). Note the slide component is named `Slide-<id>.iwa.yaml`
here (not the transition-era `Slide.iwa.yaml`) — same archive, different file
naming from this deck's master layout.

## What a build adds to the slide archive

Adding one Build In introduces **two new archived objects** and **two new keys**
on `KN.SlideArchive`.

### 1. New keys on `KN.SlideArchive` (siblings of `drawablesZOrder`)

```
buildChunks:
- identifier: <id>      # -> KN.BuildChunkArchive
builds:
- identifier: <id>      # -> KN.BuildArchive
```

So a slide holds two parallel collections: `builds` (the effect definitions) and
`buildChunks` (their timing/sequencing units). Both are **lists** — this matters
for ordering (see Exp 6, `build_order.md`).

### 2. `KN.BuildArchive` — the effect definition

```
_pbtype: KN.BuildArchive
attributes:
  ChartRotation3D: 60.0
  animationAttributes:
    animationType: In                 # In == Build-In (cf. Transition slide-transition, presumably Out/Action)
    delay: 0.0
    duration: 1.0
    effect: apple:dissolve character   # build effect enum (see build_fx.md)
    randomNumberSeed: <volatile>
    writingDirectionIsRtl: false
  customDeliveryOption: kDeliveryOptionForward
  customTextDelivery: kTextDeliveryByObject
  eventTrigger: 1                      # 1 == On Click (start trigger)
chunkIdSeed: 1
delivery: All at Once
drawable:
  identifier: '2652601'               # <-- TARGET OBJECT, by drawable id (Item 1)
duration: 0.0
```

Key facts:
- **`animationAttributes` is the same shape as a slide transition's** (Exp 2/3):
  `animationType` / `effect` / `duration` / `delay` / `randomNumberSeed` /
  `writingDirectionIsRtl`. The discriminator is `animationType: In` (transitions
  use `Transition`). Build effect/duration/delay live here, exactly mirroring the
  transition model.
- **The build references its target object by `drawable.identifier`** — a plain
  drawable id. Here `2652601`, which is "Item 1" (cross-confirmed in Exp 6:
  drawable `2652601` is the first-built object in `build_order_A`, where Item 1
  was built first). Unlike Magic Move (Exp 4, no persisted correspondence), a
  build **does** persist an explicit object reference.
- `eventTrigger: 1` encodes the start trigger (On Click). `delivery` /
  `customTextDelivery` / `customDeliveryOption` are text-delivery knobs
  (granularity + order), catalogued in `build_fx.md`.

### 3. `KN.BuildChunkArchive` — the timing / sequencing unit

```
_pbtype: KN.BuildChunkArchive
automatic: false                       # false == On Click; true == auto (After Previous/With)
build:
  identifier: <volatile>               # back-reference to its KN.BuildArchive
buildChunkIdentifier:
  buildChunkId: 1
  buildId: {lower: <id>, upper: <id>}  # 64-bit build id, split lo/hi (volatile, regenerated per save)
buildId: {lower: <id>, upper: <id>}
delay: 0.0
duration: 1.0                          # MIRRORS animationAttributes.duration (see build_fx.md)
referent: true
```

The chunk carries the *runtime* timing (`automatic`, `delay`, `duration`) and a
64-bit `buildId` pair. `duration` is duplicated here and in the BuildArchive's
`animationAttributes` (both move together — Exp 7).

## Document cache flip (derived, not source of truth)

`Index/Document.iwa.yaml` `KN.SlideNodeArchive` for this slide:

```
-      buildEventCountCacheVersion: 4294967295
+      buildEventCount: 1
+      buildEventCountCacheVersion: 2
       hasBuilds: false
-      hasExplicitBuilds: false
+      hasExplicitBuilds: true
```

`hasExplicitBuilds: false -> true` (predicted in `builds_setup.md`) plus a
derived `buildEventCount: 1`. These are **caches** mirroring the slide archive,
like `hasTransition` — source of truth is the `builds`/`buildChunks` on the
slide. (`hasBuilds` stays `false`; it appears to track a different, non-explicit
notion of builds and is not the flag to author.)

## Conclusion

A build = one `KN.BuildArchive` (effect, in the transition-shaped
`animationAttributes`, targeting an object by `drawable.identifier`) + one
`KN.BuildChunkArchive` (timing/sequence), both referenced from new `builds` /
`buildChunks` lists on `KN.SlideArchive`. `Document` flips
`hasExplicitBuilds -> true` as a cache. The build's object reference **is**
persisted (unlike Magic Move), so the `Deck` build model can carry an explicit
target ref rather than relying on a runtime matcher.
