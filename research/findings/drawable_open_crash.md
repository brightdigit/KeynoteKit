# Drawable open-crash triage (#3 / #37 / #38)

Status as of 2026-07-30 (branch `3-37-38-drawable-depth`, PR #39).

## Bisect (Keynote 15.x open)

Generate with local `BisectCrash` against the worktree package, open via
`open -a Keynote`, settle ~8s, treat process-gone / new `.ips` as crash.

| Deck | Opens? |
|---|---|
| A text only | OK |
| B frame only | OK |
| C format only | OK after CharacterStyle `super` fix |
| D format + frame | OK after same fix |
| E two-slide Magic Move, no frame | OK |
| F Magic Move + frame | OK |
| G image only | **CRASH** |
| H image + build | **CRASH** |

Geometry alone is fine. Desktop “geometry” acceptance decks were false alarms
relative to formatting/images.

Crash signature: `EXC_BREAKPOINT` / `SIGTRAP` via `+[NSApplication
_crashOnException:]`, worker `TSUAssertCat` — message not extracted from `.ips`.

## Fixed: text formatting (#37)

Minted `TSWP.CharacterStyleArchive` lacked `TSS.StyleArchive` `super` with
`stylesheet` → document stylesheet, and was not listed in
`TSS.StylesheetArchive.styles`. Theme styles always have `hasSuper=true`.

**Fix (in tree):** mint `super.stylesheet`, append style record to
`DocumentStylesheet.iwa`, register on `styles`, put stylesheet id on
`MessageInfo.objectReferences`. Confirmed open-safe in bisect C/D.

## Open: images (#38)

### Ruled out / low confidence

- `bodyPlaceholder ∉ drawablesZOrder` — same on known-good text decks.
- Missing mask alone — Keynote-inserted images on a saved blank often have
  **`mask=nil`**, `flags=0`.
- Tiny 1×1 JPEG alone — theme JPEG bytes also crash when minted our way.
- Equation media style — first `MediaStyleArchive` in blank is
  `equation-0-imageStyle` (`2652442`). Must prefer `image-0-imageStyle`
  (`2651170`). Fixed in `mediaStyleIdentifier()`; images still crash.

### Current mint (still crashes)

Aligned toward Keynote-inserted shape:

- No mask; `ImageArchive.flags = 0`; geometry `flags = 3`
- Photo media style `image-*-imageStyle`
- Standin title + caption; `titleHidden`/`captionHidden` = false
- Exterior text wrap + `aspectRatioLocked`
- Separate full-size + thumbnail `Data/` + `DataInfo` (thumb may reuse bytes)
- `MessageInfo.objectReferences` = `[title, caption, style]` (no parent)
- `dataReferences` = `[dataId, thumbId]`; slide component data refs count 1 each
- Empty `TSP.DataAttributes` on full-size `DataInfo`

### Strong finding: blank integration, not ImageArchive shape

Transplanting a **known-good** Keynote `ImageArchive` (id `2652482` from
`/tmp/blank-with-image.key`: no mask, flags 0, title/caption/style, data 9058 +
thumb) into a blank-derived `Deck { Text }` host **still crashes**.

So the failure is likely **how the blank template hosts a new image**
(metadata / component / z-order / theme wiring), not the protobuf field bag of
the image record itself.

Opening `blank.key` in Keynote and inserting an image, then saving, produces a
~460 KB package (vs ~98 KB blank) with many more components, datas, and theme
images — Keynote rewrites heavily on save. That rewritten file opens cleanly;
our surgical add onto the slim blank does not.

### Reference artifacts (local, not in repo)

- `/tmp/blank-with-image.key` — blank opened in Keynote + image insert + save
- `/tmp/keynote-authored-image.key` — AppleScript new doc + image
- `/tmp/bisect-crash/*.key` — A–H bisect decks
- `/tmp/authored-probe.txt`, `/tmp/blank-image-delta.txt` — dumps

### Next session ideas

1. Diff PackageMetadata / Document / slide component graph: slim blank text
   deck vs Keynote-saved blank+image (focus on what Keynote adds when the first
   slide image appears — not the whole theme rewrite).
2. Try authoring Image onto a **Keynote-saved** blank base (upgrade template)
   instead of the slim bundled blank.
3. Check whether slide `objectUuidMapEntries` or Document `externalReferences`
   need entries for image / caption / data objects.
4. Keep template placeholders in `drawablesZOrder` when appending images
   (Keynote keeps title/subtitle/body + image).

## Geometry (#3)

No open crash in bisect for frame / Magic Move + frame. Leave as-is.
