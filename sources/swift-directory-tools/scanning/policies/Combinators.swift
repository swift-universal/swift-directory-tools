import Foundation

// MARK: - Composite Findings

public struct AllOfFinding: PolicyFindingProtocol {
  public static let policyID = "all-of"
  public let message: String
  public let severity: PolicySeverity
  public struct Payload: Encodable, Sendable {
    public let passingCount: Int
    public let failingCount: Int
    public let childFindings: [AnyPolicyFinding]
  }
  public let payload: Payload?
  public init(message: String, severity: PolicySeverity, payload: Payload?) {
    self.message = message
    self.severity = severity
    self.payload = payload
  }
}

public struct AnyOfFinding: PolicyFindingProtocol {
  public static let policyID = "any-of"
  public let message: String
  public let severity: PolicySeverity
  public struct Payload: Encodable, Sendable {
    public let passingCount: Int
    public let failingCount: Int
    public let childFindings: [AnyPolicyFinding]
  }
  public let payload: Payload?
  public init(message: String, severity: PolicySeverity, payload: Payload?) {
    self.message = message
    self.severity = severity
    self.payload = payload
  }
}

public struct ThresholdFinding: PolicyFindingProtocol {
  public static let policyID = "n-of"
  public let message: String
  public let severity: PolicySeverity
  public struct Payload: Encodable, Sendable {
    public let required: Int
    public let passingCount: Int
    public let failingCount: Int
    public let childFindings: [AnyPolicyFinding]
  }
  public let payload: Payload?
  public init(message: String, severity: PolicySeverity, payload: Payload?) {
    self.message = message
    self.severity = severity
    self.payload = payload
  }
}

public struct NotFinding: PolicyFindingProtocol {
  public static let policyID = "not"
  public let message: String
  public let severity: PolicySeverity
  public struct Payload: Encodable, Sendable {
    public let childFindings: [AnyPolicyFinding]
  }
  public let payload: Payload?
  public init(message: String, severity: PolicySeverity, payload: Payload?) {
    self.message = message
    self.severity = severity
    self.payload = payload
  }
}

// MARK: - Combinator Policies

/// Succeeds when all child policies have no `.fail` findings.
public struct AllOfPolicy: DirectoryScanPolicy {
  public typealias Finding = AllOfFinding
  public let id: String = AllOfFinding.policyID
  public let children: [AnyDirectoryScanPolicy]
  public let asSeverity: PolicySeverity

  public init(children: [AnyDirectoryScanPolicy], severity: PolicySeverity = .fail) {
    self.children = children
    self.asSeverity = severity
  }

  public func evaluate(result: DirectoryScanResult) -> [AllOfFinding] {
    let perChild = children.map { $0.evaluate(result) }
    let childFindings = perChild.flatMap { $0 }
    guard !children.isEmpty else { return [] }
    let passingCount = perChild.filter { child in
      child.first(where: { $0.severity == .fail }) == nil
    }.count
    guard passingCount == children.count else {
      let failingCount = children.count - passingCount
      return [
        AllOfFinding(
          message: "all-of requirement failed (passing=\(passingCount) < total=\(children.count))",
          severity: asSeverity,
          payload: .init(
            passingCount: passingCount, failingCount: failingCount, childFindings: childFindings)
        )
      ]
    }
    return []
  }
}

/// Succeeds when at least one child policy has no `.fail` findings.
public struct AnyOfPolicy: DirectoryScanPolicy {
  public typealias Finding = AnyOfFinding
  public let id: String = AnyOfFinding.policyID
  public let children: [AnyDirectoryScanPolicy]
  public let asSeverity: PolicySeverity

  public init(children: [AnyDirectoryScanPolicy], severity: PolicySeverity = .fail) {
    self.children = children
    self.asSeverity = severity
  }

  public func evaluate(result: DirectoryScanResult) -> [AnyOfFinding] {
    guard !children.isEmpty else { return [] }
    let perChild = children.map { $0.evaluate(result) }
    let childFindings = perChild.flatMap { $0 }
    let passingCount = perChild.filter { child in
      child.first(where: { $0.severity == .fail }) == nil
    }.count
    guard passingCount > 0 else {
      return [
        AnyOfFinding(
          message: "any-of requirement failed (no passing children)",
          severity: asSeverity,
          payload: .init(
            passingCount: 0, failingCount: children.count, childFindings: childFindings)
        )
      ]
    }
    return []
  }
}

/// Succeeds when at least `required` children have no `.fail` findings.
public struct NOfPolicy: DirectoryScanPolicy {
  public typealias Finding = ThresholdFinding
  public let id: String = ThresholdFinding.policyID
  public let children: [AnyDirectoryScanPolicy]
  public let required: Int
  public let asSeverity: PolicySeverity

  public init(children: [AnyDirectoryScanPolicy], required: Int, severity: PolicySeverity = .fail) {
    self.children = children
    self.required = required
    self.asSeverity = severity
  }

  public func evaluate(result: DirectoryScanResult) -> [ThresholdFinding] {
    guard required > 0 else { return [] }
    guard !children.isEmpty else {
      return [
        ThresholdFinding(
          message: "n-of requirement failed (required=\(required), total=0)",
          severity: asSeverity,
          payload: .init(required: required, passingCount: 0, failingCount: 0, childFindings: [])
        )
      ]
    }
    let perChild = children.map { $0.evaluate(result) }
    let passingCount = perChild.filter { child in
      child.first(where: { $0.severity == .fail }) == nil
    }.count
    guard passingCount >= required else {
      let childFindings = perChild.flatMap { $0 }
      return [
        ThresholdFinding(
          message: "n-of requirement failed (passing=\(passingCount) < required=\(required))",
          severity: asSeverity,
          payload: .init(
            required: required, passingCount: passingCount,
            failingCount: children.count - passingCount, childFindings: childFindings)
        )
      ]
    }
    return []
  }
}

/// Succeeds when the child policy produces no `.fail` findings.
public struct NotPolicy: DirectoryScanPolicy {
  public typealias Finding = NotFinding
  public let id: String = NotFinding.policyID
  public let child: AnyDirectoryScanPolicy
  public let asSeverity: PolicySeverity

  public init(child: AnyDirectoryScanPolicy, severity: PolicySeverity = .fail) {
    self.child = child
    self.asSeverity = severity
  }

  public func evaluate(result: DirectoryScanResult) -> [NotFinding] {
    let childFindings = child.evaluate(result)
    let failing = childFindings.filter { $0.severity == .fail }
    guard !failing.isEmpty else { return [] }
    return [
      NotFinding(
        message: "not requirement failed (child produced failures)",
        severity: asSeverity,
        payload: .init(childFindings: childFindings)
      )
    ]
  }
}

// (No helper needed; we compute per-child pass/fail directly.)
