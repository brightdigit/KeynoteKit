---
name: keynotekit-integration-branch
description: v0.1.x is the integration branch (feature/swift-package was squashed into it); lane branches use slash-free GitHub issue names
metadata: 
  node_type: memory
  type: project
  originSessionId: af41e9c9-1173-4070-ae51-57d87928b13a
  modified: 2026-07-29T15:47:32.841Z
---

The v0.1.0 integration branch is **`v0.1.x`**. The former `feature/swift-package`
branch was squashed into it (`62a68f3` / PR #11) and no longer carries work — a
stale copy may still exist on the remote.

Lane branches use **standard GitHub issue branching with no slashes**:
`13-package-skeleton`, not `v010/13-scaffold`. This overrides the older
convention in `.claude/PARALLEL-WORKTREES.md`, which has been updated to match.

Create lanes with raw `git worktree add --no-track -b <n>-<slug> ../wt-<lane>
origin/v0.1.x` from the repo root. Not `git trees add` — it derives the directory
name from the branch and pushes immediately. `--no-track` stops the lane branch
inheriting `v0.1.x`'s upstream and silently pushing to integration.

**Why:** lanes branched from a squashed-away branch cannot be merged back, and a
lane that tracks integration can push to it by accident.

**How to apply:** base every new ticket lane on `origin/v0.1.x` and PR back into
it. See [[keynotekit-v010-scope]] and [[keynotekit-ci-conventions]].
