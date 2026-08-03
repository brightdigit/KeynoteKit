import Foundation
import IWAFraming
import KeynoteKit
import KeynoteKitProtobuf
import Testing

/// Vertical alignment + columns (#51 step 5): either setting mints one
/// type-2025 variation of the placeholder's style, repoints
/// `TSD.ShapeArchive.style`, and registers every edge. The column gap is a
/// fraction of the layout master's body width
/// (`research/findings/text_columns.md`).
@Suite("Shape style forks")
internal struct ShapeStyleTests {
  @Test("verticalAlignment mints a variation and repoints the shape style")
  internal func verticalAlignmentForks() throws {
    let surgeon = try ShapeStyleProbe.written(
      Deck {
        Slide {
          TextBox("Bottom").verticalAlignment(.bottom)
        }
      }
    )
    let fork = try ShapeStyleProbe.referencedShapeStyle(in: surgeon)
    #expect(fork.archive.super.super.isVariation)
    #expect(fork.archive.shapeProperties.verticalAlignment == .kFrameAlignBottom)
    #expect(fork.archive.overrideCount == 1)
    #expect(fork.archive.super.overrideCount == 1)
    #expect(fork.archive.super.hasShapeProperties)
    try ShapeStyleProbe.expectRegistered(fork.identifier, in: surgeon)
  }

  @Test("columns write count and the gap as a fraction of the master width")
  internal func columnsWriteCountAndGap() throws {
    let surgeon = try ShapeStyleProbe.written(
      Deck {
        Slide {
          // 41.25pt over the blank template's 825pt master body = 0.05,
          // the value Keynote itself wrote in build_action_B.key.
          TextBox("Columns").columns(2, gap: 41.25)
        }
      }
    )
    let fork = try ShapeStyleProbe.referencedShapeStyle(in: surgeon)
    let columns = fork.archive.shapeProperties.columns.equalColumns
    #expect(columns.count == 2)
    #expect(abs(columns.gap - 0.05) < 0.0001)
  }

  @Test("columns without a gap inherit the template gutter")
  internal func columnsWithoutGap() throws {
    let surgeon = try ShapeStyleProbe.written(
      Deck {
        Slide {
          TextBox("Columns").columns(3)
        }
      }
    )
    let fork = try ShapeStyleProbe.referencedShapeStyle(in: surgeon)
    let columns = fork.archive.shapeProperties.columns.equalColumns
    #expect(columns.count == 3)
    #expect(!columns.hasGap)
  }

  @Test("boxes without either setting keep the template shape style")
  internal func unsetKeepsTemplateStyle() throws {
    let baseline = try ShapeStyleProbe.written(
      Deck {
        Slide {
          TextBox("Bare")
        }
      }
    )
    let surgeon = try ShapeStyleProbe.written(
      Deck {
        Slide {
          TextBox("Plain").textAlignment(.center)
        }
      }
    )
    let baselineStyle = try ShapeStyleProbe.firstPlaceholder(in: baseline).super.super.style
      .identifier
    let unsetStyle = try ShapeStyleProbe.firstPlaceholder(in: surgeon).super.super.style.identifier
    #expect(unsetStyle == baselineStyle)
  }

  /// Issue #78's "existing decks are byte-unchanged" criterion, at the level
  /// the write path can actually guarantee: a fill-free deck mints a fork
  /// whose property bags are exactly what they were before #78 — an empty
  /// TSD bag and an unchanged override count.
  ///
  /// Whole-file byte identity is *not* the right assertion here: every
  /// `write(to:)` mints fresh UUIDs, so two writes of the same deck already
  /// differ byte-for-byte, independent of this change. The committed-golden
  /// comparison in `GoldenDifferentialTests` is the real cross-version gate.
  @Test("a fill-free deck mints the pre-#78 property bags")
  internal func noFillMintsUnchangedBags() throws {
    let surgeon = try ShapeStyleProbe.written(
      Deck {
        Slide {
          TextBox("Columns").columns(2, gap: 41.25).verticalAlignment(.bottom)
        }
      }
    )
    let fork = try ShapeStyleProbe.referencedShapeStyle(in: surgeon)
    #expect(fork.archive.super.hasShapeProperties)
    #expect(!fork.archive.super.shapeProperties.hasFill)
    let bag: [UInt8] = try fork.archive.super.shapeProperties.serializedBytes(partial: true)
    #expect(bag.isEmpty)
    #expect(fork.archive.overrideCount == 2)
    #expect(fork.archive.super.overrideCount == 2)
  }
}
