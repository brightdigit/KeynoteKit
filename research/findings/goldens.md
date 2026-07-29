# Golden decks: regeneration and provenance

_Recorded: 2026-07-29. Regenerate after any Keynote update or any change to the
Python reference backend (`research/tools/deckkit.py`, `archive_backend.py`)._

The five `.key` files in `research/goldens/` are the fixed differential target
for the Swift writer (#20). They are generated from the committed JSON specs in
`research/examples/` via the Python reference backend, then committed so Swift
has something stable to reproduce.

`research/samples/` is gitignored, so goldens live in `research/goldens/`
instead. Do not add that directory to `.gitignore`.

## The goldens

| Golden | Spec | Bytes | Slide archives |
|---|---|---|---|
| `bisect_in.key` | `research/examples/bisect_in.json` | 460,520 | 18 |
| `bisect_out.key` | `research/examples/bisect_out.json` | 461,089 | 18 |
| `bisect_action.key` | `research/examples/bisect_action.json` | 461,545 | 18 |
| `bisect_direction.key` | `research/examples/bisect_direction.json` | 461,610 | 18 |
| `build_acceptance.key` | `research/examples/build_acceptance.json` | 468,378 | 19 |

## Why a one-slide spec produces a ~460 KB, 18-slide deck

This surprises everyone who checks the sizes, so it is written down here.

`bisect_in.json` specifies **one** slide with **one** text item. The resulting
deck contains **18** slide archives and roughly 250 KB of JPEG stock imagery
(`Data/mt-*.jpg`, `Data/*-small-*.jpeg`).

The cause is in `deckkit.build()` (`research/tools/deckkit.py:348`): it creates
the base deck by driving Keynote over AppleScript with `make new document`,
which inherits Keynote's **default theme**. The theme's master slides and its
bundled photography come along with it. Only one slide is authored; the other 17
are theme masters.

That puts the goldens at 460–468 KB against the ~452 KB themed fixtures in
`research/fixtures/` — the same order of magnitude, because they carry the same
theme ballast. `build_acceptance.key` is the largest at 468 KB with 19 slide
archives, the one extra slide its richer spec calls for.

**This is expected, not a defect.** The Python backend has no blank-theme path.
Shipping a minimal blank template is issue #21, and it does not affect these
goldens: their purpose is to be a fixed artifact the Swift writer must
reproduce, and theme content does not compromise that.

Two consequences worth being explicit about:

- The goldens embed Apple-authored theme content. They are committed under
  `research/` as test data, not shipped as a package resource, so this is not
  the redistribution question #7 raises about the bundled template — but it is
  the same underlying concern, recorded here rather than left implicit.
- Size drift is a signal. If a regeneration lands materially away from the table
  above, the theme or the backend changed; investigate before committing.

## Regeneration

### 1. Take Keynote exclusively

Only one Keynote-bound lane may run at a time on a given Mac (#19, #21, #24).
Close everything open first, or the scripted saves collide with a live session:

```bash
osascript -e 'tell application "Keynote" to close every document saving no'
```

### 2. Bootstrap the worktree

A fresh worktree has no `.venv/` (gitignored), so this repeats every time:

```bash
mise trust
mise exec -- python3 -m ensurepip --upgrade
mise exec -- python3 -m pip install 'keynote-parser==1.14.4.0' 'grpcio-tools==1.82.1'
mkdir -p research/samples
```

`mkdir -p research/samples` is **not optional**. The directory is gitignored, so
it does not exist in a fresh worktree, and the AppleScript save fails with
`AppleEvent handler failed (-10000)` if it is missing. That error looks like a
codegen bug and is not one. See `.claude/memory/keynotekit-env-gotchas.md`.

### 3. Staleness check

These three are the ticket's "specs still valid against the current backend"
criterion. Run all three **before** generating; if any fails, stop, because
goldens generated against a broken backend are worse than no goldens.

```bash
mise run prepare-keynote-parser   # => 631 registry entries; 0 missing message names
mise run test                     # => DECKKIT TEST PASS
mise run verify-pack              # => PASS build_in_B / build_action_B / direction_B
```

### 4. Generate

```bash
for s in bisect_in bisect_out bisect_action bisect_direction build_acceptance; do
  mise exec -- python3 research/tools/authored_build_smoke.py \
    research/examples/$s.json research/samples/$s.key --no-reopen
done
```

`--no-reopen` does **not** make this unattended. It only skips the verification
reopen; `deckkit.build()` still drives Keynote via `osascript` to *create* every
deck. Keynote is busy for the whole run.

### 5. Promote into the committed directory

```bash
mkdir -p research/goldens
cp research/samples/{bisect_in,bisect_out,bisect_action,bisect_direction,build_acceptance}.key \
   research/goldens/
```

### 6. Verify before committing

```bash
for f in research/goldens/*.key; do
  printf "%s %s bytes %s slides\n" "$(basename $f)" "$(stat -f%z $f)" \
    "$(unzip -l $f 2>/dev/null | grep -c 'Slide.*\.iwa')"
done
```

Compare against the table above.

## Rules

- **Never regenerate or overwrite `research/fixtures/`.** That is a fixed
  reference corpus; the semantic round-trip gate (#17) depends on it. This
  procedure only writes `research/goldens/`.
- **Never silently edit a spec in `research/examples/`.** If a spec turns out
  stale against the current backend, report it on the issue and stop. Changing a
  spec invalidates the differential target that #20 builds against.
- Goldens are consumed by the writer lane, never rewritten by it.
