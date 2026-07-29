# Snappy block-level package survey — **VENDOR** (write it ourselves)

_Recorded: 2026-07-29. Executes issue [#15](https://github.com/brightdigit/KeynoteKit/issues/15).
Research only — no codec code lands here; the implementation is
[#16](https://github.com/brightdigit/KeynoteKit/issues/16), and
[#5](https://github.com/brightdigit/KeynoteKit/issues/5) remains the exit either way._

## TL;DR

**Decision: vendor a pure-Swift block codec in `Snappy`. Do not add a package dependency.**

The survey found **one** package that genuinely qualifies on the technical
merits — `codelynx/snappy-swift` — and it was tested against real Keynote bytes,
where it decompressed **all 30 `.iwa` chunks in the fixture corpus and
round-tripped every one**. So this is *not* the "no suitable package exists"
outcome that [#5](https://github.com/brightdigit/KeynoteKit/issues/5) predicted.

We are vendoring anyway, and the reason is supply chain, not capability. That
package is **2 stars, one author, a single squashed commit, no CI, no tagged
history, and three months old**. `Snappy` is the substrate the entire format
stack sits on — `KeynoteKit → IWAFraming → Snappy`. Taking a hard dependency
there on an unproven solo repo trades ~200 lines of frozen-since-2011 format
work for a permanent third-party risk, on a package the ecosystem has not
vetted.

**Two premises in the tickets turned out to be wrong**, and both are corrected below:

1. **#5 says stock libraries "expose the *framing* layer as their public API and
   keep the block codec internal."** That is false for every real candidate.
   google/snappy's C API (`snappy-c.h`) is **block-level only** and exposes *no*
   framing functions; `codelynx/snappy-swift` is likewise block-only. Block-level
   access is common, not rare — the scarce thing is a *trustworthy* package.
2. **PLAN says a stock stream-oriented package will "reject `.iwa` outright."**
   True, and now verified from the bytes rather than assumed — see §1.

## 1. What the fixtures actually prove (measured, not assumed)

Everything in this section was derived by decoding
`research/fixtures/*.key` directly, with no vendor library involved. The
`.iwa` framing claim was load-bearing for the whole decision, so it was verified
rather than restated.

**Apple's framing, confirmed:**

| Property | Observed |
|---|---|
| Chunk header | **4 bytes**: `0x00` type byte + **3-byte little-endian** compressed length |
| `sNaPpY` stream identifier | **Absent from all 25 `.iwa` files** |
| CRC-32C checksum | **None** — the 4-byte header leaves no room for one |
| Chunk payload | A **stock Snappy block** (varint preamble + tag elements) |
| Max uncompressed chunk | **exactly 65536** (5 chunks sit on the boundary) → Apple splits at 64 KiB |

**All 25 `.iwa` files decode with a stock block decompressor and zero
Apple-specific logic.** That is the core finding: the block/framing seam PLAN
already specifies is exactly the right one, and `Snappy` needs *only* block
primitives. Apple's non-standard part is entirely the 4-byte chunk header, which
belongs to `IWAFraming` (#17).

Why stream-only libraries are useless here: a framed decoder demands the 10-byte
`0xff 0x06 0x00 0x00 sNaPpY` chunk at byte 0 and errors immediately on a raw
block, which starts with a varint instead. A framed *encoder* emits that magic
prefix plus per-chunk CRC-32C that Keynote would read as garbage. Framing is not
a toggle on one API — upstream `framing_format.txt` states framing "is not part
of the Snappy core specification."

**Encoder behaviour observed in the corpus** (useful for #16):

| Element | Count | Note |
|---|---|---|
| literal (tag `00`) | 8,735 | |
| copy, 1-byte offset (`01`) | 8,550 | |
| copy, 2-byte offset (`10`) | 11,547 | |
| copy, 4-byte offset (`11`) | **0** | never emitted — unreachable given 64 KiB chunking |

Max back-reference offset seen: **60,980** (< 65536). A decoder must still
implement copy4 for spec compliance, but our corpus never exercises it — so it
needs a synthetic test vector, not a fixture.

Apple's aggregate ratio across the corpus: **0.265** (121,897 compressed /
460,624 plain).

## 2. Candidates

| Package | Licence | Pure Swift? | Block API public? | Linux/Win/Android | Maintenance | Verdict |
|---|---|---|---|---|---|---|
| [codelynx/snappy-swift](https://github.com/codelynx/snappy-swift) | BSD-3 | **Yes**, zero deps | **Yes** | No Darwin imports; Linux untested, no CI | **2★, 1 commit, 1 author, 2025-11-03, no CI** | Technically fine, **supply-chain reject** — use as reference |
| [lovetodream/swift-snappy](https://github.com/lovetodream/swift-snappy) | BSD-3 (NOASSERTION) | No — vendors `snappy-c` (~1.6k lines C) | Block-level, but `Data`-extensions only | Claims Linux | **1★, dead since 2022-12-07**, tools 5.7 | Reject |
| [edgeengineer/snappy](https://github.com/edgeengineer/snappy) | NOASSERTION | No (fork of above) | Same | +visionOS | Fork; 2025 commits are chores only, no algorithm work | Reject |
| [awxkee/snappy.swift](https://github.com/awxkee/snappy.swift) | CC0 wrapper | No — **prebuilt `.xcframework`** | n/a | **Apple-only by construction** | 4★, 2023 | **Disqualified** (breaks Ubuntu/Windows/Android CI) |
| [RandomHashTags/swift-compression](https://github.com/RandomHashTags/swift-compression) | Apache-2.0 | Yes | Decompress only — **compress throws `unsupportedOperation`** | — | Active (2026-04) | Reject — half-finished |
| [mrowlinson/SwiftParquet](https://github.com/mrowlinson/SwiftParquet) | **None** | Yes | **All `internal`** — not consumable | — | — | Reject — unlicensed + not public |
| [google/snappy](https://github.com/google/snappy) (vendor C++) | BSD-3 | No | **Yes** — `snappy-c.h` is block-level | Needs hand-generated `config.h` + per-platform C++ stdlib linking | Reference impl | Reject — see §3 |

**Confirmed absent** (searched, no Snappy): `apple/swift-nio-extras`,
`adam-fowler/compress-nio`, `tsolomko/SWCompression`, `swift-server/swift-kafka-client`
(Snappy is inside librdkafka), vapor, mongo/cassandra Swift drivers. GitHub's
`snappy language:Swift` returns 48 repos; the remainder are Snapchat clones,
window managers, SnapKit forks, and snapshot-testing libraries.

**Nothing is on Swift Package Index** except the dead `lovetodream` package.

## 3. Why not the C/C++ routes

The CI matrix is the deciding constraint. `.github/workflows/KeynoteKit.yml` runs
**Ubuntu, Windows, and Android** legs whose stated purpose is "to catch a host
dependency creeping into `Snappy` or `IWAFraming`, which must stay portable for
#5." A C/C++ target has to survive all of them, and `canImport` cannot paper over
a **link** failure.

Vendoring google/snappy specifically would mean:

- **Hand-generating `config.h` and `snappy-stubs-public.h`.** Upstream generates
  these with CMake (~20 `HAVE_*` probes, SSSE3/BMI2/NEON checks). SwiftPM cannot
  run CMake, so we would hand-maintain a conservative variant correct on four
  platforms — the same class of chore as the keynote-parser proto/registry
  vendoring already in this repo.
- **Per-platform C++ stdlib linking with no portable spelling.**
  `.linkedLibrary("c++")` is right on Apple/libc++ but wrong on Ubuntu
  (libstdc++), and different again on Windows. `#if os(...)` in `Package.swift`
  is evaluated on the **host**, not the target, so cross-compiling to Android
  from macOS mis-selects.

Going through `snappy-c.h` would at least avoid `-cxx-interoperability-mode`
(which is viral across dependencies and breaks auto-generated test targets —
SwiftPM [#6990](https://github.com/swiftlang/swift-package-manager/issues/6990),
[#6564](https://github.com/swiftlang/swift-package-manager/issues/6564)). But the
build-system tax above is unavoidable, and it buys nothing a pure-Swift
implementation lacks.

A pure-Swift codec has **no platform surface at all** — the Ubuntu/Windows/Android
legs become free.

## 4. What was measured on the leading candidate

`codelynx/snappy-swift` was cloned, built on **Swift 6.4**
(`DEVELOPER_DIR=/Applications/Xcode-beta.app/…  xcrun swift build` — clean), and
driven against real data:

| Test | Result |
|---|---|
| Decompress all Apple `.iwa` chunks | **30/30 OK** |
| Re-compress → decompress round-trip | **30/30 OK** |
| Its ratio vs Apple's | 0.295 vs Apple 0.265 — competitive, ~11% larger |
| Malformed input (207 cases: empty, truncated, illegal offset 0, out-of-range offset, 5-byte varint overflow, random) | **207/207 threw cleanly — never trapped or crashed** |
| Round-trip fuzz (0…200,000 bytes; repetitive / structured / incompressible; incl. the 64 KiB boundary) | **ALL PASS** |

So the rejection is emphatically *not* on quality. It is a governance call:
2 stars, 14 contributions from one author, **one squashed commit**, no `.github/`
CI, no SPI listing, three months old, `swiftLanguageVersions: [.v5]`.

There is also a mundane blocker: its product is literally named **`Snappy`**,
which **collides with our own `Snappy` product**. Depending on it would force a
`moduleAliases` dance or renaming our product — extra coupling in exactly the
seam #5 wants kept clean.

## 5. Decision and rationale

**Vendor a pure-Swift block codec in `Sources/Snappy`.**

1. **Cost is genuinely small and bounded.** The format has been frozen since
   2011. Calibrating against `golang/snappy`'s portable paths: a correct
   decompressor is **~90–120 lines** (flat loop, 4-case switch, no tables, no
   allocation beyond the output buffer); a real hash-table compressor is
   **~125–180**. The *floor* is lower still and was verified here: an
   **all-literals encoder emits valid, universally-decodable Snappy blocks**
   (round-tripped across empty / 1-byte / 70 KB / random inputs). So #16 has a
   guaranteed-correct fallback, and LZ77 matching is pure ratio optimisation
   layered on top — the compressor need only be *Keynote-compatible, not optimal*.
2. **Portability becomes a non-issue.** No C target, no stdlib linking, no
   generated config headers; the Ubuntu/Windows/Android legs pass for free.
3. **Supply chain.** No 2-star single-commit dependency under the substrate of
   the whole package.
4. **Strict concurrency is ours to get right.** Value types over `[UInt8]` with
   static functions — no `Sendable` retrofit onto someone else's 5.7-era API,
   and no `.v5` language-mode pin to work around.
5. **It does not foreclose #5** — see below.

**Cost accepted knowingly:** we own ~200 lines of codec and its test vectors
forever, until #5 retires them. That is the deliberate trade.

## 6. How this interacts with #5

**#5 stays open and gets easier, not harder.** PLAN's hard seam does the work:
`IWAFraming` may call only `Snappy`'s public block API and must never reach into
codec internals. If that holds, swapping the vendored codec for a package is a
`Package.swift` edit plus a thin shim, not a refactor.

**Concrete guidance for #16 so #5 stays a one-file change** — shape the public
API to match what a future dependency would offer, which is also what both
google/snappy's C API and `codelynx/snappy-swift` converged on:

- `Snappy.compress` / `Snappy.decompress` over `[UInt8]` (or buffer pointers),
  **not** `Data` — keeps Foundation out of the seam.
- `Snappy.maxCompressedLength(_:)` and a peek at the varint preamble
  (`uncompressedLength`), both of which every real implementation exposes.
- Throwing errors, never traps, on malformed input.
- **No Apple framing types in `Snappy`** — no chunk headers, no 64 KiB splitting.
  That 4-byte header is `IWAFraming`'s job.

**Revisit #5 when** `codelynx/snappy-swift` (or a successor) picks up
independent adoption, CI, and a real commit history — or when a server-ecosystem
package (swift-nio / swift-server) ships a block-level Snappy, which today none
does. Re-run §4's fixture test against any candidate before switching; it is
cheap and it is the only test that matters.

## Reproducing the measurements

All numbers above come from decoding `research/fixtures/*.key` — unzip a
fixture, walk `Index/*.iwa` splitting on the 4-byte header (`0x00` + 3-byte LE
length), and decode each payload as a stock Snappy block. No vendored library is
required to confirm the framing claims in §1.
