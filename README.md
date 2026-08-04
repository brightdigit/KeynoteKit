# KeynoteKit

A Swift package that **authors** Keynote `.key` files — slide transitions and
object builds — by writing the format directly. No Python, `keynote-parser`,
`mise`, or AppleScript at runtime.

```swift
struct TitleSlide: SlideContent {
  var body: some SlideContent {
    Slide {
      Text("Title")
        .magicId("title")
        .position(x: 200, y: 200)
        .build(.in) {
          Dissolve()
            .duration(1)
            .trigger(.onClick)
        }
    }
    .transition(.magicMove.duration(1))
  }
}

let deck = Deck {
  TitleSlide()
}
try deck.write(to: url)  // basedOn: defaults to bundled template
```

**Status:** research is done; the Swift package is in progress on the integration
branch **`v0.1.x`**. The container stack is built and merged — Snappy block
codec, vendored Keynote 15.3 protobuf schema + registry, and the bundled
template. Next up is `IWAFraming` (#17): Apple chunk framing and the `.key` zip
layer. See [`.claude/PLAN.md`](.claude/PLAN.md) for the v0.1.0 goal, gated steps,
and decision log. Active work is tracked under GitHub map
[#12](https://github.com/brightdigit/KeynoteKit/issues/12) (tickets #13–#24).

## Requirements

- **Swift 6.4 (dev) and newer only** (`// swift-tools-version: 6.4`)
- Preferred build:
  `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun swift build`
- Secondary: `swiftly run swift build +6.4.x-snapshot-2026-06-15`

## Layout

```
.claude/PLAN.md         v0.1.0 goal, steps, decision log
Package.swift           (lands with #13)
Sources/                Swift products (Snappy, IWAFraming, …)
research/               completed reverse-engineering (format spec + Python reference)
  findings/             format notes — treat as established
  tools/                Python reference backend (goldens / diagnostics only)
  fixtures/             24 human-authored .key files (test corpus)
  vendor/               Keynote 15.3 protos + 14.4 registry
```

## Research (completed)

The `research/` tree is the finished reverse-engineering phase (squash-merged
as PR #1 / `ab23b45`). It used differential diffing of minimal Keynote pairs to
learn how transitions and builds are represented. Resume notes:
[`research/findings/HANDOFF.md`](research/findings/HANDOFF.md).

Python tooling under `research/` is a **reference backend** for regenerating
golden decks and diagnostics — never a runtime dependency of the Swift package.

To exercise the research harness (needs Keynote + mise):

```
mise trust
mise exec -- python3 -m ensurepip --upgrade
mise exec -- python3 -m pip install 'keynote-parser==1.14.4.0' 'grpcio-tools==1.82.1'
mise run test                     # => DECKKIT TEST PASS
mise run prepare-keynote-parser
mise run verify-pack
```

## Deferred

Past v0.1.0 work is filed as issues
[#2](https://github.com/brightdigit/KeynoteKit/issues/2)–[#10](https://github.com/brightdigit/KeynoteKit/issues/10)
(from-scratch synthesis, geometry, shapes/images, public reading API, CI runner,
ScriptingBridge escape hatch, etc.).
