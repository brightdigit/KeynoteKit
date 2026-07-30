import AcceptanceDeckCatalog
import Foundation
import IWAFraming
import KeynoteKitProtobuf
import Testing

@testable import KeynoteKit

/// The #24 AFK gate: each acceptance deck expressed in the public DSL lowers
/// to exactly its committed spec, reproduces its golden's archive graph, and
/// writes a structurally valid deck from the bundled template. What remains
/// of #24 after this suite is only the human Keynote 15.3 open pass.
@Suite("Acceptance decks")
internal struct AcceptanceDeckTests {
  @Test("the DSL lowers to the committed spec", arguments: AcceptanceDeck.all)
  internal func lowersToSpec(acceptance: AcceptanceDeck) throws {
    let fixture = try golden(for: acceptance)
    let spec = try DeckSpec.load(fixture.specURL)
    #expect(surgeryModel(of: acceptance) == spec)
  }

  @Test("the DSL reproduces the golden archive graph", arguments: AcceptanceDeck.all)
  internal func reproducesGoldenGraph(acceptance: AcceptanceDeck) throws {
    let fixture = try golden(for: acceptance)
    let goldenBundle = try KeyBundle(contentsOfZip: fixture.loadKey())
    var authored = try GoldenSurgeryStripper.stripped(goldenBundle)
    var surgeon = try KeynoteArchiveSurgeon(bundle: authored)
    var generator = SystemRandomNumberGenerator()
    try surgeon.author(surgeryModel(of: acceptance), into: &authored, using: &generator)

    let difference = try ArchiveGraphComparer.firstDifference(
      between: authored,
      and: goldenBundle
    )
    #expect(difference == nil, "\(acceptance): \(difference ?? "")")
  }

  @Test("the full write path emits a structurally valid deck", arguments: AcceptanceDeck.all)
  internal func writesValidDeck(acceptance: AcceptanceDeck) throws {
    let url = FileManager.default.temporaryDirectory
      .appending(path: "acceptance-\(acceptance.name)-\(UUID().uuidString).key")
    defer { try? FileManager.default.removeItem(at: url) }
    try acceptance.deck.write(to: url)

    let bundle = try KeyBundle(contentsOfZip: Array(try Data(contentsOf: url)))
    let surgeon = try KeynoteArchiveSurgeon(bundle: bundle)
    for member in surgeon.members {
      for record in member.records {
        _ = try record.decodedMessages()
      }
    }
    try UUIDMapVerifier.verify(members: surgeon.members, expectedBuildCount: acceptance.buildCount)
    let slides = try SlideCatalog(members: surgeon.members).orderedSlides()
    #expect(slides.count == acceptance.deck.slides.count)
  }

  /// The catalog's golden fixture, matched by spec stem.
  private func golden(for acceptance: AcceptanceDeck) throws -> GoldenFixture {
    try #require(GoldenFixture.all.first { $0.name == acceptance.name })
  }

  /// The catalog deck lowered to the surgeon's model with items and
  /// transition cleared — the shape ``DeckSpec`` loads, so the two compare
  /// directly and the golden-differential path (which authors into a
  /// stripped golden that already carries its items and base transition)
  /// applies unchanged.
  private func surgeryModel(of acceptance: AcceptanceDeck) -> AuthoredDeck {
    AuthoredDeck(
      slides: acceptance.deck.authoredDeck().slides.map { slide in
        AuthoredSlide(
          itemCount: slide.itemCount,
          transitionDirection: slide.transitionDirection,
          builds: slide.builds
        )
      }
    )
  }
}
