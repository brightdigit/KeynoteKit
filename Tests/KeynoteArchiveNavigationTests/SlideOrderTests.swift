import Foundation
import IWAFraming
import KeynoteArchiveNavigation
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
}
