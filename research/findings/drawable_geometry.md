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
