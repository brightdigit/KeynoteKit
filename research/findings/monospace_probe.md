# Monospace font probe (#64)

**Round one FAILED — but not because monospace is unavailable.** All four
families rendered at the template's default size *and* a proportional face,
including `Courier New`, which certainly exists and is certainly monospaced.
Round two is authored and awaiting a render pass.

## Round one — result and diagnosis (2026-08-03)

Rendered by Leo, Keynote 15.3, exported as slide images.

| Family | Rendered monospaced? | Rendered at 96pt? |
|---|---|---|
| Menlo | no — proportional | no — template default |
| SF Mono | no — proportional | no — template default |
| Courier New | no — proportional | no — template default |
| Monaco | no — proportional | no — template default |

Two symptoms, one cause. **Both the family and the size were ignored.** Had
Keynote merely substituted an unavailable family, the authored 96pt would
still have applied — the ruler text would be large and proportional. Instead
it was small and proportional, i.e. the whole authored character style was
dropped. A missing-font explanation cannot account for the size.

`Courier New` failing is independently decisive: it ships with macOS and is
monospaced by definition.

### The archive is correct

Probed what `write(to:)` actually emits:

```
=== MULTI-LINE + .font(Menlo, 96) ===
  para VARIATION id=2653720 fontName=Menlo fontSize=96.0
=== SINGLE-LINE + .font(Menlo, 96) ===
  para VARIATION id=2653720 fontName=Menlo fontSize=96.0
```

KeynoteKit writes `fontName` and `fontSize` correctly into a
`TSWP.ParagraphStyleArchive` variation, **identically for single-line and
multi-line boxes**. So the bytes are right and Keynote ignored them at
render — which makes this a KeynoteKit correctness question, not a font
question.

### The suspect: paragraph count

`TextFormattingContent` renders its authored font correctly (render-verified
2026-07-31, `.font("HelveticaNeue", size: 48)`), and it is a **single
paragraph**. Every round-one probe box was **multi-paragraph**
(`"iiii\nMMMM\n1111"` — per the DSL's semantics, three paragraphs).

Working hypothesis: the whole-item paragraph-style variation is only honored
for single-paragraph items. Multi-paragraph items presumably need the style
threaded onto each paragraph's own fork, and today's write path attaches it
once.

That is consistent with the known mechanism — whole-item formatting renders
via a `TSWP.ParagraphStyleArchive` variation on `tableParaStyle`, and a
multi-paragraph storage has several paragraphs whose styles resolve
independently.

**Not yet confirmed.** Round two is designed to confirm or kill it.

## Round two — what to look for

```bash
open /Users/leo/Downloads/probe-round2/monospace_probe.key
```

Deck is already generated. Copy before opening — Keynote autosaves in place.

| Slide | Shape | Reads as |
|---|---|---|
| 1–3 | single paragraph, one family each (Menlo / Courier New / Monaco) | does the single-paragraph path work at all? |
| 4 | three paragraphs, item-level `.font()` | round one's shape |
| 5 | three paragraphs, per-span `Text.font()` | is per-span styling a workaround? |

Slides 1–3 show `iiii MMMM 1111` on one line at 96pt. Monospaced = the three
groups are equal width and the text is large. Slides 4–5 stack the same
groups as separate lines.

### Reading the outcome

- **1–3 render, 4 does not** → hypothesis confirmed. Whole-item font is
  ignored on multi-paragraph boxes: a real bug needing its own issue, and
  #66 cannot rely on `.font()` for code blocks until it is fixed.
- **4 fails, 5 renders** → per-span styling is the workaround; #66 should
  emit styled spans rather than item-level styling.
- **Nothing renders, including slide 1** → the `TextFormattingContent`
  evidence is stale and whole-item font selection regressed generally.
  Higher severity: it would mean #37's render verification no longer holds.
- **Everything renders** → round one's failure was an export artifact. Re-run
  round one before trusting either result.

## Results — round two

| Slide | Monospaced? | At 96pt? | Notes |
|---|---|---|---|
| 1 Menlo (single para) | | | |
| 2 Courier New (single para) | | | |
| 3 Monaco (single para) | | | |
| 4 multi-para, item font | | | |
| 5 multi-para, per-span font | | | |

**Chosen family for the demo deck:** ______

**Styling route #66 should emit:** item-level / per-span — ______

## Outcome

The winning family becomes the default in `CodeTheme` (#66), which carries it
as a property rather than a constant — so recording it here is a one-line
default change.

If slide 4 fails, file the multi-paragraph font bug before #66 lands: code
blocks are inherently multi-line, so #66 would ship broken otherwise.

## Cleanup

`monospace_probe` is spike evidence, not a feature gate. Once the family and
styling route are pinned, remove the `monospaceProbe` group from
`AcceptanceDeck` and delete `MonospaceProbeContent.swift`.
