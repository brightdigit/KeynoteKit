# Snappy dependency survey (#5): keep the vendored codec, for now

**TL;DR (recommendation, PROPOSED):** option (c) — **stay vendored**. One
year-2026 re-survey of the ecosystem finds the same shape as the
[#15 survey](snappy_survey.md): block-level APIs are common, but no package
clears the trust bar, and two candidates that appeared since #15 are
decompress-only with `internal` or unimplemented compress paths. Option (b)
(extract `Sources/Snappy` into its own BrightDigit package) is viable but buys
nothing today; option (a) has no qualifying candidate. #5 stays open with the
exit conditions in §6.

Survey date: 2026-07-30 (issue #5's first concrete task; same rigor as
[`zip_survey.md`](zip_survey.md) per the #15/#17 precedent). This survey
post-dates the vendored codec landing (#16, commit `b8c37c6`) — the question
here is no longer "what should #16 build" but "should the shipped codec now be
replaced by a dependency".

## 1. What a qualifying dependency must provide

The seam is already cut. `Sources/Snappy` (755 lines, 8 files) exposes exactly
the block layer — `Snappy.default.compress(_:)`, `decompress(_:)`,
`uncompressedLength(of:)`, `Snappy.maximumCompressedLength(for:)` over
`[UInt8]` — and `IWAFraming` owns Apple's non-standard 4-byte chunk header
(no `sNaPpY` stream id, no CRC-32C; established in
[`snappy_survey.md`](snappy_survey.md) §1). A replacement must therefore:

1. **Expose raw block compress *and* decompress publicly** — stream-framing
   APIs are useless (a framed decoder rejects `.iwa` payloads at byte 0).
2. **Build on every CI leg**: macOS + iOS/tvOS/watchOS/visionOS/Catalyst
   (xcodebuild, `macos-full.json`), Ubuntu **including wasm and
   wasm-embedded**, Windows 2022/2025, Android API 28/34 cross-compile. The
   wasm-embedded leg (added since #15) makes any C/C++ target strictly harder
   than it was at the last survey.
3. **Be trustworthy under the whole stack** — `KeynoteKit → IWAFraming →
   Snappy`; a codec bug corrupts every authored document.
4. Compatible license (BSD-3/Apache-2/MIT) and Swift 6 concurrency posture
   (our module is `Sendable`-clean under strict concurrency, Swift 6.4).

## 2. Candidates

GitHub `snappy language:Swift` returns 48 repos (2026-07-30); all but the rows
below are Snapchat clones, window managers, SnapKit forks, or snapshot-testing
libraries. Swift Package Index still lists **only** `lovetodream/swift-snappy`.
Confirmed still absent: `apple/swift-nio-extras`, `adam-fowler/compress-nio`,
`tsolomko/SWCompression`; `flexlixrup/pulsar-client-swift`'s Snappy is inside
the wrapped C++ Pulsar client, not a Swift codec.

| Package | License | Pure Swift? | Block compress / decompress public? | Platforms | Maintenance (as of 2026-07-30) | Verdict |
|---|---|---|---|---|---|---|
| [codelynx/snappy-swift](https://github.com/codelynx/snappy-swift) v1.0.1 | BSD-3 | **Yes**, zero deps | **Yes / Yes** (`Snappy.compress/decompress` over buffer pointers, + `Data` sugar) | Apple minimums declared (macOS 12/iOS 15/watchOS 8/tvOS 15); no CI anywhere, Linux/Windows/wasm unproven | **All 14 commits authored on one day (2025-11-03), silent since**; 2★; 1 known dependent (author's own parquet-swift); tools 5.9, `swiftLanguageVersions: [.v5]` | Still the only technical qualifier; still a **supply-chain reject** |
| [lovetodream/swift-snappy](https://github.com/lovetodream/swift-snappy) 1.0.0 | NOASSERTION (vendors BSD-3 `snappy-c`) | No — ~1.6k lines vendored C + swift-system | Yes / Yes (`Data` extensions) | Claims Linux; C target vs wasm-embedded/Android unproven | **Dead since 2022-12-07**; 1★; tools 5.7 | Reject — dead, C linkage, product named `Snappy` (collides with ours) |
| [edgeengineer/snappy](https://github.com/edgeengineer/snappy) 0.0.1 | NOASSERTION | No (fork of above) | Same | Adds visionOS; CI = ubuntu+macos, Swift 6.1 | Fork; 2025-06 commits are chores only, no algorithm work since the 2022 upstream; 0★ | Reject — same C core, no adoption |
| [awxkee/snappy.swift](https://github.com/awxkee/snappy.swift) | CC0 wrapper | No — **prebuilt `.xcframework`** | n/a | **Apple-only by construction** | 4★, dead since 2023-08 | Disqualified — fails every non-Darwin leg |
| [RandomHashTags/swift-compression](https://github.com/RandomHashTags/swift-compression) | Apache-2.0 | Yes | **No / Yes** — `compress` throws `CompressionError.unsupportedOperation`; real impl is commented out "TODO: finish" | — | Last push 2026-04-13; 3★ | Reject — half a codec. Curiosity: ships a `CompressionTechnique.IWA` type whose compress/decompress bodies are **empty stubs** |
| [willtemperley/swift-compression](https://github.com/willtemperley/swift-compression) *(new since #15)* | Apache-2.0 headers, **no LICENSE file** | Yes (+ swift-binary-parsing `exact: 0.0.2`) | **No / No** — `enum Snappy` is `internal`, decompress-only | Apple `.v26` minimums | Self-described experimental; 5 commits, 1★, last push 2026-04-04; benchmarks against lovetodream's C snappy | Reject — nothing public to depend on |
| [google/snappy](https://github.com/google/snappy) v1.2.2 (vendor C++) | BSD-3 | No | Yes (`snappy-c.h`) | CMake-generated `config.h`; per-platform C++ stdlib linking | Reference impl, release 2025-03-26 | Reject — #15 §3's build-system tax now also has to clear **wasm-embedded** |

**Corrections to the #15 survey record** (both minor, neither changes the
outcome): `codelynx/snappy-swift` has 14 commits (one day's burst), not "a
single squashed commit", and its product/module is **`SnappySwift`** — there is
no product-name collision with our `Snappy`; the collision claim in
`snappy_survey.md` §4 applies to lovetodream/edgeengineer (product `Snappy`),
not to codelynx.

## 3. What changed since the #15 survey (2026-07-29 → now)

Almost nothing, which is itself the finding:

- **No candidate gained commits, stars, CI, or adoption.** codelynx is 9
  months silent; the two "active" pure-Swift libraries still cannot compress.
- **One genuinely new repo** (`willtemperley/swift-compression`) appeared —
  experimental, internal-only, decompress-only.
- **Our side changed**: the vendored codec shipped (#16) with the corpus gate
  green, and CI grew wasm/wasm-embedded legs that raise the bar for any
  C/C++-backed dependency beyond what #15 already rejected.

## 4. Option (b): extract `Sources/Snappy` into its own package

Assessed, deferred. The mechanics are easy — the module already has zero
dependencies, no Foundation import in its API, and a clean seam — but today an
extraction would add a second repo to version, tag, and CI-matrix (the full
five-Apple-platforms + Ubuntu/wasm/Windows/Android matrix is the expensive
part) while serving exactly one consumer. It removes none of #5's stated
costs: we would still own the codec, its fuzzing, and its BSD-3-adjacent
accounting — just at arm's length. Extraction becomes worth it the moment a
**second consumer** exists (a BrightDigit or community project wanting a
pure-Swift block Snappy — nothing on SPI offers one today, so there is a
genuine niche).

## 5. Recommendation (PROPOSED, pending Leo's review)

**(c) stay vendored for now.** Ranked against the alternatives:

1. **(a) depend on an existing package** — no qualifying candidate. The only
   technical fit (codelynx) is unchanged since its one-day commit history and
   has zero independent adoption, no CI, and no Linux/Windows/wasm evidence.
   Every other package fails on capability, not just governance.
2. **(b) extract our codec** — sound future move, wrong moment; see §4.
3. **(c) status quo** — 755 audited lines, corpus-gated
   (30/30 `.iwa` chunks + fixture round-trip), zero platform surface, and the
   public API already has the exact shape any future dependency would offer,
   so the eventual swap stays a `Package.swift` edit plus a thin shim.

## 6. Exit conditions (when to reopen the swap)

Re-run this survey — and switch to **(a)** — when a block-level package shows
**independent adoption plus real CI** (at minimum Linux; ideally Windows/wasm)
**plus a commit history that spans more than one day**. codelynx/snappy-swift
remains the standing candidate if it wakes up. Before any switch, re-run the
#15 fixture gate against the candidate: decompress all corpus `.iwa` chunks,
round-trip them, and fuzz malformed inputs — it is cheap and it is the only
test that matters. Switch to **(b)** the moment a second consumer for the
codec exists. Tripwire either way: the swap must not move Apple's 4-byte chunk
framing out of `IWAFraming` — a dependency provides blocks, nothing more.
