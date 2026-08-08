//
//  Image.swift
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

import Foundation

/// An image drawable on a slide.
public struct Image: Sendable {
  /// The image file bytes.
  internal var data: [UInt8]

  /// Preferred file extension (`jpg`, `png`, …) for the `Data/` member.
  internal var fileExtension: String

  /// Pixel width when known.
  internal var naturalWidth: Double?

  /// Pixel height when known.
  internal var naturalHeight: Double?

  /// The item's x position (Python-parity default 200).
  internal var x: Double = 200

  /// The item's y position (Python-parity default 200).
  internal var y: Double = 200

  /// Authored width in points; `nil` uses natural width or 200.
  internal var width: Double?

  /// Authored height in points; `nil` uses natural height or 200.
  internal var height: Double?

  /// Which axes expand into the bounds an enclosing stack proposes.
  internal var flexible: FlexibleAxes = .none

  /// Layer order; higher values draw above lower ones. `nil` means 0.
  internal var zIndex: Int?

  /// The Magic Move pairing id, when set (compile-time only).
  internal var magicIdentifier: String?

  /// The item's builds, in declaration (= delivery) order.
  internal var builds: [BuildEffectConfiguration] = []

  /// The item's actions, in declaration (= delivery) order.
  internal var actions: [MotionPath] = []

  /// Creates an image from file bytes.
  ///
  /// - Parameters:
  ///   - data: The encoded image bytes (JPEG or PNG).
  ///   - fileExtension: Extension used in the zip `Data/` path.
  ///   - naturalWidth: Pixel width override.
  ///   - naturalHeight: Pixel height override.
  public init(
    data: Data,
    fileExtension: String = "jpg",
    naturalWidth: Double? = nil,
    naturalHeight: Double? = nil
  ) {
    self.data = Array(data)
    self.fileExtension = fileExtension
    let detected = JPEGSize.dimensions(of: self.data) ?? PNGSize.dimensions(of: self.data)
    self.naturalWidth = naturalWidth ?? detected?.width
    self.naturalHeight = naturalHeight ?? detected?.height
  }

  /// Creates an image by reading `url`.
  public init(contentsOf url: URL) throws {
    let data = try Data(contentsOf: url)
    let ext = url.pathExtension.isEmpty ? "jpg" : url.pathExtension.lowercased()
    self.init(data: data, fileExtension: ext)
  }

  /// Positions the item on the slide.
  public func position(x: Double, y: Double) -> Image {
    var image = self
    image.x = x
    image.y = y
    return image
  }

  /// Sets the image's extent, letting either axis fill the proposed bounds.
  ///
  /// `.infinity` on an axis adopts whatever an enclosing stack proposes.
  /// The image's natural pixel size still applies to any axis left unset.
  public func frame(maxWidth: FlexibleExtent? = nil, maxHeight: FlexibleExtent? = nil) -> Image {
    var image = self
    image.width = maxWidth?.fixedValue ?? image.width
    image.height = maxHeight?.fixedValue ?? image.height
    image.flexible = FlexibleAxes(
      width: maxWidth?.isFilling ?? image.flexible.width,
      height: maxHeight?.isFilling ?? image.flexible.height
    )
    return image
  }

  /// Sets the image's extent, filling one axis and fixing the other.
  public func frame(maxWidth: FlexibleExtent, height: Double) -> Image {
    frame(maxWidth: maxWidth, maxHeight: .points(height))
  }

  /// Sets the image's extent, fixing one axis and filling the other.
  public func frame(width: Double, maxHeight: FlexibleExtent) -> Image {
    frame(maxWidth: .points(width), maxHeight: maxHeight)
  }

  /// Sets only the image's height, leaving the width to the natural size.
  public func frame(height: Double) -> Image {
    frame(maxHeight: .points(height))
  }

  /// Sets only the image's width, leaving the height to the natural size.
  public func frame(width: Double) -> Image {
    frame(maxWidth: .points(width))
  }

  /// Sets the item's size on the slide.
  public func frame(width: Double, height: Double) -> Image {
    var image = self
    image.width = width
    image.height = height
    return image
  }

  /// Sets the item's layer order.
  public func zIndex(_ index: Int) -> Image {
    var image = self
    image.zIndex = index
    return image
  }

  /// Tags the item for Magic Move pairing.
  public func magicId(_ identifier: String) -> Image {
    var image = self
    image.magicIdentifier = identifier
    return image
  }

  /// Adds builds of `phase` to the item, in declaration order.
  public func build(
    _ phase: BuildPhase,
    @BuildEffectsBuilder _ effects: () -> [BuildEffectConfiguration]
  ) -> Image {
    var image = self
    for var configuration in effects() {
      configuration.phase = phase
      image.builds.append(configuration)
    }
    return image
  }

  /// Adds an Action build (a motion path) to the item. Repeated calls
  /// accumulate in declaration order, like ``build(_:_:)``.
  public func action(_ path: () -> MotionPath) -> Image {
    var image = self
    image.actions.append(path())
    return image
  }
}
