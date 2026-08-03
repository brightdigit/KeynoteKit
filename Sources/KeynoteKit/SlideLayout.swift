//
//  SlideLayout.swift
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

/// Something a slide's content builder accepts: a drawable, a stack, a
/// spacer, or a padded wrapper.
///
/// Every conformer reduces to a ``LayoutNode``, and the whole tree resolves
/// to absolutely-positioned drawables at build time. Nothing in this
/// protocol reaches the archive — the surgeon only ever sees the resolved
/// `x`/`y` values, which is why stacks need no archive work at all.
public protocol SlideLayout: Sendable {
  /// The layout node this value contributes.
  var layoutNode: LayoutNode { get }
}

extension TextBox: SlideLayout {
  /// A text box is a positioned leaf.
  public var layoutNode: LayoutNode { .leaf(.text(self)) }
}

extension Image: SlideLayout {
  /// An image is a positioned leaf.
  public var layoutNode: LayoutNode { .leaf(.image(self)) }
}
