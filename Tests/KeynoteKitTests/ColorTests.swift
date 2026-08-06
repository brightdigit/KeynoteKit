import KeynoteKit
import Testing

#if canImport(CoreGraphics)
  import CoreGraphics
#endif

/// ``Color`` — the authoring color shared by text and shape fills.
@Suite("Color")
internal struct ColorTests {
  @Test("components are clamped into 0...1")
  internal func componentsClamp() {
    let over = Color(red: 2, green: -1, blue: 0.5, opacity: 9)
    #expect(over.red == 1)
    #expect(over.green == 0)
    #expect(over.blue == 0.5)
    #expect(over.opacity == 1)
  }

  @Test("white: sets every channel and defaults to opaque")
  internal func whiteConvenience() {
    let grey = Color(white: 0.25)
    #expect(grey.red == 0.25)
    #expect(grey.green == 0.25)
    #expect(grey.blue == 0.25)
    #expect(grey.opacity == 1)
  }

  @Test("default argument initializers default components to 0 and opacity to 1")
  internal func defaultArguments() {
    let defaultRed = Color(red: 0.5)
    #expect(defaultRed.red == 0.5)
    #expect(defaultRed.green == 0)
    #expect(defaultRed.blue == 0)
    #expect(defaultRed.opacity == 1)

    let defaultGreen = Color(green: 0.5)
    #expect(defaultGreen.red == 0)
    #expect(defaultGreen.green == 0.5)
    #expect(defaultGreen.blue == 0)
    #expect(defaultGreen.opacity == 1)

    let defaultBlue = Color(blue: 0.5)
    #expect(defaultBlue.red == 0)
    #expect(defaultBlue.green == 0)
    #expect(defaultBlue.blue == 0.5)
    #expect(defaultBlue.opacity == 1)

    let defaultWhite = Color(white: 0)
    #expect(defaultWhite.red == 0)
    #expect(defaultWhite.green == 0)
    #expect(defaultWhite.blue == 0)
    #expect(defaultWhite.opacity == 1)
  }

  @Test("opacity(_:) returns a copy, leaving the receiver alone")
  internal func opacityModifier() {
    let opaque = Color(red: 0.2, green: 0.4, blue: 0.6)
    let faded = opaque.opacity(0.3)
    #expect(faded.opacity == 0.3)
    #expect(opaque.opacity == 1)
    #expect(faded.red == opaque.red)
  }

  @Test("named colors are the expected sRGB values")
  internal func namedColors() {
    #expect(Color.black == Color(red: 0, green: 0, blue: 0))
    #expect(Color.white == Color(red: 1, green: 1, blue: 1))
    #expect(Color.clear.opacity == 0)
  }

  #if canImport(CoreGraphics)
    @Test("a CGColor already in sRGB round-trips unchanged")
    internal func cgColorRoundTrips() throws {
      let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
      let source = try #require(
        CGColor(colorSpace: space, components: [0.25, 0.5, 0.75, 0.5])
      )
      let color = try #require(Color(cgColor: source))
      #expect(abs(color.red - 0.25) < 0.0001)
      #expect(abs(color.green - 0.5) < 0.0001)
      #expect(abs(color.blue - 0.75) < 0.0001)
      #expect(abs(color.opacity - 0.5) < 0.0001)
    }

    /// A grey in a non-sRGB space must be *converted*, not reinterpreted:
    /// 50% grey in a linear space is not 0.5 in sRGB.
    @Test("a CGColor in another space is converted rather than reinterpreted")
    internal func cgColorConverts() throws {
      let linear = try #require(CGColorSpace(name: CGColorSpace.linearSRGB))
      let source = try #require(
        CGColor(colorSpace: linear, components: [0.5, 0.5, 0.5, 1])
      )
      let color = try #require(Color(cgColor: source))
      // sRGB-encoding linear 0.5 lands near 0.735, well clear of 0.5.
      #expect(color.red > 0.7)
      #expect(color.red < 0.77)
    }
  #endif
}
