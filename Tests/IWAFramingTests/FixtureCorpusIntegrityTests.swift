import Foundation
import Testing

/// Guards the static fixture list against drift from the on-disk corpus.
@Suite("Fixture corpus integrity")
internal struct FixtureCorpusIntegrityTests {
  @Test("static fixture list matches the .key files on disk")
  internal func staticListMatchesDisk() throws {
    let onDisk = try FileManager.default
      .contentsOfDirectory(atPath: KeyFixtureCorpus.fixturesDirectory.path())
      .filter { $0.hasSuffix(".key") }
      .map { String($0.dropLast(4)) }
    #expect(Set(onDisk) == Set(KeyFixtureCorpus.all.map(\.name)))
    #expect(KeyFixtureCorpus.all.count == 24)
  }
}
