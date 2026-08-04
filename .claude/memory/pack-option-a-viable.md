---
name: pack-option-a-viable
description: keynote-parser pack works on Keynote 15.3 via 14.4 registry + regenerated 15.3 protos (Option A); the hybrid is now vendored in-repo and rebuilds reproducibly
metadata: 
  node_type: memory
  type: project
  originSessionId: e111f2e3-89a7-4cf2-9d9b-5fe4a7d2a7e6
  modified: 2026-07-18T11:38:01.470Z
---

**Option A succeeded (2026-07-17):** `keynote-parser pack` produces a `.key`
Keynote 15.3 **accepts and opens** when you pair the installed **14.4
`TSPRegistryMapping`** (631 entries, unchanged) with **regenerated 15.3 protos**.
Type IDs are stable 14.4→15.3, so the LLDB runtime-registry dump (Option B) is
NOT needed. The stock wheel fails only because its protos are 14.4. Full writeup:
`findings/pack_option_a.md`; decision doc `findings/pack_backend_approach.md` §5.

**RESOLVED 2026-07-28 — the hybrid is vendored and reproducible.** The earlier
warning that reproduction depended on ephemeral scratchpad artifacts no longer
applies: the schema now lives at `research/vendor/keynote-parser/`
(15.3 `protos/`, 14.4 `compat/`), and `mise run prepare-keynote-parser` rebuilds
the hybrid from the repo alone — verified from a clean worktree checkout with no
scratchpad present (`631 registry entries; 0 missing message names`), followed by
`mise run verify-pack` → PASS on build_in_B / build_action_B / direction_B.

Setup needed in a fresh worktree (`.venv/` is gitignored, so this repeats):

```
mise trust                                     # new worktree => untrusted mise.toml
mise exec -- python3 -m ensurepip --upgrade    # venv ships without pip
mise exec -- python3 -m pip install 'keynote-parser==1.14.4.0' 'grpcio-tools==1.82.1'
```

`prepare_keynote_parser.py` pins both versions and fails loudly on a mismatch.
Note `verify_hybrid_parser.py` compares **structurally**, not byte-wise.

Gotchas when rebuilding the hybrid: 15.3 `_pb2.py` need **protobuf ≥ 7.34.1**
(use the repo `.venv`'s 7.35.1, NOT the spike's protovenv 3.20.3); run
`dumper/rewrite_imports.py` to convert flat imports to package-relative; keep
14.4's `TSKArchives_sos_pb2.py` (15.3 dropped it but the registry imports it), and
do NOT re-run rewrite_imports on that already-package-relative file (it double-
prefixes). Related: [[keynotekit-env-gotchas]].
