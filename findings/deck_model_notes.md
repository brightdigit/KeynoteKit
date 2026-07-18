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
  # not a fixed struct. Full catalog sweep (all 43 effects, see effect_type.md):
  #   magic move -> customMagicMoveFadeUnmatchedObjects/customTextDeliveryType/
  #                 customTimingCurve
  #   customBounce (bool) -> object flip, object revolve, cube, flip, scale,
  #                          revolving door
  #   customTravelDistance (float) -> fade and move
  #   customTwist (float) -> twist
  #   everything else -> none
  # NOTE: none of these are AppleScript-settable (inspector-only); the
  # scriptable backend leaves them at Keynote defaults.
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

## 4b. Backend — IMPLEMENTED for transitions (scriptable, no pack)

`tools/deckkit.py` + `tools/build_deck.py` implement the transition half of the
backend end-to-end:
- `Deck`/`Slide`/`TextItem`/`Transition` dataclasses; `EFFECTS` maps a stable
  name -> (archive string, AppleScript enumerator).
- JSON spec loader (`examples/deck_example.json` is a working sample).
- AppleScript code-gen that drives Keynote to build the `.key` (uses
  `set transition properties`, per-slide incl. slide 1). No `pack` dependency.
- Round-trip `--verify`: unpacks the built `.key` and asserts every spec
  transition is present with matching effect/duration/delay/auto (order-
  insensitive multiset match).

Verified: `mise exec -- python3 tools/build_deck.py examples/deck_example.json
samples/deck_example.key --verify` -> `VERIFY PASS` (4 slides, dissolve/push+
auto/magic-move). This is the concrete proof the transition model lowers
faithfully. Builds/direction remain future work (non-scriptable).

## 6. Build {} — object builds (Phase 2, Exps 5-7)

Reverse-engineered from `build_in.md` (Exp 5), `build_order.md` (Exp 6),
`build_fx.md` (Exp 7). Unlike Magic Move, a build **does** persist an explicit
object reference, so the model carries a real target ref.

### What the format stores

A build lives on the slide as **two parallel objects** referenced from two new
lists on `KN.SlideArchive` (`builds` + `buildChunks`):

```
KN.BuildArchive:                 # the effect definition
  attributes:
    animationAttributes:         # SAME struct as a transition (Sec 1)
      animationType: In          # In == build-in (Transition == slide transition)
      effect: <string>           # apple:* enum, e.g. "apple:dissolve character"
      duration: <float s>
      delay: <float s>
      direction: <int>           # only for directional effects (Move In = 13); omitted otherwise
    customBounce / customTravelDistance / ...   # per-effect option bag (like transitions)
    customTextDelivery: kTextDeliveryByObject|ByCharacter
    customDeliveryOption: kDeliveryOptionForward|Random
    eventTrigger: <int>          # start trigger; 1 == On Click
  delivery: All at Once | By Paragraph | ...
  drawable: { identifier: <drawable id> }   # TARGET OBJECT, explicit
KN.BuildChunkArchive:            # the timing / sequencing unit
  automatic: <bool>             # false == On Click
  delay: <float s>
  duration: <float s>           # MIRRORS animationAttributes.duration
  buildId: {lower,upper}        # volatile 64-bit id, regenerated per save
```

`Document.iwa.yaml` caches `hasExplicitBuilds` (flips true) + `buildEventCount` —
derived mirrors, not source of truth (like `hasTransition`).

**Order:** delivery order == **position in the `builds`/`buildChunks` lists**.
There is NO explicit order/index integer (Exp 6). So builds are an ordered list.

### Proposed `Deck` build model

```
Build {
  target: ObjectRef            # -> KN.BuildArchive.drawable.identifier (compile-time -> real drawable id)
  kind: BuildKind = In         # In | Out (| Action?) -> animationAttributes.animationType
  effect: BuildEffectKind      # enum below -> animationAttributes.effect
  duration_s: float = 1.0      # -> animationAttributes.duration AND chunk.duration (write both)
  delay_s: float = 0.0
  trigger: Trigger = OnClick   # OnClick|AfterPrevious|WithPrevious -> eventTrigger + chunk.automatic
  # sparse per-effect / delivery bag, exactly like Transition.options:
  options: map<string,scalar> = {}   # direction, customBounce, customTextDelivery,
                                      # customDeliveryOption, delivery, ...
}
# Slide gains:  builds: list<Build>   # ORDER = delivery order (Exp 6)
```

### BuildEffectKind -> archive `effect` string (verified subset in bold)

Build effects reuse the `apple:*` namespace but are **distinct strings** from
transitions (note the ` character` suffix on the text-build variants):
- **Dissolve -> `apple:dissolve character`**
- **MoveIn -> `apple:move in character`** (directional; carries `direction` int)

Open: whether the ` character` suffix is object-type-qualified (re-test on a
non-text object). Full build-effect catalog is future work (mirror the 43-effect
transition sweep once a non-scriptable capture path exists).

### Backend implications

- Builds are **NOT in Keynote's AppleScript dictionary** — there is no scriptable
  setter (confirmed: they had to be added by hand in the Animate inspector). So
  unlike the transition half, the build backend **cannot** use the osascript
  path. It needs byte-level template surgery, which requires regenerated 15.3
  `pack` mappings (`versions.md`) — same blocker as transition `custom*` knobs.
- `deckkit.py` therefore models builds + implements the **read/verify** half
  (extract builds from an unpacked deck, compare as an ordered list) but leaves
  the write side as documented-future.
- The target ref is explicit (`drawable.identifier`), so builds do NOT have Magic
  Move's runtime-matching ambiguity: the compiler resolves `target` to the
  object's real drawable id at emit time.

## 5. Status of unknowns feeding this model

| Knob | Source of truth | Author via | Status |
|---|---|---|---|
| effect | slide archive `effect` | AppleScript `transition effect` | done |
| duration/delay | animationAttributes | AppleScript | done |
| auto-advance | `isAutomatic` | AppleScript `automatic transition` | done |
| magic-move options | `custom*` | (not scriptable) surgery/defaults | partial |
| direction | (unknown field) | golden fixture | TODO |
| magic-id | not stored | compile-time construction | done (conceptually) |
| build structure | slide `builds`/`buildChunks` + `KN.Build{,Chunk}Archive` | (not scriptable) surgery | done (Exp 5) |
| build effect/timing | build `animationAttributes` (+ chunk `duration`) | (not scriptable) surgery | done (Exp 7) |
| build order | list position (no order field) | list order | done (Exp 6) |
| build target ref | `KN.BuildArchive.drawable.identifier` | compile-time id resolution | done (Exp 5) |
| build direction | `animationAttributes.direction` (int, e.g. 13) | (not scriptable) surgery | done (Exp 7) |
