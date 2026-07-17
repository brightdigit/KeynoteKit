# Experiment 4 — Magic Move object correspondence (drives `magic-id`)

**This is the highest-value experiment for the `Deck` model.** It answers: when
Magic Move morphs an object on slide N into one on slide N+1, how does the
`.key` file record *which object maps to which*? By shared id? name? text?
position? Or not at all?

**Generator:** `generators/magic_move_pair.applescript`. Both variants have
Magic Move on slide 2; they differ only in matchability:
- **A (matchable):** slide 1 text "Alpha", slide 2 text "Alpha".
- **B (non-matchable):** slide 1 text "Alpha", slide 2 text "Omega".

If correspondence were persisted, A (a matchable pair) would carry a pairing
that B (nothing to pair) would not. Diffing A vs B isolates it.

## Result: correspondence is NOT stored in the file

The A-vs-B delta on slide 2 (`magic_move_pair/Index__Slide.iwa.yaml.diff`) is
just the deliberate text change and its incidental text-box width:

```
-              width: 131.688        # "Alpha" box
+              width: 165.528        # "Omega" box (wider)
...
       text:
-      - Alpha
+      - Omega
```

The **transition block is byte-identical** between the matchable and
non-matchable decks. No pairing list appears in A and vanishes in B. A full
keyword scan of the deck (`correspond`, `match`, `morph`, `pair`, `magicMove`,
...) finds **nothing** beyond the transition's `custom*` attributes.

### Corroborating facts (from the raw, un-normalized matchable deck)

1. **Matched objects do NOT share an object id.** The single "Alpha" text item
   is `ownedDrawables -> identifier 2652601` on slide 1 but `2652724` on
   slide 2. Different ids, yet these are exactly the objects Magic Move morphs.
   -> matching is **not** by shared identifier.
2. **Drawables carry no `name` field** at all. -> matching is **not** by name.
3. The only Magic-Move-specific data is the transition policy, identical in
   both variants:

```
customMagicMoveFadeUnmatchedObjects: true
customTextDeliveryType: TransitionCustomAttributesTextDeliveryTypeByObject
customTimingCurve:  TransitionCustomAttributesTimingCurveTypeEaseInEaseOut
```

`customMagicMoveFadeUnmatchedObjects` is a *policy for unmatched objects* ("fade
them") with **no accompanying list of matched pairs**. The format states the
fallback behavior and delegates the actual matching to the engine.

## Conclusion

Magic Move correspondence is **computed at runtime by Keynote's matcher**, not
serialized. The `.key` stores each slide's objects as independent archives
(independent ids, no names, no cross-slide references) plus a transition record
that only carries timing + an "fade unmatched" policy. Whether two objects
morph is decided at play time from their **intrinsic properties** — object type
and content are clearly decisive here (identical text "Alpha"/"Alpha" is a
match; "Alpha"/"Omega" is not), very likely also shape/geometry/style/z-order
similarity.

## Direct implications for the `Deck` model's `magic-id`

- **There is no archive field to write a `magic-id` into.** A markup
  `magic-id` cannot be "lowered" to a stored identifier or pairing in the file
  — that concept does not exist in the format.
- To make two objects morph, the backend must make them **matchable to
  Keynote's heuristic**, i.e. emit them as the *same object type* with
  *matching content* on both slides (for text, same string; for shapes, same
  shape/geometry so the similarity score wins). The cleanest guarantee of a
  match is the UI-native workflow: **duplicate the slide and mutate objects in
  place**, so the "same" objects persist across slides with near-identical
  attributes — maximizing the matcher's similarity score.
- Therefore `magic-id` should be an **authoring-time abstraction**, not a
  serialized field: the compiler resolves same-`magic-id` objects on adjacent
  Magic Move slides and emits them so Keynote will pair them (same type/content,
  stable geometry), rather than trying to persist the pairing.
- If deterministic matching turns out to be unreliable via pure heuristics, the
  fallback is the duplicate-and-edit construction (guarantees object continuity
  the matcher favors) — but note that even then the file shows no explicit link;
  it just gives the matcher near-identical objects to pair.

## Open questions

- Exact tie-breakers in Keynote's matcher when multiple candidates are equally
  similar (by z-order? nearest position? creation order?). Not answerable from
  the file; needs behavioral testing (render the animation and observe), or is
  moot if we use duplicate-and-edit.
- Does `customTextDeliveryType: ...ByObject` vs a "by character/word" value
  change how text morphs? Worth a sweep, but it's a Magic Move *style* knob, not
  a correspondence key.
- Non-text objects (shapes/images): **checked (Exp 4b,
  `generators/mm_shapes.applescript`, `findings/mm_shapes/`).** Same result at
  the file level — matchable-vs-non-matchable *shapes* differ only in content
  (text `Alpha`->`Omega`), transition block identical, no pairing structure
  anywhere. The "not persisted" conclusion is not text-specific. (Shapes carrying
  text reuse the same text storage, so content is still the visible key; a
  geometry-only shape probe could refine this but is unlikely to change the
  file-level conclusion.)
- Duplicate-and-edit vs independent-creation: does a duplicated object leave any
  file-level trace (e.g. a shared style/template ref) that improves match
  reliability? Worth checking before committing the backend to that workflow.
