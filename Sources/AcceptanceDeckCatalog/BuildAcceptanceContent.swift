//
//  BuildAcceptanceContent.swift
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

/// `research/examples/build_acceptance.json`: slide one carries three ordered
/// builds — In Dissolve, Out Dissolve, then an Action motion path — one per
/// text item; slide two carries the directed Move In transition. Delivery
/// order is encounter order, matching the spec's build list.
package struct BuildAcceptanceContent: SlideContent {
  @SlideBuilder package var body: some SlideContent {
    Slide {
      Text("Build In")
        .position(x: 200, y: 180)
        .build(.in) {
          Dissolve()
            .duration(1)
        }
      Text("Build Out")
        .position(x: 200, y: 360)
        .build(.out) {
          Dissolve()
            .duration(1)
        }
      Text("Move Action")
        .position(x: 200, y: 540)
        .action {
          MotionPath()
            .duration(1)
        }
    }
    Slide {
      Text("Directed Move In")
        .position(x: 200, y: 250)
    }
    .transition(
      .moveIn
        .duration(1)
        .delay(0.5)
        .direction(.moveInNonDefault)
    )
  }

  /// Creates the content.
  package init() {}
}
