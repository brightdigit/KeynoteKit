//
//  Deck+Lowering.swift
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

extension Deck {
  /// Lowers the public DSL to the surgeon's model. Delivery order is
  /// encounter order walking each slide's items: an item's builds in
  /// declaration order, then its action.
  internal func authoredDeck() -> AuthoredDeck {
    AuthoredDeck(slides: slides.map(authoredSlide(from:)))
  }

  /// Lowers one slide.
  private func authoredSlide(from slide: Slide) -> AuthoredSlide {
    let ordered = orderedDrawables(from: slide)
    touchMagicIdentifiers(in: ordered)
    let builds = collectedBuilds(from: ordered)
    let transition = slide.slideTransition.map { value in
      AuthoredSlide.Transition(
        effect: value.effect,
        duration: value.durationSeconds,
        delay: value.delaySeconds,
        autoAdvance: value.autoAdvances
      )
    }
    return AuthoredSlide(
      itemCount: ordered.count,
      transitionDirection: slide.slideTransition?.directionOrdinal,
      builds: builds,
      items: ordered.map(authoredDrawable(from:)),
      transition: transition
    )
  }

  /// Layer order = drawablesZOrder = build targetIndex. Higher zIndex draws
  /// above; declaration order breaks ties (and is the default when unset).
  private func orderedDrawables(from slide: Slide) -> [SlideDrawable] {
    slide.items
      .enumerated()
      .sorted { left, right in
        let leftIndex = left.element.zIndex
        let rightIndex = right.element.zIndex
        if leftIndex != rightIndex {
          return leftIndex < rightIndex
        }
        return left.offset < right.offset
      }
      .map(\.element)
  }

  /// `.magicId` is authoring-time only — Keynote stores no correspondence
  /// (`magic_move_correspondence.md`). Touch the values so the IR keeps them.
  private func touchMagicIdentifiers(in drawables: [SlideDrawable]) {
    for drawable in drawables {
      switch drawable {
      case .text(let text): _ = text.magicIdentifier
      case .image(let image): _ = image.magicIdentifier
      }
    }
  }

  /// Flattens each drawable's builds then action into delivery order.
  private func collectedBuilds(from drawables: [SlideDrawable]) -> [AuthoredBuild] {
    var builds: [AuthoredBuild] = []
    for (index, drawable) in drawables.enumerated() {
      for configuration in drawable.builds {
        builds.append(authoredBuild(from: configuration, targetIndex: index))
      }
      if let action = drawable.action {
        builds.append(authoredAction(from: action, targetIndex: index))
      }
    }
    return builds
  }

  /// Lowers one drawable.
  private func authoredDrawable(from drawable: SlideDrawable) -> AuthoredSlide.DrawableItem {
    switch drawable {
    case .text(let text):
      .text(
        AuthoredSlide.TextItem(
          text: text.content,
          x: text.x,
          y: text.y,
          width: text.width,
          height: text.height,
          fontName: text.fontName,
          fontSize: text.fontSize,
          isBold: text.isBold,
          isItalic: text.isItalic,
          color: text.color
        )
      )
    case .image(let image):
      .image(
        AuthoredSlide.ImageItem(
          data: image.data,
          fileExtension: image.fileExtension,
          x: image.x,
          y: image.y,
          width: image.width,
          height: image.height,
          naturalWidth: image.naturalWidth,
          naturalHeight: image.naturalHeight
        )
      )
    }
  }

  /// Lowers one In/Out build.
  private func authoredBuild(
    from configuration: BuildEffectConfiguration,
    targetIndex: Int
  ) -> AuthoredBuild {
    AuthoredBuild(
      kind: configuration.phase == .in ? .buildIn : .buildOut,
      effect: configuration.effect,
      duration: configuration.duration,
      delay: configuration.delay,
      targetIndex: targetIndex,
      direction: configuration.direction,
      trigger: authoredTrigger(from: configuration.trigger)
    )
  }

  /// Lowers one Action build.
  private func authoredAction(from path: MotionPath, targetIndex: Int) -> AuthoredBuild {
    AuthoredBuild(
      kind: .action,
      effect: "apple:action-motion-path",
      duration: path.duration,
      delay: path.delay,
      targetIndex: targetIndex,
      motionPath: AuthoredMotionPath(
        naturalWidth: path.naturalWidth,
        naturalHeight: path.naturalHeight,
        points: path.points.map { AuthoredMotionPath.Point(x: $0.x, y: $0.y) }
      ),
      trigger: authoredTrigger(from: path.trigger)
    )
  }

  /// Lowers a trigger.
  private func authoredTrigger(from trigger: BuildTrigger) -> AuthoredBuild.Trigger {
    switch trigger {
    case .onClick: .onClick
    case .afterPrevious: .afterPrevious
    case .withPrevious: .withPrevious
    }
  }
}
