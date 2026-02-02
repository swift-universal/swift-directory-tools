import Foundation

public struct NoEmptyDirsFinding: PolicyFindingProtocol {
  public static let policyID = "no-empty-dirs"
  public let message: String
  public let severity: PolicySeverity
  public struct Payload: Encodable, Sendable {
    public let mode: String
    public let count: Int
    public let directories: [String]
  }
  public let payload: Payload?
  public init(message: String, severity: PolicySeverity, payload: Payload?) {
    self.message = message
    self.severity = severity
    self.payload = payload
  }
}

public struct NoEmptyDirsPolicy: DirectoryScanPolicy {
  public typealias Finding = NoEmptyDirsFinding
  public enum Mode: Sendable {
    /// Count everything — truly zero children only.
    case strictZero
    /// Treat common noise (.DS_Store, .git, .swiftpm, etc.) as ignorable.
    case ignoreNoise
    /// Caller-provided lists.
    case custom(ignore: [String], keep: [String])
  }

  public let id: String = NoEmptyDirsFinding.policyID
  public let mode: Mode
  public let roots: [URL]
  public let asSeverity: PolicySeverity

  public init(mode: Mode, roots: [URL], severity: PolicySeverity = .fail) {
    self.mode = mode
    self.roots = roots
    self.asSeverity = severity
  }

  public func evaluate(result _: DirectoryScanResult) -> [NoEmptyDirsFinding] {
    // Derive ignore + keeper lists from mode
    let (ignores, keepers): ([String], Set<String>) = {
      switch mode {
      case .strictZero:
        return ([], [])
      case .ignoreNoise:
        return (SwiftDirectoryTools.Ignore.directoryIgnorePrefixes, [])
      case .custom(let ignore, let keep):
        return (ignore, Set(keep))
      }
    }()

    let fm = FileManager.default
    var empties: [String] = []

    for root in roots {
      guard
        let it = fm.enumerator(
          at: root, includingPropertiesForKeys: [.isDirectoryKey],
          options: [.skipsPackageDescendants], errorHandler: nil)
      else { continue }
      for case let url as URL in it {
        guard (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true else {
          continue
        }
        if isEmpty(url: url, ignores: ignores, keepers: keepers) {
          empties.append(url.path)
        }
      }
      // Also evaluate the root itself
      if isEmpty(url: root, ignores: ignores, keepers: keepers) {
        empties.append(root.path)
      }
    }

    guard !empties.isEmpty else { return [] }
    let modeString: String = {
      switch mode {
      case .strictZero: return "strict-zero"
      case .ignoreNoise: return "ignore-noise"
      case .custom: return "custom"
      }
    }()
    let msg = "empty directories found (count=\(empties.count))"
    return [
      NoEmptyDirsFinding(
        message: msg,
        severity: asSeverity,
        payload: .init(mode: modeString, count: empties.count, directories: empties)
      )
    ]
  }

  private func isEmpty(url: URL, ignores: [String], keepers: Set<String>) -> Bool {
    let fm = FileManager.default
    guard let items = try? fm.contentsOfDirectory(atPath: url.path) else { return false }
    // Classify children
    var relevant: [String] = []
    for name in items {
      // Ignore "." and ".." implicitly
      if name == "." || name == ".." { continue }
      // Ignore noise by prefix match
      if ignores.contains(where: { name.hasPrefix($0) }) { continue }
      // Keepers do not count against emptiness
      if keepers.contains(name) { continue }
      // Everything else is relevant
      relevant.append(name)
    }
    return relevant.isEmpty
  }
}
