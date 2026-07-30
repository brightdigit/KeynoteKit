---
name: keynotekit-v010-progress
description: v0.1.0 tracer stack #13–#23 merged; #34 landed scripted acceptance decks; frontier is Keynote 15.3 open pass + v0.1.0 tag
metadata:
  node_type: memory
  type: project
---

As of **2026-07-30**, the v0.1.0 tracer stack through authoring is on
`v0.1.x`. PR #32 landed #17 → #18 → #20 → #22 → #23; PR #34 landed the
scripted #24 generation path (`AcceptanceDecks` + `AcceptanceDeckTests`).

| Ticket | Status | What landed |
|---|---|---|
| #13 | done | Package skeleton, five product stubs, CI |
| #15 | done | Snappy survey — decision: **vendor a pure-Swift block codec** |
| #19 | done | Five goldens in `research/goldens/` |
| #14 | done | 34 protos generated + committed; `TSPRegistryMapping` |
| #16 | done | `Snappy` block codec |
| #21 | done | Bundled `blank.key` via `.copy`, `write(to:basedOn:)` |
| #17 | done | `IWAFraming` + `.key` zip semantic round-trip |
| #18 | done | Archive navigation (extract_builds parity) |
| #20 | done | Writer builds match goldens + invariants |
| #22 | done | Slide + text-item supply |
| #23 | done | Authoring API (`SlideContent` surface) |
| #24 | **open** | Generation scripted (PR #34); **human Keynote 15.3 open pass** + `v0.1.0` tag remain |

**The frontier is the #24 human pass:** open
`bisect_in.key`, `bisect_out.key`, `bisect_action.key`,
`bisect_direction.key`, and `build_acceptance.key` in Keynote 15.3 — no crash,
no silent repair, In/Out/Action builds and transition direction survive — then
tag `v0.1.0`. Do not open Keynote from agent sessions; that pass is HITL.

Generate decks without Keynote:

```bash
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
  xcrun swift run AcceptanceDecks ~/Desktop/acceptance-decks
```

Constraints already measured (do not re-derive):

- **Archive decoding must be `partial: true`.**
- **`.key` zip members are always `STORED`, never `DEFLATED`.**
- **`TSPRegistryMapping` values are not injective** — never invert with
  `Dictionary(uniqueKeysWithValues:)`.

**How to apply:** check `v0.1.x` and issue #12's checklist, then run the
Keynote open pass for #24. See [[keynotekit-integration-branch]],
[[keynotekit-v010-scope]], and [[keynotekit-ci-conventions]].
