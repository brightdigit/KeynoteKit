# Text-layout plan (issue #51)

> Canonical tracker copy: https://github.com/brightdigit/KeynoteKit/issues/51 — planned 2026-07-31, parked for later pickup. Decisions in "User-confirmed API decisions" were made by Leo in the planning session.


## Context

Bare `TextBox("…")` renders bulleted because every text drawable is authored by cloning the template's body placeholder (`KeynoteArchiveSurgeon+ImageSupply.swift:120`, `+Supply.swift:79`), whose `TSWP.StorageArchive.tableListStyle` points at the theme's `text-1-liststyle-Bullet` ("•") — and `applyText` (`+TextApplication.swift:71`) rewrites `text`, `tableParaStyle`, `tableCharStyle` but never `tableListStyle`. Bullets are driven entirely by that storage attribute table (the "Body" paragraph style itself references the *None* list style, verified by decoding `blank.key`).

This plan delivers: plain (no-bullet) default; a list-style API; horizontal + vertical alignment; per-paragraph indentation; rotation; and multi-column text boxes.

## User-confirmed API decisions

1. **`Paragraph` element** (user chose the name over "Line" — a wrapped paragraph spans visual lines, and the format is paragraph-based). **Each bare `Text` directly in a `TextBox` builder becomes its own paragraph**; multi-span paragraphs require explicit `Paragraph { Text… }`. This changes the semantics of the existing runs init (spans currently concatenate into one line) — see Migration below.
2. **Rotation: SwiftUI-style** — `.rotationEffect(_ angle: Angle)` with a new `Angle` value type (`.degrees(_:)`, `.radians(_:)`).
3. **Columns ship with gutter**: `.columns(_ count: Int, gap: Double? = nil)`, `gap` in points — requires the empirical gap-unit verification step (sole fixture sample `gap=0.05` cannot be points).

## Format facts (verified: protos in `research/vendor/keynote-parser/protos/15.3/`, empirical decode of `Resources/blank.key` + fixtures)

