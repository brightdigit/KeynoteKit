import Foundation
import IWAFraming
import KeynoteKitProtobuf
import Testing

@testable import KeynoteKit

/// Image authoring (#38): `Data/` + ImageArchive + builds on images.
@Suite("Image authoring")
internal struct ImageAuthoringTests {
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

  @Test("authors an image drawable with Data/ registration and an In build")
  internal func authorsImageWithBuild() throws {
    let deck = Deck {
      Slide {
        Text("Caption").position(x: 100, y: 500)
        Image(data: tinyJPEG)
          .position(x: 200, y: 150)
          .frame(width: 320, height: 240)
          .build(.in) { Dissolve() }
      }
    }
    let url = FileManager.default.temporaryDirectory
      .appending(path: "image-\(UUID().uuidString).key")
    defer { try? FileManager.default.removeItem(at: url) }
    try deck.write(to: url)

    let zipBytes = Array(try Data(contentsOf: url))
    let bundle = try KeyBundle(contentsOfZip: zipBytes)
    let surgeon = try KeynoteArchiveSurgeon(bundle: bundle)
    let catalog = SlideCatalog(members: surgeon.members)

    let dataPath = try expectAuthoredDataPath(in: zipBytes, bundle: bundle)
    let info = try expectDataInfo(for: dataPath, in: surgeon, catalog: catalog)
    #expect(info.digest.count == 20)
    #expect(Data(info.digest) == Data(SHA1Digest.hash(Array(tinyJPEG))))
    #expect(info.materializedLength == UInt64(tinyJPEG.count))
    #expect(try decodedAttributes(of: info).hasTSD_ImageDataAttributes_imageDataAttributes)
    try expectStyleExternalReference(in: surgeon, catalog: catalog)

    let imageId = try expectImageGeometry(
      in: surgeon,
      catalog: catalog,
      dataIdentifier: info.identifier
    )
    try expectBuildTargets(imageId, in: surgeon, catalog: catalog)
    try UUIDMapVerifier.verify(members: surgeon.members, expectedBuildCount: 1)
  }

  /// Asserts exactly one authored `Data/kn-` member exists and returns its path.
  private func expectAuthoredDataPath(
    in zipBytes: [UInt8],
    bundle: KeyBundle
  ) throws -> String {
    let dataPaths = zipPaths(zipBytes).filter { $0.hasPrefix("Data/kn-") }
    #expect(dataPaths.count == 1)
    let dataPath = try #require(dataPaths.first)
    #expect(bundle.entry(at: dataPath) != nil)
    return dataPath
  }

  /// Asserts slide drawables and image geometry; returns the image drawable id.
  private func expectImageGeometry(
    in surgeon: KeynoteArchiveSurgeon,
    catalog: SlideCatalog,
    dataIdentifier: UInt64
  ) throws -> UInt64 {
    let slides = try catalog.orderedSlides()
    let slide = try #require(slides.first)
    let archive = try KN_SlideArchive(
      serializedBytes: surgeon.members[slide.memberIndex].records[slide.recordIndex].payloads[0],
      partial: true
    )
    #expect(archive.drawablesZOrder.count == 2)
    #expect(archive.builds.count == 1)

    let imageId = archive.drawablesZOrder[1].identifier
    guard
      let imageLoc = try catalog.locate(
        recordIdentifier: imageId,
        named: "TSD.ImageArchive"
      )
    else {
      Issue.record("missing image archive")
      throw ArchiveSurgeryError.missingSlideRecord(identifier: imageId)
    }
    let image = try TSD_ImageArchive(
      serializedBytes: surgeon.members[imageLoc.memberIndex]
        .records[imageLoc.recordIndex]
        .payloads[imageLoc.payloadIndex],
      partial: true
    )
    #expect(image.super.geometry.position.x == 200)
    #expect(image.super.geometry.position.y == 150)
    #expect(image.super.geometry.size.width == 320)
    #expect(image.super.geometry.size.height == 240)
    #expect(image.data.identifier == dataIdentifier)
    #expect(!image.hasThumbnailData)
    #expect(image.hasTracedPath)
    #expect(image.super.hasTitle)
    #expect(image.super.hasCaption)
    #expect(archive.ownedDrawables.contains { $0.identifier == imageId })
    return imageId
  }

  /// Asserts the first build targets `imageId`.
  private func expectBuildTargets(
    _ imageId: UInt64,
    in surgeon: KeynoteArchiveSurgeon,
    catalog: SlideCatalog
  ) throws {
    let slides = try catalog.orderedSlides()
    let slide = try #require(slides.first)
    let archive = try KN_SlideArchive(
      serializedBytes: surgeon.members[slide.memberIndex].records[slide.recordIndex].payloads[0],
      partial: true
    )
    guard
      let buildLoc = try catalog.locate(
        recordIdentifier: archive.builds[0].identifier,
        named: "KN.BuildArchive"
      )
    else {
      Issue.record("missing build")
      throw ArchiveSurgeryError.missingSlideRecord(identifier: archive.builds[0].identifier)
    }
    let build = try KN_BuildArchive(
      serializedBytes: surgeon.members[buildLoc.memberIndex]
        .records[buildLoc.recordIndex]
        .payloads[buildLoc.payloadIndex],
      partial: true
    )
    #expect(build.drawable.identifier == imageId)
  }
}
