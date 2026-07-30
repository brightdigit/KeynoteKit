//
//  AppleEventCode.swift
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

/// A four-character Apple event code (an `OSType`), the identity every
/// AppleScript class, property, and enumerator carries at the event level.
///
/// The codes in this module are transcribed from Keynote 15.3's
/// `Keynote.sdef` (for example `tdis` for the dissolve transition effect and
/// `xeft` for the `transition effect` record field).
public struct AppleEventCode: Hashable, Sendable {
  /// The packed big-endian 32-bit value, as Apple events carry it.
  public let rawValue: UInt32

  /// The four ASCII characters spelled out, for example `"tdis"`.
  public var fourCharacterCode: String {
    let shifts: [UInt32] = [24, 16, 8, 0]
    let bytes = shifts.map { UInt8((rawValue >> $0) & 0xFF) }
    return String(decoding: bytes, as: UTF8.self)
  }

  /// Creates a code from its packed 32-bit value.
  ///
  /// - Parameter rawValue: The packed big-endian value of the code.
  public init(rawValue: UInt32) {
    self.rawValue = rawValue
  }

  /// Creates a code from its four-character spelling.
  ///
  /// Codes shorter than four letters are space-padded in the dictionary
  /// (for example the standard suite's `"yes "`), so the spelling passed
  /// here must include those spaces.
  ///
  /// - Parameter fourCharacterCode: Exactly four ASCII characters.
  /// - Precondition: `fourCharacterCode` is exactly four ASCII scalars.
  public init(_ fourCharacterCode: String) {
    let scalars = fourCharacterCode.unicodeScalars
    precondition(
      scalars.count == 4 && scalars.allSatisfy { $0.isASCII },
      "An Apple event code is exactly four ASCII characters."
    )
    var value: UInt32 = 0
    for scalar in scalars {
      value = value << 8 | UInt32(scalar.value)
    }
    self.rawValue = value
  }
}
