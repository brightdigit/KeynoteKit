# Experiment 1 — transition present vs. absent

**Generator:** `generators/transition_matrix.applescript` (single scripted
pass builds both variants; Keynote 15.3).
**Pair:** A = two slides, no transition. B = identical, plus Magic Move on
slide 2 (`transition duration:1.5`, `automatic transition:false`).
**Artifacts:** `findings/transition_present/*.diff`,
`unpacked/transition_present/{A,B}`.

## Which component changed

Component-level summary reported 16 changed files, but exactly one carries the
real signal:

- **`Index/Slide.iwa.yaml`** — the `KN.SlideArchive` for the slide the
  transition plays *into* (slide 2). This is the attachment point.
- **`Index/Document.iwa.yaml`** — a per-slide cache flag (secondary/derived).
- The other 14 (`TemplateSlide-*`, `CalculationEngine`, `Metadata`,
  `DocumentMetadata`) are noise — see "Residual noise" below.

## Responsible field(s)

The transition lives on the slide archive at:

```
KN.SlideArchive
  transition:
    attributes:
      animationAttributes:      # the core knobs
        animationType: Transition
        effect: <string>        # <-- the on/off + kind selector
        duration: <float sec>
        delay: <float sec>
        isAutomatic: <bool>
        randomNumberSeed: <int>            (volatile)
        writingDirectionIsRtl: <bool>
      # custom* keys appear as SIBLINGS of animationAttributes, only when a
      # real (Magic Move) effect is set:
      customMagicMoveFadeUnmatchedObjects: <bool>
      customTextDeliveryType: <enum>
      customTimingCurve: <enum>
```

Isolated delta (`Index__Slide.iwa.yaml.diff`):

```
           animationAttributes:
             animationType: Transition
             delay: 0.5
-            duration: 1.0
-            effect: none
+            duration: 1.5
+            effect: apple:magic-move-implied-motion-path
             isAutomatic: false
             randomNumberSeed: <vol>
             writingDirectionIsRtl: false
+          customMagicMoveFadeUnmatchedObjects: true
+          customTextDeliveryType: TransitionCustomAttributesTextDeliveryTypeByObject
+          customTimingCurve: TransitionCustomAttributesTimingCurveTypeEaseInEaseOut
```

Secondary flag (`Index__Document.iwa.yaml.diff`) — a cached per-slide summary
in the document's slide list:

```
-      hasTransition: false
+      hasTransition: true
```

(Adjacent in that same record: `hasExplicitBuilds`, `hasExplicitBuildsCacheVersion`
— note for Phase 2.)

## Values observed

| Field | No transition (A) | Magic Move (B) |
|---|---|---|
| `effect` | `none` | `apple:magic-move-implied-motion-path` |
| `duration` | `1.0` (default) | `1.5` (as scripted) |
| `delay` | `0.5` | `0.5` (unchanged) |
| `isAutomatic` | `false` | `false` (from `automatic transition:false`) |
| `customMagicMoveFadeUnmatchedObjects` | (absent) | `true` |
| `customTextDeliveryType` | (absent) | `...TextDeliveryTypeByObject` |
| `customTimingCurve` | (absent) | `...TimingCurveTypeEaseInEaseOut` |
| Document `hasTransition` | `false` | `true` |

Key structural facts:
- Keynote **always** writes the `animationAttributes` block. "No transition"
  is not an absent field — it is `effect: none` with default duration/delay.
  So the `Deck` model should treat transition as an always-present record whose
  *effect* is the on/off switch, not an optional sub-object.
- `effect` is a **string enum** using the `apple:` namespace. The specific
  value `apple:magic-move-implied-motion-path` shows Magic Move defaulted to
  its "implied motion path" flavor here.
- The three `custom*` keys are Magic-Move-specific and sit one level up from
  `animationAttributes` (under `attributes`), suggesting `attributes` is the
  container and `animationAttributes` is the generic timing sub-record shared by
  all transition types.

## Residual noise (characterized, not signal)

- `TemplateSlide-*`, plus parts of `Document`/`CalculationEngine`: **reordering
  of unordered collections** — identical `<id:N>` sets listed in a different
  sequence between saves (`objectReferences`, `drawablesZOrder`,
  `ownedDrawables`, `instructionalTextMap`). Set membership is unchanged.
- `Metadata.iwa.yaml` (~8k lines): internal data-reference bookkeeping
  (`saveToken` / `dataIdentifier` / `objectReferenceList` registry) rewritten
  wholesale between saves.
- `normalize.py` was extended for this experiment: canonicalize 6+ digit object
  ids first-seen -> `<id:N>` (kills renumbering churn) and treat
  `randomNumberSeed` as volatile. This dropped 2 fully-spurious components
  (18 -> 16) and made `Slide.iwa.yaml` a pristine one-hunk delta.

## Open questions (feed later experiments)

- Enum coverage: what `effect` strings do Dissolve / Push produce? (Exp 2)
- Units/ranges of `duration`, `delay`; how is *direction* encoded (not present
  here since Magic Move has no direction)? (Exp 3)
- Is the transition truly on the "destination" slide (slide 2) only, or can it
  also attach to the outgoing slide? Here it attached to slide 2's archive.
- Do the `custom*` keys generalize to non-Magic-Move effects, or are they
  Magic-Move-only? (Exp 2/3)
- `hasTransition` in `Document.iwa.yaml` is a derived cache; the source of truth
  is the slide archive. The `Deck` model should write the slide archive and let
  Keynote recompute the cache (or we mirror both when doing template surgery).
