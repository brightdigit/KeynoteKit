import Foundation
import IWAFraming
import KeynoteKit
import KeynoteKitProtobuf
import Testing

/// The #22 gates: author more slides — and more text items per slide — than
/// the bundled template contains; every minted id must satisfy the uuid-map
/// and `lastObjectIdentifier` invariants.
@Suite("Template supply")
internal struct SupplyTests {
  @Test("authors more slides than the template contains")
  internal func oversizedSlideCount() throws {
    let build = AuthoredBuild(kind: .buildIn, effect: "apple:dissolve character", targetIndex: 0)
    let deck = AuthoredDeck(
      slides: (0..<3).map { _ in AuthoredSlide(itemCount: 1, builds: [build]) }
    )
    let authored = try authorOntoBlankTemplate(deck)

    let surgeon = try KeynoteArchiveSurgeon(bundle: authored)
    let slides = try SlideCatalog(members: surgeon.members).orderedSlides()
    #expect(slides.count == 3)
    #expect(Set(slides.map(\.slideIdentifier)).count == 3)
    try UUIDMapVerifier.verify(members: surgeon.members, expectedBuildCount: 3)
  }

  @Test("authors more text items per slide than the template contains")
  internal func oversizedTextItemCount() throws {
    let builds = (0..<4).map { index in
      AuthoredBuild(kind: .buildIn, effect: "apple:dissolve character", targetIndex: index)
    }
    let deck = AuthoredDeck(slides: [AuthoredSlide(itemCount: 4, builds: builds)])
    let authored = try authorOntoBlankTemplate(deck)

    let surgeon = try KeynoteArchiveSurgeon(bundle: authored)
    let slides = try SlideCatalog(members: surgeon.members).orderedSlides()
    let slide = try #require(slides.first)
    let archive = try KN_SlideArchive(
      serializedBytes: surgeon.members[slide.memberIndex].records[slide.recordIndex].payloads[0],
      partial: true
    )
    #expect(archive.drawablesZOrder.count == 4)
    #expect(Set(archive.drawablesZOrder.map(\.identifier)).count == 4)
    let catalog = SlideCatalog(members: surgeon.members)
    for drawable in archive.drawablesZOrder {
      #expect(catalog.locate(recordIdentifier: drawable.identifier) != nil)
    }
    try UUIDMapVerifier.verify(members: surgeon.members, expectedBuildCount: 4)
  }

  @Test("round-trips an oversized deck through the container stack")
  internal func oversizedDeckRoundTrips() throws {
    let build = AuthoredBuild(kind: .buildOut, effect: "apple:dissolve character", targetIndex: 1)
    let deck = AuthoredDeck(
      slides: (0..<2).map { _ in AuthoredSlide(itemCount: 2, builds: [build]) }
    )
    let authored = try authorOntoBlankTemplate(deck)
    let reparsed = try KeyBundle(contentsOfZip: authored.serializedZip())
    for path in reparsed.indexEntryPaths {
      let entry = try #require(reparsed.entry(at: path))
      let records = try TSPArchiveStream.default.records(
        from: IWAChunkCodec.default.decode(entry.body)
      )
      for record in records {
        _ = try record.decodedMessages()
      }
    }
  }

  /// Authors `deck` onto the bundled blank template.
  private func authorOntoBlankTemplate(_ deck: AuthoredDeck) throws -> KeyBundle {
    var bundle = try KeyBundle(contentsOfZip: Array(KeynoteTemplate.bundled.data()))
    var surgeon = try KeynoteArchiveSurgeon(bundle: bundle)
    var generator = SystemRandomNumberGenerator()
    try surgeon.author(deck, into: &bundle, using: &generator)
    return bundle
  }
}
