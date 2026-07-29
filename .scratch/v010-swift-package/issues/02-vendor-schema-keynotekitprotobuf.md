# 02 — Vendor schema + registry (`KeynoteKitProtobuf`)

**What to build:** The `KeynoteKitProtobuf` product contains checked-in Swift types
generated from the vendored Keynote 15.3 protos, plus the 14.4
`TSPRegistryMapping` (type ID → message name). No `protoc` at consumer build
time. Every archive type named in the research findings can be decoded.

**Blocked by:** 01 — Package skeleton + products + scaffolding

**Status:** ready-for-agent

- [ ] Generated sources live in `KeynoteKitProtobuf` and are committed
- [ ] `TSPRegistryMapping` ported (e.g. BuildArchive / BuildChunkArchive IDs)
- [ ] Build does not require `protoc` on the consumer machine
- [ ] Every archive type named in the findings decodes from its `.proto`

---

## GitHub issue body (for `gh issue create`)

## What to build

The `KeynoteKitProtobuf` product contains checked-in Swift types generated from
the vendored Keynote 15.3 protos, plus the 14.4 `TSPRegistryMapping`. No `protoc`
at consumer build time. Every archive type named in the research findings can be
decoded.

## Acceptance criteria

- [ ] Generated sources live in `KeynoteKitProtobuf` and are committed
- [ ] `TSPRegistryMapping` ported
- [ ] Build does not require `protoc` on the consumer machine
- [ ] Every archive type named in the findings decodes from its `.proto`

## Blocked by

- 01 — Package skeleton + products + scaffolding
