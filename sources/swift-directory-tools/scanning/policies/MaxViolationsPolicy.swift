import Foundation

public struct MaxViolationsFinding: PolicyFindingProtocol {
  public static let policyID = "max-violations"
  public let message: String
  public let severity: PolicySeverity
  public struct Payload: Codable, Sendable {
    public let ruleIDs: [String]?
    public let limit: Int
    public let actual: Int
  }
  public let payload: Payload?
  public init(message: String, severity: PolicySeverity, payload: Payload?) {
    self.message = message
    self.severity = severity
    self.payload = payload
  }
}

public struct MaxViolationsPolicy: DirectoryScanPolicy {
  public typealias Finding = MaxViolationsFinding
  public let id: String = MaxViolationsFinding.policyID
  public let ruleIDs: Set<String>?
  public let limit: Int
  public let asSeverity: PolicySeverity

  public init(ruleIDs: Set<String>? = nil, limit: Int, severity: PolicySeverity = .fail) {
    self.ruleIDs = ruleIDs
    self.limit = limit
    self.asSeverity = severity
  }

  public func evaluate(result: DirectoryScanResult) -> [MaxViolationsFinding] {
    let actual = result.violations.filter { v in ruleIDs?.contains(v.ruleID) ?? true }.count
    guard actual > limit else { return [] }
    let msg = "violations exceeded limit (\(actual) > \(limit))"
    return [
      MaxViolationsFinding(
        message: msg, severity: asSeverity,
        payload: .init(ruleIDs: ruleIDs.map(Array.init), limit: limit, actual: actual))
    ]
  }
}
