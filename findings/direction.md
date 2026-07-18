# Experiment 11 — transition direction

Captures the last unknown transition field: **direction**. It is not scriptable
(no property in the `transition settings` record — see `duration_direction.md`)
and is proto3-omitted at its default, so it only materializes in the archive
when set to a non-default value. This experiment sets it via the Animate
inspector and diffs.

**Command:**

```
mise exec -- python3 tools/run_experiment.py direction --skip-generate \
  --a fixtures/direction_A.key --b fixtures/direction_B.key
```

**Exit code:** `0`

**Fixtures:** 2-slide decks, slide 2 has a Move In transition
(`effect: apple:slide`, `animationType: Transition`).
- `direction_A.key` — Direction dropdown at its **default** value (control).
- `direction_B.key` — same deck, slide-2 transition Direction changed to a
  non-default value in the Animate inspector.

## Result: direction materializes as an int enum

The slide-archive diff (`findings/direction/Index__Slide.iwa.yaml.diff`) is a
clean single-line addition — the field is **absent** on A and **appears** on B:

```
           animationAttributes:
             animationType: Transition
             delay: 0.5
+            direction: 11
             duration: 1.0
             effect: apple:slide
             isAutomatic: false
```

Full path (confirmed against the unpacked YAML):

```
transition.attributes.animationAttributes.direction
```

| Side | `direction` value | Meaning |
|---|---|---|
| A | *absent* | proto3 default — the effect's default direction |
| B | `11` (int) | the non-default direction chosen in the Animate inspector |

The other five changed components (CalculationEngine, Document,
DocumentMetadata, DocumentStylesheet, Metadata) plus the ViewState
add/remove are the usual document-level / editing-state churn, not transition
data. The Slide diff is the only substantive change and it is unambiguous.

## Transitions reuse the builds' `animationAttributes.direction` slot

This confirms the Exp 7 prediction (`build_fx.md`): builds already serialize
`direction` as an int enum in the **same** `animationAttributes` struct (Move In
build = `13`), and that finding argued the transition side "exists in the same
slot and only *appears* absent because it is proto-default-omitted." That is now
demonstrated directly — the transition's `direction` lives at the identical
`animationAttributes.direction` path, an int, absent at default and present when
set. Transitions and builds share one struct and one direction encoding.

Note the transition Move In (`apple:slide`) here reads `11`, whereas the Exp 7
Move In build read `13` — the integer is a raw enum ordinal, so different
effects (and possibly the transition vs build context) index into it
differently. The single value is enough to prove the slot; it is not enough to
decode the enum.

## Limitation — only one A→B delta

This fixture pair yields exactly one non-default value (`11`). The full
direction enum (top / bottom / left / right / top-left / …) cannot be mapped
from this experiment alone — that would need additional fixtures sweeping each
Direction dropdown option for a given effect (and likely per effect, since the
ordinal is effect-relative). Only the single default→`11` delta is available
here.

## Open questions

- The complete `direction` enum: which int corresponds to each dropdown label,
  and whether the mapping is stable across effects (Move In / Push / Wipe / …).
- Whether any continuous-angle effect also emits an `angle` float alongside (or
  instead of) the discrete `direction` int (unresolved from Exp 3).
