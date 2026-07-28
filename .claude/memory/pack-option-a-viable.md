---
name: pack-option-a-viable
description: keynote-parser pack works on Keynote 15.3 via 14.4 registry + regenerated 15.3 protos (Option A); hybrid lives in ephemeral scratchpad
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

**Reproduction is fragile — it depends on ephemeral scratchpad artifacts, not the
repo.** The hybrid package (14.4 codec + 14.4 mapping.py + 15.3 `generated/`) was
assembled in a session scratchpad, and the 15.3 protos came from a *prior*
session's scratchpad (`gen_out/`, `proto_out/`, the keynote-parser clone). These
get cleaned up. To make it durable, **vendor the 15.3 `generated/` + reuse 14.4
`mapping.py` into a pinned local keynote-parser inside the repo** — this is next
step (a) and should happen before further pack work.

Gotchas when rebuilding the hybrid: 15.3 `_pb2.py` need **protobuf ≥ 7.34.1**
(use the repo `.venv`'s 7.35.1, NOT the spike's protovenv 3.20.3); run
`dumper/rewrite_imports.py` to convert flat imports to package-relative; keep
14.4's `TSKArchives_sos_pb2.py` (15.3 dropped it but the registry imports it), and
do NOT re-run rewrite_imports on that already-package-relative file (it double-
prefixes). Related: [[keynotekit-env-gotchas]].
