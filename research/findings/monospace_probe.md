# Monospace font probe (#64)

**RESOLVED. Monospace works — use `Menlo`.** Round one's failure was not a
font problem at all: it was #81, which drops item-level formatting on
multi-paragraph text boxes.

Round two confirms it by render. A single-paragraph box renders Menlo at
96pt correctly; the *same family at the same size* across three paragraphs
renders at the template default in a proportional face.

Once #81 landed, all styling routes render correctly. The one apparent
straggler — a condensed `MMMM` — turned out to be Keynote's own font
fallback for capital M at large sizes, not a KeynoteKit defect.

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

## Results — round two (2026-08-03, rendered by Leo)

| Slide | Shape | Monospaced? | At 96pt? |
|---|---|---|---|
| 1 | Menlo, single paragraph | **yes** | **yes** |
| 2 | Courier New, single paragraph | yes | yes |
| 3 | Monaco, single paragraph | yes | yes |
| 4 | Menlo, 3 paragraphs, item-level `.font()` | **no** | **no** |
| 5 | Menlo, 3 paragraphs, per-span `Text.font()` | **partial** | **partial** |

### Monospace itself is fine

Slide 1 renders Menlo at 96pt, unmistakably monospaced — `iiii`, `MMMM`, and
`1111` are equal width. **`Menlo` is the family to use.** Round one's failure
had nothing to do with font availability.

### #81 confirmed by render

Slides 1 and 4 differ *only* in paragraph count — same family, same size,
same deck, same run. Slide 1 renders correctly; slide 4 renders at the
template default in a proportional face. That is the one-`tableParaStyle`-
entry bug, now confirmed visually as well as structurally.

### The `MMMM` line was a BAD PROBE, not a second bug (corrected 2026-08-03)

Slide 5's middle line (`MMMM`) rendered condensed while `iiii` and `1111`
rendered correctly, which looked like a second off-by-one in the per-span
route. It is not. An isolation probe settles it:

| Probe | Result |
|---|---|
| `iiii` / **`xxxx`** / `1111` | interior line renders Menlo — **fine** |
| **`MMMM`** / `iiii` / `1111` | `MMMM` fails in FIRST position |
| **`MMMM` alone**, single paragraph | still condensed |

`MMMM` fails wherever it appears, including alone on a slide with no
multi-paragraph involvement at all. Any other interior line renders
correctly. **This is Keynote substituting a condensed face for capital M in
Menlo at 90pt** — its shrink-to-fit behavior on a wide glyph run — and has
nothing to do with KeynoteKit's write path.

The ruler was badly chosen: `MMMM` was picked *because* it is the widest
glyph, which is exactly what triggers the substitution. A width comparison
needs glyphs that do not provoke fallback (`iiii` vs `xxxx` vs `1111`).

## Cleanup

`monospace_probe` is spike evidence, not a feature gate. Once the family and
styling route are pinned, remove the `monospaceProbe` group from
`AcceptanceDeck` and delete `MonospaceProbeContent.swift`.
