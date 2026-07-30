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
  /// Pixel size from a JPEG SOF marker, when present.
  internal static func dimensions(of data: [UInt8]) -> (width: Double, height: Double)? {
    guard data.count > 4, data[0] == 0xFF, data[1] == 0xD8 else {
      return nil
    }
    var index = 2
    while index + 9 < data.count {
      guard data[index] == 0xFF else {
        return nil
      }
      let marker = data[index + 1]
      if marker == 0xD9 || marker == 0xDA {
        return nil
      }
      let length = Int(data[index + 2]) << 8 | Int(data[index + 3])
      guard length >= 2, index + 2 + length <= data.count else {
        return nil
      }
      // SOF0–SOF3, SOF5–SOF7, SOF9–SOF11, SOF13–SOF15
      if marker >= 0xC0 && marker <= 0xCF, marker != 0xC4, marker != 0xC8, marker != 0xCC {
        let height = Int(data[index + 5]) << 8 | Int(data[index + 6])
        let width = Int(data[index + 7]) << 8 | Int(data[index + 8])
        return (Double(width), Double(height))
      }
      index += 2 + length
    }
    return nil
  }
}
