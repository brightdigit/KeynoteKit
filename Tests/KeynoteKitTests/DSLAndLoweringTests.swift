import Foundation
import KeynoteKitProtobuf
import Testing

@testable import KeynoteKit

@Suite("DSL and Lowering Batch C")
internal struct DSLAndLoweringTests {
  @Test("PNGSize correctly extracts dimensions from valid PNG IHDR header")
  internal func pngSizeDetection() {
    var pngHeader: [UInt8] = [
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,  // Signature
      0x00, 0x00, 0x00, 0x0D,  // IHDR Length = 13
      0x49, 0x48, 0x44, 0x52,  // 'IHDR'
      0x00, 0x00, 0x03, 0x20,  // Width = 800
      0x00, 0x00, 0x02, 0x58,  // Height = 600
      0x08, 0x06, 0x00, 0x00, 0x00,  // Bit depth, color type, etc.
    ]
    let size = PNGSize.dimensions(of: pngHeader)
    #expect(size?.width == 800)
    #expect(size?.height == 600)

    // Truncated/invalid signatures return nil
    #expect(PNGSize.dimensions(of: Array(pngHeader.prefix(15))) == nil)
    pngHeader[0] = 0x00
    #expect(PNGSize.dimensions(of: pngHeader) == nil)
  }

  @Test("JPEGSize handles 0xFF padding bytes and guards length >= 7")
  internal func jpegSizePaddingAndGuard() {
    // Valid minimal JPEG SOI + APP0 + SOF0 (with extra 0xFF fill byte)
    let jpegBytes: [UInt8] = [
      0xFF, 0xD8,  // SOI
      0xFF, 0xFF, 0xC0,  // 0xFF fill byte then SOF0
      0x00, 0x0B,  // Segment length = 11 (>= 7)
      0x08,  // Precision = 8
      0x01, 0xE0,  // Height = 480
      0x02, 0x80,  // Width = 640
      0x03, 0x01, 0x11, 0x00, 0x02, 0x11, 0x00, 0x03,  // Components
    ]
    let size = JPEGSize.dimensions(of: jpegBytes)
    #expect(size?.width == 640)
    #expect(size?.height == 480)

    // Crafted SOF segment with length < 7 (e.g. 5) must be rejected
    var invalidJpeg = jpegBytes
    invalidJpeg[6] = 0x05  // length byte low
    #expect(JPEGSize.dimensions(of: invalidJpeg) == nil)
  }

  @Test("Image initializer detects PNG dimensions as fallback")
  internal func imageInitPngFallback() {
    let pngBytes: [UInt8] = [
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
      0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52,
      0x00, 0x00, 0x01, 0x00,  // Width = 256
      0x00, 0x00, 0x01, 0x00,  // Height = 256
      0x08, 0x06, 0x00, 0x00, 0x00,
    ]
    let image = Image(data: Data(pngBytes), fileExtension: "png")
    #expect(image.naturalWidth == 256)
    #expect(image.naturalHeight == 256)
  }

  @Test("SlideItemsBuilder supports if/else and optional elements", arguments: [true, false])
  internal func slideItemsBuilderControlFlow(showImage: Bool) {
    let always = SlideItemsBuilder.buildExpression(TextBox("always"))
    let imageBranch = SlideItemsBuilder.buildEither(
      first: SlideItemsBuilder.buildExpression(
        Image(data: Data(), fileExtension: "jpg")
      )
    )
    let elseBranch = SlideItemsBuilder.buildEither(
      second: SlideItemsBuilder.buildExpression(TextBox("else"))
    )
    let optionalItem = SlideItemsBuilder.buildOptional(
      !showImage ? SlideItemsBuilder.buildExpression(TextBox("optional")) : nil
    )
    let items = SlideItemsBuilder.buildBlock(
      always,
      showImage ? imageBranch : elseBranch,
      optionalItem
    )
    // The builder now collects `any SlideLayout`; resolving the nodes gives
    // back the drawables it used to return directly (#65).
    let drawables = items.flatMap { $0.layoutNode.resolve(in: nil, origin: nil) }
    if showImage {
      #expect(drawables.count == 2)
      if let box = drawables[0] as? TextBox {
        #expect(box.content == "always")
      } else {
        Issue.record("Expected text item first")
      }
      #expect(drawables[1] is Image)
    } else {
      #expect(drawables.count == 3)
    }
  }

