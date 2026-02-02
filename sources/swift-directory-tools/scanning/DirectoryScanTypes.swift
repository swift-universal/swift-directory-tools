import Foundation
import CommonLog

public enum DirectoryScanScope: Sendable { case docc, all }

public struct DirectoryScanOptions: Sendable {
  public var scope: DirectoryScanScope
  public var roots: [URL]
  public var ignorePrefixes: [String]
  public var concurrency: Int?
  public var followSymlinks: Bool

  public init(
    scope: DirectoryScanScope = .docc,
    roots: [URL],
    ignorePrefixes: [String] = SwiftDirectoryTools.Ignore.directoryIgnorePrefixes,
    concurrency: Int? = nil,
    followSymlinks: Bool = false
  ) {
    self.scope = scope
    self.roots = roots
    self.ignorePrefixes = ignorePrefixes
    self.concurrency = concurrency
    self.followSymlinks = followSymlinks
  }
}

public struct DirectoryScanViolation: Codable, Sendable, Equatable {
  public let path: String
  public let reason: String
  public let ruleID: String
}

public struct DirectoryScanMetrics: Codable, Sendable, Equatable {
  public let filesVisited: Int
  public let directoriesVisited: Int
  public let duration: TimeInterval
  public let start: Date
  public let end: Date
}

public struct DirectoryScanResult: Codable, Sendable, Equatable {
  public let violations: [DirectoryScanViolation]
  public let emptyDirectories: [String]
  public let metrics: DirectoryScanMetrics
  public let version: Int = 1
}

public enum DirectoryScanEvent: Sendable {
  case started(root: URL)
  case progress(files: Int, directories: Int)
  case violation(DirectoryScanViolation)
  case emptyDir(path: String)
  case finished(result: DirectoryScanResult)
}
