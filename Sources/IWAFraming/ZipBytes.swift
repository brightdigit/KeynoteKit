//
//  ZipBytes.swift
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

/// Little-endian integer reads and writes over `[UInt8]`.
///
/// The zip format is little-endian throughout; keeping these in one place
/// keeps the header types free of shift arithmetic.
internal enum ZipBytes {
  /// Reads a 16-bit little-endian value at `offset` as an `Int`.
  internal static func readUInt16(_ bytes: [UInt8], _ offset: Int) -> Int {
    Int(bytes[offset]) | (Int(bytes[offset + 1]) << 8)
  }

  /// Reads a 32-bit little-endian value at `offset`.
  internal static func readUInt32(_ bytes: [UInt8], _ offset: Int) -> UInt32 {
    UInt32(bytes[offset])
      | (UInt32(bytes[offset + 1]) << 8)
      | (UInt32(bytes[offset + 2]) << 16)
      | (UInt32(bytes[offset + 3]) << 24)
  }

  /// Appends a 16-bit little-endian value.
  internal static func appendUInt16(_ output: inout [UInt8], _ value: Int) {
    output.append(UInt8(value & 0xFF))
    output.append(UInt8((value >> 8) & 0xFF))
  }

  /// Appends a 32-bit little-endian value.
  internal static func appendUInt32(_ output: inout [UInt8], _ value: UInt32) {
    output.append(UInt8(value & 0xFF))
    output.append(UInt8((value >> 8) & 0xFF))
    output.append(UInt8((value >> 16) & 0xFF))
    output.append(UInt8((value >> 24) & 0xFF))
  }
}
