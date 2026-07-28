# Experiment 4c — duplicate-and-edit vs independent creation (Magic Move)

**Question:** does constructing slide 2 by *duplicating* slide 1 (then editing)
leave any file-level trace — preserved object ids, a "duplicated-from"
reference, a persisted correspondence — that would make Keynote's Magic Move
matcher more reliable than building slide 2 independently?

**Generator:** `generators/mm_duplicate.applescript`. Both variants matchable
(text "Alpha" on both slides), Magic Move on slide 2.
- **A:** slide 2 built independently (`make new slide` + `make new text item`).
- **B:** slide 2 built via `duplicate slide 1`, then move the text item.

## Result: structurally identical — no trace

- Component summary: `only in A = 0`, `only in B = 0`. **Neither slide archive
  is in the changed set.**
- Direct check: `unpacked/mm_duplicate/{A,B}/Index/Slide.iwa.yaml` and
  `Slide-2652176.iwa.yaml` are **byte-identical** after normalization.
- The only diffs are noise: `TemplateSlide-*` reordering, `Metadata`/`Document`
  data-reference bookkeeping, and a thumbnail cache (`thumbnailSizes` /
  `thumbnails`) that Keynote happened to generate for one variant.

So duplicate-and-edit and independent creation yield the **same** on-disk slide
archives. Keynote persists **no** duplication linkage or "same object" marker;
object ids are freshly assigned either way (consistent with Exp 4: matched
objects never share an id).

## Implication for the backend / `magic-id`

- There is **no file-level advantage** to duplicate-and-edit. The runtime
  matcher works purely from object type/content/geometry, regardless of how the
  slide was authored.
- The backend can therefore construct Magic Move slides **independently** and
  just guarantee that same-`magic-id` objects are emitted with the *same object
  type and matching content/geometry* on both slides. Duplicate-and-edit remains
  a convenient way to get near-identical attributes (maximizing the matcher's
  similarity score), but it is a *content* strategy, not a persisted link.
- Net: `magic-id` stays an authoring-time abstraction (confirmed from two
  angles now). No format feature to target.

## Caveat

This confirms the two methods are equivalent *in the file*. It does not measure
runtime match reliability (which needs observing the rendered animation). If
heuristic matching proves flaky in practice, revisit — but the fix is
content/geometry similarity, not a stored id.
