# Text formatting on authored Text (#37)

## What the blank template stores

Body placeholders do **not** carry per-run `table_char_style` entries. Appearance
comes from a shared `TSWP.ParagraphStyleArchive` ("Body", e.g. id `2651133` in
the bundled blank) referenced from `TSWP.StorageArchive.table_para_style`.
That paragraph style lives in `Index/DocumentStylesheet.iwa` and is shared
across cloned placeholders — mutating it in place would restyle every body
item (and the theme).

## Write approach

When ``Text`` sets font / size / bold / italic / color:

1. Mint a fresh `TSWP.CharacterStyleArchive` (registry type **2021**) with
   required `TSS.StyleArchive` `super.stylesheet` → document stylesheet,
   plus `char_properties` (`font_name`, `font_size`, `bold`, `italic`,
   `font_color` as sRGB `TSP.Color`).
2. Append the record to `DocumentStylesheet.iwa`, register it on
   `TSS.StylesheetArchive.styles`, and set `MessageInfo.objectReferences` to
   the stylesheet id. (Omitting `super` crashes Keynote on open.)
3. Set `StorageArchive.table_char_style` to a single run at `character_index 0`
   pointing at the new style.

The shared Body paragraph style is left untouched. Unset formatting fields
leave `table_char_style` empty (template / paragraph defaults).

## Magic Move

Style-only morphs between matched `.magicId` pairs are expressible the same
way as geometry: same string/type, different character-style properties on each
slide. Correspondence remains a runtime heuristic (`magic_move_correspondence.md`).
