//
//  TransitionEffect+Catalog.swift
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

extension TransitionEffect {
  /// Every transition effect Keynote 15.3's scripting dictionary declares,
  /// in dictionary order — 44 effects including ``none``.
  public static let catalog: [TransitionEffect] = [
    .none, .magicMove, .shimmer, .sparkle, .swing, .objectCube, .objectFlip,
    .objectPop, .objectPush, .objectRevolve, .objectZoom, .perspective,
    .clothesline, .confetti, .dissolve, .drop, .droplet, .fadeThroughColor,
    .grid, .iris, .moveIn, .push, .reveal, .`switch`, .wipe, .blinds,
    .colorPlanes, .cube, .doorway, .fall, .flip, .flop, .mosaic, .pageFlip,
    .pivot, .reflection, .revolvingDoor, .scale, .swap, .swoosh, .twirl,
    .twist, .fadeAndMove, .radialWipe,
  ]

  /// Looks up the cataloged effect for an archive (Cocoa) effect string.
  ///
  /// - Parameter archiveValue: The effect string as the `.key` archive or
  ///   the sdef Cocoa value spells it, for example `"apple:dissolve"`.
  /// - Returns: The matching effect, or `nil` for a string this catalog
  ///   does not know (for example one from a newer Keynote).
  public static func matching(archiveValue: String) -> TransitionEffect? {
    catalog.first { $0.archiveValue == archiveValue }
  }

  /// Resolves an archive effect string to its cataloged effect, or wraps an
  /// unknown string as an archive-only stand-in.
  ///
  /// The stand-in has an empty ``appleScriptName`` and a zero
  /// ``eventCode`` — only the ``archiveValue`` is meaningful, which is the
  /// identity the ScriptingBridge record path actually sends.
  ///
  /// - Parameter archiveValue: The effect string as the `.key` archive or
  ///   the sdef Cocoa value spells it.
  /// - Returns: The cataloged effect, or an archive-only stand-in.
  public static func resolving(archiveValue: String) -> TransitionEffect {
    matching(archiveValue: archiveValue)
      ?? TransitionEffect(
        appleScriptName: "",
        eventCode: AppleEventCode(rawValue: 0),
        archiveValue: archiveValue
      )
  }
}
