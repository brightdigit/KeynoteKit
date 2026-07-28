# Agent notes (memory & corrections)

Read this file at the start of every session before doing work.
Append one line per directive proactively (without being asked) whenever the
user makes a correction or gives an always/never instruction.
Newest lines at the bottom; one line per entry.
When a directive supersedes an earlier one, update or remove the stale line
rather than leaving both.

- 2026-07-17: Keep the corrections/memory log and its loader instruction inside the repo (committed), not in global ~/.claude.
- 2026-07-17: Keep the corrections/memory log in the repo's `.claude/` directory (not the repo root).
- 2026-07-18: Proceed unattended with the Option A pack/write-backend work, and create a new build_setup file listing what is needed from the user. (Supersedes earlier "Continue the unattended pieces" meaning for fixture experiments only.)
- 2026-07-28: Authored Keynote 15.3 crash (EXC_BREAKPOINT/SIGTRAP in animation framework) was two missing document-level invariants: every KN.BuildArchive id must be registered in Metadata.iwa.yaml TSP.PackageMetadata → the slide's component → objectUuidMapEntries with uuid == the KN.BuildChunkArchive's buildId, and lastObjectIdentifier must stay above every minted archive id. Fixed in tools/archive_backend.py; authored decks now reopen cleanly.
- 2026-07-28: Use `.claude/agent-notes.md` as the versioned in-repo source of truth for corrections and standing always/never directives; read it first every session; append one line per new directive; when superseding, update or remove the stale line.
