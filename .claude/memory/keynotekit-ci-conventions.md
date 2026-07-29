---
name: keynotekit-ci-conventions
description: "CI follows the BrightDigit/SyndiKit pattern, Xcode 27 only, cross-platform with canImport gating; never pass a scheme to swift-build"
metadata: 
  node_type: memory
  type: project
  originSessionId: af41e9c9-1173-4070-ae51-57d87928b13a
  modified: 2026-07-29T15:47:42.580Z
---

CI follows the BrightDigit pattern (SyndiKit at
`~/Documents/Projects/SyndiKit/mellow-pine/` is the reference): jobs use
`brightdigit/swift-build@v1`, `./.github/actions/setup-tools`,
`actions/checkout@v6`, and a two-tier `configure` job reading matrix rows from
`.github/matrices/`. Do not hand-roll `run: swift build` steps.

**Never pass `scheme:` to `brightdigit/swift-build@v1`.** It skips the action's
"Calculate Scheme" step, and the product name resolves to a scheme `xcodebuild`
reports as having no supported platforms — every platform leg fails. SwiftPM's
buildable aggregate is `<Package>-Package`; the action derives it correctly when
the input is omitted.

**Xcode 27.0 only** (`runs-on: xcode-27` paired with
`xcode: /Applications/Xcode_27.0.app`). Simulator `osVersion` is **27.0** on
every platform — Xcode 27 ships 27.0 SDKs throughout. Do not copy SyndiKit's
26.5/Xcode 26.6 rows.

**The package is cross-platform, not macOS-only** — this overrode PLAN.md Step 0.
Only `KeynoteKitScripting` is Apple-specific, gated with
`#if canImport(ScriptingBridge)`. Never use `.linkedFramework("ScriptingBridge")`
— a manifest-level linker flag breaks Linux unconditionally. The Ubuntu CI job
exists to catch portability regressions.

Anything older than Swift 6.4 is pointless here: the manifest is tools-version
6.4, so older containers/Xcodes fail at parse. That is why source-compat and the
devcontainer are 6.4-only.

**How to apply:** when adding CI legs, copy SyndiKit's shape but keep the 6.4 and
Xcode-27 narrowing. See [[keynotekit-swift-64-only]] and
[[keynotekit-integration-branch]].
