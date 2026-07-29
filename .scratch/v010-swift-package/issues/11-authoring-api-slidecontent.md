# 11 — Authoring API (`SlideContent` surface)

**What to build:** The grilled public API on `KeynoteKit`: `SlideContent` +
`@SlideBuilder`, `Text` with `.position` / `.magicId`, `.build(.in|.out)`,
`.action { MotionPath… }`, slide `.transition` modifiers, proven-only effect /
direction catalogs, all three triggers, encounter-order builds. The PLAN Goal
sketch compiles and `write(to:)` produces a valid `.key`.

**Blocked by:** 10 — Slide + text-item supply

**Status:** ready-for-agent

- [ ] `SlideContent` / `@SlideBuilder` composition works (extractable slides)
- [ ] Builds, actions, transitions, magicId, position match PLAN Step 5
- [ ] Catalogs are acceptance-proven only (no `.custom` / raw direction int)
- [ ] Goal sketch compiles and writes a deck that passes structural checks
- [ ] `KeynoteKit` still does not depend on `KeynoteKitScripting`

---

## GitHub issue body (for `gh issue create`)

## What to build

The grilled public API on `KeynoteKit`: `SlideContent` + `@SlideBuilder`, `Text`
modifiers, `.build(.in|.out)`, `.action`, slide `.transition`, proven-only
catalogs, all three triggers, encounter-order builds. The PLAN Goal sketch
compiles and writes a valid `.key`.

## Acceptance criteria

- [ ] `SlideContent` / `@SlideBuilder` composition works
- [ ] Builds, actions, transitions, magicId, position match PLAN Step 5
- [ ] Catalogs are acceptance-proven only
- [ ] Goal sketch compiles and writes a structurally valid deck
- [ ] `KeynoteKit` does not depend on `KeynoteKitScripting`

## Blocked by

- 10 — Slide + text-item supply
