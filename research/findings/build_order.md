# Experiment 6 — build order / multiple builds

**Fixtures:** two copies of `builds_base` with **two Build-Ins each, same effect,
opposite authoring order**:
- `fixtures/build_order_A.key` — Build In on **Item 1**, then on **Item 2**.
- `fixtures/build_order_B.key` — Build In on **Item 2**, then on **Item 1**.

**Pair diffed:** `findings/build_order/` (run: `run_experiment.py build_order
--skip-generate --a ... --b ...`). Effect held identical in both, so the only
real difference is delivery ORDER.

## Headline: order is LIST POSITION, not an explicit field

The **normalized** slide-archive diff is *empty* — `Index/Slide-*.iwa.yaml` is
**not** in the changed set (only cache/bookkeeping files differ). That empty diff
is itself the finding: `normalize.py` canonicalizes object ids first-seen ->
`<id:N>`, which is **order-invariant for a pure reordering** ([X, Y] and [Y, X]
both collapse to [`<id:a>`, `<id:b>`]). If order were an explicit integer field
(e.g. `buildOrder: 0/1`), it would have survived normalization and shown up. It
didn't — so order is carried by **sequence position alone**.

## Confirmed on the RAW (un-normalized) archives

Re-unpacking without normalizing and diffing the slide archive shows both decks
have two `KN.BuildArchive` + two `KN.BuildChunkArchive`, identical except that
**the entries swap position**:

```
# variant A: Item 1's build first
BuildArchive identifier 2652871  ->  drawable 2652601   (Item 1)   # built 1st
BuildArchive identifier 2652872  ->  drawable 2652626   (Item 2)   # built 2nd

# variant B: Item 2's build first  (same objects, reversed order)
BuildArchive identifier 2652872  ->  drawable 2652626   (Item 2)   # built 1st
BuildArchive identifier 2652871  ->  drawable 2652601   (Item 1)   # built 2nd
```

The reversal shows up in three places, all consistent:
1. the order of `KN.BuildArchive` / `KN.BuildChunkArchive` objects in the stream;
2. the order of the `builds:` / `buildChunks:` reference lists on
   `KN.SlideArchive`;
3. correspondingly the paired `buildId {lower, upper}` values travel WITH their
   build (they are per-build volatile 64-bit ids, not an order key).

There is **no** `order` / `index` / `sequence` integer anywhere in the build
records. (`buildChunkId: 1` is per-build, always 1 for a single-chunk build — it
is a chunk index within one build, not a slide-wide order.)

## Note on drawable ids

Because a build stores its target as `drawable.identifier` (Exp 5), the raw diff
also confirms the object mapping: `2652601` = Item 1, `2652626` = Item 2. This is
how we cross-checked that Exp 5's single build (drawable `2652601`) is on Item 1.

## Conclusion

Build (delivery) order == **position in the slide's `builds`/`buildChunks`
lists**, matching authoring order. No explicit order field is written. For the
`Deck` model this means builds must be an **ordered list** on the slide; the
backend emits them in delivery order and Keynote infers order from that
sequence. (Contrast transitions, which are a single per-slide record with no
ordering question.)
