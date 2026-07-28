# Option A — cheap pack round-trip (14.4 registry + 15.3 protos): **ACCEPTED**

_Recorded: 2026-07-17. Executes the "Option A" experiment defined in
`pack_backend_approach.md` §5. Verdict: **the write backend is viable now** — no
LLDB runtime dump (Option B) required._

## TL;DR

Pairing the **installed 14.4 `TSPRegistryMapping`** (631 entries) with the
**freshly-extracted 15.3 `.proto`s** produces a `keynote-parser` that packs a
`.key` **Keynote 15.3 accepts and opens**. This is outcome (a) from the decision
doc: **type IDs are stable across 14.4 → 15.3**, so the only thing stale in the
installed wheel was the proto/wire layout — which regenerates unattended. The
runtime-registry blocker (Option B) is **not** on the critical path.

This directly overturns the `versions.md` round-trip failure, which used the
**stock** wheel (14.4 protos + 14.4 registry). Swapping in the 15.3 protos — and
nothing else — flips REJECT → ACCEPT.

## What was assembled (the hybrid package)

Built in the session scratchpad; the installed `.venv` was never modified.

| Layer | Source | Notes |
|---|---|---|
| Codec / `file_utils` / `codec.py` | installed 14.4 wheel | version-agnostic; unchanged |
| `TSPRegistryMapping` (`mapping.py`) | installed **14.4** | 631 entries, reused verbatim |
| `generated/*_pb2.py` | **15.3** extraction (spike `gen_out/`, 33 modules) | overlaid onto the 14.4 base |
| `generated/TSKArchives_sos_pb2.py` | installed **14.4** | 15.3 dropped this type; retained so `mapping.py`'s import resolves |

Reconciliation steps required:
- Ran `dumper/rewrite_imports.py` over the overlaid modules to convert protoc's
  flat imports (`import TSPMessages_pb2`) to package-relative
  (`import keynote_parser.generated.TSPMessages_pb2`), matching the 14.4 base and
  avoiding protobuf double-registration under the 7.35.1 runtime.
- The 15.3 `_pb2.py` require **protobuf ≥ 7.34.1** (`runtime_version` guard); they
  load under the `.venv`'s 7.35.1 but **not** under the spike's `protovenv`
  (3.20.3). The hybrid is therefore run via `PYTHONPATH` over the `.venv` runtime.

**Schema-level reconciliation result:** `compute_maps()` resolved **all 631**
registry entries against the 15.3 protos with **zero missing message names**
(`NAME_CLASS_MAP` = 1199, `ID_NAME_MAP` = 629; the 631→629 delta is duplicate
type-IDs, same as the 14.4 baseline). The "manual field/ID reconciliation" stop
point that `versions.md` warned about **did not materialize**.

## The round-trip

Test deck: `samples/regression_check.key` — a real Keynote 15.3 deck, **4 slides**,
~22 embedded images, 58 zip components.

| Step | Result |
|---|---|
| `unpack` (hybrid 15.3 schema) | **PASS** — 58 files, no errors |
| `pack` (hybrid 15.3 schema) | **PASS** — wrote `regression_repacked.key`, no errors |
| Component-set diff (orig vs repack) | **identical** (same 58 names) |
| Size | orig 468,333 B → repack 468,122 B (−211 B, re-compression) |
| **Reopen in Keynote 15.3** (osascript) | **ACCEPTED** — document opens, **4 slides** |
| Fidelity check | original also opens at **4 slides** → slide count preserved |

Acceptance test was scripted: `open` the repacked file, confirm a new document
appears, read its slide count, close without saving. A silent rejection would
have surfaced as no new document / an AppleScript error; neither occurred.

## What this proves — and what it does not

**Proves:** the 15.3 wire schema + 14.4 registry can **re-encode** an existing
15.3 deck to a form Keynote accepts. The pack path is fundamentally sound on 15.3.

**Does not yet prove (next step):** that we can **author a new feature** (inject a
`KN.BuildArchive` / a transition `animationAttributes.direction`) into the YAML,
repack, and have Keynote honor it. Acceptance of an unmodified round-trip is the
prerequisite; the authoring test is now de-risked and worth doing. Also only one
deck was tested — broaden to a builds-bearing deck and the transition fixtures
before depending on this in the backend.

## Recommendation

**Proceed on Option A.** Skip Option B (LLDB / LLVM / re-sign / SIP) unless a
later authoring test exposes a type-ID that actually shifted. Next actions:

1. Promote the hybrid schema to a reproducible artifact (script the overlay +
   `rewrite_imports` + `TSKArchives_sos` retention, or vendor the 15.3
   `generated/` + reuse `mapping.py` into a pinned local keynote-parser).
2. Authoring smoke test: hand-edit an unpacked slide to add a build (using the
   `KN.BuildArchive` shape from `findings/build_*.md`), repack, reopen, verify the
   build is present via `deckkit.extract_builds`.
3. Re-run the round-trip on a deck that already carries builds + on the transition
   direction fixtures, to widen the fidelity evidence.

## Reproduce

Artifacts live in the session scratchpad `pack_optionA/` (hybrid `keynote_parser/`,
`unpacked_153/`, `regression_repacked.key`); the accepted file is also at
`samples/optionA_repacked.key`. 15.3 proto/`gen_out` source: the pack-mapping
spike scratchpad (see `pack_mappings.md`). Run unpack/pack with
`PYTHONPATH=<pack_optionA> mise exec -- python3 -m keynote_parser.command_line …`.
