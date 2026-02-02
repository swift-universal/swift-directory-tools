import Foundation
import Testing

@testable import SwiftDirectoryTools

// Helpers
private func makeResult(violations: [DirectoryScanViolation] = [], emptyDirs: [String] = [])
  -> DirectoryScanResult
{
  let now = Date()
  let metrics = DirectoryScanMetrics(
    filesVisited: 0,
    directoriesVisited: 0,
    duration: 0,
    start: now,
    end: now
  )
  return DirectoryScanResult(violations: violations, emptyDirectories: emptyDirs, metrics: metrics)
}

@Test("AllOf succeeds when all children pass (no finding)")
func allOf_passes() async throws {
  // No violations → both child policies pass
  let res = makeResult()
  let p1 = AnyDirectoryScanPolicy(MaxViolationsPolicy(ruleIDs: ["kebab-case"], limit: 0))
  let p2 = AnyDirectoryScanPolicy(MaxViolationsPolicy(ruleIDs: ["empty-dir"], limit: 0))
  let all = AllOfPolicy(children: [p1, p2])

  let findings = DirectoryPolicyEvaluator().evaluate(
    result: res, policies: [AnyDirectoryScanPolicy(all)])
  #expect(findings.isEmpty)
}

@Test("AllOf fails when any child fails (aggregate finding)")
func allOf_fails_when_one_child_fails() async throws {
  // One kebab-case violation → kebab child fails
  let v = DirectoryScanViolation(path: "BadName.swift", reason: "not-kebab", ruleID: "kebab-case")
  let res = makeResult(violations: [v])
  let p1 = AnyDirectoryScanPolicy(MaxViolationsPolicy(ruleIDs: ["kebab-case"], limit: 0))
  let p2 = AnyDirectoryScanPolicy(MaxViolationsPolicy(ruleIDs: ["empty-dir"], limit: 0))
  let all = AllOfPolicy(children: [p1, p2])

  let findings = DirectoryPolicyEvaluator().evaluate(
    result: res, policies: [AnyDirectoryScanPolicy(all)])
  #expect(findings.count == 1)
  #expect(findings[0].policyID == "all-of")
  #expect(findings[0].severity == .fail)
}

@Test("AnyOf succeeds when at least one child passes (no finding)")
func anyOf_passes_when_one_child_passes() async throws {
  // One kebab violation; empty-dir child passes if no empty-dir violations
  let v = DirectoryScanViolation(path: "BadName.swift", reason: "not-kebab", ruleID: "kebab-case")
  let res = makeResult(violations: [v])
  let kebab = AnyDirectoryScanPolicy(MaxViolationsPolicy(ruleIDs: ["kebab-case"], limit: 0))
  let empty = AnyDirectoryScanPolicy(MaxViolationsPolicy(ruleIDs: ["empty-dir"], limit: 0))
  let any = AnyOfPolicy(children: [kebab, empty])

  let findings = DirectoryPolicyEvaluator().evaluate(
    result: res, policies: [AnyDirectoryScanPolicy(any)])
  #expect(findings.isEmpty)
}

@Test("AnyOf fails when all children fail (aggregate finding)")
func anyOf_fails_when_all_children_fail() async throws {
  // Both kebab and empty-dir violations → both children fail
  let v1 = DirectoryScanViolation(path: "BadName.swift", reason: "not-kebab", ruleID: "kebab-case")
  let v2 = DirectoryScanViolation(path: "empty/", reason: "empty", ruleID: "empty-dir")
  let res = makeResult(violations: [v1, v2])
  let kebab = AnyDirectoryScanPolicy(MaxViolationsPolicy(ruleIDs: ["kebab-case"], limit: 0))
  let empty = AnyDirectoryScanPolicy(MaxViolationsPolicy(ruleIDs: ["empty-dir"], limit: 0))
  let any = AnyOfPolicy(children: [kebab, empty])

  let findings = DirectoryPolicyEvaluator().evaluate(
    result: res, policies: [AnyDirectoryScanPolicy(any)])
  #expect(findings.count == 1)
  #expect(findings[0].policyID == "any-of")
}

@Test("NOf succeeds when required threshold met (no finding)")
func nOf_passes_at_threshold() async throws {
  // Only kebab has a violation; require 1 of 2 to pass
  let v = DirectoryScanViolation(path: "BadName.swift", reason: "not-kebab", ruleID: "kebab-case")
  let res = makeResult(violations: [v])
  let kebab = AnyDirectoryScanPolicy(MaxViolationsPolicy(ruleIDs: ["kebab-case"], limit: 0))
  let empty = AnyDirectoryScanPolicy(MaxViolationsPolicy(ruleIDs: ["empty-dir"], limit: 0))
  let nOf = NOfPolicy(children: [kebab, empty], required: 1)

  let findings = DirectoryPolicyEvaluator().evaluate(
    result: res, policies: [AnyDirectoryScanPolicy(nOf)])
  #expect(findings.isEmpty)
}

@Test("NOf fails when not enough children pass (aggregate finding)")
func nOf_fails_below_threshold() async throws {
  // Both fail; require 1 → fails
  let v1 = DirectoryScanViolation(path: "BadName.swift", reason: "not-kebab", ruleID: "kebab-case")
  let v2 = DirectoryScanViolation(path: "empty/", reason: "empty", ruleID: "empty-dir")
  let res = makeResult(violations: [v1, v2])
  let kebab = AnyDirectoryScanPolicy(MaxViolationsPolicy(ruleIDs: ["kebab-case"], limit: 0))
  let empty = AnyDirectoryScanPolicy(MaxViolationsPolicy(ruleIDs: ["empty-dir"], limit: 0))
  let nOf = NOfPolicy(children: [kebab, empty], required: 1)

  let findings = DirectoryPolicyEvaluator().evaluate(
    result: res, policies: [AnyDirectoryScanPolicy(nOf)])
  #expect(findings.count == 1)
  #expect(findings[0].policyID == "n-of")
}

@Test("Not succeeds when child passes (no finding)")
func not_passes_when_child_passes() async throws {
  // No violations → child passes
  let res = makeResult()
  let child = AnyDirectoryScanPolicy(MaxViolationsPolicy(ruleIDs: ["kebab-case"], limit: 0))
  let not = NotPolicy(child: child)
  let findings = DirectoryPolicyEvaluator().evaluate(
    result: res, policies: [AnyDirectoryScanPolicy(not)])
  #expect(findings.isEmpty)
}

@Test("Not fails when child fails (aggregate finding)")
func not_fails_when_child_fails() async throws {
  // Kebab violation → child fails → not fails
  let v = DirectoryScanViolation(path: "BadName.swift", reason: "not-kebab", ruleID: "kebab-case")
  let res = makeResult(violations: [v])
  let child = AnyDirectoryScanPolicy(MaxViolationsPolicy(ruleIDs: ["kebab-case"], limit: 0))
  let not = NotPolicy(child: child)
  let findings = DirectoryPolicyEvaluator().evaluate(
    result: res, policies: [AnyDirectoryScanPolicy(not)])
  #expect(findings.count == 1)
  #expect(findings[0].policyID == "not")
}
