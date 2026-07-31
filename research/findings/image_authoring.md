# Authoring images as slide drawables (#38)

## Blank template baseline

`Sources/KeynoteKit/Resources/blank.key` has **no** `TSD.ImageArchive` records.
It does keep theme `Data/` + `TSP.DataInfo` rows (e.g. data id `9058` →
`Data/st-…-9058.jpg`). `TSP.DataInfo.digest` is **SHA-1** of the file bytes
(20 bytes). Media styles live in `DocumentStylesheet.iwa` — prefer
`image-0-imageStyle` (`2651170`); the first `MediaStyleArchive` may be
`equation-0-imageStyle` (`2652442`) and must not be used for photos.

Keynote-inserted images (verified against a script-driven insert + save on the
same blank, 2026-07-30) look like:

- registry type **3005**, `flags = 0`, **no mask**, **no `thumbnailData`**
- single `data` id; `MessageInfo.dataReferences = [dataId]`
- `super.title` / `super.caption` → empty `StandinCaptionArchive` (3097)
- `MessageInfo.objectReferences` = `[title, caption, mediaStyle]` (no parent)
- exterior text wrap (`type 4 / direction 2 / fitType 1`) + `aspectRatioLocked`
- `originalSize = naturalSize` = pixel dims; rectangle `tracedPath`;
  `interpretsUntaggedImageDataAsGeneric: false`

Theme fixtures (e.g. `research/fixtures/build_shape_B.key`) also show older
images with masks and `flags = 3`; those are not required for a simple insert.

## Write approach (current; **opens cleanly in Keynote 15.3**)

Root causes of the earlier open crashes are in `drawable_open_crash.md`. For
each authored ``Image`` (`KeynoteArchiveSurgeon+ImageSupply.swift` /
`+ImageRecords.swift`):

1. Allocate object ids for image + two standin captions; one data id
   (`max(DataInfo.identifier)+1`). No thumbnail.
2. Upsert `Data/kn-…-<dataId>.<ext>` (**STORED**).
3. Append one `TSP.DataInfo` row with `digest` (SHA-1),
   **`materializedLength`**, and `attributes` carrying the
   `TSD.ImageDataAttributes` extension (`pixelSize`,
   `shouldBeInterpretedAsGenericIfUntagged: false`).
4. Mint `TSD.ImageArchive` (`flags = 0`, geometry flags 3, photo media style,
   title/caption standins, wrap type 4, `originalSize = naturalSize`,
   rectangle `tracedPath`); no mask.
5. Append to `drawablesZOrder` **and `ownedDrawables`**; slide header
   `objectReferences` gains only the image id; register the slide-component
   data ref (count 1).
6. **Register the media style as a slide-component `externalReferences` entry**
   pointing into the DocumentStylesheet component — missing this edge crashes
   Keynote during layout (`registerExternalReferences`).

Builds target images like text (Exp 8: same effect strings).

## Shapes

Still deferred on #4 — this path is images only.
