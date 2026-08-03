import Foundation
import Testing

@testable import KeynoteKit

@Suite("KeynoteKit")
internal struct KeynoteKitTests {
  /// SHA-256 of `Sources/KeynoteKit/Resources/blank.key` as authored.
  ///
  /// Pinned so the test fails loudly if the resource rule ever transforms the
  /// document, or if the template is regenerated without deliberate intent.
  private static let templateDigest =
    "5e2b501e3af538b55e55cc95eb12bee8e4a2c2cf33dab87006a57602873ffe10"

  /// Byte length of the authored template.
  private static let templateByteCount = 98_240

  // MARK: - Helpers

  /// A unique, unused file URL in the system temporary directory.
  private static func temporaryURL() -> URL {
    FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("key")
  }

  /// Computes the lowercase hex SHA-256 digest of `data`.
  ///
  /// Implemented in plain Swift rather than CryptoKit so the test runs on the
  /// Linux, Windows, and Android CI legs.
  private static func digest(of data: Data) -> String {
    SHA256Digest.hexString(of: data)
  }

  // MARK: - Initialization Tests

  /// Asserts against a real public type rather than a version constant.
  /// The former `KeynoteKit` namespace enum held only a placeholder version
  /// and shadowed the module name, which made `KeynoteKit.Color`
  /// unresolvable for downstream targets importing both this module and
  /// SwiftUI.
  @Test("module is linkable")
  internal func moduleIsLinkable() {
    #expect(Color.white.opacity == 1)
  }

  // MARK: - Bundled Resource Tests

  @Test("bundled template resolves from Bundle.module")
  internal func bundledTemplateResolves() throws {
    let url = try KeynoteTemplate.bundled.url()
    #expect(url.isFileURL)
    #expect(url.lastPathComponent == "blank.key")
    #expect(FileManager.default.fileExists(atPath: url.path))
  }

  @Test("bundled template bytes are unmodified")
  internal func bundledTemplateBytesAreUnmodified() throws {
    let data = try KeynoteTemplate.bundled.data()
    #expect(data.count == Self.templateByteCount)
    #expect(Self.digest(of: data) == Self.templateDigest)
  }

  @Test("bundled template is a zip archive")
  internal func bundledTemplateIsZipArchive() throws {
    // A `.key` is a zip container. If a resource rule ever rewrote or
    // re-encoded the file, this local header signature is the first casualty.
    let data = try KeynoteTemplate.bundled.data()
    #expect(data.prefix(4) == Data([0x50, 0x4B, 0x03, 0x04]))
  }

  // MARK: - Write Tests

  @Test("write defaults to the bundled template")
  internal func writeDefaultsToBundledTemplate() throws {
    let destination = Self.temporaryURL()
    defer { try? FileManager.default.removeItem(at: destination) }

    try Deck().write(to: destination)

    let written = try Data(contentsOf: destination)
    #expect(Self.digest(of: written) == Self.templateDigest)
  }

  @Test("write accepts a caller-supplied base template")
  internal func writeAcceptsSuppliedTemplate() throws {
    let base = Self.temporaryURL()
    let destination = Self.temporaryURL()
    defer {
      try? FileManager.default.removeItem(at: base)
      try? FileManager.default.removeItem(at: destination)
    }

    let bytes = Data([0x50, 0x4B, 0x03, 0x04, 0xDE, 0xAD, 0xBE, 0xEF])
    try bytes.write(to: base)

    try Deck().write(to: destination, basedOn: KeynoteTemplate(contentsOf: base))

    #expect(try Data(contentsOf: destination) == bytes)
  }

  @Test("write replaces an existing file")
  internal func writeReplacesExistingFile() throws {
    let destination = Self.temporaryURL()
    defer { try? FileManager.default.removeItem(at: destination) }

    try Data([0x00]).write(to: destination)
    try Deck().write(to: destination)

    #expect(try Data(contentsOf: destination).count == Self.templateByteCount)
  }
}
