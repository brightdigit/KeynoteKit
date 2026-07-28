# Experiment 10 — Build In vs Out vs Action (the animation-type axis)

**Fixtures:**
- `fixtures/build_out_A.key` — control, three text items ("Item 1/2/3"), no build.
  (Reused as the A-side control for both pairs below.)
- `fixtures/build_out_B.key` — same deck + one **Build Out = Dissolve** on
  "Item 1", default timing.
- `fixtures/build_action_B.key` — same deck + one **Action** (Move / motion
  path) on "Item 1", default timing.

**Pairs diffed:**
- `findings/build_out/` — Build Out vs control.
- `findings/build_action/` — Action vs control.

This closes the In-vs-Out/Action axis left open by Exp 5 (`build_in.md`), which
only characterized `animationType: In`. Both variants reuse the exact Exp-5
scaffolding (`builds` / `buildChunks` lists on `KN.SlideArchive`, one
`KN.BuildArchive` + one `KN.BuildChunkArchive`, `Document` cache flip); the only
question is what changes inside the `KN.BuildArchive`.

## Commands (run from repo root, exit codes)

```
mise exec -- python3 tools/run_experiment.py build_out --skip-generate \
    --a fixtures/build_out_A.key --b fixtures/build_out_B.key          # exit 0
mise exec -- python3 tools/run_experiment.py build_action --skip-generate \
    --a fixtures/build_out_A.key --b fixtures/build_action_B.key       # exit 0
mise exec -- python3 tools/read_builds.py \
    fixtures/build_out_B.key fixtures/build_action_B.key               # exit 0
```

Both diffs are **non-empty** and localize the same way as Exp 5: the signal is
in `Index/Slide-2652176.iwa.yaml`; `Index/Document.iwa.yaml` carries the cache
flip; the rest (`CalculationEngine`, `DocumentMetadata`, `DocumentStylesheet`,
`Metadata`, the `ViewState` rename) is characterized noise.

## Build Out — `animationType: Out`, otherwise identical to In

The new `KN.BuildArchive` in `build_out/Index__Slide-2652176.iwa.yaml.diff`:

```
_pbtype: KN.BuildArchive
attributes:
  ChartRotation3D: 60.0
  animationAttributes:
    animationType: Out                 # <-- the discriminator (Exp 5 = In)
    delay: 0.0
    duration: 1.0
    effect: apple:dissolve character    # same dissolve enum as the In case
    randomNumberSeed: <vol>
    writingDirectionIsRtl: false
  customDeliveryOption: kDeliveryOptionForward
  customTextDelivery: kTextDeliveryByObject
  eventTrigger: 1
chunkIdSeed: 1
delivery: All at Once
drawable:
  identifier: <vol>
duration: 0.0
```

**Confirmed: `animationType: Out`.** This is the *only* field that differs from
the Exp-5 Build-In archive. Same effect enum (`apple:dissolve character`), same
`customTextDelivery` / `customDeliveryOption` / `delivery` text-delivery knobs,
same `eventTrigger: 1` (On Click), same `chunkIdSeed` / `ChartRotation3D`
noise-attributes, same `KN.BuildChunkArchive` (`automatic: false`, `delay 0`,
`duration 1`, 64-bit `buildId` pair). `Index/Document.iwa.yaml` flips exactly as
in Exp 5: `hasExplicitBuilds: false -> true`, `buildEventCount: 1`,
`buildEventCountCacheVersion 4294967295 -> 2`.

So **In and Out are the same archive shape distinguished purely by the
`animationType` string** — mirroring how a slide transition uses
`animationType: Transition` in that same `animationAttributes` block (Exp 2/3).

## Action — `animationType: Action`, plus a motion-path payload

The `KN.BuildArchive` in `build_action/Index__Slide-2652176.iwa.yaml.diff` shares
the same scaffolding but diverges inside `attributes`:

```
_pbtype: KN.BuildArchive
attributes:
  ChartRotation3D: 60.0
  actionAcceleration: kEaseBoth         # NEW — easing curve for the action
  actionMotionPathSource:               # NEW — the path the object travels
    editableBezierPathSource:
      naturalSize: {height: 0.0, width: 50.0}
      subpaths:
      - closed: false
        nodes:
        - inControlPoint:  {x: 0.0,  y: 0.0}
          nodePoint:       {x: 0.0,  y: 0.0}
          outControlPoint: {x: 0.0,  y: 0.0}
          type: sharp
        - inControlPoint:  {x: 50.0, y: 0.0}
          nodePoint:       {x: 50.0, y: 0.0}
          outControlPoint: {x: 50.0, y: 0.0}
          type: sharp
      horizontalFlip: false
      verticalFlip: false
  animationAttributes:
    animationType: Action               # <-- the discriminator
    delay: 0.0
    duration: 1.0
    effect: apple:action-motion-path     # action effect enum (not a text effect)
    randomNumberSeed: <vol>
    writingDirectionIsRtl: false
  eventTrigger: 1
chunkIdSeed: 1
delivery: All at Once
drawable:
  identifier: <vol>
duration: 0.0
```

**Action serializes as the SAME `KN.BuildArchive` type** — not a separate
archive class — discriminated by `animationType: Action`. It is *not* a
Smart-build variant; it is a first-class value on the same three-way
`animationType` enum (`In` / `Out` / `Action`). New keys vs In/Out:

- `effect: apple:action-motion-path` — an action-family effect enum (a Move
  action here), distinct from the text-transition effects used by In/Out.
- `actionAcceleration: kEaseBoth` — the easing curve.
- `actionMotionPathSource` — a full `editableBezierPathSource` (natural size +
  bezier subpaths/nodes + flip flags) describing the path the object moves along.
  A default Move is a 50pt horizontal 2-node segment.

**Two In/Out keys are absent on the Action archive:** `customTextDelivery` and
`customDeliveryOption` do not appear (an Action animates a whole object, so the
text-delivery granularity/order knobs are not emitted). Everything else
(`KN.BuildChunkArchive`, the `builds`/`buildChunks` lists, the `Document` cache
flip) is byte-for-byte the same as the In/Out cases.

## Cross-check (`read_builds.py`)

```
fixtures/build_out_B.key  (1 build(s))
  [0] kind=Out    effect='apple:dissolve character'   dur=1 delay=0 ... drawable=2652614  customTextDelivery=kTextDeliveryByObject, customDeliveryOption=kDeliveryOptionForward, delivery=All at Once, eventTrigger=1
fixtures/build_action_B.key  (1 build(s))
  [0] kind=Action effect='apple:action-motion-path'   dur=1 delay=0 ... drawable=2652614  delivery=All at Once, eventTrigger=1
```

Independently confirms the two `animationType` values, and that the Action row
carries **no** `customTextDelivery` / `customDeliveryOption` (they are simply not
present in the archive), while both builds target the same drawable `2652614`
("Item 1").

## What this means for the `Deck` build model

- **The In/Out/Action distinction is a single enum field**, `animationType`, on
  the build's `animationAttributes` — the same slot that discriminates slide
  transitions. The Deck `Build` needs one **three-valued axis field**
  (`In` / `Out` / `Action`); it is *not* a separate archive type and *not* a
  Smart-build flag.
- In and Out are structurally identical, so the Deck model needs nothing beyond
  that enum value to represent Build Out — the existing Exp-5 `Build`
  representation (effect + duration/delay + `eventTrigger` + drawable ref +
  text-delivery knobs) already covers both by just varying `animationType`.
- **Action is a distinct shape** that carries extra payload the model must be
  able to hold: `effect` drawn from an action family (`apple:action-motion-path`
  …), an `actionAcceleration` easing value, and an `actionMotionPathSource`
  bezier path. Conversely it **omits** the `customTextDelivery` /
  `customDeliveryOption` text knobs. This argues for modelling the build's
  animation payload as a variant/sum: text-transition builds (In/Out) carry the
  delivery knobs, action builds carry the motion-path + acceleration. A flat
  struct with everything optional would work but would let invalid combinations
  (an Action with `customTextDelivery`) be expressed.
- The object reference (`drawable.identifier`) and the `KN.BuildChunkArchive`
  timing/sequencing unit are shared across all three types — no change from
  Exp 5.
