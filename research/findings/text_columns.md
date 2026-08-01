# Text columns & vertical alignment (verified 2026-07-31, Keynote 15.3 render probes)

## Where they live

Both are `TSWP.ShapeStyleArchive` (registry type **2025**) →
`shape_properties` (field 11):

- `vertical_alignment` (field 2): `kFrameAlignTop`=0 / `kFrameAlignMiddle`=1 /
  `kFrameAlignBottom`=2 (theme precedents 2651750 top / 2651755 bottom in
  `blank.key`).
- `columns` (field 4) → `ColumnsArchive.equal_columns { count(1), gap(2) }`.

Authored via a type-2025 **variation** of the placeholder's current style
(`TSD.ShapeArchive.style` repointed, placeholder record header ref swapped,
full 6-edge registration). Mirrors the theme's own forks: the TSWP-level
`shapeProperties` carries the overrides; the TSD-level super carries a
present-but-empty bag and the same `overrideCount`.

## The gap unit (empirically pinned)

`equal_columns.gap` is a **dimensionless fraction of the text layout
width** — not points, EMs, cm, or inches.

Method: authored 2-column probes with raw gaps 0.04 / 0.05 / 0.1 / 0.2
(probe deck: `research/fixtures/probes/column_gap_probe.key`, re-expressed
through the final points API), exported slide PNGs via AppleScript, measured
column-start strides. All four fit `stride = W(1 + raw)/2` with a single
constant `W ≈ 816.5 pt`; linear absolute-unit models do not fit
(0.04→0.05 and 0.1→0.2 imply incompatible per-unit factors).

The human-authored fixture sample (`build_action_B.key`, style 2651858,
`count: 2, gap: 0.05`) is therefore a 5% gutter.

`KeynoteKit` exposes the gutter in points and converts:
`gap = points / templateBodyPlaceholderWidth` (825 pt in `blank.key`).

## Layout-width caveat (pre-existing, NOT caused by the fork)

Keynote lays out a cloned body placeholder's **text** at the layout
master's body width (825 pt frame → ≈816.5 pt content after insets),
**ignoring the authored frame width**: probes with 300 / 600 / 1200 pt
frames all produced identical column strides, and a plain no-fork box with
long text also wrapped at ≈810 pt (so this is placeholder behavior, present
before #51's shape-style fork — the fork does not cause it).

Consequences:

- The frame sets the drawable's geometry (verified in #3), but long text
  wraps at the master's width and can visually overflow a narrower frame.
- The points→fraction gap conversion uses the master body width (the width
  Keynote actually divides), making the rendered gutter accurate to ~1%
  (825 frame vs ≈816.5 content).
- Follow-up filed for the frame-vs-layout-width mismatch itself.
