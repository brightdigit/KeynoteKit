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
- 2026-07-28: KeynoteKit supports only Swift 6.4 (dev) and newer; build via `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun swift ...` or `swiftly run swift ... +6.4.x-snapshot-2026-06-15`, never the default 6.3.2 toolchain.
- 2026-07-28: KeynoteKit's goal is AUTHORING a .key from Swift; reading a .key is explicitly NOT a v0.1.0 feature (archive navigation is internal test infrastructure only; the public reading API is issue #6).
- 2026-07-28: v0.1.0 authors by byte-surgery on a bundled minimal template, not by synthesizing a package from nothing (issue #2). "Self-contained" means no Python/keynote-parser/mise/AppleScript at RUNTIME — it does not mean zero dependencies (swift-protobuf is a dependency; a template .key ships as a resource).
- 2026-07-28: ScriptingBridge/AppleScript is a public escape hatch for developers (issue #10), never an authoring backend — `deck.write(to:)` must never require a running Keynote. Expose it as a separate product `KeynoteKitScripting`; `KeynoteKit` must not link ScriptingBridge.
- 2026-07-28: Verification gates are STRUCTURAL, not byte-identical; Keynote requires the file be accepted, not byte-equal to an original. Byte-comparison is a diagnostic only.
- 2026-07-28: Prefer fine-grained SwiftPM products/targets by default (there is usually no cost to splitting); do not collapse layers into one product for convenience.
