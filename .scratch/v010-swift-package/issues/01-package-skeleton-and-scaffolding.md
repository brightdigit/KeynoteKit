# 01 — Package skeleton + products + scaffolding

**What to build:** An empty Swift 6.4 package that declares the five v0.1 products
(`Snappy`, `IWAFraming`, `KeynoteKitProtobuf`, `KeynoteKit`, `KeynoteKitScripting`),
wires BrightDigit scaffolding (lint/format/CI from SyndiKit, macOS-only, 6.4+),
and builds cleanly. `KeynoteKitScripting` is an empty reserved product; `KeynoteKit`
must not link ScriptingBridge. Overlaps GitHub [#9](https://github.com/brightdigit/KeynoteKit/issues/9).

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `Package.swift` tools-version 6.4; all five products/targets declared with the
      dependency direction from PLAN Step 0
- [ ] Empty package builds and tests on Swift 6.4 (Xcode-beta or swiftly snapshot)
- [ ] `KeynoteKit` does not import or link ScriptingBridge
- [ ] `KeynoteKitScripting` product exists (stub OK)
- [ ] SyndiKit-style lint/CI scaffolding present; root `mise.toml` research tasks
      preserved
- [ ] `Scripts/lint.sh` clean

---

## GitHub issue body (for `gh issue create`)

## What to build

An empty Swift 6.4 package that declares the five v0.1 products (`Snappy`,
`IWAFraming`, `KeynoteKitProtobuf`, `KeynoteKit`, `KeynoteKitScripting`), wires
BrightDigit scaffolding (lint/format/CI from SyndiKit, macOS-only, 6.4+), and
builds cleanly. `KeynoteKitScripting` is an empty reserved product; `KeynoteKit`
must not link ScriptingBridge. Overlaps #9.

## Acceptance criteria

- [ ] `Package.swift` tools-version 6.4; all five products/targets declared with the dependency direction from PLAN Step 0
- [ ] Empty package builds and tests on Swift 6.4
- [ ] `KeynoteKit` does not import or link ScriptingBridge
- [ ] `KeynoteKitScripting` product exists (stub OK)
- [ ] SyndiKit-style lint/CI scaffolding present; root `mise.toml` research tasks preserved
- [ ] `Scripts/lint.sh` clean

## Blocked by

None — can start immediately.
