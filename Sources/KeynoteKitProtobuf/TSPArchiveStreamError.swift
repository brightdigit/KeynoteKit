//
//  TSPArchiveStreamError.swift
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

/// Errors thrown when splitting a decompressed `.iwa` stream into records.
///
/// Protobuf decoding failures inside an `ArchiveInfo` header or a payload
/// surface as SwiftProtobuf errors instead; these cases cover the delimiting
/// layer itself.
public enum TSPArchiveStreamError: Error, Equatable, Sendable {
  /// The stream ended inside an `ArchiveInfo` length prefix.
  case truncatedVarint(offset: Int)

  /// An `ArchiveInfo` header's declared length runs past the stream.
  case truncatedArchiveInfo(offset: Int, expected: Int)

  /// A message payload declared by `MessageInfo.length` runs past the stream.
  case truncatedPayload(archiveIdentifier: UInt64, expected: Int, available: Int)
}
