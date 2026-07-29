//
//  TSPRegistryMapping.swift
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

public import SwiftProtobuf

/// Keynote's archive-type registry: the table that says which protobuf message
/// a `.iwa` component holds.
///
/// Every object in a Keynote document is tagged with a numeric type identifier
/// rather than a message name, so decoding a component means looking the
/// identifier up here first. The table is transcribed from Keynote 14.4's
/// registry, which the 15.3 schema is still compatible with.
///
/// Identifiers are sparse — they run from `1` to `11027` with large gaps — and
/// the mapping is **not** one-to-one. Several identifiers name the same message:
/// both `5` and `6` resolve to `KN.SlideArchive`, and both `7` and `12` resolve
/// to `KN.PlaceholderArchive`. Do not invert this table assuming unique keys.
public enum TSPRegistryMapping {
  /// The number of archive types Keynote 14.4's registry defines.
  public static var count: Int { Self.table.count }

  /// Every archive-type identifier the registry defines, in ascending order.
  public static var identifiers: [UInt32] { Self.table.keys.sorted() }

  /// The fully-qualified protobuf message name registered for an identifier.
  ///
  /// - Parameter identifier: An archive-type identifier read from a component.
  /// - Returns: A name such as `"KN.SlideArchive"`, or `nil` when the registry
  ///   does not define the identifier.
  public static func messageName(for identifier: UInt32) -> String? {
    Self.table[identifier]
  }

  /// The generated Swift type that decodes a registered message name.
  ///
  /// - Parameter messageName: A fully-qualified name such as `"KN.SlideArchive"`.
  /// - Returns: The message type, or `nil` when no generated type matches.
  public static func messageType(
    forName messageName: String
  ) -> (any SwiftProtobuf.Message.Type)? {
    Self.messageTypes[messageName]
  }

  /// The generated Swift type that decodes an archive-type identifier.
  ///
  /// - Parameter identifier: An archive-type identifier read from a component.
  /// - Returns: The message type, or `nil` when the identifier is unregistered.
  public static func messageType(
    for identifier: UInt32
  ) -> (any SwiftProtobuf.Message.Type)? {
    Self.table[identifier].flatMap { Self.messageTypes[$0] }
  }

  /// Decodes a serialized component body as the message its identifier names.
  ///
  /// Decoding is *partial*: proto2 `required` fields that the bytes omit do not
  /// fail the parse. The vendored schema and registry come from different
  /// Keynote releases, and the 15.3 protos mark 1,497 fields `required` — so
  /// enforcing them would reject documents Keynote itself writes and reads.
  ///
  /// - Parameters:
  ///   - identifier: The archive-type identifier the component was tagged with.
  ///   - serializedBytes: The message's wire-format bytes.
  /// - Returns: The decoded message.
  /// - Throws: ``TSPRegistryError/unknownIdentifier(_:)`` when the registry does
  ///   not define `identifier`, or a `SwiftProtobuf` error when the bytes do not
  ///   parse as that message.
  public static func decode(
    identifier: UInt32,
    serializedBytes: [UInt8]
  ) throws -> any SwiftProtobuf.Message {
    guard let messageType = Self.messageType(for: identifier) else {
      throw TSPRegistryError.unknownIdentifier(identifier)
    }
    return try messageType.init(serializedBytes: serializedBytes, partial: true)
  }
}
