# 09 — Minimal bundled template (`KeynoteKit` resource)

**What to build:** A minimal hand-authored blank-theme `.key` shipped as a
SwiftPM resource on `KeynoteKit` (`.copy`, not `.process`). `deck.write(to:basedOn:)`
defaults to it. Full rationale: GitHub [#7](https://github.com/brightdigit/KeynoteKit/issues/7).

**Blocked by:** 01 — Package skeleton + products + scaffolding

**Status:** ready-for-agent

- [ ] Minimal blank-theme `.key` authored and committed as a package resource
- [ ] Resource registered with `.copy(...)` (directory-shaped bundle)
- [ ] `write(to:basedOn:)` exists with bundled default
- [ ] Redistribution caveat acknowledged per #7

---

## GitHub issue body (for `gh issue create`)

## What to build

A minimal hand-authored blank-theme `.key` shipped as a SwiftPM resource on
`KeynoteKit`. `deck.write(to:basedOn:)` defaults to it. See #7.

## Acceptance criteria

- [ ] Minimal blank-theme `.key` shipped as a package resource
- [ ] Registered with `.copy(...)` (directory-shaped bundle)
- [ ] `write(to:basedOn:)` exists with bundled default
- [ ] Redistribution caveat acknowledged per #7

## Blocked by

- 01 — Package skeleton + products + scaffolding