- **List styles**: `TSWP.ListStyleArchive`, registry type **2023**. `LabelType`: kNone=0, kImage=1, kString=2, kNumber=3. Parallel per-level arrays (9 levels in blank.key): `label_types(11)`, `text_indents(12)` (EM), `indents(13)` (points), `number_types(15)`, `strings(16)`. Theme already ships `text-0-liststyle-None`, `text-1-liststyle-Bullet` ("•"), `-Lettered`, `-Numbered` — resolve by `styleIdentifier` suffix, never hardcoded id. Human-authored fixture text boxes all use the None style, confirming the default fix is a **reference repoint, no minting**.
- **Paragraph props**: `ParagraphStylePropertiesArchive` — `alignment(1)` (0=left, 1=right, 2=center, 3=justify, 4=natural), `first_line_indent(7)`, `left_indent(11)`, `right_indent(19)`. Goes in the already-minted-but-empty `paraProperties` (`+CharacterStyle.swift:103`), bumping `overrideCount`.
- **Vertical alignment + columns**: both on `TSWP.ShapeStyleArchive` (type 2025) → `shape_properties(11)`: `vertical_alignment(2)` (top=0/middle=1/bottom=2/justify=3), `columns(4)` = `ColumnsArchive.equal_columns{count(1), gap(2)}`. Reached via `placeholder.super.super.style` (`TSD.ShapeArchive.style`). Theme has minimal variation precedents (2651750 top, 2651755 bottom). Fixture `build_action_B.key` style 2651858 is a real 2-column sample.
- **Rotation**: `TSD.GeometryArchive.angle(4)` (float; universal to all drawables; Keynote UI can't rotate tables/charts but the field exists). `flags(3)` = 3 observed on sized drawables; text path currently writes neither. Unit (radians vs degrees, sign) unverified — no rotated fixture exists.
- **Per-paragraph attributes** = multiple `tableParaStyle` entries keyed by each paragraph's UTF-16 start offset ("\n"-joined text); UTF-16 offset machinery exists in `+CharacterRuns.swift`.
- **Registration**: any minted style needs the full 6-edge set or Keynote silently renders plain/crashes: stylesheet `styles` + `parentToChildrenStyleMap` (`+StylesheetRegistry.swift:46-74`), uuid-map entries in BOTH DocumentStylesheet and Slide components, slide-component `externalReferences` (`+TextStyleRegistration.swift:37-60`), and record-header `objectReferences` swap (`replaceRecordHeaderReference`, `+TextApplication.swift:113`). The existing `MintedTextStyle` pipeline in `+DrawableItems.swift:62-91` is type-agnostic and carries list-style and shape-style records unchanged.

## Steps (each a PR; gate = `LINT_MODE=STRICT ./Scripts/lint.sh` + `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun swift test`)

### Step 1 — Default no-bullets (the bug fix; ship first)
- New `Sources/KeynoteKit/KeynoteArchiveSurgeon+ListStyle.swift`: `themeListStyleIdentifier(suffix:)` — scan DocumentStylesheet for type-2023 records, match `super.styleIdentifier` suffix (`liststyle-None` / `-Bullet` / `-Numbered`); throw if absent.
- `+TextApplication.swift`: `applyText` always writes `storage.tableListStyle.entries = [(characterIndex: 0, object: id)]` + header-reference swap.
- `+DrawableItems.swift`: resolve the None id in `applyTextItem`, pass through.
- **Golden impact**: all 5 goldenBacked decks' storages diverge from Python goldens. Add one documented normalization to `Tests/KeynoteKitTests/ArchiveGraphComparer.swift`: for records containing a `TSWP.StorageArchive`, clear `tableListStyle` and drop its referenced ids from that record's header `objectReferences` on both sides; update the "nothing else is masked" doc comment.
- Tests: new structural round-trip (pattern: `DrawableGeometryTests.swift:96-140`) — bare TextBox's `tableListStyle` resolves to a style with suffix `liststyle-None`; header refs contain it. Golden suite stays green.

### Step 2 — List style API
- New `Sources/KeynoteKit/TextListStyle.swift`:
  ```swift
  public struct TextListStyle: Sendable, Equatable {
    public static let none: TextListStyle          // theme None, repoint only
    public static let bullet: TextListStyle        // theme Bullet "•", repoint only
    public static func bullet(_ character: String) -> TextListStyle   // minted variation
    public static func numbered(_ format: NumberFormat = .decimal) -> TextListStyle
    public func indent(_ points: Double) -> TextListStyle
  }
  public enum NumberFormat: Sendable, Equatable { case decimal, romanUpper, romanLower, alphaUpper, alphaLower }
  ```
- `TextBox.listStyle(_:)`; lower through `AuthoredSlide+TextItem.swift` / `Deck+Lowering.swift:102`.
- Custom bullet/number mints a type-2023 **variation off the matching theme style** (never from scratch — inherits all 9 levels of indents/geometries): override `label_types` + `strings` (kString) or `number_types` (kNumber), `indents` for `.indent(points)`, mirrored across all 9 levels to keep parallel arrays aligned; `isVariation` + parent + stylesheet like `paragraphStyleRecord` (`+CharacterStyle.swift:98-104`); full 6-edge registration via the existing `MintedTextStyle` pipeline.
- Tests: `.bullet` repoints with no mint; `.bullet("→")` asserts variation parentage, 9-level `strings`, and all 6 edges; `.numbered(.decimal)` parents off `-Numbered`.

### Step 3 — Rotation
- Pre-work (verification): no rotated fixture exists — hand-author a one-box rotated deck in Keynote 15.3 (copy first; Keynote autosaves in place), decode it to pin (a) radians vs degrees, (b) sign/direction, (c) any new `flags` bit; record in `research/findings/drawable_geometry.md`.
- New `Sources/KeynoteKit/Angle.swift`: `public struct Angle: Sendable, Equatable { public static func degrees(_:) / radians(_:) }`.
- `TextBox.rotationEffect(_ angle: Angle)`; `writePlaceholderGeometry` (`+DrawableItems.swift:184`) writes `geometry.angle` (+ `flags = 3`) only when set, converting per the verified unit.
- Tests: structural angle round-trip; unrotated decks byte-stable (field only written when set → goldens untouched).

### Step 4 — `Paragraph`, horizontal alignment, per-paragraph indentation (largest PR)
- New `Sources/KeynoteKit/TextAlignment.swift` (`left/right/center/justified/natural` → ordinals 0/1/2/3/4), `Paragraph.swift`, `ParagraphsBuilder.swift`:
  ```swift
  public struct Paragraph: Sendable {
    public init(_ content: String)
    public init(@TextRunsBuilder _ runs: () -> [Text])
    public func indent(_ left: Double, firstLine: Double? = nil, right: Double? = nil) -> Paragraph
    public func alignment(_ alignment: TextAlignment) -> Paragraph
  }
  ```
- **Builder semantics (user decision)**: the `TextBox` builder produces `[Paragraph]`; `buildExpression(Text)` wraps each bare `Text` as its own single-span `Paragraph`; `buildExpression(Paragraph)` passes through. `TextBox("a\nb")` splits on `\n` into unstyled paragraphs. No bare-String expressions (standing directive).
- `TextBox.textAlignment(_:)` = item-wide default; `Paragraph.alignment/indent` override per paragraph.
- Surgeon: refactor `mintedParagraphFork` (`+DrawableItems.swift:157`) to **N forks** — one per distinct effective paragraph format. Every fork carries the item-wide `charProperties` (a `tableParaStyle` entry applies from its offset onward) plus merged `paraProperties` (alignment, `left_indent(11)`, `first_line_indent(7)`, `right_indent(19)`); `paraProperties` finally stops being empty (`+CharacterStyle.swift:103`). Dedupe identical formats; run-length adjacent identical entries. A bare item with only item-wide formatting still yields exactly today's single fork at index 0 (golden-safe).
- `applyText` gains `paragraphEntries: [(characterIndex, identifier, parentIdentifier)]`, writes all `tableParaStyle` entries + header refs. Run offsets for `characterRunStyles` computed over the joined string.
- **Migration (breaking semantics)**: `Sources/AcceptanceDeckCatalog/TextRunsContent.swift` (render-verified `text_runs` deck, #40) builds one line from multiple spans — wrap its spans in a single `Paragraph { }` to preserve the verified render; audit `TextRunTests.swift` / `TextRunTests+Decoding.swift` similarly.
- Tests: single-paragraph alignment; three-paragraph deck with distinct indents (3 forks, correct UTF-16 offsets incl. a non-BMP char); dedupe (identical paragraphs share a fork); regression: item-wide-only deck byte-identical to pre-refactor; bare-Text-splits-into-paragraphs semantics.

### Step 5 — Vertical alignment + columns (shape-style fork)
- Pre-work (verification): pin the `ColumnsArchive.gap` unit — author a 2-column box with a known gutter (e.g. 24 pt) in Keynote 15.3, decode, derive the conversion (candidates: fraction-of-width, EM); record in `research/findings/`.
- New `Sources/KeynoteKit/VerticalTextAlignment.swift` (`top/middle/bottom` → 0/1/2); `TextBox.verticalAlignment(_:)` and `TextBox.columns(_ count: Int, gap: Double? = nil)` (gap in points, converted per verified unit; nil inherits parent's gap).
- New `KeynoteArchiveSurgeon+ShapeStyle.swift`: when either is set, mint **one** type-2025 variation off `placeholder.super.super.style` with `shape_properties.vertical_alignment(2)` / `columns(4).equal_columns{count, gap}`; repoint `TSD.ShapeArchive.style`; swap the **placeholder record's** header ref (widen `replaceRecordHeaderReference` to internal); full 6-edge registration via `MintedTextStyle`.
- Tests: fork is type 2025, variation parentage, properties correct, style repointed, all edges present.

### Step 6 — Acceptance deck + human render pass
- New `Sources/AcceptanceDeckCatalog/TextLayoutContent.swift`: slides exercising default-plain vs `.listStyle(.bullet)` vs `.bullet("→")` vs `.numbered()`, all alignments, `Paragraph` indents, top/middle/bottom vertical alignment, 2–3 columns with gutter, rotated boxes (±45°, 90°). Register a new group in `AcceptanceDeck.swift` (pattern: `drawableDepth`, :58), appended to `all`. `CustomDeck.swift` stays as-is — its three bare TextBoxes are the regression proof that the default is now plain.
- Gate: human Keynote 15.3 open **and render** pass over `swift run AcceptanceDecks` output (open-pass ≠ render-pass — verify visually via AppleScript slide-image export per agent-notes), plus structural + golden suites.

Dependency order: 1 → 2, 1 → 4; 3 and 5 independent; 6 last.

## Housekeeping (implementation time)
- Append to `.claude/agent-notes.md`: the `Paragraph` naming + each-bare-`Text`-is-its-own-paragraph decision (supersedes the "spans concatenate" reading of the 2026-07-31 DSL-naming entry — update that line), rotation-as-SwiftUI (`Angle`), columns-with-gap decision, and the verified angle/gap units once pinned.
- Update `.claude/PLAN.md` / `PARALLEL-WORKTREES.md` per the always-update-docs-before-push directive.
- No Foundation `Process` in tests/lib; struct-over-caseless-enum for configurable types (`TextListStyle`, `Angle` are structs; closed sets like `TextAlignment` are enums, matching `BuildPhase`).

## Verification
1. Per-step: strict lint + full `swift test` under the 6.4 toolchain (structural round-trips via `KeyBundle(contentsOfZip:)`, golden differential with the one documented list-style normalization).
2. Empirical unit pins (rotation angle, column gap) land as `research/findings/` notes with the fixture decks kept in `research/fixtures/`.
3. Final human gate: `swift run AcceptanceDecks`, open every deck in Keynote 15.3 (copies, not originals), confirm no crash/repair dialog, and visually verify the new `text_layout` deck renders: no bullets by default, correct bullets/numbering when opted in, alignments, indents, columns, rotation.
