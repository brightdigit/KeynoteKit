//
//  BuildOptionValue.swift
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

/// One scalar in a build's sparse option bag, matching the shapes Python's
/// `deckkit._coerce_scalar` produces: bool, int, float, or string.
///
/// Equality is Python's: `.int` and `.double` compare by numeric value
/// (`1 == 1.0`), because JSON round-trips cannot reliably preserve the
/// int-versus-float distinction that Python's coercion draws from the
/// original YAML text.
package enum BuildOptionValue: Sendable {
  /// A boolean option, such as `customBounce`.
  case bool(Bool)

  /// An integer option, such as `eventTrigger`.
  case int(Int64)

  /// A floating-point option, such as `customTravelDistance`.
  case double(Double)

  /// A string option: enum names and delivery labels.
  case string(String)
}

extension BuildOptionValue: Equatable {
  /// The case's numeric value, when it has one.
  private var numericValue: Double? {
    switch self {
    case .int(let value): Double(value)
    case .double(let value): value
    default: nil
    }
  }

  /// `.int` and `.double` compare numerically, as in Python.
  package static func == (lhs: BuildOptionValue, rhs: BuildOptionValue) -> Bool {
    switch (lhs, rhs) {
    case (.bool(let left), .bool(let right)): left == right
    case (.string(let left), .string(let right)): left == right
    default: lhs.numericValue != nil && lhs.numericValue == rhs.numericValue
    }
  }
}

extension BuildOptionValue: Codable {
  package init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let bool = try? container.decode(Bool.self) {
      self = .bool(bool)
    } else if let int = try? container.decode(Int64.self) {
      self = .int(int)
    } else if let double = try? container.decode(Double.self) {
      self = .double(double)
    } else {
      self = .string(try container.decode(String.self))
    }
  }

  package func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .bool(let value): try container.encode(value)
    case .int(let value): try container.encode(value)
    case .double(let value): try container.encode(value)
    case .string(let value): try container.encode(value)
    }
  }
}
