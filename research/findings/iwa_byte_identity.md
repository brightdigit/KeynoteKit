# Byte-identity experiment: repack vs Apple's bytes (#17, diagnostic)

**Result: byte-identity does not hold, at any level above the decompressed
stream. It stays a diagnostic; it is not promoted to a regression check.**

Run 2026-07-29 on the 24-fixture corpus:

```
IWA_BYTE_DIAGNOSTIC=1 DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
  xcrun swift test --filter ByteIdentityDiagnostic
```

## Measured

| Level | Identical after unpack → repack |
|---|---|
| Decompressed archive streams | **24/24 fixtures, byte-for-byte** (gated in `SemanticRoundTripTests` §3) |
| Framed `.iwa` entries | **24/602** — only the trivial single-chunk `AnnotationAuthorStorage.iwa`-class entries |
| Zip containers | **0/24** |
| Compressed size, ours vs Apple | **~1.033×** per fixture (min 1.0325, max 1.0332) |

## Why, and why that is fine

- The Snappy format gives encoders real freedom (match length, candidate
  offset, when to stop searching); our vendored encoder makes different —
  legal — choices than Apple's closed-source one, so compressed chunk bytes
  differ while decompressing identically. This confirms the #16 measurement
  (ours ~0.2734 aggregate ratio vs Apple's ~0.2647).
- Containers additionally differ because Keynote writes LH-only zip64 extras
  on six metadata/preview entries and a bimodal version-made-by
  (`zip_survey.md` §1); our writer emits uniform minimal headers.
- The property Keynote actually requires is acceptance, and the property the
  gate enforces is a byte-identical *decompressed* stream — the strongest
  check that survives encoder freedom (standing directive, 2026-07-28:
  verification gates are structural, not byte-identical).

If a future encoder change ever reaches full framed-entry identity, flip
`ByteIdentityDiagnosticTests` into an always-on regression check and update
this file; until then any "identical" count above 24/602 is a bonus, not a
contract.
