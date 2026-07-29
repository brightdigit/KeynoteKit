// swift-tools-version: 6.4

import PackageDescription

let package = Package(
  name: "KeynoteKit",
  platforms: [
    .macOS(.v14),
    .iOS(.v17),
    .tvOS(.v17),
    .watchOS(.v10),
    .visionOS(.v1)
  ],
  products: [
    .library(name: "Snappy", targets: ["Snappy"]),
    .library(name: "IWAFraming", targets: ["IWAFraming"]),
    .library(name: "KeynoteKitProtobuf", targets: ["KeynoteKitProtobuf"]),
    .library(name: "KeynoteKit", targets: ["KeynoteKit"]),
    .library(name: "KeynoteKitScripting", targets: ["KeynoteKitScripting"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-protobuf", from: "1.38.1")
  ],
  targets: [
    // Generic Snappy block codec. Nothing Apple-specific lives here — this is
    // the seam that becomes an external dependency in #5.
    .target(name: "Snappy"),

    // Apple's .iwa chunk layout, built on the block codec.
    .target(name: "IWAFraming", dependencies: ["Snappy"]),

    // Generated Keynote 15.3 messages + TSPRegistryMapping (#14).
    .target(
      name: "KeynoteKitProtobuf",
      dependencies: [.product(name: "SwiftProtobuf", package: "swift-protobuf")]
    ),

    // Public authoring API. Must never import or link ScriptingBridge.
    .target(name: "KeynoteKit", dependencies: ["IWAFraming", "KeynoteKitProtobuf"]),

    // ScriptingBridge escape hatch (#10). Reserved here, empty until then.
    // The body is gated on `canImport(ScriptingBridge)` rather than a linked
    // framework, so this module still compiles on non-Apple platforms.
    .target(name: "KeynoteKitScripting"),

    .testTarget(name: "SnappyTests", dependencies: ["Snappy"]),
    .testTarget(name: "IWAFramingTests", dependencies: ["IWAFraming"]),
    .testTarget(name: "KeynoteKitProtobufTests", dependencies: ["KeynoteKitProtobuf"]),
    .testTarget(name: "KeynoteKitTests", dependencies: ["KeynoteKit"]),
    .testTarget(name: "KeynoteKitScriptingTests", dependencies: ["KeynoteKitScripting"])
  ]
)
