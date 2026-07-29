---
name: keynotekit-env-gotchas
description: KeynoteKit prototype — venv/keynote-parser reinstall and samples/ dir gotchas
metadata: 
  node_type: memory
  type: project
  originSessionId: eaabced2-1800-49b7-82d4-f99237219664
---

Two recurring environmental gotchas for the Python research tooling under
`research/` that are NOT persisted in git and cost time each fresh session:

1. **keynote-parser is not persisted.** The `.venv/` is gitignored and mise
   recreates it empty. HANDOFF.md says keynote-parser 1.14.4.0 is "installed" but
   it is not durable. If `mise exec -- keynote-parser ...` gives
   `FileNotFoundError`, reinstall: `mise exec -- python3 -m pip install
   'keynote-parser==1.14.4.0'`. Needed for every `run_experiment.py` unpack and
   `build_deck.py --verify`.

2. **`research/samples/` must exist before `build_deck.py`.** `research/samples/`
   is gitignored; if it's missing, Keynote's AppleScript `save` fails with
   `AppleEvent handler failed (-10000)` (misleading — looks like a codegen bug,
   isn't). `mkdir -p research/samples` first. Also close stale docs
   (`osascript -e 'tell application "Keynote" to close every document saving no'`)
   if automation flakes.

**Why:** both surface as confusing failures (missing binary; cryptic -10000) that
look like regressions. **How to apply:** on any fresh session touching research
tools, reinstall keynote-parser and `mkdir -p research/samples` before running
experiments or the deck backend.
