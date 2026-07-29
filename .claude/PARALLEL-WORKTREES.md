# Parallel worktrees for v0.1.0 tickets

How to run the [12 tickets](https://github.com/brightdigit/KeynoteKit/issues/12)
(#13–#24) across **git worktrees** without stepping on each other. Integration
branch: `feature/swift-package`.

This repo already lives as a worktree of the bare clone
`../KeynoteKit.git`. Add sibling worktrees next to `swift-package`, not nested
inside it.

## Principles

1. **One worktree ↔ one parallel lane** (not one ticket). A lane is a chain that
   can move without waiting on another lane’s *code*.
2. **Merge into `feature/swift-package` when a ticket’s gate is green** — don’t
   stack long-lived lane branches past their join points.
3. **Rebase or merge from integration before starting the next ticket** in that
   lane so product seams (`Snappy`, `IWAFraming`, …) stay aligned.
4. **#13 is the fan-out gate.** Until it lands on integration, only lanes
   that don’t need `Package.swift` (#15 survey, #19 goldens) should run in
   parallel with it.
5. **Prefer fine-grained products** — lanes should mostly touch different
   products; if two lanes must edit the same target, serialize or land one first.

## Lanes

```mermaid
flowchart LR
  subgraph phase0 [Phase 0 — fan-out]
    L0[Lane 0: #13 scaffold]
    L3[Lane S: #15 survey]
    L7[Lane G: #19 goldens]
  end
  subgraph phase1 [Phase 1 — after #13]
    LP[Lane P: #14 protobuf]
    LN[Lane N: #16 snappy]
    LT[Lane T: #21 template]
  end
  subgraph phase2 [Phase 2 — join]
    LI[Lane I: #17 then #18]
  end
  subgraph phase3 [Phase 3 — authoring]
    LW[Lane W: #20 then #22 then #23 then #24]
  end
  L0 --> LP
  L0 --> LN
  L0 --> LT
  L3 --> LN
  LP --> LI
  LN --> LI
  LI --> LW
  L7 --> LW
  LT --> LW
```

| Lane | Tickets (in order) | Primary products / artifacts | Needs Keynote? |
|---|---|---|---|
| **0 — Scaffold** | #13 | `Package.swift`, all five product stubs, CI/lint | No |
| **S — Survey** | #15 | PLAN decision log only (docs) | No |
| **G — Goldens** | #19 | Committed `.key` goldens / samples policy | **Yes** (takes over the app) |
| **P — Protobuf** | #14 | `KeynoteKitProtobuf` | No |
| **N — Snappy** | #16 *(after #13+#15)* | `Snappy` | No |
| **T — Template** | #21 *(after #13)* | Bundled `.key` resource on `KeynoteKit` | Hand-author in Keynote once |
| **I — IWA** | #17 → #18 *(after #14+#16)* | `IWAFraming`, navigation/tests | No |
| **W — Writer+API** | #20 → #22 → #23 → #24 *(after #18+#19+#21)* | `KeynoteKit` | #24 yes (human open) |

`KeynoteKitScripting` stays empty until GitHub #10 — no lane.

## Suggested worktree layout

From the KeynoteKit parent directory (sibling of `swift-package`):

```text
KeynoteKit/
  KeynoteKit.git          # bare
  swift-package/          # integration: feature/swift-package
  wt-scaffold/            # lane 0 — #13
  wt-survey/              # lane S — #15
  wt-goldens/             # lane G — #19 (Keynote machine)
  wt-protobuf/            # lane P — #14
  wt-snappy/              # lane N — #16
  wt-template/            # lane T — #21
  wt-iwa/                 # lane I — #17–#18
  wt-authoring/           # lane W — #20–#24
```

You do **not** need every worktree at once. Create a worktree when that lane
starts; remove it when the lane’s tickets are merged.

### Create / remove

```bash
# From swift-package (or any worktree of the bare repo)
git fetch origin
git worktree add -b v010/13-scaffold ../wt-scaffold feature/swift-package
git worktree add -b v010/15-survey  ../wt-survey  feature/swift-package
git worktree add -b v010/19-goldens ../wt-goldens feature/swift-package

# After #13 is on feature/swift-package:
git worktree add -b v010/14-protobuf ../wt-protobuf feature/swift-package
git worktree add -b v010/16-snappy   ../wt-snappy   feature/swift-package
git worktree add -b v010/21-template ../wt-template feature/swift-package

# After #14+#16 merged:
git worktree add -b v010/17-iwa ../wt-iwa feature/swift-package

# After #18+#19+#21 merged:
git worktree add -b v010/20-authoring ../wt-authoring feature/swift-package
```

Branch naming: `v010/<issue>-<slug>` for single-ticket lanes; keep one branch
per lane when the lane is a short chain (e.g. `v010/iwa` for #17→#18).

Remove when done:

```bash
git worktree remove ../wt-scaffold
git branch -d v010/13-scaffold   # after merge
```

Each new worktree that runs Python research tools needs its own venv setup
(`mise trust`, `ensurepip`, `keynote-parser` install) — see PLAN Toolchain.

## Phasing (what runs in parallel when)

### Phase 0 — before #13 lands (max 3 worktrees)

| Worktree | Ticket | Notes |
|---|---|---|
| `wt-scaffold` | #13 | Owns `Package.swift` / product graph |
| `wt-survey` | #15 | Docs-only; merge anytime; unblocks #16’s *decision* |
| `wt-goldens` | #19 | **Exclusive Keynote use** while regenerating |

Do not start #14/#16/#21 until #13 is merged to `feature/swift-package`.

### Phase 1 — after #13 (max 3 code worktrees + goldens if still open)

| Worktree | Ticket | Touches |
|---|---|---|
| `wt-protobuf` | #14 | `KeynoteKitProtobuf` only |
| `wt-snappy` | #16 | `Snappy` only (needs #15’s decision merged) |
| `wt-template` | #21 | Resource + thin `basedOn:` wiring on `KeynoteKit` |

Conflict risk: #21 vs later authoring on `KeynoteKit` — keep #21 minimal (resource
+ default path only). Leave DSL to lane W.

### Phase 2 — after #14 and #16

| Worktree | Tickets | Touches |
|---|---|---|
| `wt-iwa` | #17 → #18 | `IWAFraming` + tests; may read protobuf + Snappy as deps |

Serialize #17 then #18 on the **same** branch/worktree — #18 is not parallelizable
with #17.

### Phase 3 — after #18, #19, and #21

| Worktree | Tickets | Touches |
|---|---|---|
| `wt-authoring` | #20 → #22 → #23 → #24 | `KeynoteKit` write path + API |

Single lane: each ticket needs the previous gate. #24 is human + Keynote;
don’t overlap with #19’s Keynote sessions.

## Merge order at join points

Land in this order when multiple PRs are ready:

1. **#13** before anything that edits package layout
2. **#15** before **#16** (decision must be on the branch #16 builds from)
3. **#14** and **#16** before **#17** (either order vs each other)
4. **#17** before **#18**
5. **#18**, **#19**, **#21** before **#20** (any order among those three)
6. **#20** → **#22** → **#23** → **#24**

Prefer small PRs into `feature/swift-package`, not lane-to-lane merges.

## Agent / human split

| Kind | Good for agents in parallel worktrees | Prefer human / HITL |
|---|---|---|
| AFK | #13, #14, #15, #16, #17, #18, #20, #22, #23 | — |
| Keynote-bound | — | #19 (regen), #21 (author blank template), #24 (open five decks) |

Run at most **one** Keynote-bound lane at a time on a given Mac.

## Conflict hotspots

| Area | Who touches it | Rule |
|---|---|---|
| `Package.swift` | #13 primarily; later tickets add deps sparingly | After #13, only add a dependency in the ticket that owns that product |
| `KeynoteKit` | #21 (thin), then #20–#24 | Finish #21 before #20 starts if both touch write entry |
| `.claude/PLAN.md` decision log | #15, #22 | Tiny additive edits; rebase carefully |
| GitHub issues (#13–#24) | Claim / close / unlock dependents | Source of truth; see map #12 |
| Goldens / samples | #19 | Don’t let #20 rewrite goldens — only consume them |

## Checklist per lane session

1. Create/update worktree from current `feature/swift-package`.
2. Claim the ticket (`gh issue edit <n> --add-assignee @me`).
3. Implement until the ticket’s acceptance checklist is green.
4. Open PR → merge to `feature/swift-package`.
5. Delete lane branch / remove worktree (or reset branch for the next ticket in-lane).
6. Close the GitHub issue; dependents unblock via native `blocked_by` edges.

## What not to do

- Don’t put two lanes in one worktree with uncommitted cross-product edits.
- Don’t start #17 “early” against unmerged #14/#16 branches — integrate first.
- Don’t run #19 and #24 (or #21’s Keynote authoring) at the same time on one app.
- Don’t implement `#10` ScriptingBridge in the authoring lane — separate product, later issue.
