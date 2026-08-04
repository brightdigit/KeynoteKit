# Drawable open-crash triage (#3 / #37 / #38) — RESOLVED

Status as of 2026-07-31 (branch `3-37-38-drawable-depth`, PR #39): **all
resolved**. All 8 acceptance decks (5 original + 3 drawable-depth) open cleanly
in Keynote 15.3 with no crash and no new `.ips`, AND render correctly
(verified via scripted `export … as slide images`, not just open-survival —
the 2026-07-30 pass missed three render-level failures the human pass caught).

## Human-pass failures found 2026-07-31 (all fixed)

### drawable_geometry crash + blank slide 2 — three stacked clone bugs

The user-reported open crash (`+[NSSet setWithObject:]` with nil, uncaught,
via NSViewLayout) and the "slide 2 renders empty / 0 iWork items" symptom were
the multi-slide CLONE path, root-caused by normalizing the cloned member's ids
back to the template's and diffing, plus field-level comparison against a
Keynote-made `duplicate slide` reference:

1. **RecordCloner materialized absent optional references as EMPTY messages**
   (identifier 0): accessing `slide.objectPlaceholder` / `drawable.caption` /
   `drawable.title` through the generated accessor `inout` creates the field.
   Keynote resolves reference 0 to nil → the slide's objects silently never
   load (0 iWork items, `transition properties` = missing value) and Magic
   Move pairing crashes on the nil. Fix: guard every singular remap with the
   `has*` check (`RecordCloner.swift`).
2. **Cloned slide component had `objectUuidMapEntries = []`** — Keynote gives
   every slide-member record a fresh-uuid entry in its component map (14 on
   the blank), and a fresh set again on duplicate. Fix: remap the template's
   entries through the clone id map with fresh uuids (`appendComponent`).
3. **Cloned slide node was missing Document-component bookkeeping**: a uuid
   entry for the node, and a data-reference row entry for the node's
   thumbnail data (`Data/st-…-9058.jpg`). A record whose header declares
   `dataReferences` the component does not register fails TSP integrity.
   Fix: `registerUUIDEntries(componentStem: "Document")` +
   `registerDataObjectReference` merge (`cloneLastSlide`).

Also: the DSL transition in `DrawableGeometryContent` moved to slide 1 —
Keynote plays the OUTGOING slide's transition, so a Magic Move declared on the
last slide never plays.

### text_formatting rendered plain — wrong style mechanism

The forked `TSWP.CharacterStyleArchive` on `tableCharStyle` opened cleanly but
never rendered. Keynote's own whole-item formatting (script-driven reference
on the same blank) uses a **`TSWP.ParagraphStyleArchive` variation**:
`isVariation: true`, `parent` = the storage's current paragraph style,
`stylesheet` super, char properties on the fork, `overrideCount` = property
count, wired via the storage's `tableParaStyle` entry. Registration needs ALL
of: stylesheet `styles` list, stylesheet `parentToChildrenStyleMap` under the
parent, the storage record header's `objectReferences` swapped from parent to
fork, slide-component `externalReferences` edge, and uuid entries in both the
DocumentStylesheet and Slide components. **Color only paints via
`charProperties.tsdFill`** (a fill with the same color) — `fontColor` alone
renders black.

### image_drawable showed the missing-media "?" placeholder

The embedded hand-minimal 1×1 JPEG is not decodable by macOS ImageIO (`sips`
returns nil dimensions) — wiring was fine; the media itself was rejected, so
the editor showed "?" and playback showed nothing. Fix: embed a real
sips-encoded 64×48 JPEG in `AcceptanceSampleJPEG`.

## Verification harness additions

`renderdeck.sh <deck> <outdir>`: open in Keynote, AppleScript
`export … as slide images (PNG)`, read the PNGs — catches render-level
failures that the open/crash pass cannot. AppleScript object-model queries
(`count of iWork items of slide N`, `transition properties of slide N`)
distinguish "component never loaded" from "loaded but not painted".

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
