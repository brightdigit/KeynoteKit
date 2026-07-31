# Text formatting on authored Text (#37 whole-item, #40 mixed runs)

## What the blank template stores

Body placeholders do **not** carry per-run `table_char_style` entries. Appearance
comes from a shared `TSWP.ParagraphStyleArchive` ("Body", e.g. id `2651133` in
the bundled blank) referenced from `TSWP.StorageArchive.table_para_style`.
That paragraph style lives in `Index/DocumentStylesheet.iwa` and is shared
across cloned placeholders — mutating it in place would restyle every body
item (and the theme).

## Whole-item formatting (#37 — SHIPPED, render-verified 2026-07-31)

When ``Text`` sets font / size / bold / italic / color for the whole item,
KeynoteKit mints a **`TSWP.ParagraphStyleArchive` variation** — the mechanism
Keynote itself uses (verified against a script-driven reference on the same
blank). `KeynoteArchiveSurgeon+CharacterStyle.swift`:

1. Fork with `super.isVariation = true`, `super.parent` = the storage's
   current paragraph style (`tableParaStyle` entry 0), `super.stylesheet` =
   the document stylesheet, `charProperties` carrying the overrides,
   `overrideCount` = property count. Registry type **2022**.
2. Color must set **`charProperties.tsdFill`** (a fill with the same color)
   alongside `fontColor` — modern Keynote paints glyphs with the fill;
   `fontColor` alone renders black.
3. Registration needs ALL of: append the record to `DocumentStylesheet.iwa`;
   stylesheet `styles` list; stylesheet `parentToChildrenStyleMap` under the
   parent; the storage record header's `objectReferences` swapped from parent
   to fork; slide-component `externalReferences` edge into the
   DocumentStylesheet component; uuid-map entries in both the
   DocumentStylesheet and Slide components. Keynote silently renders plain
   when any edge is missing (`drawable_open_crash.md`).

An earlier whole-item attempt via a `TSWP.CharacterStyleArchive` fork on
`table_char_style` opened cleanly but **rendered plain** — that attempt
predates the registration edges above and `tsdFill`.

## Mixed runs inside one item (#40 — IMPLEMENTED, render verification PENDING)

`Text { TextRun("Styled").bold(); " plain" }` authors several spans in one
text box. Implementation (`KeynoteArchiveSurgeon+CharacterRuns.swift`,
`+TextApplication.swift`):

- The paragraph-style variation above still carries item-wide defaults.
- When any span has its own overrides, KeynoteKit mints one
  **`TSWP.CharacterStyleArchive`** (registry type **2021**) per span:
  `super.stylesheet` set (no parent), `charProperties` (color with
  `tsdFill`), `overrideCount`. Plain spans mint an override-free style so
  their entry resets the preceding span — a zero-identifier reference is
  never written (Keynote resolves id 0 to nil: blank render or NSSet-nil
  crash).
- `StorageArchive.table_char_style` gets one object-attribute entry per span
  keyed by the span's **UTF-16** start offset; each style id is appended to
  the storage record header's `objectReferences`.
- Every minted style gets the full edge set from #37: stylesheet `styles`
  list, slide-component `externalReferences`, uuid-map entries in both
  components (`+TextStyleRegistration.swift`).

**Render risk (open):** the char-style mechanism is the one that rendered
plain in the pre-fix #37 attempt. It has *not* been re-tested in Keynote 15.3
since the registration edges and `tsdFill` were understood — that was exactly
#40's premise. Verification must be render-level (AppleScript
`export … as slide images` + reading the PNGs, per `drawable_open_crash.md`),
not open-level: `text_runs.key` (acceptance catalog) is the probe deck. If it
still renders plain, build a Keynote-scripted reference (set a bold word via
AppleScript on the blank, save, raw-diff `Index/*.iwa.yaml`) and match its
shape — the same method that cracked #37 and #38.

## Magic Move

Style-only morphs between matched `.magicId` pairs are expressible the same
way as geometry: same string/type, different style properties on each slide.
Correspondence remains a runtime heuristic (`magic_move_correspondence.md`).
