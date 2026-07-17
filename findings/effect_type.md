# Experiment 2 — transition effect type (Magic Move vs Dissolve vs Push)

**Generator:** `generators/effect_type.applescript` (builds all three variants
in one scripted pass; slide 2 gets a transition with `duration:1.5`,
`automatic:false`, differing only in `transition effect`).
**Pairs diffed:**
- `effect_dissolve_push/` — Dissolve vs Push (two "simple" effects)
- `effect_magic_dissolve/` — Magic Move vs Dissolve

## Which component changed

Same as Exp 1: the only real signal is in **`Index/Slide.iwa.yaml`** (the
`KN.SlideArchive` for slide 2). Everything else is the characterized
reorder/bookkeeping noise (`TemplateSlide-*`, `Metadata`, `CalculationEngine`).

## Responsible field: `effect` (string enum)

The effect type is a single string field:
`KN.SlideArchive.transition.attributes.animationAttributes.effect`.

**Dissolve vs Push** — the delta is *only* the string:

```
             duration: 1.5
-            effect: apple:dissolve
+            effect: apple:push
             isAutomatic: false
```

Nothing else changed — no extra fields, no direction. For simple effects, the
effect type is fully captured by this one string.

**Magic Move vs Dissolve** — the string changes AND the Magic-Move-only
`custom*` keys appear/disappear:

```
-            effect: apple:magic-move-implied-motion-path
+            effect: apple:dissolve
             ...
-          customMagicMoveFadeUnmatchedObjects: true
-          customTextDeliveryType: TransitionCustomAttributesTextDeliveryTypeByObject
-          customTimingCurve: TransitionCustomAttributesTimingCurveTypeEaseInEaseOut
```

Confirms: the three `custom*` keys (siblings of `animationAttributes`, under
`attributes`) are specific to Magic Move; Dissolve/Push do not emit them.

## Values observed / enum mapping

The `effect` string stored in the archive is exactly the Cocoa `string-value`
from the AppleScript `transition effects` enumeration (verified for the three
tested; the full table below comes from the app's `Keynote.sdef` and is the
enum the `Deck` model should target):

| AppleScript effect | archive `effect` string | tested? |
|---|---|---|
| no transition effect | `none` | ✅ (Exp 1) |
| magic move | `apple:magic-move-implied-motion-path` | ✅ |
| dissolve | `apple:dissolve` | ✅ |
| push | `apple:push` | ✅ |
| move in | `apple:slide` | ✅ |
| wipe | `apple:wipe` | ✅ |
| reveal | `apple:reveal` | |
| iris | `apple:wipe-iris` | ✅ |
| grid | `apple:apple-grid` | |
| drop | `apple:bounce` | |
| droplet | `apple:droplet` | |
| switch | `apple:FlipThrough` | ✅ |
| clothesline | `apple:ClotheslinePush` | |
| object cube | `apple:ca-cube` | ✅ |
| object flip | `apple:ca-dissolve-and-flip` | ✅ (adds `customBounce`) |
| object pop | `apple:ca-pop` | |
| object push | `apple:ca-push` | |
| object revolve | `apple:ca-revolve` | |
| object zoom | `apple:ca-zoom` | |
| perspective | `apple:ca-isometric` | |
| shimmer | `apple:ca-text-shimmer` | |
| sparkle | `apple:ca-text-sparkle` | |
| swing | `apple:ca-swing` | |
| confetti | `com.apple.iWork.Keynote.KLNConfetti` | |
| fade through color | `com.apple.iWork.Keynote.BLTFadeThruColor` | |
| blinds | `com.apple.iWork.Keynote.BLTBlinds` | |
| color planes | `com.apple.iWork.Keynote.KLNColorPlanes` | |

Notes:
- Three string namespaces appear: `apple:` (built-in Core Animation effects),
  `apple:ca-*` (a Core-Animation "object effects" family — the "object X"
  names), and `com.apple.iWork.Keynote.*` (Keynote plug-in effects). The `Deck`
  model's effect enum can be a straight string map to these values.

## Per-effect extra attributes (effect matrix sweep)

`generators/effect_matrix.applescript` / `generators/one_effect.applescript`
build one deck per effect (all else identical); transition blocks extracted from
each. Result — `attributes` = the universal `animationAttributes` plus an
optional set of effect-specific `custom*` siblings:

| Effect | archive `effect` | extra `custom*` under `attributes` |
|---|---|---|
| dissolve | `apple:dissolve` | none |
| wipe | `apple:wipe` | none |
| move in | `apple:slide` | none |
| iris | `apple:wipe-iris` | none |
| object cube | `apple:ca-cube` | none |
| switch | `apple:FlipThrough` | none |
| **object flip** | `apple:ca-dissolve-and-flip` | **`customBounce: true`** |
| magic move | `apple:magic-move-implied-motion-path` | `customMagicMoveFadeUnmatchedObjects`, `customTextDeliveryType`, `customTimingCurve` |

Takeaways for the `Deck` model:
- `animationAttributes` (animationType/effect/duration/delay/isAutomatic/...) is
  universal.
- Effect-specific knobs live as `custom*` siblings and are **sparse** (most
  effects emit none). Model them as an extensible per-effect options bag keyed
  by effect, not a fixed struct.
- No effect serialized a **direction** at its default value — reinforces that
  direction is proto3-default-omitted and only appears when changed (needs the
  golden fixture in `duration_direction.md`).

## Open questions

- **Direction is not serialized for a default Push.** `apple:push` produced no
  direction/angle field at all. Direction is likely (a) an extra field that only
  appears when set to a non-default, or (b) lives in a separate sub-record. Exp
  3 must set a non-default direction to force it to appear.
- Do `apple:ca-*` "object" effects carry their own extra attribute blocks
  (like Magic Move's `custom*`)? Not tested here.
- Is `animationType: Transition` ever something else (e.g. for builds it may be
  `Build`)? Relevant to Phase 2.
