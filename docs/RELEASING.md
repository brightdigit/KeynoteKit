# Releasing KeynoteKit

The demo `.key`, the movie, and the slide-image screenshots can only be
produced by a human on a Mac running Keynote.

**None of this is CI-verified.** No CI job generates or checks these
artifacts, and none can until a self-hosted macOS runner lands
([#8](https://github.com/brightdigit/KeynoteKit/issues/8)). Everything below
is a manual procedure, and the artifacts silently rot as the API changes
unless someone runs it.

## When this is required

Refresh the artifacts when any of these change:

- the public DSL surface (a rename, a new modifier, a changed default)
- the demo deck's source
- anything that alters how a deck renders — the surgeon's style forks,
  geometry, or text layout

A release that changes none of those can ship with the existing artifacts.

## Prerequisites

- macOS with **Keynote 15.3**. On this machine it lives at
  `/Applications/Keynote Creator Studio.app` (bundle id `com.apple.Keynote`).
- Swift 6.4:
  `export DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer`
- For the `.mov` → `.mp4` conversion: `ffmpeg` (`brew install ffmpeg`).

> **Keynote autosaves in place.** A deck Keynote has opened — especially one
> driven by AppleScript — must be treated as modified. Always work on a copy,
> and never let Keynote open a pristine template or fixture directly.

## 1. Regenerate the demo `.key`

> The demo target ships with
> [#56](https://github.com/brightdigit/KeynoteKit/issues/56). Until it lands,
> substitute `swift run AcceptanceDecks <dir>` — the same structural
> self-check runs over the acceptance catalog.

```bash
export DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer
xcrun swift run KeynoteKitDemo ~/Desktop/keynotekit-demo
```

The write path self-checks as it goes: every record must decode, and the
UUID-map invariants must hold. A structural pass here means the file is
well-formed — it does **not** mean Keynote will open it, and it does not mean
the deck looks right.

## 2. Open it in Keynote and eyeball the render

```bash
cp ~/Desktop/keynotekit-demo/demo.key ~/Desktop/demo-review.key
open ~/Desktop/demo-review.key
```

Confirm, in order:

1. **No crash.** A SIGTRAP on open means a document-level invariant broke.
2. **No repair dialog.** A silent "repair" is a failure, not a pass — Keynote
   rewriting the file means we wrote something it rejected.
3. **Every slide renders as intended.** Text present and styled, images
   present, panels filled, layout unbroken.
4. **Animations play.** Step through the deck; confirm transitions and builds
   fire in the authored order.

An open pass is not a render pass. A deck can open cleanly with drawables
that never painted — check what is actually on screen.

## 3. Export the movie

Scripted, via `KeynoteKitScripting`:

```swift
import KeynoteKitScripting

let keynote = try KeynoteScriptingApplication()
let document = try keynote.openDocument(at: URL(filePath: "…/demo-review.key"))
try document.export(to: movieURL, format: .quickTimeMovie)
```

Two things routinely interrupt this:

- **Automation permission (TCC).** The first run raises a system prompt
  asking to control Keynote. Grant it. Until then the Apple Event fails, and
  the failure surfaces as an error rather than a dialog you can click.
- **An options sheet.** Keynote may present export options and wait. The
  scripted path is not reliably non-interactive.

**Fallback — do this if the scripted path stalls.** In Keynote:
File → Export To → Movie…, then choose a resolution and export. The manual
route is the supported one for releases; the scripted path is a convenience.

Export at **1080p** unless the deck's content demands more.

## 4. Export slide images

Per-slide PNGs are lighter than video and should carry most of the visual
load in the README and DocC.

```swift
try document.export(to: imagesURL, format: .slideImages)
```

Or manually: File → Export To → Images…, PNG, all slides.

## 5. Convert the movie for DocC

DocC's `@Video` needs **H.264 `.mp4`**, not QuickTime `.mov`. Keynote exports
`.mov`, so convert:

```bash
ffmpeg -i demo.mov -c:v libx264 -pix_fmt yuv420p -crf 23 -movflags +faststart demo.mp4
```

`-pix_fmt yuv420p` matters for browser compatibility; without it Safari may
refuse the file. `+faststart` moves the index to the front so the video
starts before it has fully downloaded.

## 6. Commit the artifacts

| Artifact | Location | Used by |
|---|---|---|
| Demo `.key` | `Documentation/demo/demo.key` | README download link |
| Movie (`.mp4`) | `Sources/KeynoteKit/KeynoteKit.docc/Resources/` | DocC `@Video` |
| Slide images | `Sources/KeynoteKit/KeynoteKit.docc/Resources/` | DocC + README |

Keep the `.mov` out of the repository — commit only the converted `.mp4`.

Use the video **once**, on the Getting Started page. Slide images should
carry the rest.

## 7. Release checklist

- [ ] Demo `.key` regenerated and structurally green
- [ ] Opened in Keynote 15.3: no crash, no repair, renders correctly,
      animations play
- [ ] Movie exported and converted to H.264 `.mp4`
- [ ] Slide images exported
- [ ] Artifacts committed to the locations above
- [ ] README code samples still compile against the shipped API
- [ ] DocC builds
- [ ] Tag

## Why none of this is automated

Keynote is a GUI application driven by Apple Events. Rendering, exporting,
and visual confirmation all require a logged-in macOS session with Keynote
installed and Automation permission granted — which no hosted CI runner
provides.

[#8](https://github.com/brightdigit/KeynoteKit/issues/8) tracks a self-hosted
macOS runner. Until it lands, treat every artifact in the table above as
human-generated and human-verified, and re-run this procedure whenever the
API or the demo changes.
