import Foundation
import IWAFraming
import Testing

/// The STORED-only zip layer against real Keynote documents and synthetic
/// malformed archives.
@Suite("KeyBundle")
internal struct KeyBundleTests {
  // MARK: - Real documents

  @Test("parses a fixture into ordered entries")
  internal func parsesFixture() throws {
    let bundle = try KeyBundle(contentsOfZip: KeyFixture(name: "build_in_B").load())
    #expect(bundle.entries.count > 20)
    #expect(bundle.entry(at: "Index/Document.iwa") != nil)
    #expect(bundle.entry(at: "Metadata/Properties.plist") != nil)
    #expect(bundle.entry(at: "preview.jpg") != nil)
    #expect(!bundle.indexEntryPaths.isEmpty)
    #expect(bundle.indexEntryPaths.allSatisfy { $0.hasPrefix("Index/") && $0.hasSuffix(".iwa") })
  }

  @Test("write then reparse preserves entries and order exactly")
  internal func writeReparseIdentity() throws {
    let bundle = try KeyBundle(contentsOfZip: KeyFixture(name: "builds_base").load())
    let reparsed = try KeyBundle(contentsOfZip: bundle.serializedZip())
    #expect(reparsed == bundle)
  }

  @Test("setBody replaces one entry and leaves the rest untouched")
  internal func setBodyReplacesInPlace() throws {
    var bundle = try KeyBundle(contentsOfZip: KeyFixture(name: "builds_base").load())
    let original = bundle.entries
    let path = try #require(bundle.indexEntryPaths.first)
    bundle.setBody([0x01, 0x02], at: path)
    #expect(bundle.entry(at: path)?.body == [0x01, 0x02])
    #expect(bundle.entries.map(\.path) == original.map(\.path))
    let untouched = zip(bundle.entries, original)
      .filter { $0.0.path != path }
      .allSatisfy { $0.0 == $0.1 }
    #expect(untouched)
  }

  // MARK: - Synthetic archives

  @Test("round-trips a synthetic bundle byte-for-byte")
  internal func roundTripsSyntheticBundle() throws {
    let bundle = KeyBundle(entries: [
      KeyBundleEntry(path: "Data/a.jpg", body: [0xFF, 0xD8, 0xFF]),
      KeyBundleEntry(path: "Index/Document.iwa", body: Array("payload".utf8)),
      KeyBundleEntry(path: "preview.jpg", body: []),
    ])
    let zipped = try bundle.serializedZip()
    #expect(try KeyBundle(contentsOfZip: zipped) == bundle)
    let rezipped = try KeyBundle(contentsOfZip: zipped).serializedZip()
    #expect(rezipped == zipped)
  }

  @Test("rejects bytes with no end-of-central-directory record")
  internal func rejectsNonZip() {
    #expect(throws: KeyBundleError.notAZipArchive) {
      _ = try KeyBundle(contentsOfZip: Array("not a zip archive".utf8))
    }
  }

  @Test("rejects a DEFLATED entry")
  internal func rejectsDeflatedEntry() throws {
    var zipped = try KeyBundle(entries: [KeyBundleEntry(path: "a", body: [0x61])])
      .serializedZip()
    // Patch the method field of the sole central directory record (offset 10
    // within the record) from STORED to DEFLATED.
    let directoryOffset = zipped.count - 22 - 46 - 1
    zipped[directoryOffset + 10] = 8
    #expect(throws: KeyBundleError.unsupportedCompressionMethod(8, path: "a")) {
      _ = try KeyBundle(contentsOfZip: zipped)
    }
  }

  @Test("rejects a corrupted body checksum")
  internal func rejectsCorruptedChecksum() throws {
    var zipped = try KeyBundle(entries: [KeyBundleEntry(path: "a", body: Array("abcd".utf8))])
      .serializedZip()
    // The body sits right after the 30-byte local header + 1-byte name.
    zipped[31] ^= 0xFF
    #expect(throws: KeyBundleError.checksumMismatch(path: "a")) {
      _ = try KeyBundle(contentsOfZip: zipped)
    }
  }

  @Test("rejects duplicate entry paths on write")
  internal func rejectsDuplicatePaths() {
    let bundle = KeyBundle(entries: [
      KeyBundleEntry(path: "a", body: []),
      KeyBundleEntry(path: "a", body: []),
    ])
    #expect(throws: KeyBundleError.duplicateEntryPath("a")) {
      _ = try bundle.serializedZip()
    }
  }
}
