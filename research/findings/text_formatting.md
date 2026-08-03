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

## Mixed runs inside one item (#40 — SHIPPED, render-verified 2026-07-31)

`TextBox { Text("Styled").bold(); Text(" plain") }` authors several spans in one
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

**Render verification (2026-07-31, human pass, Keynote 15.3):** `text_runs.key`
renders the mixed formatting correctly — "Bold red" large bold red, "italic"
italic, the spans between plain, all inside one text box, with the whole-item
control box bold. This retires the historical "char-style fork renders plain"
risk: that failure belonged to the pre-fix #37 attempt, which lacked the
registration edges and `tsdFill`. With the full edge set above, per-run
`TSWP.CharacterStyleArchive` on `table_char_style` **does** render.

## Magic Move

Style-only morphs between matched `.magicId` pairs are expressible the same
way as geometry: same string/type, different style properties on each slide.
Correspondence remains a runtime heuristic (`magic_move_correspondence.md`).

## `tableParaStyle` needs one entry per paragraph (verified 2026-08-03, #81)

Item-level formatting reached only the **first** paragraph of a
multi-paragraph box. The archive was valid and nothing errored — the defect
was visible only by opening a slide.

**Cause.** The surgeon run-length collapsed adjacent identical paragraph
formats into a single entry at offset 0. Keynote treats each
`tableParaStyle` entry as a paragraph boundary marker, so a collapsed table
left later paragraphs unstyled.

**Keynote's own shape.** A human-authored 5-paragraph body storage in
`build_action_B.key`:

```
STORAGE id=2651751  text=Body Level One\nBody Level Two\n…
  paraEntries=5
    char=0  -> 2651127
    char=15 -> 0
    char=30 -> 0
    char=47 -> 0
    char=63 -> 0
```

One entry per paragraph. The style rides entry 0; every later boundary
carries **identifier 0**, meaning "same style as the preceding entry". The
entry must exist even though it references no record.

**Fix.** `paragraphEntries(of:identifiers:)` emits one entry per paragraph,
writing identifier 0 where a paragraph's effective format repeats its
predecessor. Fork *records* are still deduped — the dedupe is on records,
not entries. `applyParagraphStyles` filters identifier-0 entries out of the
record header references, since 0 is not a record.

**A repeat entry must OMIT `object`, never zero it** (crash, 2026-08-03).
The first attempt at this fix set `entry.object.identifier = 0` for repeats.
Keynote **crashed on open**. Reading the identifier back cannot tell the two
apart — an absent message and a zeroed one both report 0 — but the wire bytes
do:

```
template repeat entry:  [08 0f]           <- characterIndex only
zeroed repeat entry:    [08 0f 12 00]     <- present-but-empty TSP.Reference
```

An empty reference resolves to nil and crashes, the same trap recorded for
`RecordCloner` remaps and for plain character spans. Only `hasObject`
distinguishes the two shapes, so `UUIDMapVerifier` rule 7 now checks it
across `tableParaStyle`, `tableCharStyle`, and `tableListStyle`.

**Testing note.** Use **three or more** paragraphs. A two-paragraph case
exercises only the first and last and passes while interior paragraphs stay
broken — which is how the per-span variant of this bug survived the first
#64 probe round.
