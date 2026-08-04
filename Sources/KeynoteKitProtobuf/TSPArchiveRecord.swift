//
//  TSPArchiveRecord.swift
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

/// One record of a decompressed `.iwa` archive stream: an `ArchiveInfo`
/// header plus the raw payload bytes of each of its messages.
///
/// Payloads stay opaque `[UInt8]` so a parse–serialize round-trip carries
/// Keynote's exact bytes; decode them on demand with ``decodedMessages()``.
public struct TSPArchiveRecord: Equatable, Sendable {
  /// The record's header: object identifier and per-message metadata.
  public var info: TSP_ArchiveInfo

  /// One serialized payload per `info.messageInfos` entry, in order.
  public var payloads: [[UInt8]]

  /// The effective registry identifier of each message, in order, with the
  /// `0` patch marker resolved through `baseMessageIndex`.
  public var resolvedTypes: [UInt32] {
    info.messageInfos.map(resolvedType(of:))
  }

  /// Creates a record.
  ///
  /// - Parameters:
  ///   - info: The record's `ArchiveInfo` header.
  ///   - payloads: One serialized payload per `messageInfos` entry.
  public init(info: TSP_ArchiveInfo, payloads: [[UInt8]]) {
    self.info = info
    self.payloads = payloads
  }

  /// Decodes every payload through ``TSPRegistryMapping``.
  ///
  /// Decoding is always partial: Keynote leaves many proto2 `required`
  /// fields unpopulated, so strict decoding would reject documents Keynote
  /// itself round-trips.
  ///
  /// A message with `type == 0` in a `shouldMerge` record is a patch — its
  /// payload is a sparse message of the type named by the entry at its
  /// `baseMessageIndex`, mirroring keynote-parser's `ProtobufPatch`.
  ///
  /// - Returns: One decoded message per payload, in order.
  /// - Throws: `TSPRegistryError.unknownIdentifier` for an unregistered
  ///   message type, or a SwiftProtobuf error for undecodable bytes.
  public func decodedMessages() throws -> [any SwiftProtobuf.Message] {
    try zip(info.messageInfos, payloads).map { messageInfo, payload in
      try TSPRegistryMapping.decode(
        identifier: resolvedType(of: messageInfo),
        serializedBytes: payload
      )
    }
  }

  /// The registry identifier for a message, following a patch entry's
  /// `baseMessageIndex` when its own type is the `0` patch marker.
  private func resolvedType(of messageInfo: TSP_MessageInfo) -> UInt32 {
    guard messageInfo.type == 0, info.shouldMerge else {
      return messageInfo.type
    }
    let baseIndex = Int(messageInfo.baseMessageIndex)
    guard info.messageInfos.indices.contains(baseIndex) else {
      return messageInfo.type
    }
    return info.messageInfos[baseIndex].type
  }
}
