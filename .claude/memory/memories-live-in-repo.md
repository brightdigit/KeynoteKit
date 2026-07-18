---
name: memories-live-in-repo
description: "mirror every memory into the repo at .claude/memory/, not just the global ~/.claude memory dir"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: e111f2e3-89a7-4cf2-9d9b-5fe4a7d2a7e6
  modified: 2026-07-18T11:39:39.422Z
---

The user wants all memories version-controlled in the repo, not only in the
global auto-memory dir.

**Why:** the global `~/.claude/.../memory/` is per-machine and outside git — a
teammate cloning the repo (or a fresh machine) never sees it. Findings + memories
should travel with the code.

**How to apply:** whenever you write/update a memory file under the global memory
dir, mirror the same file (and the updated `MEMORY.md` index) into
**`.claude/memory/`** in the repo (`/Users/leo/Documents/Projects/KeynoteKit/prototype`),
and include it in the commit. `.claude/` is already tracked here (see
`.claude/CORRECTIONS.md`). Keep the two copies in sync.
