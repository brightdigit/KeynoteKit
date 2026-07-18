# The build/direction write backend — approach, options, and glossary

Decision-support companion to `pack_mappings.md` (the feasibility spike) and
`versions.md` (the 14.4→15.3 version gap). Read this to choose how (or whether)
to build the byte-surgery path that can **author** object builds and transition
direction into a `.key`. A **glossary** of every technical term is at the end —
terms in **bold** on first use are defined there.

---

## 1. Why a write backend is needed at all

The project's goal is a `Deck` model + a backend that turns it into a real
Keynote file. That backend has two halves, split by what Keynote's
**AppleScript** dictionary exposes:

| Feature | Authorable via AppleScript? | How we write it |
|---|---|---|
| Slide **transitions** (effect/duration/delay/auto) | **Yes** | `deckkit.py` drives Keynote via `osascript` — DONE, verified, unit-tested |
| Transition **direction** | **No** (not in the `sdef`) | needs byte-surgery |
| Object **builds** (build-in/out, order, timing) | **No** (not in the `sdef`) | needs byte-surgery |

So everything scriptable is already handled with **no pack** dependency. The
*only* way to author builds and direction is to edit the file's bytes directly —
**byte-surgery** — which means writing valid **IWA** archives back into the
`.key`. That is exactly what **`keynote-parser pack`** does… except it doesn't
work for our Keynote version yet.

## 2. What "pack" is, and why it's broken for 15.3

A `.key` is a zip of **IWA** components (protobuf messages, **Snappy**-chunked).
`keynote-parser`:

- **`unpack`** — decodes IWA → readable YAML. **Works on 15.3** because unmapped
  fields are preserved raw (`unknownFieldRule: IgnoreAndPreserve`). This is what
  the whole reverse-engineering pipeline relies on; it needs nothing below.
- **`pack`** — re-encodes YAML → IWA. **Broken on 15.3.** `keynote-parser`
  1.14.4.0 was built against Keynote **≤ 14.4**; its schema (`mapping.py` +
  `generated/*_pb2.py`) is stale, so a repacked 15.3 file has a structure Keynote
  15.3 silently rejects (opens no document). Proven in `versions.md`.

To fix `pack` for 15.3 we must regenerate the schema from *this* Keynote build.
That schema has **two independent pieces**:

1. **The `.proto` definitions** → compiled to **`_pb2.py`**. These carry the
   **field numbers** that determine the wire layout of every archive message.
   **This half already regenerates unattended** (see §3).
2. **The `TSPRegistryMapping`** — the `{integer type-ID → archive message name}`
   table. When packing, each object is tagged with an integer **archive type ID**;
   the registry says which protobuf message that ID means. Without a *correct*
   15.3 registry, packed objects are mislabeled and Keynote rejects the file.
   **This half is the blocker** (see §4).

## 3. What already works (the static half)

From the spike (`pack_mappings.md`), with tools already on this machine:

- The keynote-parser **source** ships `dumper/protodump.py` — a **pure-Python**
  Mach-O protobuf extractor. The old C++ **`proto-dump`** tool is **not needed**.
- Running it over `Keynote Creator Studio.app/Contents/Frameworks/` extracted
  **33 real 15.3 `.proto` types** and **`protoc`** compiled them all to `_pb2.py`.
- The set matches 14.4 almost exactly (only `TSKArchives.sos` dropped) — proof
  the schema really shifted, so regeneration is warranted.

So field numbers / wire layout for 15.3: **recoverable today, no heavy setup.**

## 4. The blocker: the `TSPRegistryMapping` is runtime-only

`generate_mapping.py` is a dumb serializer — it needs the `{id → name}` dict from
`extract_mapping.py`, and that step is **dynamic analysis**: it launches Keynote
under **LLDB**, sets breakpoints, and evaluates the Objective-C expression
`[TSPRegistry sharedRegistry]` to read the table out of the *running* app
(the 14.4 table has **631 entries**). Three compounding obstacles make this
un-unattended:

1. **Toolchain mismatch.** `extract_mapping.py` hard-requires **Homebrew LLVM**'s
   `lldb` Python bindings, built for the *running* interpreter. Current
   `brew llvm` bottles **python@3.14**; our env is **3.12** → mismatch. Fix:
   install `llvm` (~1.5 GB) and re-provision the env on 3.14 (or find a keg whose
   bindings target 3.12).
