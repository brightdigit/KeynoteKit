# Experiment 8 — shape build (is ` character` object-type-qualified?)

**Question (from `build_fx.md`):** text builds serialize the effect as
`apple:dissolve character`. Is that ` character` suffix object-type-qualified?
A Build In ▸ Dissolve on a **shape** (a rectangle, not a text object) settles it:
if the suffix drops, the build enum depends on object type and the `Deck` model
would need per-type effect strings.

**Fixtures:**
- `fixtures/build_shape_A.key` — control, rectangle shape, **no build**.
- `fixtures/build_shape_B.key` — same rectangle with **Build In ▸ Dissolve**
  (default timing), added in the Animate inspector.

**Command run (exit code 0):**

```
mise exec -- python3 tools/run_experiment.py build_shape --skip-generate \
  --a fixtures/build_shape_A.key --b fixtures/build_shape_B.key
```

Diffed pair: `findings/build_shape/`. The `Document` `hasExplicitBuilds` cache
flips (A has no builds, B does), and the whole build signal lands on
`Index/Slide-2652176.iwa.yaml` as a new `KN.BuildArchive` + `KN.BuildChunkArchive`
on the shape's drawable.

## The delta (no build → Dissolve on a shape)

From `findings/build_shape/Index__Slide-2652176.iwa.yaml.diff`, the added
`KN.BuildArchive`:

```
+    - _pbtype: KN.BuildArchive
+      attributes:
+        animationAttributes:
+          animationType: In
+          delay: 0.0
+          duration: 1.0
+          effect: apple:dissolve character      # <-- SAME string as the text case
+          randomNumberSeed: <vol>
+          writingDirectionIsRtl: false
+        customDeliveryOption: kDeliveryOptionForward
+        customTextDelivery: kTextDeliveryByObject
+        eventTrigger: 1
+      delivery: All at Once
```

**Direct cross-check** (`tools/read_builds.py fixtures/build_shape_B.key`):

```
fixtures/build_shape_B.key  (1 build(s))
  [0] kind=In effect='apple:dissolve character' dur=1 delay=0 direction=-
      drawable=2652614  customTextDelivery=kTextDeliveryByObject,
      customDeliveryOption=kDeliveryOptionForward, delivery=All at Once, eventTrigger=1
```

## Comparison to the text case

| Object type | Build (inspector) | archive `effect` string |
|---|---|---|
| Text (Exp 7, `build_fx.md`) | Dissolve | `apple:dissolve character` |
| **Shape (this exp)** | Dissolve | `apple:dissolve character` |

Byte-for-byte identical, ` character` suffix and all.

## Verdict

**The ` character` suffix is NOT object-type-qualified.** A Dissolve build on a
plain rectangle shape serializes exactly `apple:dissolve character`, the same
string a text-object Dissolve produced in Exp 7. The suffix is part of the effect
enum's canonical spelling — it does **not** mark "this is a text object." (Note
`customTextDelivery: kTextDeliveryByObject` is present on the shape too; the
text-delivery/granularity machinery rides along regardless of object type,
defaulting to whole-object.)

**Implication for the Deck model's `BUILD_EFFECTS`:** effect strings are
**per-effect, not per-object-type**. `BUILD_EFFECTS` stays a single flat
`name → archive-string` map (`Dissolve → apple:dissolve character`, etc.), exactly
like the transition `EFFECTS` table. No per-type branching, no separate
shape/image/text effect string variants are needed.

## Caveat

This is confirmed for **Dissolve** on a **shape**. It is very likely general (the
suffix looks like the effect's fixed spelling), but only Dissolve was tested on a
non-text object. If any future effect turns out to have a type-dependent spelling,
that would surface as a different archive string on a shape vs text fixture — not
observed here.
