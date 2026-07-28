# Corrections log

Append-only. Source of truth for corrections and explicit always/never directives.
One concise line per entry, in the exact meaning of the instruction. Never
rewrite, reorder, or delete prior entries.

- 2026-07-17: Whenever the user corrects me or gives an explicit "always"/"never" directive, immediately append one concise line here; keep the file append-only — never rewrite, reorder, or delete prior notes.
- 2026-07-17: Keep the corrections log and its loader instruction inside the repo (committed every time), not in global ~/.claude.
- 2026-07-17: Keep CORRECTIONS.md in the repo's .claude/ directory (not the repo root).
- 2026-07-17: "Continue the unattended pieces" means process the pending fixture experiments as they land (and approved prep tooling), NOT start the pack/write-backend Option A work.
- 2026-07-18: Proceed unattended with the Option A pack/write-backend work, and create a new build_setup file listing what is needed from the user.
- 2026-07-18: Opening the authored acceptance deck crashes Keynote 15.3 with EXC_BREAKPOINT/SIGTRAP in the Keynote animation framework; this is not merely an AppleScript object-access limitation.
- 2026-07-28: Resolves the 2026-07-18 entry — the crash was two missing document-level invariants in authored builds: every KN.BuildArchive id must be registered in Metadata.iwa.yaml TSP.PackageMetadata -> the slide's component -> objectUuidMapEntries with uuid == the KN.BuildChunkArchive's buildId, and lastObjectIdentifier must stay above every minted archive id. Fixed in tools/archive_backend.py; authored decks now reopen cleanly.
