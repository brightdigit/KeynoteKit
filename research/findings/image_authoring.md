# Authoring images as slide drawables (#38)

## Blank template baseline

`Sources/KeynoteKit/Resources/blank.key` has **no** `TSD.ImageArchive` records.
It does keep theme `Data/` + `TSP.DataInfo` rows (e.g. data id `9058` →
`Data/st-…-9058.jpg`). `TSP.DataInfo.digest` is **SHA-1** of the file bytes
(20 bytes). Media styles (`TSD.MediaStyleArchive`) remain in
`DocumentStylesheet.iwa` (first id `2652442` / others including `2651170`).

Full theme fixtures (e.g. `research/fixtures/build_shape_B.key`) carry real
`TSD.ImageArchive` examples: registry type **3005**, `data` →
`TSP.DataReference`, `naturalSize` / `originalSize`, `flags = 3`, optional
`style` → media style, `super.parent` → owning slide.

## Write approach

For each authored ``Image``:

1. Allocate an object id (`lastObjectIdentifier` high-water) and a data id
   (`max(PackageMetadata.datas.identifier) + 1` — separate from object ids).
2. Upsert zip member `Data/kn-<uuid>-<dataId>.<ext>` (**STORED**), inserted
   after existing `Data/` entries.
3. Append `TSP.DataInfo` (`identifier`, SHA-1 `digest`, `preferred_file_name`,
   `file_name`).
4. Mint `TSD.ImageArchive` with geometry, sizes, `data` ref, media style when
   present; put the data id on `MessageInfo.dataReferences`.
5. Append to `drawablesZOrder`; register
   `ComponentInfo.dataReferences` on the slide component
   (`data_identifier` + object reference count).

Builds target images like text (Exp 8: same effect strings).

## Shapes

Still deferred on #4 — this path is images only.
