# Per-slide transition independence

**Generator:** `generators/multi_slide.applescript` — one 3-slide deck, a
different effect on each slide (slide 1 dissolve, slide 2 push, slide 3 wipe).

## Result

Unpacking and reading each slide's own archive:

| Slide | Label | archive `effect` |
|---|---|---|
| 1 | One | `apple:dissolve` |
| 2 | Two | `apple:push` |
| 3 | Three | `apple:wipe` |

- Transitions are stored **per slide, independently**: each slide's
  `KN.SlideArchive.transition.attributes.animationAttributes` holds its own
  effect. No document-level transition list; no cross-slide coupling.
- **Slide 1 can carry a transition** and it serializes identically to any other
  slide (it plays on entry). So the `Deck` model should allow a transition on
  every slide including the first.

## Implication for the `Deck` model / backend

- Transition is a per-`Slide` field (already modeled that way). The backend sets
  each slide's transition on that slide's `KN.SlideArchive` — for the AppleScript
  path that is exactly `set transition properties of slide N to {...}`, which is
  fully scriptable and needs no pack.
