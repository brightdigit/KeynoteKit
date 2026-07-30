import IWAFraming
import KeynoteKitProtobuf
import Testing

/// The #17 gate: for every committed fixture, unpack → repack → unpack must
/// preserve the archive graph exactly.
///
/// The comparison is full identity, not the volatile-field canonicalization
/// `research/tools/normalize.py` applies — that exists for comparing two
/// *independently authored* decks. A pure round-trip regenerates nothing, so
/// every identifier, uuid, and seed must survive verbatim; a difference in a
/// "volatile" field here is a framing bug to fix, never churn to normalize
/// away.
@Suite("Semantic .key round-trip")
internal struct SemanticRoundTripTests {
  @Test("unpack → repack → unpack preserves the archive graph", arguments: KeyFixtureCorpus.all)
  internal func roundTripsArchiveGraph(fixture: KeyFixture) throws {
    let original = try KeyBundle(contentsOfZip: fixture.load())
    let repacked = try KeyBundle(contentsOfZip: repack(original))

    #expect(repacked.entries.map(\.path) == original.entries.map(\.path))
    for (entry, repackedEntry) in zip(original.entries, repacked.entries) {
      if entry.path.hasSuffix(".iwa") {
        try expectSameArchiveGraph(entry, repackedEntry, fixture: fixture)
      } else {
        #expect(repackedEntry.body == entry.body, "\(fixture): \(entry.path) body changed")
      }
    }
  }

  /// Repacks a bundle by decoding and re-encoding every `.iwa` member.
  private func repack(_ bundle: KeyBundle) throws -> [UInt8] {
    var repacked = bundle
    for path in bundle.indexEntryPaths {
      guard let entry = bundle.entry(at: path) else { continue }
      let stream = try IWAChunkCodec.default.decode(entry.body)
      repacked.setBody(IWAChunkCodec.default.encode(stream), at: path)
    }
    return try repacked.serializedZip()
  }

  /// Asserts two `.iwa` members carry an identical archive graph, and that
  /// every payload still decodes through the registry (the "+ protobuf" rung
  /// of the acceptance stack).
  private func expectSameArchiveGraph(
    _ original: KeyBundleEntry,
    _ repacked: KeyBundleEntry,
    fixture: KeyFixture
  ) throws {
    let originalStream = try IWAChunkCodec.default.decode(original.body)
    let repackedStream = try IWAChunkCodec.default.decode(repacked.body)
    #expect(
      repackedStream == originalStream,
      "\(fixture): \(original.path) decompressed stream changed"
    )
    let records = try TSPArchiveStream.default.records(from: originalStream)
    let repackedRecords = try TSPArchiveStream.default.records(from: repackedStream)
    #expect(repackedRecords == records, "\(fixture): \(original.path) archive graph changed")
    for record in records {
      _ = try record.decodedMessages()
    }
  }
}
