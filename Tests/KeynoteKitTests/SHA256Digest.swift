import Foundation

/// A minimal, dependency-free SHA-256 used to pin the bundled template's bytes.
///
/// CryptoKit is Darwin-only and `swift-crypto` is not a package dependency, so
/// this is implemented directly to keep the test running on the Linux, Windows,
/// and Android CI legs.
internal enum SHA256Digest {
  /// SHA-256 round constants.
  private static let roundConstants: [UInt32] = [
    0x428a_2f98, 0x7137_4491, 0xb5c0_fbcf, 0xe9b5_dba5,
    0x3956_c25b, 0x59f1_11f1, 0x923f_82a4, 0xab1c_5ed5,
    0xd807_aa98, 0x1283_5b01, 0x2431_85be, 0x550c_7dc3,
    0x72be_5d74, 0x80de_b1fe, 0x9bdc_06a7, 0xc19b_f174,
    0xe49b_69c1, 0xefbe_4786, 0x0fc1_9dc6, 0x240c_a1cc,
    0x2de9_2c6f, 0x4a74_84aa, 0x5cb0_a9dc, 0x76f9_88da,
    0x983e_5152, 0xa831_c66d, 0xb003_27c8, 0xbf59_7fc7,
    0xc6e0_0bf3, 0xd5a7_9147, 0x06ca_6351, 0x1429_2967,
    0x27b7_0a85, 0x2e1b_2138, 0x4d2c_6dfc, 0x5338_0d13,
    0x650a_7354, 0x766a_0abb, 0x81c2_c92e, 0x9272_2c85,
    0xa2bf_e8a1, 0xa81a_664b, 0xc24b_8b70, 0xc76c_51a3,
    0xd192_e819, 0xd699_0624, 0xf40e_3585, 0x106a_a070,
    0x19a4_c116, 0x1e37_6c08, 0x2748_774c, 0x34b0_bcb5,
    0x391c_0cb3, 0x4ed8_aa4a, 0x5b9c_ca4f, 0x682e_6ff3,
    0x748f_82ee, 0x78a5_636f, 0x84c8_7814, 0x8cc7_0208,
    0x90be_fffa, 0xa450_6ceb, 0xbef9_a3f7, 0xc671_78f2,
  ]

  /// SHA-256 initial hash values.
  private static let initialState: [UInt32] = [
    0x6a09_e667, 0xbb67_ae85, 0x3c6e_f372, 0xa54f_f53a,
    0x510e_527f, 0x9b05_688c, 0x1f83_d9ab, 0x5be0_cd19,
  ]

  /// Computes the lowercase hex SHA-256 digest of `data`.
  ///
  /// - Parameter data: Message to hash.
  /// - Returns: A 64-character lowercase hexadecimal digest.
  internal static func hexString(of data: Data) -> String {
    self.hash(data).map { String(format: "%02x", $0) }.joined()
  }

  /// Computes the raw 32-byte SHA-256 digest of `data`.
  ///
  /// - Parameter data: Message to hash.
  /// - Returns: The 32-byte digest.
  private static func hash(_ data: Data) -> [UInt8] {
    var state = self.initialState
    let message = self.padded(Array(data))

    for chunkStart in stride(from: 0, to: message.count, by: 64) {
      let chunk = Array(message[chunkStart..<chunkStart + 64])
      self.compress(chunk, into: &state)
    }

    return state.flatMap { word in
      [
        UInt8(truncatingIfNeeded: word >> 24),
        UInt8(truncatingIfNeeded: word >> 16),
        UInt8(truncatingIfNeeded: word >> 8),
        UInt8(truncatingIfNeeded: word),
      ]
    }
  }

  /// Applies SHA-256 length padding to a message.
  ///
  /// - Parameter message: Raw message bytes.
  /// - Returns: The message padded to a multiple of 64 bytes.
  private static func padded(_ message: [UInt8]) -> [UInt8] {
    var padded = message
    let bitCount = UInt64(message.count) * 8

    padded.append(0x80)
    while padded.count % 64 != 56 {
      padded.append(0)
    }
    for shift in stride(from: 56, through: 0, by: -8) {
      padded.append(UInt8(truncatingIfNeeded: bitCount >> UInt64(shift)))
    }

    return padded
  }

  /// Runs the SHA-256 compression function over one 64-byte chunk.
  ///
  /// - Parameters:
  ///   - chunk: Exactly 64 message bytes.
  ///   - state: Running hash state, updated in place.
  private static func compress(_ chunk: [UInt8], into state: inout [UInt32]) {
    var schedule = [UInt32](repeating: 0, count: 64)

    for index in 0..<16 {
      let offset = index * 4
      schedule[index] =
        UInt32(chunk[offset]) << 24 | UInt32(chunk[offset + 1]) << 16
        | UInt32(chunk[offset + 2]) << 8 | UInt32(chunk[offset + 3])
    }
    for index in 16..<64 {
      let sigma0 =
        self.rotate(schedule[index - 15], 7)
        ^ self.rotate(schedule[index - 15], 18) ^ (schedule[index - 15] >> 3)
      let sigma1 =
        self.rotate(schedule[index - 2], 17)
        ^ self.rotate(schedule[index - 2], 19) ^ (schedule[index - 2] >> 10)
      schedule[index] =
        schedule[index - 16] &+ sigma0 &+ schedule[index - 7] &+ sigma1
    }

    var working = state

    for index in 0..<64 {
      let sigma1 =
        self.rotate(working[4], 6) ^ self.rotate(working[4], 11)
        ^ self.rotate(working[4], 25)
      let choice = (working[4] & working[5]) ^ (~working[4] & working[6])
      let temp1 =
        working[7] &+ sigma1 &+ choice &+ self.roundConstants[index]
        &+ schedule[index]
      let sigma0 =
        self.rotate(working[0], 2) ^ self.rotate(working[0], 13)
        ^ self.rotate(working[0], 22)
      let majority =
        (working[0] & working[1]) ^ (working[0] & working[2])
        ^ (working[1] & working[2])
      let temp2 = sigma0 &+ majority

      working[7] = working[6]
      working[6] = working[5]
      working[5] = working[4]
      working[4] = working[3] &+ temp1
      working[3] = working[2]
      working[2] = working[1]
      working[1] = working[0]
      working[0] = temp1 &+ temp2
    }

    for index in 0..<8 {
      state[index] = state[index] &+ working[index]
    }
  }

  /// Rotates a 32-bit word right by `amount` bits.
  ///
  /// - Parameters:
  ///   - value: Word to rotate.
  ///   - amount: Bit count to rotate by.
  /// - Returns: The rotated word.
  private static func rotate(_ value: UInt32, _ amount: UInt32) -> UInt32 {
    (value >> amount) | (value << (32 - amount))
  }
}
