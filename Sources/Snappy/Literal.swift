//
//  Literal.swift
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

/// Emits literal elements.
///
/// Encoding every byte of a block as literals always produces a valid,
/// universally decodable block, so this is the encoder's correctness floor.
internal enum Literal {
  /// Appends `input[range]` as one or more literal elements.
  ///
  /// - Parameters:
  ///   - input: The source buffer.
  ///   - range: The slice to emit; an empty range writes nothing.
  ///   - output: The block being built.
  internal static func emit(
    from input: UnsafeBufferPointer<UInt8>,
    range: Range<Int>,
    into output: inout [UInt8]
  ) {
    guard !range.isEmpty else {
      return
    }
    emitTag(length: range.count, into: &output)
    output.append(contentsOf: UnsafeBufferPointer(rebasing: input[range]))
  }

  /// Writes the tag byte, and any extended length operand, for `length` bytes.
  private static func emitTag(length: Int, into output: inout [UInt8]) {
    let biased = length - 1
    guard biased >= Element.maximumInlineLiteralLength else {
      output.append(UInt8(biased) << 2)
      return
    }

    // Selectors 60...63 mean "length follows in the next 1...4 bytes".
    let width = byteWidth(of: biased)
    output.append(UInt8(Element.firstExtendedLiteralSelector + width - 1) << 2)
    for shift in 0..<width {
      output.append(UInt8((biased >> (8 * shift)) & 0xFF))
    }
  }

  /// The number of bytes needed to hold `value`.
  private static func byteWidth(of value: Int) -> Int {
    var width = 1
    var remaining = value >> 8
    while remaining > 0 {
      remaining >>= 8
      width += 1
    }
    return width
  }
}
