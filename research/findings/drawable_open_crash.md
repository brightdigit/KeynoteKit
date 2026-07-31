# Drawable open-crash triage (#3 / #37 / #38) — RESOLVED

Status as of 2026-07-30 (branch `3-37-38-drawable-depth`, PR #39): **all
resolved**. All 8 acceptance decks (5 original + 3 drawable-depth) open cleanly
in Keynote 15.3 with no crash and no new `.ips`.

## Root causes (in the order they were found)

### #37 text formatting — fixed earlier this branch

Minted `TSWP.CharacterStyleArchive` lacked `TSS.StyleArchive` `super` with
`stylesheet` → document stylesheet, and was not listed in
`TSS.StylesheetArchive.styles`. Fix: mint `super.stylesheet`, append the style
record to `DocumentStylesheet.iwa`, register on `styles`, put the stylesheet id
on `MessageInfo.objectReferences`.

### #38 images, crash 1 — TSPersistence `abort()` (SIGABRT)

`.ips` fault thread sat in `TSPersistence` → `abort()`. Our image `DataInfo`
and data wiring did not match what Keynote itself writes when inserting a photo
into the same blank. Fixed by matching Keynote's shape exactly
(`KeynoteArchiveSurgeon+ImageSupply.swift` / `+ImageRecords.swift`):

- `TSP.DataInfo` must carry `materializedLength` (byte count) and an
  `attributes` bag with the `TSD.ImageDataAttributes.image_data_attributes`
  extension: `pixelSize` (image pixel dims) and
  `shouldBeInterpretedAsGenericIfUntagged: false`. Ours had an *empty*
  `TSP_DataAttributes` and no length.
- **No thumbnail**: Keynote's insert writes a single full-size `Data/` member;
  `MessageInfo.dataReferences = [dataId]`, one component data reference
  (count 1). Ours minted a second `-small-` data + `DataInfo` + reference.
- Slide record additions Keynote also writes: `ownedDrawables` gains the image
  reference (alongside `drawablesZOrder`); the slide record's header
  `objectReferences` gains **only** the image id (standins are referenced from
  the image's own `MessageInfo.objectReferences = [title, caption, style]`).
- `ImageArchive`: `originalSize = naturalSize`, `tracedPath` rectangle in pixel
  space (moveTo 0,0 → lineTo w,0 → w,h → 0,h → closeSubpath → moveTo 0,0),
  `interpretsUntaggedImageDataAsGeneric: false`, exterior wrap
  `type 4 / direction 2 / fitType 1 / isHtmlWrap false / margin 12 /
  alphaThreshold 0.5`, no mask, `flags = 0`, geometry `flags = 3`.

### #38 images, crash 2 — NSViewLayout uncaught exception (the real killer)

After crash 1 was fixed the signature changed to `+[NSApplication
_crashOnException:]` inside view layout. Cause: the image references the photo
media style (`image-0-imageStyle`, id `2651170`) which is **owned by the
DocumentStylesheet component**, but the Slide component's
`TSP.PackageMetadata … externalReferences` never declared that cross-component
edge. Keynote's own insert appends
`{componentIdentifier: <DocumentStylesheet component>, objectIdentifier:
<style id>}` to the slide component's `externalReferences`.

Fix: `registerExternalReferences(_:slideIdentifier:)`
(`KeynoteArchiveSurgeon+Metadata.swift`) — the owning component is resolved by
matching the style's member locator stem (`DocumentStylesheet`) against
component `preferredLocator`/`locator`. `mediaStyle()`
(`+DataIdentifiers.swift`) returns the style id plus that stem.

This is the same *class* of bug as the earlier #24 build crash (uuid-map /
`lastObjectIdentifier`): cross-component metadata invariants that TSP enforces
at load, invisible in the record bytes themselves.

## Notes for future surgery

- **No uuid-map entry is needed for images** — Keynote's own insert adds none
  for the image, standins, or data.
- The earlier "transplant a known-good ImageArchive still crashes" finding is
  explained: both crashes lived *outside* the ImageArchive record (DataInfo
  fields + component externalReferences).
- Keynote **autosaves in place** when driven via AppleScript — opening a
  template copy and inserting an image silently rewrites that file on disk.
  Copy the template before letting Keynote touch it, and treat any file Keynote
  opened as dirty.
- AppleScript `save … in` on a freshly script-modified blank produces a
  ~102 KB minimally-changed package (unlike the interactive Save's ~460 KB
  theme rewrite reported earlier). That near-noise-free reference is what made
  this diff tractable: `blank.key` vs Keynote-saved `blank+image` differed in
  ~270 raw lines total.

## Repro / verification harness (scratchpad, not committed)

- `crashcheck.sh <deck.key>`: quit Keynote, `open -a`, settle ~10 s, crash =
  process gone OR new `Keynote*.ips` in `~/Library/Logs/DiagnosticReports`.
  Note: Keynote 15.3 is installed at `/Applications/Keynote Creator
  Studio.app` on this machine (bundle id `com.apple.Keynote`).
- Reference: copy blank.key to scratch, `open -a` it, AppleScript
  `make new image … {file: …}` + `save … in blank-with-image.key`.
- Dump/diff: worktree `.venv` (`keynote-parser==1.14.4.0`) `unpack`, then raw
  `diff` of `Index/*.iwa.yaml` (skip `normalize.py` when hunting identifier
  wiring — the id-normalization hides exactly what matters).

## Geometry (#3)

No open crash in bisect for frame / Magic Move + frame. Unchanged.
