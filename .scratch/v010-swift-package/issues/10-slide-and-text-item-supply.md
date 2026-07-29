# 10 — Slide + text-item supply

**What to build:** Writer can author more slides (and more text items per slide)
than the bundled template contains, by duplicating template slides/items and
maintaining uuid-map / lastObjectIdentifier invariants. **First:** inspect the
blank template and decide reuse-placeholders vs synthesize `TSWP`; log the
choice in PLAN’s decision log before implementing.

**Blocked by:** 08 — Writer: builds match goldens + invariants; 09 — Minimal bundled template

**Status:** ready-for-agent

- [ ] Text-item supply strategy decided and logged (reuse vs `TSWP` synthesis)
- [ ] Deck with more slides than the template writes successfully
- [ ] Deck with more text items per slide than the template writes successfully
- [ ] `_verify_uuid_map` invariants hold for every minted id

---

## GitHub issue body (for `gh issue create`)

## What to build

Writer can author more slides (and more text items per slide) than the bundled
template contains, maintaining uuid-map / lastObjectIdentifier invariants.
First: decide reuse-placeholders vs synthesize `TSWP` from the blank template;
log the choice before implementing.

## Acceptance criteria

- [ ] Text-item supply strategy decided and logged
- [ ] Oversized slide count works
- [ ] Oversized text-item count per slide works
- [ ] Uuid-map / lastObjectIdentifier invariants hold for every minted id

## Blocked by

- 08 — Writer: builds match goldens + invariants
- 09 — Minimal bundled template
