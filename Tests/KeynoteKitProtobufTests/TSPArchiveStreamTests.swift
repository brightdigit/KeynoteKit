import KeynoteKitProtobuf
import Testing

/// The `ArchiveInfo`-delimited stream layer over synthetic streams.
///
/// Real Keynote streams are exercised end to end by the 24-fixture semantic
/// round-trip gate in `IWAFramingTests`; these tests pin the delimiting
/// rules and failure modes in isolation.
@Suite("TSPArchiveStream")
internal struct TSPArchiveStreamTests {
  // MARK: - Round-trips

  @Test("parses an empty stream as no records")
  internal func parsesEmptyStream() throws {
    #expect(try TSPArchiveStream.default.records(from: []).isEmpty)
  }

  @Test("round-trips a single-record stream")
  internal func roundTripsSingleRecord() throws {
    let record = try makeRecord(identifier: 7, payloads: [Array("payload".utf8)])
    let stream = try TSPArchiveStream.default.serialize([record])
    let parsed = try TSPArchiveStream.default.records(from: stream)
    #expect(parsed == [record])
    #expect(try TSPArchiveStream.default.serialize(parsed) == stream)
  }

  @Test("round-trips multiple records in stream order")
  internal func roundTripsMultipleRecords() throws {
    let records = [
      try makeRecord(identifier: 1, payloads: [Array("first".utf8)]),
      try makeRecord(identifier: 2, payloads: [Array("second".utf8), Array("third".utf8)]),
    ]
    let stream = try TSPArchiveStream.default.serialize(records)
    #expect(try TSPArchiveStream.default.records(from: stream) == records)
  }

  @Test("slices multi-message payloads by each MessageInfo length")
  internal func slicesMultiMessagePayloads() throws {
    let first = Array(repeating: UInt8(0xAA), count: 3)
    let second = Array(repeating: UInt8(0xBB), count: 5)
    let record = try makeRecord(identifier: 9, payloads: [first, second])
    let parsed = try TSPArchiveStream.default.records(
      from: try TSPArchiveStream.default.serialize([record])
    )
    #expect(parsed.count == 1)
    #expect(parsed[0].payloads == [first, second])
  }

  @Test("serialize recomputes a stale MessageInfo length")
  internal func recomputesStaleLength() throws {
    var record = try makeRecord(identifier: 3, payloads: [Array("abc".utf8)])
    record.payloads[0] = Array("longer payload".utf8)
    let parsed = try TSPArchiveStream.default.records(
      from: try TSPArchiveStream.default.serialize([record])
    )
    #expect(parsed[0].payloads[0] == Array("longer payload".utf8))
    #expect(parsed[0].info.messageInfos[0].length == 14)
  }

  // MARK: - Registry decoding

  @Test("decodedMessages resolves payloads through the registry")
  internal func decodesThroughRegistry() throws {
    var metadata = TSP_PackageMetadata()
    metadata.lastObjectIdentifier = 42
    let payload: [UInt8] = try metadata.serializedBytes(partial: true)
    // 11006 is TSP.PackageMetadata in the Keynote 14.4 registry.
    let record = try makeRecord(identifier: 2, payloads: [payload], type: 11_006)
    let decoded = try record.decodedMessages()
    #expect((decoded.first as? TSP_PackageMetadata)?.lastObjectIdentifier == 42)
  }

  // MARK: - Malformed streams

  @Test("rejects a stream ending inside the length varint")
  internal func rejectsTruncatedVarint() {
    #expect(throws: TSPArchiveStreamError.truncatedVarint(offset: 0)) {
      _ = try TSPArchiveStream.default.records(from: [0x80])
    }
  }

  @Test("rejects a header length running past the stream")
  internal func rejectsTruncatedArchiveInfo() {
    #expect(throws: TSPArchiveStreamError.truncatedArchiveInfo(offset: 0, expected: 5)) {
      _ = try TSPArchiveStream.default.records(from: [0x05, 0x08])
    }
  }

  @Test("rejects a payload running past the stream")
  internal func rejectsTruncatedPayload() throws {
    let record = try makeRecord(identifier: 6, payloads: [Array("payload".utf8)])
    var stream = try TSPArchiveStream.default.serialize([record])
    stream.removeLast(3)
    #expect(
      throws: TSPArchiveStreamError.truncatedPayload(
        archiveIdentifier: 6,
        expected: 7,
        available: 4
      )
    ) {
      _ = try TSPArchiveStream.default.records(from: stream)
    }
  }

  // MARK: - Helpers

  /// Builds a record whose header declares one `MessageInfo` per payload.
  private func makeRecord(
    identifier: UInt64,
    payloads: [[UInt8]],
    type: UInt32 = 1
  ) throws -> TSPArchiveRecord {
    var info = TSP_ArchiveInfo()
    info.identifier = identifier
    info.messageInfos = payloads.map { payload in
      var messageInfo = TSP_MessageInfo()
      messageInfo.type = type
      messageInfo.length = UInt32(payload.count)
      return messageInfo
    }
    return TSPArchiveRecord(info: info, payloads: payloads)
  }
}
