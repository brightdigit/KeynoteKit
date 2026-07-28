# Experiment 3 — duration & direction

**Generator:** `generators/duration_sweep.applescript` (three decks in one
pass, effect fixed to `dissolve` so only timing varies).
**Pairs diffed:**
- `dur_duration/` — duration 0.5 vs 3.0 (delay held at 0.0)
- `dur_delay/` — delay 0.0 vs 2.0 (duration held at 0.5)

## Duration and delay: automated, fully resolved

Both are plain floats in **seconds**, stored verbatim from the AppleScript
value, in `animationAttributes` on the slide archive. Each sweep produced a
clean single-line delta.

Duration (`dur_duration/Index__Slide.iwa.yaml.diff`):

```
             animationType: Transition
             delay: 0.0
-            duration: 0.5
+            duration: 3.0
             effect: apple:dissolve
```

Delay (`dur_delay/Index__Slide.iwa.yaml.diff`):

```
             animationType: Transition
-            delay: 0.0
+            delay: 2.0
             duration: 0.5
             effect: apple:dissolve
```

| Field | Path | Type / unit | AppleScript source |
|---|---|---|---|
| `duration` | `...animationAttributes.duration` | float, seconds | `transition duration` (`KNTransitionAttributesDuration`) |
| `delay` | `...animationAttributes.delay` | float, seconds | `transition delay` (`KNTransitionAttributesDelay`) |
| `isAutomatic` | `...animationAttributes.isAutomatic` | bool | `automatic transition` (`KNTransitionAttributesIsAutomatic`) |

No unit conversion: AppleScript seconds == archive float. The `Deck` model can
store transition duration/delay as seconds and write them straight through.

## Direction: NOT automatable (dictionary gap) — deferred to human-in-the-loop

The Keynote AppleScript `transition settings` record (`Keynote.sdef`,
`record-type "transition settings"`) exposes only **four** properties:
`transition effect`, `transition duration`, `transition delay`,
`automatic transition`. There is **no** direction/orientation property. (The
only `direction` term in the whole dictionary belongs to an unrelated media
command.) So direction cannot be set by script — same class of gap as builds.

Evidence it is default-omitted from the archive: in the Exp 2 default `push`
deck (`apple:push`), the transition block contains **no** direction field at
all:

```
      transition:
        attributes:
          animationAttributes:
            animationType: Transition
            delay: 0.5
            duration: 1.5
            effect: apple:push
            isAutomatic: false
            randomNumberSeed: <vol>
            writingDirectionIsRtl: false
```

(The `direction: 2` / `angle: 0.0` fields elsewhere in that same file are
object geometry/style on the drawables, NOT the transition — they sit far
outside the `transition:` block.)

Interpretation: direction is almost certainly a proto field left at its default
(0 = the effect's default direction, e.g. left-to-right) and therefore omitted
by proto3 serialization. It should materialize once set to a non-default value.

### Recommended follow-up (golden-fixture, like builds)

1. `duration_sweep.applescript` (or `transition_matrix`) to make a base deck
   with a directional effect (Push or Move In) at its default direction; save
   as `fixtures/direction_A.key`.
2. In Keynote, duplicate, open the Animate inspector, change only the
   transition **direction** (e.g. Left-to-Right -> Top-to-Bottom); save as
   `fixtures/direction_B.key`.
3. `run_experiment.py direction --skip-generate --a fixtures/direction_A.key
   --b fixtures/direction_B.key` and read `Index__Slide.iwa.yaml.diff`.

Expected: a new field appears in `animationAttributes` (or `attributes`)
encoding direction as a small int enum and/or an `angle` float. Capturing its
name + enum values is required before the backend can drive directional
transitions.

## Open questions

- Exact field name and enum for direction (needs the fixture above).
- Do continuous-parameter effects (e.g. an angle-based wipe) use `angle` (float
  degrees/radians) vs a discrete `direction` enum? Both may exist.
## Exp 3b — automatic transition (auto-advance): RESOLVED

Sweep `automatic transition:false` vs `true` (effect dissolve),
`generators/auto_advance.applescript`, diffs in `findings/auto_advance/`.
The only slide-archive change is the boolean:

```
             effect: apple:dissolve
-            isAutomatic: false
+            isAutomatic: true
```

No separate auto-advance-delay field appears — the existing `delay` field
carries the wait for both click-advance and auto-advance. So the `Deck` model
needs just `isAutomatic: bool` + `delay: seconds`; no extra field.
