import Foundation
import KeynoteArchiveNavigation

/// One committed `Expected/<fixture>.json` file: the ground-truth output of
/// Python `deckkit.extract_builds` for a fixture.
internal struct ExpectedBuilds: Decodable {
  private enum CodingKeys: String, CodingKey {
    case generator = "_generator"
    case fixture
    case builds
  }

  /// Provenance note written by `dump_expected_builds.py`.
  internal let generator: String

  /// The fixture file name the builds were extracted from.
  internal let fixture: String

  /// The expected builds, in Python's extraction order.
  internal let builds: [BuildRecord]

  /// Loads the expected builds for `fixture`.
  internal static func load(for fixture: KeyFixture) throws -> ExpectedBuilds {
    let url = KeyFixtureCorpus.expectedDirectory.appending(path: "\(fixture.name).json")
    return try JSONDecoder().decode(ExpectedBuilds.self, from: Data(contentsOf: url))
  }
}
