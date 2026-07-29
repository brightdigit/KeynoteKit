# 08 — Writer: builds match goldens + invariants (`KeynoteKit`)

**What to build:** Archive surgery in `KeynoteKit` that can re-emit the five
golden decks: mint builds/buildChunks, flip `hasExplicitBuilds`, and enforce
`objectUuidMapEntries` + `lastObjectIdentifier` (port `_verify_uuid_map` as a
precondition). Differential match against Python goldens plus standalone
invariant assertions.

**Blocked by:** 06 — Archive navigation; 07 — Regenerate & commit Python golden decks

**Status:** ready-for-agent

- [ ] Swift re-emits all five goldens; archive graphs match committed Python
      goldens
- [ ] Standalone asserts: build archives exist, each `buildId` registered in
      `objectUuidMapEntries`, `lastObjectIdentifier` exceeds every minted id
- [ ] Write path does not require a running Keynote

---

## GitHub issue body (for `gh issue create`)

## What to build

Archive surgery in `KeynoteKit` that re-emits the five golden decks: mint
builds/buildChunks, flip `hasExplicitBuilds`, enforce `objectUuidMapEntries` +
`lastObjectIdentifier`. Differential match against Python goldens plus
standalone invariant assertions.

## Acceptance criteria

- [ ] Swift re-emits all five goldens; archive graphs match
- [ ] Standalone uuid-map / lastObjectIdentifier invariants assert green
- [ ] Write path does not require a running Keynote

## Blocked by

- 06 — Archive navigation
- 07 — Regenerate & commit Python golden decks
