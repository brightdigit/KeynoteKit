# Experiment 9 — Build-In effect catalog

Sweep to capture the archive `effect` string (and any `custom*`/`direction`
options) for each common **Build In** effect, the way the transition `EFFECTS`
table was built (Exp 7 gave us only `dissolve` + `move_in`).

**Fixtures:** each = one slide, three text items, with a Build In of the named
effect added to "Item 1" via Keynote's Animate inspector. `build_cat_A.key` is
the control (no build).

**Command run (from repo root):**

```
mise exec -- python3 tools/read_builds.py \
  fixtures/build_cat_A.key fixtures/build_cat_appear.key \
  fixtures/build_cat_dissolve.key fixtures/build_cat_movein.key \
  fixtures/build_cat_fadein.key fixtures/build_cat_fademove.key \
  fixtures/build_cat_scale.key fixtures/build_cat_blur.key \
  fixtures/build_cat_flip.key
```

(`--json` re-run used for exact field capture.) All builds are
`kind=In`, `drawable=2652614`, `delivery=All at Once`, `eventTrigger=1`.

## Catalog

| Inspector name | archive `effect` string | direction / `custom*` options | notes |
|---|---|---|---|
| **(control)** | — | — | `build_cat_A.key` has **0 builds** ✓ |
| Appear | `apple:bc-appear` | `customTextDelivery=kTextDeliveryByObject`, `customDeliveryOption=kDeliveryOptionForward` | `bc-` prefix, **no ` character` suffix**. Carries text-delivery keys even though "Appear" has no visual anim. |
| Dissolve | `apple:dissolve character` | `customTextDelivery=ByObject`, `customDeliveryOption=Forward` | matches Exp 7 ✓ |
| Move In | `apple:sidezoom` | `direction=21` (no custom text keys) | **SURPRISE** — Exp 7's Move In was `apple:move in character` w/ `direction=13`. This fixture resolved to `apple:sidezoom`. See below. |
| Fade In | `com.apple.iWork.Keynote.FromDarkness` | (none beyond delivery) | **SURPRISE** — uses the `com.apple.iWork.Keynote.*` namespace (transition-style), **not** `apple:*`. No text-delivery keys. |
| Fade and Move | `apple:fade and move character` | `customTravelDistance=0.3990885416666667`, `customTextDelivery=ByObject`, `customDeliveryOption=Backward` | only effect carrying `customTravelDistance` (travel magnitude, not a direction enum). |
| Scale | `apple:zoom character` | `direction=44`, `customBounce=true`, `customTextDelivery=ByCharacter`, `customDeliveryOption=Forward` | directional **and** bounce; inspector "Scale" -> archive `zoom`. |
| Blur | `apple:blur character` | `customTextDelivery=ByObject`, `customDeliveryOption=Forward` | straightforward `character` variant. |
| Flip | `apple:bc-flip` | `customBounce=true`, `customTextDelivery=ByObject`, `customDeliveryOption=Forward` | `bc-` prefix like Appear, **no ` character` suffix**, but does carry `customBounce`. |

Durations captured (per-fixture, whatever the inspector had set): appear 1.0,
dissolve 1.0, movein 0.5, fadein 2.5, fademove 1.0, scale 0.75, blur 2.0,
flip 2.75. Durations are per-fixture knob settings, not effect-intrinsic.

## Three naming families in one `effect` slot

The Exp 7 assumption that build effects are uniformly `apple:* character`
strings does **not** hold. This sweep surfaces three distinct families:

1. **`apple:<name> character`** — the text-build variants:
   `dissolve character`, `fade and move character`, `zoom character`,
   `blur character`. These reliably carry `customTextDelivery` /
   `customDeliveryOption`.
2. **`apple:bc-<name>`** (build-chunk prefix, **no** ` character` suffix):
   `bc-appear`, `bc-flip`. Also `apple:sidezoom` sits in the plain `apple:*`
   space without the suffix.
3. **`com.apple.iWork.Keynote.<Name>`** — the same reverse-DNS namespace the
   transition `EFFECTS` table uses: `FromDarkness` (Fade In). This is the one
   effect that is namespaced exactly like a transition.

So the ` character` suffix is **not** universal (Exp 7's open item) — it marks
one family, not "the text-build variant" in general. `bc-appear`/`bc-flip` are
also on text objects yet drop it.

## Surprises / call-outs

- **Move In ≠ `apple:move in character`.** Exp 7 (`build_fx.md`) recorded
  `apple:move in character` (direction 13) for Move In. Here the fixture labeled
  `movein` came back as **`apple:sidezoom`** (direction 21). Either (a) the
  inspector item picked for this fixture differs from Exp 7's, (b) a Keynote
  version difference, or (c) "Move In" and a "Zoom/Side" style share an inspector
  grouping. **Do not silently overwrite the existing `move_in` row** — treat
  `sidezoom` as a separately-observed effect pending a re-shoot of a plain
  Move In. (Re-run with a confirmed Move In selection to reconcile.)
- **Fade In is transition-namespaced** (`com.apple.iWork.Keynote.FromDarkness`),
  the lone effect not in the `apple:*` space. Worth confirming it round-trips
  through `read_builds` / write path the same as `apple:*` strings.
- **Appear carries anim/delivery keys.** Even though "Appear" is the null visual
  build, it still emits `apple:bc-appear` + text-delivery keys (not empty). So an
  "Appear" build is a real, non-empty record, not a no-op absence.
- **`direction` only on `sidezoom` (21) and `zoom character` (44).** Matches
  Exp 7's rule: directional effects serialize `direction`; others omit it.
- **`customBounce` on `zoom character` (Scale) and `bc-flip` (Flip).**
- **`customTravelDistance` unique to `fade and move character`** — a float
  magnitude, distinct from the `direction` int enum.
- Control (`build_cat_A`) confirmed **0 builds** ✓.

## Proposed `BUILD_EFFECTS` rows (do NOT edit deckkit.py here)

AppleScript term stays `None` for all (builds are not AppleScript-settable —
same rule as the existing rows). Keys follow the existing snake_case convention
(`dissolve`, `move_in`). To add to `tools/deckkit.py` (~line 108):

```python
    "appear":        ("apple:bc-appear", None),
    "fade_in":       ("com.apple.iWork.Keynote.FromDarkness", None),
    "fade_and_move": ("apple:fade and move character", None),  # customTravelDistance
    "scale":         ("apple:zoom character", None),           # directional + customBounce
    "blur":          ("apple:blur character", None),
    "flip":          ("apple:bc-flip", None),                  # customBounce
```

Deferred / flagged (do not add without reconciliation):

```python
    # "move_in" is already ("apple:move in character", None) from Exp 7.
    # This sweep's `movein` fixture instead produced apple:sidezoom (direction 21).
    # Re-shoot a confirmed "Move In" before deciding whether sidezoom is:
    #   - a mislabeled fixture, a version delta, or a distinct effect e.g.
    #     "side_zoom": ("apple:sidezoom", None),  # directional
```

## Conclusion

Six new build effects are justified for `BUILD_EFFECTS`
(`appear`, `fade_in`, `fade_and_move`, `scale`, `blur`, `flip`), taking the
catalog from 2 -> 8 verified effects. The `effect` slot spans **three** naming
families (`apple:* character`, `apple:bc-*`, `com.apple.iWork.Keynote.*`), so the
Exp 7 " character"-suffix generalization is retired. One reconciliation item
remains: the `movein` fixture's `apple:sidezoom` vs Exp 7's
`apple:move in character`.
