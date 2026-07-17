# keynote-format-lab

An automated pipeline for reverse-engineering how Keynote's `.key` format
represents the two features that matter for a markup/DSL authoring tool:
**slide transitions (Magic Move)** and **object builds**. The goal is not a
full format spec — it's to learn just enough of the object graph to (a) design
a `Deck` intermediate model and (b) drive a template-surgery and/or AppleScript
backend with confidence.

## The core idea: differential diffing

You don't decode the whole format. You generate **minimal pairs** — two decks
identical except for one feature toggle — unpack both, and let a diff isolate
the delta. That delta *is* the feature's representation. Repeat across
parameter values to learn which fields encode which knobs.

The two hard parts are both handled by the tooling here:

1. **Noise.** Between saves, Keynote reshuffles object ids, UUIDs, and
   timestamps. A raw diff is useless. `tools/normalize.py` collapses that churn
   to placeholders so only structural change survives.
2. **Localization.** keynote-parser unpacks a `.key` into many YAML files
   (~one per internal component). `tools/diff.py` reports *which files changed*
   first — that alone points at the responsible component before you read a
   single line.

## Pipeline

```
generator (osascript)  ->  A.key, B.key          # controlled minimal pair
keynote-parser unpack  ->  unpacked/<exp>/{A,B}  # YAML dump of the graph
normalize.py --in-place->  collapse volatile noise
diff.py                ->  findings/<exp>/*.diff # the isolated delta
```

`tools/run_experiment.py` runs all four steps. `mise run transitions` is the
first worked example.

## Prerequisites (runs on your Mac)

- macOS with **Keynote** installed (for the AppleScript generators).
- **keynote-parser**: `pipx install keynote-parser`. Confirm the CLI with
  `keynote-parser --help` and **pin the version** you validate against.
- Python 3.12 (via `mise`). The harness itself is stdlib-only.

**First, validate the toolchain** before trusting any diff: unpack a real
`.key` from *your* Keynote version, `pack` it back, and confirm Keynote still
opens it. If your Keynote is newer than keynote-parser's bundled protobuf
mappings, regenerate the mappings from the installed app per keynote-parser's
docs. Record the Keynote + keynote-parser versions in `findings/`.

## Verify the harness with no Keynote needed

```
mise run selftest      # fabricates synthetic unpacked decks and checks
                       # that churn is suppressed and a real delta survives
```

## Experiment backlog (in order)

Transitions are fully scriptable, so automate them first. Builds are **not**
scriptable, so they use a human-in-the-loop golden-fixture flow.

| # | Experiment | Automatable? | What the diff should reveal |
|---|---|---|---|
| 1 | transition present vs. absent | ✅ full | the transition-properties message + where it attaches |
| 2 | Magic Move vs. Dissolve vs. Push | ✅ full | the effect-type field / enum |
| 3 | duration & direction sweep | ✅ full | the parameter fields (and their units) |
| 4 | Magic Move: matchable vs. not | ✅ full | **object correspondence mechanism** (drives `magic-id`) |
| 5 | one build-in vs. none | ⚠️ human adds build | the build message + attachment point |
| 6 | build order / multiple builds | ⚠️ human | sequencing representation |
| 7 | build effect & timing sweep | ⚠️ human | effect enum + timing fields |

Experiment 4 is the highest-value one for your model design: it tells you
whether Magic Move matches objects by shared id, name, text, or position —
which is exactly what your markup's `magic-id` has to encode.

## Builds: the human-in-the-loop step

The Keynote AppleScript dictionary can set slide transitions but **cannot** set
per-object builds. So for experiments 5–7: `base_for_builds.applescript`
generates the base deck, you duplicate it, add exactly one build in the Animate
inspector, save the variant, then run the compare stage with
`--skip-generate --a base.key --b variant.key`. Automation does the setup; you
do the one un-scriptable click.

## Recording findings

Each experiment writes normalized diffs to `findings/<exp>/`. Alongside them,
keep a short `findings/<exp>.md` in your own words: which component changed,
the field(s) responsible, values observed, and open questions. Those notes —
not the raw diffs — become the spec your `Deck` model and backends target.

## Known risks

- **Version fragility.** protobuf field numbers can shift between Keynote
  releases; pin versions and re-validate after Keynote updates.
- **Residual ID noise.** `normalize.py` is a v1 heuristic. Once you see real
  output, extend `VOLATILE_KEYS` and the regexes; minimal pairs generated in a
  single scripted pass keep the graph most stable.
- **AppleScript dictionary gaps.** Anything not in the dictionary (builds,
  some transition options) needs the golden-fixture path, not automation.

## Layout

```
generators/   AppleScript sample generators (automated setup)
tools/        normalize.py, diff.py, run_experiment.py, selftest.py
fixtures/     hand-authored golden decks (build experiments)
samples/      generated .key pairs                 (gitignore)
unpacked/     keynote-parser YAML output           (gitignore)
findings/     isolated diffs + your written notes
```
