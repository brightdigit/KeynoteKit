# 04 — Snappy block codec (`Snappy`)

**What to build:** The `Snappy` product implements (or wraps, per ticket 03) the
generic **block** codec — nothing Apple-specific. Callers can compress and
decompress Snappy blocks correctly. Hard seam preserved so #5 can later replace
vendoring with a package dependency via `Package.swift` only.

**Blocked by:** 01 — Package skeleton + products + scaffolding; 03 — Survey Snappy block-level packages

**Status:** ready-for-agent

- [ ] `Snappy` public API is block-level only (no Apple framing)
- [ ] Compress/decompress round-trips known block vectors
- [ ] Implementation follows ticket 03’s depend-vs-vendor decision
- [ ] No Apple/`IWAFraming` types leak into `Snappy`

---

## GitHub issue body (for `gh issue create`)

## What to build

The `Snappy` product implements (or wraps) the generic block codec — nothing
Apple-specific. Callers can compress and decompress Snappy blocks correctly.
Hard seam preserved so moving to an external dependency (#5) is a Package.swift
edit.

## Acceptance criteria

- [ ] `Snappy` public API is block-level only (no Apple framing)
- [ ] Compress/decompress round-trips known block vectors
- [ ] Implementation follows the survey’s depend-vs-vendor decision
- [ ] No Apple framing types leak into `Snappy`

## Blocked by

- 01 — Package skeleton + products + scaffolding
- 03 — Survey Snappy block-level packages
