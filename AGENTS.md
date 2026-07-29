# KeynoteKit

## What this project is

A Swift package that **authors** Keynote `.key` files — slide transitions and
object builds — by writing the format directly, with no Python, `keynote-parser`,
`mise`, or AppleScript at runtime.

**Start here:**

1. **`PLAN.md`** (repo root) — the v0.1.0 goal, 7 gated steps, the two real
   risks, and a decision log explaining *why* each choice was made. Read before
   proposing architecture.
2. **`.claude/agent-notes.md`** — standing directives (below).
3. **`.claude/memory/keynotekit-v010-scope.md`** — scope decisions a fresh
   session is likely to get wrong by reasonable-sounding inference (e.g. that
   reading a `.key` is in scope, or that "from scratch" means no template).

**`research/`** holds the completed reverse-engineering that this package is
built from: `research/findings/` is the format spec, `research/tools/` is the
working Python reference backend, and `research/fixtures/` has 24 human-authored
`.key` files used as test corpus. Treat findings as established — don't
re-derive them. `research/findings/HANDOFF.md` is that phase's own resume point.

Active v0.1.0 work: GitHub map
[#12](https://github.com/brightdigit/KeynoteKit/issues/12) (tickets #13–#24);
parallel lanes in [`.claude/PARALLEL-WORKTREES.md`](.claude/PARALLEL-WORKTREES.md).
Deferred past v0.1.0: issues [#2](https://github.com/brightdigit/KeynoteKit/issues/2)–[#10](https://github.com/brightdigit/KeynoteKit/issues/10).

## Memory & Corrections Convention

`.claude/agent-notes.md` is the source of truth for how to work in this repo:
corrections and standing always/never directives. Read it at the start of every
session before doing work. Append one line per directive proactively (without
being asked) whenever the user makes a correction or gives an always/never
instruction. Newest lines at the bottom; one line per entry. When a directive
supersedes an earlier one, update or remove the stale line rather than leaving
both.

## Agent skills

### Issue tracker

Issues and PRDs are tracked as **GitHub issues** (`gh` CLI) in `brightdigit/KeynoteKit`. See `docs/agents/issue-tracker.md`.

### Domain docs

**Single-context**: one `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.
