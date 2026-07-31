//
//  AuthoredSlide.swift
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

/// One slide's authored content, positionally matched to a base slide.
package struct AuthoredSlide: Equatable, Sendable {
  /// A text item's content and position, applied to the slide's drawables
  /// in order. Empty means "leave the base slide's items untouched" (the
  /// golden differential path).
  package struct TextItem: Equatable, Sendable {
    /// The string content.
    package var text: String

    /// The x position.
    package var x: Double

    /// The y position.
    package var y: Double

    /// Authored width; `nil` leaves the template size.
    package var width: Double?

    /// Authored height; `nil` leaves the template size.
    package var height: Double?

    /// Authored font family; `nil` leaves the template style.
    package var fontName: String?

    /// Authored font size; `nil` leaves the template style.
    package var fontSize: Double?

    /// Authored bold; `nil` leaves the template style.
    package var isBold: Bool?

    /// Authored italic; `nil` leaves the template style.
    package var isItalic: Bool?

    /// Authored sRGB color; `nil` leaves the template style.
    package var color: TextColor?

    /// Whether any formatting field is set.
    package var hasFormatting: Bool {
      fontName != nil || fontSize != nil || isBold != nil || isItalic != nil || color != nil
    }

    /// Creates a text item.
    package init(
      text: String,
      x: Double,
      y: Double,
      width: Double? = nil,
      height: Double? = nil,
      fontName: String? = nil,
      fontSize: Double? = nil,
      isBold: Bool? = nil,
      isItalic: Bool? = nil,
      color: TextColor? = nil
    ) {
      self.text = text
      self.x = x
      self.y = y
      self.width = width
      self.height = height
      self.fontName = fontName
      self.fontSize = fontSize
      self.isBold = isBold
      self.isItalic = isItalic
      self.color = color
    }
  }

  /// An image drawable's bytes and geometry.
  package struct ImageItem: Equatable, Sendable {
    /// Encoded image bytes.
    package var data: [UInt8]

    /// Zip / preferred filename extension.
    package var fileExtension: String

    /// The x position.
    package var x: Double

    /// The y position.
    package var y: Double

    /// Authored width in points.
    package var width: Double?

    /// Authored height in points.
    package var height: Double?

    /// Pixel width when known.
    package var naturalWidth: Double?

    /// Pixel height when known.
    package var naturalHeight: Double?

    /// Creates an image item.
    package init(
      data: [UInt8],
      fileExtension: String,
      x: Double,
      y: Double,
      width: Double? = nil,
      height: Double? = nil,
      naturalWidth: Double? = nil,
      naturalHeight: Double? = nil
    ) {
      self.data = data
      self.fileExtension = fileExtension
      self.x = x
      self.y = y
      self.width = width
      self.height = height
      self.naturalWidth = naturalWidth
      self.naturalHeight = naturalHeight
    }
  }

  /// One authored drawable in z-order / build-target order.
  package enum DrawableItem: Equatable, Sendable {
    /// A text placeholder.
    case text(TextItem)

    /// An image drawable.
    case image(ImageItem)
  }

  /// A transition's authored fields (direction travels separately in
  /// ``transitionDirection`` to keep the #20 golden path byte-stable).
  package struct Transition: Equatable, Sendable {
    /// The raw archive effect string.
    package var effect: String

    /// Seconds.
    package var duration: Double

    /// Seconds.
    package var delay: Double

    /// Whether the slide auto-advances.
    package var autoAdvance: Bool

    /// Creates a transition.
    package init(effect: String, duration: Double, delay: Double, autoAdvance: Bool) {
      self.effect = effect
      self.duration = duration
      self.delay = delay
      self.autoAdvance = autoAdvance
    }
  }

  /// The number of drawables the spec declares; must equal the base
  /// slide's `drawablesZOrder` count (drawable order is target order).
  package var itemCount: Int

  /// The slide transition's direction ordinal, when the spec sets one —
  /// the only transition field archive surgery touches.
  package var transitionDirection: UInt32?

  /// The slide's builds, in delivery order.
  package var builds: [AuthoredBuild]

  /// The drawables to write, in order. Empty means "leave the base slide's
  /// items untouched" (the golden differential path).
  package var items: [DrawableItem]

  /// The transition to author, when the deck sets one.
  package var transition: Transition?

  /// Creates a slide.
  package init(
    itemCount: Int,
    transitionDirection: UInt32? = nil,
    builds: [AuthoredBuild] = [],
    items: [DrawableItem] = [],
    transition: Transition? = nil
  ) {
    self.itemCount = itemCount
    self.transitionDirection = transitionDirection
    self.builds = builds
    self.items = items
    self.transition = transition
  }
}
