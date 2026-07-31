//
//  AcceptanceDeck.swift
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

import KeynoteKit

/// An acceptance deck: a public-DSL `Deck` written for the human Keynote
/// 15.3 open pass (`swift run AcceptanceDecks`).
///
/// PLAN Step 6's original five decks also have committed goldens under
/// `research/goldens/` and specs under `research/examples/`. Drawable-depth
/// decks (#3 / #37 / #38) are structural + human-open only — no Python
/// goldens yet.
package struct AcceptanceDeck: CustomStringConvertible, Sendable {
  /// Decks that match committed goldens / specs (golden-differential gate).
  package static let goldenBacked: [AcceptanceDeck] = [
    AcceptanceDeck(name: "bisect_in", buildCount: 1, deck: Deck { BisectInContent() }),
    AcceptanceDeck(name: "bisect_out", buildCount: 1, deck: Deck { BisectOutContent() }),
    AcceptanceDeck(name: "bisect_action", buildCount: 1, deck: Deck { BisectActionContent() }),
    AcceptanceDeck(
      name: "bisect_direction",
      buildCount: 0,
      deck: Deck { BisectDirectionContent() }
    ),
    AcceptanceDeck(
      name: "build_acceptance",
      buildCount: 3,
      deck: Deck { BuildAcceptanceContent() }
    ),
  ]

  /// Geometry / formatting / image decks for expanded #24 (no goldens).
  package static let drawableDepth: [AcceptanceDeck] = [
    AcceptanceDeck(
      name: "drawable_geometry",
      buildCount: 0,
      deck: Deck { DrawableGeometryContent() }
    ),
    AcceptanceDeck(
      name: "text_formatting",
      buildCount: 0,
      deck: Deck { TextFormattingContent() }
    ),
    AcceptanceDeck(
      name: "image_drawable",
      buildCount: 1,
      deck: Deck { ImageDrawableContent() }
    ),
  ]

  /// Mixed-formatting-runs deck for #40 (no goldens).
  package static let formattingRuns: [AcceptanceDeck] = [
    AcceptanceDeck(
      name: "text_runs",
      buildCount: 0,
      deck: Deck { TextRunsContent() }
    )
  ]

  /// Every deck `swift run AcceptanceDecks` writes.
  package static let all: [AcceptanceDeck] = goldenBacked + drawableDepth + formattingRuns

  /// The stem used for the output filename (`<name>.key`).
  package let name: String

  /// Expected build count for the UUID-map invariant.
  package let buildCount: Int

  /// The deck, expressed in the public DSL.
  package let deck: Deck

  package var description: String { name }

  /// Whether a committed golden / spec exists for differential tests.
  package var hasGolden: Bool {
    Self.goldenBacked.contains { $0.name == name }
  }

  /// Creates an acceptance deck.
  package init(name: String, buildCount: Int, deck: Deck) {
    self.name = name
    self.buildCount = buildCount
    self.deck = deck
  }
}
