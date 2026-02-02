import Foundation
import CommonLog

public protocol DirectoryScanAdapter: Sendable {
  func run(
    rules: DirectoryScanRuleSet, options: DirectoryScanOptions,
    sink: ((DirectoryScanEvent) -> Void)?
  ) throws -> DirectoryScanResult
}

public struct InProcessSingleAdapter: DirectoryScanAdapter {
  public init() {}

  public func run(
    rules: DirectoryScanRuleSet, options: DirectoryScanOptions,
    sink: ((DirectoryScanEvent) -> Void)?
  ) throws -> DirectoryScanResult {
    let start = Date()
    var filesVisited = 0
    var dirsVisited = 0
    var violations: [DirectoryScanViolation] = []
    var emptyDirs: [String] = []

    let fm = FileManager.default
    let roots = options.roots
    for root in roots {
      sink?(.started(root: root))
      // Track child counts to detect empties
      var childCounts: [String: Int] = [:]
      guard
        let it = fm.enumerator(
          at: root, includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey], options: [],
          errorHandler: nil)
      else { continue }
      for case let url as URL in it {
        let name = url.lastPathComponent
        // Ignore prefixes
        if options.ignorePrefixes.contains(where: { name.hasPrefix($0) }) {
          it.skipDescendants()
          continue
        }
        // Scope (DocC-only)
        if options.scope == .docc {
          if !url.path.contains(".docc/") { continue }
        }

        let vals = try? url.resourceValues(forKeys: [
          .isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey,
        ])
        if vals?.isSymbolicLink == true && !options.followSymlinks { continue }
        if vals?.isDirectory == true {
          dirsVisited += 1
          // Initialize child count
          childCounts[url.path, default: 0] = childCounts[url.path, default: 0]
          // Count into parent
          let parent = url.deletingLastPathComponent().path
          childCounts[parent, default: 0] += 1
          if !rules.accept(directory: url) { it.skipDescendants() }
          continue
        }
        if vals?.isRegularFile == true {
          filesVisited += 1
          let parent = url.deletingLastPathComponent().path
          childCounts[parent, default: 0] += 1
          if let v = rules.apply(file: url) {
            violations.append(v)
            sink?(.violation(v))
          }
          if (filesVisited % 500) == 0 {
            sink?(.progress(files: filesVisited, directories: dirsVisited))
          }
        }
      }
      // finalize empty dirs
      for (dirPath, count) in childCounts where count == 0 {
        let dirURL = URL(fileURLWithPath: dirPath)
        if let rec = rules.finalize(directory: dirURL, childCount: count) {
          emptyDirs.append(rec)
          sink?(.emptyDir(path: rec))
        }
      }
    }

    let end = Date()
    let metrics = DirectoryScanMetrics(
      filesVisited: filesVisited, directoriesVisited: dirsVisited,
      duration: end.timeIntervalSince(start), start: start, end: end)
    let result = DirectoryScanResult(
      violations: violations, emptyDirectories: emptyDirs, metrics: metrics)
    sink?(.finished(result: result))
    return result
  }
}
