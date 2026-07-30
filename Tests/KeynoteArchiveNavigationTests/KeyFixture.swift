import Foundation

/// One committed `.key` fixture from `research/fixtures/`.
///
/// A small copy of `IWAFramingTests/KeyFixture.swift` — test targets cannot
/// share code, and ~60 duplicated lines beat a resource-bundle detour.
internal struct KeyFixture: Sendable, CustomStringConvertible {
  /// The fixture's file stem, such as `build_in_B`.
  internal let name: String

  internal var description: String { name }

  /// The fixture's location on disk.
  internal var url: URL {
    KeyFixtureCorpus.fixturesDirectory.appending(path: "\(name).key")
  }

  /// Reads the fixture's bytes from disk.
  internal func load() throws -> [UInt8] {
    Array(try Data(contentsOf: url))
  }
}
