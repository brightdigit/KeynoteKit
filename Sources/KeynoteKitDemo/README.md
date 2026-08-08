# KeynoteKitDemo

The [#56](https://github.com/brightdigit/KeynoteKit/issues/56) showcase
presentation — a sample deck authored with the public KeynoteKit API, kept
out of the core library so demo-only code never reaches consumers who only
need `KeynoteKit`.

## Products

| Product | Kind | Role |
|---|---|---|
| `KeynoteKitDemo` | library | Public `DemoDeck`, a `Presentation` |
| `KeynoteKitDemoTool` | executable | Writes `demo.key` and structurally self-checks |

```bash
export DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer
xcrun swift run KeynoteKitDemoTool ~/Desktop/keynotekit-demo
```

## Layout

| Path | Role |
|---|---|
| `DemoDeck.swift` | A `Presentation`: its `body` is the **slide order**, and the target's only public API |
| `Slides/` | One file per slide, each a `SlideContent` type |
| `Support/` | `DemoStyle` (margin, type scale) and `DemoResources` (`Bundle.module` media) |

To add a slide: create `Slides/YourSlide.swift` conforming to `SlideContent`,
then add `YourSlide()` to `DemoDeck.deck` where it belongs in the running
order. Take shared values from `DemoStyle` rather than restating them.

A slide may resolve to nothing — `ImageSlide` does when its resource is
missing — so entries in `DemoDeck` stay unconditional and each slide owns
the question of whether it can be built.

Slides carry explicit heights because text cannot measure itself yet
([#67](https://github.com/brightdigit/KeynoteKit/issues/67)). Widths are
never named: a stack child fills the cross axis by default.

## Status

**Scaffold.** One title slide proves the write path. The finished deck is a
15–20 slide tutorial highlighting:

- slide transitions and object builds
- layout primitives (`VStack` / `HStack` / `ZStack`)
- monospace / syntax-highlighted code (`KeynoteKitSyntax`)
- filled code panels (background fill)
- text formatting and Magic Move

A structural pass from the tool means the archive is well-formed. Opening
and eyeballing in Keynote 15.3 is still a separate human gate — see
`docs/RELEASING.md`.
