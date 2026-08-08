//
//  FlexibleExtent.swift
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

/// How far a drawable may grow along one axis.
///
/// The SwiftUI spelling is `.frame(maxWidth: .infinity)`, and this type is
/// what that `.infinity` resolves to. It stays a named type rather than a
/// bare `Double` so the fill sentinel never enters layout arithmetic: a
/// literal `Double.infinity` multiplied or subtracted anywhere in the
/// resolve pass would silently produce `nan` positions.
///
/// A fixed extent behaves exactly like today's `frame(width:height:)`. A
/// filling extent means "adopt whatever the parent proposes", which is
/// resolved during ``LayoutNode/resolve(in:origin:)`` — sizing itself stays
/// a bottom-up fold, since ``LayoutNode/size`` takes no bounds.
public enum FlexibleExtent: Equatable, Sendable {
  /// Fill the extent the parent proposes.
  case infinity

  /// Hold a constant extent, in points.
  case points(Double)

  /// Whether this extent expands into the proposal.
  internal var isFilling: Bool {
    self == .infinity
  }

  /// The authored constant, or `nil` when this extent fills.
  internal var fixedValue: Double? {
    switch self {
    case .infinity: nil
    case .points(let value): value
    }
  }

  /// Lets a bare number stand in for a fixed extent.
  public init(floatLiteral value: Double) {
    self = .points(value)
  }

  /// Lets a bare integer stand in for a fixed extent.
  public init(integerLiteral value: Int) {
    self = .points(Double(value))
  }
}

extension FlexibleExtent: ExpressibleByFloatLiteral {}

extension FlexibleExtent: ExpressibleByIntegerLiteral {}
