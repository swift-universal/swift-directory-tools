import Foundation

public protocol DirectoryScanRule: Sendable {
  var id: String { get }
  var description: String { get }
  func apply(file url: URL) -> DirectoryScanViolation?
  func accept(directory url: URL) -> Bool
  func finalize(directory url: URL, childCount: Int) -> String?
}

extension DirectoryScanRule {
  public func accept(directory _: URL) -> Bool { true }
  public func finalize(directory _: URL, childCount _: Int) -> String? { nil }
}

public struct DirectoryScanRuleSet: Sendable {
  public var rules: [DirectoryScanRule]
  public init(_ rules: [DirectoryScanRule]) { self.rules = rules }

  public func apply(file url: URL) -> DirectoryScanViolation? {
    for rule in rules { if let v = rule.apply(file: url) { return v } }
    return nil
  }
  public func accept(directory url: URL) -> Bool { rules.allSatisfy { $0.accept(directory: url) } }
  public func finalize(directory url: URL, childCount: Int) -> String? {
    for rule in rules {
      if let s = rule.finalize(directory: url, childCount: childCount) { return s }
    }
    return nil
  }
}