  @Test(".action {} calls accumulate in declaration order")
  internal func actionAccumulatesInOrder() {
    let box = TextBox("motion")
      .action {
        MotionPath(points: [MotionPath.Point(x: 0, y: 0), MotionPath.Point(x: 100, y: 0)])
      }
      .action {
        MotionPath(points: [MotionPath.Point(x: 100, y: 0), MotionPath.Point(x: 100, y: 100)])
      }

    #expect(box.actions.count == 2)
    #expect(box.actions[0].nodes[1].position == MotionPath.Point(x: 100, y: 0))
    #expect(box.actions[1].nodes[1].position == MotionPath.Point(x: 100, y: 100))
  }

  @Test("MotionPath curved Node API creates bezier path source")
  internal func motionPathCurvedNodes() {
    let path = MotionPath(
      nodes: [
        MotionPath.Node(
          at: MotionPath.Point(x: 0, y: 0),
          controlOut: MotionPath.Point(x: 20, y: 10)
        ),
        MotionPath.Node(
          at: MotionPath.Point(x: 100, y: 50),
          controlIn: MotionPath.Point(x: 80, y: 40)
        ),
      ]
    )
    #expect(path.nodes.count == 2)
    #expect(path.naturalWidth == 100)
    #expect(path.naturalHeight == 50)
  }

  @Test("Magic Move validation checks paired drawables across slides")
  internal func magicMovePairValidation() throws {
    let validDeck = Deck {
      Slide {
        TextBox("Hello").magicId("hero")
      }
      .transition(.magicMove)
      Slide {
        TextBox("Hello").magicId("hero")
      }
    }
    let url = FileManager.default.temporaryDirectory
      .appending(path: "magic-\(UUID().uuidString).key")
    defer { try? FileManager.default.removeItem(at: url) }
    // Valid magic move pair should write without error
    try validDeck.write(to: url)

    // Mismatched type or content magic move pair should throw MagicMoveError
    let mismatchedDeck = Deck {
      Slide {
        TextBox("Hello").magicId("hero")
      }
      .transition(.magicMove)
      Slide {
        TextBox("Different Content").magicId("hero")
      }
    }
    #expect(throws: MagicMoveError.self) {
      try mismatchedDeck.write(to: url)
    }
  }

  @Test("M11: Target index in builds tracks declaration order even when zIndex permutes items")
  internal func zIndexReordersDrawablesWithoutAlteringBuildTargetIndices() throws {
    // Declarations: Item 0 = box0 (zIndex 10), Item 1 = box1 (zIndex 1)
    let slide = Slide {
      TextBox("item0")
        .zIndex(10)
        .build(.in) { Dissolve() }
      TextBox("item1")
        .zIndex(1)
        .build(.in) { Appear() }
    }
    let deck = Deck { slide }
    let authored = try deck.authoredDeck()
    let authoredSlide = authored.slides[0]

    // Builds stay in declaration order (builds[0] = item0, builds[1] = item1)
    // targetIndex points to the item's position in drawablesZOrder (item1 at 0, item0 at 1)
    #expect(authoredSlide.builds.count == 2)
    #expect(authoredSlide.builds[0].targetIndex == 1)
    #expect(authoredSlide.builds[1].targetIndex == 0)
  }

  @Test("TextRunsBuilder supports optional, if-else, and loop control flow")
  internal func textRunsBuilderControlFlow() {
    let includeSecond = true
    let includeThird = false
    let items = ["A", "B"]

    let box = TextBox {
      Text("First")
      if includeSecond {
        Text("Second")
      }
      if includeThird {
        Text("Third-First")
      } else {
        Text("Third-Else")
      }
      for item in items {
        Text(item)
      }
    }
    #expect(box.paragraphs.count == 5)
    let contents = box.paragraphs.map { $0.runs.map(\.content).joined() }
    #expect(contents == ["First", "Second", "Third-Else", "A", "B"])
  }
}
