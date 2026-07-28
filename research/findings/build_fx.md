# Experiment 7 — build effect & timing sweep

**Fixtures:** two copies of `builds_base`, one Build In on **Item 1** each:
- `fixtures/build_fx_A.key` — **Dissolve**, default timing.
- `fixtures/build_fx_B.key` — **Move In**, with several non-default knobs
  (duration 0.5, by-paragraph / by-character delivery, random order, bounce).
  Reference screenshot: `fixtures/build_fx_B-Item-1-Move-In.png`.

**Pair diffed:** `findings/build_fx/` (run: `run_experiment.py build_fx
--skip-generate --a ... --b ...`). Both slides already have a build, so
`Document`'s `hasExplicitBuilds` is `true` in both (no cache flip); the entire
signal is inside the build records on `Index/Slide-*.iwa.yaml`.

## The delta (Dissolve default vs Move In modified)

```
         animationAttributes:
           animationType: In
           delay: 0.0
-          duration: 1.0
+          direction: 13                       # NEW: Move In has a direction
+          duration: 0.5
-          effect: apple:dissolve character
+          effect: apple:move in character     # build effect enum string
           randomNumberSeed: <vol>
           writingDirectionIsRtl: false
-        customDeliveryOption: kDeliveryOptionForward
+        customBounce: true                     # NEW: per-effect option
+        customDeliveryOption: kDeliveryOptionRandom
-        customTextDelivery: kTextDeliveryByObject
+        customTextDelivery: kTextDeliveryByCharacter
         eventTrigger: 1
       ...
-      delivery: All at Once
+      delivery: By Paragraph
...
   # in the paired KN.BuildChunkArchive:
-      duration: 1.0
+      duration: 0.5                            # chunk duration MIRRORS animationAttributes.duration
```

## Fields isolated

| Field | Location | Meaning | Notes |
|---|---|---|---|
| `effect` | `animationAttributes` | build effect enum (string) | `apple:dissolve character`, `apple:move in character` |
| `duration` | `animationAttributes` **and** `KN.BuildChunkArchive.duration` | seconds | duplicated; both moved 1.0 -> 0.5 together |
| `delay` | `animationAttributes` (and chunk) | seconds | unchanged here (0.0) |
| `direction` | `animationAttributes` | directional enum | **only present for directional effects** (Move In = `13`); absent for Dissolve |
| `customBounce` | `attributes` | per-effect bool | Move-In option; absent for Dissolve |
| `customTextDelivery` | `attributes` | `kTextDeliveryByObject` / `ByCharacter` | text granularity |
| `customDeliveryOption` | `attributes` | `kDeliveryOptionForward` / `Random` | delivery order within the object |
| `delivery` | `KN.BuildArchive` | `All at Once` / `By Paragraph` | human-readable delivery mode |

## The build effect enum

Build effects use the **same `apple:*` namespace as transitions**, but they are
**distinct strings** — note the ` character` suffix on the text-build variants:

| Build effect (inspector) | archive `effect` string |
|---|---|
| Dissolve | `apple:dissolve character` |
| Move In | `apple:move in character` |

The ` character` suffix appears on both; it likely marks the text-capable build
variant (these builds are on text objects) rather than a per-effect distinction.
**Open item:** re-run on a non-text object (image/shape) to see whether the
suffix drops — that tells us if the enum is object-type-qualified. Regardless, the
mapping is name -> archive-string, exactly like the transition `EFFECTS` table.

## `direction` — bonus: the field transitions wouldn't expose

Transition **direction** was the one un-scriptable, un-serialized transition
unknown (`duration_direction.md`): at default it is proto3-omitted and there is
no AppleScript setter. Builds serialize it explicitly (`direction: 13` for Move
In). Same `animationAttributes` struct, so this is strong evidence the transition
`direction` field exists in the same slot and only *appears* absent because it is
proto-default-omitted. A directional-transition golden fixture should now be able
to confirm the transition side uses the same integer enum.

## Conclusion

Build effect = `animationAttributes.effect` (an `apple:*` string enum, distinct
from transition strings). Timing = `duration`/`delay` in `animationAttributes`,
with `duration` mirrored into the `KN.BuildChunkArchive`. Directional builds add
`direction` (int enum); per-effect options ride as `custom*` keys on
`attributes`; text delivery is `delivery` + `customTextDelivery` +
`customDeliveryOption`. Start trigger is `eventTrigger` (BuildArchive) /
`automatic` (BuildChunkArchive). This mirrors the transition model closely enough
that the `Deck` `Build` reuses the same effect+timing shape (see
`deck_model_notes.md`).
