import Foundation
import IWAFraming
import KeynoteKit
import KeynoteKitProtobuf
import Testing

/// The #20 differential gate: strip the Python surgery out of each golden,
/// re-author it with the Swift surgeon from the same committed spec, and
/// require the resulting archive graph to match the golden with only the
/// build uuid and `randomNumberSeed` normalized. Because both writers mint
/// ids from the same high-water scan, even the minted identifiers match.
@Suite("Golden differential")
internal struct GoldenDifferentialTests {
  @Test("Swift surgery reproduces the golden archive graph", arguments: GoldenFixture.all)
  internal func reproducesGoldenGraph(golden: GoldenFixture) throws {
    let goldenBundle = try KeyBundle(contentsOfZip: golden.loadKey())
    let deck = try DeckSpec.load(golden.specURL)

    var authored = try GoldenSurgeryStripper.stripped(goldenBundle)
    var surgeon = try KeynoteArchiveSurgeon(bundle: authored)
    var generator = SystemRandomNumberGenerator()
    try surgeon.author(deck, into: &authored, using: &generator)

    let difference = try ArchiveGraphComparer.firstDifference(
      between: authored,
      and: goldenBundle
    )
    #expect(difference == nil, "\(golden): \(difference ?? "")")
  }

  @Test("uuid-map invariants hold on every authored golden", arguments: GoldenFixture.all)
  internal func invariantsHold(golden: GoldenFixture) throws {
    let goldenBundle = try KeyBundle(contentsOfZip: golden.loadKey())
    let deck = try DeckSpec.load(golden.specURL)
    var authored = try GoldenSurgeryStripper.stripped(goldenBundle)
    var surgeon = try KeynoteArchiveSurgeon(bundle: authored)
    var generator = SystemRandomNumberGenerator()
    try surgeon.author(deck, into: &authored, using: &generator)

    let reparsed = try KeynoteArchiveSurgeon(bundle: authored)
    try UUIDMapVerifier.verify(
      members: reparsed.members,
      expectedBuildCount: deck.slides.reduce(0) { $0 + $1.builds.count }
    )
  }
}
