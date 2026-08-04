//
//  BuildExtractor.swift
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

/// Reproduces Python `deckkit.extract_builds` at archive level (#18).
///
/// Parity rules mirrored from the Python implementation exactly:
/// slide members are visited in lexicographic *filename* order (Python sorts
/// `os.listdir`, so `Slide-1234.iwa` sorts before `Slide.iwa`), records in
/// stream order, and a build with no `effect` is skipped.
package enum BuildExtractor {
  /// Every object build in the deck, in Python's extraction order.
  ///
  /// - Parameter index: The deck's parsed `Index/` members.
  /// - Returns: One ``BuildRecord`` per `KN.BuildArchive` with an effect.
  /// - Throws: A SwiftProtobuf error if a build payload is undecodable.
  package static func builds(in index: KeyArchiveIndex) throws -> [BuildRecord] {
    var builds: [BuildRecord] = []
    for path in slideEntryPaths(in: index) {
      for record in index.records(at: path) ?? [] {
        builds.append(contentsOf: try buildRecords(in: record))
      }
    }
    return builds
  }

  /// `Index/Slide*.iwa` paths in lexicographic filename order.
  package static func slideEntryPaths(in index: KeyArchiveIndex) -> [String] {
    index.entryPaths
      .filter { path in
        let name = String(path.dropFirst("Index/".count))
        return name.hasPrefix("Slide") && name.hasSuffix(".iwa")
      }
      .sorted()
  }

  /// The build records inside one archive record, in message order.
  private static func buildRecords(in record: TSPArchiveRecord) throws -> [BuildRecord] {
    var builds: [BuildRecord] = []
    for (type, payload) in zip(record.resolvedTypes, record.payloads)
    where TSPRegistryMapping.messageName(for: type) == "KN.BuildArchive" {
      let archive = try KN_BuildArchive(serializedBytes: payload, partial: true)
      if let build = buildRecord(from: archive) {
        builds.append(build)
      }
    }
    return builds
  }

  /// Maps one decoded `KN.BuildArchive` to a ``BuildRecord``, or `nil` when
  /// it has no effect (Python skips those).
  private static func buildRecord(from archive: KN_BuildArchive) -> BuildRecord? {
    let animation = archive.attributes.animationAttributes
    guard animation.hasEffect, !animation.effect.isEmpty else {
      return nil
    }
    // Python takes the FIRST `duration:` in the alphabetized YAML block —
    // `attributes.animationAttributes.duration` when set, else the archive's.
    var duration: Double?
    if animation.hasDuration {
      duration = animation.duration
    } else if archive.hasDuration {
      duration = archive.duration
    }
    return BuildRecord(
      kind: animation.hasAnimationType ? animation.animationType : nil,
      effect: animation.effect,
      duration: duration,
      delay: animation.hasDelay ? animation.delay : nil,
      direction: animation.hasDirection ? Int(animation.direction) : nil,
      drawable: archive.hasDrawable ? String(archive.drawable.identifier) : nil,
      options: options(of: archive)
    )
  }

  /// The sparse option bag, from the fields Python's key list captures.
  private static func options(of archive: KN_BuildArchive) -> [String: BuildOptionValue] {
    let attributes = archive.attributes
    var options: [String: BuildOptionValue] = [:]
    if attributes.hasCustomBounce {
      options["customBounce"] = .bool(attributes.customBounce)
    }
    if attributes.hasCustomTravelDistance {
      options["customTravelDistance"] = .double(attributes.customTravelDistance)
    }
    if attributes.hasCustomTextDelivery {
      options["customTextDelivery"] = .string(String(describing: attributes.customTextDelivery))
    }
    if attributes.hasCustomDeliveryOption {
      options["customDeliveryOption"] = .string(String(describing: attributes.customDeliveryOption))
    }
    if archive.hasDelivery {
      options["delivery"] = .string(archive.delivery)
    }
    if attributes.hasEventTrigger {
      options["eventTrigger"] = .int(Int64(attributes.eventTrigger))
    }
    return options
  }
}
