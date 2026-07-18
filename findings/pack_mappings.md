# Regenerating keynote-parser pack mappings for Keynote 15.3 — feasibility spike

_Recorded: 2026-07-17. Bounded feasibility assessment, NOT a promise of working
pack. Builds on `findings/versions.md` (the 14.4 -> 15.3 version gap that makes
`keynote-parser pack` output silently rejected by Keynote 15.3)._

## TL;DR verdict

Regeneration is **partially feasible unattended, but blocked on the one piece
that actually matters**. The proto-definition half of the pipeline runs
end-to-end today with tools already on this machine (pure-Python, no C++
`proto-dump`). The **`TSPRegistryMapping` half — the integer-type-ID -> archive
message-name table the byte-surgery backend needs — cannot be produced
statically**. It requires launching Keynote under LLDB and dumping a runtime
object. That needs a heavier toolchain (Homebrew LLVM with a Python matching the
venv), a debuggable re-sign of a sandboxed Mac App Store app, and fragile
breakpoint logic the upstream author flags as "will break again for sure."
**Not achievable unattended in this spike; needs human/toolchain setup.**

## Tooling: present vs missing

| Tool / input | Needed for | Status |
|---|---|---|
| keynote-parser **source** tree (has `dumper/`) | whole pipeline | **OBTAINED** — cloned `github.com/psobot/keynote-parser` @ `6bc3849` (2025-04-13, post-"multiversion" refactor) into scratchpad |
| `dumper/protodump.py` (proto extractor) | Step 1 | **PRESENT in source** — pure Python; the `proto-dump` C++ tool is NOT required |
| `protobuf < 4` runtime | protodump + protoc gencode | **PROVISIONED** — isolated scratchpad venv, protobuf 3.20.3 (repo venv left untouched at 7.35.1) |
| `protoc` | Steps 5–7 | **PRESENT** — 34.1 at `/opt/homebrew/bin/protoc` |
| `Keynote.framework` + TS* frameworks | Steps 1–2 | **PRESENT** — `/Applications/Keynote Creator Studio.app/Contents/Frameworks/` (genuine Keynote 15.3, per versions.md) |
| Homebrew **LLVM/LLDB** at `/opt/homebrew/opt/llvm` w/ Python matching venv | Step 2 (`extract_mapping.py`) | **MISSING** — only system `/usr/bin/lldb` present; `extract_mapping.py` hard-requires the Homebrew path. `brew llvm` is v22 bottling **python@3.14**, which would NOT match the venv's Python 3.12 |
| Debuggable (get-task-allow) re-sign of the app + ability to launch it under LLDB | Step 2 | **NOT ESTABLISHED** — see blocker |
| `proto-dump` (obriensp C++ Mach-O tool) | — | **NOT NEEDED** — superseded by `protodump.py`; brew has no formula, no pip pkg, no release binary |

## The generator pipeline (learned from the source)

Modern entry point is `python -m dumper.run --app-path <App.app>` (the
README's `cd dumper && make` is stale; there is no Makefile in this revision).
`dumper/run.py` orchestrates:

1. **Proto extraction** — `protodump.extract_proto_files(app, protos/versions/<ver>/)`.
   Pure Python: `rglob`s every file in the bundle, scans bytes for embedded
   `FileDescriptorProto` blobs (finds the `.proto` marker, walks back to the
   `0x0a` length tag, parses until a null protobuf tag), reconstructs `.proto`
   source text, and resolves imports via a `DescriptorPool`. Emits one `.proto`
   per archive type. Input = the `.app` bundle; output = a dir of `.proto` files.
2. **Mapping extraction** — `extract_mapping.extract_mapping(unsigned_copy)`.
   **Dynamic analysis via LLDB.** `run.py` first makes an unsigned+resigned copy
   (`unsigned_copy_of`: `security find-identity` -> `codesign --remove-signature`
   -> `codesign --sign <identity>`). Then `extract_mapping` imports the Homebrew
   `lldb` Python module, creates a target, sets breakpoints
   (`_sendFinishLaunchingNotification`, `_handleAEOpenEvent:`,
   `[CKContainer containerWithIdentifier:]`, plus a `___lldb_unnamed_symbol\d+`
   regex in CloudKit), **launches the app**, returns early out of CloudKit to
   dodge an entitlements crash, and at the breakpoint evaluates the Obj-C
   expression `[TSPRegistry sharedRegistry]`. It parses that description into
   `{int typeID: "message.full.name"}`. Output = the JSON registry mapping.
3. **`generate_mapping.py`** — takes that `{id: name}` dict + the proto dir,
   emits `mapping.py`: `from .generated import X_pb2 as X` lines, a `PROTO_FILES`
   list, `TSPRegistryMapping = {…}`, and `compute_maps()` runtime glue building
   `NAME_CLASS_MAP` / `ID_NAME_MAP`. **It is a dumb serializer — it contributes
   nothing without the dict from Step 2.**
4. **`rename_proto_files.py`** — `TSCHArchives.Common.proto` -> `TSCHArchives_Common.proto`
   and fixes `import` lines (protoc-safe identifiers).
5–7. **`protoc`** compiles each `.proto` to `_pb2.py`, touches `__init__.py`,
   then `rewrite_imports.py` rewrites `import X_pb2 as X__pb2` to the package path.

Key insight: the **field numbers the byte layout depends on live in the `.proto`
files (Step 1, static & working)**. The **archive-type-ID registry (Step 2) is
runtime-only** and is the hard dependency.

## How far the spike got, step by step

1. **Source acquired.** Cloned; located `dumper/{protodump,extract_mapping,generate_mapping,rename_proto_files,rewrite_imports,run}.py`. Read all of them (summary above).
2. **`proto-dump` question resolved.** Not needed — `protodump.py` replaces it. (`brew`/`pip`/release all have nothing named proto-dump anyway.)
3. **Step 1 proto extraction — RAN SUCCESSFULLY.** Isolated venv (protobuf 3.20.3). Ran `extract_proto_files` over `…/Contents/Frameworks/`:
   > Scanning 3,369 files … Found what look like 34 protobuf definitions. Done! Wrote 34 proto files.
   - (Scanning only the single `Keynote.framework` binary yields 0 — the KN*/TSP* protos are spread across the `TS*.framework` binaries, so the whole-bundle scan is required, exactly as `run.py` does.)
   - Extracted set = **33 real archive types** (one spurious `return this.proto` false-positive from a source-string match, trivially dropped). This **matches the 14.4 baseline's 34 `_pb2.py` almost exactly**; the only set-level delta is `TSKArchives.sos.proto`, present in 14.4, **absent in 15.3** — concrete proof the archive schema genuinely shifted (regeneration is warranted, not just a re-tag).
4. **Steps 4–7 rename + protoc — RAN SUCCESSFULLY.** `rename_proto_files` normalized names; `protoc 34.1` compiled all 33 protos to `_pb2.py` (exit 0, import-unused warnings only). So the **entire static pipeline works unattended on this machine.**
5. **Step 2 mapping extraction — NOT ATTEMPTED (stopped at the boundary).** See below.

## Precise next blocker(s) and options

**Blocker: `extract_mapping.py` (the `TSPRegistryMapping`) is runtime-LLDB-only.**
This is the byte-surgery backend's actual dependency (the 14.4 baseline table has
**631 entries**). Three compounding obstacles:

