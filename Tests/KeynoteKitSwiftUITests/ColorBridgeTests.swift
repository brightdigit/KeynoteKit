import KeynoteKit
import KeynoteKitSwiftUI
import Testing

#if canImport(SwiftUI)
  import SwiftUI
#endif

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKit
#endif

/// Bridges from the platform color types into ``KeynoteKit/Color``.
///
/// The value under test is the sRGB *encoding*: SwiftUI resolves to linear
/// components, and writing those straight through renders washed out.
@Suite("Platform color bridges")
internal struct ColorBridgeTests {
  #if canImport(SwiftUI)
    @Test("a SwiftUI color converts to sRGB-encoded components")
    @available(macOS 14, iOS 17, tvOS 17, watchOS 10, visionOS 1, *)
    internal func swiftUIColorConverts() {
      let source = SwiftUI.Color(
        .sRGB,
        red: 0.25,
        green: 0.5,
        blue: 0.75,
        opacity: 0.5
      )
      let color = KeynoteColor(source)
      #expect(abs(color.red - 0.25) < 0.01)
      #expect(abs(color.green - 0.5) < 0.01)
      #expect(abs(color.blue - 0.75) < 0.01)
      #expect(abs(color.opacity - 0.5) < 0.01)
    }

    /// Guards the linear-to-sRGB step specifically. Mid-grey resolves to a
    /// linear component near 0.216; passed through unencoded it would land
    /// near 0.216 instead of 0.5, i.e. visibly darker.
    @Test("mid-grey encodes back to mid-grey, not its linear value")
    @available(macOS 14, iOS 17, tvOS 17, watchOS 10, visionOS 1, *)
    internal func midGreyRoundTrips() {
      let grey = KeynoteColor(SwiftUI.Color(.sRGB, white: 0.5, opacity: 1))
      #expect(abs(grey.red - 0.5) < 0.02)
      #expect(grey.red > 0.3)
    }

    @Test("opaque SwiftUI colors stay opaque")
    @available(macOS 14, iOS 17, tvOS 17, watchOS 10, visionOS 1, *)
    internal func opaqueStaysOpaque() {
      #expect(KeynoteColor(SwiftUI.Color.black).opacity == 1)
    }
  #endif

  #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    @Test("an NSColor in sRGB converts unchanged")
    internal func nsColorConverts() throws {
      let source = NSColor(
        srgbRed: 0.25,
        green: 0.5,
        blue: 0.75,
        alpha: 0.5
      )
      let color = try #require(source.keynoteColor)
      #expect(abs(color.red - 0.25) < 0.0001)
      #expect(abs(color.green - 0.5) < 0.0001)
      #expect(abs(color.blue - 0.75) < 0.0001)
      #expect(abs(color.opacity - 0.5) < 0.0001)
    }

    @Test("a pattern NSColor has no sRGB representation")
    internal func patternColorReturnsNil() {
      let pattern = NSColor(patternImage: NSImage(size: NSSize(width: 1, height: 1)))
      #expect(pattern.keynoteColor == nil)
    }
  #endif
}
