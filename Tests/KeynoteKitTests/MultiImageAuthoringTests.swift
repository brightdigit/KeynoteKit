import Foundation
import IWAFraming
import KeynoteKitProtobuf
import Testing

@testable import KeynoteKit

/// Multi-image interactions the single-image suite cannot see: per-slide
/// data-identifier allocation and cloning a slide that carries an inserted
/// image.
@Suite("Multi-image authoring")
internal struct MultiImageAuthoringTests {
  /// Minimal 1×1 JPEG used as authored image bytes.
  private var tinyJPEG: Data {
    Data([
      0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01, 0x01, 0x00, 0x00,
      0x01, 0x00, 0x01, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43, 0x00, 0x08, 0x06, 0x06, 0x07, 0x06,
      0x05, 0x08, 0x07, 0x07, 0x07, 0x09, 0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B,
      0x0C, 0x19, 0x12, 0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20,
      0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29, 0x2C, 0x30, 0x31,
      0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32, 0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF,
      0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01, 0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00,
      0x1F, 0x00, 0x00, 0x01, 0x05, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B,
      0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3F, 0x00, 0x7F, 0xFF, 0xD9,
    ])
  }

  @Test("two images on one slide mint distinct data identifiers")
  internal func twoImagesDistinctData() throws {
    let deck = Deck {
      Slide {
        Image(data: tinyJPEG).position(x: 100, y: 100).frame(width: 100, height: 100)
        Image(data: tinyJPEG).position(x: 300, y: 100).frame(width: 100, height: 100)
      }
    }
    let url = temporaryKeyURL()
    defer { try? FileManager.default.removeItem(at: url) }
    try deck.write(to: url)

    let bundle = try KeyBundle(contentsOfZip: Array(try Data(contentsOf: url)))
    let surgeon = try KeynoteArchiveSurgeon(bundle: bundle)
    let catalog = SlideCatalog(members: surgeon.members)

    let dataPaths = bundle.entries.map(\.path).filter { $0.hasPrefix("Data/kn-") }
    #expect(dataPaths.count == 2)

    let dataIdentifiers = try imageDataIdentifiers(in: surgeon, catalog: catalog)
    #expect(dataIdentifiers.count == 2)
    #expect(Set(dataIdentifiers).count == 2)

    let registered = try registeredDataIdentifiers(in: surgeon, catalog: catalog)
    #expect(registered.count == Set(registered).count)
    for identifier in dataIdentifiers {
      #expect(registered.contains(identifier))
    }
  }

  @Test("cloning a slide with an inserted image keeps ownership in the clone")
  internal func cloneKeepsImageOwnership() throws {
    let baseURL = temporaryKeyURL()
    let outURL = temporaryKeyURL()
    defer {
      try? FileManager.default.removeItem(at: baseURL)
      try? FileManager.default.removeItem(at: outURL)
    }
    try Deck {
      Slide {
        Image(data: tinyJPEG).position(x: 100, y: 100).frame(width: 100, height: 100)
      }
    }
    .write(to: baseURL)
    // Slide cloning runs before item expansion, so the base's image records
    // are cloned wholesale; the text items only satisfy the per-slide
    // drawable count.
    try Deck {
      Slide { TextBox("first") }
      Slide { TextBox("second") }
    }
    .write(to: outURL, basedOn: KeynoteTemplate(contentsOf: baseURL))

    let bundle = try KeyBundle(contentsOfZip: Array(try Data(contentsOf: outURL)))
    let surgeon = try KeynoteArchiveSurgeon(bundle: bundle)
    let slides = try SlideCatalog(members: surgeon.members).orderedSlides()
    #expect(slides.count == 2)

    let owned = try slides.map { slide in
      let archive = try KN_SlideArchive(
        serializedBytes: surgeon.members[slide.memberIndex]
          .records[slide.recordIndex]
          .payloads[0],
        partial: true
      )
      return Set(archive.ownedDrawables.map(\.identifier))
    }
    #expect(!owned[0].isEmpty)
    #expect(!owned[1].isEmpty)
    #expect(owned[0].isDisjoint(with: owned[1]))
    for (slide, identifiers) in zip(slides, owned) {
      let memberIdentifiers = Set(
        surgeon.members[slide.memberIndex].records.map(\.info.identifier)
      )
      #expect(identifiers.isSubset(of: memberIdentifiers))
    }
  }

  /// The authored image archives' data identifiers, in z-order.
  private func imageDataIdentifiers(
    in surgeon: KeynoteArchiveSurgeon,
    catalog: SlideCatalog
  ) throws -> [UInt64] {
    let slide = try #require(try catalog.orderedSlides().first)
    let archive = try KN_SlideArchive(
      serializedBytes: surgeon.members[slide.memberIndex]
        .records[slide.recordIndex]
        .payloads[0],
      partial: true
    )
    return try archive.drawablesZOrder.map { reference in
      let location = try #require(
        try catalog.locate(recordIdentifier: reference.identifier, named: "TSD.ImageArchive")
      )
      let image = try TSD_ImageArchive(
        serializedBytes: surgeon.members[location.memberIndex]
          .records[location.recordIndex]
          .payloads[location.payloadIndex],
        partial: true
      )
      return image.data.identifier
    }
  }

  /// All `TSP.DataInfo` identifiers registered in package metadata.
  private func registeredDataIdentifiers(
    in surgeon: KeynoteArchiveSurgeon,
    catalog: SlideCatalog
  ) throws -> [UInt64] {
    let location = try #require(try catalog.locateFirst(named: "TSP.PackageMetadata"))
    let metadata = try TSP_PackageMetadata(
      serializedBytes: surgeon.members[location.memberIndex]
        .records[location.recordIndex]
        .payloads[location.payloadIndex],
      partial: true
    )
    return metadata.datas.map(\.identifier)
  }

  private func temporaryKeyURL() -> URL {
    FileManager.default.temporaryDirectory
      .appending(path: "multi-image-\(UUID().uuidString).key")
  }
}
