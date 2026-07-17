# Phase 2 — builds: human-in-the-loop setup (Exps 5-7)

Builds are NOT in the Keynote AppleScript dictionary, so automation makes the
base deck and you do the one un-scriptable action in the Animate inspector.
After each variant is saved, I run the compare stage.

## Baseline (already generated + verified)

- `fixtures/builds_base.key` — one slide, 3 text items ("Item 1/2/3"), no
  animation. (`generators/base_for_builds.applescript`, which I fixed: it
  referenced the master slide from the wrong scope.)
- Confirmed baseline: the slide archive has only the transition block
  (`effect: none`) and **no** build keys; `Document.iwa.yaml` shows
  `hasExplicitBuilds: false`, `hasExplicitBuildsCacheVersion: 2`. So any build
  we add should (a) introduce a new build structure referenced from the slide,
  and (b) flip `hasExplicitBuilds -> true`.

## Why copies (keep the graph stable)

For each experiment, A and B start as **byte-identical copies** of the base, so
the only real difference is the build you add. `normalize.py` absorbs the id
renumbering Keynote does on save.

---

## Exp 5 — one build-in vs none

Control is already staged: `fixtures/build_in_A.key` (untouched copy of base).

Your steps:
1. Open `fixtures/build_in_A.key` in Keynote. **Immediately Save a Copy**
   (File > Save a Copy, or duplicate in Finder) as `fixtures/build_in_B.key`,
   and work in B (leave A untouched as the control).
2. In B: select **"Item 1"** only. Open the **Animate** inspector (top-right),
   **Build In** tab, click **Add an Effect**, choose **Dissolve** (a simple,
   common one). Leave all timing at defaults.
3. Save B (Cmd-S) and close.
4. Tell me "Exp 5 ready" and I run:
   `run_experiment.py build_in --skip-generate --a fixtures/build_in_A.key --b fixtures/build_in_B.key`

Expected signal: a new build message on the slide (likely `KN.BuildArchive` /
a `builds` collection) referencing Item 1's drawable id + an effect string;
`Document` `hasExplicitBuilds -> true`.

---

## Exp 6 — build order / multiple builds

1. Copy the base to `fixtures/build_order_A.key` and `fixtures/build_order_B.key`.
2. In **A**: add a Build In to **Item 1**, then to **Item 2** (order 1 then 2).
3. In **B**: add a Build In to **Item 2**, then to **Item 1** (reversed order),
   using the SAME effect as A.
4. Save both. I diff A vs B — isolates how sequencing/order is represented
   (an explicit index/order field vs list position vs a delivery order).

Keep the effect identical in both so only ORDER differs.

---

## Exp 7 — build effect & timing sweep

1. Copy base to `fixtures/build_fx_A.key` and `fixtures/build_fx_B.key`.
2. In A: Build In on Item 1 = **Dissolve**, default timing.
3. In B: Build In on Item 1 = **Move In** (or another effect), and/or change
   **Duration**/**Delay**/**Start** (On Click vs After Previous).
4. Save both. I diff to isolate the effect enum + timing fields (compare with
   the transition timing fields, which were `duration`/`delay`/`isAutomatic`).

Optional finer split: keep the effect fixed and vary only Duration to isolate
the build's duration field, mirroring Exp 3's approach.

---

## Notes

- If any generated build refers to an effect by an `apple:*` /
  `com.apple.iWork.Keynote.*` string (like transitions do), record the mapping;
  the build effect enum will feed the `Deck` build model the same way the
  transition enum did.
- Watch `Document.iwa.yaml` for build caches analogous to `hasTransition`
  (`hasExplicitBuilds` already seen). Source of truth will be the slide/build
  archive, not the cache.
- All build findings go in `findings/build_*.md` (same format as the transition
  notes) and should update `findings/deck_model_notes.md` with a `Build {}`
  section.
