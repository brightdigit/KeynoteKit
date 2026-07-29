# KeynoteKit — v0.1.0 Goal & Plan

Integration branch: **`v0.1.x`**. It carries the squash-merged prototype research
(`ab23b45` / PR #1) and the squash-merged planning work (`62a68f3` / PR #11) —
the former `feature/swift-package` branch was squashed into it and no longer
exists. Ticket lanes branch off `v0.1.x` and PR back into it.

## Goal

A **self-contained Swift package** that authors Keynote `.key` files with
transitions and object builds — no Python, no `keynote-parser`, no `mise`, no
AppleScript at runtime.

```swift
struct TitleSlide: SlideContent {
  var body: some SlideContent {
    Slide {
      Text("Title")
        .magicId("title")
        .position(x: 200, y: 200)
        .build(.in) {
          Dissolve()
            .duration(1)
            .trigger(.onClick)
        }
        .action {
          MotionPath(/* full bezier */)
            .duration(1)
            .trigger(.afterPrevious)
        }
    }
    .transition(.magicMove.duration(1))
  }
}

let deck = Deck {
  TitleSlide()
  // …more SlideContent
}
try deck.write(to: url)  // basedOn: defaults to bundled template
```

"Self-contained" means **no Python/keynote-parser/mise/AppleScript at runtime**.
It does *not* mean zero dependencies: we depend on **swift-protobuf** and ship a
**bundled template** (#7). "From scratch" here means *authored from Swift source
rather than by hand in Keynote* — authoring with no template at all is #2.

**Definition of done for v0.1.0:** a deck authored purely in Swift opens in
Keynote 15.3 with no crash and no repair warning, and its transitions and builds
verify structurally against what was specified.

## What we already know (from `v0.1.x` research — do not re-derive)

The prototype answered the format questions. Treat `research/findings/` as spec:

- **Transitions** live at `KN.SlideArchive.transition.attributes.animationAttributes`
  (`effect` string enum, `duration`/`delay` float seconds verbatim, `isAutomatic`).
  43 effects catalogued and verified (`effect_type.md`, `examples/effect_catalog.json`).
- **Builds** = `KN.BuildArchive` (effect + `drawable.identifier` target) paired with
  `KN.BuildChunkArchive` (timing), referenced from `builds`/`buildChunks` on the
  slide. **Order = list position**, no order field. `In`/`Out`/`Action` are one
  `animationType` enum; Action is a distinct payload → model as a sum type.
- **`magic-id` is compile-time only** — Keynote persists *no* object correspondence;
  matching is a runtime heuristic. The compiler must emit matched objects as the
  same type with similar content/geometry.
- **Two document-level invariants cause the SIGTRAP crash if missed** (hard-won,
  `write_backend_bisect.md`): every build must be registered in `Metadata.iwa.yaml`
  → `TSP.PackageMetadata` → the slide's component → `objectUuidMapEntries` with
  `uuid == KN.BuildChunkArchive.buildId`; and `lastObjectIdentifier` must stay
  above every minted archive id.
- **Pack works on 15.3** via the 14.4 registry + regenerated 15.3 protos ("Option A").
  Both are vendored at `research/vendor/keynote-parser/`.

## Toolchain

### Swift

**6.4 (dev) and newer only.** `// swift-tools-version: 6.4`.

- Preferred: `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun swift build`
- Secondary (assertions on): `swiftly run swift build +6.4.x-snapshot-2026-06-15`

### Python (reference backend — Step 4 goldens only, never a runtime dep)

Verified working from a clean checkout on 2026-07-28. `.venv/` is gitignored, so
**each fresh worktree repeats this**:

```
mise trust                                            # new worktree => untrusted .mise.toml
mise exec -- python3 -m ensurepip --upgrade           # venv ships without pip
mise exec -- python3 -m pip install 'keynote-parser==1.14.4.0' 'grpcio-tools==1.82.1'
mise run test                     # => DECKKIT TEST PASS
mise run prepare-keynote-parser   # => 631 registry entries; 0 missing message names
mise run verify-pack              # => PASS build_in_B / build_action_B / direction_B
```

The vendored 15.3 schema **is** reproducible — `prepare-keynote-parser` rebuilds
the hybrid from `research/vendor/` with no scratchpad artifacts, closing the risk
flagged in the prototype's memory notes.

Useful corroboration for Q1: `verify_hybrid_parser.py` compares **structurally**,
not byte-wise — the Python path never asserted byte-identity either.

## The two real risks

Everything above the container is well-specified by the prototype's findings.
Two things are not.

**1. The IWA container in Swift (Step 2).** Apple's `.iwa` files are protobuf
messages framed by `TSP.ArchiveInfo` headers inside a *non-standard* Snappy
stream. The Python path got this from `keynote-parser` for free; we must
reimplement it, and it is the substrate everything else sits on.
*Mitigation:* Step 2's semantic round-trip gate runs against the 24 committed
fixtures **before** any authoring code is written.

**2. Slide and text-item supply (Step 4b).** The bundled template has a fixed
number of slides; users author arbitrarily many. Duplicating template slides
means minting ids and maintaining `objectUuidMapEntries` + `lastObjectIdentifier`
by hand — **exactly the invariants that caused the SIGTRAP crash**, on a code
path the Python backend never exercised (it only mutated decks whose slides
already existed).
*Mitigation:* its own gate; and #10's AppleScript path is the known escape route,
at the cost of a live-Keynote dependency.

## Execution tracker

Active v0.1.0 work is filed on GitHub under map
[#12](https://github.com/brightdigit/KeynoteKit/issues/12) (label `v0.1.0`).
Claim, block, and close tickets there — not in local scratch files.

Parallel lanes / worktree layout: [`PARALLEL-WORKTREES.md`](PARALLEL-WORKTREES.md).

| PLAN step | Ticket |
|---|---|
| 0 Package skeleton + scaffolding | [#13](https://github.com/brightdigit/KeynoteKit/issues/13) (overlaps [#9](https://github.com/brightdigit/KeynoteKit/issues/9)) |
| 1 Vendor schema (`KeynoteKitProtobuf`) | [#14](https://github.com/brightdigit/KeynoteKit/issues/14) |
| 2 Snappy package survey | [#15](https://github.com/brightdigit/KeynoteKit/issues/15) |
| 2 Snappy block codec | [#16](https://github.com/brightdigit/KeynoteKit/issues/16) |
| 2 IWA framing + `.key` zip round-trip | [#17](https://github.com/brightdigit/KeynoteKit/issues/17) |
| 3 Archive navigation | [#18](https://github.com/brightdigit/KeynoteKit/issues/18) |
| 4 Regenerate Python golden decks | [#19](https://github.com/brightdigit/KeynoteKit/issues/19) |
| 4 Writer + invariants | [#20](https://github.com/brightdigit/KeynoteKit/issues/20) |
| 4b Minimal bundled template | [#21](https://github.com/brightdigit/KeynoteKit/issues/21) (see also [#7](https://github.com/brightdigit/KeynoteKit/issues/7)) |
| 4b Slide + text-item supply | [#22](https://github.com/brightdigit/KeynoteKit/issues/22) |
| 5 Authoring API | [#23](https://github.com/brightdigit/KeynoteKit/issues/23) |
| 6 Acceptance (Keynote 15.3) | [#24](https://github.com/brightdigit/KeynoteKit/issues/24) |

Frontier (unblocked now): #13, #15, #19.

## Plan

Each step ends in a runnable gate. Steps 2 and 4b carry the risk; do them in
order and don't start authoring code until Step 2's gate is green.

### 0. Package skeleton + scaffolding (#13, overlaps #9)
`Package.swift` (tools 6.4). Prefer **fine-grained products/targets** — splitting
is cheap; gluing later is not. v0.1.0 ships these **products** (each with a
matching library target unless noted):

| Product | Role | v0.1.0 |
|---|---|---|
| `Snappy` | Generic block codec (nothing Apple-specific) | Implemented (or thin wrapper over a dep after the Step 2 survey); exit → #5 |
| `IWAFraming` | Apple chunk layout over the block codec | Implemented |
| `KeynoteKitProtobuf` | Generated 15.3 messages + `TSPRegistryMapping` | Implemented (Step 1); keeps protoc output out of the DSL module |
| `KeynoteKit` | Public authoring API + `deck.write(to:)` | Implemented — **must not** link ScriptingBridge |
| `KeynoteKitScripting` | ScriptingBridge escape hatch (#10) | **Scaffolded empty** in Step 0 (name + product reserved); body is #10, past v0.1 |

Dependency direction: `KeynoteKit` → (`IWAFraming` → `Snappy`) + `KeynoteKitProtobuf`.
`KeynoteKitScripting` depends on Apple frameworks only — **not** on the write
path, and the write path must not depend on it. Tests per product as needed.
Keep `research/` untouched as the reference corpus.

Bring over the BrightDigit scaffolding from **SyndiKit** (closest reference —
already on Swift 6.4 tooling): `.swift-format`, `.swiftlint.yml`,
`.periphery.yml`, `.spi.yml`, `Scripts/lint.sh`, `.github/workflows/` with
`brightdigit/swift-build@v1`. Deviation: **6.4+ only** (no
`Package@swift-*.swift` fallbacks).

**Cross-platform, not macOS-only** (decided in #13, superseding this plan's
earlier "macOS-only — we target Keynote"). Most of the package is portable:
`Snappy` is a generic block codec, `IWAFraming` is zip + protobuf framing, and
`KeynoteKitProtobuf` is generated messages. Only `KeynoteKitScripting` needs
Apple frameworks, and it is gated with `#if canImport(ScriptingBridge)` so it
compiles to an empty module elsewhere rather than failing the build. Never use
`.linkedFramework("ScriptingBridge")` — that would break Linux unconditionally.
CI runs a Linux job to keep this honest; without it, a stray `Darwin` import
regresses portability silently. Keeping `Snappy` Linux-clean also enforces the
separation that #5 depends on.

**Resolved in #13:** the root `mise.toml` was renamed to `.mise.toml` and the
Swift toolchain merged into it — one config file, matching SyndiKit and Bitness.
The two sets of keys are disjoint, and all nine Python research tasks
(`test` / `prepare-keynote-parser` / `verify-pack` included) are preserved.

**Gate:** empty package builds and tests on 6.4; all five products declared;
`KeynoteKit` does not import ScriptingBridge; `Scripts/lint.sh` clean.

### 1. Vendor the schema into Swift (#14)
Generate Swift types from `research/vendor/keynote-parser/protos/15.3/*.proto`
(33 files; 34 compiled including `compat/14.4/TSKArchives_sos.proto`) with
swift-protobuf into the **`KeynoteKitProtobuf`** product.
Port the 14.4 `TSPRegistryMapping` (type ID → message name, e.g.
`8: KN.BuildArchive`, `153: KN.BuildChunkArchive`) into generated Swift — it is
a flat table, so this is mechanical. Check generated sources in; do not require
`protoc` at build time.
**Gate:** every archive type named in the findings decodes from its `.proto`.

### 2. IWA container read/write — **the crux** (#15 survey, #16 codec, #17 framing)
Implement Apple's Snappy variant + `TSP.ArchiveInfo` framing, and the `.key`
bundle (zip) layer around it.

The `.key` stack, outermost in: **zip bundle → `.iwa` files → Apple-framed
Snappy → `TSP.ArchiveInfo`-delimited protobuf messages**. swift-protobuf covers
only the innermost layer; Steps 1–2 build the rest.

Snappy is a fast/low-ratio LZ77-style codec. Apple uses the standard **block
format** but a **non-standard stream framing** — no `sNaPpY` stream identifier,
custom chunk headers, no CRC-32C checksums — so a stock *stream*-oriented Snappy
package will reject `.iwa` input outright. The compressor need only be
Keynote-compatible, not optimal. Default plan: **vendor** the block codec (Q3 /
#5); the Step 2 survey may replace that with a package dependency if one exposes
block-level APIs.

**Vendoring here is temporary — design for its removal (#5).** Keep a hard
seam between the two layers:

- `Snappy` — the generic block codec. Nothing Apple-specific. This is the part
  that should later become an external package dependency.
- `IWAFraming` — Apple's chunk layout, calling only the block codec's public
  API.

If the framing layer never reaches into codec internals, #5 becomes a
`Package.swift` edit rather than a refactor.

**First task of this step — Snappy package survey (blocking on vendor-vs-depend).**
Survey which Swift Snappy packages expose **block-level** compress/decompress
(not only the standard framed stream), and whether they are pure Swift or C++
shims. If a suitable package already exists, depend on it and write only
`IWAFraming`. Otherwise vendor the block codec as planned above; #5 remains the
exit either way. Record the survey result in the decision log before implementing
the codec.
**Gate (hard, blocking) — SEMANTIC round-trip:** for all 24 committed
fixtures in `research/fixtures/`, unpack → repack → unpack and assert the
**archive graph is identical**. This mirrors what the Python backend already
does (`archive_backend.py:352-355`: `_parser("unpack", packed, verified)`), and
it is the property Keynote actually requires — the file must be *accepted*, not
byte-equal to its original.

**Byte-identity is a DIAGNOSTIC, not a gate.** Snappy leaves the encoder real
freedom (match length, which candidate offset to use, when to stop searching),
Apple's encoder is closed-source and may not even be stock Snappy, and the
prototype never demonstrated byte-identity — its verification was structural
throughout. Making it blocking risks stalling on a property that was never
required.

So: run byte-comparison as an experiment and record the result. If it holds,
promote it to a stricter regression check (it is the cheapest way to catch
encoder drift that semantic comparison misses). If it doesn't, note it in
`research/findings/` and move on.

A cheap early probe, if we ever want the answer sooner: unpack+repack a fixture
with the **Python** `keynote-parser` and compare bytes. If Python can't
reproduce them, Swift won't either.

### 3. Archive navigation (internal — **not** a public reading API) (#18)

**Reading a `.key` is explicitly out of scope as a feature.** The goal is
*authoring*. But archive-level reading is still **required infrastructure**, for
two reasons:

1. Template surgery is unpack → mutate → repack, so the writer must parse the
   template to find the slide, resolve `drawable.identifier`s, and locate
   `objectUuidMapEntries`.
2. Every gate from here on is checked by reading our own output.

So build the *navigation* layer only — decode `.iwa` into typed protobuf
messages and walk the graph. Explicitly **not** in v0.1.0:

- a public `Deck(readingKeynoteAt:)` API (→ #6)
- a full typed `Deck`/`Transition`/`Build` IR reconstructed *from* a file
- graceful handling of arbitrary third-party decks

Scope it as test infrastructure: correct for our fixtures, no API-quality
polish. It may live in the test target.

**Gate:** Swift reproduces `deckkit.extract_builds` results on the 24 committed
fixtures — compared at **archive level**, which is the representation both sides
genuinely share (comparing two `Deck` IRs would test our own abstraction as much
as the format).

### 4. Writer / archive surgery (#19 goldens, #20 writer)
Port `archive_backend.py`: mint archives, wire `builds`/`buildChunks`, flip
`hasExplicitBuilds`, and **enforce the two invariants from Step 0's notes** —
port `_verify_uuid_map` as a precondition, not an afterthought. This is where
the crash came from last time.

**First task of this step — regenerate the golden decks (#19).** The Python
backend's outputs are *gone*: `research/samples/` is gitignored, so only the
five JSON specs survive (`examples/bisect_{in,out,action,direction}.json`,
`examples/build_acceptance.json`). Regenerate with the Python backend, then
**commit the resulting `.key` files** so Swift has a fixed differential target:

```
mkdir -p research/samples          # gitignored + must exist, else save fails -10000
mise exec -- python3 research/tools/authored_build_smoke.py \
    research/examples/bisect_in.json research/samples/bisect_in.key --no-reopen
```

Needs Keynote (AppleScript drives deck creation) — it takes over the app while
running. Also treat this as a **staleness check**: the specs were last exercised
by a backend that has since been fixed twice.

**Gate (two parts, they compose):**
1. **Differential** — Swift re-emits all five decks; archive graphs match the
   committed Python goldens. Catches a subtly-wrong-but-self-consistent writer,
   which is the failure mode that cost a 4-deck bisect last time.
2. **Standalone invariants** — assert directly, with no Python reference, that
   build archives exist, `objectUuidMapEntries` registers each `buildId`, and
   `lastObjectIdentifier` exceeds every minted id. These make a red diff
   *diagnosable*.

### 4b. Bundled template + slide/text-item supply (#21 template, #22 supply; see also #7)

Template surgery needs a base deck shipped as a SwiftPM **resource** — a
minimal hand-authored blank-theme `.key`, not one of the 460 KB themed
fixtures. Use `.copy(...)` (not `.process(...)`): a `.key` is a
directory-shaped bundle. Expose `basedOn:` on the write entry point from day
one, defaulting to the bundled template — retrofitting it later breaks the
primary API. Full rationale and the redistribution caveat: #7 / #21.

**The unproven part — supply.** The template has a fixed number of slides and
text items; users author arbitrarily many. So the writer must **duplicate**
template slides N times, minting new ids and registering each in the package
metadata. The Python backend **never did this** — it only mutated decks whose
slides already existed. This is new work on exactly the invariant-maintenance
that caused the SIGTRAP crash, and it is the **second-biggest risk in the plan
after the Snappy framing**.

Text items are the same problem one level down.

**First task of this step — text-item supply lookup (blocked on #21 / #7's template).**
Once the minimal blank-theme template exists, inspect it and decide: reuse
placeholder text items (cheap) or synthesize `TSWP` archives (a slice of #2
leaking into v0.1.0). Record the choice in the decision log before implementing
supply. Do not guess from themed fixtures — the blank template is the authority.

**Gate:** author a deck with more slides — and more text items per slide — than
the template contains; `_verify_uuid_map`'s invariants hold for every minted id.

### 5. Authoring API (#23)

Ship the grilled public surface (canonical sketch in **Goal** above). Details:

**Composition (SwiftUI mirror at slide level):**
- `SlideContent` protocol + `@SlideBuilder` — custom slide types, extracted
  helpers, shallow `Deck { }` bodies. `Deck` accepts `SlideContent` values.
- Inside a slide: concrete `Text` only for v0.1.0. No item-level `SlideItem`
  protocol yet — revisit when shapes/images land (#4).

**Drawables:**
- `Text("…")` with `.position(x:y:)` (default documented; Python parity 200/200)
  and optional `.magicId(_:)` for Magic Move pairing (compile-time only; lowering
  rule in `deck_model_notes.md` §3).

**Builds (In/Out):**
- `.build(.in|.out) { effects… }` — required kind on the call; one or more
  effects in the builder; target = enclosing `Text`.
- Delivery order = **encounter order** walking the slide builder. No
  `buildOrder`, no build-event ids.
- Timing/triggers via SwiftUI-style chaining on each effect: `.duration`,
  `.delay`, `.trigger(.onClick | .afterPrevious | .withPrevious)` (default
  `.onClick`).

**Action (distinct payload):**
- Separate `.action { MotionPath(/* full bezier */) … }` on `Text`.
- Same delivery timeline as builds (one ordered `builds`/`buildChunks` list);
  same chaining for duration/delay/trigger. Full `editableBezierPathSource` in
  v0.1.0 (not a simplified Move-only sugar).

**Transitions:**
- Modifier on `Slide`: `.transition(.magicMove.duration(1).delay(0).autoAdvance(false))`.
- Direction via a **typed enum** on directional effects only (e.g. `.push`,
  `.moveIn`), chained as `.direction(.…)`.

**Catalogs — acceptance-proven cases only:**
- Transitions: the set exercised by acceptance (including `none`, `magicMove`,
  `dissolve`, `push`, `moveIn`) — not all 43.
- Build In/Out effects: the Exp 9 catalog set used by acceptance.
- Directions: only ordinals verified for those effects.
- No `.custom(archiveName:)` and no raw-`Int` direction escapes in v0.1.0.

**Write:**
- `try deck.write(to: url, basedOn: …)` — method on `Deck`; `basedOn` defaults
  to the bundled template (#7). Must never require a running Keynote.

Drawable IR remains **text + position only**. Consequence: Magic Move can
express a **translation** but **not a size or style change**. Geometry is #3;
shapes/images #4.

**Gate:** the Goal sketch compiles and produces a valid deck.

### 6. Acceptance — human-in-the-loop (#24)

**Why this step exists.** On 2026-07-18 the Python backend produced a deck that
passed *every* automated check — round-tripped, structurally correct,
`extract_builds` read back exactly what was written — and Keynote still crashed
opening it (`EXC_BREAKPOINT/SIGTRAP` in the animation framework). Root cause was
the two document-level invariants now enforced by `_verify_uuid_map`; finding
them took a 4-deck bisect (that is why `examples/bisect_*.json` exist).

**Structural correctness does not imply Keynote will open the file.** There is
no substitute for the real app.

Procedure:

1. Author the five acceptance decks from Swift (4 bisect cases + `build_acceptance`).
2. Open each in Keynote 15.3 **by hand**.
3. Confirm, per deck:
   - no crash
   - **no repair warning** — a silent "repair" means we emitted something
     invalid that Keynote chose to tolerate; that is a failure, not a pass
   - In/Out/Action builds, multiple ordered builds, and transition direction
     all survived — Action via the public `.action { MotionPath… }` API;
     direction via the typed `.direction(…)` enum on the transition
4. Tag `v0.1.0`.

**Automation limit — do not skip the human.** `authored_build_smoke.py` can
drive Keynote to open a deck, but a real crash surfaces there as AppleEvent
`-10000`/`-609` rather than a clean signal; its own docstring says a failure
"is NOT sufficient evidence of the crash: open the artifact by hand to confirm."
Even with the self-hosted runner (#8), CI gets a **smoke test**, not the verdict.

Keep it cheap to repeat: fixed set of five decks, generation fully scripted, and
the checklist above written down so the human's job is "open five files and look"
rather than a fresh judgment call each time.

**Gate:** human confirmation — the same gate the Python backend had to pass.

## Deferred past v0.1.0

**Breadth, not correctness:** the remaining 35 of 43 transition effects, the full
`direction` enum (only two ordinals observed), per-effect option coverage,
`buildOrder` / build-event ids (layout≠timeline), an item-level `SlideItem`
protocol, simplified Move sugar over `MotionPath`, and Keynote versions other
than 15.3.

**Filed as issues** (separate from the v0.1.0 tracer bullets #13–#24):

| # | Item | Note |
|---|---|---|
| [#2](https://github.com/brightdigit/KeynoteKit/issues/2) | Authoring from nothing (no template) | needs theme/master/stylesheet synthesis research |
| [#3](https://github.com/brightdigit/KeynoteKit/issues/3) | Drawable geometry (w/h, z-order) | unblocks size-changing Magic Move |
| [#4](https://github.com/brightdigit/KeynoteKit/issues/4) | Shapes and images | Exp 8 proved shape *builds* work; authoring doesn't |
| [#6](https://github.com/brightdigit/KeynoteKit/issues/6) | Public `Deck(readingKeynoteAt:)` | reading is explicitly not a v0.1.0 feature |
| [#7](https://github.com/brightdigit/KeynoteKit/issues/7) | Minimal bundled template | **v0.1.0 blocker** — execution ticket is [#21](https://github.com/brightdigit/KeynoteKit/issues/21); see step 4b |
| [#8](https://github.com/brightdigit/KeynoteKit/issues/8) | Self-hosted macOS runner | Keynote-dependent CI jobs |
| [#9](https://github.com/brightdigit/KeynoteKit/issues/9) | BrightDigit scaffolding (lint/CI) | SyndiKit is the reference; overlapped by [#13](https://github.com/brightdigit/KeynoteKit/issues/13) |
| [#10](https://github.com/brightdigit/KeynoteKit/issues/10) | ScriptingBridge escape hatch | **additive only** — not an authoring backend |

### On #10 and the authoring path

ScriptingBridge is a **public escape hatch, not a second backend**:
`deck.write(to:)` must never require a running Keynote. Decided 2026-07-28.

Worth recording, because it is the standing fallback if step 4b goes badly:
the AppleScript path *does* create slides and text items with Keynote
maintaining every invariant itself — no id minting, no `objectUuidMapEntries`
bookkeeping — and `research/tools/deckkit.py:308` (`generate_applescript`) is
proven working code that does it. Switching to it would trade self-containment
for a live-Keynote dependency. Not the plan; the escape route.

## Open questions

1. ~~**Templates vs. from-scratch.**~~ **RESOLVED:** v0.1.0 keeps the surgery
   model behind a from-scratch-looking facade, shipping a minimal bundled
   template. Authoring with no template at all is deferred to
   [#2](https://github.com/brightdigit/KeynoteKit/issues/2).
2. ~~**Drawable authoring depth.**~~ **RESOLVED: option (a)** — parity with the
   Python IR (`text`, `x`, `y`). Geometry → #3, shapes/images → #4.
3. ~~**Snappy dependency.**~~ **RESOLVED 2026-07-29 (#15): vendor a pure-Swift
   block codec**, and vendor the Apple-variant framing on top; depend on
   swift-protobuf. The survey overturned the premise that stock libraries hide
   the block codec — they don't — but no *trustworthy* Swift package exposes it:
   the sole pure-Swift candidate (`codelynx/snappy-swift`) is 2★, one author, a
   single squashed commit, no CI, and its product name collides with ours; every
   other option is a C/C++ shim, Apple-only, half-finished, or unlicensed.
   Measured, not assumed: all 25 fixture `.iwa` files decode with a stock block
   decompressor, and Apple's chunk header is 4 bytes with no `sNaPpY` identifier
   and no CRC-32C. Vendoring is still an **expedient, not the destination** —
   moving to a package dependency is #5. Full writeup:
   `research/findings/snappy_survey.md`.

4. ~~**Step 2 gate: byte-identical or semantic?**~~ **RESOLVED: semantic.**
   Byte-identity is a diagnostic, not a blocking gate — see Step 2.
5. ~~**Golden decks: regenerate when?**~~ **RESOLVED:** at the start of Step 4,
   not during planning. They need Keynote and take over the app.
6. ~~**Is a reading API in scope?**~~ **RESOLVED: no.** The goal is authoring.
   Archive navigation is internal test infrastructure; the public reading API
   is #6.
7. ~~**ScriptingBridge: escape hatch or backend?**~~ **RESOLVED: escape hatch
   only** (#10). `deck.write(to:)` must never require a running Keynote.
8. ~~**Public authoring API shape?**~~ **RESOLVED 2026-07-28** — see Step 5 and
   the Goal sketch. Highlights: `SlideContent` composition; `.build(.in|.out)` +
   separate `.action`; encounter-order builds (no `buildOrder`); transition /
   position / magicId as modifiers; proven-only catalogs; all three triggers.

## Decision log

Every decision above, with the reasoning that is easy to lose:

| Decision | Chose | Because |
|---|---|---|
| Backend | Native Swift IWA/protobuf | self-contained package, no Python at runtime |
| Swift floor | 6.4 (dev)+ only | user directive; no back-compat shims |
| Template | surgery on a bundled minimal template | from-scratch synthesis is unresearched (#2) |
| Drawable IR | `text`/`x`/`y` parity with Python | smallest proven step; geometry #3, shapes #4 |
| Snappy | **vendor a pure-Swift block codec** (#15 survey; exit stays #5) | Block-level APIs *are* common (google/snappy's C API, `codelynx/snappy-swift`) — but the only pure-Swift candidate is 2★/1-commit/no-CI, and a C/C++ shim would owe per-platform stdlib linking + hand-generated `config.h` across the Ubuntu/Windows/Android legs. ~200 lines of a format frozen since 2011 beats both. See `research/findings/snappy_survey.md` |
| protobuf | depend on swift-protobuf | 13,863 lines of `.proto`; hand-rolling is not sensible |
| Step 2 gate | semantic round-trip | Keynote requires *acceptance*, not byte-equality |
| Reading | internal only (#6) | goal is authoring; reading is test infrastructure |
| ScriptingBridge | escape hatch only (#10); **separate product** `KeynoteKitScripting` | keeping the authoring path free of live Keynote — module boundary, not a comment |
| Package products | split finely by default (`Snappy`, `IWAFraming`, `KeynoteKitProtobuf`, `KeynoteKit`, `KeynoteKitScripting`) | cheap now; gluing coupled modules later is expensive |
| Build DSL | `.build(.in\|.out) { effects… }`; separate `.action` | In/Out share shape; Action's motion-path payload differs enough for its own function |
| Build order | encounter order only | `buildOrder` / build-event ids cut — declaration order is enough for v0.1 |
| Triggers | all three (onClick / afterPrevious / withPrevious) | archive supports them; default onClick |
| Timing knobs | SwiftUI-style chaining on effect/action/transition | matches inspector mental model; duration lives with the effect, not the build call |
| Magic Move id | `.magicId(_:)` + `.transition(.magicMove…)` | Keynote vocabulary; don't over-promise SwiftUI's `matchedGeometryEffect` |
| Transitions | `.transition` modifier on `Slide` | slide-level state expressed like SwiftUI, not an init arg |
| Direction | typed enum, proven ordinals only | raw ints are opaque; expand when more ordinals are verified |
| Effect catalogs | acceptance-proven cases only | no `.custom` escape — breadth is deferred, not correctness |
| Composition | `SlideContent` + `@SlideBuilder`; concrete `Text` inside | SwiftUI-scale decks without a second item protocol yet |
| Write entry | `deck.write(to:basedOn:)` | README-shaped; `basedOn` defaulted from day one |
| Action path | full `MotionPath` bezier in v0.1 | acceptance includes Action; simplified Move deferred as sugar |

### Known consequences we accepted knowingly

- **No size- or style-changing Magic Move** in v0.1.0 — the IR has no
  width/height/style to differ between slides (#3 lifts this).
- **No shape or image authoring** — even though Exp 8 proved shape *builds*
  serialize correctly (#4 lifts this).
- **A `.key` ships inside the package** — binary in git history, downloaded by
  every consumer, and it carries Apple-authored theme content (#7 minimizes,
  does not eliminate).
- **v0.1.0 writes but cannot read** — an odd shape for a library (#6 lifts this).
- **No `buildOrder` / build-event ids** — layout order of `Text` declarations
  *is* delivery order; decoupling them is a later escape hatch if needed.
- **No item-level `SlideItem` protocol** — only `SlideContent` scales composition
  in v0.1; item extraction waits on shapes/images (#4).
- **Public effect/direction enums are narrow** — unproven archive strings are
  not expressible without expanding the catalog.
