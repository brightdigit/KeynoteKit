import Foundation
import IWAFraming
import KeynoteArchiveNavigation
import Testing

/// The #18 gate: Swift navigation reproduces Python `deckkit.extract_builds`
/// on every fixture, compared at archive level against the committed
/// `Expected/*.json` (regenerate with `research/tools/dump_expected_builds.py`).
@Suite("extract_builds parity")
internal struct ExtractBuildsParityTests {
  @Test("matches deckkit.extract_builds", arguments: KeyFixtureCorpus.all)
  internal func matchesPythonExtractBuilds(fixture: KeyFixture) throws {
    let expected = try ExpectedBuilds.load(for: fixture)
    #expect(!expected.generator.isEmpty)
    #expect(expected.fixture == "\(fixture.name).key")
    let bundle = try KeyBundle(contentsOfZip: fixture.load())
    let builds = try BuildExtractor.builds(in: KeyArchiveIndex(bundle: bundle))

    #expect(builds.count == expected.builds.count, "\(fixture): build count")
    for (offset, pair) in zip(builds, expected.builds).enumerated() {
      #expect(
        pair.0 == pair.1,
        "\(fixture): build[\(offset)] differs\n  Swift: \(pair.0)\n  Python: \(pair.1)")
    }
  }
}
