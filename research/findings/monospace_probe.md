# Monospace font probe (#64)

**Status: AWAITING HUMAN RENDER PASS.** The probe deck is written and
structurally green; the results table below is empty until someone opens it in
Keynote 15.3.

## Why

The v0.1.0 demo deck (#56) is a code-heavy tutorial, and syntax highlighting
(#66) colors code that has to *read* as code — which requires a monospaced
face. Font **family** selection is already proven: `TextBox.font(_:size:)` sets
`fontName`, threaded to `properties.fontName` in
`KeynoteArchiveSurgeon+CharacterStyle.swift:61-62`, and ships render-verified as
`.font("HelveticaNeue", size: 48)` in `TextFormattingContent.swift:37`.

What is unproven is whether a *monospace* family specifically resolves, or
whether Keynote silently substitutes a proportional face. A substitution is
easy to miss — the text still renders, just not monospaced — so this probe is
designed around a signal that cannot be misread.

## Procedure

```bash
export DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer
xcrun swift run AcceptanceDecks /path/to/out
open /path/to/out/monospace_probe.key
```

**Copy the file before opening it.** Keynote autosaves in place when driven via
AppleScript, and any deck Keynote has opened should be treated as dirty.

### Reading slides 1–4 (one per family)

Each slide shows the family name, then three ruler lines at 96pt:

```
iiii
MMMM
1111
```

- **Monospaced** → all three lines are the **same width**; their right edges
  form a clean vertical column.
- **Substituted** → `MMMM` is dramatically wider than `iiii`; edges are ragged.

That is the whole test. No measuring, no zooming.

### Reading slide 5 (indentation)

Nested leading-space lines in `Menlo`. The left edges of the nested lines must
form clean columns. If `Menlo` was rejected on slide 1, this slide proves
nothing — re-run it against whichever family survived.

## Results

Fill in per family. "Renders monospaced?" is the slide 1–4 ruler test.

| Family | Renders monospaced? | Substituted with | Notes |
|---|---|---|---|
| Menlo | | | |
| SF Mono | | | |
| Courier New | | | |
| Monaco | | | |

**Indentation (slide 5):** columns hold / columns drift — ______

**Chosen family for the demo deck:** ______

## Outcome

The winning family becomes the default in `CodeTheme` (#66). The theme carries
the family as a property rather than a hardcoded constant, so recording the
result here is a one-line default change, not a rework.

If **no** family resolves — unlikely, since `Courier New` is the conservative
fallback — the code-on-slide design in #56 needs rethinking, and that is a
scope conversation, not an implementation detail.

## Cleanup

`monospace_probe` is spike evidence, not a feature gate. Once the working
family is recorded here and pinned in the demo deck, remove the
`monospaceProbe` group from `AcceptanceDeck` and delete
`MonospaceProbeContent.swift` — it should not sit in the acceptance catalog
permanently, where it would add noise to every future human pass.
