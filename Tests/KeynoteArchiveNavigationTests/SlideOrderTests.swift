import Foundation
import IWAFraming
import KeynoteArchiveNavigation
import KeynoteKitProtobuf
import Testing

/// The presentation-order walk that #20's writer will consume.
@Suite("Slide order")
internal struct SlideOrderTests {
  @Test("slide tree resolves to the slide members", arguments: KeyFixtureCorpus.all)
  internal func slideTreeResolvesSlideMembers(fixture: KeyFixture) throws {
    let bundle = try KeyBundle(contentsOfZip: fixture.load())
    let index = try KeyArchiveIndex(bundle: bundle)
    let ordered = try SlideOrder.slideEntryPaths(in: index)
    let slideMembers = BuildExtractor.slideEntryPaths(in: index)

    #expect(!ordered.isEmpty, "\(fixture): no slides resolved")
    #expect(Set(ordered) == Set(slideMembers), "\(fixture): tree and members disagree")
    #expect(ordered.count == slideMembers.count, "\(fixture): slide count")
  }

  @Test("returns slides in tree order, not member order")
  internal func returnsTreeOrder() throws {
    // Tree order [200, 100] is the reverse of lexicographic member order,
    // so a walk that sorted by path (or returned a set) fails here.
    let index = try SyntheticDeck.index(
      treeNodeIdentifiers: [20, 10],
      nodes: [10: 100, 20: 200],
      slideIdentifiers: [100, 200]
    )
    let ordered = try SlideOrder.slideEntryPaths(in: index)
    #expect(ordered == ["Index/Slide-200.iwa", "Index/Slide-100.iwa"])
  }

  @Test("throws when a tree slide has no record")
  internal func throwsOnMissingSlide() throws {
    let index = try SyntheticDeck.index(
      treeNodeIdentifiers: [10, 30],
      nodes: [10: 100, 30: 300],
      slideIdentifiers: [100]
    )
    #expect(throws: SlideOrderError.missingSlide(identifier: 300)) {
      _ = try SlideOrder.slideEntryPaths(in: index)
    }
  }

  @Test("throws on a nested slide node instead of dropping its slides")
  internal func throwsOnNestedNode() throws {
    let index = try SyntheticDeck.index(
      treeNodeIdentifiers: [10],
      nodes: [10: 100, 20: 200],
      slideIdentifiers: [100, 200],
      childrenOfNode: [10: [20]]
    )
    #expect(throws: SlideOrderError.nestedSlideNode(identifier: 10)) {
      _ = try SlideOrder.slideEntryPaths(in: index)
    }
  }
}