2. **Debuggable re-sign of a sandboxed App Store app.** The app has a **Mac App
   Store receipt**, **hardened runtime**, and **library validation**. To attach
   LLDB it must be re-signed with the **`get-task-allow`** **entitlement**, and
   library validation must not reject the re-sign. `dumper/run.py`'s naive
   `codesign` doesn't add that entitlement, and it also assumes the wrong
   executable name (`Keynote Creator Studio` vs the real `Keynote`). Getting a
   debuggable launch may require weakening library validation and/or **SIP**
   (a recovery-mode reboot and a real security tradeoff).
3. **Fragile instrumentation.** The breakpoint/CloudKit-bailout logic is
   upstream-flagged as "will break again for sure," and it drives a full GUI app —
   non-deterministic and not unattended-safe.

## 5. The three options (this is the decision)

### Option A — Cheap path first (reuse the 14.4 registry) — recommended
**Idea:** the installed `mapping.py` already contains the **14.4**
`TSPRegistryMapping` (631 entries). The 15.3 type set is nearly identical. **If**
Apple kept the integer type IDs stable across 14.4→15.3, we can pair the 14.4
registry with the freshly-extracted 15.3 protos and test a real **`pack`
round-trip**: pack a simple deck, reopen it in Keynote 15.3, see if it's accepted.

- **Cost/risk:** low. Runs mostly unattended in the scratchpad; **no** LLVM, **no**
  re-sign, **no** SIP change; the installed package/venv stay untouched.
- **Outcomes:** (a) Keynote accepts it → the write backend is viable *now*, and we
  proceed to encode builds/direction. (b) It rejects it → we've *proven* the
  runtime registry is required, and we choose Option B with evidence.
- **Caveat:** speculative — type-ID stability is an assumption. `versions.md`
  flags "manual field/ID reconciliation" as a stop point; this experiment is the
  cheapest way to test that assumption instead of guessing.
- **What I need from you:** nothing; I can run it. (I paused only because you may
  prefer a different sequence.)

### Option B — Full LLDB runtime dump (the "correct" path)
Do the real `extract_mapping.py`: install Homebrew LLVM, provision a matching
Python env, re-sign Keynote debuggable, launch it under LLDB, dump the 15.3
registry, then `generate_mapping.py` + `protoc` → a complete, correct 15.3 schema.

- **Cost/risk:** high. ~1.5 GB install; interactive `sudo`/`codesign`; likely
  needs to weaken **library validation** / **SIP** (recovery reboot). GUI-launch
  instrumentation is fragile.
- **What I need from you:** hands-on steps I can't do headless (SIP change in
  recovery mode, approving codesign/debug, possibly re-running the LLDB dump).
- **Payoff:** the authoritative 15.3 registry — the only path guaranteed correct
  if type IDs *did* change.

### Option C — Defer the write backend
Keep transitions via AppleScript (working). Builds/direction remain fully
reverse-engineered and modeled (`deck_model_notes.md`) but **read-only** — the
tool can *read/verify* builds, not *author* them. Revisit pack later.

- **Cost/risk:** none. **Trade-off:** the generated `.key` files can carry
  transitions but not builds or non-default transition direction.

### At-a-glance

| | A: Cheap first | B: Full LLDB | C: Defer |
|---|---|---|---|
| Can author builds/direction? | if it works | yes | no |
| Heavy install (LLVM ~1.5 GB) | no | yes | no |
| SIP / library-validation change | no | likely | no |
| Needs your hands-on steps | no | yes | no |
| Mostly unattended | yes | no | n/a |
| Risk | low | high | none |
| Good next step if it fails | → B, with evidence | — | — |

**Recommended sequence:** A → (only if A fails) B; C if you don't need authored
builds soon. A is cheap enough that it's worth trying before committing to B.

---

## 6. Glossary

- **`.key`** — a Keynote document; a zip archive containing **IWA** components,
  `Data/` assets, previews, and metadata.
- **IWA (iWork Archive)** — Apple's binary container: **protobuf** messages
  concatenated and **Snappy**-compressed in chunks. The native on-disk form of
  every Keynote object.
- **keynote-parser** — the open-source Python tool (`psobot/keynote-parser`) that
  `unpack`s IWA↔YAML and (when its schema matches) `pack`s it back.
