//
//  ProtobufVarint.swift
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

/// Base-128 varints as used to length-prefix `TSP.ArchiveInfo` headers.
///
/// SwiftProtobuf's own varint machinery is internal to its stream APIs, so
/// the archive-stream layer carries this ~40-line implementation instead of
/// reaching into the library.
internal enum ProtobufVarint {
  /// The widest encoding accepted: ten 7-bit groups covers `UInt64`.
  private static let maximumWidth = 10

  /// Reads a varint at `index`, returning the value and the index after it,
  /// or `nil` when the input ends mid-varint or the encoding overflows.
  internal static func read(
    from bytes: [UInt8],
    at index: Int
  ) -> (value: UInt64, next: Int)? {
    var value: UInt64 = 0
    var shift: UInt64 = 0
    var cursor = index
    while cursor < bytes.count, cursor - index < maximumWidth {
      let byte = bytes[cursor]
      let group = UInt64(byte & 0x7F)
      guard (group << shift) >> shift == group else {
        return nil
      }
      value |= group << shift
      cursor += 1
      if byte & 0x80 == 0 {
        return (value: value, next: cursor)
      }
      shift += 7
    }
    return nil
  }

  /// Appends `value` to `output` in varint encoding.
  internal static func append(_ value: UInt64, to output: inout [UInt8]) {
    var remaining = value
    while remaining >= 0x80 {
      output.append(UInt8(remaining & 0x7F) | 0x80)
      remaining >>= 7
    }
    output.append(UInt8(remaining))
  }
}
