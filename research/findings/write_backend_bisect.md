# Write-backend bisect — isolated authored decks (crash diagnosis, step 1)

**Status: RUN 2026-07-28 — verdict below.** This file documents *how* to produce
the four isolated decks that `findings/write_backend.md` ("Next steps" §1) calls
for, and what reopening them showed. That section named the artifacts but not the
recipe; this is the recipe plus the result.

**Question:** the combined acceptance deck
(`samples/build_backend_acceptance.key`) crashes Keynote 15.3 with
`EXC_BREAKPOINT (SIGTRAP)` from `-[__NSSetM addObject:]` in the animation
framework, while an *unmodified* Action fixture packed by the same hybrid parser
reopens fine. So the pack path is sound and some newly-authored animation-graph
invariant is wrong — but the acceptance deck varies **four** things at once
(In build, Out build, Action build, transition direction) across two slides.
**Which single feature is the first to crash?** One minimal deck per feature
settles it.

**Do not diagnose from the acceptance deck.** It is preserved as evidence; each
deck below authors exactly one feature on one slide with one text item, so a
crash names its own cause.

---

## The four decks

Each spec is the `examples/build_acceptance.json` schema reduced to a single
slide. Field names and effect keys are as validated by `deckkit.deck_from_dict`
/ `Deck.validate`; `dissolve` is in `BUILD_EFFECTS`, and the Action effect string
is passed raw.

| # | Deck | Feature under test | Spec (one slide, one item) |
|---|---|---|---|
| 1 | `samples/bisect_direction.key` | transition `direction` only — **no builds** | `transition: {effect: "move_in", duration: 1.0, delay: 0.5, direction: 11}` |
| 2 | `samples/bisect_in.key` | one Build **In** | `builds: [{kind: "In", effect: "dissolve", duration: 1.0, target: "item:0"}]` |
| 3 | `samples/bisect_out.key` | one Build **Out** | `builds: [{kind: "Out", effect: "dissolve", duration: 1.0, target: "item:0"}]` |
| 4 | `samples/bisect_action.key` | one **Action** (motion path) | `builds: [{kind: "Action", effect: "apple:action-motion-path", duration: 1.0, target: "item:2" → "item:0", action_attributes: …}]` |

Deck 1 is the important control: it exercises `archive_backend.write_back`
(direction is archive-only, so surgery still runs) **without** adding any
`KN.BuildArchive`. If deck 1 reopens cleanly, the fault is in build-archive
authoring, not in the pack/surgery path generally. If deck 1 *also* crashes, the
fault is upstream of builds entirely.

For deck 4, copy the `action_attributes` bezier payload verbatim from
`examples/build_acceptance.json` and **retarget it to `item:0`** — the
acceptance spec aims at `item:2`, which is out of bounds on a one-item slide and
`Deck.validate` rejects it.

Specs go in `examples/bisect_*.json` alongside the existing acceptance spec.

---

## Generating them

`deckkit.build` is the whole path — it emits the scriptable base via AppleScript,
then applies `archive_backend.write_back` when the deck carries builds or a
transition direction (`tools/deckkit.py:348`):

```python
import deckkit
deck = deckkit.load_spec("examples/bisect_in.json")
deckkit.build(deck, "samples/bisect_in.key")
```

Prerequisite: the hybrid parser cache must be assembled.

```
mise run prepare-keynote-parser     # 631/631 registry names resolve
```

`tools/authored_build_smoke.py` already performs exactly this generate-then-reopen
cycle, but it is hardcoded to one spec path, one output path, and an assertion of
2 slides / 3 + 1 text items. To drive it here it needs the spec and output as
arguments and a per-deck reopen assertion (1 slide, 1 text item). Generalizing it
is the small piece of work this procedure implies.

**Generate all four before reopening any.** Generation is unattended; the reopen
is not, and batching keeps the human step to one pass.

---

## Reopening (human-in-the-loop)

The crash is only observable in the GUI. Per `findings/write_backend.md`, it
surfaced through automation as AppleEvent `-10000` / invalid connection `-609` —
consequences of a real crash, not automation limits. So an `osascript` reopen may
report a confusing error instead of a clean signal. **Open each deck by hand, one
at a time**, and record for each:

- does Keynote open it, crash, or show a repair/recovery warning?
- if it opens, are the objects accessible and is the authored feature present?
- if it crashes, is the backtrace the same `-[__NSSetM addObject:]` frame?

Quit and relaunch Keynote between decks so a prior crash cannot contaminate the
next result.

## Pass/fail gate

Per `findings/write_backend.md`, a deck only passes when it **reopens with object
access and no repair/recovery warning**. Structural re-unpack matching the
requested fields is necessary but *not* sufficient — the acceptance deck already
clears that bar and still crashes.

