# HANDOFF — resume point for keynote-format-lab

Read this first after a context clear. It is self-contained: environment, how
to run things, what is done, gotchas, and next steps.

## Mission (unchanged)

Reverse-engineer how Keynote's `.key` represents **slide transitions (Magic
Move)** and **object builds** via differential diffing of minimal pairs, so we
can design a `Deck` intermediate model + an AppleScript / template-surgery
backend. See `README.md` for full methodology. Favor written findings over raw
diffs.

## Environment (already set up)

- Repo: `/Users/leo/Documents/Projects/KeynoteKit/prototype`
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
- **`pack` is broken for 15.3**: repacked files do not reopen in Keynote
  (keynote-parser maps <= 14.4). Phase 1 does NOT need pack (unpack+diff only).
  Regenerating mappings (upstream `dumper/generate_mapping.py` + proto-dump
  against `Keynote.framework`) is a prerequisite ONLY for the pack-based
  template-surgery backend. Details: `findings/versions.md`.
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
- **Effect matrix** (`generators/one_effect.applescript`, table in
  `effect_type.md`): swept dissolve/wipe/move-in/iris/object-cube/object-flip/
  switch. `effect` strings match the sdef; effect-specific knobs are sparse
  `custom*` siblings (only object flip -> `customBounce`; magic move -> its 3).
  No direction serialized at default for any effect.
- **`findings/deck_model_notes.md`**: first-cut `Deck` transition + `magic-id`
  model synthesized from all findings. Read this before designing the IR.
  Transition `options` is an extensible per-effect bag (not a fixed struct).

## Next steps (in priority order)

1. **Phase 2 builds (NEEDS HUMAN):** everything is staged in
   `findings/builds_setup.md`. Base deck `fixtures/builds_base.key` and control
   `fixtures/build_in_A.key` already exist. The user adds ONE build in the
   Animate inspector, saves `fixtures/build_in_B.key`, then run:
   `mise exec -- python3 tools/run_experiment.py build_in --skip-generate --a fixtures/build_in_A.key --b fixtures/build_in_B.key`
   Then Exps 6 (order) and 7 (effect/timing) per `builds_setup.md`. Write
   `findings/build_*.md` and add a `Build {}` section to `deck_model_notes.md`.
2. **Direction fixture** (golden-fixture; procedure in
   `duration_direction.md`) — the one remaining transition unknown.
3. **Backend:** the transition half (effect/duration/delay/automatic) is fully
   AppleScript-scriptable and needs NO pack; start there. Builds/direction/
   byte-surgery need regenerated 15.3 mappings (see `versions.md`).

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
`mm_duplicate.md` (Exp 4c), `deck_model_notes.md`, `builds_setup.md`.
Generators added: `effect_type`, `duration_sweep`, `auto_advance`,
`mm_duplicate`, `mm_shapes` (+ fixed `base_for_builds`).
