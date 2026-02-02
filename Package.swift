// swift-tools-version:6.2
import Foundation
import PackageDescription

let commonShellDependency: Package.Dependency = {
  if ProcessInfo.useLocalDeps {
    return .package(path: "../../../../../../../swift-universal/public/spm/universal/domain/system/common-shell")
  }
  return .package(url: "https://github.com/swift-universal/common-shell.git", from: "0.0.1")
}()

// MARK: - Configuration Service

ConfigurationService.local.dependencies = [
  .package(name: "common-log", path: "../../../../../../../swift-universal/public/spm/universal/domain/system/common-log"),
  .package(name: "common-cli", path: "../../../../../../../swift-universal/public/spm/universal/domain/system/common-cli"),
  commonShellDependency,
  .package(
    name: "wrkstrm-main",
    path: "../../../../../../../wrkstrm/spm/universal/domain/system/wrkstrm-main"
  ),
  .package(
    name: "wrkstrm-foundation",
    path: "../../../../../../../wrkstrm/spm/universal/domain/system/wrkstrm-foundation"
  ),
]

ConfigurationService.remote.dependencies = [
  .package(url: "https://github.com/swift-universal/common-log.git", from: "3.0.0"),
  .package(url: "https://github.com/swift-universal/common-cli.git", from: "0.1.0"),
  .package(url: "https://github.com/swift-universal/common-shell.git", from: "0.0.1"),
  .package(url: "https://github.com/wrkstrm/wrkstrm-main.git", from: "3.0.0"),
  .package(url: "https://github.com/wrkstrm/wrkstrm-foundation.git", from: "3.0.0"),
]

let package: Package = .init(
  name: "SwiftDirectoryTools",
  platforms: [
    .iOS(.v16),
    .macOS(.v15),
    .macCatalyst(.v13),
    .tvOS(.v16),
    .visionOS(.v1),
    .watchOS(.v9),
  ],
  products: [
    .library(
      name: "SwiftDirectoryTools",
      targets: ["SwiftDirectoryTools"],
    ),
    .executable(
      name: "swift-directory-tools",
      targets: ["SwiftDirectoryToolsCLI"],
    ),
  ],
  dependencies: ConfigurationService.inject.dependencies + [
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.6.0")
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "SwiftDirectoryTools",
      dependencies: [
        .product(name: "CommonLog", package: "common-log"),
        .product(name: "WrkstrmMain", package: "wrkstrm-main")
      ],
      path: "sources/swift-directory-tools",
      swiftSettings: ConfigurationService.inject.swiftSettings,
    ),
    .executableTarget(
      name: "SwiftDirectoryToolsCLI",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        "SwiftDirectoryTools",
        .product(name: "WrkstrmFoundation", package: "wrkstrm-foundation"),
        .product(name: "CommonLog", package: "common-log"),
        .product(name: "CommonCLI", package: "common-cli"),
        .product(name: "CommonShell", package: "common-shell"),
      ],
      path: "sources/swift-directory-tools-cli",
      swiftSettings: ConfigurationService.inject.swiftSettings,
    ),
    .testTarget(
      name: "SwiftDirectoryToolsTests",
      dependencies: ["SwiftDirectoryTools", .product(name: "CommonLog", package: "common-log")],
      path: "tests/swift-directory-tools-tests",
      swiftSettings: ConfigurationService.inject.swiftSettings,
    ),
    .testTarget(
      name: "SwiftDirectoryToolsCLITests",
      dependencies: [
        "SwiftDirectoryToolsCLI",
        .product(name: "CommonLog", package: "common-log"),
        .product(name: "WrkstrmFoundation", package: "wrkstrm-foundation"),
      ],
      path: "tests/swift-directory-tools-cli-tests",
      swiftSettings: ConfigurationService.inject.swiftSettings,
    ),
  ],
)

// MARK: - Configuration Service

@MainActor
public struct ConfigurationService {
  public static let version = "1.0.0"

  public var swiftSettings: [SwiftSetting] = []
  var dependencies: [PackageDescription.Package.Dependency] = []

  public static let inject: ConfigurationService = ProcessInfo.useLocalDeps ? .local : .remote

  static var local: ConfigurationService = .init(swiftSettings: [.local])
  static var remote: ConfigurationService = .init()
}

// MARK: - PackageDescription extensions

extension SwiftSetting {
  public static let local: SwiftSetting = .unsafeFlags([
    "-Xfrontend",
    "-warn-long-expression-type-checking=10",
  ])
}

// MARK: - Foundation extensions

extension ProcessInfo {
  public static var useLocalDeps: Bool {
    guard let raw = ProcessInfo.processInfo.environment["SPM_USE_LOCAL_DEPS"] else { return true }
    let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    return !(normalized == "0" || normalized == "false" || normalized == "no")
  }
}

// CONFIG_SERVICE_END_V1_HASH:{{CONFIG_HASH}}
