import Foundation
import IWAFraming
import Testing

@testable import KeynoteKit

/// `Presentation` (#88): the root of the content hierarchy. Conforming lets a
/// type skip the `Deck { … }` wrapper, which an author outside this module
/// cannot write around — flattening ``SlideContent`` is internal.
@Suite("Presentation")
internal struct PresentationTests {
  /// A minimal two-slide presentation.
  private struct TwoSlideTalk: Presentation {
    var body: some SlideContent {
      Slide {
        TextBox("first").frame(height: 100)
      }
      Slide {
        TextBox("second").frame(height: 100)
      }
    }
  }

  /// Content that itself composes two slides, for the flattening case.
  private struct Section: SlideContent {
    var body: some SlideContent {
      Slide {
        TextBox("a").frame(height: 100)
      }
      Slide {
        TextBox("b").frame(height: 100)
      }
    }
  }

  /// A presentation whose body is another composing type.
  private struct NestedTalk: Presentation {
    var body: some SlideContent {
      Section()
    }
  }

  /// A presentation with no slides at all.
  private struct EmptyTalk: Presentation {
    var body: some SlideContent {
      SlideGroup(slides: [])
    }
  }

  /// A presentation that declares builds, overriding the default count.
  private struct BuildingTalk: Presentation {
    var buildCount: Int { 2 }

    var body: some SlideContent {
      Slide {
        TextBox("in").frame(height: 100).build(.in) { Dissolve() }
        TextBox("out").frame(height: 100).build(.out) { Dissolve() }
      }
    }
  }

  /// The headline: composed content becomes a deck with no `Deck { }` in
  /// sight, and the slide order is the body's order.
  @Test("composed content resolves to a deck of the same slides")
  internal func composedContentResolvesToDeck() {
    #expect(TwoSlideTalk().deck.slides.count == 2)
  }

  /// Nesting must flatten: a presentation composing a type that itself
  /// composes two slides still yields two, not one group.
  @Test("nested content flattens into the deck")
  internal func nestedContentFlattens() {
    #expect(NestedTalk().deck.slides.count == 2)
  }

  /// A presentation with no slides is legal and writes the template
  /// verbatim, matching ``Deck``'s own empty-deck behavior.
  @Test("an empty presentation resolves to an empty deck")
  internal func emptyPresentationResolvesToEmptyDeck() {
    #expect(EmptyTalk().deck.slides.isEmpty)
  }

  /// Defaulted so the common case — a deck with no builds — says nothing.
  @Test("buildCount defaults to zero")
  internal func buildCountDefaultsToZero() {
    #expect(TwoSlideTalk().buildCount == 0)
  }

  /// ...and a conformer with builds overrides it, which is what a tool's
  /// structural self-check gates on.
  @Test("a conformer can override buildCount")
  internal func buildCountOverrideWins() {
    #expect(BuildingTalk().buildCount == 2)
  }

  /// `write(to:)` must be a true convenience, not a second implementation:
  /// the archive it produces has to match `deck.write(to:)` structurally.
  @Test("write(to:) matches writing the deck directly")
  internal func writeMatchesDeckWrite() throws {
    let presentation = TwoSlideTalk()
    let viaPresentation = try slideCount { try presentation.write(to: $0) }
    let viaDeck = try slideCount { try presentation.deck.write(to: $0) }
    #expect(viaPresentation == 2)
    #expect(viaPresentation == viaDeck)
  }

  /// An empty presentation writes the bundled template through, so the file
  /// is well-formed rather than a zero-slide error.
  @Test("an empty presentation writes the template verbatim")
  internal func emptyPresentationWritesTemplate() throws {
    let url = FileManager.default.temporaryDirectory
      .appending(path: "presentation-empty-\(UUID().uuidString).key")
    defer { try? FileManager.default.removeItem(at: url) }
    try EmptyTalk().write(to: url)
    let written = try Data(contentsOf: url)
    #expect(try written == KeynoteTemplate.bundled.data())
  }

  /// Writes via `write` to a temporary URL and reports the deck's slide count.
  private func slideCount(
    ofArchiveWrittenBy write: (URL) throws -> Void
  ) throws -> Int {
    let url = FileManager.default.temporaryDirectory
      .appending(path: "presentation-\(UUID().uuidString).key")
    defer { try? FileManager.default.removeItem(at: url) }
    try write(url)
    let bundle = try KeyBundle(contentsOfZip: Array(try Data(contentsOf: url)))
    let surgeon = try KeynoteArchiveSurgeon(bundle: bundle)
    return try SlideCatalog(members: surgeon.members).orderedSlides().count
  }
}
