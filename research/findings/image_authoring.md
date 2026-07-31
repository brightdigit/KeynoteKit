# Authoring images as slide drawables (#38)

## Blank template baseline

`Sources/KeynoteKit/Resources/blank.key` has **no** `TSD.ImageArchive` records.
It does keep theme `Data/` + `TSP.DataInfo` rows (e.g. data id `9058` →
`Data/st-…-9058.jpg`). `TSP.DataInfo.digest` is **SHA-1** of the file bytes
(20 bytes). Media styles live in `DocumentStylesheet.iwa` — prefer
`image-0-imageStyle` (`2651170`); the first `MediaStyleArchive` may be
`equation-0-imageStyle` (`2652442`) and must not be used for photos.

Keynote-inserted images (after opening blank and saving) often look like:

- registry type **3005**, `flags = 0`, **no mask**
- `data` + separate `thumbnailData` data ids
- `super.title` / `super.caption` → empty `StandinCaptionArchive` (3097)
- `MessageInfo.objectReferences` = `[title, caption, mediaStyle]` (no parent)
- exterior text wrap + `aspectRatioLocked`

Theme fixtures (e.g. `research/fixtures/build_shape_B.key`) also show older
images with masks and `flags = 3`; those are not required for a simple insert.

## Write approach (current; **still crashes Keynote on open**)

See `drawable_open_crash.md` — transplant of a good ImageArchive into a
blank-derived deck still SIGTRAPs, so blank **integration** is the blocker.

For each authored ``Image`` today:

1. Allocate object ids for image + two standin captions; data ids for full-size
   and thumbnail (`max(DataInfo.identifier)+1` and `+2`).
2. Upsert `Data/kn-…` and `Data/kn-…-small-…` (**STORED**).
3. Append two `TSP.DataInfo` rows (full-size gets empty `attributes`).
4. Mint `TSD.ImageArchive` (`flags = 0`, geometry flags 3, photo media style,
   title/caption standins, wrap); no mask.
5. Append to `drawablesZOrder`; register slide-component data refs (count 1
   each for thumb and full-size).

Builds target images like text (Exp 8: same effect strings).

## Shapes

Still deferred on #4 — this path is images only.
