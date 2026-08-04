//
//  Spacer.swift
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

/// Flexible space that divides a stack's leftover room between its
/// neighbours.
///
/// A spacer only acts inside a **bounded** stack — one given
/// `.frame(width:height:)`. Without bounds there is no slack to divide, so
/// the spacer collapses to zero rather than erroring; that keeps an
/// unbounded stack usable and matches the fact that slides are
/// fixed-size canvases where explicit frames are normal.
///
/// Multiple spacers in one stack split the slack equally, as in SwiftUI.
public struct Spacer: SlideLayout {
  /// The layout node this spacer contributes.
  public var layoutNode: any LayoutNode { SpacerNode() }

  /// Creates a spacer.
  public init() {}
}
