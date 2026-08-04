# #24 Keynote 15.3 open pass (2026-07-30)

Human open of the five decks produced by `swift run AcceptanceDecks` (Desktop
copy under `~/Desktop/acceptance-decks/`). Structural gates
(`AcceptanceDeckTests`, UUID-map invariants) were already green on all five.

| Deck | Opens in Keynote 15.3 |
|---|---|
| `bisect_in.key` | yes |
| `bisect_out.key` | yes |
| `bisect_action.key` | yes |
| `bisect_direction.key` | yes |
| `build_acceptance.key` | **yes** |

## Diagnosis & Fix

The open failure on `build_acceptance.key` was caused by three component/node invariants when cloning slides:

1. **Component `preferredLocator`**: `appendComponent` in `KeynoteArchiveSurgeon+SlideCloning.swift` was overwriting `component.preferredLocator` with `"Slide-<id>"` instead of keeping `"Slide"`. Keynote requires `preferredLocator` to be `"Slide"`.
2. **`Document` Component External Reference**: `TSP.PackageMetadata` inside `Metadata.iwa.yaml` requires Component 1 (`Document`) to register an `externalReference` pointing to every cloned slide component identifier (`newSlideIdentifier`). Added this registration in `appendComponent`.
3. **Slide Node `hasTransition_p` Flag**: When a transition was applied to a slide, `slideArchive.transition` was updated on the slide archive, but `node.hasTransition_p` on the slide's `KN.SlideNodeArchive` in `Document.iwa` remained `false` if the template node had no transition. Added `flagSlideNodeTransition` in `KeynoteArchiveSurgeon+NodeFlagging.swift` to ensure `hasTransition_p = true`.

All 5/5 acceptance decks now open cleanly in Keynote 15.3.

Tracked on [#24](https://github.com/brightdigit/KeynoteKit/issues/24).

# #24 Expanded pass — drawable depth (2026-07-31, PENDING)

Drawable depth (#3 geometry, #37 text formatting, #38 images) landed via
PR #39 (squash `211b956`), and mixed formatting runs (#40) landed via PR #41
(squash `45b8c4f`, which also renamed the DSL: `Text`→`TextBox`,
`TextRun`→`Text`). `swift run AcceptanceDecks` now writes **9** decks;
fresh copies are under `~/Desktop/acceptance-decks/`. Structural gates are
green on this branch (`swift test` all targets, `LINT_MODE=STRICT
./Scripts/lint.sh`).

This pass is the **only remaining gate** to tagging `v0.1.0`.

State going in: on 2026-07-31, pre-merge on the identical tree, all 8 pre-#40
decks were verified **open AND render green** via scripted slide-image export +
AppleScript model probes (see `drawable_open_crash.md`; harness was
scratchpad-only, not committed), and `text_runs.key` was render-verified by
human pass the same day (see `text_formatting.md`). What scripted export cannot confirm — and
what this human pass is for — is animation playback (Magic Move actually
playing 1→2, Dissolve In on the image) and the absence of a silent "repair"
dialog on interactive open.

Reminder: an open-pass is NOT a render-pass — formatted text has already
demonstrated open-clean-but-render-plain failure modes. Verify visually; for
anything doubtful, export slide images via AppleScript (`export … as slide
images`) and inspect the PNGs.

## Checklist — original five (regression)

Per deck: opens with no crash; **no repair warning** (a silent "repair" is a
failure); In/Out/Action builds, ordering, and transition direction survived.

| Deck | Opens | No repair | Builds / order / direction |
|---|---|---|---|
| `bisect_in.key` | | | |
| `bisect_out.key` | | | |
| `bisect_action.key` | | | |
| `bisect_direction.key` | | | |
| `build_acceptance.key` | | | |

## Checklist — drawable depth (new)

| Deck | Opens | No repair | Renders correctly |
|---|---|---|---|
| `drawable_geometry.key` | | | Magic Move grows "Alpha" — size AND position change; z-order visually correct |
| `text_formatting.key` | | | "Styled" is large red bold-italic; neighbor stays plain (formatting must *render*, not just open) |
| `image_drawable.key` | | | image displays (no missing-media "?"), correct placement; Dissolve In on the image plays |
| `text_runs.key` | | | one text box: "Bold red" large bold red, "italic" italic, plain spans between; control box whole-item bold (regression: already human-verified 2026-07-31 pre-merge) |

## Same-session extras

- [ ] #10 live verify: `KEYNOTEKIT_LIVE_KEYNOTE=1 swift test` with Keynote
      installed and Automation (TCC) permission granted — exercises the
      ScriptingBridge create → slide → text item → transition → save →
      export-PDF → close flow that PR #35 could not run. Green ⇒ close #10.

## On green

- [ ] Record results above (flip PENDING → date + verdicts)
- [ ] PR this branch (`24-expanded-acceptance`) to `v0.1.x`
- [ ] Tag `v0.1.0` from `v0.1.x`; close #24 and #12 (and #40 — its code
      merged pre-tag via PR #41; only the issue is still open)
- [ ] Merge `v0.1.x` → `main`
