//
//  Deck+MagicMove.swift
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

/// A `magicId` pairing that Keynote's Magic Move matcher cannot honor.
///
/// The file format stores no object correspondence
/// (`research/findings/magic_move_correspondence.md`): matching is a runtime
/// heuristic keyed on object type and content. Two drawables sharing a
/// `magicId` across a Magic Move boundary therefore must be emitted as the
/// same type with the same content — anything else silently fails to morph,
/// so it is rejected at write time instead.
public enum MagicMoveError: Error, Equatable, Sendable {
  /// The same `magicId` names two different drawable types across the pair.
  case typeMismatch(magicId: String, slideIndex: Int)

  /// The same `magicId` names drawables whose content differs — Keynote's
  /// matcher pairs by content, so these can never morph.
  case contentMismatch(magicId: String, slideIndex: Int)

  /// One slide declares the same `magicId` on more than one drawable.
  case duplicateMagicId(magicId: String, slideIndex: Int)
}

extension Deck {
  /// Validates every Magic Move pair's `magicId` declarations.
  ///
  /// For each adjacent slide pair whose outgoing slide (the first of the
  /// pair — Keynote plays the outgoing slide's transition) is Magic Move,
  /// drawables sharing a `magicId` must be the same type with the same
  /// content, so the emitted archives are matchable by Keynote's runtime
  /// heuristic. Geometry may differ freely — that difference is the motion.
  ///
  /// - Throws: ``MagicMoveError`` for an unmatchable declaration.
  internal func validateMagicMovePairs() throws {
    for index in slides.indices.dropLast()
    where slides[index].slideTransition?.effect == SlideTransition.magicMove.effect {
      let outgoing = try magicDrawables(of: slides[index], slideIndex: index)
      let incoming = try magicDrawables(of: slides[index + 1], slideIndex: index + 1)
      for (identifier, drawable) in outgoing {
        guard let partner = incoming[identifier] else {
          continue  // Unmatched objects fade, per the transition's policy.
        }
        try validatePair(drawable, partner, magicId: identifier, slideIndex: index)
      }
    }
  }

  /// One slide's drawables keyed by `magicId`, rejecting duplicates.
  private func magicDrawables(
    of slide: Slide,
    slideIndex: Int
  ) throws -> [String: SlideDrawable] {
    var drawables: [String: SlideDrawable] = [:]
    for item in slide.items {
      guard let identifier = item.magicIdentifier else {
        continue
      }
      guard drawables.updateValue(item, forKey: identifier) == nil else {
        throw MagicMoveError.duplicateMagicId(magicId: identifier, slideIndex: slideIndex)
      }
      drawables[identifier] = item
    }
    return drawables
  }

  /// Requires the pair to be matchable: same type, same content.
  private func validatePair(
    _ first: SlideDrawable,
    _ second: SlideDrawable,
    magicId: String,
    slideIndex: Int
  ) throws {
    switch (first, second) {
    case (.text(let outgoing), .text(let incoming)):
      guard effectiveText(of: outgoing) == effectiveText(of: incoming) else {
        throw MagicMoveError.contentMismatch(magicId: magicId, slideIndex: slideIndex)
      }
    case (.image(let outgoing), .image(let incoming)):
      guard outgoing.data == incoming.data else {
        throw MagicMoveError.contentMismatch(magicId: magicId, slideIndex: slideIndex)
      }
    default:
      throw MagicMoveError.typeMismatch(magicId: magicId, slideIndex: slideIndex)
    }
  }

  /// The string Keynote's matcher sees: the box's paragraphs joined.
  private func effectiveText(of text: TextBox) -> String {
    text.content
  }
}
