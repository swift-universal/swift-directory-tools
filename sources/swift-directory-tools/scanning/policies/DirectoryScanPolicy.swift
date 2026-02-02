import Foundation

public protocol DirectoryScanPolicy: Sendable {
  associatedtype Finding: PolicyFindingProtocol
  var id: String { get }
  func evaluate(result: DirectoryScanResult) -> [Finding]
}

public struct AnyDirectoryScanPolicy: Sendable {
  private let _id: @Sendable () -> String
  private let _eval: @Sendable (DirectoryScanResult) -> [AnyPolicyFinding]
  public init<P: DirectoryScanPolicy>(_ p: P) {
    _id = { p.id }
    _eval = { res in p.evaluate(result: res).map(AnyPolicyFinding.init) }
  }
  public var id: String { _id() }
  public func evaluate(_ result: DirectoryScanResult) -> [AnyPolicyFinding] { _eval(result) }
}

public struct DirectoryPolicyEvaluator: Sendable {
  public init() {}
  public func evaluate(result: DirectoryScanResult, policies: [AnyDirectoryScanPolicy])
    -> [AnyPolicyFinding]
  {
    policies.flatMap { $0.evaluate(result) }
  }
}
