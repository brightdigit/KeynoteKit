import Foundation
import Testing

/// #66's standing constraint: adding syntax highlighting must not put a
/// parser behind `import KeynoteKit`.
///
/// Authoring a deck should stay a swift-protobuf-only dependency, so
/// `KeynoteKitSyntax` is its own target and `swift-syntax` is wired only to
/// it. That is easy to violate by adding one line to `Package.swift`, and
/// nothing else would fail — hence this test.
@Suite("Core dependency isolation")
internal struct CoreDependencyTests {
  @Test("the KeynoteKit target declares no swift-syntax dependency")
  internal func coreHasNoSyntaxDependency() throws {
    let manifest = try packageManifest()
    let target = try #require(targetBlock(named: "KeynoteKit", in: manifest))
    #expect(!target.contains("SwiftSyntax"))
    #expect(!target.contains("SwiftParser"))
    #expect(!target.contains("swift-syntax"))
  }

  @Test("the KeynoteKitSyntax target does declare it")
  internal func syntaxTargetHasDependency() throws {
    let manifest = try packageManifest()
    let target = try #require(targetBlock(named: "KeynoteKitSyntax", in: manifest))
    #expect(target.contains("swift-syntax"))
  }

  /// The package manifest's source.
  ///
  /// Walks up from this file rather than using the working directory, which
  /// differs between `swift test` and an IDE run.
  private func packageManifest() throws -> String {
    var directory = URL(filePath: #filePath).deletingLastPathComponent()
    for _ in 0..<6 {
      let candidate = directory.appending(path: "Package.swift")
      if FileManager.default.fileExists(atPath: candidate.path) {
        return try String(contentsOf: candidate, encoding: .utf8)
      }
      directory = directory.deletingLastPathComponent()
    }
    throw CocoaError(.fileNoSuchFile)
  }

  /// The manifest text of the target named `name`, up to the next target.
  ///
  /// Scoped to the `targets:` section: the package itself is also named
  /// "KeynoteKit", so a naive search for `name: "KeynoteKit"` matches the
  /// package header and captures the top-level `dependencies:` block —
  /// which of course lists swift-syntax, and the assertion fails for the
  /// wrong reason.
  private func targetBlock(named name: String, in manifest: String) -> String? {
    guard let targetsRange = manifest.range(of: "\n  targets: [") else {
      return nil
    }
    let targets = manifest[targetsRange.upperBound...]
    guard let start = targets.range(of: "name: \"\(name)\"") else {
      return nil
    }
    let rest = targets[start.upperBound...]
    guard let end = rest.range(of: ".target(") ?? rest.range(of: ".testTarget(") else {
      return String(rest)
    }
    return String(rest[..<end.lowerBound])
  }
}
