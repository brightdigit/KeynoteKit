#if canImport(ScriptingBridge)
  import Foundation
  import Testing

  @testable import KeynoteKitScripting

  /// Whether the environment opts in to driving a real Keynote.
  private var liveKeynoteEnabled: Bool {
    ProcessInfo.processInfo.environment["KEYNOTEKIT_LIVE_KEYNOTE"] == "1"
  }

  // Integration against a real, running Keynote. SKIPPED unless
  // KEYNOTEKIT_LIVE_KEYNOTE=1 is exported: these tests launch Keynote, send
  // it Apple events, and require Automation (TCC) permission, none of which
  // belongs in a default `swift test` run (or on CI, which has no Keynote).
  @Suite("Live Keynote", .enabled(if: liveKeynoteEnabled), .serialized)
  internal struct LiveKeynoteTests {
    @Test("authors, saves, exports, and reads back a transition")
    internal func authorsSavesExportsAndReadsBack() throws {
      let application = try KeynoteScriptingApplication()
      let document = try application.makeDocument()

      let slide = try document.makeSlide(baseLayoutNamed: "Blank")
      let textItem = try slide.makeTextItem(text: "Hello from KeynoteKitScripting")
      try textItem.setPosition(x: 200, y: 200)

      let settings = TransitionSettings(
        effect: .dissolve,
        duration: 1.5,
        delay: 0.5,
        isAutomatic: false
      )
      try slide.applyTransitionSettings(settings)
      let readBack = try slide.transitionSettings()
      #expect(readBack.effect == .dissolve)
      #expect(readBack.duration == 1.5)

      let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("keynotekit-live-\(UUID().uuidString)", isDirectory: true)
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      defer { try? FileManager.default.removeItem(at: directory) }

      let keyURL = directory.appendingPathComponent("live.key")
      try document.save(to: keyURL)
      #expect(FileManager.default.fileExists(atPath: keyURL.path))

      let pdfURL = directory.appendingPathComponent("live.pdf")
      try document.export(to: pdfURL, format: .pdf)
      #expect(FileManager.default.fileExists(atPath: pdfURL.path))

      try document.close(.notSaving)
    }
  }
#endif
