import Foundation
import IWAFraming
import Testing

/// The #17 byte-comparison *experiment* — a diagnostic, never a gate.
///
/// The semantic gate is `SemanticRoundTripTests`; Keynote requires a file be
/// accepted, not byte-equal. This suite exists to measure and record how
/// close a repack comes to Apple's bytes at each level (results in
/// `research/findings/iwa_byte_identity.md`). It prints a table and asserts
/// nothing about identity, so encoder drift can never break CI. Run with:
///
/// ```
/// IWA_BYTE_DIAGNOSTIC=1 swift test --filter ByteIdentityDiagnostic
/// ```
@Suite("Byte-identity diagnostic")
internal struct ByteIdentityDiagnosticTests {
  @Test(
    "reports container, entry, and chunk byte identity per fixture",
    .enabled(if: ProcessInfo.processInfo.environment["IWA_BYTE_DIAGNOSTIC"] != nil)
  )
  internal func reportsByteIdentity() throws {
    var lines = ["fixture | container | iwa entries identical | apple bytes | ours | ratio"]
    var identicalEntries = 0
    var totalEntries = 0
    for fixture in KeyFixtureCorpus.all {
      let original = try fixture.load()
      let bundle = try KeyBundle(contentsOfZip: original)
      var sameEntries = 0
      var appleByteCount = 0
      var ourByteCount = 0
      var repacked = bundle
      for path in bundle.indexEntryPaths {
        guard let entry = bundle.entry(at: path) else { continue }
        let reframed = IWAChunkCodec.default.encode(try IWAChunkCodec.default.decode(entry.body))
        if reframed == entry.body { sameEntries += 1 }
        appleByteCount += entry.body.count
        ourByteCount += reframed.count
        repacked.setBody(reframed, at: path)
      }
      let container = try repacked.serializedZip() == original ? "identical" : "differs"
      let ratio = Double(ourByteCount) / Double(appleByteCount)
      identicalEntries += sameEntries
      totalEntries += bundle.indexEntryPaths.count
      lines.append(
        "\(fixture.name) | \(container) | \(sameEntries)/\(bundle.indexEntryPaths.count)"
          + " | \(appleByteCount) | \(ourByteCount) | \(String(format: "%.4f", ratio))"
      )
    }
    lines.append("TOTAL identical .iwa entries: \(identicalEntries)/\(totalEntries)")
    print(lines.joined(separator: "\n"))
  }
}
