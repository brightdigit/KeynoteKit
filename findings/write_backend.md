# Option A write backend — implementation and verification

## Implemented

- Vendored the 34 extracted Keynote 15.3 schemas plus the 14.4
  `TSKArchives_sos.proto` and 631-entry registry mapping.
- `mise run prepare-keynote-parser` verifies `keynote-parser==1.14.4.0` and
  `grpcio-tools==1.82.1`, hashes all schema/runtime inputs, compiles into ignored
  `build/keynote-parser/<hash>/`, rewrites generated imports, retains the removed
  compatibility module, and asserts 631/631 registry names resolve.
- `mise run verify-pack` round-trips the captured Build In, Action, and direction
  fixtures and checks the authored fields survive.
- The public model now validates zero-based `item:N` targets, eight verified
  In/Out effects, `Action`, raw Action effects and nested `action_attributes`,
  reserved fields, transition direction, and the currently supported
  `on_click` trigger.
- The archive surgery resolves presentation order through
  `KN.ShowArchive.slideTree`, resolves drawable z-order, allocates unique archive
  and random build IDs, emits ordered Build/BuildChunk archives, updates slide
  references and SlideNode caches, writes direction, structurally re-unpacks the
  packed result, and replaces the requested destination atomically.

## Commands and evidence (2026-07-18)

```text
.venv/bin/python tools/prepare_keynote_parser.py
  631 registry entries; 0 missing message names

.venv/bin/python tools/test_deckkit.py
  DECKKIT TEST PASS

Hybrid fixture pack/unpack:
  Build In payload survived
  Action motion-path payload survived
  transition direction: 11 survived
```

The generated acceptance file is
`samples/build_backend_acceptance.key` (2 slides, 4 authored text objects,
3 ordered builds, transition direction 11). Its post-pack structural re-unpack
matches the requested In/Out/Action effects, timings, targets, order, and
direction.

## Blocking Keynote reopen result

The milestone is **not complete**. Human reopening confirmed that the generated
deck crashes Keynote 15.3 (7050.0.24) with `EXC_BREAKPOINT (SIGTRAP)`. The
application-specific backtrace throws from `-[__NSSetM addObject:]` inside the
Keynote animation framework while processing a UI event. This explains the
earlier AppleEvent `-10000` and invalid connection `-609`: they were consequences
of a real application crash, not an automation-only limitation.

In contrast, the captured authentic Action deck packed without modification
through this exact hybrid parser reopens and reports five text items, so the 15.3
schemas and general pack path are sound; some newly-authored animation graph
invariant not visible in the decoded YAML remains missing or internally
inconsistent.

Preserved diagnostic artifacts:

- `samples/build_backend_acceptance.key` — full In/Out/Action/direction case.
- `/tmp/authored-one.key` — minimal one Build Out case (session-local).
- `/tmp/build_action_B-hybrid.key` — successful unmodified Action round-trip
  control (session-local).

Do not mark the write backend complete until a newly authored build reopens with
object access and no repair/recovery warning.

## Next steps

1. Generate four isolated authored decks: direction only, one Dissolve In, one
   Dissolve Out, and one Move Action. Reopen them independently to locate the
   first crashing feature; do not use the combined acceptance deck for diagnosis.
2. For the smallest crashing build, compare its decoded and raw IWA state with
   the corresponding authentic fixture. Inspect BuildArchive/BuildChunkArchive,
   slide object references and ordering, SlideNode caches, archive identifier
   allocation, and any document-level animation index not exposed by the
   existing YAML findings.
3. Starting from the authentic fixture, vary one identity invariant at a time:
   reuse versus reallocate archive IDs, reuse versus regenerate the 64-bit build
   ID, change only the drawable, reinsert only the existing records, and rebuild
   only the SlideNode caches. Reopen each artifact separately.
4. Once one newly-authored Dissolve In reopens cleanly, repeat the gate for Out,
   Action, multiple ordered builds, and transition direction. Then regenerate
   the combined acceptance deck and rerun `mise run authored-build-smoke`, the
   complete unit suite, `mise run selftest`, and `git diff --check`.

The leading hypothesis is a duplicate, missing, or inconsistent identity or
reference in Keynote's animation registration graph, based on the crash in
`-[__NSSetM addObject:]`; protobuf schema compilation and unmodified fixture
packing are controls that already pass.

## Supported fields and limitations

- In/Out effects: `appear`, `blur`, `dissolve`, `fade_and_move`, `fade_in`,
  `flip`, `move_in`, `scale`. The ambiguous `apple:sidezoom` alias is deferred.
- Action: any non-empty raw archive effect string plus arbitrary nested
  `action_attributes`; structural and text-delivery keys are reserved.
- Transition direction: optional raw integer.
- Targets: zero-based `item:N` only.
- Trigger: `on_click` only. `after_previous` and `with_previous` fail clearly
  until their archive encodings are captured.
