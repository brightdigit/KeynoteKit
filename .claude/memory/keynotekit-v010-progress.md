---
name: keynotekit-v010-progress
description: v0.1.0 container stack (#13-#16, #19, #21) is merged on v0.1.x; #17 IWAFraming is the frontier
metadata:
  node_type: memory
  type: project
---

As of **2026-07-29**, the v0.1.0 container stack is built and merged on
`v0.1.x` (head `3ec7c77`, builds clean):

| Ticket | Commit | What landed |
|---|---|---|
| #13 | `d17ae91` | Package skeleton, five product stubs, CI |
| #15 | `d5bb1ef` | Snappy survey — decision: **vendor a pure-Swift block codec** |
| #19 | `c06313d` | Five goldens in `research/goldens/` (NOT `research/samples/`, which is gitignored) |
| #14 | `9733e93` | 34 protos generated + committed; `TSPRegistryMapping` (631 ids → 624 types) |
| #16 | `b8c37c6` | `Snappy` block codec — 873/873 blocks round-trip, ratio 0.2734 vs Apple's 0.2647 |
| #21 | `3ec7c77` | 98 KB `blank.key` resource via `.copy`, `write(to:basedOn:)` |

**The frontier is #17** (`IWAFraming`: Apple chunk framing + the `.key` zip
layer), then #18. Both its gates (#14, #16) have landed. After #18, the writer
lane #20 → #22 → #23 → #24 opens (it also needs #19 and #21, both done).

Three constraints already measured and recorded in PLAN's decision log — do not
re-derive them:

- **Archive decoding must be `partial: true`.** The 15.3 protos mark 1,497
  fields `required` (proto2) but Keynote does not populate them all; strict
  decoding throws `.missingRequiredFields` on documents Keynote itself
  round-trips.
- **`.key` zip members are always `STORED`, never `DEFLATED`** — 1,604/1,604
  entries across all 30 committed `.key` files. Most zip libraries default to
  deflate; getting this wrong would only fail at #24 acceptance.
- **`TSPRegistryMapping` values are not injective** (ids 5 and 6 both name
  `KN.SlideArchive`). Never invert the table with
  `Dictionary(uniqueKeysWithValues:)`.

The zip-library depend-vs-vendor call is still open and belongs to #17;
groundwork is in a comment on that issue. `ZIPFoundation` is the lead candidate
but its `libz` dependency is the same class of problem that disqualified the
C/C++ route in #15 — verify the Android leg specifically. Hand-rolling is
unusually cheap here: everything is `STORED`, so there is no compression codec
to write, only headers, central directory, and CRC-32.

**How to apply:** start a session by checking `v0.1.x` and issue #12's
checklist, then open a lane for #17 per [[keynotekit-integration-branch]]. See
also [[keynotekit-v010-scope]] and [[keynotekit-ci-conventions]].
