import Foundation

public enum PolicySeverity: String, Codable, Sendable { case fail, warn, info }

public protocol PolicyFindingProtocol: Sendable, Encodable {
  associatedtype Payload: Encodable & Sendable
  static var policyID: String { get }
  var message: String { get }
  var severity: PolicySeverity { get }
  var payload: Payload? { get }
}

public struct AnyEncodable: Encodable, Sendable {
  private let json: String
  public init<T: Encodable>(_ value: T) {
    let enc = JSONEncoder()
    if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *) {
      enc.outputFormatting = [.sortedKeys]
    }
    if let data = try? enc.encode(value), let string = String(data: data, encoding: .utf8) {
      self.json = string
    } else {
      self.json = "\"<any-encodable>\""
    }
  }
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(json)
  }
}

public struct AnyPolicyFinding: Encodable, Sendable {
  public let policyID: String
  public let message: String
  public let severity: PolicySeverity
  public let payload: AnyEncodable?

  public init<F: PolicyFindingProtocol>(_ f: F) {
    self.policyID = F.policyID
    self.message = f.message
    self.severity = f.severity
    self.payload = f.payload.map(AnyEncodable.init)
  }
}
