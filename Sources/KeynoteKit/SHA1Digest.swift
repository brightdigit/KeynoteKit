//
//  SHA1Digest.swift
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

/// A portable SHA-1 used for `TSP.DataInfo.digest` (Keynote stores SHA-1 of
/// `Data/` members). CryptoKit is Darwin-only; keep this Linux-clean.
internal enum SHA1Digest {
  /// SHA-1 initial hash values.
  private static let initialState: [UInt32] = [
    0x6745_2301, 0xEFCD_AB89, 0x98BA_DCFE, 0x1032_5476, 0xC3D2_E1F0,
  ]

  /// Computes the 20-byte SHA-1 digest of `data`.
  internal static func hash(_ data: [UInt8]) -> [UInt8] {
    var state = self.initialState
    let message = self.padded(data)

    for chunkStart in stride(from: 0, to: message.count, by: 64) {
      let chunk = Array(message[chunkStart..<chunkStart + 64])
      self.compress(chunk, into: &state)
    }

    return state.flatMap { word in
      [
        UInt8(truncatingIfNeeded: word >> 24),
        UInt8(truncatingIfNeeded: word >> 16),
        UInt8(truncatingIfNeeded: word >> 8),
        UInt8(truncatingIfNeeded: word),
      ]
    }
  }

  /// Applies SHA-1 length padding to a message.
  private static func padded(_ message: [UInt8]) -> [UInt8] {
    var padded = message
    let bitCount = UInt64(message.count) * 8

    padded.append(0x80)
    while padded.count % 64 != 56 {
      padded.append(0)
    }
    for shift in stride(from: 56, through: 0, by: -8) {
      padded.append(UInt8(truncatingIfNeeded: bitCount >> UInt64(shift)))
    }

    return padded
  }

  /// Runs the SHA-1 compression function over one 64-byte chunk.
  private static func compress(_ chunk: [UInt8], into state: inout [UInt32]) {
    var schedule = [UInt32](repeating: 0, count: 80)

    for index in 0..<16 {
      let offset = index * 4
      schedule[index] =
        UInt32(chunk[offset]) << 24 | UInt32(chunk[offset + 1]) << 16
        | UInt32(chunk[offset + 2]) << 8 | UInt32(chunk[offset + 3])
    }
    for index in 16..<80 {
      schedule[index] = self.rotate(
        schedule[index - 3] ^ schedule[index - 8]
          ^ schedule[index - 14] ^ schedule[index - 16],
        1
      )
    }

    var working = state

    for index in 0..<80 {
      let (function, roundConstant) = self.roundTerms(
        index: index,
        wordB: working[1],
        wordC: working[2],
        wordD: working[3]
      )
      let temporary =
        self.rotate(working[0], 5) &+ function &+ working[4]
        &+ roundConstant &+ schedule[index]
      working[4] = working[3]
      working[3] = working[2]
      working[2] = self.rotate(working[1], 30)
      working[1] = working[0]
      working[0] = temporary
    }

    for index in 0..<5 {
      state[index] = state[index] &+ working[index]
    }
  }

  /// Returns the round function and constant for SHA-1 round `index`.
  private static func roundTerms(
    index: Int,
    wordB: UInt32,
    wordC: UInt32,
    wordD: UInt32
  ) -> (UInt32, UInt32) {
    switch index {
    case 0..<20:
      ((wordB & wordC) | (~wordB & wordD), 0x5A82_7999)
    case 20..<40:
      (wordB ^ wordC ^ wordD, 0x6ED9_EBA1)
    case 40..<60:
      ((wordB & wordC) | (wordB & wordD) | (wordC & wordD), 0x8F1B_BCDC)
    default:
      (wordB ^ wordC ^ wordD, 0xCA62_C1D6)
    }
  }

  /// Left-rotates a 32-bit word.
  private static func rotate(_ value: UInt32, _ amount: UInt32) -> UInt32 {
    (value << amount) | (value >> (32 - amount))
  }
}
