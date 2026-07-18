# Phase 2b — next fixtures: human-in-the-loop setup (Exps 8-11)

Same deal as `builds_setup.md`: builds (and transition **direction**) are not in
Keynote's AppleScript dictionary, so automation makes the **base** deck and you do
the one un-scriptable action in the Animate inspector. After you save each
variant, I run the compare/extract stage unattended and write the findings.

**General flow for every experiment below:**
1. I generate the scriptable base (already runnable — see each section).
2. You make **one** change in Keynote's **Animate** inspector.
3. You **Save a Copy** (File ▸ Save a Copy…) to the named path — leave the control
   untouched.
4. Tell me "Exp N ready" (or just "fixtures ready") and I run the listed command.

All fixtures go in `fixtures/`. Keep the base/control byte-identical to the base so
the only real delta is your one change (`normalize.py` absorbs id renumbering).

---

## Exp 8 — non-text (shape) build  → settles the `character`-suffix question

**Why:** text builds serialize the effect as e.g. `apple:dissolve character`
(see `build_fx.md`). Open question: is that ` character` suffix
*object-type-qualified*? A build on a **shape** should tell us — if it comes out
`apple:dissolve` (no suffix), the build enum depends on object type and the `Deck`
model needs per-type effect strings.

**Base:** one slide, one **shape** (rectangle), no animation.
```
mise exec -- osascript generators/base_shape_build.applescript \
  "$PWD/fixtures/build_shape_A.key"
```
(Verified: this produces a valid deck whose slide carries a Shape archive and no
builds.)

**Your steps:**
1. Open `fixtures/build_shape_A.key`. **Save a Copy** as
   `fixtures/build_shape_B.key`; work in B (leave A as the control).
2. In B: select the **shape**. Animate ▸ **Build In** ▸ **Add an Effect** ▸
   **Dissolve**. Leave timing at defaults.
3. Save B (Cmd-S) and close.

**I run:**
```
mise exec -- python3 tools/run_experiment.py build_shape \
  --skip-generate --a fixtures/build_shape_A.key --b fixtures/build_shape_B.key
```
Expected signal: a `KN.BuildArchive` on the slide targeting the shape's drawable.
I compare its `effect` string to the text case (`apple:dissolve character`).

---

## Exp 9 — build-effect catalog  → builds the `BUILD_EFFECTS` table

**Why:** we only have two verified build effects (`dissolve`, `move_in`). This
sweep captures the archive `effect` string (and any `custom*` / `direction`
options) for the common Build-In effects, the way the 43-effect sweep built the
transition `EFFECTS` table.

**Base + control:** one slide, three text items (reuse the existing generator).
```
mise exec -- osascript generators/base_for_builds.applescript \
  "$PWD/fixtures/build_cat_A.key" 3
```
`build_cat_A.key` is the **control** (no build) — save it once, untouched.

**Your steps:** for each effect in the shortlist below, open `build_cat_A.key`,
**Save a Copy** to the named path, then on **"Item 1"** add Animate ▸ **Build In**
▸ that one effect (default timing), save, close. One fixture per effect:

| Effect (inspector) | Save as | Why it's interesting |
|---|---|---|
| Appear | `fixtures/build_cat_appear.key` | simplest; baseline (may carry no anim effect) |
| Dissolve | `fixtures/build_cat_dissolve.key` | already known (`apple:dissolve character`) — confirms method |
| Move In | `fixtures/build_cat_movein.key` | directional (`direction` int) |
| Fade In | `fixtures/build_cat_fadein.key` | maybe `customTravelDistance`? |
| Fade and Move | `fixtures/build_cat_fademove.key` | transition twin carries `customTravelDistance` |
| Scale | `fixtures/build_cat_scale.key` | transition twin carries `customBounce` |
| Blur | `fixtures/build_cat_blur.key` | text/CA effect family |
| Flip | `fixtures/build_cat_flip.key` | 3D → likely `customBounce` / `direction` |

(Do as many as you like — even 3-4 is useful; the more, the fuller the catalog.)

**I run:** for each saved fixture I unpack + `deckkit.extract_builds` and record
`effect` + any `custom*`/`direction`. No pairwise diff needed — the control just
confirms the base had no build.

---

## Exp 10 — Build Out / Action  → the `In` vs `Out`/`Action` axis

**Why:** we've only characterized `animationType: In`. This captures **Out** and
an **Action/Smart Build**, confirming those variants and any new fields.

**Base + control:** reuse the text base.
```
mise exec -- osascript generators/base_for_builds.applescript \
  "$PWD/fixtures/build_out_A.key" 3
```
Save `build_out_A.key` as the untouched control.

**Your steps (two variants):**
1. Copy → `fixtures/build_out_B.key`: on "Item 1" add Animate ▸ **Build Out** ▸
   **Dissolve** (default timing). Save, close.
2. Copy → `fixtures/build_action_B.key`: on "Item 1" add Animate ▸ **Action** ▸
   any move/opacity/scale (e.g. **Move**). Save, close.

**I run:**
```
mise exec -- python3 tools/run_experiment.py build_out \
  --skip-generate --a fixtures/build_out_A.key --b fixtures/build_out_B.key
mise exec -- python3 tools/run_experiment.py build_action \
  --skip-generate --a fixtures/build_out_A.key --b fixtures/build_action_B.key
```
Expected: `animationType: Out` (and something distinct for Action — possibly a
separate archive / `Action` type), plus any new keys.

---

## Exp 11 — transition direction  → the last transition unknown

**Why:** transition **direction** is the one remaining transition field
(`duration_direction.md`). It's not scriptable and is proto3-omitted at default,
so it only materializes when set to a non-default value. Exp 7 already showed the
field lives at `animationAttributes.direction` (int) for builds; this confirms the
transition side uses the same slot and captures the value enum.

**Base:** 2-slide deck, slide 2 has a **Move In** transition at default direction.
```
mise exec -- osascript generators/direction_base.applescript \
  "$PWD/fixtures/direction_A.key"
```
(Verified: slide 2 gets `effect: apple:slide` = Move In, `animationType:
Transition`.)

**Your steps:**
1. Open `fixtures/direction_A.key`. **Save a Copy** as
   `fixtures/direction_B.key`; work in B.
2. In B: select **slide 2**. Animate ▸ (the slide **Transition**, top of the
   Animate panel) ▸ change **only** the **Direction** dropdown (e.g. Left → Right,
   or Left → Top). Change nothing else.
3. Save B (Cmd-S) and close.

**I run:**
```
mise exec -- python3 tools/run_experiment.py direction \
  --skip-generate --a fixtures/direction_A.key --b fixtures/direction_B.key
```
Expected: a `direction` (int) field appears/changes in the slide-2 transition
`animationAttributes`. If you want the full enum, save extra copies with other
directions (`direction_top.key`, `direction_bottom.key`, …) and I'll map each.

---

## Notes

- If scripted shape creation (Exp 8) ever misbehaves, insert a shape by hand into
  the base, then copy to A/B before adding the build — the analysis is identical.
- Record build effects that come back as `apple:*` / `com.apple.iWork.Keynote.*`
  strings; they feed `deckkit.BUILD_EFFECTS` the same way transitions fed
  `EFFECTS`.
- All findings land in `findings/build_shape.md`, `build_catalog.md`,
  `build_out.md`, `direction.md`, and update `deck_model_notes.md`
  (`Build {}` / transition `direction`) + `HANDOFF.md`.
