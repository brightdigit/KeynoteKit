import Foundation
import KeynoteKitProtobuf
import Testing

@testable import KeynoteKit

extension ImageAuthoringTests {
  /// Asserts the slide component declares the image's media style as an
  /// external reference into the stylesheet component (missing edge crashes
  /// Keynote during layout).
  internal func expectStyleExternalReference(
    in surgeon: KeynoteArchiveSurgeon,
    catalog: SlideCatalog
  ) throws {
    let meta = try packageMetadata(in: surgeon, catalog: catalog)
    let style = try #require(try surgeon.mediaStyle())
    let slideIdentifier = try #require(try catalog.orderedSlides().first?.slideIdentifier)
    let slideComponent = try #require(
      meta.components.first { $0.identifier == slideIdentifier }
    )
    #expect(
      slideComponent.externalReferences.contains {
        $0.objectIdentifier == style.identifier
      }
    )
  }

  /// Loads the `TSP.DataInfo` row for `dataPath`.
  internal func expectDataInfo(
    for dataPath: String,
    in surgeon: KeynoteArchiveSurgeon,
    catalog: SlideCatalog
  ) throws -> TSP_DataInfo {
    let meta = try packageMetadata(in: surgeon, catalog: catalog)
    return try #require(
      meta.datas.first { $0.fileName == dataPath.split(separator: "/").last.map(String.init) }
    )
  }

  /// Re-decodes a `DataInfo`'s attributes with the TSD extension map so
  /// extension fields (e.g. image pixel size) become visible.
  internal func decodedAttributes(of info: TSP_DataInfo) throws -> TSP_DataAttributes {
    try TSP_DataAttributes(
      serializedBytes: info.attributes.serializedBytes(partial: true) as Data,
      extensions: TSD_Tsdarchives_Extensions,
      partial: true
    )
  }

  /// Decodes the single `TSP.PackageMetadata` record.
  private func packageMetadata(
    in surgeon: KeynoteArchiveSurgeon,
    catalog: SlideCatalog
  ) throws -> TSP_PackageMetadata {
    guard let metaLoc = try catalog.locateFirst(named: "TSP.PackageMetadata") else {
      Issue.record("missing metadata")
      throw ArchiveSurgeryError.missingSlideComponent(slideIdentifier: 0)
    }
    return try TSP_PackageMetadata(
      serializedBytes: surgeon.members[metaLoc.memberIndex]
        .records[metaLoc.recordIndex]
        .payloads[metaLoc.payloadIndex],
      partial: true
    )
  }
}
