# Surgeon at demo scale (#63)

**Result: no action needed. Writing a 20-slide demo-shaped deck takes ~0.66s
and cost grows linearly (exponent 0.97), not quadratically. #44 stays v0.1.1.**

Measured 2026-08-03 on Apple Silicon, Swift 6.4
(`swiftlang-6.4.0.27.1`), release-mode `swift run ScaleSpike`.

## Why this was a risk

The v0.1.0 demo (#56) is 15–20 slides. The largest deck ever authored or
tested was **3** (`Tests/KeynoteKitTests/SupplyTests.swift`), so demo scale
was entirely unexercised.

There is **no capacity cap** to worry about: `expandSlides`
(`KeynoteArchiveSurgeon+Supply.swift:38-47`) loops `cloneLastSlide` until the
deck's count is met, and runs *before* the `slideCountMismatch` guard
(`KeynoteArchiveSurgeon.swift:78-88`) — so that guard only fires when the deck
has *fewer* slides than the template. No new template is needed.

The real concern was **cost**. Two shapes in the code suggest quadratic
behavior:

- `SlideCatalog.locate(recordIdentifier:)` (`SlideCatalog.swift:107-115`) is a
  full nested linear scan over every member × record.
- `SlideCatalog(members:)` is reconstructed **inside the `expandSlides` loop
  condition**, so it is rebuilt on every iteration.

Together those read as roughly O(slides² × records) — issue #44.

## Method

A single 20-slide timing cannot distinguish "quadratic but small" from
"linear", so `Sources/ScaleSpike` sweeps a ladder of slide counts and reports
the empirical growth exponent `log(t₂/t₁) / log(n₂/n₁)` — ~1 linear, ~2
quadratic.

The deck is **demo-shaped, not minimal**: 4 drawables per slide (title, code
block, caption, badge), a Magic Move transition per slide, and a build on the
code block. Cost scales with records per member, not just slide count, so a
deck of bare one-drawable slides would understate it.

Three writes per count, median reported.

```bash
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
  xcrun swift run ScaleSpike /path/to/out
```

## Results

| slides | drawables | median write (s) | bytes |
|---:|---:|---:|---:|
| 3 | 12 | 0.1049 | 110,111 |
| 5 | 20 | 0.1547 | 116,215 |
| 10 | 40 | 0.2965 | 131,569 |
| 15 | 60 | 0.4645 | 146,871 |
| 20 | 80 | 0.6558 | 162,087 |

**Growth exponent, 3 → 20 slides: 0.97.** Per-slide cost at 20 slides:
0.0328s. Deck size grows ~2.6 KB per slide.

The per-slide cost is essentially flat across the ladder (0.035s at 3 slides,
0.033s at 20), which is the signature of linear scaling. A quadratic term
large enough to matter would show per-slide cost climbing with n; it does not.

## Interpretation

The quadratic *shape* in `expandSlides` is real, but at demo scale the
constant factors dominate: the template has few enough members and records
that the repeated `SlideCatalog` construction and linear `locate` scans stay
cheap relative to protobuf serialization and zip writing.

**#44 is therefore not a v0.1.0 blocker.** It remains worth doing — the
asymptotics are genuinely bad and would bite a 100+ slide deck — but nothing
in the v0.1.0 demo needs it.

Extrapolating the fitted curve, a 100-slide deck would land near 3.5s if
growth stays linear. That is the point at which the quadratic term would
likely become visible, and re-measuring before promising large-deck support
is the right move.

## Not covered here

Timing is not rendering. The 20-slide deck this harness keeps
(`scale-20-<n>.key`) still needs a human to open it in Keynote 15.3 and
confirm it renders with no crash and no repair dialog — an open pass is not a
render pass. That confirmation is the remaining half of #63.
