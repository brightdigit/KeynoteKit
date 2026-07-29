# 07 — Regenerate & commit Python golden decks

**What to build:** The five acceptance/differential golden `.key` files,
regenerated from the committed JSON specs via the Python reference backend and
**committed** so Swift has a fixed target. Needs a live Keynote (AppleScript
drives creation). Also a staleness check on the specs.

**Blocked by:** None — can start immediately (parallel with substrate work).

**Status:** ready-for-agent

- [ ] `bisect_in`, `bisect_out`, `bisect_action`, `bisect_direction`, and
      `build_acceptance` `.key` files regenerated from their JSON specs
- [ ] Goldens committed (or otherwise durable for CI/local diffs — samples dir
      may need an exception to gitignore for these five)
- [ ] Specs still exercise a backend that has been fixed since last run
- [ ] Documented how to re-run regeneration

---

## GitHub issue body (for `gh issue create`)

## What to build

The five acceptance/differential golden `.key` files, regenerated from the
committed JSON specs via the Python reference backend and committed so Swift has
a fixed target. Needs live Keynote. Also a staleness check on the specs.

## Acceptance criteria

- [ ] Five goldens regenerated: bisect_in/out/action/direction + build_acceptance
- [ ] Goldens committed (durable for differential tests)
- [ ] Specs still valid against the current Python backend
- [ ] Regeneration steps documented

## Blocked by

None — can start immediately.
