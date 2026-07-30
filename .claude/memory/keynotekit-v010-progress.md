---
name: keynotekit-v010-progress
description: v0.1.0 tracer stack #13–#23 and scripted #24 landed; Keynote open pass 4/5 — build_acceptance fails
metadata:
  node_type: memory
  type: project
---

As of **2026-07-30**, the v0.1.0 tracer stack through authoring is on
`v0.1.x`. PR #32 landed #17 → #18 → #20 → #22 → #23; PR #34 landed the
scripted #24 generation path; PR #35 landed the #10 ScriptingBridge AFK
surface.

| Ticket | Status | What landed |
|---|---|---|
| #13–#23 | done | Package through authoring API |
| #24 | **open** | Generation scripted; Keynote open pass **4/5** |
| #10 | open | AFK surface merged; live Keynote verify remains |

**Keynote 15.3 open pass:** `bisect_in`, `bisect_out`, `bisect_action`, and
`bisect_direction` open. **`build_acceptance` does not.** Recorded in
[[acceptance_keynote_open]] (`research/findings/acceptance_keynote_open.md`).
Do not tag `v0.1.0` until that deck is fixed and re-checked.

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

**How to apply:** next session diagnoses/fixes `build_acceptance` open
failure, then re-runs the Keynote open pass before tagging. See
[[keynotekit-integration-branch]], [[keynotekit-v010-scope]], and
[[keynotekit-ci-conventions]].
