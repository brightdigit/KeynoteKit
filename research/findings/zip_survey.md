# Zip survey: vendor a STORED-only reader/writer in `IWAFraming`

**TL;DR (decision):** vendor. A `.key` needs only the `STORED` subset of zip —
the DEFLATE codec, the sole reason zip libraries link zlib, is dead code for
this format. Every surveyed dependency fails at least one CI leg or one
container constraint; the vendored implementation is ~500 lines with the
30-file corpus as its conformance suite. Exit condition at the end.

Survey date: 2026-07-29 (issue #17; same rigor as
[`snappy_survey.md`](snappy_survey.md) per the #15 precedent).

## 1. What the corpus actually proves

Probe script: `research/tools/zip_probe.py` over all 30 committed `.key`
files (24 fixtures + 5 goldens + the #21 `blank.key`), 1,604 entries:

| Property | Observed |
|---|---|
| Compression method | `STORED` for **1,604/1,604** entries; zero DEFLATE |
| Data-descriptor flag (bit 3) | 0/1,604 — local headers always carry real sizes/CRC |
| zip64 | no EOCD64, no CD extras, no `0xFFFFFFFF` sentinels (but see below) |
| Directory entries | none |
| Duplicate names | none |
| Archive comments | length 0 in all 30 |
| LH ↔ CD agreement | 0 mismatches on name/method/flags/CRC/sizes |
| CRC-32 of bodies | verified, 0 failures |
| Entry order | all 30 archives: `Data/` → `Index/` → `Metadata/` → root previews |

**Structural quirk that shapes the reader:** 150 *local* headers carry a
20-byte zip64 extra (id `0x0001`) that their central-directory records do
not, on exactly six names — `Metadata/{Properties.plist, DocumentIdentifier,
BuildVersionHistory.plist}` and `preview{,-micro,-web}.jpg`. Version-made-by
is bimodal (62 vs 20), i.e. two writer identities inside every archive. A
reader must therefore locate entry bodies via the **local header's own**
name/extra lengths, never via central-directory field widths.

## 2. Candidates

| Candidate | Backend | STORED write | Order / no-dir-entries | CI-proven platforms | Verdict |
|---|---|---|---|---|---|
| ZIPFoundation 0.9.20 | `Compression` on Darwin, system zlib elsewhere (C shim) | yes (default) | yes | macOS, Linux; **Android proven** (PRs #250, #380 by the Android SDK maintainer) | **No Windows** — POSIX `FILE*`/`funopen` based; upstream points at a 12-star fork (issue #262). Disqualifying |
| swift-zip-archive 0.8.1 | system zlib via C shim + swift-system | yes (`.noCompression`) | order yes; **auto-inserts directory entries** (unconditional `addFolder` in `writeFile`), stamps `.now` mtimes | macOS, Linux, **Windows**; Android unproven (zero mentions) | Closest dependency, but cannot write Keynote-shaped archives today and Android is unproven |
| marmelroy/Zip | vendored minizip C | no control | no | Apple only; last push 2024 | Unmaintained, disqualified |
| SSZipArchive | Obj-C over minizip | limited | no | Apple only | Won't build on Ubuntu/Windows/Android, disqualified |
| SWCompression | pure Swift | **zip is read-only** | n/a | Linux, Windows | Half the problem, disqualified |
| tomasf/Zip | vendored miniz | level-0 | unverified | claims only | No license file, 5 stars — supply-chain non-starter |

Every dependency that can write also drags a zlib/minizip C linkage into the
Android cross-compile — the exact host-dependency class that disqualified
C/C++ Snappy in #15.

## 3. Decision criteria, ranked

1. **Builds on every CI leg** (Ubuntu container, macOS, Windows 2022/2025,
   Android API 28/34 cross-compile) with no system-library assumption —
   vendored: trivially yes; every writer dependency: at least one leg
   unproven or failing.
2. **STORED + exact entry order + no directory entries** — vendored: total
   control; swift-zip-archive: fails no-dir-entries; ZIPFoundation: passes.
3. **Supply-chain trust** — vendored: none added.
4. **Code saved by depending** — negative: the saved code is inflate/deflate,
   encryption, zip64, streaming — all dead code for this format.

## 4. What was vendored

`Sources/IWAFraming/`: `KeyBundle` / `KeyBundleEntry` / `KeyBundleError`
(public), `ZipArchive`, `ZipLocalFileHeader`, `ZipCentralDirectoryRecord`,
`ZipEndOfCentralDirectory`, `ZipBytes`, `CRC32` (internal). Reader: backward
EOCD scan (tolerates 64 KiB comments), central-directory walk, body located
via the local header's own lengths (per §1), CRC-32 verified, `method ≠ 0` /
zip64 sentinels / multi-disk / duplicates throw typed errors — invariants are
*verified*, not silently trusted. Writer: append order preserved verbatim,
`STORED` only, no directory entries, empty extras, version 20, zero
timestamps. Conformance: `KeyBundleTests` + the 24-fixture semantic
round-trip gate in `SemanticRoundTripTests`.

## 5. Exit condition (when to revisit a dependency)

Adopt a dependency (swift-zip-archive is the standing candidate) if the
STORED-only invariant ever breaks in real documents — DEFLATE entries, data
descriptors, or zip64-scale content (e.g. >4 GiB embedded media) — or the
writer needs features beyond framing (encryption, streaming). Preconditions
for that switch: upstream gains a no-directory-entries option and a
demonstrated Swift-Android-SDK build. Tripwire: re-run
`research/tools/zip_probe.py` whenever the corpus grows; the reader's typed
errors (`unsupportedCompressionMethod`, `zip64Unsupported`) fail loudly in
the meantime.
