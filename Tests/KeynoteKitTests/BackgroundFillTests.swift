import Foundation
import IWAFraming
import KeynoteKit
import KeynoteKitProtobuf
import Testing

/// Background fill (#78): a fill mints the same type-2025 shape-style fork
/// that alignment and columns use, writing `TSD.FillArchive` into the
/// TSD-level property bag rather than the TSWP-level one.
///
/// `overrideCount` is a shared total across both bags — see
/// `research/findings/text_columns.md`.
@Suite("Background fill")
internal struct BackgroundFillTests {
  @Test("background mints a fill on the TSD-level property bag")
  internal func backgroundForksFill() throws {
    let surgeon = try ShapeStyleProbe.written(
      Deck {
        Slide {
          TextBox("Panel")
            .background(Color(red: 0.1, green: 0.12, blue: 0.16))
            .frame(width: 600, height: 300)
        }
      }
    )
    let fork = try ShapeStyleProbe.referencedShapeStyle(in: surgeon)
    let fill = fork.archive.super.shapeProperties.fill
    #expect(fork.archive.super.super.isVariation)
    #expect(fork.archive.super.shapeProperties.hasFill)
    #expect(fill.hasColor)
    #expect(fill.color.model == .rgb)
    #expect(fill.color.rgbspace == .srgb)
    #expect(abs(fill.color.r - 0.1) < 0.0001)
    #expect(abs(fill.color.g - 0.12) < 0.0001)
    #expect(abs(fill.color.b - 0.16) < 0.0001)
    #expect(abs(fill.color.a - 1) < 0.0001)
    try ShapeStyleProbe.expectRegistered(fork.identifier, in: surgeon)
  }

  @Test("a fill alone counts as one override on both levels")
  internal func backgroundCountsOneOverride() throws {
    let surgeon = try ShapeStyleProbe.written(
      Deck {
        Slide {
          TextBox("Panel").background(Color(red: 0, green: 0, blue: 0))
        }
      }
    )
    let fork = try ShapeStyleProbe.referencedShapeStyle(in: surgeon)
    // `overrideCount` is a shared total across both bags, mirrored into
    // both fields — every theme style in `build_action_B.key` writes them
    // equal, including fill-bearing variation 2651764 (4/4).
    #expect(fork.archive.overrideCount == 1)
    #expect(fork.archive.super.overrideCount == 1)
  }

  @Test("a fill composes with vertical alignment as two overrides")
  internal func backgroundComposesWithAlignment() throws {
    let surgeon = try ShapeStyleProbe.written(
      Deck {
        Slide {
          TextBox("Panel")
            .background(Color(red: 0.2, green: 0.2, blue: 0.2))
            .verticalAlignment(.middle)
        }
      }
    )
    let fork = try ShapeStyleProbe.referencedShapeStyle(in: surgeon)
    #expect(fork.archive.super.shapeProperties.hasFill)
    #expect(fork.archive.shapeProperties.verticalAlignment == .kFrameAlignMiddle)
    #expect(fork.archive.overrideCount == 2)
    #expect(fork.archive.super.overrideCount == 2)
  }

  @Test("an unfilled box writes no fill on the fork")
  internal func unsetBackgroundWritesNoFill() throws {
    let surgeon = try ShapeStyleProbe.written(
      Deck {
        Slide {
          TextBox("Aligned").verticalAlignment(.bottom)
        }
      }
    )
    let fork = try ShapeStyleProbe.referencedShapeStyle(in: surgeon)
    #expect(!fork.archive.super.shapeProperties.hasFill)
  }
}
