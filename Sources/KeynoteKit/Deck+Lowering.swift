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
    var builds: [AuthoredBuild] = []
    for (index, text) in slide.items.enumerated() {
      for configuration in text.builds {
        builds.append(authoredBuild(from: configuration, targetIndex: index))
      }
      if let action = text.action {
        builds.append(authoredAction(from: action, targetIndex: index))
      }
    }
    let transition = slide.slideTransition.map { value in
      AuthoredSlide.Transition(
        effect: value.effect,
        duration: value.durationSeconds,
        delay: value.delaySeconds,
        autoAdvance: value.autoAdvances
      )
    }
    return AuthoredSlide(
      itemCount: slide.items.count,
      transitionDirection: slide.slideTransition?.directionOrdinal,
      builds: builds,
      items: slide.items.map { AuthoredSlide.TextItem(text: $0.content, x: $0.x, y: $0.y) },
      transition: transition
    )
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
