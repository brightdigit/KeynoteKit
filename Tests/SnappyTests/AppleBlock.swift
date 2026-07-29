/// A Snappy block captured from a real Keynote `.iwa` component.
internal struct AppleBlock: Sendable, CustomStringConvertible {
  /// Which fixture and component the block came from.
  internal let origin: String

  /// The uncompressed length Apple's preamble declares.
  internal let uncompressedCount: Int

  /// The compressed block as hex, including its varint preamble.
  internal let hex: String

  /// The compressed block's bytes.
  internal var block: [UInt8] {
    var bytes = [UInt8]()
    bytes.reserveCapacity(hex.utf8.count / 2)
    var high: UInt8?
    for character in hex {
      guard let nibble = character.hexDigitValue.map(UInt8.init) else {
        continue
      }
      if let pending = high {
        bytes.append(pending << 4 | nibble)
        high = nil
      } else {
        high = nibble
      }
    }
    return bytes
  }

  internal var description: String {
    "\(origin) (\(uncompressedCount) bytes uncompressed)"
  }
}
