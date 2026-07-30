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

/// One of the five #24 acceptance decks: a committed spec stem
/// (`research/examples/<name>.json`, golden `research/goldens/<name>.key`)
/// paired with the same deck expressed in the public authoring DSL.
///
/// PLAN Step 6 requires the acceptance decks to go through the *public* API —
/// Action via `.action { MotionPath() }`, direction via the typed
/// `.direction(.moveInNonDefault)` — so these are hand-written DSL mirrors of
/// the committed specs, not decks loaded from the JSON.
package struct AcceptanceDeck: CustomStringConvertible, Sendable {
  /// The five acceptance decks (PLAN Step 6): the four bisect cases plus
  /// `build_acceptance`, in golden order.
  package static let all: [AcceptanceDeck] = [
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

  /// The spec stem shared with `research/examples/` and `research/goldens/`.
  package let name: String

  /// The number of builds the spec declares — the UUID-map invariant's
  /// expected count when verifying an authored copy.
  package let buildCount: Int

  /// The deck, expressed in the public DSL.
  package let deck: Deck

  package var description: String { name }

  /// Creates an acceptance deck.
  package init(name: String, buildCount: Int, deck: Deck) {
    self.name = name
    self.buildCount = buildCount
    self.deck = deck
  }
}
