//
//  Copy.swift
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

/// Emits copy elements, which replay bytes already present in the output.
///
/// Two forms are produced. Short nearby matches use the compact one-byte-offset
/// encoding; everything else uses the two-byte form. The four-byte form is
/// never emitted — a block caps at 64 KiB, so no legal offset needs it.
internal enum Copy {
  /// Appends a copy element for `length` bytes at `offset` back.
  ///
  /// - Parameters:
  ///   - length: Run length, from 4 through 64.
  ///   - offset: Distance back into the output, at most 65,535.
  ///   - output: The block being built.
  internal static func emit(length: Int, offset: Int, into output: inout [UInt8]) {
    let usesCompactForm =
      length <= Element.maximumCopy1Length && offset <= Element.maximumCopy1Offset

    guard usesCompactForm else {
      // 6-bit length biased by 1, then a little-endian 16-bit offset.
      output.append(UInt8(length - 1) << 2 | Element.copy2Tag)
      output.append(UInt8(offset & 0xFF))
      output.append(UInt8((offset >> 8) & 0xFF))
      return
    }

    // 3-bit length biased by 4, with the offset's high 3 bits in the tag.
    let lengthBits = UInt8(length - Element.minimumCopyLength) << 2
    let offsetHighBits = UInt8((offset >> 8) & 0x07) << 5
    output.append(offsetHighBits | lengthBits | Element.copy1Tag)
    output.append(UInt8(offset & 0xFF))
  }
}
