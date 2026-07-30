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
