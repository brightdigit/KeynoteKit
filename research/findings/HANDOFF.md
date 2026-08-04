# HANDOFF — resume point for the research phase

Read this first after a context clear. It is self-contained: environment, how
to run things, what is done, gotchas, and next steps.

> ## ⚠️ The project has moved to its Swift phase (2026-07-28)
>
> **This file documents the completed reverse-engineering research.** That work
> is DONE and squash-merged to `v0.1.x` (`ab23b45`, PR #1). Everything below is
> still accurate as the format spec and as the Python reference backend.
>
> **The active work is now building the Swift package.** For that, read:
>
> 1. **`.claude/PLAN.md`** (branch `feature/swift-package`) — goal,
>    gated steps, two named risks, and a decision log.
> 2. **GitHub map [#12](https://github.com/brightdigit/KeynoteKit/issues/12)** —
>    v0.1.0 tracer bullets (#13–#24, label `v0.1.0`); claim / close there.
> 3. **`.claude/PARALLEL-WORKTREES.md`** — parallel lanes and worktree layout.
> 4. **`.claude/agent-notes.md`** and **`.claude/memory/keynotekit-v010-scope.md`**.
>
> Deferred past v0.1.0 remains issues [#2](https://github.com/brightdigit/KeynoteKit/issues/2)–[#10](https://github.com/brightdigit/KeynoteKit/issues/10).

## Mission (unchanged)

Reverse-engineer how Keynote's `.key` represents **slide transitions (Magic
Move)** and **object builds** via differential diffing of minimal pairs, so we
can design a `Deck` intermediate model + an AppleScript / template-surgery
backend. Methodology summary is in the repo-root `README.md` (Research
section). Favor written findings over raw diffs.

## Environment (already set up)

- Repo: this worktree (`…/KeynoteKit/swift-package`); research lives under `research/`
- Apple Keynote **15.3** is installed but presents as
  `/Applications/Keynote Creator Studio.app` (genuine; see
  `findings/versions.md` for the forensic proof). `tell application "Keynote"`
  resolves to it.
- Python 3.12.13 via **mise** (`mise.toml`), venv at `.venv/` (created by uv;
  `pip` was bootstrapped via `ensurepip`).
- **keynote-parser 1.14.4.0** installed in the venv (supports Keynote <= 14.4).
- Everything must run inside the mise env. Prefix commands with `mise exec --`
  (e.g. `mise exec -- keynote-parser ...`, `mise exec -- python3 tools/...`).
  `mise run selftest` works.

## How to run an experiment

```
# full auto (generator writes A and B from argv 1,2):
mise exec -- python3 tools/run_experiment.py <exp> --generate generators/<x>.applescript

# from existing .key files (skip Keynote):
mise exec -- python3 tools/run_experiment.py <exp> --skip-generate --a A.key --b B.key

# re-diff already-unpacked dirs:
mise exec -- python3 tools/run_experiment.py <exp> --skip-generate --skip-unpack
```

Output: unpacked YAML in `unpacked/<exp>/{A,B}` (normalized in place), diffs in
`findings/<exp>/*.diff`. The real signal for transitions is almost always
`findings/<exp>/Index__Slide.iwa.yaml.diff`.

## Toolchain validation status (Phase 0: DONE)

- `unpack` works and yields authentic IWA YAML (`KN.SlideArchive`, `TSP.*`).
- **`pack` — was broken on the stock wheel; NOW FIXED for 15.3 (2026-07-17).**
  The stock keynote-parser (14.4 protos) produced files Keynote 15.3 rejected.
  **Option A** (`findings/pack_option_a.md`) pairs the installed **14.4
  `TSPRegistryMapping`** with **regenerated 15.3 protos** and round-trips a deck
  Keynote 15.3 **accepts and opens** (verified on `samples/regression_check.key`,
  4 slides). Type IDs are stable 14.4→15.3, so the LLDB runtime dump (Option B) is
  **not needed**. The hybrid package lives in the session scratchpad
  (`pack_optionA/`); promoting it to a reproducible vendored schema is a next step.
  Details: `pack_option_a.md`, `pack_backend_approach.md` (§5 RESOLVED), `versions.md`.
- `mise run selftest` -> `SELFTEST PASS`.

## Where transitions live (established)

Slide archive path:
`KN.SlideArchive.transition.attributes.animationAttributes`
```
animationType: Transition
effect: <string enum>     # "none" = off; else the sdef Cocoa string, e.g. apple:dissolve
duration: <float sec>     # verbatim from AppleScript seconds
delay: <float sec>        # verbatim
isAutomatic: <bool>       # from `automatic transition`
randomNumberSeed: <int>   # VOLATILE
writingDirectionIsRtl: <bool>
```
Magic Move ONLY adds three siblings of `animationAttributes` (under
`attributes`): `customMagicMoveFadeUnmatchedObjects`, `customTextDeliveryType`,
`customTimingCurve`. `Document.iwa.yaml` has a derived per-slide `hasTransition`
cache flag (and a `hasExplicitBuilds` flag — relevant to Phase 2).

## Phase 1 findings (DONE) — see the per-experiment notes

| Exp | Note | One-line result |
|---|---|---|
| 1 present/absent | `findings/transition_present.md` | transition always written; `effect: none` = off |
| 2 effect type | `findings/effect_type.md` | `effect` = string enum == sdef Cocoa string; full enum table captured |
| 3 duration/delay | `findings/duration_direction.md` | floats in seconds, verbatim; DIRECTION not scriptable (deferred) |
| 4 Magic Move match | `findings/magic_move_correspondence.md` | **correspondence NOT persisted; runtime heuristic; `magic-id` must be authoring-time** |

## Key gotchas (learned the hard way)

- **AppleScript two-word enumerators** (e.g. `magic move`) are only valid INSIDE
  a `tell application "Keynote"` block. Don't pass them as handler args from
  `on run`; pass a string tag and branch inside the tell (see
  `generators/effect_type.applescript`).
- **`diff.py` does not clean `--out`** before writing. Stale `.diff` files from a
  previous run linger. `rm -f findings/<exp>/*.diff` before re-diffing, or trust
  the "changed (N)" summary line over the file listing.
- **Object ids renumber every save** but stay *parallel* across a pair built in
  one scripted pass. `normalize.py` canonicalizes 6+ digit ids -> `<id:N>` and
  blanks `randomNumberSeed`. Two residual noise classes remain and are EXPECTED:
  (a) reordering of unordered collections in `TemplateSlide-*`/`Document`
  (same `<id:N>` set, different order); (b) `Metadata.iwa.yaml` data-reference
  bookkeeping (~8k lines). Ignore both.
- Generators build BOTH variants in a single scripted pass on purpose (keeps the
  object graph stable -> clean diffs). Keep doing that.

## What is NOT scriptable (needs human-in-the-loop golden fixtures)

- **Transition direction** (Exp 3 tail): `transition settings` sdef record only
  exposes effect/duration/delay/automatic. Procedure to capture it is in
  `findings/duration_direction.md`.
- **All object builds** (Phase 2, Exps 5-7). Flow: `base_for_builds.applescript`
  makes the base; human adds ONE build in the Animate inspector; save variant;
  `run_experiment.py <exp> --skip-generate --a base.key --b variant.key`.

## Files I added/changed this session

- `mise.toml` (new), `.gitignore` (added samples/ unpacked/ .venv/ .DS_Store)
- `tools/normalize.py` (added `OBJ_ID_RE` id canonicalization + `randomNumberSeed`)
- `generators/effect_type.applescript`, `generators/duration_sweep.applescript` (new)
- `findings/*.md` (this file + versions + 4 experiment notes) and `findings/<exp>/`
- Nothing committed to git yet.

## Follow-up experiments DONE this session (all scriptable)

- **Exp 4b shapes** (`findings/mm_shapes.md` note is folded into
  `magic_move_correspondence.md`; diffs in `findings/mm_shapes/`): shapes behave
  like text — no persisted correspondence. Conclusion is not text-specific.
- **Exp 4c duplicate-and-edit** (`findings/mm_duplicate.md`): duplicate-and-edit
  vs independent creation -> byte-identical slide archives. Duplication leaves no
  trace; `magic-id` stays a compile-time abstraction (confirmed from 2 angles).
- **Exp 3b auto-advance** (folded into `findings/duration_direction.md`): only
  `isAutomatic` flips; no separate auto-advance-delay field.
- **Full effect catalog** (`examples/effect_catalog.json`, table in
  `effect_type.md`): all **43** effects built + `--verify`'d (every archive
  `effect` string round-trips). `deckkit.EFFECTS` is the authoritative verified
  map. Gotcha: `radial wipe` archive string is `apple:radial wipe` (has a
  space). Per-effect `custom*` options catalogued: `customBounce` (bool) on
  several 3D effects, `customTravelDistance` (fade and move), `customTwist`
  (twist), magic move's 3; all others none. None are AppleScript-settable.
- **`findings/deck_model_notes.md`**: first-cut `Deck` transition + `magic-id`
  model synthesized from all findings. Read this before designing the IR.
  Transition `options` is an extensible per-effect bag (not a fixed struct).

## Next steps (in priority order)

1. **Phase 2 builds (DONE — Exps 5-7):** the human added the builds; all six
   fixtures exist (`fixtures/build_{in,order,fx}_{A,B}.key`) and were diffed.
   Findings written: `findings/build_in.md` (Exp 5), `build_order.md` (Exp 6),
   `build_fx.md` (Exp 7); `deck_model_notes.md` now has a `## Build {}` section.
   `deckkit.py` gained the `Build` IR + `BUILD_EFFECTS` + read/verify half
   (`extract_builds`/`verify_builds`) — builds are NOT scriptable so there is no
   build path (byte-surgery only). Key results:
   - build = `KN.BuildArchive` (effect in a transition-shaped `animationAttributes`,
     targets its object by `drawable.identifier`) + `KN.BuildChunkArchive`
     (timing), referenced from new `builds`/`buildChunks` lists on `KN.SlideArchive`;
     `Document` flips `hasExplicitBuilds -> true`.
   - **order = list position** (no explicit order field; Exp 6).
   - build effects: `apple:dissolve character`, `apple:move in character`
     (distinct from transition strings; ` character` suffix on text builds).
   - **bonus:** builds serialize `direction` (int, Move In = 13) — the same
     `animationAttributes` field transitions omit at default (feeds the direction
     fixture below).
   **Exps 8-11 are now DONE (2026-07-17)** — fixtures authored + analyzed:
   - **Exp 8** (`build_shape.md`): the ` character` suffix is **NOT**
     object-type-qualified — a shape's Dissolve = `apple:dissolve character` too.
     `BUILD_EFFECTS` stays a flat name→string map.
   - **Exp 9** (`build_catalog.md`): 8-effect catalog across three naming families
     (`apple:* character`, `apple:bc-*`, `com.apple.iWork.Keynote.*`). Options:
     `direction` (sidezoom/zoom), `customBounce` (scale/flip), `customTravelDistance`
     (fade+move). One reconciliation flag: the Move-In fixture came out `apple:sidezoom`,
     not Exp 7's `apple:move in character`.
   - **Exp 10** (`build_out.md`): In/Out/Action are one `animationType` enum on the
     same `KN.BuildArchive`. Action is a distinct payload (motion path + acceleration,
     drops text-delivery knobs) → model the payload as a variant/sum.
   - **Exp 11** (`direction.md`): transition `direction` = `animationAttributes.direction`
     (int), absent at default, = 11 for one non-default Move In. Same slot builds use.
   `deckkit` build read/verify is unit-tested (`tools/test_deckkit.py`,
   `mise run test` -> DECKKIT TEST PASS, 11 tests). Proposed `BUILD_EFFECTS` rows
   from Exp 9 are in `build_catalog.md` (not yet wired into `deckkit.py`).
2. **Direction (Exp 11) — DONE.** `animationAttributes.direction` (int), absent at
   default, materializes when set (Move In non-default = 11); transitions reuse the
   builds' slot. To map the full enum (top/bottom/left/right/…), author extra
   direction fixtures. See `direction.md`.
3. **Backend — Option A authoring is IMPLEMENTED and WORKING (unblocked 2026-07-28).** Transition half stays
   fully AppleScript-scriptable (DONE + unit-tested). The build/direction **write**
   side needs `pack`, which **now works on 15.3** via the 14.4 registry + 15.3
   protos (`pack_option_a.md`). The runtime LLDB `TSPRegistryMapping` dump
   (Option B) is NOT required — type IDs proved stable. **Next:**
   (a) promote the scratchpad hybrid schema to a reproducible vendored keynote-parser;
   (b) authoring smoke test — inject a `KN.BuildArchive` into unpacked YAML, repack,
   reopen, verify via `deckkit.extract_builds`;
   (c) widen fidelity evidence (a builds-bearing deck + the transition-direction fixtures).
   The 2026-07-18 authored acceptance deck structurally round-trips but crashes
   Keynote 15.3 with `EXC_BREAKPOINT/SIGTRAP` in the animation framework. An
   unmodified Action fixture round-tripped by the same hybrid parser reopens,
   isolating a missing newly-authored animation graph invariant. Current status,
   isolated-deck experiments, and completion gates: `findings/write_backend.md`.
   **ROOT-CAUSED AND FIXED 2026-07-28** (`findings/write_backend_bisect.md`): a
   4-deck bisect (`examples/bisect_*.json`) showed direction-only opens while
   In/Out/Action each crash. Two document-level defects, both now fixed in
   `tools/archive_backend.py` and covered by tests (18 pass):
   (a) emitted builds were never registered in `Metadata.iwa.yaml` →
   `TSP.PackageMetadata` → the slide's component → `objectUuidMapEntries`, where
   the entry's `uuid` must equal the `KN.BuildChunkArchive`'s `buildId`
   (8/8 human fixtures register it, 0/2 of ours; chunk ids are registered 0/8);
   (b) `lastObjectIdentifier` was left below the ids we minted, inverting a
   high-water mark 5/5 fixtures maintain.
   `_verify_uuid_map` now enforces both inside `write_back`.
   **Acceptance gate PASSED**: human reopening confirms all four bisect decks and
   `samples/build_backend_acceptance.key` open in Keynote 15.3 with no crash and
   no repair warning. Newly authored In/Out/Action, multiple ordered builds, and
   transition direction all survive the round trip. The write backend is done;
   remaining work is breadth (more effects/options), not correctness.

Update this file and the per-experiment notes as you go.

## Backend (transitions) — IMPLEMENTED

`tools/deckkit.py` (Deck IR + AppleScript code-gen + verify) and
`tools/build_deck.py` (CLI). Build + round-trip verify:
`mise exec -- python3 tools/build_deck.py examples/deck_example.json samples/out.key --verify`
-> `VERIFY PASS`. Scriptable knobs only (effect/duration/delay/auto_advance);
no pack. Extend with builds/direction once those are reverse-engineered.

## Full findings index

`versions.md`, `transition_present.md`, `effect_type.md`,
`duration_direction.md` (+ Exp 3b), `magic_move_correspondence.md` (+ Exp 4b),
`mm_duplicate.md` (Exp 4c), `deck_model_notes.md`, `builds_setup.md`,
`build_in.md` (Exp 5), `build_order.md` (Exp 6), `build_fx.md` (Exp 7),
`build_shape.md` (Exp 8), `build_catalog.md` (Exp 9), `build_out.md` (Exp 10),
`direction.md` (Exp 11), `builds_setup_2.md` (Exps 8-11 setup),
`pack_mappings.md` (pack-regen feasibility spike),
`pack_backend_approach.md` (write-backend decision, §5 RESOLVED),
`pack_option_a.md` (Option A — pack round-trip ACCEPTED).
Generators added: `effect_type`, `duration_sweep`, `auto_advance`,
`mm_duplicate`, `mm_shapes`, `base_shape_build`, `direction_base`
(+ fixed `base_for_builds`).
Tests: `tools/test_deckkit.py` covers transition + build read/verify
(`mise run test`).
