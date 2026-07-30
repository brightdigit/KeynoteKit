//
//  TSPArchiveStream.swift
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

/// The `TSP.ArchiveInfo`-delimited encoding of a decompressed `.iwa` stream.
///
/// The layout — verified against keynote-parser 1.14.4.0's `codec.py` and
/// recorded in `research/findings/` — repeats until the stream ends:
///
/// 1. a base-128 varint holding the byte length of an `ArchiveInfo` message,
/// 2. that many bytes of `ArchiveInfo`,
/// 3. for each of its `messageInfos`, `length` bytes of serialized payload.
public struct TSPArchiveStream: Sendable {
  /// The shared default archive-stream codec.
  public static let `default` = TSPArchiveStream()

  private init() {}

  /// Splits a decompressed `.iwa` stream into records.
  ///
  /// Payload bytes are carried verbatim; nothing inside them is re-encoded.
  ///
  /// - Parameter bytes: The decompressed archive stream.
  /// - Returns: The records, in stream order.
  /// - Throws: ``TSPArchiveStreamError`` if the delimiting is malformed, or
  ///   a SwiftProtobuf error if an `ArchiveInfo` header is undecodable.
  public func records(from bytes: [UInt8]) throws -> [TSPArchiveRecord] {
    var records: [TSPArchiveRecord] = []
    var index = 0
    while index < bytes.count {
      records.append(try nextRecord(in: bytes, at: &index))
    }
    return records
  }

  /// Serializes records back into a delimited stream.
  ///
  /// Each `MessageInfo.length` is recomputed from its payload on a local
  /// copy of the header, so callers that mutate payloads cannot leave the
  /// two out of sync. `ArchiveInfo` headers are re-encoded partially, as
  /// Keynote omits many proto2 `required` fields.
  ///
  /// - Parameter records: The records to serialize, in order.
  /// - Returns: A delimited stream ready for ``records(from:)`` or framing.
  /// - Throws: A SwiftProtobuf error if a header fails to serialize.
  public func serialize(_ records: [TSPArchiveRecord]) throws -> [UInt8] {
    var output: [UInt8] = []
    for record in records {
      var info = record.info
      for (index, payload) in record.payloads.enumerated()
      where index < info.messageInfos.count {
        info.messageInfos[index].length = UInt32(payload.count)
      }
      let header: [UInt8] = try info.serializedBytes(partial: true)
      ProtobufVarint.append(UInt64(header.count), to: &output)
      output.append(contentsOf: header)
      for payload in record.payloads {
        output.append(contentsOf: payload)
      }
    }
    return output
  }

  /// Reads one record at `index`, advancing `index` past it.
  private func nextRecord(
    in bytes: [UInt8],
    at index: inout Int
  ) throws -> TSPArchiveRecord {
    guard let (headerLength, headerStart) = ProtobufVarint.read(from: bytes, at: index) else {
      throw TSPArchiveStreamError.truncatedVarint(offset: index)
    }
    let headerEnd = headerStart + Int(headerLength)
    guard headerEnd <= bytes.count else {
      throw TSPArchiveStreamError.truncatedArchiveInfo(
        offset: index,
        expected: Int(headerLength)
      )
    }
    let info = try TSP_ArchiveInfo(
      serializedBytes: Array(bytes[headerStart..<headerEnd]),
      partial: true
    )
    var cursor = headerEnd
    var payloads: [[UInt8]] = []
    payloads.reserveCapacity(info.messageInfos.count)
    for messageInfo in info.messageInfos {
      let payloadEnd = cursor + Int(messageInfo.length)
      guard payloadEnd <= bytes.count else {
        throw TSPArchiveStreamError.truncatedPayload(
          archiveIdentifier: info.identifier,
          expected: Int(messageInfo.length),
          available: bytes.count - cursor
        )
      }
      payloads.append(Array(bytes[cursor..<payloadEnd]))
      cursor = payloadEnd
    }
    index = cursor
    return TSPArchiveRecord(info: info, payloads: payloads)
  }
}
