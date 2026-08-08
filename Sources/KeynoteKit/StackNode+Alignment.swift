//
//  StackNode+Alignment.swift
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

extension StackNode {
  /// The initial offset along the main axis for alignment when no spacers exist.
  internal func initialMainOffset(in bounds: LayoutSize?, sizes: [LayoutSize]) -> Double {
    let spacerCount = children.count { $0 is SpacerNode }
    guard spacerCount == 0, let bounds else {
      return 0
    }
    let gaps = Double(max(0, children.count - 1)) * spacing
    let used =
      axis == .vertical
      ? sizes.map(\.height).reduce(0, +)
      : sizes.map(\.width).reduce(0, +)
    let available = axis == .vertical ? bounds.height : bounds.width
    let totalContentExtent = used + gaps
    switch mainAlignment {
    case .leading:
      return 0
    case .center:
      return (available - totalContentExtent) / 2
    case .trailing:
      return available - totalContentExtent
    }
  }

  /// Each spacer's share of the leftover space.
  ///
  /// Zero without bounds: there is no slack to divide, so a spacer is a
  /// documented no-op rather than an error.
  internal func spacerShare(sizes: [LayoutSize], bounds: LayoutSize?) -> Double {
    let spacerCount = children.count { $0 is SpacerNode }
    guard spacerCount > 0, let bounds else {
      return 0
    }
    let gaps = Double(max(0, children.count - 1)) * spacing
    let used =
      axis == .vertical
      ? sizes.map(\.height).reduce(0, +)
      : sizes.map(\.width).reduce(0, +)
    let available = axis == .vertical ? bounds.height : bounds.width
    return max(0, available - used - gaps) / Double(spacerCount)
  }

  /// The container extent on the cross axis, used for alignment.
  internal func crossExtent(sizes: [LayoutSize], bounds: LayoutSize?) -> Double {
    if let bounds {
      return axis == .vertical ? bounds.width : bounds.height
    }
    let extents = axis == .vertical ? sizes.map(\.width) : sizes.map(\.height)
    return extents.max() ?? 0
  }

  /// A child's offset on the cross axis for this stack's alignment.
  internal func crossOffset(childExtent: Double, containerExtent: Double) -> Double {
    switch alignment {
    case .leading: 0
    case .center: (containerExtent - childExtent) / 2
    case .trailing: containerExtent - childExtent
    }
  }
}
