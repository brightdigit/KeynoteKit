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
    let permutation = orderedPermutation(of: slide)
    let ordered = permutation.map { slide.items[$0] }
    let builds = collectedBuilds(from: slide, permutation: permutation)
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
  ///
  /// - Returns: Declaration offsets in z-order — position *p* of the result
  ///   names the declared item drawn at layer *p*.
  private func orderedPermutation(of slide: Slide) -> [Int] {
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
      .map(\.offset)
  }

  /// Flattens builds into delivery order: encounter order walking the slide
  /// builder (an item's builds in declaration order, then its action) —
  /// zIndex reorders layers, never the animation timeline. Each build's
  /// `targetIndex` maps through the permutation into the z-ordered list.
  private func collectedBuilds(from slide: Slide, permutation: [Int]) -> [AuthoredBuild] {
    var builds: [AuthoredBuild] = []
    for (offset, drawable) in slide.items.enumerated() {
      guard let targetIndex = permutation.firstIndex(of: offset) else {
        continue
      }
      for configuration in drawable.builds {
        builds.append(authoredBuild(from: configuration, targetIndex: targetIndex))
      }
      for action in drawable.actions {
        builds.append(authoredAction(from: action, targetIndex: targetIndex))
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
          color: text.color,
          listStyle: text.listStyle,
          runs: text.runs.map { run in
            AuthoredSlide.TextItem.Run(
              text: run.content,
              fontName: run.fontName,
              fontSize: run.fontSize,
              isBold: run.isBold,
              isItalic: run.isItalic,
              color: run.color
            )
          }
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
        nodes: path.nodes.map { node in
          AuthoredMotionPath.Node(
            point: AuthoredMotionPath.Point(x: node.position.x, y: node.position.y),
            controlIn: node.controlIn.map { AuthoredMotionPath.Point(x: $0.x, y: $0.y) },
            controlOut: node.controlOut.map { AuthoredMotionPath.Point(x: $0.x, y: $0.y) }
          )
        }
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
