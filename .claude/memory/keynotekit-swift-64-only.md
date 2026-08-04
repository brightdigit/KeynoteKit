---
name: keynotekit-swift-64-only
description: KeynoteKit targets Swift 6.4 (dev) and newer only — build via Xcode-beta DEVELOPER_DIR or swiftly 6.4.x-snapshot, never the default 6.3.2
metadata:
  node_type: memory
  type: project
---

KeynoteKit supports **only Swift 6.4 (dev) and newer**. The machine's default
toolchain is 6.3.2 (`swift --version`, `/Applications/Xcode.app`) — do NOT build
or test with it.

Two working 6.4 toolchains as of 2026-07-28:

- **Xcode-beta (preferred for normal builds)** — release-configured Swift 6.4
  (`swiftlang-6.4.0.27.1`), no assertion overhead:
  `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun swift build`
- **swiftly snapshot (secondary check)** — 6.4-dev with `+assertions`, catches
  more but runs slower:
  `swiftly run swift build +6.4.x-snapshot-2026-06-15`
  (`6.4.x-snapshot-2026-06-10` also installed)

Set `// swift-tools-version: 6.4` in `Package.swift`. No
`Package@swift-*.swift` back-compat shims — the floor is 6.4.

**Why:** the user explicitly corrected an attempt to proceed on 6.3.2. **How to
apply:** prefix every swift/SwiftPM invocation in this repo with the Xcode-beta
`DEVELOPER_DIR`, or use `swiftly run ... +6.4.x-snapshot-*`. Related:
[[keynotekit-env-gotchas]], [[keynotekit-v010-scope]].
