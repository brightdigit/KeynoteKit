import IWAFraming
import Testing

/// `upsertEntry` sits on the production surgery path; each of its four
/// ordering branches is pinned here.
@Suite("KeyBundle upsertEntry")
internal struct KeyBundleUpsertTests {
  @Test("replaces an existing entry's body in place")
  internal func replacesExistingBody() {
    var bundle = KeyBundle(entries: [
      KeyBundleEntry(path: "Index/Document.iwa", body: [1]),
      KeyBundleEntry(path: "Data/a.jpg", body: [2]),
    ])
    bundle.upsertEntry(body: [9, 9], at: "Data/a.jpg")
    #expect(bundle.entries.map(\.path) == ["Index/Document.iwa", "Data/a.jpg"])
    #expect(bundle.entries[1].body == [9, 9])
  }

  @Test("inserts a new Data/ member after the last existing Data/ entry")
  internal func insertsDataAfterLastData() {
    var bundle = KeyBundle(entries: [
      KeyBundleEntry(path: "Data/a.jpg", body: [1]),
      KeyBundleEntry(path: "Index/Document.iwa", body: [2]),
    ])
    bundle.upsertEntry(body: [3], at: "Data/b.jpg")
    #expect(
      bundle.entries.map(\.path) == ["Data/a.jpg", "Data/b.jpg", "Index/Document.iwa"]
    )
  }

  @Test("inserts the first Data/ member before the Index/ entries")
  internal func insertsFirstDataBeforeIndex() {
    var bundle = KeyBundle(entries: [
      KeyBundleEntry(path: "Metadata/Properties.plist", body: [1]),
      KeyBundleEntry(path: "Index/Document.iwa", body: [2]),
    ])
    bundle.upsertEntry(body: [3], at: "Data/a.jpg")
    #expect(
      bundle.entries.map(\.path)
        == ["Metadata/Properties.plist", "Data/a.jpg", "Index/Document.iwa"]
    )
  }

  @Test("inserts a Data/ member at the front of an Index-free bundle")
  internal func insertsDataFirstWithoutIndex() {
    var bundle = KeyBundle(entries: [
      KeyBundleEntry(path: "Metadata/Properties.plist", body: [1])
    ])
    bundle.upsertEntry(body: [2], at: "Data/a.jpg")
    #expect(bundle.entries.map(\.path) == ["Data/a.jpg", "Metadata/Properties.plist"])
  }

  @Test("appends non-Data entries at the end")
  internal func appendsNonDataEntries() {
    var bundle = KeyBundle(entries: [
      KeyBundleEntry(path: "Index/Document.iwa", body: [1])
    ])
    bundle.upsertEntry(body: [2], at: "Metadata/DocumentIdentifier")
    #expect(
      bundle.entries.map(\.path) == ["Index/Document.iwa", "Metadata/DocumentIdentifier"]
    )
  }
}