## Result (2026-07-28)

Generated with `--no-reopen`, then reopened by hand, one at a time, quitting
Keynote between decks.

| Deck | Authored feature | Structural verify | Reopen in Keynote 15.3 |
|---|---|---|---|
| `samples/bisect_direction.key` | transition direction 11, **no builds** | `apple:slide`, direction 11, delay 0.5 | **OPENS** |
| `samples/bisect_in.key` | 1 × Build In, `apple:dissolve character` | 1 build, drawable 2652601 | **CRASH** |
| `samples/bisect_out.key` | 1 × Build Out, `apple:dissolve character` | 1 build, drawable 2652601 | **CRASH** |
| `samples/bisect_action.key` | 1 × Action, `apple:action-motion-path` | 1 build, drawable 2652601 | **CRASH** |

## Verdict

**The fault is in `KN.BuildArchive` authoring, and only there.** This is the
"only deck 1 reopens" row of the pre-registered outcome table.

What the direction deck rules out — it exercises `archive_backend.write_back`
end to end (unpack → mutate → repack → atomic replace) and reopens cleanly:

- the hybrid 14.4-registry/15.3-proto parser and the `pack` path
- `write_back` surgery as a mechanism, including atomic destination replacement
- slide-order resolution via `KN.ShowArchive.slideTree` and SlideNode cache updates
- writing an archive-only field (`animationAttributes.direction`) that Keynote
  then reads back without complaint

So a deck can be taken apart, modified, and reassembled by this toolchain and
Keynote 15.3 accepts the result. Adding **one** `KN.BuildArchive` is what breaks
it.

What the three crashers rule out — the crash is **not** specific to:

- **effect string**: `apple:dissolve character` and `apple:action-motion-path`
  both crash
- **`animationType`**: In, Out, and Action all crash
- **payload shape**: the Action's motion-path/acceleration payload is a distinct
  variant (`build_out.md`) yet fails identically to plain In/Out
- **build count or ordering**: one build is sufficient; `build_order.md`'s
  list-position ordering is not implicated
- **cross-slide or multi-feature interaction**: one slide, one text item, one
  build still crashes

That points at something common to *every* emitted build — the
`KN.BuildArchive`/`KN.BuildChunkArchive` pair, its `drawable.identifier`
reference, its archive/build ID allocation, or the slide-level `builds`/
`buildChunks` list wiring — rather than at any per-effect field. Consistent with
the `-[__NSSetM addObject:]` crash frame (a set insertion, i.e. registration of
an animation identity), and with the fact that an *unmodified* Action fixture
round-trips through this same parser and reopens (`write_backend.md`).

Note all three crashers target the same `drawable=2652601`, and the surviving
direction deck targets no drawable at all — so "does the drawable reference
resolve the way Keynote expects" is not yet discriminated by this round and
carries into §3.

## Root cause (§2 comparison, 2026-07-28)

Comparing `samples/bisect_in.key` against the human-authored
`fixtures/build_in_B.key` found the decoded slide YAML to be **equivalent** —
same `KN.BuildArchive` fields, same effect, same drawable, same
`KN.BuildChunkArchive` back-reference, same `TSP.ArchiveInfo` headers (type 8 /
153), same slide `builds`/`buildChunks` wiring. As `write_backend.md` predicted,
the missing invariant is not visible there. It is **document-level**, and there
are **two** defects:

### 1. The build is never registered in the package object→UUID map

Keynote records every `KN.BuildArchive`'s identifier at:

```
Index/Metadata.iwa.yaml
  └─ TSP.PackageMetadata
       └─ components[] where identifier == <slide id>   (locator: Slide-<id>)
            └─ objectUuidMapEntries[]
                 { identifier: '<build archive id>',
                   uuid: { lower: '<64-bit>', upper: '<64-bit>' } }
```

and the entry's `uuid` is **exactly** the `KN.BuildChunkArchive`'s `buildId`.
So a build's identity is stored twice — once in the chunk, once in the package
map — and our surgery wrote only the first.

Measured across every Keynote-authored build fixture:

| Fixture | builds | registered | uuid == chunk.buildId |
|---|---|---|---|
| `build_in_B` | 1 | 1/1 | yes |
| `build_out_B` | 1 | 1/1 | yes |
| `build_action_B` | 1 | 1/1 | yes |
| `build_shape_B` | 1 | 1/1 | yes |
| `build_order_B` | 2 | 2/2 | yes |
| **`bisect_in` / `bisect_action` (ours)** | 1 | **0/1** | — |

**8/8** human-authored builds registered; **0/2** of ours. `build_order_B` shows
it is one entry **per build**, not per slide. The `KN.BuildChunkArchive` id is
registered in **0/8** — only the build archive.

