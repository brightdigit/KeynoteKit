import Testing

@testable import KeynoteKitScripting

@Suite("ExportFormat")
internal struct ExportFormatTests {
  @Test("catalog carries every Keynote 15.3 export format")
  internal func catalogIsComplete() {
    #expect(ExportFormat.catalog.count == 6)
    #expect(Set(ExportFormat.catalog.map(\.eventCode)).count == 6)
  }

  @Test("formats lower to their sdef identities")
  internal func formatsLower() {
    #expect(ExportFormat.pdf.eventCode == AppleEventCode("Kpdf"))
    #expect(ExportFormat.pdf.cocoaValue == "com.apple.iWork.Keynote.exportPDF")
    #expect(ExportFormat.quickTimeMovie.eventCode == AppleEventCode("Kmov"))
    #expect(ExportFormat.microsoftPowerPoint.eventCode == AppleEventCode("Kppt"))
    #expect(ExportFormat.slideImages.appleScriptName == "slide images")
  }
}
