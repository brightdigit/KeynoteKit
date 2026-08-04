/// A named byte payload, so parameterised test failures identify themselves.
internal struct Payload: Sendable, CustomStringConvertible {
  /// Human-readable name shown in test output.
  internal let name: String

  /// The bytes under test.
  internal let bytes: [UInt8]

  internal var description: String {
    "\(name) (\(bytes.count) bytes)"
  }

  /// Deterministic pseudo-random bytes.
  ///
  /// A fixed linear congruential generator keeps failures reproducible, which
  /// a system random source would not.
  ///
  /// - Parameter count: How many bytes to produce.
  /// - Returns: Incompressible-looking but repeatable bytes.
  internal static func pseudoRandom(count: Int) -> [UInt8] {
    var state: UInt64 = 0x2545_F491_4F6C_DD1D
    return (0..<count).map { _ in
      state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
      return UInt8(truncatingIfNeeded: state >> 33)
    }
  }

  /// Repeating English-like text, which compresses via medium-range matches.
  ///
  /// - Parameter count: The desired byte count.
  /// - Returns: The first `count` bytes of a repeated phrase.
  internal static func repeatingText(count: Int) -> [UInt8] {
    let phrase = Array("the quick brown fox jumps over the lazy dog. ".utf8)
    var bytes = [UInt8]()
    bytes.reserveCapacity(count)
    while bytes.count < count {
      bytes.append(contentsOf: phrase.prefix(count - bytes.count))
    }
    return bytes
  }
}
