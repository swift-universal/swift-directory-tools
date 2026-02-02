import Foundation

public struct EmptyDirectoryRule: DirectoryScanRule {
  public let id: String = "empty-dir"
  public let description: String = "Detect empty directories and recommend deletion."
  public init() {}

  public func apply(file url: URL) -> DirectoryScanViolation? { nil }
  public func finalize(directory url: URL, childCount: Int) -> String? {
    childCount == 0 ? url.path : nil
  }
}
