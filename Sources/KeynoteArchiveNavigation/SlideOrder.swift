//
//  SlideOrder.swift
//  KeynoteKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

package import KeynoteKitProtobuf

/// The presentation-order slide walk: document → show → slide tree → slides.
///
/// This is the traversal the #20 writer needs (mirroring Python
/// `archive_backend._slide_order`), distinct from `BuildExtractor`'s
/// filename-order parity walk.
package enum SlideOrder {
  /// The `Index/` member paths of the deck's slides, in slide-tree order.
  ///
  /// Follows `KN.DocumentArchive.show` → `KN.ShowArchive.slideTree` → the
  /// root `KN.SlideNodeArchive`'s children → each node's `slide` reference,
  /// then maps every slide identifier to the member that holds its record.
  ///
  /// - Parameter index: The deck's parsed `Index/` members.
  /// - Returns: One member path per slide, in presentation order.
  /// - Throws: ``SlideOrderError`` when a link in the walk is missing, or a
  ///   SwiftProtobuf error for undecodable payloads.
  package static func slideEntryPaths(in index: KeyArchiveIndex) throws -> [String] {
    let show = try showArchive(in: index)
    var paths: [String] = []
    for slideIdentifier in try slideIdentifiers(of: show, in: index) {
      guard let located = index.record(withIdentifier: slideIdentifier) else {
        throw SlideOrderError.missingSlide(identifier: slideIdentifier)
      }
      paths.append(located.path)
    }
    return paths
  }

  /// Finds and decodes the deck's `KN.ShowArchive`.
  private static func showArchive(in index: KeyArchiveIndex) throws -> KN_ShowArchive {
    guard let document = try firstMessage(named: "KN.DocumentArchive", in: index),
      let documentArchive = document as? KN_DocumentArchive
    else {
      throw SlideOrderError.missingDocumentArchive
    }
    guard documentArchive.hasShow,
      let located = index.record(withIdentifier: documentArchive.show.identifier),
      let showIndex = located.record.resolvedTypes.firstIndex(where: {
        TSPRegistryMapping.messageName(for: $0) == "KN.ShowArchive"
      })
    else {
      throw SlideOrderError.missingShowArchive
    }
    return try KN_ShowArchive(
      serializedBytes: located.record.payloads[showIndex],
      partial: true
    )
  }

  /// The slide identifiers of the show, in tree order.
  ///
  /// `slideTree.slides` (and a root node's `children`) reference
  /// `KN.SlideNodeArchive` records — typically stored in `Document.iwa` —
  /// whose `slide` reference then names the actual `KN.SlideArchive` in its
  /// `Slide-*.iwa` member. The walk always resolves through the node.
  private static func slideIdentifiers(
    of show: KN_ShowArchive,
    in index: KeyArchiveIndex
  ) throws -> [UInt64] {
    let tree = show.slideTree
    var nodeIdentifiers = tree.slides.map(\.identifier)
    if tree.hasRootSlideNode,
      let root = try slideNode(withIdentifier: tree.rootSlideNode.identifier, in: index),
      !root.children.isEmpty
    {
      nodeIdentifiers = root.children.map(\.identifier)
    }
    var identifiers: [UInt64] = []
    for nodeIdentifier in nodeIdentifiers {
      guard let node = try slideNode(withIdentifier: nodeIdentifier, in: index) else {
        throw SlideOrderError.missingSlideNode(identifier: nodeIdentifier)
      }
      if node.hasSlide {
        identifiers.append(node.slide.identifier)
      }
    }
    return identifiers
  }

  /// Decodes the `KN.SlideNodeArchive` in the record with `identifier`, or
  /// `nil` when the record is missing or holds no slide node.
  private static func slideNode(
    withIdentifier identifier: UInt64,
    in index: KeyArchiveIndex
  ) throws -> KN_SlideNodeArchive? {
    guard let located = index.record(withIdentifier: identifier),
      let nodeIndex = located.record.resolvedTypes.firstIndex(where: {
        TSPRegistryMapping.messageName(for: $0) == "KN.SlideNodeArchive"
      })
    else {
      return nil
    }
    return try KN_SlideNodeArchive(
      serializedBytes: located.record.payloads[nodeIndex],
      partial: true
    )
  }

  /// Decodes the first message of `name` found in archive order.
  private static func firstMessage(
    named name: String,
    in index: KeyArchiveIndex
  ) throws -> (any Sendable)? {
    for path in index.entryPaths {
      for record in index.records(at: path) ?? [] {
        for (offset, type) in record.resolvedTypes.enumerated()
        where TSPRegistryMapping.messageName(for: type) == name {
          return try TSPRegistryMapping.decode(
            identifier: type,
            serializedBytes: record.payloads[offset]
          )
        }
      }
    }
    return nil
  }
}
