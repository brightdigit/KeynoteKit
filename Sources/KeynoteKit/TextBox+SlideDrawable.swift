//
//  TextBox+SlideDrawable.swift
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

extension TextBox: SlideDrawable {
  /// Builds attached to this drawable.
  public var drawableBuilds: [BuildEffectConfiguration] { builds }

  /// Action builds attached to this drawable.
  public var drawableActions: [MotionPath] { actions }

  /// The Magic Move pairing declaration.
  public var drawableMagicIdentifier: String? { magicIdentifier }

  /// Layer order, with an undeclared index normalized to 0.
  public var layerOrder: Int { zIndex ?? 0 }

  /// The drawable's current position.
  public var authoredPosition: LayoutPoint { LayoutPoint(x: x, y: y) }

  /// The authored size; either axis may be unset.
  public var authoredSize: DrawableSize {
    DrawableSize(width: width, height: height)
  }

  /// Which axes expand into the proposed bounds.
  public var flexibleAxes: FlexibleAxes { flexible }

  /// Text matches on its joined paragraphs — the string Keynote's matcher
  /// sees. Styling is excluded: restyling a box across a Magic Move pair
  /// still morphs.
  public var magicMoveIdentity: MagicMoveIdentity {
    MagicMoveIdentity(kind: "text", content: .text(content))
  }

  /// Returns a copy positioned at `x`, `y`.
  public func positioned(x: Double, y: Double) -> any SlideDrawable {
    position(x: x, y: y)
  }

  /// Returns a copy sized to `width` by `height`; a `nil` axis is untouched.
  public func resized(width: Double?, height: Double?) -> any SlideDrawable {
    var text = self
    text.width = width ?? text.width
    text.height = height ?? text.height
    return text
  }
}

extension TextBox: LowerableDrawable {
  /// Lowers this box into the writer's representation.
  package func lowered() -> AuthoredSlide.DrawableItem {
    .text(
      AuthoredSlide.TextItem(
        x: x,
        y: y,
        width: width,
        height: height,
        fontName: fontName,
        fontSize: fontSize,
        isBold: isBold,
        isItalic: isItalic,
        color: color,
        listStyle: listStyle,
        rotation: rotation,
        textAlignment: textAlignment,
        verticalAlignment: verticalAlignment,
        columnCount: columnCount,
        columnGap: columnGap,
        background: background,
        paragraphs: paragraphs.map { $0.lowered() }
      )
    )
  }
}
