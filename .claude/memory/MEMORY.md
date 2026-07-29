# Memory index

- [KeynoteKit v0.1.0 scope](keynotekit-v010-scope.md) — authoring not reading; template surgery not synthesis; what "self-contained" and "from scratch" actually mean
- [KeynoteKit Swift 6.4 only](keynotekit-swift-64-only.md) — build via Xcode-beta DEVELOPER_DIR or swiftly 6.4.x-snapshot, never the default 6.3.2
- [KeynoteKit env gotchas](keynotekit-env-gotchas.md) — reinstall keynote-parser + `mkdir -p samples` each fresh session, else FileNotFoundError / save -10000
- [Pack Option A viable](pack-option-a-viable.md) — pack works on 15.3 via 14.4 registry + 15.3 protos; hybrid is now vendored in-repo and rebuilds reproducibly
- [Memories live in repo](memories-live-in-repo.md) — mirror every memory into `.claude/memory/` in the repo, keep in sync with the global copy
- [KeynoteKit integration branch](keynotekit-integration-branch.md) — `v0.1.x` is integration; lane branches are slash-free issue names off it
- [KeynoteKit CI conventions](keynotekit-ci-conventions.md) — BrightDigit pattern, Xcode 27 only, cross-platform via canImport; never pass `scheme:` to swift-build
- [KeynoteKit v0.1.0 progress](keynotekit-v010-progress.md) — container stack (#13–#16, #19, #21) merged on `v0.1.x`; #17 IWAFraming is the frontier; three measured constraints not to re-derive
