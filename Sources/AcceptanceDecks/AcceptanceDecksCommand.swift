//
//  AcceptanceDecksCommand.swift
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

import AcceptanceDeckCatalog
import Foundation
import IWAFraming
import KeynoteKit
import KeynoteKitProtobuf

/// Writes the #24 acceptance decks for the human pass:
/// `swift run AcceptanceDecks [output-directory]` (default `acceptance-decks`).
///
/// Each deck is authored through the public DSL from the bundled template and
/// self-checked before the tool reports it: every record must decode and both
/// SIGTRAP invariants must hold. The Keynote 15.3 open pass stays human —
/// structural correctness does not imply Keynote will open the file
/// (PLAN Step 6).
@main
internal enum AcceptanceDecksCommand {
  /// The per-deck checklist from PLAN Step 6 + drawable depth, printed for
  /// the human pass.
  private static let checklist = """

    Human pass (#24) — open each deck in Keynote 15.3 by hand and confirm:
      Original five:
        1. no crash
        2. no repair warning — a silent "repair" is a failure, not a pass
        3. In/Out/Action builds, ordering, and the transition direction survived
      Drawable depth:
        - drawable_geometry.key — Magic Move grows "Alpha" (size + position)
        - text_formatting.key — "Styled" is large red bold-italic; neighbor plain
        - image_drawable.key — image present; Dissolve In on the image plays
      Mixed runs (#40):
        - text_runs.key — ONE box: "Bold red" large bold red, "italic" italic,
          spans between plain; neighbor box whole-item bold
      Text layout (#51):
        - text_layout.key — slide 1: plain / "•" / "→" / numbered lists;
          slide 2: left, centered, right, indented, first-line-indented
          paragraphs; slide 3: TOP / MIDDLE / BOTTOM; slides 4-5: 2- and
          3-column flows with a visible gutter; slide 6: three rotated boxes
        - Acceptance.key — the three bare boxes stay bullet-free
      Monospace probe (#64) — spike evidence, NOT a tag gate:
        - monospace_probe.key — slides 1-4 (Menlo, SF Mono, Courier New,
          Monaco): iiii / MMMM / 1111 must be the SAME WIDTH — right edges
          form a clean column. Ragged edges = Keynote substituted a
          proportional face; that family is rejected.
        - slide 5 — leading-space indentation holds its columns.
        - Record results in research/findings/monospace_probe.md.
    Tag v0.1.0 when all decks are green.
    """

  /// Writes and self-checks every acceptance deck, then prints the checklist.
  internal static func main() throws {
    let directory = outputDirectory()
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    for acceptance in AcceptanceDeck.all {
      let url = directory.appending(path: "\(acceptance.name).key")
      try acceptance.deck.write(to: url)
      try verify(url: url, buildCount: acceptance.buildCount)
      print("wrote \(url.path)")
    }
    print(checklist)
  }

  /// The first command-line argument, or `acceptance-decks` in the current
  /// directory.
  private static func outputDirectory() -> URL {
    let arguments = CommandLine.arguments
    guard arguments.count > 1 else {
      return URL(filePath: "acceptance-decks", directoryHint: .isDirectory)
    }
    return URL(filePath: arguments[1], directoryHint: .isDirectory)
  }

  /// Reopens a written deck and applies the structural gates: every record
  /// decodes; the UUID-map invariants hold for the expected build count.
  private static func verify(url: URL, buildCount: Int) throws {
    let bundle = try KeyBundle(contentsOfZip: Array(try Data(contentsOf: url)))
    let surgeon = try KeynoteArchiveSurgeon(bundle: bundle)
    for member in surgeon.members {
      for record in member.records {
        _ = try record.decodedMessages()
      }
    }
    try UUIDMapVerifier.verify(members: surgeon.members, expectedBuildCount: buildCount)
  }
}
