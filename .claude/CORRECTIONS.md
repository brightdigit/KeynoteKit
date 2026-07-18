# Corrections log

Append-only. Source of truth for corrections and explicit always/never directives.
One concise line per entry, in the exact meaning of the instruction. Never
rewrite, reorder, or delete prior entries.

- 2026-07-17: Whenever the user corrects me or gives an explicit "always"/"never" directive, immediately append one concise line here; keep the file append-only — never rewrite, reorder, or delete prior notes.
- 2026-07-17: Keep the corrections log and its loader instruction inside the repo (committed every time), not in global ~/.claude.
- 2026-07-17: Keep CORRECTIONS.md in the repo's .claude/ directory (not the repo root).