### 2. `lastObjectIdentifier` is inverted

`TSP.PackageMetadata.lastObjectIdentifier` (a quoted string) is a high-water mark
sitting strictly above every archive id Keynote has handed out. Our allocator
(`max(all identifiers) + 1`) minted ids **above** it:

| Deck | lastObjectIdentifier | highest build/chunk id | last > highest |
|---|---|---|---|
| `build_in_B` | 2653026 | 2652982 | yes |
| `build_out_B` | 2652911 | 2652905 | yes |
| `build_action_B` | 2652897 | 2652891 | yes |
| `build_shape_B` | 2652901 | 2652849 | yes |
| `build_order_B` | 2653182 | 2652887 | yes |
| **`bisect_in` (ours)** | 2652634 | 2652636 | **NO** |

5/5 fixtures hold the invariant; ours inverts it.

Both defects fit the crash frame: `-[__NSSetM addObject:]` is a set insertion —
Keynote rebuilding its animation/id registry on load and failing on an identity
it cannot resolve. Both are absent from the direction-only deck, which authors no
build and allocates no ids, which is exactly why it survives.

## Fix (2026-07-28)

`tools/archive_backend.py`:

- `build_archive_records` returns the 128-bit build uuid it already generates.
- New `_package_metadata(files)` / `_slide_component(metadata, slide_id)` helpers.
  The component lookup keys on `identifier` (present on all 24 components), not
  `locator` (absent on 5: Document, ViewState, …), cross-checking `locator` when
  present.
- `author_unpacked` appends one `objectUuidMapEntries` entry per emitted build —
  build archive id only — inside the existing `if spec_slide.builds:` guard, and
  bumps `lastObjectIdentifier` **only when ids were actually allocated**, leaving
  the working direction-only path byte-untouched.
- New `_verify_uuid_map(root, count)`, called from `write_back` against the
  re-unpacked tree, asserts registration, `uuid == chunk.buildId`, and the
  high-water mark. `deckkit.extract_builds` reads only `Index/Slide*.iwa.yaml`
  and structurally cannot see this, so without it a regression would ship silently.

`tools/test_deckkit.py` gains 4 tests (18 total) over a synthetic unpacked tree:
registration + uuid equality + chunk ids *not* registered, per-slide component
routing, a direction-only regression guard, and a test of the verifier itself.
Both fixes were mutation-tested — disabling either makes the suite fail.

## Post-fix state (2026-07-28)

```
mise run test        DECKKIT TEST PASS (18)
mise run selftest    SELFTEST PASS
mise run verify-pack PASS build_in_B / build_action_B / direction_B
```

All four bisect decks and the acceptance deck regenerate, now passing the
in-pipeline `_verify_uuid_map`. Probed independently:

| Deck | registered | uuid == chunk.buildId | last > highest |
|---|---|---|---|
| `bisect_in` | yes | yes | yes |
| `bisect_out` | yes | yes | yes |
| `bisect_action` | yes | yes | yes |
| `bisect_direction` | (no builds) | — | n/a |
| `build_backend_acceptance` | 3/3 | yes | yes |

## Acceptance (2026-07-28) — GATE PASSED

Human reopening of the regenerated decks in Keynote 15.3: **all reopen**
(`bisect_direction`, `bisect_in`, `bisect_out`, `bisect_action`, and the combined
`build_backend_acceptance`) — no crash, no repair/recovery warning.

This confirms both defects above were the cause: registering each
`KN.BuildArchive` in `objectUuidMapEntries` (uuid == chunk `buildId`) and keeping
`lastObjectIdentifier` above every minted id is **sufficient** for Keynote 15.3
to accept a newly authored build. Newly authored In, Out, Action, multiple
ordered builds, and transition direction all survive the round trip.

`externalReferences` on the slide component — the next suspect had this failed —
turned out **not** to be required for these cases.

Because both fixes landed together (per user decision), this does not attribute
the crash to one defect alone. Both are invariants Keynote itself maintains in
every authored fixture, so both are honored regardless.

---

## Notes

- Keep every generated deck as a diagnostic artifact — do not overwrite between
  runs. The existing preserved artifacts are listed in `write_backend.md`.
- These decks are *authored*, not captured; unlike Exps 5–11 there is no
  human-in-the-loop inspector step, because the point is to test what **we**
  write. The human step here is reopening only.
- The leading hypothesis stays a duplicate/missing/inconsistent identity in
  Keynote's animation registration graph (`-[__NSSetM addObject:]` is a set
  insertion). Decks 2–4 each allocate exactly one archive ID and one 64-bit
  build ID, so a collision-driven crash should vanish in isolation and reappear
  only when features are recombined.
