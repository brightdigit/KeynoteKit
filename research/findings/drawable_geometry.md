# Drawable geometry write path (#3)

Authored size and layer order for text (and later image) drawables.

## Geometry

`TSD.DrawableArchive.geometry` (`TSD.GeometryArchive`):

- `position` → `TSP.Point.{x,y}` — already written by v0.1.0 text supply
- `size` → `TSP.Size.{width,height}` — written when ``Text.frame(width:height:)`` /
  ``Image.frame(width:height:)`` is set; unset leaves the template size

Path on a body placeholder:

`KN.PlaceholderArchive.super.super.super.geometry`
(= `TSWP.ShapeInfoArchive` → `TSD.ShapeArchive` → `TSD.DrawableArchive`)

## Z-order

Not a geometry field. Layer order is **`KN.SlideArchive.drawables_z_order`
list order** (later = above). Public ``Text.zIndex`` / ``Image.zIndex`` sort
drawables before lowering so build `targetIndex` stays aligned with that list.

Declaration order is the default (z-index 0, stable by encounter order).

## Magic Move

Size-changing morphs between matched `.magicId` pairs are expressible: emit the
same type/content with only the intended `geometry.size` / position delta
(`deck_model_notes.md` §3). Correspondence is still not stored in the file.

## Rotation (verified 2026-07-31, Keynote 15.3 render probe)

`TSD.GeometryArchive.angle` (field 4, float) is in **degrees**,
**counterclockwise-positive** on screen. Empirically pinned by authoring
`research/fixtures/probes/rotation_probe.key` (KeynoteKit-authored deck, angles
0.5 / 45 / −45 injected on the three slides' body placeholders, `flags = 3`
alongside) and reading the AppleScript slide-image export:

- `0.5` renders visually flat → **not radians** (0.5 rad ≈ 28.6° would be
  obvious; 45 also rendered as a clean 45°, not 45 rad ≡ 58.3°)
- `45` tilts the box 45° **counterclockwise**
- `−45` tilts 45° clockwise

Keynote honors the field on authored body placeholders with `flags = 3`
written next to it; rotation is about the box center, so a rotated box's
text visually displaces from its unrotated anchor.

Public API consequence: ``TextBox.rotationEffect(_:)`` follows SwiftUI
(positive = clockwise on screen), so the surgeon writes `angle = −degrees`.
