# 05 — IWA framing + `.key` zip semantic round-trip (`IWAFraming`)

**What to build:** Apple chunk framing over the block codec, plus the `.key` zip
bundle layer, in `IWAFraming` (calling only `Snappy`’s public API). For all 24
committed fixtures: unpack → repack → unpack yields an **identical archive
graph** (semantic gate). Byte-identity is a diagnostic only — run it, record
the result, do not block on it.

**Blocked by:** 02 — Vendor schema + registry; 04 — Snappy block codec

**Status:** ready-for-agent

- [ ] Stack works: zip → `.iwa` → Apple-framed Snappy → `TSP.ArchiveInfo` + protobuf
- [ ] `IWAFraming` does not reach into `Snappy` internals
- [ ] All 24 fixtures: unpack → repack → unpack; archive graphs identical
- [ ] Byte-comparison experiment run and result recorded (gate remains semantic)

---

## GitHub issue body (for `gh issue create`)

## What to build

Apple chunk framing over the block codec, plus the `.key` zip bundle layer, in
`IWAFraming`. For all 24 committed fixtures: unpack → repack → unpack yields an
identical archive graph (semantic gate). Byte-identity is diagnostic only.

## Acceptance criteria

- [ ] Stack works: zip → `.iwa` → Apple-framed Snappy → ArchiveInfo + protobuf
- [ ] `IWAFraming` does not reach into `Snappy` internals
- [ ] All 24 fixtures pass semantic archive-graph round-trip
- [ ] Byte-comparison experiment run and result recorded

## Blocked by

- 02 — Vendor schema + registry
- 04 — Snappy block codec
