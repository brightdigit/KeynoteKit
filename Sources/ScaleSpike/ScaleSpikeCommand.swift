//
//  ScaleSpikeCommand.swift
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
import KeynoteKit

/// `swift run ScaleSpike [dir]` — the #63 scale spike.
///
/// The demo deck (#56) is 15–20 slides; the largest deck ever written or
/// tested is 3. This measures whether `Deck.write(to:)` stays cheap at that
/// scale, and — more usefully — *how the cost grows*.
///
/// There is no capacity cap to probe: `expandSlides`
/// (`KeynoteArchiveSurgeon+Supply.swift`) clones the last template slide
/// until the deck's count is met, and runs before the `slideCountMismatch`
/// guard, so that guard only fires when the deck is *smaller* than the
/// template. The open question is cost. `SlideCatalog.locate` is a full
/// nested scan over every member × record, and `SlideCatalog(members:)` is
/// reconstructed inside the `expandSlides` loop condition on every
/// iteration — roughly O(slides² × records).
///
/// A single 20-slide timing cannot distinguish "quadratic but small" from
/// "linear", so this sweeps a ladder of slide counts and reports the growth
/// exponent. Doubling the slide count multiplies a linear cost by ~2 and a
/// quadratic one by ~4.
@main
internal enum ScaleSpikeCommand {
  /// Slide counts to time, spanning the demo's 15–20 target.
  private static let ladder = [3, 5, 10, 15, 20]

  /// Timed writes per slide count; the median is reported.
  private static let repetitions = 3

  /// Times the ladder and prints a table plus the growth exponent.
  internal static func main() throws {
    let directory = outputDirectory()
    try FileManager.default.createDirectory(
      at: directory,
      withIntermediateDirectories: true
    )
    print("#63 scale spike — \(repetitions) writes per count, median reported")
    print("")
    print("slides  drawables  median(s)  bytes")
    var samples: [(slides: Int, seconds: Double)] = []
    for count in ladder {
      let deck = ScaleSpikeDeck.deck(slides: count)
      var timings: [Double] = []
      var size = 0
      for repetition in 0..<repetitions {
        let url = directory.appending(path: "scale-\(count)-\(repetition).key")
        let start = ContinuousClock.now
        try deck.write(to: url)
        timings.append(Double(start.duration(to: .now).components.attoseconds) / 1e18)
        size = (try? Data(contentsOf: url).count) ?? 0
        // Keep only the last write of the largest count for the human pass.
        if repetition < repetitions - 1 || count != ladder.last {
          try? FileManager.default.removeItem(at: url)
        }
      }
      let median = timings.sorted()[timings.count / 2]
      samples.append((count, median))
      let drawables = count * ScaleSpikeDeck.drawablesPerSlide
      print(
        "\(pad(count, 6))  \(pad(drawables, 9))  \(pad(seconds: median, 9))  \(size)"
      )
    }
    report(samples)
    print("")
    let kept = "scale-\(ladder.last ?? 0)-\(repetitions - 1).key"
    print("Kept for the human pass: \(directory.path)/\(kept)")
    print("Open it in Keynote 15.3 and confirm it renders (no crash, no repair).")
  }

  /// The first argument, or `scale-spike` in the current directory.
  private static func outputDirectory() -> URL {
    let arguments = CommandLine.arguments
    guard arguments.count > 1 else {
      return URL(filePath: "scale-spike", directoryHint: .isDirectory)
    }
    return URL(filePath: arguments[1], directoryHint: .isDirectory)
  }

  /// Prints the empirical growth exponent between the smallest and largest
  /// timed counts: `log(t₂/t₁) / log(n₂/n₁)`. ~1 is linear, ~2 quadratic.
  private static func report(_ samples: [(slides: Int, seconds: Double)]) {
    guard
      let first = samples.first,
      let last = samples.last,
      first.seconds > 0,
      first.slides != last.slides
    else {
      return
    }
    let exponent =
      log(last.seconds / first.seconds) / log(Double(last.slides) / Double(first.slides))
    print("")
    print(
      "growth exponent \(first.slides)→\(last.slides) slides: "
        + String(format: "%.2f", exponent)
        + "  (1 = linear, 2 = quadratic)"
    )
    let perSlide = last.seconds / Double(last.slides)
    print("per-slide cost at \(last.slides): " + String(format: "%.4f", perSlide) + "s")
  }

  /// Right-aligns an integer in `width` columns.
  private static func pad(_ value: Int, _ width: Int) -> String {
    String(repeating: " ", count: max(0, width - "\(value)".count)) + "\(value)"
  }

  /// Right-aligns a seconds value in `width` columns.
  private static func pad(seconds: Double, _ width: Int) -> String {
    let text = String(format: "%.4f", seconds)
    return String(repeating: " ", count: max(0, width - text.count)) + text
  }
}
