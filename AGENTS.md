# KeynoteKit

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
