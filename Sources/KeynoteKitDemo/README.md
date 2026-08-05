# KeynoteKitDemo

The [#56](https://github.com/brightdigit/KeynoteKit/issues/56) showcase
presentation — a sample deck authored with the public KeynoteKit API, kept
out of the core library so demo-only code never reaches consumers who only
need `KeynoteKit`.

## Products

| Product | Kind | Role |
|---|---|---|
| `KeynoteKitDemo` | library | Public `DemoPresentation.deck` |
| `KeynoteKitDemoTool` | executable | Writes `demo.key` and structurally self-checks |

```bash
export DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer
xcrun swift run KeynoteKitDemoTool ~/Desktop/keynotekit-demo
```

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
