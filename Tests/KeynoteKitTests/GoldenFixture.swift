import Foundation

/// One committed golden deck (`research/goldens/`) with its spec
/// (`research/examples/`).
internal struct GoldenFixture: Sendable, CustomStringConvertible {
  /// The five goldens (`research/findings/goldens.md`).
  internal static let all: [GoldenFixture] = [
    GoldenFixture(name: "bisect_in"),
    GoldenFixture(name: "bisect_out"),
    GoldenFixture(name: "bisect_action"),
    GoldenFixture(name: "bisect_direction"),
    GoldenFixture(name: "build_acceptance"),
  ]

  /// The repository root, resolved relative to this file.
  internal static let repositoryRoot = URL(filePath: String(#filePath))
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()

  /// The golden's stem, such as `bisect_in`.
  internal let name: String

  internal var description: String { name }

  /// The committed `.key` file.
  internal var keyURL: URL {
    Self.repositoryRoot.appending(path: "research/goldens/\(name).key")
  }

  /// The committed spec JSON.
  internal var specURL: URL {
    Self.repositoryRoot.appending(path: "research/examples/\(name).json")
  }

  /// Reads the golden's bytes.
  internal func loadKey() throws -> [UInt8] {
    Array(try Data(contentsOf: keyURL))
  }
}