- **unpack / pack** — decode IWA→YAML / re-encode YAML→IWA. Unpack works on 15.3;
  pack needs a matching schema (the thing we're regenerating).
- **byte-surgery / template surgery** — authoring a feature by editing the file's
  archives directly (via pack), rather than asking the app to make it. The only
  route for features absent from AppleScript.
- **AppleScript / `sdef` / `osascript`** — macOS automation language / an app's
  scripting-definition dictionary / the CLI that runs a script. Keynote's `sdef`
  exposes transition effect/duration/delay/automatic — but **not** direction or
  builds.
- **protobuf (Protocol Buffers)** — Google's binary serialization format used
  inside IWA. Messages are defined in **`.proto`** files.
- **`.proto` file** — the schema/source defining a protobuf message's fields.
- **field number** — the integer tag identifying each field on the wire. The byte
  layout depends on these; if they shift between Keynote versions, an old schema
  mis-decodes/mis-encodes. (`versions.md` warns these "can shift between
  releases.")
- **`_pb2.py`** — Python classes generated from a `.proto` by **`protoc`**;
  keynote-parser imports these to read/write messages.
- **`protoc`** — the protobuf compiler (`.proto` → `_pb2.py`). Present here
  (v34.1, Homebrew).
- **FileDescriptorProto** — protobuf's own description of a `.proto` file, embedded
  in compiled binaries; **`protodump.py`** scans the app's Mach-O binaries for
  these blobs to reconstruct the `.proto` sources.
- **Snappy** — the fast compression IWA uses to chunk archives (via `python-snappy`
  / `cramjam`).
- **`TSPRegistry`** — an iWork runtime singleton (`[TSPRegistry sharedRegistry]`)
  holding the master table of archive types for this app build.
- **`TSPRegistryMapping`** — the `{integer type-ID → archive message name}` table
  extracted from `TSPRegistry`. Pack needs it to tag each object with the right
  type ID. **This is the missing 15.3 piece.**
- **archive type ID** — the integer Keynote writes to label an archived object;
  the registry maps it to a message name like `KN.SlideArchive`.
- **`KN.*` / `TSP.*` / `TS*.framework`** — the iWork archive namespaces
  (`KN` = Keynote, `TSP` = persistence, `TS*` = shared iWork frameworks). The
  15.3 protos are spread across all the `TS*.framework` binaries, so extraction
  scans the whole app bundle.
- **`dumper/`** — keynote-parser's (source-only) mapping-regeneration pipeline:
  `run.py` (orchestrator) → `protodump.py` (extract `.proto`) → `extract_mapping.py`
  (LLDB dump of the registry) → `generate_mapping.py` (serialize `mapping.py`) →
  `rename_proto_files.py` / `rewrite_imports.py` / `protoc` (compile).
- **`proto-dump`** — an *older* C++ Mach-O proto extractor (obriensp). **Not
  needed** — `protodump.py` supersedes it.
- **LLDB** — the LLVM debugger. `extract_mapping.py` uses its Python bindings to
  launch Keynote, breakpoint, and evaluate an Objective-C expression at runtime.
- **Objective-C runtime / `[TSPRegistry sharedRegistry]`** — the live method call
  LLDB evaluates to read the registry out of the running app.
- **codesign / code signature** — the cryptographic signing of a macOS app. Apps
  from the store are signed by Apple; re-signing changes entitlements/identity.
- **entitlement / `get-task-allow`** — capabilities baked into a signature. LLDB
  can only attach to a process whose signature includes `get-task-allow`
  (debuggable); store apps don't have it, hence the re-sign.
- **hardened runtime** — a signing option that restricts code injection/debugging;
  Keynote uses it.
- **library validation** — a hardened-runtime rule that a process may only load
  libraries signed by the *same team*. A naive re-sign of Keynote can trip this
  because it loads Apple-signed `TS*.framework`s.
- **SIP (System Integrity Protection)** — the macOS kernel protection that (among
  other things) blocks debugging Apple-signed processes. Fully debugging a store
  Keynote may require weakening it — changed only from **recovery mode**, a
  security tradeoff.
- **Mac App Store receipt (`_MASReceipt`)** — proof of store purchase inside the
  bundle; part of why this app is sandboxed/hardened (see the app-identity note in
  `versions.md`).
- **Gatekeeper / `spctl`** — macOS's app-notarization/origin check; used in
  `versions.md` to confirm this app is genuine store-distributed Keynote.
- **`Deck` IR / backend** — this project's intermediate model of a deck
  (`tools/deckkit.py`) and the code that lowers it to a `.key` (AppleScript today;
  byte-surgery for builds/direction later).
- **build / transition / Magic Move** — the Keynote features under study; see
  `deck_model_notes.md`, `build_*.md`, and `magic_move_correspondence.md`.
