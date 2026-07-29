---
name: keynotekit-v010-scope
description: KeynoteKit v0.1.0 scope — authoring only (not reading), template surgery (not synthesis), what "self-contained" and "from scratch" actually mean
metadata:
  node_type: memory
  type: project
---

Scope decisions for the Swift package, made 2026-07-28. A fresh session is
likely to get these wrong by reasonable-sounding inference, so check here first.
Full reasoning + decision log: `.claude/PLAN.md` on `feature/swift-package`.

**The goal is AUTHORING a `.key` from Swift.** Reading one is explicitly not a
v0.1.0 feature. Archive-level navigation IS built, but only as internal test
infrastructure (the writer must parse the template; every gate reads our own
output). A public `Deck(readingKeynoteAt:)` is issue #6, not v0.1.0.

**Two phrases that mislead:**

- **"Self-contained"** = no Python / keynote-parser / mise / AppleScript at
  *runtime*. It does NOT mean zero dependencies. swift-protobuf is a dependency,
  and a template `.key` ships as a SwiftPM resource.
- **"From scratch"** = authored from Swift source rather than by hand in
  Keynote. It does NOT mean synthesizing a package with no base deck — v0.1.0
  does byte-surgery on a bundled minimal template. True from-nothing authoring
  is issue #2 and needs theme/master/stylesheet research comparable to Exps 1-11.

**ScriptingBridge is a developer escape hatch (#10), never an authoring
backend.** `deck.write(to:)` must never require a running Keynote. It ships as a
separate product `KeynoteKitScripting`; `KeynoteKit` must not link
ScriptingBridge. Noted because the AppleScript path is tempting: it creates
slides/text items with Keynote maintaining every invariant itself
(`research/tools/deckkit.py:308`), which would sidestep the riskiest part of the
plan — at the cost of self-containment. It is the documented escape route if
slide-duplication proves intractable, not the plan.

**Prefer fine-grained SwiftPM products/targets** — splitting is cheap; collapsing
coupled modules later is not. v0.1 products: `Snappy`, `IWAFraming`,
`KeynoteKitProtobuf`, `KeynoteKit`, `KeynoteKitScripting` (scaffolded).

**Gates are STRUCTURAL, not byte-identical.** Keynote requires the file be
*accepted*, not byte-equal to an original. Snappy leaves the encoder real freedom
and Apple's encoder is closed-source; the Python path never asserted byte-identity
either (`verify_hybrid_parser.py` compares structurally). Byte-comparison is a
diagnostic only.

**Drawable IR is `text`/`x`/`y` only**, at parity with the Python prototype.
Accepted consequence: Magic Move can express a translation but NOT a size or
style change (no width/height/style to differ between slides). Geometry is #3,
shapes/images #4.

Related: [[keynotekit-swift-64-only]], [[keynotekit-env-gotchas]],
[[pack-option-a-viable]].
