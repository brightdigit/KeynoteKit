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
| `build_acceptance.key` | **no** |

## Follow-up

`build_acceptance` is the multi-slide / multi-build deck (In + Out + Action on
slide one, directed Move In transition on slide two — see
`Sources/AcceptanceDeckCatalog/BuildAcceptanceContent.swift` and
`research/examples/build_acceptance.json`). Bisect decks that isolate each
concern open; the combined case does not. Root cause is not diagnosed yet —
defer diagnosis and fix to a later session. Do **not** tag `v0.1.0` until this
deck opens without crash or silent repair and builds/ordering/direction are
re-verified.

Tracked on [#24](https://github.com/brightdigit/KeynoteKit/issues/24).
