# KeynoteKit

## Corrections log (append-only)

Whenever the user corrects me, or gives an explicit "always" or "never" directive,
immediately append one concise line to `CORRECTIONS.md` at the repo root, capturing
the exact meaning of the instruction (not an interpretation). That file is
append-only and the source of truth for corrections: preserve all existing entries;
never rewrite, reorder, or delete prior notes. Read it at the start of work and
honor every entry.

## Agent skills

### Issue tracker

Issues and PRDs are tracked as **GitHub issues** (`gh` CLI) in `brightdigit/KeynoteKit`. See `docs/agents/issue-tracker.md`.

### Domain docs

**Single-context**: one `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.