1. **Toolchain — Homebrew LLVM with a version-matched Python.**
   `extract_mapping.py` requires `/opt/homebrew/opt/llvm/libexec/python<maj>.<min>/site-packages`
   for the *running* interpreter. Current `brew llvm` = v22, bottling
   **python@3.14**; the venv is **3.12** -> guaranteed mismatch. Option:
   `brew install llvm` (~1.5 GB keg) **and** re-provision the keynote-parser env
   on Python 3.14 (or find an LLVM keg whose lldb bindings target 3.12). Heavy,
   but off-the-shelf — not a from-source build.
2. **Debuggability of a sandboxed Mac App Store app.** The app has
   `Contents/_MASReceipt/` + hardened runtime + **library validation** (versions.md).
   `run.py`'s naive `remove-signature` + `codesign --sign` does **not** add the
   `get-task-allow` entitlement LLDB needs to attach/launch, and library
   validation will reject a re-sign that doesn't match the frameworks' team.
   Local codesigning identities **do exist** (`security find-identity` lists 5,
   incl. Apple Development), but a working debug launch would need a
   `--entitlements` plist with `get-task-allow` and likely SIP considerations.
   Additionally, `run.py` derives the executable as
   `Contents/MacOS/Keynote Creator Studio`, but the real binary is
   `Contents/MacOS/Keynote` — the script would need patching for this bundle.
3. **Fragility of the dump itself.** The breakpoint/CloudKit-bailout logic is
   explicitly commented as determined "by painstaking experimentation… will
   break again for sure," and it launches a full GUI app. Non-deterministic;
   not unattended-safe.

Per the spike's hard-stop rules, I did **not** install LLVM, re-sign, or launch
the app under a debugger.

**Alternative avenues (documented, not pursued — each hits the versions.md
"manual reconciliation" stop):**

- **Reuse the 14.4 `TSPRegistryMapping` against the 15.3 protos.** The archive
  type set is nearly identical (only `TSKArchives.sos` dropped). *If* Apple kept
  the integer type IDs stable, the 631-entry 14.4 table could be pruned/reused,
  covering existing types and missing only new 15.3 IDs. This is speculative and
  is exactly the manual field/ID reconciliation the boundary says to stop at —
  needs empirical validation, not assumption.
- **Static recovery of the registry** from the binary (the IDs may be emitted by
  `__attribute__((constructor))` registrations / static data rather than
  computed). This is reverse-engineering work, out of scope here.

## Bottom line

- Proto definitions for Keynote 15.3: **regenerable today, unattended** (33
  types extracted + compiled in the scratchpad; repo venv & installed package
  untouched, nothing committed).
- The `TSPRegistryMapping`: **blocked on a runtime LLDB dump** requiring a
  matched Homebrew LLVM toolchain + a debuggable re-sign of a sandboxed App Store
  app + fragile app-launch instrumentation. **Requires human/toolchain setup;
  not achievable in an unattended spike.** Until that table exists for 15.3, a
  byte-surgery pack backend cannot map archive type IDs correctly.

_Scratchpad artifacts (not committed):
`…/scratchpad/keynote-parser` (source),
`…/scratchpad/proto_out` (33 extracted 15.3 `.proto`),
`…/scratchpad/gen_out` (33 compiled `_pb2.py`),
`…/scratchpad/protovenv` (protobuf 3.20.3 env)._
