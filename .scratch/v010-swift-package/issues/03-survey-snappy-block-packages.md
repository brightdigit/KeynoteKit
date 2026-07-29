# 03 — Survey Snappy block-level packages

**What to build:** A decision, recorded in PLAN’s decision log: whether an
existing Swift package exposes **block-level** Snappy compress/decompress (pure
Swift vs C++ shim). If yes, `Snappy` becomes a thin wrapper/dependency; if no,
vendor the block codec as planned (#5 remains the eventual exit). This is
research only — no codec implementation required here.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Survey covers packages that expose block-level APIs (not stream-only)
- [ ] Pure Swift vs C++ shim noted for each candidate
- [ ] Decision (depend vs vendor) written into PLAN decision log
- [ ] Recommendation is actionable for ticket 04

---

## GitHub issue body (for `gh issue create`)

## What to build

A decision, recorded in PLAN’s decision log: whether an existing Swift package
exposes block-level Snappy compress/decompress (pure Swift vs C++ shim). If yes,
`Snappy` becomes a thin wrapper/dependency; if no, vendor the block codec (#5
remains the eventual exit). Research only — no codec implementation here.

## Acceptance criteria

- [ ] Survey covers packages that expose block-level APIs (not stream-only)
- [ ] Pure Swift vs C++ shim noted for each candidate
- [ ] Decision (depend vs vendor) written into PLAN decision log
- [ ] Recommendation is actionable for the Snappy codec ticket

## Blocked by

None — can start immediately.
