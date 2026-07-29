# 06 — Archive navigation (extract_builds parity)

**What to build:** Internal (test-infrastructure) navigation: decode `.iwa` into
typed protobuf messages and walk the graph enough to reproduce Python
`deckkit.extract_builds` results on the 24 fixtures — compared at **archive
level**. Not a public `Deck(readingKeynoteAt:)` API (#6).

**Blocked by:** 05 — IWA framing + `.key` zip semantic round-trip

**Status:** ready-for-agent

- [ ] Can locate slides, builds, buildChunks, and drawable targets in fixtures
- [ ] Swift extract results match Python `extract_builds` on all 24 fixtures
      (archive-level comparison)
- [ ] No public reading API shipped

---

## GitHub issue body (for `gh issue create`)

## What to build

Internal navigation: decode `.iwa` into typed protobuf and walk the graph enough
to reproduce Python `deckkit.extract_builds` on the 24 fixtures at archive level.
Not a public reading API (#6).

## Acceptance criteria

- [ ] Can locate slides, builds, buildChunks, and drawable targets in fixtures
- [ ] Swift matches Python `extract_builds` on all 24 fixtures (archive-level)
- [ ] No public reading API shipped

## Blocked by

- 05 — IWA framing + `.key` zip semantic round-trip
