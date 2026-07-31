//
//  JPEGSize.swift
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

/// Minimal JPEG SOF dimension reader (no ImageIO — keeps Linux clean).
internal enum JPEGSize {
  /// Returns true if `marker` is a Start-of-Frame marker carrying pixel dimensions.
  private static func isSOFMarker(_ marker: UInt8) -> Bool {
    switch marker {
    case 0xC0...0xC3, 0xC5...0xC7, 0xC9...0xCB, 0xCD...0xCF:
      return true
    default:
      return false
    }
  }

  /// Extracts width and height from an SOF segment.
  private static func parseSOFSegment(
    data: [UInt8],
    index: Int,
    length: Int
  ) -> (width: Double, height: Double)? {
    guard length >= 7, index + 7 <= data.count else {
      return nil
    }
    let height = Int(data[index + 3]) << 8 | Int(data[index + 4])
    let width = Int(data[index + 5]) << 8 | Int(data[index + 6])
    return (Double(width), Double(height))
  }

  /// Returns true if `data` starts with JPEG SOI marker.
  private static func isValidHeader(_ data: [UInt8]) -> Bool {
    data.count > 4 && data[0] == 0xFF && data[1] == 0xD8
  }

  /// Advances `index` past consecutive 0xFF fill bytes.
  private static func skipFillBytes(in data: [UInt8], startingAt index: Int) -> Int {
    var idx = index
    while idx < data.count, data[idx] == 0xFF {
      idx += 1
    }
    return idx
  }

  /// Returns true if `marker` indicates end of image or start of scan (no more metadata markers).
  private static func isTerminalMarker(_ marker: UInt8) -> Bool {
    marker == 0xD9 || marker == 0xDA
  }

  /// Reads and validates a 2-byte big-endian segment length.
  private static func segmentLength(in data: [UInt8], at index: Int) -> Int? {
    guard index + 2 <= data.count else {
      return nil
    }
    let length = Int(data[index]) << 8 | Int(data[index + 1])
    guard length >= 2, index + length <= data.count else {
      return nil
    }
    return length
  }

  /// Pixel size from a JPEG SOF marker, when present.
  internal static func dimensions(of data: [UInt8]) -> (width: Double, height: Double)? {
    guard isValidHeader(data) else {
      return nil
    }
    var index = 2
    while index < data.count {
      index = skipFillBytes(in: data, startingAt: index)
      guard index < data.count else {
        return nil
      }
      let marker = data[index]
      index += 1
      if isTerminalMarker(marker) {
        return nil
      }
      guard let length = segmentLength(in: data, at: index) else {
        return nil
      }
      if isSOFMarker(marker) {
        return parseSOFSegment(data: data, index: index, length: length)
      }
      index += length
    }
    return nil
  }
}
