# Deck intermediate model — transition + magic-id (first cut)

Synthesis of Phase 1 findings (Exps 1-4, 3b, 4c) into a concrete model for the
`Deck` IR and how the backend lowers it to a `.key`. **Transitions only** so
far; builds (Phase 2) are TBD pending the human-in-the-loop experiments.

## 1. What the format actually stores for a transition

A slide transition is a record that is **always present** on every slide's
`KN.SlideArchive`, at `transition.attributes`:

```
attributes:
  animationAttributes:
    animationType: Transition          # constant for slide transitions
    effect: <string>                   # "none" == no transition
    duration: <float seconds>
    delay: <float seconds>             # also the auto-advance wait
    isAutomatic: <bool>                # true == advance on timer, false == on click
    writingDirectionIsRtl: <bool>
    randomNumberSeed: <int>            # volatile, do not author
  # Magic-Move-only siblings (absent for other effects):
  customMagicMoveFadeUnmatchedObjects: <bool>
  customTextDeliveryType: <enum>       # e.g. ...TextDeliveryTypeByObject
  customTimingCurve: <enum>            # e.g. ...TimingCurveTypeEaseInEaseOut
```

The transition plays *into* the slide it is attached to (set on the destination
slide, e.g. slide 2). `Document.iwa.yaml` also holds a derived `hasTransition`
per-slide cache flag — a computed mirror, not the source of truth.

Transitions are **per-slide and independent** (verified, `multi_slide.md`): a
3-slide deck with dissolve/push/wipe stored each effect in its own slide
archive, with no document-level list. **Slide 1 can carry a transition** too
(plays on entry). So `Transition` is a field on every `Slide`, including the
first.

## 2. Proposed `Deck` transition model

```
Transition {
  effect: EffectKind          # enum below; None == no transition
  duration_s: float = 1.0     # default Keynote writes when unset
  delay_s: float = 0.0
  auto_advance: bool = false  # -> isAutomatic
  # effect-specific knobs -> `custom*` siblings of animationAttributes.
  # SPARSE: most effects emit none. Model as an extensible per-effect bag,
  # not a fixed struct. Observed so far (effect matrix sweep, see effect_type.md):
  #   magic move  -> customMagicMoveFadeUnmatchedObjects (bool),
  #                  customTextDeliveryType (enum), customTimingCurve (enum)
  #   object flip -> customBounce (bool)
  #   dissolve/wipe/move in/iris/object cube/switch -> (none)
  options: map<string, scalar> = {}   # e.g. {"customBounce": true}
  # direction: TBD (not scriptable; proto3-default-omitted; see duration note)
}
```

### EffectKind -> archive `effect` string (verified subset in bold)

The archive `effect` value is exactly the Cocoa `string-value` from Keynote's
`transition effects` sdef enum. Full table lives in `effect_type.md`. Verified:
- **None -> `none`**
- **MagicMove -> `apple:magic-move-implied-motion-path`**
- **Dissolve -> `apple:dissolve`**
- **Push -> `apple:push`**
Others (Wipe `apple:wipe`, MoveIn `apple:slide`, the `apple:ca-*` "object"
family, and `com.apple.iWork.Keynote.*` plug-ins) are in the table but untested.

Units: `duration_s`/`delay_s` are seconds, written verbatim (no conversion).

## 3. magic-id: an AUTHORING-TIME abstraction, not a stored field

**Established (Exp 4 + 4c):** Keynote does **not** persist any object
correspondence. Matched objects don't share ids or names; there is no pairing
list; the file only carries a `fade_unmatched` policy. Matching is a **runtime
heuristic** over object type + content (text) + geometry/style. Duplicate-and-
edit produces byte-identical archives to independent creation, so construction
method leaves no trace either.

Consequences for the model:
- `magic-id` in the markup/DSL is resolved **at compile time**; it never becomes
  a field in the `.key`.
- The compiler groups objects that share a `magic-id` across adjacent
  Magic-Move slides and must emit each as the **same object type with matching
  content/geometry**, so Keynote's matcher pairs them:
  - text: identical (or near-identical) string; same text-item type
  - shapes/images: same shape kind / same source; keep size/position close
    enough that the similarity score wins over other candidates
- Objects that should NOT morph must be made dissimilar (different type/content)
  or will be cross-faded per `fade_unmatched`.

### Lowering rule (backend)

```
for each MagicMove boundary (slideA -> slideB):
  for each magic-id group g present on both slides:
    emit g's object on slideB as SAME type as on slideA,
      carrying over identity signals (text string, shape kind, style),
      with only the intended geometry/appearance delta.
  objects present on only one side: leave as-is (they fade in/out).
```

No explicit link is written; correctness = giving the matcher an unambiguous
best match. If ambiguity is possible (two similar candidates), disambiguate by
making the intended pair MORE similar (content/geometry) than any competitor.

## 4. Backend implications / open risks

- **Runtime match ambiguity** is the main risk (tie-breakers unknown; see
  `magic_move_correspondence.md`). Mitigation: maximize intended-pair
  similarity; if needed, validate by rendering.
- **Direction** (Push/Wipe/MoveIn) is not yet modeled — not scriptable and not
  serialized at default; capture via the golden-fixture procedure in
  `duration_direction.md`, then add `direction` to the model.
- **Pack path**: writing these archives back requires `keynote-parser pack`,
  which currently does NOT round-trip on Keynote 15.3 (see `versions.md`). The
  template-surgery/AppleScript backend must either (a) use AppleScript for the
  scriptable knobs (effect/duration/delay/automatic — all settable!) and avoid
  pack, or (b) wait for regenerated 15.3 mappings for byte-level surgery.
  NOTE: since effect/duration/delay/automatic ARE fully AppleScript-scriptable,
  the *transition* half of the backend can be done entirely via AppleScript with
  no pack dependency. Only builds/direction (non-scriptable) will need surgery.
```
```

## 5. Status of unknowns feeding this model

| Knob | Source of truth | Author via | Status |
|---|---|---|---|
| effect | slide archive `effect` | AppleScript `transition effect` | done |
| duration/delay | animationAttributes | AppleScript | done |
| auto-advance | `isAutomatic` | AppleScript `automatic transition` | done |
| magic-move options | `custom*` | (not scriptable) surgery/defaults | partial |
| direction | (unknown field) | golden fixture | TODO |
| magic-id | not stored | compile-time construction | done (conceptually) |
| builds | (unknown) | golden fixture (Phase 2) | TODO |
